# Job Application Tracker - Electron

Windows desktop implementation of the Job Application Tracker using Electron.

Electron combines the React frontend and Spring Boot backend into a Windows application. A custom Java 22 runtime is bundled so end users do not need Java, Maven, Node.js, or Docker.

## Tech Stack

- Electron 43.3.0
- Electron Builder 26.15.3
- TypeScript
- React + Vite
- Spring Boot 3.5.4
- Java 22
- SQLite
- NSIS

## Project Structure

```text
electron/
├── src/
│   └── main.ts
├── runtime/
│   └── bin/
│       └── java.exe
├── electron-dist/
│   └── electron-v43.3.0-win32-x64.zip
├── package.json
├── tsconfig.json
└── release/
```

## How It Works

```text
Electron
   │
   ├── React Frontend
   │       │
   │       └── http://localhost:8080/api
   │
   └── Spring Boot Backend
           │
           ├── Bundled Java 22
           │
           └── SQLite Database
```

Electron starts the bundled Java runtime, launches the Spring Boot backend, waits for it to become available, and then loads the production React frontend.

## Frontend

The React frontend is built separately and produces:

```text
workspace/Job-Application-Tracker-UI/dist/
```

Electron loads the compiled `dist/index.html`.

The frontend communicates with the backend through:

```text
http://localhost:8080/api
```

This is required because the Electron application loads the frontend from the local filesystem rather than the Vite development server.

## Backend

The Spring Boot application is packaged as:

```text
workspace/Job-Application-Tracker/target/job-application-tracker-1.0.0.jar
```

Electron starts this JAR on:

```text
localhost:8080
```

The packaged application contains the JAR under:

```text
resources/backend/
```

## Bundled Java Runtime

A custom Java 22 runtime was created using `jlink`.

Development runtime:

```text
runtime/bin/java.exe
```

Packaged runtime:

```text
resources/runtime/bin/java.exe
```

The runtime was created with:

```powershell
& "C:\Program Files\Java\jdk-22\bin\jlink.exe" `
  --module-path "C:\Program Files\Java\jdk-22\jmods" `
  --add-modules java.base,java.sql,java.naming,java.management,java.instrument,java.desktop,java.security.jgss,jdk.crypto.ec,jdk.unsupported `
  --output ".\electron\runtime" `
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
%APPDATA%\job-application-tracker-electron\data\job_tracker.db
```

This keeps user data separate from the installed application files, so updating the application does not replace the database.

## Development

From the `electron` directory, install dependencies once:

```bash
npm install
```

Then start the desktop application:

```bash
npm start
```

`npm start` builds the Electron TypeScript source and launches the application.

## Production

Create the Windows installer with:

```bash
npm run package
```

The installer is generated at:

```text
release/Job Application Tracker - Electron Setup 1.0.0.exe
```

The unpacked application is also available at:

```text
release/win-unpacked/
```

## NSIS Installer

The installer can be configured as a traditional installation wizard:

```json
"nsis": {
  "oneClick": false,
  "allowToChangeInstallationDirectory": true,
  "createDesktopShortcut": true,
  "createStartMenuShortcut": true,
  "runAfterFinish": true,
  "deleteAppDataOnUninstall": false
}
```

This allows the user to choose the installation directory, creates shortcuts, optionally launches the application after installation, and preserves application data during uninstall.

## Custom Icon

Add the Windows icon at:

```text
build/icon.ico
```

Then configure:

```json
"win": {
  "target": "nsis",
  "icon": "build/icon.ico"
}
```

A multi-resolution `.ico` containing sizes up to `256×256` is recommended.
