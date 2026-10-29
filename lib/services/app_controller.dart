import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:local_notifier/local_notifier.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/conversion_result.dart';
import '../core/keyboard_converter.dart';
import '../core/localization.dart';
import '../core/settings_manager.dart';
import '../core/shortcut_definition.dart';
import '../core/app_log.dart';
import '../core/keyboard_layout_map.dart';
import '../platform/autostart.dart';
import '../platform/isolate_hook.dart';
import '../platform/platform_interop.dart';
import '../platform/platform_services.dart' as services;
import '../platform/shortcut_hook.dart';
import '../platform/windows/keyboard_hook.dart';
import '../platform/windows/memory_trimmer.dart';
import '../platform/windows/windows_registry.dart';
import 'selection_converter.dart';
import 'shortcut_recorder.dart';

const String _rle = '\u202B';
const String _pdf = '\u202C';

class AppController extends ChangeNotifier
    with TrayListener, WindowListener {
  AppController._(
    this.settingsManager,
    this.backgroundMode,
  );

  final SettingsManager settingsManager;
  final bool backgroundMode;

  final ShortcutRecorder recorder = ShortcutRecorder();

  late final PlatformInterop _os;
  late final KeyboardConverter _keyboardConverter;
  late final SelectionConverter _selectionConverter;
  final AutoStart _autoStart = createAutoStart();

  ShortcutHook? _hook;
  StreamSubscription<void>? _hookSub;
  bool _hookBusy = false;
  bool _hookDirty = false;
  bool _exiting = false;
  bool _saving = false;

  late ShortcutDefinition _currentShortcut;
  late AppLanguage _language;

  bool _busy = false;
  bool _allowRealClose = false;
  bool _windowHidden = false;
  Timer? _trimTimer;
  Timer? _trimLoop;
  Timer? _blurTimer;
  Timer? _permissionTimer;

  String _statusText = '';
  int _hotkeyErrorCode = 0;

  DateTime _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastNotificationText;

  static Future<AppController> create({
    required bool backgroundMode,
    String? initialLanguage,
  }) async {
    final SettingsManager settings = await SettingsManager.create(
      initialLanguage: initialLanguage,
    );

    final AppController controller = AppController._(settings, backgroundMode);
    await controller._init();
    return controller;
  }

  KeyFixSettings get settings => settingsManager.settings;

  AppLanguage get language => _language;
  bool get isPersian => Localization.isPersian(_language);
  ShortcutDefinition get currentShortcut => _currentShortcut;
  String get statusText => _statusText;
  bool get enabled => settings.isEnabled;

  String L(String key) => Localization.get(_language, key);

  Future<void> _init() async {
    _language = settingsManager.getLanguage();
    _currentShortcut = settingsManager.getShortcut();

    KeyboardHook.onLog = AppLog.write;
    IsolateShortcutHook.onLog = AppLog.write;
    AppLog.write('--- KeyFix starting (background: $backgroundMode) ---');

    if (Platform.isMacOS && !services.accessibilityTrusted()) {
      services.promptAccessibility();
    }

    _os = services.createInterop();

    final String? problem = _os.setupProblemKey;
    if (problem != null) {
      AppLog.write('Setup problem: $problem');
    }

    _keyboardConverter = KeyboardConverter(
      englishMap: KeyboardLayoutMap(_os.englishTranslator),
      persianMap: KeyboardLayoutMap(_os.persianTranslator),
    )
      ..detectCapsLockInMixedCaseEnglish =
          settings.detectCapsLockInMixedCaseEnglish
      ..ignoreShiftPersianToEnglish = settings.ignoreShiftPersianToEnglish
      ..ignoreShiftEnglishToPersian = settings.ignoreShiftEnglishToPersian;

    _selectionConverter =
        SelectionConverter(_keyboardConverter, _currentShortcut, _os)
          ..autoSwitchKeyboardLanguage = settings.autoSwitchKeyboardLanguage;

    recorder.addListener(_onRecorderChanged);
    await _syncHook();

    _refreshToastShortcut();

    try {
      await localNotifier.setup(
        appName: 'KeyFix',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    } catch (e) {
      debugPrint('KeyFix: notification setup failed: $e');
    }

    windowManager.addListener(this);
    await windowManager.setPreventClose(true);

    trayManager.addListener(this);
    if (Platform.isLinux) {
      _linuxTrayHostAvailable = await _detectLinuxTrayHost();
    }
    await _applyTray();

    _autoStart.refreshCurrentPath();
    final bool wanted = settings.startWithWindows;
    final bool ok = _autoStart.setEnabled(wanted);
    final bool actual = ok ? wanted : _autoStart.isEnabled();
    settingsManager.setStartWithWindows(actual);

    _updateStatusForEnabledState();

    if (backgroundMode) {
      _setWindowHidden(true);
    }

    if (_hook == null) {
      _watchPermission();
      if (!backgroundMode) {
        _showLocalizedError(_hookErrorKey(_hotkeyErrorCode), _hotkeyErrorCode);
      }
    }
  }

  String _hookErrorKey(int code) {
    switch (code) {
      case kHookPermissionDenied:
        return 'MacPermissionNeeded';
      case kHookNoDisplay:
        return 'LinuxNoDisplay';
      default:
        return 'HotkeyRegistrationFailed';
    }
  }

  void _watchPermission() {
    if (!Platform.isMacOS ||
        _hotkeyErrorCode != kHookPermissionDenied ||
        _permissionTimer != null) {
      return;
    }

    _permissionTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_exiting || !services.accessibilityTrusted()) {
        return;
      }

      _permissionTimer?.cancel();
      _permissionTimer = null;

      await _syncHook();
      if (_hook != null) {
        _updateStatusForEnabledState();
      } else {
        _watchPermission();
      }
    });
  }

  void _onRecorderChanged() {
    final bool shouldRun = _hookWanted;
    final bool running = _hook != null;
    if (shouldRun != running ||
        (running && _hook!.shortcut != _currentShortcut)) {
      _syncHook();
    }
  }

  bool get _hookWanted =>
      !_exiting && (_saving || (!recorder.recording && !recorder.visible));

  Future<void> _syncHook() async {
    if (_hookBusy) {
      _hookDirty = true;
      return;
    }

    _hookBusy = true;

    try {
      do {
        _hookDirty = false;

        final bool want = _hookWanted;

        if (!want) {
          _stopHook();
          continue;
        }

        final ShortcutHook? current = _hook;
        if (current != null && current.shortcut == _currentShortcut) {
          continue;
        }

        _stopHook();

        final ShortcutHook hook = await startShortcutHook(_currentShortcut);

        if (hook.installed) {
          _hook = hook;
          _hookSub = hook.pressed.listen((_) {
            AppLog.write('Shortcut pressed: $_currentShortcut');
            convertSelection();
          });
          _hotkeyErrorCode = 0;
          AppLog.write('Keyboard hook active for "$_currentShortcut"');
        } else {
          _hotkeyErrorCode = hook.errorCode;
          AppLog.write('Keyboard hook FAILED (error ${hook.errorCode})');
        }
      } while (_hookDirty);
    } finally {
      _hookBusy = false;
    }
  }

  void _stopHook() {
    _hookSub?.cancel();
    _hookSub = null;
    _hook?.dispose();
    _hook = null;
  }

  void _setStatus(String text) {
    _statusText = text;
    notifyListeners();
  }

  void _showLocalizedError(String messageKey, int errorCode) {
    _setStatus('${L(messageKey)}\n\n${L('ErrorCode')}$errorCode');
  }

  void _updateStatusForEnabledState() {
    final String base = enabled ? L('EnabledStatus') : L('DisabledStatus');
    final List<String> issues = <String>[];
    final String? problem = _os.setupProblemKey;
    if (problem != null) {
      issues.add(L(problem));
    }
    if (Platform.isLinux && !_linuxTrayHostAvailable) {
      issues.add(L('LinuxTrayHostUnavailable'));
    }
    _statusText = issues.isEmpty ? base : '$base\n\n${issues.join('\n\n')}';
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (language == _language) {
      return;
    }

    _language = language;
    settingsManager.setLanguage(language);

    _applyTray();
    _updateStatusForEnabledState();
  }

  void setEnabled(bool value) {
    settingsManager.setEnabled(value);
    _applyTray();
    _updateStatusForEnabledState();
  }

  void setStartWithWindows(bool value) {
    final bool success = _autoStart.setEnabled(value);
    final bool actual = success ? value : _autoStart.isEnabled();
    settingsManager.setStartWithWindows(actual);
    notifyListeners();
  }

  void setKeepRunningInBackground(bool value) {
    settingsManager.setKeepRunningInBackground(value);
    notifyListeners();
  }

  void setShowTrayIcon(bool value) {
    settingsManager.setShowTrayIcon(value);
    _applyTray();
    notifyListeners();
  }

  void setStatusNotifications(bool value) {
    settingsManager.setStatusNotifications(value);
    notifyListeners();
  }

  void setAutoSwitchKeyboardLanguage(bool value) {
    _selectionConverter.autoSwitchKeyboardLanguage = value;
    settingsManager.setAutoSwitchKeyboardLanguage(value);
    notifyListeners();
  }

  void setDetectCapsLock(bool value) {
    _keyboardConverter.detectCapsLockInMixedCaseEnglish = value;
    settingsManager.setDetectCapsLock(value);
    notifyListeners();
  }

  void setIgnoreShiftPersianToEnglish(bool value) {
    _keyboardConverter.ignoreShiftPersianToEnglish = value;
    settingsManager.setIgnoreShiftPersianToEnglish(value);
    notifyListeners();
  }

  void setIgnoreShiftEnglishToPersian(bool value) {
    _keyboardConverter.ignoreShiftEnglishToPersian = value;
    settingsManager.setIgnoreShiftEnglishToPersian(value);
    notifyListeners();
  }

  Future<void> saveShortcut() async {
    final ShortcutDefinition? newShortcut = recorder.tryBuild();
    if (newShortcut == null) {
      return;
    }

    if (newShortcut == _currentShortcut) {
      recorder.close();
      _setStatus(L('ShortcutChanged'));
      return;
    }

    final ShortcutDefinition previous = _currentShortcut;

    _saving = true;
    _currentShortcut = newShortcut;
    await _syncHook();

    if (_hook == null) {
      final int error = _hotkeyErrorCode;
      _currentShortcut = previous;
      await _syncHook();
      _saving = false;
      await _syncHook();
      recorder.setHelp(
        'ShortcutUnavailable',
        suffix: '\n\n${L('ErrorCode')}$error',
      );
      return;
    }

    _saving = false;

    _selectionConverter.updateShortcut(newShortcut);
    settingsManager.setShortcut(newShortcut);
    AppLog.write('Shortcut changed to "$newShortcut"');

    recorder.close();
    _setStatus(L('ShortcutChanged'));
  }

  Future<void> convertSelection() async {
    if (_busy) {
      return;
    }

    if (!settings.isEnabled) {
      _showStatusNotification(L('DisabledStatus'), force: true);
      return;
    }

    _busy = true;

    try {
      _setStatus(L('Converting'));

      final ConversionResult result =
          await _selectionConverter.convertSelectedText();

      final String message;
      switch (result) {
        case ConversionResult.success:
          message = L('ConversionSuccess');
        case ConversionResult.noSelectionFound:
          message = L('NoSelection');
        case ConversionResult.nothingToConvert:
          message = L('NothingToConvert');
        case ConversionResult.focusChanged:
          message = L('FocusChanged');
        case ConversionResult.inputInjectionFailed:
          message = L('InputInjectionFailed');
        case ConversionResult.clipboardError:
          message = L('ClipboardError');
      }

      AppLog.write('Conversion result: ${result.name}');
      _setStatus(message);
      if (result != ConversionResult.noSelectionFound) {
        _showStatusNotification(message);
      }
    } catch (e, st) {
      AppLog.write('Conversion failed: $e\n$st');
      final String error = '${L('ErrorPrefix')}\n$e';
      _setStatus(error);
      _showStatusNotification(error);
    } finally {
      _busy = false;
      _scheduleTrim();
    }
  }

  void _refreshToastShortcut() {
    if (!Platform.isWindows) {
      return;
    }
    try {
      WindowsRegistry.deleteKey(r'Software\Classes\AppUserModelId\KeyFix');

      final String? appData = Platform.environment['APPDATA'];
      if (appData == null) {
        return;
      }

      final File shortcut = File(
        '$appData\\Microsoft\\Windows\\Start Menu\\Programs\\KeyFix.lnk',
      );
      if (shortcut.existsSync()) {
        shortcut.deleteSync();
      }
    } catch (e) {
      AppLog.write('Toast shortcut refresh failed: $e');
    }
  }

  void _showStatusNotification(String message, {bool force = false}) {
    if (!force && !settings.statusNotifications) {
      return;
    }

    final DateTime now = DateTime.now();

    if (!force &&
        message == _lastNotificationText &&
        now.difference(_lastNotificationTime) < const Duration(seconds: 2)) {
      return;
    }

    _lastNotificationText = message;
    _lastNotificationTime = now;

    _presentNotification(message);
  }

  LocalNotification? _notification;

  Future<void> _presentNotification(String message) async {
    try {
      final LocalNotification? previous = _notification;
      _notification = null;
      if (previous != null) {
        try {
          await previous.close();
        } catch (_) {}
      }

      final String display = isPersian ? '$_rle$message$_pdf' : message;

      final LocalNotification notification = LocalNotification(
        identifier: 'KeyFixStatusNotification',
        title: display,
        body: '',
        silent: true,
      );

      notification.onClick = showMainWindow;
      _notification = notification;
      await notification.show();
    } catch (e) {
      debugPrint('KeyFix: notification failed: $e');
    }
  }

  bool _trayCreated = false;
  bool _trayReady = false;
  bool _linuxTrayHostAvailable = true;

  bool get canRunInBackground => settings.keepRunningInBackground &&
      settings.showTrayIcon &&
      _trayReady &&
      _linuxTrayHostAvailable;

  Future<bool> _detectLinuxTrayHost() async {
    final String desktop =
        (Platform.environment['XDG_CURRENT_DESKTOP'] ?? '').toLowerCase();
    if (!desktop.contains('gnome')) {
      return true;
    }

    try {
      final ProcessResult result = await Process.run(
        'gnome-extensions',
        <String>['list', '--enabled'],
      ).timeout(const Duration(seconds: 2));
      if (result.exitCode != 0) {
        return false;
      }
      final String enabled = result.stdout.toString().toLowerCase();
      return enabled.contains('appindicatorsupport@rgcjonas.gmail.com') ||
          enabled.contains('ubuntu-appindicators@ubuntu.com');
    } catch (_) {
      return false;
    }
  }

  Future<String> _trayIconPath() async {
    if (Platform.isWindows) {
      return 'assets/KeyFix.ico';
    }

    final String home =
        Platform.environment['HOME'] ?? Directory.systemTemp.path;
    final String cacheHome =
        Platform.environment['XDG_CACHE_HOME'] ?? '$home/.cache';
    final String base = Platform.isMacOS
        ? '$home/Library/Application Support/KeyFix'
        : '$cacheHome/keyfix';
    final File icon = File('$base${Platform.pathSeparator}tray-icon.png');
    final ByteData data = await rootBundle.load('assets/icons/keyfix.png');
    final Uint8List bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    try {
      await icon.parent.create(recursive: true);
      await icon.writeAsBytes(bytes, flush: true);
      return icon.absolute.path;
    } catch (_) {
      final Directory fallback = Directory.systemTemp;
      final File fallbackIcon = File(
        '${fallback.path}${Platform.pathSeparator}keyfix-tray-icon.png',
      );
      await fallbackIcon.writeAsBytes(bytes, flush: true);
      return fallbackIcon.absolute.path;
    }
  }

  Future<void> _applyTray() async {
    try {
      if (!settings.showTrayIcon) {
        if (_trayCreated) {
          await trayManager.destroy();
          _trayCreated = false;
        }
        _trayReady = false;
        return;
      }

      if (!_trayCreated) {
        await trayManager.setIcon(await _trayIconPath());
        await trayManager.setToolTip('KeyFix');
        _trayCreated = true;
      }

      await trayManager.setContextMenu(
        Menu(
          items: <MenuItem>[
            MenuItem.checkbox(
              key: 'enabled',
              label: L('Active'),
              checked: settings.isEnabled,
              onClick: (_) {},
            ),
            MenuItem.separator(),
            MenuItem(key: 'settings', label: L('Settings')),
            MenuItem.separator(),
            MenuItem(key: 'exit', label: L('Exit')),
          ],
        ),
      );
      _trayReady = true;
    } catch (e) {
      _trayReady = false;
      debugPrint('KeyFix: tray error: $e');
    }
  }

  @override
  Future<void> onTrayIconMouseDown() async {
    if (await windowManager.isVisible() && !await windowManager.isMinimized()) {
      await hideMainWindow();
    } else {
      await showMainWindow();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'enabled':

        setEnabled(!settings.isEnabled);
      case 'settings':
        showMainWindow();
      case 'exit':
        exitApplication();
    }
  }

  void _trimMemory() {
    PaintingBinding.instance.imageCache.clear();
    if (Platform.isWindows) {
      MemoryTrimmer.trim();
    }
  }

  void _scheduleTrim() {
    if (!_windowHidden) {
      return;
    }
    _trimTimer?.cancel();
    _trimTimer = Timer(const Duration(seconds: 2), () {
      if (_windowHidden) {
        _trimMemory();
      }
    });
  }

  @override
  void onWindowBlur() {
    if (!Platform.isWindows) {
      return;
    }
    _blurTimer?.cancel();
    _blurTimer = Timer(const Duration(seconds: 4), MemoryTrimmer.trim);
  }

  @override
  void onWindowFocus() {
    _blurTimer?.cancel();
    _blurTimer = null;
  }

  void _setWindowHidden(bool hidden) {
    _windowHidden = hidden;
    _trimTimer?.cancel();
    _trimLoop?.cancel();
    _trimLoop = null;
    if (hidden) {
      _scheduleTrim();
      if (Platform.isWindows) {
        _trimLoop = Timer.periodic(
          const Duration(seconds: 60),
          (_) => MemoryTrimmer.trim(),
        );
      }
    }
  }

  @override
  void onWindowMinimize() => _setWindowHidden(true);

  @override
  void onWindowRestore() => _setWindowHidden(false);

  Future<void> showMainWindow() async {
    _setWindowHidden(false);
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(false);
    }
    await windowManager.show();
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.focus();
    notifyListeners();
  }

  Future<void> hideMainWindow() async {
    await windowManager.hide();
    if (Platform.isMacOS && settings.showTrayIcon) {
      await windowManager.setSkipTaskbar(true);
    }
    _setWindowHidden(true);
    notifyListeners();
  }

  @override
  void onWindowClose() {
    if (_allowRealClose) {
      return;
    }

    if (!canRunInBackground) {
      exitApplication();
      return;
    }

    hideMainWindow();
  }

  Future<void> exitApplication() async {
    _allowRealClose = true;
    _exiting = true;

    try {
      _stopHook();
    } catch (_) {}

    try {
      await trayManager.destroy();
    } catch (_) {}

    settingsManager.flushPendingSaves();

    exit(0);
  }

  static int readAccentColor() => services.readAccentColor();

  @override
  void dispose() {
    _trimTimer?.cancel();
    _trimLoop?.cancel();
    _blurTimer?.cancel();
    _permissionTimer?.cancel();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    _stopHook();
    recorder.removeListener(_onRecorderChanged);
    recorder.dispose();
    super.dispose();
  }
}
