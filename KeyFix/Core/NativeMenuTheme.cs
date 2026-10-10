using System;
using System.Runtime.InteropServices;
using Windows.UI.ViewManagement;

namespace KeyFix.Core;

/// <summary>
/// Makes the native Win32 popup menu used by the tray icon follow the
/// same light/dark theme as the app window.
///
/// The app derives its theme from the system "app mode"
/// (UISettings Background colour), so the menu is forced to exactly
/// the same decision. Uses the undocumented uxtheme ordinals 135
/// (SetPreferredAppMode) and 136 (FlushMenuThemes), which are the
/// standard way to theme native menus on Windows 10 1903+ / Windows 11.
/// Every call is best-effort: on failure the menu simply keeps the
/// default system look.
/// </summary>
internal static class NativeMenuTheme
{
    private enum PreferredAppMode
    {
        Default = 0,
        AllowDark = 1,
        ForceDark = 2,
        ForceLight = 3
    }

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate int SetPreferredAppModeDelegate(
        PreferredAppMode appMode);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate void FlushMenuThemesDelegate();

    [DllImport(
        "kernel32.dll",
        CharSet = CharSet.Unicode,
        SetLastError = true)]
    private static extern IntPtr LoadLibrary(
        string fileName);

    [DllImport(
        "kernel32.dll",
        SetLastError = true)]
    private static extern IntPtr GetProcAddress(
        IntPtr module,
        IntPtr ordinal);

    private static readonly object Sync = new();

    private static UISettings? _uiSettings;
    private static SetPreferredAppModeDelegate? _setPreferredAppMode;
    private static FlushMenuThemesDelegate? _flushMenuThemes;
    private static bool _resolved;

    /// <summary>
    /// Applies the current theme and keeps it updated while the
    /// process lives, even if the main window was never created
    /// (background start).
    /// </summary>
    public static void Initialize()
    {
        try
        {
            lock (Sync)
            {
                if (_uiSettings != null)
                    return;

                _uiSettings =
                    new UISettings();

                _uiSettings.ColorValuesChanged +=
                    (_, _) => Apply();
            }

            Apply();
        }
        catch
        {
        }
    }

    public static void Apply()
    {
        try
        {
            lock (Sync)
            {
                Resolve();

                if (_setPreferredAppMode == null)
                    return;

                UISettings settings =
                    _uiSettings ??= new UISettings();

                bool isDark =
                    settings
                        .GetColorValue(UIColorType.Background)
                        .R < 128;

                _setPreferredAppMode(
                    isDark
                        ? PreferredAppMode.ForceDark
                        : PreferredAppMode.ForceLight);

                _flushMenuThemes?.Invoke();
            }
        }
        catch
        {
        }
    }

    private static void Resolve()
    {
        if (_resolved)
            return;

        _resolved = true;

        IntPtr module =
            LoadLibrary("uxtheme.dll");

        if (module == IntPtr.Zero)
            return;

        IntPtr setMode =
            GetProcAddress(
                module,
                new IntPtr(135));

        IntPtr flush =
            GetProcAddress(
                module,
                new IntPtr(136));

        if (setMode != IntPtr.Zero)
        {
            _setPreferredAppMode =
                Marshal.GetDelegateForFunctionPointer<
                    SetPreferredAppModeDelegate>(
                    setMode);
        }

        if (flush != IntPtr.Zero)
        {
            _flushMenuThemes =
                Marshal.GetDelegateForFunctionPointer<
                    FlushMenuThemesDelegate>(
                    flush);
        }
    }
}
