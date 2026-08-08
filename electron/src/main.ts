import { app, BrowserWindow } from "electron";
import path from "node:path";
import fs from "node:fs";
import { spawn, ChildProcess, spawnSync } from "node:child_process";
import http from "node:http";

let backendProcess: ChildProcess | null = null;

function getResourcePath(...segments: string[]): string {
    if (app.isPackaged) {
        return path.join(process.resourcesPath, ...segments);
    }

    return path.resolve(app.getAppPath(), "..", ...segments);
}

function findBackendJar(): string {
    const backendDir = app.isPackaged
        ? path.join(process.resourcesPath, "backend")
        : path.resolve(
              app.getAppPath(),
              "../workspace/Job-Application-Tracker/target"
          );

    const jar = fs
        .readdirSync(backendDir)
        .find(
            (file) =>
                file.endsWith(".jar") &&
                !file.endsWith("-sources.jar") &&
                !file.endsWith("-javadoc.jar")
        );

    if (!jar) {
        throw new Error(`No backend JAR found in: ${backendDir}`);
    }

    return path.join(backendDir, jar);
}

function startBackend(): void {
    const jarPath = findBackendJar();
    const backendDir = path.dirname(jarPath);

    const dataDir = path.join(
        app.getPath("userData"),
        "data"
    );

    fs.mkdirSync(dataDir, { recursive: true });

    const databasePath = path.join(
        dataDir,
        "job_tracker.db"
    );

    const javaPath = app.isPackaged
        ? path.join(
              process.resourcesPath,
              "runtime",
              "bin",
              "java.exe"
          )
        : path.resolve(
              app.getAppPath(),
              "runtime",
              "bin",
              "java.exe"
          );

    console.log("Starting backend:", jarPath);
    console.log("Java runtime:", javaPath);
    console.log("Application data:", dataDir);
    console.log("Database:", databasePath);

    backendProcess = spawn(
        javaPath,
        [
            "-jar",
            jarPath,
            `--spring.datasource.url=jdbc:sqlite:${databasePath}`,
        ],
        {
            cwd: backendDir,
            stdio: "inherit",
        }
    );

    backendProcess.on("error", (error) => {
        console.error("Failed to start backend:", error);
    });

    backendProcess.on("exit", (code, signal) => {
        console.log(
            `Backend exited. code=${code}, signal=${signal}`
        );

        backendProcess = null;
    });
}

function waitForBackend(
    url: string,
    timeoutMs = 30000
): Promise<void> {
    return new Promise((resolve, reject) => {
        const startTime = Date.now();

        const check = () => {
            const request = http.get(url, (response) => {
                response.resume();

                resolve();
            });

            request.on("error", () => {
                if (Date.now() - startTime >= timeoutMs) {
                    reject(
                        new Error(
                            `Backend did not become available within ${timeoutMs / 1000} seconds.`
                        )
                    );
                    return;
                }

                setTimeout(check, 500);
            });

            request.setTimeout(1000, () => {
                request.destroy();
            });
        };

        check();
    });
}

function createWindow(): void {
    const window = new BrowserWindow({
        width: 1280,
        height: 800,
        webPreferences: {
            contextIsolation: true,
            nodeIntegration: false,
        },
    });

    const frontendPath = app.isPackaged
        ? path.join(
            process.resourcesPath,
            "frontend",
            "dist",
            "index.html"
        )
        : path.resolve(
            app.getAppPath(),
            "../workspace/Job-Application-Tracker-UI/dist/index.html"
        );

    console.log("Loading frontend:", frontendPath);

    window.loadFile(frontendPath);
}

async function startApplication(): Promise<void> {
    startBackend();

    console.log("Waiting for Spring Boot...");

    await waitForBackend(
        "http://localhost:8080/swagger-ui/index.html"
    );

    console.log("Spring Boot is ready.");

    createWindow();
}

function stopBackend(): void {
    if (!backendProcess?.pid) {
        return;
    }

    const pid = backendProcess.pid;

    console.log(`Stopping Spring Boot (PID ${pid})...`);

    if (process.platform === "win32") {
        spawnSync("taskkill", ["/pid", pid.toString(), "/T", "/F"]);
    } else {
        backendProcess.kill("SIGTERM");
    }

    backendProcess = null;
}

app.whenReady().then(async () => {
    try {
        await startApplication();

        app.on("activate", () => {
            if (BrowserWindow.getAllWindows().length === 0) {
                createWindow();
            }
        });
    } catch (error) {
        console.error("Failed to start application:", error);

        stopBackend();

        app.quit();
    }
});

app.on("window-all-closed", () => {
    if (process.platform !== "darwin") {
        app.quit();
    }
});

app.on("will-quit", () => {
    stopBackend();
});