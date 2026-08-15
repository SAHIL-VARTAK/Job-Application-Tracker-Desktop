#define MyAppName "Job Application Tracker"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Sahil Vartak"
#define MyAppExeName "JobApplicationTracker-Dotnet.exe"

; Default build type when compiling from the Inno Setup GUI.
; Change this to "Normal" or "SingleFile".
#ifndef BuildType
  #define BuildType "SingleFile"
#endif

#if BuildType == "SingleFile"
  #define PublishDir "..\..\publish\WinUI3-SingleFile"
  #define OutputName "JobApplicationTracker-WinUI3-SingleFile-Setup"
#else
  #define PublishDir "..\..\publish\WinUI3"
  #define OutputName "JobApplicationTracker-WinUI3-Setup"
#endif

[Setup]
AppId={{36edb761-b5f4-4a7c-9cc9-abb493177e22}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}

DefaultDirName={autopf}\JobApplicationTracker-Dotnet-WinUI3
DefaultGroupName={#MyAppName}

SetupIconFile=..\..\resources\icons\icon.ico

DisableProgramGroupPage=yes

OutputDir=..\..\publish\installers
OutputBaseFilename={#OutputName}

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

Compression=lzma
SolidCompression=yes
WizardStyle=modern

UninstallDisplayName={#MyAppName}
Uninstallable=yes

[Files]
#if BuildType == "SingleFile"
Source: "{#PublishDir}\JobApplicationTracker-Dotnet.exe"; DestDir: "{app}"; Flags: ignoreversion
#else
Source: "{#PublishDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
#endif

[Tasks]
Name: "startmenu"; Description: "Create a Start Menu shortcut"; GroupDescription: "Shortcuts:"
Name: "desktop"; Description: "Create a Desktop shortcut"; GroupDescription: "Shortcuts:"

[Icons]
Name: "{autoprograms}\{#MyAppName} (WinUI 3)"; Filename: "{app}\{#MyAppExeName}"; Tasks: startmenu
Name: "{autodesktop}\{#MyAppName} (WinUI 3)"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktop

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName} (WinUI 3)"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"