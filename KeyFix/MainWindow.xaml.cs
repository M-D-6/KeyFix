using KeyFix.Core;
using H.NotifyIcon.EfficiencyMode;
using Microsoft.UI;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Text;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.Windows.AppNotifications;
using Microsoft.Windows.AppNotifications.Builder;
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using Windows.Globalization;
using Windows.UI.Text;

using Windows.UI.ViewManagement;

namespace KeyFix;

public sealed partial class MainWindow : Window
{
    private readonly SelectionConverter _selectionConverter;
    private readonly KeyboardConverter _keyboardConverter;
    private readonly DispatcherQueue _dispatcherQueue;
    private readonly SettingsManager _settingsManager;
    private AutoStartManager? _autoStartManager;
    private readonly AppWindow _appWindow;
    private UISettings? _uiSettings;
    private DateTime _lastNotificationTime = DateTime.MinValue;
    private string? _lastNotificationText;

    private const string StatusNotificationTag =
        "KeyFixStatusNotification";

    private readonly WndProcDelegate _windowProc;
    private readonly PointerEventHandler _rootPointerPressedHandler;

    private GlobalHotKey _globalHotKey;
    private ShortcutDefinition _currentShortcut;
    private AppLanguage _currentLanguage;

    private IntPtr _windowHandle;
    private IntPtr _originalWindowProc;

    private bool _busy;

    private bool _recordingShortcut;
    private bool _shortcutHasMainKey;
    private bool _shortcutRecordingPaused;

    private uint _recordedModifiers;
    private uint _recordedMainKey;

    private readonly List<uint> _recordedModifierOrder =
        new();

    private bool _allowRealClose;
    private readonly bool _backgroundMode;
    private bool _uiInitialized;
    private bool _loadingStartupState;
    private bool _loadingLanguage;
    private bool _loadingEnabledState;

    

    private const int MinimumWindowWidth = 760;
    private const int MinimumWindowHeight = 380;

    private const int InitialWindowWidth = 960;
    private const int InitialWindowHeight = 680;

    private const uint WM_GETMINMAXINFO = 0x0024;
    private const int GWLP_WNDPROC = -4;

    

    private const uint ModifierAlt = 0x0001;
    private const uint ModifierCtrl = 0x0002;
    private const uint ModifierShift = 0x0004;

    private const uint VirtualKeyAlt = 0x12;
    private const uint VirtualKeyCtrl = 0x11;
    private const uint VirtualKeyShift = 0x10;

    private const uint VirtualKeySpace = 0x20;

    

    private const char Lre = '\u202A';
    private const char Rle = '\u202B';
    private const char Pdf = '\u202C';

    

    private XamlUICommand TraySettingsCommand =>
        (XamlUICommand)RootGrid.Resources[
            "TraySettingsCommand"];

    private XamlUICommand TrayExitCommand =>
        (XamlUICommand)RootGrid.Resources[
            "TrayExitCommand"];

    private XamlUICommand TrayEnableCommand =>
        (XamlUICommand)RootGrid.Resources[
            "TrayEnableCommand"];

    private XamlUICommand TrayShowWindowCommand =>
        (XamlUICommand)RootGrid.Resources[
            "TrayShowWindowCommand"];

    

    public MainWindow(
        bool backgroundMode = false)
    {
        _backgroundMode = backgroundMode;
        _windowProc =
            WindowProc;

        _rootPointerPressedHandler =
            RootGrid_PointerPressed;

        InitializeComponent();

        _dispatcherQueue =
            DispatcherQueue.GetForCurrentThread();

        _windowHandle =
            WinRT.Interop.WindowNative.GetWindowHandle(
                this);

        WindowId windowId =
            Win32Interop.GetWindowIdFromWindow(
                _windowHandle);

        _appWindow =
            AppWindow.GetFromWindowId(
                windowId);

        _settingsManager =
            new SettingsManager();

        _currentLanguage =
            _settingsManager.GetLanguage();

        _currentShortcut =
            _settingsManager.GetShortcut();

        _keyboardConverter =
            new KeyboardConverter(
                KeyboardLayouts.English,
                KeyboardLayouts.Persian);

        _keyboardConverter
            .DetectCapsLockInMixedCaseEnglish =
            _settingsManager.Settings
                .DetectCapsLockInMixedCaseEnglish;

        _keyboardConverter
            .IgnoreShiftPersianToEnglish =
            _settingsManager.Settings
                .IgnoreShiftPersianToEnglish;

        _keyboardConverter
            .IgnoreShiftEnglishToPersian =
            _settingsManager.Settings
                .IgnoreShiftEnglishToPersian;

        _selectionConverter =
            new SelectionConverter(
                _keyboardConverter,
                _currentShortcut);

        _selectionConverter.AutoSwitchKeyboardLanguage =
            _settingsManager.Settings
                .AutoSwitchKeyboardLanguage;

        _globalHotKey =
            new GlobalHotKey(
                _currentShortcut);

        _globalHotKey.Pressed +=
            OnHotKeyPressed;

        bool registered =
            _globalHotKey.Register(
                out int errorCode);

        if (!registered)
        {
            _hotkeyRegistrationErrorCode = errorCode;
        }

        _appWindow.Closing +=
            AppWindow_Closing;

        // Native tray menu must match the app theme (light/dark),
        // including when the app starts hidden in background mode.
        NativeMenuTheme.Initialize();

        InitializeTrayBackgroundState();

        EfficiencyModeUtilities.SetEfficiencyMode(
            _backgroundMode);

        if (!_backgroundMode)
        {
            EnsureUiInitialized();
            ShowLocalizedErrorIfHotkeyRegistrationFailed(registered, errorCode);
        }
    }

    private void InitializeTrayBackgroundState()
    {
        TrayIcon.Visibility =
            _settingsManager.Settings.ShowTrayIcon
                ? Visibility.Visible
                : Visibility.Collapsed;

        TrayEnabledItem.IsChecked =
            _settingsManager.Settings.IsEnabled;

        ApplyTrayLanguageOnly();
    }

    private void ApplyTrayLanguageOnly()
    {
        TraySettingsCommand.Label =
            L("Settings");
        TraySettingsCommand.Description =
            L("TraySettingsDescription");
        TrayExitCommand.Label =
            L("Exit");
        TrayExitCommand.Description =
            L("TrayExitDescription");
        TrayEnableCommand.Label =
            L("Active");
        TrayEnableCommand.Description =
            L("TrayEnableDescription");
        TrayShowWindowCommand.Label =
            L("ShowKeyFix");
        TrayShowWindowCommand.Description =
            L("TrayShowDescription");
        TrayEnabledItem.Text =
            L("Active");
        TraySettingsItem.Text =
            L("Settings");
        TrayExitItem.Text =
            L("Exit");
    }

    private void EnsureUiInitialized()
    {
        if (_uiInitialized)
            return;

        _uiInitialized = true;

        EfficiencyModeUtilities.SetEfficiencyMode(
            false);

        RootGrid.AddHandler(
            UIElement.PointerPressedEvent,
            _rootPointerPressedHandler,
            true);

        SetWindowIcon(
            _windowHandle,
            Path.Combine(
                AppContext.BaseDirectory,
                "KeyFix.ico"));

        InstallMinimumWindowSizeHook(
            _windowHandle);

        _appWindow.Resize(
            new Windows.Graphics.SizeInt32(
                InitialWindowWidth,
                InitialWindowHeight));

        _uiSettings =
            new UISettings();

        _uiSettings.ColorValuesChanged +=
            UiSettings_ColorValuesChanged;

        Activated +=
            MainWindow_Activated;

        ExtendsContentIntoTitleBar =
            true;
        SetTitleBar(
            AppTitleBar);

        UpdateTitleBarTheme();

        _autoStartManager =
            new AutoStartManager();
        _autoStartManager.RefreshCurrentPath();

        _loadingStartupState =
            true;

        bool startupEnabled =
            _settingsManager.Settings.StartWithWindows;

        bool startupResult =
            _autoStartManager.SetEnabled(
                startupEnabled);

        if (!startupResult)
        {
            startupEnabled =
                _autoStartManager.IsEnabled();
        }

        StartWithWindowsOption.IsOn =
            startupEnabled;
        KeepRunningInBackgroundOption.IsOn =
            _settingsManager.Settings.KeepRunningInBackground;
        ShowTrayIconOption.IsOn =
            _settingsManager.Settings.ShowTrayIcon;
        StatusNotificationsOption.IsOn =
            _settingsManager.Settings.StatusNotifications;

        UpdateTrayIconVisibility();

        _loadingStartupState =
            false;

        _settingsManager.SetStartWithWindows(
            startupEnabled);

        DetectCapsLockOption.Toggled +=
            DetectCapsLockOption_Toggled;
        AutoSwitchKeyboardLanguageOption.Toggled +=
            AutoSwitchKeyboardLanguageOption_Toggled;
        IgnoreShiftPersianToEnglishOption.Toggled +=
            IgnoreShiftPersianToEnglish_Toggled;
        IgnoreShiftEnglishToPersianOption.Toggled +=
            IgnoreShiftEnglishToPersian_Toggled;
        StartWithWindowsOption.Toggled +=
            StartWithWindowsOption_Toggled;
        KeepRunningInBackgroundOption.Toggled +=
            KeepRunningInBackgroundOption_Toggled;
        ShowTrayIconOption.Toggled +=
            ShowTrayIconOption_Toggled;
        StatusNotificationsOption.Toggled +=
            StatusNotificationsOption_Toggled;
        EnabledStateToggle.Toggled +=
            EnabledStateToggle_Toggled;

        DetectCapsLockOption.IsOn =
            _keyboardConverter.DetectCapsLockInMixedCaseEnglish;
        AutoSwitchKeyboardLanguageOption.IsOn =
            _selectionConverter.AutoSwitchKeyboardLanguage;
        IgnoreShiftPersianToEnglishOption.IsOn =
            _keyboardConverter.IgnoreShiftPersianToEnglish;
        IgnoreShiftEnglishToPersianOption.IsOn =
            _keyboardConverter.IgnoreShiftEnglishToPersian;

        ApplyLanguage();

        CurrentShortcutText.Text =
            _currentShortcut.ToString();

        UpdateEnabledState();
    }

    private int _hotkeyRegistrationErrorCode;

    private void ShowLocalizedErrorIfHotkeyRegistrationFailed(
        bool registered,
        int errorCode)
    {
        if (registered)
            return;

        _hotkeyRegistrationErrorCode = errorCode;
        ShowLocalizedError(
            "HotkeyRegistrationFailed",
            errorCode);
    }

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetForegroundWindow(
        IntPtr hWnd);

    private void InstallMinimumWindowSizeHook(
        IntPtr windowHandle)
    {
        IntPtr newProc =
            Marshal.GetFunctionPointerForDelegate(
                _windowProc);

        _originalWindowProc =
            SetWindowLongPtr(
                windowHandle,
                GWLP_WNDPROC,
                newProc);
    }

    private IntPtr WindowProc(
        IntPtr hWnd,
        uint message,
        IntPtr wParam,
        IntPtr lParam)
    {
        if (message == WM_GETMINMAXINFO)
        {
            MINMAXINFO info =
                Marshal.PtrToStructure<MINMAXINFO>(
                    lParam);

            info.ptMinTrackSize.X =
                MinimumWindowWidth;

            info.ptMinTrackSize.Y =
                MinimumWindowHeight;

            Marshal.StructureToPtr(
                info,
                lParam,
                false);

            return IntPtr.Zero;
        }

        if (_originalWindowProc != IntPtr.Zero)
        {
            return CallWindowProc(
                _originalWindowProc,
                hWnd,
                message,
                wParam,
                lParam);
        }

        return DefWindowProc(
            hWnd,
            message,
            wParam,
            lParam);
    }

    

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MINMAXINFO
    {
        public POINT ptReserved;
        public POINT ptMaxSize;
        public POINT ptMaxPosition;
        public POINT ptMinTrackSize;
        public POINT ptMaxTrackSize;
    }

    private delegate IntPtr WndProcDelegate(
        IntPtr hWnd,
        uint message,
        IntPtr wParam,
        IntPtr lParam);

    

    private string L(
        string key)
    {
        return Localization.Get(
            _currentLanguage,
            key);
    }

    private bool IsPersian()
    {
        return Localization.IsPersian(
            _currentLanguage);
    }

    private void ShowLocalizedError(
        string messageKey,
        int errorCode)
    {
        SetStatusText(
            OutputTextBox,
            L(messageKey) +
            "\n\n" +
            L("ErrorCode") +
            errorCode,
            IsPersian());
    }

    private static void SetSettingText(
        TextBlock titleControl,
        TextBlock descriptionControl,
        string title,
        string description,
        bool isPersian)
    {
        titleControl.Text =
            isPersian
                ? $"{Rle}{title}{Pdf}"
                : $"{Lre}{title}{Pdf}";

        descriptionControl.Text =
            isPersian
                ? $"{Rle}{description}{Pdf}"
                : $"{Lre}{description}{Pdf}";

        titleControl.TextAlignment =
            isPersian
                ? TextAlignment.Right
                : TextAlignment.Left;

        descriptionControl.TextAlignment =
            isPersian
                ? TextAlignment.Right
                : TextAlignment.Left;

        titleControl.FlowDirection =
            FlowDirection.LeftToRight;

        descriptionControl.FlowDirection =
            FlowDirection.LeftToRight;

        titleControl.HorizontalAlignment =
            HorizontalAlignment.Stretch;

        descriptionControl.HorizontalAlignment =
            HorizontalAlignment.Stretch;

        titleControl.TextWrapping =
            TextWrapping.Wrap;

        descriptionControl.TextWrapping =
            TextWrapping.Wrap;
    }

    private static void SetBidiText(
        TextBlock control,
        string text,
        bool isPersian,
        TextAlignment englishAlignment =
            TextAlignment.Left)
    {
        control.Text =
            isPersian
                ? $"{Rle}{text}{Pdf}"
                : $"{Lre}{text}{Pdf}";

        control.FlowDirection =
            FlowDirection.LeftToRight;

        control.TextAlignment =
            isPersian
                ? TextAlignment.Right
                : englishAlignment;

        control.HorizontalAlignment =
            HorizontalAlignment.Stretch;

        control.TextWrapping =
            TextWrapping.Wrap;
    }

    private const char Rlm = '\u200F';

    private static void SetAboutText(
        TextBlock control,
        string text,
        bool isPersian)
    {
        control.Text =
            isPersian
                ? $"{Rlm}{text}{Rlm}"
                : text;

        control.FlowDirection =
            FlowDirection.LeftToRight;

        control.TextAlignment =
            isPersian
                ? TextAlignment.Right
                : TextAlignment.Left;

        control.HorizontalAlignment =
            HorizontalAlignment.Stretch;

        control.TextWrapping =
            TextWrapping.Wrap;
    }

    private static void SetShortcutHelpText(
        TextBlock control,
        string text,
        bool isPersian)
    {
        SetBidiText(
            control,
            text,
            isPersian,
            TextAlignment.Left);
    }

    private static void SetStatusText(
        TextBlock control,
        string text,
        bool isPersian)
    {
        SetBidiText(
            control,
            text,
            isPersian,
            TextAlignment.Left);
    }

    

    private void SetShortcutRecorderActive(
        bool active)
    {
        if (active)
        {
            ShortcutRecorderButton.Background =
                new SolidColorBrush(
                    Windows.UI.Color.FromArgb(
                        255,
                        45,
                        45,
                        48));

            ShortcutRecorderButton.BorderBrush =
                new SolidColorBrush(
                    Windows.UI.Color.FromArgb(
                        255,
                        100,
                        100,
                        105));

            ShortcutRecorderText.Foreground =
                new SolidColorBrush(
                    Windows.UI.Color.FromArgb(
                        255,
                        255,
                        255,
                        255));
        }
        else
        {
            ShortcutRecorderButton.ClearValue(
                Button.BackgroundProperty);

            ShortcutRecorderButton.ClearValue(
                Button.BorderBrushProperty);

            ShortcutRecorderText.ClearValue(
                TextBlock.ForegroundProperty);
        }
    }

    private void UpdateShortcutRecorderText()
    {
        if (_recordedMainKey == 0)
        {
            string modifiers =
                GetRecordedModifiersText();

            ShortcutRecorderText.Text =
                string.IsNullOrEmpty(modifiers)
                    ? L("ShortcutPlaceholder")
                    : modifiers;

            return;
        }

        string modifierText =
            GetRecordedModifiersText();

        string mainKeyText =
            GetMainKeyDisplayText(
                _recordedMainKey);

        ShortcutRecorderText.Text =
            string.IsNullOrEmpty(modifierText)
                ? mainKeyText
                : $"{modifierText} + {mainKeyText}";
    }

    

    private void ApplyConversionOptionLayout(
        ToggleSwitch toggle,
        StackPanel textPanel,
        TextBlock title,
        TextBlock description,
        Grid grid,
        bool isPersian)
    {
        grid.FlowDirection =
            FlowDirection.LeftToRight;

        textPanel.FlowDirection =
            FlowDirection.LeftToRight;

        title.FlowDirection =
            FlowDirection.LeftToRight;

        description.FlowDirection =
            FlowDirection.LeftToRight;

        if (isPersian)
        {
            Grid.SetColumn(
                toggle,
                0);

            Grid.SetColumn(
                textPanel,
                1);

            toggle.FlowDirection =
                FlowDirection.LeftToRight;

            toggle.HorizontalAlignment =
                HorizontalAlignment.Left;

            toggle.VerticalAlignment =
                VerticalAlignment.Center;

            toggle.Margin =
                new Thickness(0);

            textPanel.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            textPanel.VerticalAlignment =
                VerticalAlignment.Center;

            textPanel.Margin =
                new Thickness(
                    16,
                    0,
                    0,
                    0);

            title.TextAlignment =
                TextAlignment.Right;

            description.TextAlignment =
                TextAlignment.Right;
        }
        else
        {
            Grid.SetColumn(
                textPanel,
                1);

            Grid.SetColumn(
                toggle,
                2);

            toggle.FlowDirection =
                FlowDirection.RightToLeft;

            toggle.HorizontalAlignment =
                HorizontalAlignment.Right;

            toggle.VerticalAlignment =
                VerticalAlignment.Center;

            toggle.Margin =
                new Thickness(0);

            textPanel.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            textPanel.VerticalAlignment =
                VerticalAlignment.Center;

            textPanel.Margin =
                new Thickness(
                    0,
                    0,
                    16,
                    0);

            title.TextAlignment =
                TextAlignment.Left;

            description.TextAlignment =
                TextAlignment.Left;
        }

        title.HorizontalAlignment =
            HorizontalAlignment.Stretch;

        description.HorizontalAlignment =
            HorizontalAlignment.Stretch;

        title.TextWrapping =
            TextWrapping.Wrap;

        description.TextWrapping =
            TextWrapping.Wrap;
    }

    

    private void ApplyEnabledStateLayout(
        bool isPersian)
    {
        if (isPersian)
        {
            Grid.SetColumn(
                EnabledStateToggle,
                0);

            Grid.SetColumn(
                EnabledStateTextPanel,
                1);

            Grid.SetColumn(
                EnabledStateIndicator,
                2);

            EnabledStateToggle.FlowDirection =
                FlowDirection.LeftToRight;

            EnabledStateToggle.HorizontalAlignment =
                HorizontalAlignment.Left;

            EnabledStateToggle.VerticalAlignment =
                VerticalAlignment.Center;

            EnabledStateToggle.Margin =
                new Thickness(0);

            EnabledStateTextPanel.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            EnabledStateTextPanel.VerticalAlignment =
                VerticalAlignment.Center;

            EnabledStateTextPanel.Margin =
                new Thickness(0);

            EnabledStateIndicator.HorizontalAlignment =
                HorizontalAlignment.Right;

            EnabledStateIndicator.VerticalAlignment =
                VerticalAlignment.Center;

            EnabledStateIndicator.Margin =
                new Thickness(
                    14,
                    0,
                    0,
                    0);
        }
        else
        {
            Grid.SetColumn(
                EnabledStateIndicator,
                0);

            Grid.SetColumn(
                EnabledStateTextPanel,
                1);

            Grid.SetColumn(
                EnabledStateToggle,
                2);

            EnabledStateIndicator.HorizontalAlignment =
                HorizontalAlignment.Left;

            EnabledStateIndicator.VerticalAlignment =
                VerticalAlignment.Center;

            EnabledStateIndicator.Margin =
                new Thickness(
                    0,
                    0,
                    14,
                    0);

            EnabledStateTextPanel.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            EnabledStateTextPanel.VerticalAlignment =
                VerticalAlignment.Center;

            EnabledStateTextPanel.Margin =
                new Thickness(0);

            EnabledStateToggle.FlowDirection =
                FlowDirection.RightToLeft;

            EnabledStateToggle.HorizontalAlignment =
                HorizontalAlignment.Right;

            EnabledStateToggle.VerticalAlignment =
                VerticalAlignment.Center;

            EnabledStateToggle.Margin =
                new Thickness(0);
        }

        EnabledStateToggle.OnContent =
            L("Active");

        EnabledStateToggle.OffContent =
            L("Disabled");
    }

    private void ApplyToggleLocalization(
        ToggleSwitch toggle)
    {
        toggle.OnContent =
            L("On");

        toggle.OffContent =
            L("Off");
    }

    

    private void ApplyLanguage()
    {
        _loadingLanguage =
            true;

        bool isPersian =
            IsPersian();

        RootGrid.FlowDirection =
            FlowDirection.LeftToRight;

        AppTitleBar.FlowDirection =
            FlowDirection.LeftToRight;

        HeaderGrid.FlowDirection =
            FlowDirection.LeftToRight;

        

        if (isPersian)
        {
            Grid.SetColumn(
                LanguagePanel,
                0);

            Grid.SetColumn(
                AppTitlePanel,
                1);

            AppTitlePanel.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            AppTitlePanel.FlowDirection =
                FlowDirection.LeftToRight;

            AppTitleText.Text =
                $"{Rle}KeyFix{Pdf}";

            AppTitleText.FontSize =
                20;

            AppTitleText.FlowDirection =
                FlowDirection.LeftToRight;

            AppTitleText.TextAlignment =
                TextAlignment.Right;

            AppTitleText.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            AppTitleText.TextWrapping =
                TextWrapping.NoWrap;

            AppDescriptionText.Text =
                $"{Rle}{L("Description")}{Pdf}";

            AppDescriptionText.FlowDirection =
                FlowDirection.LeftToRight;

            AppDescriptionText.TextAlignment =
                TextAlignment.Right;

            AppDescriptionText.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            AppDescriptionText.TextWrapping =
                TextWrapping.Wrap;

            LanguagePanel.HorizontalAlignment =
                HorizontalAlignment.Left;

            LanguagePanel.FlowDirection =
                FlowDirection.LeftToRight;

            LanguageLabelText.Text =
                $"{Rle}{L("Language")}{Pdf}";

            LanguageLabelText.FlowDirection =
                FlowDirection.LeftToRight;

            LanguageLabelText.TextAlignment =
                TextAlignment.Right;

            LanguageLabelText.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            LanguageLabelText.TextWrapping =
                TextWrapping.NoWrap;

            LanguageComboBox.FlowDirection =
                FlowDirection.RightToLeft;

            LanguageComboBox.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            LanguageComboBox.HorizontalContentAlignment =
                HorizontalAlignment.Stretch;

            AboutTitleText.FlowDirection =
                FlowDirection.RightToLeft;

            AboutDescriptionText.FlowDirection =
                FlowDirection.RightToLeft;
        }
        else
        {
            Grid.SetColumn(
                AppTitlePanel,
                0);

            Grid.SetColumn(
                LanguagePanel,
                1);

            AppTitlePanel.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            AppTitlePanel.FlowDirection =
                FlowDirection.LeftToRight;

            AppTitleText.Text =
                $"{Lre}KeyFix{Pdf}";

            AppTitleText.FontSize =
                20;

            AppTitleText.FlowDirection =
                FlowDirection.LeftToRight;

            AppTitleText.TextAlignment =
                TextAlignment.Left;

            AppTitleText.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            AppTitleText.TextWrapping =
                TextWrapping.NoWrap;

            AppDescriptionText.Text =
                $"{Lre}{L("Description")}{Pdf}";

            AppDescriptionText.FlowDirection =
                FlowDirection.LeftToRight;

            AppDescriptionText.TextAlignment =
                TextAlignment.Left;

            AppDescriptionText.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            AppDescriptionText.TextWrapping =
                TextWrapping.Wrap;

            LanguagePanel.HorizontalAlignment =
                HorizontalAlignment.Right;

            LanguagePanel.FlowDirection =
                FlowDirection.LeftToRight;

            LanguageLabelText.Text =
                $"{Lre}{L("Language")}{Pdf}";

            LanguageLabelText.FlowDirection =
                FlowDirection.LeftToRight;

            LanguageLabelText.TextAlignment =
                TextAlignment.Left;

            LanguageLabelText.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            LanguageLabelText.TextWrapping =
                TextWrapping.NoWrap;

            LanguageComboBox.FlowDirection =
                FlowDirection.LeftToRight;

            LanguageComboBox.HorizontalAlignment =
                HorizontalAlignment.Stretch;

            LanguageComboBox.HorizontalContentAlignment =
                HorizontalAlignment.Stretch;

            AboutTitleText.FlowDirection =
                FlowDirection.LeftToRight;

            AboutDescriptionText.FlowDirection =
                FlowDirection.LeftToRight;
        }

        LanguageComboBox.Items[0] =
            L("Persian");

        LanguageComboBox.Items[1] =
            L("English");

        LanguageComboBox.SelectedIndex =
            isPersian
                ? 0
                : 1;

        

        SetBidiText(
            EnabledStateText,
            L("KeyFixEnabled"),
            isPersian,
            TextAlignment.Left);

        SetBidiText(
            EnabledStateDescriptionText,
            L("KeyFixStatusDescription"),
            isPersian,
            TextAlignment.Left);

        ApplyEnabledStateLayout(
            isPersian);

        

        SetBidiText(
            ShortcutSectionText,
            L("ShortcutSection"),
            isPersian,
            TextAlignment.Left);

        SetBidiText(
            ShortcutDescriptionText,
            L("ShortcutDescription"),
            isPersian,
            TextAlignment.Left);

        ChangeShortcutButton.Content =
            L("ChangeShortcut");

        ChangeShortcutButton.HorizontalAlignment =
            isPersian
                ? HorizontalAlignment.Right
                : HorizontalAlignment.Left;

        ShortcutEditorTitleText.Text =
            isPersian
                ? $"{Rle}{L("ShortcutEditor")}{Pdf}"
                : $"{Lre}{L("ShortcutEditor")}{Pdf}";

        ShortcutEditorTitleText.FlowDirection =
            FlowDirection.LeftToRight;

        ShortcutEditorTitleText.TextAlignment =
            isPersian
                ? TextAlignment.Right
                : TextAlignment.Left;

        ShortcutEditorTitleText.HorizontalAlignment =
            HorizontalAlignment.Stretch;

        SaveShortcutButton.Content =
            L("Save");

        CancelShortcutButton.Content =
            L("Cancel");

        RetryShortcutButton.Content =
            L("RetryShortcut");

        if (isPersian)
        {
            Grid.SetColumn(
                RetryShortcutButton,
                0);

            Grid.SetColumn(
                ShortcutEditorButtonsPanel,
                1);

            RetryShortcutButton.HorizontalAlignment =
                HorizontalAlignment.Left;

            ShortcutEditorButtonsPanel.HorizontalAlignment =
                HorizontalAlignment.Right;

            ShortcutEditorButtonsPanel.FlowDirection =
                FlowDirection.RightToLeft;
        }
        else
        {
            Grid.SetColumn(
                ShortcutEditorButtonsPanel,
                0);

            Grid.SetColumn(
                RetryShortcutButton,
                1);

            ShortcutEditorButtonsPanel.HorizontalAlignment =
                HorizontalAlignment.Left;

            RetryShortcutButton.HorizontalAlignment =
                HorizontalAlignment.Right;

            ShortcutEditorButtonsPanel.FlowDirection =
                FlowDirection.LeftToRight;
        }

        CurrentShortcutText.FlowDirection =
            FlowDirection.LeftToRight;

        UpdateShortcutRecorderText();

        if (_recordingShortcut)
        {
            SetShortcutRecorderActive(
                true);

            SetShortcutHelpText(
                ShortcutHelpText,
                L("ShortcutHelp"),
                isPersian);
        }
        else if (_shortcutRecordingPaused)
        {
            SetShortcutRecorderActive(
                false);

            SetShortcutHelpText(
                ShortcutHelpText,
                L("ShortcutRecordingStopped"),
                isPersian);
        }
        else
        {
            SetShortcutRecorderActive(
                false);
        }

        

        SetBidiText(
            ExecutionOptionsTitleText,
            L("ExecutionOptions"),
            isPersian,
            TextAlignment.Left);

        SetBidiText(
            ConversionOptionsTitleText,
            L("ConversionOptions"),
            isPersian,
            TextAlignment.Left);

        SetSettingText(
            StartupTitleText,
            StartupDescriptionText,
            L("Startup"),
            L("StartupDescription"),
            isPersian);

        SetSettingText(
            KeepRunningInBackgroundTitleText,
            KeepRunningInBackgroundDescriptionText,
            L("KeepRunningInBackground"),
            L("KeepRunningInBackgroundDescription"),
            isPersian);

        SetSettingText(
            ShowTrayIconTitleText,
            ShowTrayIconDescriptionText,
            L("ShowTrayIcon"),
            L("ShowTrayIconDescription"),
            isPersian);

        SetSettingText(
            StatusNotificationsTitleText,
            StatusNotificationsDescriptionText,
            L("StatusNotifications"),
            L("StatusNotificationsDescription"),
            isPersian);

        SetSettingText(
            AutoSwitchKeyboardLanguageTitleText,
            AutoSwitchKeyboardLanguageDescriptionText,
            L("AutoSwitchKeyboardLanguageTitle"),
            L("AutoSwitchKeyboardLanguageDescription"),
            isPersian);

        SetSettingText(
            DetectCapsLockTitleText,
            DetectCapsLockDescriptionText,
            L("DetectCapsLockTitle"),
            L("DetectCapsLockDescription"),
            isPersian);

        SetSettingText(
            PersianToEnglishTitleText,
            PersianToEnglishDescriptionText,
            L("PersianToEnglish"),
            L("PersianToEnglishDescription"),
            isPersian);

        SetSettingText(
            EnglishToPersianTitleText,
            EnglishToPersianDescriptionText,
            L("EnglishToPersian"),
            L("EnglishToPersianDescription"),
            isPersian);

        ApplyConversionOptionLayout(
            StartWithWindowsOption,
            StartupText,
            StartupTitleText,
            StartupDescriptionText,
            StartupOptionGrid,
            isPersian);

        ApplyConversionOptionLayout(
            KeepRunningInBackgroundOption,
            KeepRunningInBackgroundText,
            KeepRunningInBackgroundTitleText,
            KeepRunningInBackgroundDescriptionText,
            KeepRunningInBackgroundOptionGrid,
            isPersian);

        ApplyConversionOptionLayout(
            ShowTrayIconOption,
            ShowTrayIconText,
            ShowTrayIconTitleText,
            ShowTrayIconDescriptionText,
            ShowTrayIconOptionGrid,
            isPersian);

        ApplyConversionOptionLayout(
            StatusNotificationsOption,
            StatusNotificationsText,
            StatusNotificationsTitleText,
            StatusNotificationsDescriptionText,
            StatusNotificationsOptionGrid,
            isPersian);

        ApplyConversionOptionLayout(
            AutoSwitchKeyboardLanguageOption,
            AutoSwitchKeyboardLanguageText,
            AutoSwitchKeyboardLanguageTitleText,
            AutoSwitchKeyboardLanguageDescriptionText,
            AutoSwitchKeyboardLanguageOptionGrid,
            isPersian);

        ApplyConversionOptionLayout(
            DetectCapsLockOption,
            DetectCapsLockText,
            DetectCapsLockTitleText,
            DetectCapsLockDescriptionText,
            DetectCapsLockOptionGrid,
            isPersian);

        ApplyConversionOptionLayout(
            IgnoreShiftPersianToEnglishOption,
            PersianToEnglishText,
            PersianToEnglishTitleText,
            PersianToEnglishDescriptionText,
            PersianToEnglishOptionGrid,
            isPersian);

        ApplyConversionOptionLayout(
            IgnoreShiftEnglishToPersianOption,
            EnglishToPersianText,
            EnglishToPersianTitleText,
            EnglishToPersianDescriptionText,
            EnglishToPersianOptionGrid,
            isPersian);

        ApplyToggleLocalization(
            StartWithWindowsOption);

        ApplyToggleLocalization(
            KeepRunningInBackgroundOption);

        ApplyToggleLocalization(
            ShowTrayIconOption);

        ApplyToggleLocalization(
            StatusNotificationsOption);

        ApplyToggleLocalization(
            AutoSwitchKeyboardLanguageOption);

        ApplyToggleLocalization(
            DetectCapsLockOption);

        ApplyToggleLocalization(
            IgnoreShiftPersianToEnglishOption);

        ApplyToggleLocalization(
            IgnoreShiftEnglishToPersianOption);

        

        SetBidiText(
            StatusTitleText,
            L("StatusTitle"),
            isPersian,
            TextAlignment.Left);

        SetAboutText(
            AboutTitleText,
            L("About"),
            isPersian);

        SetAboutText(
            AboutDescriptionText,
            L("AboutDescription"),
            isPersian);

        UpdateEnabledState();

        

        TraySettingsCommand.Label =
            L("Settings");

        TraySettingsCommand.Description =
            L("TraySettingsDescription");

        TrayExitCommand.Label =
            L("Exit");

        TrayExitCommand.Description =
            L("TrayExitDescription");

        TrayEnableCommand.Label =
            L("Active");

        TrayEnableCommand.Description =
            L("TrayEnableDescription");

        TrayShowWindowCommand.Label =
            L("ShowKeyFix");

        TrayShowWindowCommand.Description =
            L("TrayShowDescription");

        TrayEnabledItem.Text =
            L("Active");

        TraySettingsItem.Text =
            L("Settings");

        TrayExitItem.Text =
            L("Exit");

        _loadingLanguage =
            false;
    }

    

    private void LanguageComboBox_SelectionChanged(
        object sender,
        SelectionChangedEventArgs e)
    {
        if (_loadingLanguage ||
            LanguageComboBox.SelectedIndex < 0)
        {
            return;
        }

        AppLanguage newLanguage =
            LanguageComboBox.SelectedIndex == 1
                ? AppLanguage.English
                : AppLanguage.Persian;

        if (newLanguage ==
            _currentLanguage)
        {
            return;
        }

        _currentLanguage =
            newLanguage;

        _settingsManager.SetLanguage(
            _currentLanguage);

        ApplyLanguage();
    }

    

    private void EnabledStateToggle_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        if (_loadingEnabledState)
            return;

        bool enabled =
            EnabledStateToggle.IsOn;

        _settingsManager.SetEnabled(
            enabled);

        UpdateEnabledState();
    }

    private void UpdateEnabledState()
    {
        bool enabled =
            _settingsManager.Settings.IsEnabled;

        bool isPersian =
            IsPersian();

        TrayEnabledItem.IsChecked =
            enabled;

        _loadingEnabledState =
            true;

        EnabledStateToggle.IsOn =
            enabled;

        _loadingEnabledState =
            false;

        ApplyEnabledStateLayout(
            isPersian);

        EnabledStateIndicator.Fill =
            new SolidColorBrush(
                enabled
                    ? Windows.UI.Color.FromArgb(
                        255,
                        34,
                        197,
                        94)
                    : Windows.UI.Color.FromArgb(
                        255,
                        239,
                        68,
                        68));

        SetStatusText(
            OutputTextBox,
            enabled
                ? L("EnabledStatus")
                : L("DisabledStatus"),
            isPersian);
    }

    

    private void UiSettings_ColorValuesChanged(
        UISettings sender,
        object args)
    {
        _dispatcherQueue.TryEnqueue(
            UpdateTitleBarTheme);
    }

    private void MainWindow_Activated(
        object sender,
        WindowActivatedEventArgs args)
    {
        UpdateTitleBarTheme();
    }

    private void UpdateTitleBarTheme()
    {
        if (!AppWindowTitleBar.IsCustomizationSupported())
            return;

        UISettings uiSettings =
            _uiSettings ??
            throw new InvalidOperationException(
                "UI settings have not been initialized.");

        AppWindowTitleBar titleBar =
            _appWindow.TitleBar;

        Windows.UI.Color transparent =
            Windows.UI.Color.FromArgb(
                0,
                0,
                0,
                0);

        Windows.UI.Color background =
            uiSettings.GetColorValue(
                UIColorType.Background);

        Windows.UI.Color foreground =
            uiSettings.GetColorValue(
                UIColorType.Foreground);

        bool isDark =
            background.R < 128;

        Windows.UI.Color inactiveForeground =
            isDark
                ? Windows.UI.Color.FromArgb(
                    170,
                    220,
                    220,
                    220)
                : Windows.UI.Color.FromArgb(
                    170,
                    70,
                    70,
                    70);

        Windows.UI.Color hoverBackground =
            isDark
                ? Windows.UI.Color.FromArgb(
                    35,
                    255,
                    255,
                    255)
                : Windows.UI.Color.FromArgb(
                    25,
                    0,
                    0,
                    0);

        Windows.UI.Color pressedBackground =
            isDark
                ? Windows.UI.Color.FromArgb(
                    55,
                    255,
                    255,
                    255)
                : Windows.UI.Color.FromArgb(
                    40,
                    0,
                    0,
                    0);

        titleBar.BackgroundColor =
            transparent;

        titleBar.InactiveBackgroundColor =
            transparent;

        titleBar.ForegroundColor =
            foreground;

        titleBar.InactiveForegroundColor =
            inactiveForeground;

        titleBar.ButtonBackgroundColor =
            transparent;

        titleBar.ButtonInactiveBackgroundColor =
            transparent;

        titleBar.ButtonForegroundColor =
            foreground;

        titleBar.ButtonInactiveForegroundColor =
            inactiveForeground;

        titleBar.ButtonHoverBackgroundColor =
            hoverBackground;

        titleBar.ButtonHoverForegroundColor =
            foreground;

        titleBar.ButtonPressedBackgroundColor =
            pressedBackground;

        titleBar.ButtonPressedForegroundColor =
            foreground;
    }

    

    private async void StartWithWindowsOption_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        if (_loadingStartupState)
            return;

        await SetStartWithWindowsAsync(
            StartWithWindowsOption.IsOn);
    }

    private Task SetStartWithWindowsAsync(
        bool enabled)
    {
        AutoStartManager autoStartManager =
            _autoStartManager ??
            throw new InvalidOperationException(
                "UI has not been initialized.");

        bool success =
            autoStartManager.SetEnabled(
                enabled);

        if (success)
        {
            _settingsManager.SetStartWithWindows(
                enabled);

            return Task.CompletedTask;
        }

        bool actualState =
            autoStartManager.IsEnabled();

        _loadingStartupState =
            true;

        StartWithWindowsOption.IsOn =
            actualState;

        _loadingStartupState =
            false;

        _settingsManager.SetStartWithWindows(
            actualState);

        return Task.CompletedTask;
    }

    private void KeepRunningInBackgroundOption_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        _settingsManager.SetKeepRunningInBackground(
            KeepRunningInBackgroundOption.IsOn);
    }

    private void ShowTrayIconOption_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        _settingsManager.SetShowTrayIcon(
            ShowTrayIconOption.IsOn);

        UpdateTrayIconVisibility();
    }

    private void StatusNotificationsOption_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        _settingsManager.SetStatusNotifications(
            StatusNotificationsOption.IsOn);
    }

    private void UpdateTrayIconVisibility()
    {
        TrayIcon.Visibility =
            _settingsManager.Settings.ShowTrayIcon
                ? Visibility.Visible
                : Visibility.Collapsed;
    }

    private void ShowStatusNotification(
    string message,
    bool force = false)
    {
        if (!force &&
            !_settingsManager.Settings.StatusNotifications)
        {
            return;
        }

        DateTime now =
            DateTime.Now;

        if (!force &&
            message == _lastNotificationText &&
            (now - _lastNotificationTime) < TimeSpan.FromSeconds(2))
        {
            return;
        }

        _lastNotificationText =
            message;

        _lastNotificationTime =
            now;

        try
        {
            ((App)Application.Current).EnsureNotificationsRegistered();

            AppNotificationManager manager =
                AppNotificationManager.Default;

            bool isPersian =
                IsPersian();

            string displayMessage =
                isPersian
                    ? $"{Rle}{message}{Pdf}"
                    : message;

            AppNotification notification =
                new AppNotificationBuilder()
                    .AddText(displayMessage)
                    .BuildNotification();

            notification.Tag =
                StatusNotificationTag;

            notification.Group =
                StatusNotificationTag;

            manager.Show(notification);

            LogNotificationFailure(
                $"Notification shown: {message}");
        }
        catch (Exception ex)
        {
            LogNotificationFailure(
                $"Show failed: {ex}");
        }
    }

    private static void LogNotificationFailure(
        string message)
    {
        try
        {
            string folder =
                Path.Combine(
                    Environment.GetFolderPath(
                        Environment.SpecialFolder.LocalApplicationData),
                    "KeyFix");

            Directory.CreateDirectory(folder);

            File.AppendAllText(
                Path.Combine(folder, "notification.log"),
                $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}{Environment.NewLine}");
        }
        catch
        {
        }
    }

    

    public void HandleExternalLaunch()
    {
        _dispatcherQueue.TryEnqueue(
            () =>
            {
                ShowMainWindow();

                if (!_settingsManager.Settings.IsEnabled)
                {
                    ShowStatusNotification(
                        L("DisabledStatus"),
                        force: true);
                }
            });
    }

    

    private void TrayShowWindowCommand_ExecuteRequested(
        XamlUICommand sender,
        ExecuteRequestedEventArgs args)
    {
        // Left-click on the tray icon toggles only the UI window.
        // The application/process remains running in the background.
        if (_appWindow.IsVisible)
        {
            _appWindow.Hide();
            return;
        }

        ShowMainWindow();
    }

    private void TraySettingsCommand_ExecuteRequested(
        XamlUICommand sender,
        ExecuteRequestedEventArgs args)
    {
        ShowMainWindow();
    }

    private void TrayEnableCommand_ExecuteRequested(
        XamlUICommand sender,
        ExecuteRequestedEventArgs args)
    {
        // The native popup menu does not necessarily flip IsChecked
        // before invoking the command, so derive the new state from
        // the stored setting instead of from the menu item.
        bool enabled =
            !_settingsManager.Settings.IsEnabled;

        EnsureUiInitialized();

        _settingsManager.SetEnabled(
            enabled);

        UpdateEnabledState();
    }

    private void TrayExitCommand_ExecuteRequested(
        XamlUICommand sender,
        ExecuteRequestedEventArgs args)
    {
        ExitApplication();
    }

    

    private void AppWindow_Closing(
        AppWindow sender,
        AppWindowClosingEventArgs args)
    {
        if (_allowRealClose)
            return;

        if (!_settingsManager.Settings.KeepRunningInBackground)
        {
            _allowRealClose =
                true;

            ExitApplication();
            return;
        }

        args.Cancel = true;

        _appWindow.Hide();
    }

    public void ShowMainWindow()
    {
        EnsureUiInitialized();

        _appWindow.Show();
        Activate();

        if (_windowHandle != IntPtr.Zero)
        {
            SetForegroundWindow(_windowHandle);
        }
    }

    private void ExitApplication()
    {
        _allowRealClose =
            true;

        try
        {
            _globalHotKey.Dispose();
        }
        catch
        {
        }

        try
        {
            if (_uiSettings != null)
            {
                _uiSettings.ColorValuesChanged -=
                    UiSettings_ColorValuesChanged;
            }
        }
        catch
        {
        }

        try
        {
            Activated -=
                MainWindow_Activated;
        }
        catch
        {
        }

        try
        {
            if (_uiInitialized)
            {
                RootGrid.RemoveHandler(
                    UIElement.PointerPressedEvent,
                    _rootPointerPressedHandler);
            }
        }
        catch
        {
        }

        try
        {
            if (_windowHandle != IntPtr.Zero &&
                _originalWindowProc != IntPtr.Zero)
            {
                SetWindowLongPtr(
                    _windowHandle,
                    GWLP_WNDPROC,
                    _originalWindowProc);
            }
        }
        catch
        {
        }

        try
        {
            TrayIcon.Dispose();
        }
        catch
        {
        }

        try
        {
            AppNotificationManager.Default.Unregister();
        }
        catch
        {
        }

        _settingsManager.FlushPendingSaves();

        Application.Current.Exit();

        // Do not leave a background WinUI/App SDK process behind. This is
        // especially important during uninstall, where the uninstaller must
        // see KeyFix.exe as fully terminated.
        Environment.Exit(0);
    }

    

    private void AutoSwitchKeyboardLanguageOption_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        bool enabled =
            AutoSwitchKeyboardLanguageOption.IsOn;

        _selectionConverter.AutoSwitchKeyboardLanguage =
            enabled;

        _settingsManager.SetAutoSwitchKeyboardLanguage(
            enabled);
    }

    private void DetectCapsLockOption_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        bool enabled =
            DetectCapsLockOption.IsOn;

        _keyboardConverter
            .DetectCapsLockInMixedCaseEnglish =
            enabled;

        _settingsManager.SetDetectCapsLock(
            enabled);
    }

    private void IgnoreShiftPersianToEnglish_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        bool enabled =
            IgnoreShiftPersianToEnglishOption.IsOn;

        _keyboardConverter
            .IgnoreShiftPersianToEnglish =
            enabled;

        _settingsManager
            .SetIgnoreShiftPersianToEnglish(
                enabled);
    }

    private void IgnoreShiftEnglishToPersian_Toggled(
        object sender,
        RoutedEventArgs e)
    {
        bool enabled =
            IgnoreShiftEnglishToPersianOption.IsOn;

        _keyboardConverter
            .IgnoreShiftEnglishToPersian =
            enabled;

        _settingsManager
            .SetIgnoreShiftEnglishToPersian(
                enabled);
    }

    

    private void ChangeShortcutButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (ShortcutEditorPanel.Visibility ==
            Visibility.Visible)
        {
            CloseShortcutEditor();
            return;
        }

        BeginShortcutRecording();
    }

    private void CloseShortcutEditor()
    {
        StopShortcutRecording();

        ShortcutEditorPanel.Visibility =
            Visibility.Collapsed;

        ShortcutHelpText.Text =
            string.Empty;
    }

    private void RetryShortcutButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        BeginShortcutRecording();
    }

    private void BeginShortcutRecording()
    {
        ClearShortcutRecordingState();

        _recordingShortcut =
            true;

        _shortcutRecordingPaused =
            false;

        ShortcutEditorPanel.Visibility =
            Visibility.Visible;

        RetryShortcutButton.Visibility =
            Visibility.Collapsed;

        SetShortcutRecorderActive(
            true);

        UpdateShortcutRecorderText();

        SetShortcutHelpText(
            ShortcutHelpText,
            L("ShortcutHelp"),
            IsPersian());

        ShortcutRecorderButton.Focus(
            FocusState.Programmatic);
    }

    private void ShortcutRecorderButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        
        if (!_recordingShortcut)
        {
            BeginShortcutRecording();
        }
    }

    

    private void ShortcutRecorderButton_PreviewKeyDown(
        object sender,
        KeyRoutedEventArgs e)
    {
        
        e.Handled = true;

        if (!_recordingShortcut)
            return;

        ProcessShortcutKeyDown(
            (uint)e.Key);
    }

    private void ShortcutRecorderButton_KeyDown(
        object sender,
        KeyRoutedEventArgs e)
    {
        
        e.Handled = true;
    }

    private void ShortcutRecorderButton_KeyUp(
        object sender,
        KeyRoutedEventArgs e)
    {
        e.Handled = true;
    }

    private void ProcessShortcutKeyDown(
        uint key)
    {
        if (!_recordingShortcut)
            return;

        

        if (IsModifierKey(key))
        {
            uint modifier =
                GetModifierForKey(key);

            bool alreadyRecorded =
                (_recordedModifiers & modifier) != 0;

            _recordedModifiers |=
                modifier;

            if (!alreadyRecorded)
            {
                _recordedModifierOrder.Add(
                    modifier);
            }

            int modifierCount =
                CountModifiers(
                    _recordedModifiers);

            if (modifierCount > 3)
            {
                ResetShortcutEditor(
                    L("MaxModifiers"));

                return;
            }

            
            
            if (modifierCount == 1)
            {
                RetryShortcutButton.Visibility =
                    Visibility.Visible;
            }

            UpdateShortcutRecorderText();

            SetShortcutHelpText(
                ShortcutHelpText,
                L("ShortcutHelp"),
                IsPersian());

            return;
        }

        

        if (_shortcutHasMainKey)
        {
            ResetShortcutEditor(
                L("ResetShortcut"));

            return;
        }

        int modifierCountBeforeMainKey =
            CountModifiers(
                _recordedModifiers);

        if (modifierCountBeforeMainKey < 1)
        {
            ResetShortcutEditor(
                L("MinModifiers"));

            return;
        }

        if (!IsAllowedCustomMainKey(
                key))
        {
            ResetShortcutEditor(
                L("InvalidMainKey"));

            return;
        }

        _recordedMainKey =
            key;

        _shortcutHasMainKey =
            true;

        UpdateShortcutRecorderText();

        _recordingShortcut =
            false;

        _shortcutRecordingPaused =
            false;

        SetShortcutRecorderActive(
            false);

        RetryShortcutButton.Visibility =
            Visibility.Visible;

        SetShortcutHelpText(
            ShortcutHelpText,
            L("ValidShortcut"),
            IsPersian());
    }

    

    private void RootGrid_PointerPressed(
        object sender,
        PointerRoutedEventArgs e)
    {
        if (!_recordingShortcut)
            return;

        DependencyObject? source =
            e.OriginalSource as DependencyObject;

        

        
        
        if (IsInsideElement(
                source,
                ShortcutEditorPanel) ||
            IsInsideElement(
                source,
                ChangeShortcutButton))
        {
            return;
        }

        PauseShortcutRecording();
    }

    private void PauseShortcutRecording()
    {
        _recordingShortcut =
            false;

        _shortcutRecordingPaused =
            true;

        SetShortcutRecorderActive(
            false);

        RetryShortcutButton.Visibility =
            Visibility.Visible;

        SetShortcutHelpText(
            ShortcutHelpText,
            L("ShortcutRecordingStopped"),
            IsPersian());
    }

    private static bool IsInsideElement(
        DependencyObject? source,
        DependencyObject target)
    {
        DependencyObject? current =
            source;

        while (current != null)
        {
            if (ReferenceEquals(
                    current,
                    target))
            {
                return true;
            }

            current =
                VisualTreeHelper.GetParent(
                    current);
        }

        return false;
    }

    

    private void CancelShortcutButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        CloseShortcutEditor();
    }

    

    private void SaveShortcutButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        int modifierCount =
            CountModifiers(
                _recordedModifiers);

        if (modifierCount < 1 ||
            modifierCount > 3 ||
            !_shortcutHasMainKey)
        {
            SetShortcutHelpText(
                ShortcutHelpText,
                L("InvalidShortcut"),
                IsPersian());

            return;
        }

        if (!IsAllowedCustomMainKey(
                _recordedMainKey))
        {
            SetShortcutHelpText(
                ShortcutHelpText,
                L("InvalidMainKey"),
                IsPersian());

            return;
        }

        var newShortcut =
            new ShortcutDefinition(
                _recordedModifiers,
                _recordedMainKey);

        if (IsSameShortcut(
                newShortcut,
                _currentShortcut))
        {
            StopShortcutRecording();

            ShortcutEditorPanel.Visibility =
                Visibility.Collapsed;

            ShortcutHelpText.Text =
                string.Empty;

            SetStatusText(
                OutputTextBox,
                L("ShortcutChanged"),
                IsPersian());

            return;
        }

        var testHotKey =
            new GlobalHotKey(
                newShortcut);

        bool registered =
            testHotKey.Register(
                out int errorCode);

        if (!registered)
        {
            testHotKey.Dispose();

            ShowShortcutRegistrationError(
                errorCode);

            return;
        }

        testHotKey.Pressed +=
            OnHotKeyPressed;

        _globalHotKey.Dispose();

        _globalHotKey =
            testHotKey;

        _currentShortcut =
            newShortcut;

        _selectionConverter.UpdateShortcut(
            _currentShortcut);

        _settingsManager.SetShortcut(
            _currentShortcut);

        CurrentShortcutText.Text =
            _currentShortcut.ToString();

        StopShortcutRecording();

        ShortcutEditorPanel.Visibility =
            Visibility.Collapsed;

        ShortcutHelpText.Text =
            string.Empty;

        SetStatusText(
            OutputTextBox,
            L("ShortcutChanged"),
            IsPersian());
    }

    private void ShowShortcutRegistrationError(
        int errorCode)
    {
        SetShortcutHelpText(
            ShortcutHelpText,
            L("ShortcutUnavailable") +
            "\n\n" +
            L("ErrorCode") +
            errorCode,
            IsPersian());
    }

    private static bool IsSameShortcut(
        ShortcutDefinition first,
        ShortcutDefinition second)
    {
        return
            first.Modifiers ==
                second.Modifiers &&

            first.VirtualKey ==
                second.VirtualKey;
    }

    

    private void StopShortcutRecording()
    {
        _recordingShortcut =
            false;

        _shortcutRecordingPaused =
            false;

        ClearShortcutRecordingState();

        SetShortcutRecorderActive(
            false);

        RetryShortcutButton.Visibility =
            Visibility.Collapsed;
    }

    private void ClearShortcutRecordingState()
    {
        _shortcutHasMainKey =
            false;

        _recordedModifiers =
            0;

        _recordedMainKey =
            0;

        _recordedModifierOrder.Clear();
    }

    private void ResetShortcutEditor(
        string message)
    {
        ClearShortcutRecordingState();

        _recordingShortcut =
            true;

        _shortcutRecordingPaused =
            false;

        SetShortcutRecorderActive(
            true);

        UpdateShortcutRecorderText();

        RetryShortcutButton.Visibility =
            Visibility.Collapsed;

        SetShortcutHelpText(
            ShortcutHelpText,
            message,
            IsPersian());

        ShortcutRecorderButton.Focus(
            FocusState.Programmatic);
    }

    

    private string GetRecordedModifiersText()
    {
        var parts =
            new List<string>();

        foreach (uint modifier
                 in _recordedModifierOrder)
        {
            if (modifier == ModifierCtrl)
            {
                parts.Add("Ctrl");
            }
            else if (modifier == ModifierAlt)
            {
                parts.Add("Alt");
            }
            else if (modifier == ModifierShift)
            {
                parts.Add("Shift");
            }
        }

        return string.Join(
            " + ",
            parts);
    }

    private static string GetMainKeyDisplayText(
        uint key)
    {
        return key switch
        {
            VirtualKeySpace =>
                "Space",

            >= 0x70 and <= 0x7B =>
                $"F{key - 0x6F}",

            >= 0x41 and <= 0x5A =>
                ((char)key).ToString(),

            >= 0x30 and <= 0x39 =>
                ((char)key).ToString(),

            >= 0x60 and <= 0x69 =>
                $"Num {key - 0x60}",

            _ =>
                $"0x{key:X2}"
        };
    }

    

    private static int CountModifiers(
        uint modifiers)
    {
        int count = 0;

        if ((modifiers & ModifierAlt) != 0)
            count++;

        if ((modifiers & ModifierCtrl) != 0)
            count++;

        if ((modifiers & ModifierShift) != 0)
            count++;

        return count;
    }

    private static bool IsModifierKey(
        uint key)
    {
        return
            key == VirtualKeyCtrl ||
            key == VirtualKeyShift ||
            key == VirtualKeyAlt;
    }

    private static uint GetModifierForKey(
        uint key)
    {
        return key switch
        {
            VirtualKeyCtrl =>
                ModifierCtrl,

            VirtualKeyAlt =>
                ModifierAlt,

            VirtualKeyShift =>
                ModifierShift,

            _ =>
                0
        };
    }

    

    private static bool IsAllowedCustomMainKey(
        uint key)
    {
        
        if (key == VirtualKeySpace)
            return true;

        if (key >= 0x41 &&
            key <= 0x5A)
        {
            return true;
        }

        if (key >= 0x30 &&
            key <= 0x39)
        {
            return true;
        }

        if (key >= 0x60 &&
            key <= 0x69)
        {
            return true;
        }

        if (key >= 0x6A &&
            key <= 0x6F)
        {
            return true;
        }

        if (key >= 0x70 &&
            key <= 0x7B)
        {
            return true;
        }

        if (key >= 0xBA &&
            key <= 0xC0)
        {
            return true;
        }

        if (key >= 0xDB &&
            key <= 0xDF)
        {
            return true;
        }

        if (key == 0xE2)
            return true;

        return false;
    }

    

    private void OnHotKeyPressed()
    {
        _dispatcherQueue.TryEnqueue(
            async () =>
            {
                await ConvertSelectionAsync();
            });
    }

    

    private async Task ConvertSelectionAsync()
    {
        if (_busy)
            return;

        if (!_settingsManager.Settings.IsEnabled)
        {
            ShowStatusNotification(
                L("DisabledStatus"),
                force: true);

            return;
        }

        _busy = true;

        try
        {
            SetStatusText(
                OutputTextBox,
                L("Converting"),
                IsPersian());

            ConversionResult result =
                await _selectionConverter
                    .ConvertSelectedTextAsync();

            string message =
                result switch
                {
                    ConversionResult.Success =>
                        L("ConversionSuccess"),

                    ConversionResult.NoSelectionFound =>
                        L("NoSelection"),

                    ConversionResult.NothingToConvert =>
                        L("NothingToConvert"),

                    ConversionResult.FocusChanged =>
                        L("FocusChanged"),

                    ConversionResult.InputInjectionFailed =>
                        L("InputInjectionFailed"),

                    ConversionResult.ClipboardError =>
                        L("ClipboardError"),

                    _ =>
                        L("UnknownError")
                };

            SetStatusText(
                OutputTextBox,
                message,
                IsPersian());

            ShowStatusNotification(
                message);
        }
        catch (Exception ex)
        {
            string errorMessage =
                L("ErrorPrefix") +
                "\n" +
                ex.Message;

            SetStatusText(
                OutputTextBox,
                errorMessage,
                IsPersian());

            ShowStatusNotification(
                errorMessage);
        }
        finally
        {
            _busy = false;
        }
    }

    

    private static void SetWindowIcon(
        IntPtr windowHandle,
        string iconPath)
    {
        if (!File.Exists(iconPath))
            return;

        IntPtr hIcon =
            LoadImage(
                IntPtr.Zero,
                iconPath,
                IMAGE_ICON,
                0,
                0,
                LR_LOADFROMFILE |
                LR_DEFAULTSIZE);

        if (hIcon == IntPtr.Zero)
            return;

        SendMessage(
            windowHandle,
            WM_SETICON,
            ICON_SMALL,
            hIcon);

        SendMessage(
            windowHandle,
            WM_SETICON,
            ICON_BIG,
            hIcon);
    }

    

    private const uint WM_SETICON =
        0x0080;

    private static readonly IntPtr ICON_SMALL =
        new(0);

    private static readonly IntPtr ICON_BIG =
        new(1);

    private const uint IMAGE_ICON =
        1;

    private const uint LR_LOADFROMFILE =
        0x00000010;

    private const uint LR_DEFAULTSIZE =
        0x00000040;

    

    [DllImport(
        "user32.dll",
        SetLastError = true,
        CharSet = CharSet.Unicode)]
    private static extern IntPtr LoadImage(
        IntPtr hInst,
        string name,
        uint type,
        int cx,
        int cy,
        uint fuLoad);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern IntPtr SendMessage(
        IntPtr hWnd,
        uint msg,
        IntPtr wParam,
        IntPtr lParam);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern IntPtr DefWindowProc(
        IntPtr hWnd,
        uint msg,
        IntPtr wParam,
        IntPtr lParam);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern IntPtr CallWindowProc(
        IntPtr lpPrevWndFunc,
        IntPtr hWnd,
        uint message,
        IntPtr wParam,
        IntPtr lParam);

    [DllImport(
        "user32.dll",
        EntryPoint = "SetWindowLongPtrW",
        SetLastError = true)]
    private static extern IntPtr SetWindowLongPtr64(
        IntPtr hWnd,
        int nIndex,
        IntPtr dwNewLong);

    [DllImport(
        "user32.dll",
        EntryPoint = "SetWindowLongW",
        SetLastError = true)]
    private static extern int SetWindowLong32(
        IntPtr hWnd,
        int nIndex,
        int dwNewLong);

    private static IntPtr SetWindowLongPtr(
        IntPtr hWnd,
        int nIndex,
        IntPtr dwNewLong)
    {
        if (IntPtr.Size == 8)
        {
            return SetWindowLongPtr64(
                hWnd,
                nIndex,
                dwNewLong);
        }

        return new IntPtr(
            SetWindowLong32(
                hWnd,
                nIndex,
                dwNewLong.ToInt32()));
    }
}
