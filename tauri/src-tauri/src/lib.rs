use std::{
    fs,
    io::{Read, Write},
    net::{TcpStream, ToSocketAddrs},
    path::PathBuf,
    process::{Child, Command},
    sync::{
        atomic::{AtomicBool, Ordering},
        Mutex,
    },
    thread,
    time::{Duration, Instant},
};

use tauri::{
    http::{Request, Response},
    Manager,
    RunEvent,
    WebviewUrl,
    WebviewWindowBuilder,
    WindowEvent,
};

struct BackendState {
    process: Mutex<Option<Child>>,
}

struct SplashState {
    programmatic_close: AtomicBool,
}

fn get_resource_dir(app: &tauri::AppHandle) -> Result<PathBuf, String> {
    if cfg!(debug_assertions) {
        Ok(PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("resources"))
    } else {
        app.path()
            .resource_dir()
            .map_err(|e| format!("Failed to get resource directory: {e}"))
    }
}

fn find_backend_jar(app: &tauri::AppHandle) -> Result<PathBuf, String> {
    let backend_dir = get_resource_dir(app)?.join("backend");

    let entries = fs::read_dir(&backend_dir)
        .map_err(|e| format!("Failed to read backend directory: {e}"))?;

    for entry in entries {
        let entry =
            entry.map_err(|e| format!("Failed to read backend directory entry: {e}"))?;

        let path = entry.path();

        if path.extension().and_then(|ext| ext.to_str()) != Some("jar") {
            continue;
        }

        let file_name = path
            .file_name()
            .and_then(|name| name.to_str())
            .unwrap_or_default();

        if !file_name.ends_with("-sources.jar") && !file_name.ends_with("-javadoc.jar") {
            return Ok(path);
        }
    }

    Err(format!(
        "No backend JAR found in: {}",
        backend_dir.display()
    ))
}

fn start_backend(app: &tauri::AppHandle) -> Result<Child, String> {
    let jar_path = find_backend_jar(app)?;
    let resource_dir = get_resource_dir(app)?;

    let java_path = resource_dir
        .join("runtime")
        .join("bin")
        .join("java.exe");

    if !java_path.exists() {
        return Err(format!(
            "Bundled Java runtime not found: {}",
            java_path.display()
        ));
    }

    let backend_dir = jar_path
        .parent()
        .ok_or_else(|| "Failed to determine backend directory".to_string())?;

    let data_dir = app
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get application data directory: {e}"))?
        .join("data");

    fs::create_dir_all(&data_dir)
        .map_err(|e| format!("Failed to create application data directory: {e}"))?;

    let database_path = data_dir.join("job_tracker.db");

    println!("Starting backend: {}", jar_path.display());
    println!("Java runtime: {}", java_path.display());
    println!("Application data: {}", data_dir.display());
    println!("Database: {}", database_path.display());

    Command::new(&java_path)
        .arg("-jar")
        .arg(&jar_path)
        .arg(format!(
            "--spring.datasource.url=jdbc:sqlite:{}",
            database_path.display()
        ))
        .current_dir(backend_dir)
        .spawn()
        .map_err(|e| format!("Failed to start Spring Boot backend: {e}"))
}

fn wait_for_backend(timeout: Duration) -> Result<(), String> {
    let start_time = Instant::now();
    let address = "127.0.0.1:8080";

    println!("Waiting for Spring Boot...");

    loop {
        if start_time.elapsed() >= timeout {
            return Err(format!(
                "Backend did not become available within {} seconds.",
                timeout.as_secs()
            ));
        }

        let address_result = address
            .to_socket_addrs()
            .map_err(|e| format!("Failed to resolve backend address: {e}"))?
            .next();

        if let Some(address) = address_result {
            match TcpStream::connect_timeout(&address, Duration::from_secs(1)) {
                Ok(mut stream) => {
                    let request = concat!(
                        "GET /swagger-ui/index.html HTTP/1.1\r\n",
                        "Host: localhost:8080\r\n",
                        "Connection: close\r\n",
                        "\r\n"
                    );

                    if stream.write_all(request.as_bytes()).is_ok() {
                        let mut response = String::new();

                        if stream.read_to_string(&mut response).is_ok()
                            && response.starts_with("HTTP/")
                        {
                            let status_line = response.lines().next().unwrap_or("");

                            if status_line.contains(" 200 ")
                                || status_line.contains(" 301 ")
                                || status_line.contains(" 302 ")
                                || status_line.contains(" 304 ")
                            {
                                println!("Spring Boot is ready.");
                                return Ok(());
                            }
                        }
                    }
                }
                Err(_) => {
                    // Backend is not ready yet.
                }
            }
        }

        thread::sleep(Duration::from_millis(500));
    }
}

fn stop_backend(state: &BackendState) {
    let mut process = state.process.lock().unwrap();

    if let Some(mut child) = process.take() {
        let pid = child.id();

        println!("Stopping Spring Boot backend (PID {pid})...");

        #[cfg(target_os = "windows")]
        {
            let result = Command::new("taskkill")
                .args([
                    "/PID",
                    &pid.to_string(),
                    "/T",
                    "/F",
                ])
                .output();

            match result {
                Ok(output) if output.status.success() => {
                    println!("Spring Boot backend stopped.");
                }
                Ok(output) => {
                    eprintln!(
                        "taskkill failed with exit code: {:?}",
                        output.status.code()
                    );

                    if !output.stderr.is_empty() {
                        eprintln!(
                            "{}",
                            String::from_utf8_lossy(&output.stderr)
                        );
                    }
                }
                Err(error) => {
                    eprintln!("Failed to execute taskkill: {error}");
                }
            }
        }

        #[cfg(not(target_os = "windows"))]
        {
            if let Err(error) = child.kill() {
                eprintln!("Failed to stop backend: {error}");
            }
        }

        // Reap the child process.
        let _ = child.wait();
    }
}

fn create_main_window(app: &tauri::AppHandle) -> Result<(), String> {
    WebviewWindowBuilder::new(
        app,
        "main",
        WebviewUrl::App("index.html".into()),
    )
    .title("Job Application Tracker")
    .inner_size(1280.0, 800.0)
    .resizable(true)
    .fullscreen(false)
    .build()
    .map_err(|e| format!("Failed to create main window: {e}"))?;

    Ok(())
}

fn serve_splash_file(
    request: &Request<Vec<u8>>,
    resource_dir: &PathBuf,
) -> Response<Vec<u8>> {
    let request_path = request.uri().path();

    let relative_path = request_path
        .trim_start_matches('/')
        .replace('/', "\\");

    // Only allow files from the splash directory.
    let splash_dir = resource_dir.join("splash");

    let file_path = splash_dir.join(&relative_path);

    // Prevent path traversal.
    let canonical_splash_dir = match fs::canonicalize(&splash_dir) {
        Ok(path) => path,
        Err(_) => {
            return Response::builder()
                .status(404)
                .body(b"Splash directory not found".to_vec())
                .unwrap();
        }
    };

    let canonical_file = match fs::canonicalize(&file_path) {
        Ok(path) => path,
        Err(_) => {
            return Response::builder()
                .status(404)
                .body(b"File not found".to_vec())
                .unwrap();
        }
    };

    if !canonical_file.starts_with(&canonical_splash_dir) {
        return Response::builder()
            .status(403)
            .body(b"Forbidden".to_vec())
            .unwrap();
    }

    let contents = match fs::read(&canonical_file) {
        Ok(contents) => contents,
        Err(_) => {
            return Response::builder()
                .status(404)
                .body(b"File not found".to_vec())
                .unwrap();
        }
    };

    let content_type = match canonical_file.extension().and_then(|ext| ext.to_str()) {
        Some("html") => "text/html; charset=utf-8",
        Some("css") => "text/css; charset=utf-8",
        Some("js") => "application/javascript; charset=utf-8",
        Some("png") => "image/png",
        Some("jpg") | Some("jpeg") => "image/jpeg",
        Some("ico") => "image/x-icon",
        Some("svg") => "image/svg+xml",
        _ => "application/octet-stream",
    };

    Response::builder()
        .header("Content-Type", content_type)
        .body(contents)
        .unwrap()
}

fn create_splash_window(app: &tauri::AppHandle) -> Result<(), String> {
    let splash_window = WebviewWindowBuilder::new(
        app,
        "splash",
        WebviewUrl::CustomProtocol(
            "splash://localhost/loading.html"
                .parse()
                .map_err(|e| format!("Invalid splash URL: {e}"))?,
        ),
    )
    .title("Job Application Tracker")
    .inner_size(500.0, 400.0)
    .resizable(false)
    .center()
    .build()
    .map_err(|e| format!("Failed to create splash window: {e}"))?;

    let app_handle = app.clone();

    splash_window.on_window_event(move |event| {
        if let WindowEvent::CloseRequested { .. } = event {
            let splash_state = app_handle.state::<SplashState>();

            if splash_state
                .programmatic_close
                .load(Ordering::SeqCst)
            {
                return;
            }

            println!("Loading splash closed by user. Exiting application...");

            app_handle.exit(0);
        }
    });

    Ok(())
}

fn show_startup_error(
    app: &tauri::AppHandle,
    error: &str,
) -> Result<(), String> {
    println!("Creating error splash...");

    let encoded_message = urlencoding::encode(error);

    let error_url = format!(
        "splash://localhost/error.html?message={}",
        encoded_message
    );

    println!("Error splash URL: {error_url}");

    let url = error_url
        .parse()
        .map_err(|e| format!("Invalid error splash URL: {e}"))?;

    let error_window = WebviewWindowBuilder::new(
        app,
        "error",
        WebviewUrl::CustomProtocol(url),
    )
    .title("Job Application Tracker - Error")
    .inner_size(500.0, 400.0)
    .resizable(false)
    .center()
    .build()
    .map_err(|e| {
        format!("Failed to create error splash: {e}")
    })?;

    println!("Error splash created.");

    let app_handle = app.clone();

    error_window.on_window_event(move |event| {
        if let WindowEvent::CloseRequested { .. } = event {
            println!("Error splash closed. Exiting application...");
            app_handle.exit(0);
        }
    });

    // Close the loading splash programmatically.
    let splash_state = app.state::<SplashState>();

    splash_state
        .programmatic_close
        .store(true, Ordering::SeqCst);

    if let Some(splash) = app.get_webview_window("splash") {
        splash
            .close()
            .map_err(|e| {
                format!("Failed to close loading splash: {e}")
            })?;
    }

    // Keep the error splash visible.
    error_window
        .show()
        .map_err(|e| {
            format!("Failed to show error splash: {e}")
        })?;

    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(BackendState {
            process: Mutex::new(None),
        })
        .manage(SplashState {
            programmatic_close: AtomicBool::new(false),
        })
        .register_uri_scheme_protocol("splash", |context, request| {
            let resource_dir = if cfg!(debug_assertions) {
                PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("resources")
            } else {
                match context.app_handle().path().resource_dir() {
                    Ok(path) => path,
                    Err(_) => {
                        return Response::builder()
                            .status(500)
                            .body(b"Failed to resolve resource directory".to_vec())
                            .unwrap();
                    }
                }
            };

            serve_splash_file(&request, &resource_dir)
        })
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }

            // Create the splash immediately.
            create_splash_window(app.handle())
                .map_err(std::io::Error::other)?;

            // Start Spring Boot.
            let process = start_backend(app.handle())
                .map_err(std::io::Error::other)?;

            let state = app.state::<BackendState>();

            *state.process.lock().unwrap() = Some(process);

            // Don't block Tauri's main thread while waiting for Spring Boot.
            let app_handle = app.handle().clone();

            thread::spawn(move || {
                match wait_for_backend(Duration::from_secs(30)) {
                    Ok(()) => {
                        println!("Spring Boot is ready.");

                        let ui_handle = app_handle.clone();

                        if let Err(error) = app_handle.run_on_main_thread(move || {
                            // Create the React frontend only after
                            // Spring Boot is confirmed ready.
                            if let Err(error) = create_main_window(&ui_handle) {
                                eprintln!("Failed to create main window: {error}");
                                return;
                            }

                            // The splash is being closed by the application,
                            // not by the user.
                            let splash_state = ui_handle.state::<SplashState>();

                            splash_state
                                .programmatic_close
                                .store(true, Ordering::SeqCst);

                            if let Some(splash) =
                                ui_handle.get_webview_window("splash")
                            {
                                if let Err(error) = splash.close() {
                                    eprintln!("Failed to close splash: {error}");
                                }
                            }

                            println!("Main window created and splash closed.");
                        }) {
                            eprintln!("Failed to schedule UI update: {error}");
                        }
                    }
                    
                    Err(error) => {
                        eprintln!("Spring Boot failed to start: {error}");

                        let error_message = error.to_string();
                        let ui_handle = app_handle.clone();

                        if let Err(ui_error) = app_handle.run_on_main_thread(move || {
                            println!("Running startup error UI update on main thread.");

                            if let Some(main_window) =
                                ui_handle.get_webview_window("main")
                            {
                                let _ = main_window.hide();
                            }

                            if let Err(error) =
                                show_startup_error(&ui_handle, &error_message)
                            {
                                eprintln!(
                                    "Failed to show startup error splash: {error}"
                                );
                            } else {
                                println!("Startup error splash requested successfully.");
                            }
                        }) {
                            eprintln!(
                                "Failed to schedule error UI update: {ui_error}"
                            );
                        }

                        let backend_handle = app_handle.clone();

                        thread::spawn(move || {
                            let state = backend_handle.state::<BackendState>();
                            stop_backend(&state);
                        });
                    }
                }
            });

            Ok(())
        })
        .build(tauri::generate_context!())
        .expect("error while building tauri application")
        .run(|app_handle, event| {
            if matches!(event, RunEvent::Exit) {
                let state = app_handle.state::<BackendState>();
                stop_backend(&state);
            }
        });
}