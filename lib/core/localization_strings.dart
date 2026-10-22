// ignore_for_file: lines_longer_than_80_chars

const Map<String, String> kEnglishStrings = <String, String>{
  'Language':
      'Language',
  'Persian':
      'Persian',
  'English':
      'English',
  'Description':
      'Quickly convert selected text with a keyboard shortcut.',
  'On':
      'On',
  'Off':
      'Off',
  'KeyFixEnabled':
      'KeyFix status',
  'KeyFixStatusDescription':
      'Click this section to enable or disable KeyFix.',
  'Active':
      'Enabled',
  'Disabled':
      'Disabled',
  'ShortcutSection':
      'Keyboard shortcut',
  'ShortcutDescription':
      'Convert selected text instantly with your preferred shortcut.',
  'ChangeShortcut':
      'Change shortcut',
  'ShortcutEditor':
      'Change shortcut',
  'ShortcutRules':
      'Shortcut rules',
  'ShortcutPlaceholder':
      'Press your new shortcut...',
  'ShortcutHelp':
      'Press two or three of Ctrl, Alt and Shift together and release them (for example Alt + Shift), or press modifiers plus one key (for example Ctrl + K), or just one special key such as F9 or Pause. If the shortcut is already used by Windows or another application, it is better to choose a different one.',
  'ShortcutRecordingStopped':
      'Shortcut entry stopped and your current keys were kept. Click Retry to start over.',
  'RetryShortcut':
      'Retry',
  'Save':
      'Save',
  'Cancel':
      'Cancel',
  'ResetShortcut':
      'To change the key, start entering the shortcut again.',
  'ExecutionOptions':
      'Execution settings',
  'ConversionOptions':
      'Conversion settings',
  'Startup':
      'Automatic startup',
  'StartupDescription':
      'Start KeyFix when Windows starts.',
  'KeepRunningInBackground':
      'Keep running in the background',
  'KeepRunningInBackgroundDescription':
      'Keep KeyFix running after the main window is closed.',
  'ShowTrayIcon':
      'Show the app icon in the System Tray',
  'ShowTrayIconDescription':
      'Show the app icon in the Windows notification area.',
  'StatusNotifications':
      'Conversion notifications',
  'StatusNotificationsDescription':
      'Show a Windows notification with the conversion result each time you use the shortcut.',
  'AutoSwitchKeyboardLanguageTitle':
      'Automatically switch keyboard language',
  'AutoSwitchKeyboardLanguageDescription':
      'Automatically switch the Windows keyboard language to match the converted text.',
  'DetectCapsLockTitle':
      'Detect Caps Lock',
  'DetectCapsLockDescription':
      'Detect Caps Lock when English letters are more frequent than Persian letters.',
  'PersianToEnglish':
      'Ignore Persian diacritics when converting to English',
  'PersianToEnglishDescription':
      'Do not output uppercase English letters during conversion.',
  'EnglishToPersian':
      'Ignore English uppercase letters when converting to Persian',
  'EnglishToPersianDescription':
      'Do not output Persian diacritics during conversion.',
  'Settings':
      'Settings',
  'Exit':
      'Exit',
  'ShowKeyFix':
      'Show KeyFix',
  'TraySettingsDescription':
      'Open KeyFix settings.',
  'TrayExitDescription':
      'Completely exit KeyFix.',
  'TrayEnableDescription':
      'Enable or disable KeyFix.',
  'TrayShowDescription':
      'Open the KeyFix window.',
  'StatusTitle':
      'Status',
  'EnabledStatus':
      'KeyFix is enabled.',
  'DisabledStatus':
      'KeyFix is disabled.',
  'HotkeyRegistrationFailed':
      'Shortcut registration failed.',
  'ErrorCode':
      'Error code: ',
  'RecordingShortcut':
      'Press the shortcut keys...',
  'InvalidShortcut':
      'Invalid shortcut.\nPress at least two of Ctrl, Alt and Shift together, or one key (with or without Ctrl, Alt, Shift).',
  'InvalidMainKey':
      'This key cannot be used in a shortcut.\nTry another key.',
  'ShortcutUnavailable':
      'This shortcut cannot be used.',
  'MaxModifiers':
      'At most 3 modifiers from Ctrl, Alt and Shift are allowed.',
  'MainKeyInvalid':
      'This key cannot be used. Choose an allowed typing key or F1–F12.',
  'MinModifiers':
      'At least 1 modifier from Ctrl, Alt or Shift is required.',
  'ValidShortcut':
      'Shortcut is valid.',
  'ShortcutChanged':
      'Shortcut changed successfully.',
  'Converting':
      'Converting...',
  'ConversionSuccess':
      'Conversion completed.',
  'NoSelection':
      'No selected text was found.',
  'NothingToConvert':
      'The selected text does not need conversion.',
  'FocusChanged':
      'Operation cancelled because the active window changed during conversion.',
  'InputInjectionFailed':
      'Keyboard input could not be sent.',
  'ClipboardError':
      'Clipboard access failed.',
  'UnknownError':
      'Unknown error.',
  'ErrorPrefix':
      'Error:',
  'About':
      'About KeyFix',
  'AboutDescription':
      'KeyFix detects text typed with the wrong keyboard language or layout and restores it to the correct layout. Simply select the text and press the keyboard shortcut to fix it without typing it again.',
  'LoneKeyNotAllowed':
      'A typing key cannot be used alone. Add Ctrl or Alt, or use F1–F24, Pause, Scroll Lock or Print Screen.',
  'ShiftOnlyNotAllowed':
      'Shift with a typing key would break normal typing. Add Ctrl or Alt as well.',
  'ShortcutReserved':
      'This shortcut is reserved by Windows or used internally (for example Alt+Tab, Alt+F4, Ctrl+C, Ctrl+V). Choose another one.',
};

const Map<String, String> kPersianStrings = <String, String>{
  'Language':
      'زبان برنامه',
  'Persian':
      'فارسی',
  'English':
      'انگلیسی',
  'Description':
      'تبدیل سریع متن انتخاب‌شده با میانبر صفحه‌کلید.',
  'On':
      'روشن',
  'Off':
      'خاموش',
  'KeyFixEnabled':
      'وضعیت KeyFix',
  'KeyFixStatusDescription':
      'برای فعال یا غیرفعال کردن KeyFix روی این بخش کلیک کنید.',
  'Active':
      'فعال',
  'Disabled':
      'غیرفعال',
  'ShortcutSection':
      'میانبر صفحه‌کلید',
  'ShortcutDescription':
      'متن انتخاب‌شده را با میانبر دلخواه شما فوراً تبدیل می‌کند.',
  'ChangeShortcut':
      'تغییر میانبر',
  'ShortcutEditor':
      'تغییر میانبر',
  'ShortcutRules':
      'قوانین میانبر',
  'ShortcutPlaceholder':
      'میانبر جدید را فشار دهید...',
  'ShortcutHelp':
      'دو یا سه کلید از Ctrl، Alt و Shift را با هم بزنید و رها کنید (مثلاً Alt + Shift)، یا کلیدهای تغییردهنده را همراه یک کلید بزنید (مثلاً Ctrl + K)، یا فقط یک کلید ویژه مثل F9 یا Pause را فشار دهید. اگر این میانبر قبلاً توسط ویندوز یا برنامه دیگری استفاده می‌شود، بهتر است میانبر دیگری انتخاب کنید.',
  'ShortcutRecordingStopped':
      'ثبت میانبر متوقف شد و کلیدهای واردشده حفظ شدند. برای شروع دوباره روی «تلاش مجدد» کلیک کنید.',
  'RetryShortcut':
      'تلاش مجدد',
  'Save':
      'ذخیره',
  'Cancel':
      'لغو',
  'ResetShortcut':
      'برای تغییر کلید، میانبر را دوباره از ابتدا وارد کنید.',
  'ExecutionOptions':
      'تنظیمات اجرا',
  'ConversionOptions':
      'تنظیمات تبدیل',
  'Startup':
      'اجرای خودکار',
  'StartupDescription':
      'KeyFix هنگام ورود به ویندوز اجرا شود.',
  'KeepRunningInBackground':
      'فعال ماندن در پس‌زمینه',
  'KeepRunningInBackgroundDescription':
      'با بستن پنجره، KeyFix در پس‌زمینه فعال بماند.',
  'ShowTrayIcon':
      'نمایش آیکون KeyFix در System Tray',
  'ShowTrayIconDescription':
      'نمایش آیکون برنامه در System Tray',
  'StatusNotifications':
      'اعلان نتیجه تبدیل',
  'StatusNotificationsDescription':
      'با هر بار استفاده از شورتکات، نتیجه تبدیل به‌صورت اعلان ویندوز نمایش داده شود.',
  'AutoSwitchKeyboardLanguageTitle':
      'تغییر خودکار زبان صفحه‌کلید',
  'AutoSwitchKeyboardLanguageDescription':
      'زبان فعال صفحه‌کلید ویندوز را پس از تبدیل، متناسب با زبان متن تغییر می‌دهد.',
  'DetectCapsLockTitle':
      'تشخیص Caps Lock',
  'DetectCapsLockDescription':
      'اگر حروف انگلیسی بیشتر از حروف فارسی باشد، Caps Lock روشن در نظر گرفته می‌شود.',
  'PersianToEnglish':
      'نادیده گرفتن اعراب در تبدیل فارسی به انگلیسی',
  'PersianToEnglishDescription':
      'حروف بزرگ انگلیسی در خروجی تولید نشود.',
  'EnglishToPersian':
      'نادیده گرفتن حروف بزرگ در تبدیل انگلیسی به فارسی',
  'EnglishToPersianDescription':
      'اعراب فارسی در خروجی تولید نشود.',
  'Settings':
      'تنظیمات',
  'Exit':
      'خروج',
  'ShowKeyFix':
      'نمایش KeyFix',
  'TraySettingsDescription':
      'باز کردن تنظیمات KeyFix.',
  'TrayExitDescription':
      'خروج کامل از KeyFix.',
  'TrayEnableDescription':
      'فعال یا غیرفعال کردن KeyFix.',
  'TrayShowDescription':
      'باز کردن پنجره KeyFix.',
  'StatusTitle':
      'وضعیت',
  'EnabledStatus':
      'KeyFix فعال است.',
  'DisabledStatus':
      'KeyFix غیرفعال است.',
  'HotkeyRegistrationFailed':
      'ثبت میانبر ناموفق بود.',
  'ErrorCode':
      'کد خطا: ',
  'RecordingShortcut':
      'کلیدهای میانبر را فشار دهید...',
  'InvalidShortcut':
      'میانبر نامعتبر است.\nحداقل دو کلید از Ctrl، Alt و Shift را با هم بزنید، یا یک کلید (با یا بدون Ctrl، Alt و Shift) انتخاب کنید.',
  'InvalidMainKey':
      'این کلید در میانبر قابل استفاده نیست.\nکلید دیگری را امتحان کنید.',
  'ShortcutUnavailable':
      'این میانبر قابل استفاده نیست.',
  'MaxModifiers':
      'حداکثر ۳ کلید از Ctrl، Alt و Shift مجاز است.',
  'MainKeyInvalid':
      'این کلید مجاز نیست. یک کلید نوشتاری مجاز یا F1 تا F12 انتخاب کنید.',
  'MinModifiers':
      'حداقل ۱ کلید از Ctrl، Alt یا Shift لازم است.',
  'ValidShortcut':
      'میانبر معتبر است.',
  'ShortcutChanged':
      'میانبر با موفقیت تغییر کرد.',
  'Converting':
      'در حال تبدیل...',
  'ConversionSuccess':
      'تبدیل با موفقیت انجام شد.',
  'NoSelection':
      'متن انتخاب‌شده‌ای پیدا نشد.',
  'NothingToConvert':
      'متن انتخاب‌شده نیازی به تبدیل ندارد.',
  'FocusChanged':
      'عملیات لغو شد؛ پنجره فعال هنگام تبدیل تغییر کرد.',
  'InputInjectionFailed':
      'ارسال کلید ناموفق بود.',
  'ClipboardError':
      'دسترسی به Clipboard ناموفق بود.',
  'UnknownError':
      'خطای نامشخص.',
  'ErrorPrefix':
      'خطا:',
  'About':
      'درباره KeyFix',
  'AboutDescription':
      'KeyFix متن‌هایی را که به‌دلیل انتخاب اشتباه زبان یا چیدمان صفحه‌کلید نادرست تایپ شده‌اند، تشخیص داده و به چیدمان صحیح بازمی‌گرداند. کافی است متن را انتخاب کرده و میانبر صفحه‌کلید را فشار دهید؛ بدون نیاز به تایپ دوباره، متن اصلاح می‌شود.',
  'LoneKeyNotAllowed':
      'کلید نوشتاری را نمی‌توان تنها به‌کار برد. Ctrl یا Alt را اضافه کنید، یا از F1 تا F24، Pause، Scroll Lock یا Print Screen استفاده کنید.',
  'ShiftOnlyNotAllowed':
      'Shift همراه یک کلید نوشتاری تایپ عادی را مختل می‌کند. Ctrl یا Alt را هم اضافه کنید.',
  'ShortcutReserved':
      'این میانبر برای ویندوز رزرو شده یا داخل برنامه استفاده می‌شود (مثل Alt+Tab، Alt+F4، Ctrl+C، Ctrl+V). میانبر دیگری انتخاب کنید.',
};
