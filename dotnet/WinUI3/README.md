# Job Application Tracker - WinUI 3

Windows desktop implementation of the Job Application Tracker using WinUI 3, Windows App SDK, and .NET 10.

The WinUI 3 application hosts the production React frontend using WebView2 and communicates with the Spring Boot backend running locally. It supports normal self-contained publishing, single-file publishing, and MSIX packaging.

## Tech Stack

* .NET 10
* C#
* WinUI 3
* Windows App SDK
* WebView2
* React + Vite
* Spring Boot 3.5.4
* Java 22
* SQLite
* MSIX
* Inno Setup

## Project Structure

```text
WinUI3/
├── WinUI3.csproj
├── App.xaml
├── App.xaml.cs
├── MainWindow.xaml
├── MainWindow.xaml.cs
├── Assets/
├── Package.appxmanifest
├── orchestrator.sh
└── README.md
```

## How It Works

```text
WinUI 3
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

The WinUI 3 application loads the production React frontend through WebView2.

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

The WinUI 3 application loads:

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

The WinUI 3 application starts the backend using the bundled Java runtime.

## Bundled Java Runtime

A custom Java 22 runtime is generated using `jlink`.

The runtime is stored under:

```text
dotnet/resources/runtime/
```

The runtime allows the WinUI 3 application to launch the Spring Boot backend without requiring Java to be installed separately.

## Development

Start the WinUI 3 application with:

```powershell
dotnet run --project WinUI3\WinUI3.csproj
```

## Build

Build the WinUI 3 application with:

```powershell
dotnet build WinUI3\WinUI3.csproj
```

The build output is generated under:

```text
WinUI3\bin\
```

## Production Publish

### Normal Publish

Publish the WinUI 3 application as a self-contained Windows x64 application:

```powershell
dotnet publish WinUI3\WinUI3.csproj -c Release -r win-x64 --self-contained true -o publish\WinUI3
```

The published application is generated under:

```text
publish\WinUI3\
```

### Single-File Publish

Publish the WinUI 3 application as a single executable:

```powershell
dotnet publish WinUI3\WinUI3.csproj -c Release -r win-x64 --self-contained true -p:SingleFile=true -o publish\WinUI3-SingleFile
```

The single-file output is generated under:

```text
publish\WinUI3-SingleFile\
```

The single-file publish packages the .NET application into the executable.

## MSIX

The WinUI 3 application can also be packaged as a signed MSIX package.

### Build MSIX

From the `dotnet` directory:

```powershell
dotnet build WinUI3\WinUI3.csproj -c Release -p:Platform=x64 -p:GenerateAppxPackageOnBuild=true
````

The generated MSIX package is placed under:

```text
WinUI3\AppPackages\
```

### Build and Sign MSIX

The project also provides a script that builds and signs the MSIX package using the configured development certificate.

From the repository root:

```bash
./dotnet/scripts/build-msix.sh
```

The script:

1. Builds the WinUI 3 MSIX package.
2. Locates the generated `.msix` file.
3. Signs it using the configured `.pfx` certificate.
4. Verifies the package signature.

The signed package is generated under:

```text
dotnet/publish/WinUI3-MSIX/
```

The signing certificate password is read from the `MSIX_CERT_PASSWORD` environment variable.

## Installer

The WinUI 3 application has two Inno Setup installer variants:

* Normal published application
* Single-file published application

The installer uses the same Inno Setup script for both variants and selects the appropriate published output through the `BuildType` parameter.

See the [Installer README](../installer/README.md) for installer configuration and commands.

## Commands

| Command                         | Description                                            |
| ------------------------------- | ------------------------------------------------------ |
| `./orchestrator.sh start`       | Start the WinUI 3 application                          |
| `./orchestrator.sh build`       | Build the WinUI 3 application                          |
| `./orchestrator.sh publish`     | Publish the normal WinUI 3 application                 |
| `./orchestrator.sh single-file` | Publish the WinUI 3 application as a single executable |
| `./orchestrator.sh clean`       | Remove WinUI 3 build artifacts                         |
| `./orchestrator.sh help`        | Show available commands                                |
