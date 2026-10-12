#define MyAppName "KeyFix"
; Version: taken from the KEYFIX_VERSION environment variable when set
; (CI passes the release tag), otherwise the default below.
#define MyAppVersion GetEnv("KEYFIX_VERSION")
#if MyAppVersion == ""
  #undef MyAppVersion
  #define MyAppVersion "1.0.1"
#endif

; Target architecture, selected with a plain define on the command line:
;   ISCC /DKEYFIX_ARM64 KeyFix.iss -> arm64
;   ISCC /DKEYFIX_X86   KeyFix.iss -> x86
;   ISCC               KeyFix.iss -> x64 (default)
; Must match the publish folder KeyFix\publish\win-<arch>.
#if defined(KEYFIX_ARM64)
  #define MyArch "arm64"
#elif defined(KEYFIX_X86)
  #define MyArch "x86"
#else
  #define MyArch "x64"
#endif

#define MyAppPublisher "M-D-6"
#define MyAppPublisherURL "https://github.com/M-D-6/KeyFix"
#define MyAppExeName "KeyFix.exe"
#define MyAppId "{{A7D4E8C2-5F31-4B96-91D7-62C8A4E3F105}"
#define MyAppIcon "..\KeyFix\KeyFix.ico"
#define MyPublishDir "..\KeyFix\publish\win-" + MyArch
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
OutputBaseFilename=KeyFix-Setup-{#MyArch}

SetupIconFile={#MyAppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

#if MyArch == "x64"
; 64-bit app, installed in 64-bit mode (also runs on Arm64 Windows 11 via emulation).
; SetupArchitecture needs Inno Setup 7+; older compilers just use a 64-bit loader (UseSetupLdr below).
#if Ver >= 0x07000000
SetupArchitecture=x64
#endif
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#elif MyArch == "arm64"
; Native Arm64 app. Setup itself stays a 32-bit x86 binary (runs on Arm64 Windows 10/11).
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
; 32-bit app, installed in 32-bit mode ({autopf} = Program Files (x86) on 64-bit Windows).
ArchitecturesAllowed=x86compatible
#endif

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

#if MyArch == "x64"
UseSetupLdr=x64
#endif

OutputManifestFile=KeyFix-Setup-{#MyArch}.manifest


[Languages]

Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "fa"; MessagesFile: "Languages\Farsi.isl"


[Tasks]

Name: "startmenuicon"; \
    Description: "{cm:CreateStartMenuShortcut}"; \
    GroupDescription: "{cm:AdditionalIcons}"

Name: "desktopicon"; \
    Description: "{cm:CreateDesktopIcon}"; \
    GroupDescription: "{cm:AdditionalIcons}"



[Files]

Source: "{#MyPublishDir}\*"; \
    DestDir: "{app}"; \
    Flags: ignoreversion recursesubdirs createallsubdirs



[UninstallDelete]
; Force cleanup of the exact application directory after uninstall.
; This targets ONLY {app}, not the parent Program Files directory.
Type: filesandordirs; Name: "{app}"


[Icons]

Name: "{autoprograms}\{#MyAppName}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    WorkingDir: "{app}"; \
    Tasks: startmenuicon

Name: "{autodesktop}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    WorkingDir: "{app}"; \
    Tasks: desktopicon


[Run]

Filename: "{app}\{#MyAppExeName}"; \
    Parameters: "--initial-language={code:GetInitialLanguage}"; \
    Description: "{cm:LaunchProgram,{#MyAppName}}"; \
    Flags: nowait postinstall skipifsilent


[CustomMessages]

en.AdditionalIcons=Additional shortcuts:
en.CreateStartMenuShortcut=Create Start Menu shortcut
en.CreateDesktopIcon=Create Desktop shortcut
en.LaunchProgram=Launch %1

fa.AdditionalIcons=میانبر های جانبی:
fa.CreateStartMenuShortcut=ایجاد &میانبر در منوی استارت
fa.CreateDesktopIcon=ایجاد &میانبر روی دسکتاپ
fa.LaunchProgram=اجرای %1


[Code]

const
  RunRegistryPath =
    'Software\Microsoft\Windows\CurrentVersion\Run';

  RunRegistryValueName =
    'KeyFix';

  StartupArgument =
    '--startup';


var
  DeleteSettings:
    Boolean;


function GetInitialLanguage(
  Param: String): String;
begin
  if ActiveLanguage = 'fa' then
    Result := 'fa'
  else
    Result := 'en';
end;


function IsKeyFixStartupCommand(
  const Command: String): Boolean;
var
  ExpectedCommand:
    String;
begin
  ExpectedCommand :=
    '"' +
    ExpandConstant(
      '{app}\{#MyAppExeName}') +
    '" ' +
    StartupArgument;

  Result :=
    CompareText(
      Trim(Command),
      ExpectedCommand) = 0;
end;


procedure RemoveKeyFixStartupEntry;
var
  ExistingCommand:
    String;
begin
  try
    if RegQueryStringValue(
         HKCU,
         RunRegistryPath,
         RunRegistryValueName,
         ExistingCommand) then
    begin
      {
       * IMPORTANT:
       *
       * Never delete another application's "KeyFix"
       * value just because the value name matches.
       *
       * We delete it only when its command points exactly
       * to this KeyFix installation and uses --startup.
       }
      if IsKeyFixStartupCommand(
           ExistingCommand) then
      begin
        RegDeleteValue(
          HKCU,
          RunRegistryPath,
          RunRegistryValueName);
      end;
    end;
  except
    {
     * Cleanup must never turn an uninstall failure
     * into a system-wide problem.
     }
  end;
end;


procedure DeleteKeyFixSettings;
var
  SettingsFolder:
    String;
begin
  SettingsFolder :=
    ExpandConstant(
      '{localappdata}\KeyFix');


  if not DirExists(
       SettingsFolder) then
    Exit;


  {
   * Deliberately restricted to the exact KeyFix folder.
   *
   * Never target %LocalAppData% itself or use a wildcard.
   }
  DelTree(
    SettingsFolder,
    True,
    True,
    True);
end;



procedure CleanupKeyFixShortcuts;
var
  DesktopShortcut: String;
  StartMenuFolder: String;
begin
  DesktopShortcut :=
    ExpandConstant('{autodesktop}\{#MyAppName}.lnk');

  if FileExists(DesktopShortcut) then
    DeleteFile(DesktopShortcut);

  StartMenuFolder :=
    ExpandConstant('{autoprograms}\{#MyAppName}');

  if DirExists(StartMenuFolder) then
    DelTree(StartMenuFolder, True, True, True);
end;


procedure CloseRunningKeyFix;
var
  ResultCode: Integer;
begin
  Exec(
    ExpandConstant('{sys}\taskkill.exe'),
    '/IM {#MyAppExeName} /F',
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode);
end;


function InitializeUninstall:
  Boolean;
var
  Form:
    TSetupForm;

  TitleLabel:
    TNewStaticText;

  DescriptionLabel:
    TNewStaticText;

  SettingsCheckBox:
    TNewCheckBox;

  RemoveButton:
    TNewButton;

  CancelButton:
    TNewButton;

  ResultCode:
    Integer;

  IsPersian:
    Boolean;
begin
  {
   * Safe default:
   * settings are deleted unless the user explicitly
   * turns the checkbox off.
   }
  DeleteSettings :=
    True;


  IsPersian :=
    ActiveLanguage = 'fa';


  Form :=
    CreateCustomForm(
      ScaleX(470),
      ScaleY(270),
      False,
      False);


  try

    Form.Caption :=
      'KeyFix';

    Form.BorderStyle :=
      bsDialog;

    Form.Position :=
      poScreenCenter;


    TitleLabel :=
      TNewStaticText.Create(
        Form);

    TitleLabel.Parent :=
      Form;

    TitleLabel.Left :=
      ScaleX(24);

    TitleLabel.Top :=
      ScaleY(22);

    TitleLabel.Width :=
      ScaleX(420);

    TitleLabel.Height :=
      ScaleY(30);

    TitleLabel.AutoSize :=
      False;

    TitleLabel.Font.Style := [fsBold];

    TitleLabel.Font.Size :=
      12;


    if IsPersian then
      TitleLabel.Caption :=
        'حذف KeyFix'
    else
      TitleLabel.Caption :=
        'Remove KeyFix';


    DescriptionLabel :=
      TNewStaticText.Create(
        Form);

    DescriptionLabel.Parent :=
      Form;

    DescriptionLabel.Left :=
      ScaleX(24);

    DescriptionLabel.Top :=
      ScaleY(68);

    DescriptionLabel.Width :=
      ScaleX(420);

    DescriptionLabel.Height :=
      ScaleY(58);

    DescriptionLabel.AutoSize :=
      False;

    DescriptionLabel.WordWrap :=
      True;


    if IsPersian then
      DescriptionLabel.Caption :=
        'آیا مطمئن هستید که می‌خواهید KeyFix از این رایانه حذف شود؟'
    else
      DescriptionLabel.Caption :=
        'Are you sure you want to remove KeyFix from this computer?';


    SettingsCheckBox :=
      TNewCheckBox.Create(
        Form);

    SettingsCheckBox.Parent :=
      Form;

    SettingsCheckBox.Left :=
      ScaleX(24);

    SettingsCheckBox.Top :=
      ScaleY(135);

    SettingsCheckBox.Width :=
      ScaleX(420);

    SettingsCheckBox.Height :=
      ScaleY(28);

    SettingsCheckBox.Checked :=
      True;


    if IsPersian then
      SettingsCheckBox.Caption :=
        'تنظیمات و داده‌های برنامه نیز حذف شوند'
    else
      SettingsCheckBox.Caption :=
        'Delete settings and application data';


    RemoveButton :=
      TNewButton.Create(
        Form);

    RemoveButton.Parent :=
      Form;

    RemoveButton.Left :=
      ScaleX(285);

    RemoveButton.Top :=
      ScaleY(210);

    RemoveButton.Width :=
      ScaleX(78);

    RemoveButton.Height :=
      ScaleY(30);

    RemoveButton.Default :=
      True;

    RemoveButton.ModalResult :=
      mrOk;


    if IsPersian then
      RemoveButton.Caption :=
        'حذف'
    else
      RemoveButton.Caption :=
        'Remove';


    CancelButton :=
      TNewButton.Create(
        Form);

    CancelButton.Parent :=
      Form;

    CancelButton.Left :=
      ScaleX(373);

    CancelButton.Top :=
      ScaleY(210);

    CancelButton.Width :=
      ScaleX(70);

    CancelButton.Height :=
      ScaleY(30);

    CancelButton.Cancel :=
      True;

    CancelButton.ModalResult :=
      mrCancel;


    if IsPersian then
      CancelButton.Caption :=
        'لغو'
    else
      CancelButton.Caption :=
        'Cancel';


    ResultCode :=
      Form.ShowModal;


    if ResultCode <> mrOk then
    begin
      Result :=
        False;

      Exit;
    end;


    DeleteSettings :=
      SettingsCheckBox.Checked;


    {
     * Remove only KeyFix's own Startup entry.
     }
    CloseRunningKeyFix();

    RemoveKeyFixStartupEntry();


    Result :=
      True;

  finally

    Form.Free;

  end;
end;


procedure CurUninstallStepChanged(
  CurUninstallStep: TUninstallStep);
begin

  if CurUninstallStep =
       usPostUninstall then
  begin

    { Remove shortcuts only after the application files are gone. }
    CleanupKeyFixShortcuts();

    { Extra cleanup for files created after installation. }
    if DirExists(ExpandConstant('{app}')) then
      DelTree(ExpandConstant('{app}'), True, True, True);

    if DeleteSettings then
      DeleteKeyFixSettings();

  end;

end;
