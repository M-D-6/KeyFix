# KeyFix

[فارسی](#فارسی) · [English](#english)

---

## فارسی

**KeyFix** یک برنامهٔ سبک برای ویندوز است که متنِ تایپ‌شده با **زبان یا چیدمان اشتباه صفحه‌کلید** را به چیدمان درست برمی‌گرداند. فقط کافی است متن را انتخاب کنید و میانبر را بزنید.

مثال: اگر به‌جای «سلام» تایپ شده باشد `sghl`، یا به‌جای `hello` تایپ شده باشد «اثممخ»، با یک میانبر متن درست می‌شود، بدون اینکه دوباره تایپش کنید.

### امکانات

- تبدیل متن انتخاب‌شده بین چیدمان **فارسی و انگلیسی** با یک میانبر سراسری (پیش‌فرض: `Ctrl + K`)
- تشخیص خودکار جهت تبدیل، حتی در متن ترکیبی
- تشخیص Caps Lock در متن‌های انگلیسی
- تغییر خودکار زبان صفحه‌کلید ویندوز پس از تبدیل (اختیاری)
- میانبر قابل تغییر: ۱ تا ۳ کلید از Ctrl / Alt / Shift به‌علاوهٔ یک کلید
- آیکون در System Tray با منوی راست‌کلیک (فعال/غیرفعال، تنظیمات، خروج)
- اجرا همراه ویندوز و ادامهٔ کار در پس‌زمینه (اختیاری)
- اعلان نتیجهٔ تبدیل (اختیاری)
- رابط **فارسی و انگلیسی**، هماهنگ با تم روشن/تاریک ویندوز
- بدون اتصال به اینترنت و بدون جمع‌آوری اطلاعات

### نحوهٔ کار

KeyFix متن انتخاب‌شده را با شبیه‌سازی `Ctrl+C` می‌خواند، هر کاراکتر را با نقشهٔ چیدمان فارسی و انگلیسی تبدیل می‌کند و نتیجه را با `Ctrl+V` جایگزین می‌کند. محتوای قبلی کلیپ‌بورد پس از پایان کار بازگردانده می‌شود.

### نصب

از بخش [Releases](https://github.com/M-D-6/KeyFix/releases) نصب‌کنندهٔ مناسب سیستم خود را بگیرید:

| فایل | مناسب برای |
|---|---|
| `KeyFix-Setup-x64.exe` | ویندوز ۶۴ بیتی معمولی (اکثر کامپیوترها) |
| `KeyFix-Setup-x86.exe` | ویندوز ۳۲ بیتی |
| `KeyFix-Setup-arm64.exe` | ویندوز روی پردازندهٔ ARM64 |

حداقل نیاز: ویندوز ۱۰ (نسخهٔ 1809) یا بالاتر. فایل `SHA256SUMS.txt` برای بررسی سلامت فایل‌ها کنار هر ریلیز قرار دارد.

### استفاده

1. KeyFix را اجرا کنید؛ در System Tray قرار می‌گیرد.
2. متنی را که با زبان اشتباه تایپ شده انتخاب کنید.
3. میانبر را بزنید (پیش‌فرض `Ctrl + K`).

### محدودیت‌ها

- KeyFix با دسترسی معمولی کاربر اجرا می‌شود. به همین دلیل نمی‌تواند در پنجره‌هایی که **به‌صورت Administrator** اجرا شده‌اند متن را تبدیل کند (محدودیت امنیتی ویندوز).
- اگر میانبر انتخابی را ویندوز یا برنامهٔ دیگری استفاده می‌کند، ثبت آن شکست می‌خورد و باید میانبر دیگری انتخاب کنید.

### تنظیمات

تنظیمات در `%LocalAppData%\KeyFix\Settings.json` ذخیره می‌شود. هنگام حذف برنامه می‌توانید انتخاب کنید که تنظیمات هم پاک شوند.

### ساخت از روی سورس

- Windows 10/11 و [.NET 10 SDK](https://dotnet.microsoft.com/download)
- Visual Studio 2022 یا جدیدتر با workload توسعهٔ دسکتاپ (WinUI)

```powershell
dotnet publish KeyFix/KeyFix.csproj -c Release -p:Platform=x64
```

پلتفرم‌های `x86`، `x64` و `ARM64` پشتیبانی می‌شوند و خروجی در `KeyFix/publish/win-<arch>` قرار می‌گیرد. نصب‌کننده با [Inno Setup](https://jrsoftware.org/isinfo.php) از روی `KeyFix.Installer/KeyFix.iss` ساخته می‌شود. ریلیزهای رسمی با GitHub Actions ساخته می‌شوند: هر تگ به شکل `vX.Y.Z` (مثل `v1.0.0`) سه نصب‌کننده را می‌سازد و در Releases قرار می‌دهد.

### مجوز

KeyFix یک نرم‌افزار آزاد است و تحت **GNU General Public License نسخهٔ ۳** (GPL-3.0) منتشر شده است. متن کامل مجوز در فایل [LICENSE](LICENSE) آمده است.

Copyright © 2026 M-D-6

---

## English

**KeyFix** is a lightweight Windows utility that fixes text typed with the **wrong keyboard language or layout**. Select the text, press a shortcut, and it is converted to the correct layout without retyping.

Example: if you typed `sghl` instead of «سلام», or «اثممخ» instead of `hello`, one shortcut fixes it.

### Features

- Converts the selected text between the **Persian and English** layouts with a global shortcut (default: `Ctrl + K`)
- Detects the conversion direction automatically, even in mixed text
- Caps Lock detection for English text
- Optionally switches the Windows keyboard language to match the converted text
- Customizable shortcut: 1–3 modifiers from Ctrl / Alt / Shift plus one key
- System Tray icon with a right-click menu (enable/disable, settings, exit)
- Optional start with Windows and running in the background
- Optional conversion notifications
- **Persian and English** interface that follows the Windows light/dark theme
- No network access and no data collection

### How it works

KeyFix reads the selection by sending `Ctrl+C`, maps each character between the Persian and English layouts, and pastes the result with `Ctrl+V`. Your previous clipboard content is restored afterwards.

### Installation

Download the installer for your system from [Releases](https://github.com/M-D-6/KeyFix/releases):

| File | For |
|---|---|
| `KeyFix-Setup-x64.exe` | Regular 64-bit Windows (most PCs) |
| `KeyFix-Setup-x86.exe` | 32-bit Windows |
| `KeyFix-Setup-arm64.exe` | Windows on ARM64 processors |

Requires Windows 10 (version 1809) or later. A `SHA256SUMS.txt` file is attached to each release for verifying downloads.

### Usage

1. Start KeyFix; it lives in the System Tray.
2. Select text that was typed with the wrong layout.
3. Press the shortcut (default `Ctrl + K`).

### Limitations

- KeyFix runs without elevation, so it cannot convert text in windows running **as Administrator** (a Windows security restriction).
- If the chosen shortcut is already used by Windows or another app, registration fails and you need to pick another one.

### Settings

Settings are stored in `%LocalAppData%\KeyFix\Settings.json`. The uninstaller lets you choose whether to delete them.

### Building from source

- Windows 10/11 and the [.NET 10 SDK](https://dotnet.microsoft.com/download)
- Visual Studio 2022 or later with the desktop (WinUI) workload

```powershell
dotnet publish KeyFix/KeyFix.csproj -c Release -p:Platform=x64
```

`x86`, `x64` and `ARM64` are supported; output goes to `KeyFix/publish/win-<arch>`. The installer is built with [Inno Setup](https://jrsoftware.org/isinfo.php) from `KeyFix.Installer/KeyFix.iss`. Official releases are built by GitHub Actions: pushing a tag like `v1.0.0` builds the three installers and attaches them to a GitHub Release.

### License

KeyFix is free software, released under the **GNU General Public License, version 3** (GPL-3.0). The full text is in [LICENSE](LICENSE).

Copyright © 2026 M-D-6
