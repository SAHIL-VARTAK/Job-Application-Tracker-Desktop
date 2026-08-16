# Job Application Tracker - .NET Installers

Windows installers for the WPF and WinUI 3 desktop applications using Inno Setup.

The installer layer packages the already-published .NET applications. It does not build or publish the WPF or WinUI 3 applications.

## Tech Stack

* Inno Setup 6
* Inno Setup Command-Line Compiler (`ISCC`)
* WPF
* WinUI 3
* .NET 10

## Project Structure

```text
installer/
├── WPF/
│   └── WPF.iss
├── WinUI3/
│   └── WinUI3.iss
├── orchestrator.sh
└── README.md
```

## Prerequisites

Install Inno Setup and make sure `ISCC.exe` is available in `PATH`.

Verify the installation:

```powershell
iscc /?
```

The compiler should display the Inno Setup command-line help.

## WPF Installer

The WPF installer packages the published WPF application.

First publish the WPF application:

```powershell
dotnet publish WPF\WPF.csproj -c Release -r win-x64 --self-contained true -o publish\WPF
```

Then compile the installer:

```powershell
iscc installer\WPF\WPF.iss
```

The installer is generated under:

```text
publish\installers\
```

## WinUI 3 Installer

The WinUI 3 installer uses the same Inno Setup script for both the normal and single-file versions.

### Normal Version

First publish the normal WinUI 3 application:

```powershell
dotnet publish WinUI3\WinUI3.csproj -c Release -r win-x64 --self-contained true -o publish\WinUI3
```

Then compile the installer:

```powershell
iscc /DBuildType=Normal installer\WinUI3\WinUI3.iss
```

The installer is generated under:

```text
publish\installers\
```

### Single-File Version

First publish the single-file WinUI 3 application:

```powershell
dotnet publish WinUI3\WinUI3.csproj -c Release -r win-x64 --self-contained true -p:SingleFile=true -o publish\WinUI3-SingleFile
```

Then compile the installer:

```powershell
iscc /DBuildType=SingleFile installer\WinUI3\WinUI3.iss
```

The same `WinUI3.iss` script selects the appropriate published output using the `BuildType` preprocessor definition.

## Installer Options

The installers allow the user to choose whether to create:

* Start Menu shortcut
* Desktop shortcut

The installation directory can also be changed by the user.

The default installation directories are application-specific:

```text
JobApplicationTracker-Dotnet-WPF
JobApplicationTracker-Dotnet-WinUI3
JobApplicationTracker-Dotnet-WinUI3-MSIX
```

## Output

All Inno Setup installers are generated under:

```text
publish\installers\
```

The installer filenames identify the desktop host and packaging type.

## Orchestration

The installer orchestrator provides commands for creating the installers without repeating the publish step.

| Command                           | Description                                         |
| --------------------------------- | --------------------------------------------------- |
| `./orchestrator.sh wpf`           | Create WPF installer from existing published output |
| `./orchestrator.sh winui3`        | Create WinUI 3 normal installer                     |
| `./orchestrator.sh winui3-single` | Create WinUI 3 single-file installer                |
| `./orchestrator.sh all`           | Create all .NET installers                          |
| `./orchestrator.sh clean`         | Remove installer output                             |
| `./orchestrator.sh help`          | Show available commands                             |

The installer orchestrator expects the corresponding application to have already been published.
