# Job Application Tracker - .NET

Windows desktop implementation of the Job Application Tracker using .NET, with WPF and WinUI 3 desktop hosts.

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

## Project Structure

```text
dotnet/
├── Shared/
│   └── Shared.csproj
├── WPF/
│   └── WPF.csproj
├── WinUI3/
│   └── WinUI3.csproj
└── JobApplicationTracker.slnx
```

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

### Create the Solution

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

### Verify WPF Build

```powershell
dotnet build WPF\WPF.csproj
```

### Create WinUI 3 Application

```powershell
dotnet new winui -n WinUI3 -o WinUI3
dotnet sln JobApplicationTracker.slnx add WinUI3\WinUI3.csproj
```

### Verify WinUI 3 Build

```powershell
dotnet build WinUI3\WinUI3.csproj
```
