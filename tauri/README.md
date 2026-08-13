# Job Application Tracker - Tauri

Windows desktop implementation of the Job Application Tracker using Tauri.

Tauri combines the React frontend and Spring Boot backend into a Windows application. A custom Java 22 runtime is bundled so end users do not need Java, Maven, Node.js, or Docker.

## Tech Stack

- Tauri 2.11.3
- Rust
- Cargo
- TypeScript
- React + Vite
- Spring Boot 3.5.4
- Java 22
- SQLite
- NSIS

## Project Structure

```text
tauri/
├── orchestrator.sh
└── src-tauri/
    ├── src/
    │   ├── lib.rs
    │   └── main.rs
    ├── resources/
    │   ├── backend/
    │   │   └── job-application-tracker-1.0.0.jar
    │   ├── runtime/
    │   │   └── bin/
    │   │       ├── java.exe
    │   │       └── javaw.exe
    │   └── splash/
    │       └── icon.ico
    ├── icons/
    │   └── icon.ico
    ├── Cargo.toml
    ├── Cargo.lock
    └── tauri.conf.json
```

## How It Works

```text
Tauri
   ├── React Frontend
   │       └── Tauri API proxy
   │               └── http://127.0.0.1:8080/api
   │
   └── Spring Boot Backend
           ├── Bundled Java 22
           └── SQLite Database
```

Tauri creates a loading splash window, starts the bundled Java runtime, launches the Spring Boot backend, waits for it to become available, and then creates the main React window.

The frontend is served from Tauri's packaged application resources in production. A Rust-side API proxy forwards `/api` requests to the local Spring Boot backend, allowing the existing React frontend to remain unchanged.

## Frontend

The React frontend is built separately and produces:

```text
workspace/Job-Application-Tracker-UI/dist/
```

Tauri packages the compiled `dist` directory as the application's frontend.

The frontend communicates with the backend through:

```text
/api
```

The Tauri application proxies these requests to:

```text
http://127.0.0.1:8080/api
```

This allows the existing React API calls to work without changing the React project specifically for Tauri.

During development, Vite runs at:

```text
http://localhost:5173
```

and Tauri loads the Vite development server.

## Backend

The Spring Boot application is packaged as:

```text
workspace/Job-Application-Tracker/target/job-application-tracker-1.0.0.jar
```

The Tauri application starts this JAR on:

```text
localhost:8080
```

The packaged application contains the JAR under:

```text
resources/backend/
```

## Bundled Java Runtime

A custom Java 22 runtime is created using `jlink`.

Development uses:

```text
resources/runtime/bin/java.exe
```

The packaged application uses:

```text
resources/runtime/bin/javaw.exe
```

`java.exe` is used during development so Spring Boot logs remain visible. `javaw.exe` is used in the release application so the backend runs without opening a console window.

The runtime is created with:

```powershell
& "C:\Program Files\Java\jdk-22\bin\jlink.exe" `
  --module-path "C:\Program Files\Java\jdk-22\jmods" `
  --add-modules java.base,java.sql,java.naming,java.management,java.instrument,java.desktop,java.security.jgss,jdk.crypto.ec,jdk.unsupported `
  --output ".\tauri\src-tauri\resources\runtime" `
  --strip-debug `
  --no-man-pages `
  --no-header-files `
  --compress=2
```

This allows the application to run without requiring Java to be installed on the user's machine.

The runtime includes the Java modules required by Spring Boot and embedded Tomcat, including `java.security.jgss`.

## Application Data

The SQLite database is stored separately from the application:

```text
%APPDATA%\com.sahilvartak.jobapplicationtracker.tauri\data\job_tracker.db
```

This keeps user data separate from the installed application files, so updating the application does not replace the database.

## Development

From the `tauri` directory, the application can be started through the Tauri orchestrator:

```bash
./orchestrator.sh start
```

The orchestrator verifies the required tools, creates the custom Java runtime if necessary, and starts:

```bash
cargo tauri dev
```

Tauri starts the Vite development server through the configured `beforeDevCommand`.

The development application uses `java.exe`, so Spring Boot console output remains available for debugging.

## Production

Create the Windows installer with:

```bash
./orchestrator.sh package
```

The orchestrator builds the React frontend, creates the custom Java runtime if necessary, and runs:

```bash
cargo tauri build
```

The generated files are located under:

```text
src-tauri/target/release/bundle/
```

Depending on the configured Tauri bundle targets, Windows installer packages such as NSIS installers are generated there.

The unpacked release application is available under:

```text
src-tauri/target/release/
```

## NSIS Installer

The Tauri NSIS bundle provides a traditional Windows installer for the application.

The installer packages:

- Tauri desktop application
- Production React frontend
- Spring Boot JAR
- Custom Java 22 runtime
- Splash resources
- Application icon

The application data is stored separately under `%APPDATA%`, so user data is not stored inside the installation directory.

## Custom Icon

The Tauri application icon is configured through:

```text
src-tauri/tauri.conf.json
```

with:

```json
"icon": [
  "icons/icon.ico"
]
```

The splash window uses the application icon from:

```text
src-tauri/resources/splash/icon.ico
```

A multi-resolution `.ico` containing high-resolution sizes is recommended to keep the Windows application and splash icons sharp across different display sizes.

## Build Commands

The Tauri-specific orchestrator supports:

```bash
./orchestrator.sh start
./orchestrator.sh package
./orchestrator.sh clean
```

The root project orchestrator can also call these commands through the Tauri orchestrator.
