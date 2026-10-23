#define MyAppName "KeyFix"
#define MyAppVersion GetEnv("KEYFIX_VERSION")
#if MyAppVersion == ""
  #undef MyAppVersion
  #define MyAppVersion "1.0.1"
#endif

#define MyAppPublisher "M-D-6"
#define MyAppPublisherURL "https://github.com/M-D-6/KeyFix"
#define MyAppExeName "KeyFix.exe"
#define MyAppId "{{A7D4E8C2-5F31-4B96-91D7-62C8A4E3F105}"
#define MyAppIcon "assets\KeyFix.ico"
#define MyPublishDir "build\windows\x64\runner\Release"
#define MyOutputDir "Output"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoDescription={#MyAppName} Installer
VersionInfoVersion={#MyAppVersion}
VersionInfoTextVersion={#MyAppVersion}
VersionInfoCopyright=Copyright © 2026 {#MyAppPublisher}
AppPublisherURL={#MyAppPublisherURL}
AppSupportURL={#MyAppPublisherURL}
AppUpdatesURL={#MyAppPublisherURL}/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir={#MyOutputDir}
OutputBaseFilename=KeyFix-Setup-x64
SetupIconFile={#MyAppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
#if Ver >= 0x07000000
SetupArchitecture=x64
#endif
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
MinVersion=10.0
WizardStyle=modern windows11 dynamic includetitlebar
WizardSizePercent=120
ShowLanguageDialog=yes
UsePreviousLanguage=no
LanguageDetectionMethod=uilanguage
DisableStartupPrompt=yes
DisableProgramGroupPage=yes
AllowNoIcons=yes
CreateUninstallRegKey=yes
Uninstallable=yes
AppMutex=Local\KeyFix.SingleInstance
CloseApplications=yes
RestartApplications=no
SetupLogging=yes
UninstallLogging=yes
UninstallLogMode=append
RedirectionGuard=yes
Compression=lzma
SolidCompression=yes
UseSetupLdr=x64
OutputManifestFile=KeyFix-Setup-x64.manifest

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "fa"; MessagesFile: "Languages\Farsi.isl"

[Tasks]
Name: "startmenuicon"; Description: "{cm:CreateStartMenuShortcut}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#MyPublishDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Icons]
Name: "{autoprograms}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: startmenuicon
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Parameters: "--initial-language={code:GetInitialLanguage}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[CustomMessages]
en.AdditionalIcons=Additional shortcuts:
en.CreateStartMenuShortcut=Create Start Menu shortcut
en.CreateDesktopIcon=Create Desktop shortcut
en.LaunchProgram=Launch %1
fa.AdditionalIcons=میانبرهای جانبی:
fa.CreateStartMenuShortcut=ایجاد &میانبر در منوی استارت
fa.CreateDesktopIcon=ایجاد &میانبر روی دسکتاپ
fa.LaunchProgram=اجرای %1

[Code]
const
  RunRegistryPath = 'Software\Microsoft\Windows\CurrentVersion\Run';
  RunRegistryValueName = 'KeyFix';
  StartupArgument = '--startup';

var
  DeleteSettings: Boolean;

function GetInitialLanguage(Param: String): String;
begin
  if ActiveLanguage = 'fa' then
    Result := 'fa'
  else
    Result := 'en';
end;

function IsKeyFixStartupCommand(const Command: String): Boolean;
var
  ExpectedCommand: String;
begin
  ExpectedCommand := '"' + ExpandConstant('{app}\{#MyAppExeName}') + '" ' + StartupArgument;
  Result := CompareText(Trim(Command), ExpectedCommand) = 0;
end;

procedure RemoveKeyFixStartupEntry;
var
  ExistingCommand: String;
begin
  try
    if RegQueryStringValue(HKCU, RunRegistryPath, RunRegistryValueName, ExistingCommand) then
    begin
      if IsKeyFixStartupCommand(ExistingCommand) then
        RegDeleteValue(HKCU, RunRegistryPath, RunRegistryValueName);
    end;
  except
  end;
end;

procedure DeleteKeyFixSettings;
var
  SettingsFolder: String;
begin
  SettingsFolder := ExpandConstant('{localappdata}\KeyFix');
  if DirExists(SettingsFolder) then
    DelTree(SettingsFolder, True, True, True);
end;

procedure CleanupKeyFixShortcuts;
var
  DesktopShortcut: String;
  StartMenuFolder: String;
begin
  DesktopShortcut := ExpandConstant('{autodesktop}\{#MyAppName}.lnk');
  if FileExists(DesktopShortcut) then
    DeleteFile(DesktopShortcut);
  StartMenuFolder := ExpandConstant('{autoprograms}\{#MyAppName}');
  if DirExists(StartMenuFolder) then
    DelTree(StartMenuFolder, True, True, True);
end;

procedure CloseRunningKeyFix;
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/IM {#MyAppExeName} /F', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function InitializeUninstall: Boolean;
var
  Form: TSetupForm;
  TitleLabel: TNewStaticText;
  DescriptionLabel: TNewStaticText;
  SettingsCheckBox: TNewCheckBox;
  RemoveButton: TNewButton;
  CancelButton: TNewButton;
  ResultCode: Integer;
  IsPersian: Boolean;
begin
  DeleteSettings := True;
  IsPersian := ActiveLanguage = 'fa';
  Form := CreateCustomForm(ScaleX(470), ScaleY(270), False, False);
  try
    Form.Caption := 'KeyFix';
    Form.BorderStyle := bsDialog;
    Form.Position := poScreenCenter;

    TitleLabel := TNewStaticText.Create(Form);
    TitleLabel.Parent := Form;
    TitleLabel.Left := ScaleX(24);
    TitleLabel.Top := ScaleY(22);
    TitleLabel.Width := ScaleX(420);
    TitleLabel.Height := ScaleY(30);
    TitleLabel.AutoSize := False;
    TitleLabel.Font.Style := [fsBold];
    TitleLabel.Font.Size := 12;
    if IsPersian then
      TitleLabel.Caption := 'حذف KeyFix'
    else
      TitleLabel.Caption := 'Remove KeyFix';

    DescriptionLabel := TNewStaticText.Create(Form);
    DescriptionLabel.Parent := Form;
    DescriptionLabel.Left := ScaleX(24);
    DescriptionLabel.Top := ScaleY(68);
    DescriptionLabel.Width := ScaleX(420);
    DescriptionLabel.Height := ScaleY(58);
    DescriptionLabel.AutoSize := False;
    DescriptionLabel.WordWrap := True;
    if IsPersian then
      DescriptionLabel.Caption := 'آیا مطمئن هستید که می‌خواهید KeyFix از این رایانه حذف شود؟'
    else
      DescriptionLabel.Caption := 'Are you sure you want to remove KeyFix from this computer?';

    SettingsCheckBox := TNewCheckBox.Create(Form);
    SettingsCheckBox.Parent := Form;
    SettingsCheckBox.Left := ScaleX(24);
    SettingsCheckBox.Top := ScaleY(135);
    SettingsCheckBox.Width := ScaleX(420);
    SettingsCheckBox.Height := ScaleY(28);
    SettingsCheckBox.Checked := True;
    if IsPersian then
      SettingsCheckBox.Caption := 'تنظیمات و داده‌های برنامه نیز حذف شوند'
    else
      SettingsCheckBox.Caption := 'Delete settings and application data';

    RemoveButton := TNewButton.Create(Form);
    RemoveButton.Parent := Form;
    RemoveButton.Left := ScaleX(285);
    RemoveButton.Top := ScaleY(210);
    RemoveButton.Width := ScaleX(78);
    RemoveButton.Height := ScaleY(30);
    RemoveButton.Default := True;
    RemoveButton.ModalResult := mrOk;
    if IsPersian then
      RemoveButton.Caption := 'حذف'
    else
      RemoveButton.Caption := 'Remove';

    CancelButton := TNewButton.Create(Form);
    CancelButton.Parent := Form;
    CancelButton.Left := ScaleX(373);
    CancelButton.Top := ScaleY(210);
    CancelButton.Width := ScaleX(70);
    CancelButton.Height := ScaleY(30);
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;
    if IsPersian then
      CancelButton.Caption := 'لغو'
    else
      CancelButton.Caption := 'Cancel';

    ResultCode := Form.ShowModal;
    if ResultCode <> mrOk then
    begin
      Result := False;
      Exit;
    end;

    DeleteSettings := SettingsCheckBox.Checked;
    CloseRunningKeyFix;
    RemoveKeyFixStartupEntry;
    Result := True;
  finally
    Form.Free;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    CleanupKeyFixShortcuts;
    if DirExists(ExpandConstant('{app}')) then
      DelTree(ExpandConstant('{app}'), True, True, True);
    if DeleteSettings then
      DeleteKeyFixSettings;
  end;
end;
