# Job Application Tracker - WPF

Windows desktop implementation of the Job Application Tracker using WPF and .NET 10.

The WPF application hosts the production React frontend using WebView2 and communicates with the Spring Boot backend running locally. The application uses the shared .NET project for common functionality.

## Tech Stack

* .NET 10
* C#
* WPF
* WebView2
* React + Vite
* Spring Boot 3.5.4
* Java 22
* SQLite

## Project Structure

```text
WPF/
├── WPF.csproj
├── App.xaml
├── App.xaml.cs
├── MainWindow.xaml
├── MainWindow.xaml.cs
├── orchestrator.sh
└── README.md
```

## How It Works

```text
WPF
 │
 ├── WebView2
 │      │
 │      └── React Production Build
 │
 └── Spring Boot Backend
        │
        ├── Bundled Java 22 Runtime
        │
        └── SQLite Database
```

The WPF application loads the production React frontend through WebView2.

The frontend communicates with the Spring Boot backend through:

```text
http://localhost:8080/api
```

The Spring Boot backend runs locally on:

```text
localhost:8080
```

## Frontend

The production frontend is prepared from:

```text
workspace/Job-Application-Tracker-UI/dist/
```

The .NET orchestrator copies the frontend production bundle to:

```text
dotnet/resources/frontend/dist/
```

The WPF application loads the compiled:

```text
resources/frontend/dist/index.html
```

## Backend

The Spring Boot backend is packaged as a JAR under:

```text
workspace/Job-Application-Tracker/target/
```

The .NET preparation process copies the JAR to:

```text
dotnet/resources/backend/
```

The WPF application starts the backend using the bundled Java runtime.

## Bundled Java Runtime

A custom Java 22 runtime is generated using `jlink`.

The runtime is stored under:

```text
dotnet/resources/runtime/
```

The runtime allows the WPF application to launch the Spring Boot backend without requiring Java to be installed separately.

Yes. Keep the **WPF/WinUI 3 READMEs focused on the actual .NET commands**, while the orchestrator commands can remain documented at the `dotnet/README.md` level.

## Development

Start the WPF application with:

```powershell
dotnet run --project WPF\WPF.csproj
```

## Build

Build the WPF application with:

```powershell
dotnet build WPF\WPF.csproj
```

The build output is generated under:

```text
WPF\bin\
```

## Production Publish

Publish the WPF application as a self-contained Windows x64 application:

```powershell
dotnet publish WPF\WPF.csproj -c Release -r win-x64 --self-contained true -o publish\WPF
```

The published application is generated under:

```text
publish\WPF\
```

The published output contains the WPF executable and the files required to run the application.

## Installer

The WPF installer is handled separately by the .NET installer orchestrator.

From the `dotnet/installer` directory:

```bash
./orchestrator.sh wpf
```

The installer packages the already-published WPF application and is generated under:

```text
dotnet/publish/installers/
```

See the [Installer README](../installer/README.md) for installer configuration and details.

## Commands

| Command                     | Description                 |
| --------------------------- | --------------------------- |
| `./orchestrator.sh start`   | Start the WPF application   |
| `./orchestrator.sh build`   | Build the WPF application   |
| `./orchestrator.sh publish` | Publish the WPF application |
| `./orchestrator.sh clean`   | Remove WPF build artifacts  |
| `./orchestrator.sh help`    | Show available commands     |
