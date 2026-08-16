#define MyAppName "Job Application Tracker"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Sahil Vartak"
#define MyAppExeName "JobApplicationTracker-Dotnet.exe"

[Setup]
AppId={{9836aed7-dcbe-4193-8a27-2226111bf104}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}

DefaultDirName={autopf}\JobApplicationTracker-Dotnet-WPF
DefaultGroupName={#MyAppName}

OutputDir=..\..\publish\installers
OutputBaseFilename=JobApplicationTracker-WPF-Setup

SetupIconFile=..\..\resources\icons\icon.ico

DisableProgramGroupPage=yes

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

Compression=lzma
SolidCompression=yes
WizardStyle=modern

UninstallDisplayName={#MyAppName}
Uninstallable=yes

[Files]
Source: "..\..\publish\WPF\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Tasks]
Name: "startmenu"; Description: "Create a Start Menu shortcut"; GroupDescription: "Shortcuts:"
Name: "desktop"; Description: "Create a Desktop shortcut"; GroupDescription: "Shortcuts:"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startmenu
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktop

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"