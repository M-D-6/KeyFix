# KeyFix

Fix text typed in the wrong keyboard layout with one shortcut.
متنِ تایپ‌شده با چیدمان اشتباه را با یک میانبر درست کنید.

```
sghl   <->   سلام
اثممخ  <->   hello
```

A Flutter port of [M-D-6/KeyFix](https://github.com/M-D-6/KeyFix) (Persian <-> English).
Windows is supported now; Linux and macOS are planned. All OS access sits behind
`PlatformInterop`, so those platforms only need a new implementation.

## Features

- Converts the selected text between Persian and English, direction detected
  automatically (also for mixed text), with Caps Lock detection
- Optional automatic switch of the keyboard language after converting
- Flexible global shortcut: `Alt + Shift` alone (any two of Ctrl/Alt/Shift),
  modifiers + any key, or one special key (`Pause`, `F9`, `Print Screen` ...)
- Tray icon, start with Windows, background mode, optional notifications
- Persian and English UI (RTL aware), light/dark, system accent colour
- Single instance (a second launch just shows the running window), no network access, no data collection

## Download

Get `KeyFix-windows-x64.zip` from the
[Releases](../../releases) page, extract it anywhere and run `KeyFix.exe`.
No installer and no extra runtime are needed.

## Usage

1. Select text typed in the wrong layout, in any application.
2. Press the shortcut (default `Alt + Shift`).
3. The text is replaced with the corrected version.

Use **Change shortcut** to record a new one. Press the keys, then Save. The
small info icon in the dialog lists the allowed combinations.

## Build from source (Windows 10 1809+ / 11)

Requires Flutter (stable, Windows desktop enabled) and Visual Studio 2022 with
"Desktop development with C++".

```powershell
flutter pub get
flutter test
flutter run -d windows
flutter build windows --release
```

The release build is in `build\windows\x64\runner\Release\KeyFix.exe`.

## Publishing a release

Update `version` in `pubspec.yaml`, then push a tag:

```powershell
git tag v1.0.1
git push origin v1.0.1
```

The `Build Windows` workflow analyzes, tests, builds and attaches
`KeyFix-windows-x64.zip` to a new GitHub Release. It can also be started
manually from the Actions tab to get the zip as a build artifact.

## How it works

Ctrl+C is sent with `SendInput`, the clipboard text is mapped between the two
layouts, Ctrl+V pastes it and the previous clipboard content is restored.

The layouts are read from Windows (`LoadKeyboardLayout`, `MapVirtualKeyEx`,
`ToUnicodeEx`), not from a hard-coded table. The shortcut is a low-level
keyboard hook running in its own isolate; it is paused while a new shortcut is
recorded.

Settings and a diagnostic log live in `%LocalAppData%\KeyFix`.

## Look

Solid Material 3 look: colours come from the Windows accent colour and the
light/dark setting, cards are one tonal step lighter than the background.
The bundled font is [Vazirmatn](https://github.com/rastikerdar/vazirmatn) (SIL OFL 1.1).

## Code layout

```
lib/core      converter, layout map, shortcut rules, settings, localization
lib/platform  PlatformInterop and the Windows implementation
lib/services  SelectionConverter, ShortcutRecorder, AppController
lib/ui        theme, widgets, home page
```

## License

GPL-3.0, like the original (derivative work).
