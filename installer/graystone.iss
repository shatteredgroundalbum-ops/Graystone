; Inno Setup script for Graystone — builds Graystone-Setup.exe
; Compile with: iscc installer\graystone.iss   (after `flutter build windows --release`)
; Get Inno Setup at https://jrsoftware.org/isdl.php

#define MyAppName "Graystone"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Graystone"
#define MyAppExeName "graystone.exe"

[Setup]
AppId={{4BB0C6BE-DC5E-49E2-905D-B31629D6BA71}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Graystone
DefaultGroupName=Graystone
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=Graystone-Setup
SetupIconFile=..\assets\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Everything Flutter emits for the release build.
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Graystone"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall Graystone"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Graystone"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,Graystone}"; Flags: nowait postinstall skipifsilent
