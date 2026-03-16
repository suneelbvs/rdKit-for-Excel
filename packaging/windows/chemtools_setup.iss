; chemtools_setup.iss — Inno Setup script for ChemToolsSetup.exe
; Download Inno Setup 6: https://jrsoftware.org/isdl.php
; Compile: ISCC.exe chemtools_setup.iss

#define MyAppName "Atomicas ChemTools"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Atomicas"
#define MyAppURL "https://atomicas.com"
#define MyAppExeName "chemtools-server.exe"
#define SourceDir "..\..\release\windows\ChemToolsSetup"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={localappdata}\ChemTools
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\release\windows
OutputBaseFilename=ChemToolsSetup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "startup"; Description: "Start ChemTools server automatically with Windows"; GroupDescription: "Additional options:"; Flags: checked

[Files]
Source: "{#SourceDir}\chemtools-server\*"; DestDir: "{app}\chemtools-server"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#SourceDir}\manifest.xml"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "ChemToolsServer"; ValueData: """{app}\chemtools-server\{#MyAppExeName}"""; Tasks: startup

[Run]
; Register manifest with Excel (both common WEF locations)
Filename: "{cmd}"; Parameters: "/c mkdir ""{userappdata}\Microsoft\Excel\XLSTART"" & copy /y ""{app}\manifest.xml"" ""{userappdata}\Microsoft\Excel\XLSTART\ChemTools.xml"""; Flags: runhidden
Filename: "{cmd}"; Parameters: "/c mkdir ""{localappdata}\Microsoft\Office\16.0\Wef"" & copy /y ""{app}\manifest.xml"" ""{localappdata}\Microsoft\Office\16.0\Wef\ChemTools.xml"""; Flags: runhidden
; Start server
Filename: "{app}\chemtools-server\{#MyAppExeName}"; Description: "Start ChemTools server"; Flags: nowait postinstall skipifsilent runhidden
; Open Excel
Filename: "excel.exe"; Description: "Open Microsoft Excel"; Flags: nowait postinstall skipifsilent shellexec

[UninstallRun]
Filename: "{cmd}"; Parameters: "/c taskkill /f /im chemtools-server.exe"; Flags: runhidden

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
