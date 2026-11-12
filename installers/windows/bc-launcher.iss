; BC Launcher's Windows installer (Inno Setup 6).
;
; Per user, without admin rights. It is also how the launcher updates itself:
; it downloads this installer (zipped, checked against the signed update feed)
; and runs it with /SILENT ... /RELAUNCH=1, which installs over the old version
; and opens the launcher again. Build `flutter build windows --release` first,
; then:
;
;   iscc /DAppVersion=1.2.0 installers\windows\bc-launcher.iss
;
; The installer is written to dist\installers\.

#ifndef AppVersion
  #error Pass the version: iscc /DAppVersion=x.y.z installers\windows\bc-launcher.iss
#endif

#define Root "..\.."
#define AppName "BC Launcher"
#define AppExe "bc_launcher.exe"
; Where the launcher keeps its data: path_provider's support folder, from
; CompanyName and ProductName in windows\runner\Runner.rc.
#define DataFolder "{userappdata}\com.bcr\bc_launcher"

[Setup]
; Never change it: it is how Windows knows an installation is this app (the
; one the launcher's first installers used, so they are updated in place).
AppId={{5F3FCBEA-D946-4499-9D41-F35BB25D6721}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Boludo´s Company
AppPublisherURL=https://github.com/elRubenof/bc-launcher
AppSupportURL=https://github.com/elRubenof/bc-launcher/issues
AppUpdatesURL=https://github.com/elRubenof/bc-launcher/releases
DefaultDirName={localappdata}\Programs\{#AppName}
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile={#Root}\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
OutputDir={#Root}\dist\installers
OutputBaseFilename=BC-Launcher-Installer
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ShowLanguageDialog=auto

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
spanish.DeleteData=¿Borrar también tus datos de BC Launcher (organizaciones, instancias y mundos)?%n%nSi los conservas, volverás a tenerlos al instalarlo de nuevo.
english.DeleteData=Also delete your BC Launcher data (organizations, instances and worlds)?%n%nIf you keep it, you'll have it back when you install it again.

[Tasks]
; Checked by default.
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#Root}\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; bclauncher:// links work right after installing. The launcher registers
; the same keys on every start.
Root: HKCU; Subkey: "Software\Classes\bclauncher"; ValueType: string; ValueName: ""; ValueData: "URL:BC Launcher"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\bclauncher"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\bclauncher\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
; The launcher's own update: open it again once installed.
Filename: "{app}\{#AppExe}"; Flags: nowait; Check: Relaunch

[UninstallDelete]
; Updates may add files the installer didn't put there.
Type: filesandordirs; Name: "{app}"

[Code]
// /RELAUNCH=1, passed by the launcher when it installs its update.
function Relaunch: Boolean;
begin
  Result := ExpandConstant('{param:RELAUNCH|0}') = '1';
end;

// After uninstalling, asks whether the player's data goes too (No by
// default). It holds the organizations, the instances with their worlds,
// Java and the saved sign-ins (encrypted in flutter_secure_storage.dat).
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Data: String;
begin
  if CurUninstallStep <> usPostUninstall then
    exit;

  Data := ExpandConstant('{#DataFolder}');
  if not DirExists(Data) or UninstallSilent then
    exit;

  if MsgBox(CustomMessage('DeleteData'), mbConfirmation,
            MB_YESNO or MB_DEFBUTTON2) = IDYES then
  begin
    DelTree(Data, True, True, True);
    // The company folder, only if nothing else is in it.
    RemoveDir(ExtractFileDir(Data));
  end;
end;
