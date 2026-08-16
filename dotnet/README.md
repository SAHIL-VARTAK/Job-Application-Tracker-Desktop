# Job Application Tracker - .NET

Windows desktop implementation of the Job Application Tracker using .NET, with WPF and WinUI 3 desktop hosts.

The .NET implementation reuses the existing React frontend and Spring Boot backend. A custom Java 22 runtime is generated with `jlink` and bundled with the desktop applications so end users do not need Java installed separately.

## Tech Stack

* .NET 10
* C#
* WPF
* WinUI 3
* Windows App SDK
* WebView2
* React + Vite
* Spring Boot 3.5.4
* Java 22
* SQLite
* Inno Setup

## Project Structure

```text
dotnet/
├── Shared/
│   └── Shared.csproj
├── WPF/
│   ├── WPF.csproj
│   ├── README.md
│   └── orchestrator.sh
├── WinUI3/
│   ├── WinUI3.csproj
│   ├── README.md
│   └── orchestrator.sh
├── installer/
│   ├── WPF/
│   ├── WinUI3/
│   ├── README.md
│   └── orchestrator.sh
├── resources/
│   ├── frontend/
│   │   └── dist/
│   ├── backend/
│   │   └── *.jar
│   ├── runtime/
│   ├── splash/
│   │   ├── error.html
│   │   └── loading.html
│   ├── icons/
│   │   └── icon.ico
├── scripts/
├── orchestrator.sh
└── JobApplicationTracker.slnx
```

The `resources/` and `publish/` directories contain generated build artifacts and are not required as source files.

## How It Works

```text
.NET Desktop Application
        │
        ├── WPF / WinUI 3
        │
        ├── React Frontend
        │       │
        │       └── http://localhost:8080/api
        │
        └── Spring Boot Backend
                │
                ├── Bundled Java 22 Runtime
                │
                └── SQLite Database
```

The .NET orchestrator prepares the production frontend, Spring Boot backend JAR, and custom Java runtime under `resources/`.

The WPF and WinUI 3 applications then use these prepared resources when running, building, or publishing.

## Frontend

The React frontend is built separately and produces:

```text
workspace/Job-Application-Tracker-UI/dist/
```

The .NET preparation process copies the production bundle to:

```text
dotnet/resources/frontend/dist/
```

The desktop applications load the compiled `dist/index.html` through WebView2.

The frontend communicates with the backend through:

```text
http://localhost:8080/api
```

## Backend

The Spring Boot application is packaged as a JAR under:

```text
workspace/Job-Application-Tracker/target/
```

The .NET preparation process copies the JAR to:

```text
dotnet/resources/backend/
```

The desktop applications launch the Spring Boot backend locally on:

```text
localhost:8080
```

## Bundled Java Runtime

A custom Java 22 runtime is created using `jlink`.

The runtime is generated under:

```text
dotnet/resources/runtime/
```

The runtime contains the Java modules required to run the Spring Boot backend without requiring a separate Java installation.

The runtime is generated from the JDK configured through `JAVA_HOME`.

## Setup

### Verify .NET Installation

```powershell
dotnet --version
dotnet --list-sdks
dotnet --list-runtimes
```

### Check Available Templates

```powershell
dotnet new list
```

### Install WinUI 3 Templates

```powershell
dotnet new install Microsoft.WindowsAppSDK.WinUI.CSharp.Templates
```

### Navigate to the .NET Directory

```powershell
cd dotnet
```

## Create the Solution

```powershell
dotnet new sln -n JobApplicationTracker
```

### Create Shared Class Library

```powershell
dotnet new classlib -n Shared -o Shared --framework net10.0
dotnet sln JobApplicationTracker.slnx add Shared\Shared.csproj
```

### Create WPF Application

```powershell
dotnet new wpf -n WPF -o WPF --framework net10.0
dotnet sln JobApplicationTracker.slnx add WPF\WPF.csproj
```

### Create WinUI 3 Application

```powershell
dotnet new winui -n WinUI3 -o WinUI3
dotnet sln JobApplicationTracker.slnx add WinUI3\WinUI3.csproj
```

### Add Shared Project References

```powershell
dotnet add WPF\WPF.csproj reference Shared\Shared.csproj
dotnet add WinUI3\WinUI3.csproj reference Shared\Shared.csproj
```

### Add WebView2

```powershell
dotnet add WPF\WPF.csproj package Microsoft.Web.WebView2
dotnet add WinUI3\WinUI3.csproj package Microsoft.Web.WebView2
```

### Verify the Solution

```powershell
dotnet build JobApplicationTracker.slnx
```

### Verify Project References

```powershell
dotnet list WPF\WPF.csproj reference
dotnet list WinUI3\WinUI3.csproj reference
```

### Verify WebView2 Packages

```powershell
dotnet list WPF\WPF.csproj package
dotnet list WinUI3\WinUI3.csproj package
```

## Orchestration

The .NET orchestrator provides a single entry point for preparing resources, running applications, building, publishing, creating installers, and cleaning generated artifacts.

| Command                              | Description                                           |
| ------------------------------------ | ----------------------------------------------------- |
| `./orchestrator.sh prepare`          | Prepare frontend, backend, and Java runtime resources |
| `./orchestrator.sh start-wpf`        | Start WPF                                             |
| `./orchestrator.sh start-winui3`     | Start WinUI 3                                         |
| `./orchestrator.sh build-wpf`        | Build WPF                                             |
| `./orchestrator.sh build-winui3`     | Build WinUI 3                                         |
| `./orchestrator.sh publish-wpf`      | Publish WPF                                           |
| `./orchestrator.sh publish-winui3`   | Publish WinUI 3                                       |
| `./orchestrator.sh publish-single`   | Publish WinUI 3 as a single executable                |
| `./orchestrator.sh installer-wpf`    | Create the WPF installer                              |
| `./orchestrator.sh installer-winui3` | Create the WinUI 3 installer                          |
| `./orchestrator.sh installer-single` | Create the WinUI 3 single-file installer              |
| `./orchestrator.sh installers`       | Create all .NET installers                            |
| `./orchestrator.sh clean`            | Remove .NET build artifacts                           |
| `./orchestrator.sh help`             | Show available commands                               |

## WPF

The WPF implementation is documented separately.

See [WPF README](WPF/README.md) for WPF-specific development, build, publish, and application details.

## WinUI 3

The WinUI 3 implementation is documented separately.

See [WinUI 3 README](WinUI3/README.md) for WinUI 3-specific development, publishing, single-file publishing, and MSIX details.

## Installers

The Inno Setup installers are documented separately.

See [Installer README](installer/README.md) for installer configuration, publishing requirements, and Inno Setup commands.
