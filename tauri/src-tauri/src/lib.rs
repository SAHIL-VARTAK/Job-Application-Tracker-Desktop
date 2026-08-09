use std::{
    fs,
    io::{Read, Write},
    net::{TcpStream, ToSocketAddrs},
    path::PathBuf,
    process::{Child, Command},
    sync::Mutex,
    thread,
    time::{Duration, Instant},
};

use tauri::{Manager, RunEvent};

struct BackendState {
    process: Mutex<Option<Child>>,
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
        println!("Stopping Spring Boot backend...");

        if let Err(error) = child.kill() {
            eprintln!("Failed to stop backend: {error}");
        }

        let _ = child.wait();
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(BackendState {
            process: Mutex::new(None),
        })
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }

            let process = start_backend(app.handle())
                .map_err(std::io::Error::other)?;

            let state = app.state::<BackendState>();

            *state.process.lock().unwrap() = Some(process);

            if let Err(error) = wait_for_backend(Duration::from_secs(30)) {
                stop_backend(&state);

                return Err(std::io::Error::other(error).into());
            }

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