using KeyFix.Core;
using Microsoft.Windows.AppNotifications;
using Microsoft.UI.Xaml;
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Runtime.Versioning;

namespace KeyFix;

[SupportedOSPlatform("windows10.0.17763.0")]
public partial class App : Application
{
    private MainWindow? _window;

    private bool _notificationsRegistered;

    private const string SingleInstanceMutexName =
        @"Local\KeyFix.SingleInstance";

    private static Mutex? _singleInstanceMutex;

    private static EventWaitHandle? _activationEvent;
    private static RegisteredWaitHandle? _activationRegistration;

    private const string ActivationEventName =
        @"Local\KeyFix.ActivateWindow";

    private const string InitialLanguageArgument =
        "--initial-language=";

    public App()
    {
        InitializeComponent();

        RegisterGlobalExceptionHandlers();
    }

    private static void RegisterGlobalExceptionHandlers()
    {
        Current.UnhandledException +=
            (_, e) =>
            {
                LogCrash(
                    "UI thread",
                    e.Exception);

                e.Handled = true;
            };

        AppDomain.CurrentDomain.UnhandledException +=
            (_, e) =>
            {
                LogCrash(
                    "Non-UI thread (fatal)",
                    e.ExceptionObject as Exception);
            };

        TaskScheduler.UnobservedTaskException +=
            (_, e) =>
            {
                LogCrash(
                    "Unobserved Task",
                    e.Exception);

                e.SetObserved();
            };
    }

    private static void LogCrash(
        string source,
        Exception? exception)
    {
        try
        {
            string folder =
                Path.Combine(
                    Environment.GetFolderPath(
                        Environment.SpecialFolder.LocalApplicationData),
                    "KeyFix");

            Directory.CreateDirectory(folder);

            string logPath =
                Path.Combine(
                    folder,
                    "crash.log");

            File.AppendAllText(
                logPath,
                $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] ({source})\n{exception}\n\n");
        }
        catch
        {
        }
    }

    protected override void OnLaunched(
        Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        string[] commandLineArguments =
            Environment.GetCommandLineArgs();

        _singleInstanceMutex =
            new Mutex(
                initiallyOwned: true,
                name: SingleInstanceMutexName,
                createdNew: out bool isFirstInstance);

        if (!isFirstInstance)
        {
            SignalFirstInstance();

            Environment.Exit(0);

            return;
        }

        CreateActivationEvent();

        ApplyInitialLanguageIfNeeded(
            commandLineArguments);

        bool startedFromStartup =
            HasArgument(
                commandLineArguments,
                "--startup");

        // Startup launches into a deliberately lightweight background mode:
        // the tray icon and hotkey are initialized, while the visual settings
        // UI, title-bar customization and other window-only work are deferred
        // until the user actually opens KeyFix.
        _window =
            new MainWindow(startedFromStartup);

        if (!startedFromStartup)
        {
            RegisterNotifications();
        }

        StartActivationListener();

        if (!startedFromStartup)
        {
            _window.Activate();
        }
    }

    private void RegisterNotifications()
    {
        try
        {
            if (_notificationsRegistered)
            {
                LogNotification(
                    "Skipped",
                    "Notifications already registered.");

                return;
            }

            if (!AppNotificationManager.IsSupported())
            {
                LogNotification(
                    "Unsupported",
                    "AppNotificationManager.IsSupported() returned false.");

                return;
            }

            AppNotificationManager manager =
                AppNotificationManager.Default;

            manager.NotificationInvoked -=
                NotificationManager_NotificationInvoked;

            manager.NotificationInvoked +=
                NotificationManager_NotificationInvoked;

            manager.Register();

            _notificationsRegistered = true;

            LogNotification(
                "Registered",
                $"App notifications registered. Setting: {manager.Setting}");
        }
        catch (Exception ex)
        {
            LogNotification(
                "Register failed",
                ex.ToString());
        }
    }

    public void EnsureNotificationsRegistered()
    {
        RegisterNotifications();
    }

    private void NotificationManager_NotificationInvoked(
        AppNotificationManager sender,
        AppNotificationActivatedEventArgs args)
    {
        try
        {
            MainWindow? window = _window;

            if (window == null)
                return;

            window.DispatcherQueue.TryEnqueue(
                window.ShowMainWindow);
        }
        catch (Exception ex)
        {
            LogNotification(
                "Notification activation failed",
                ex.ToString());
        }
    }

    private static void LogNotification(
        string source,
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

            string logPath =
                Path.Combine(
                    folder,
                    "notification.log");

            File.AppendAllText(
                logPath,
                $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] ({source}) {message}{Environment.NewLine}");
        }
        catch
        {
        }
    }

    private static void CreateActivationEvent()
    {
        try
        {
            _activationEvent =
                new EventWaitHandle(
                    false,
                    EventResetMode.AutoReset,
                    ActivationEventName);
        }
        catch
        {
            _activationEvent = null;
        }
    }

    private static void SignalFirstInstance()
    {
        try
        {
            using EventWaitHandle activationEvent =
                EventWaitHandle.OpenExisting(
                    ActivationEventName);

            activationEvent.Set();
        }
        catch
        {
        }
    }

    private void StartActivationListener()
    {
        if (_activationEvent == null)
            return;

        _activationRegistration =
            ThreadPool.RegisterWaitForSingleObject(
                _activationEvent,
                static (state, timedOut) =>
                {
                    if (timedOut || state is not App app)
                        return;

                    app._window?.HandleExternalLaunch();
                },
                this,
                Timeout.Infinite,
                executeOnlyOnce: false);
    }

    private void StopActivationListener()
    {
        try
        {
            _activationRegistration?.Unregister(null);
        }
        catch
        {
        }
        finally
        {
            _activationRegistration = null;
        }
    }

    private static void ApplyInitialLanguageIfNeeded(
        string[] arguments)
    {
        string? initialLanguage =
            GetInitialLanguage(arguments);

        if (string.IsNullOrWhiteSpace(initialLanguage))
            return;

        try
        {
            string settingsPath =
                Path.Combine(
                    Environment.GetFolderPath(
                        Environment.SpecialFolder.LocalApplicationData),
                    "KeyFix",
                    "Settings.json");

            if (File.Exists(settingsPath))
                return;

            SettingsManager settingsManager =
                new SettingsManager();

            settingsManager.SetLanguage(
                string.Equals(
                    initialLanguage,
                    "en",
                    StringComparison.OrdinalIgnoreCase)
                    ? AppLanguage.English
                    : AppLanguage.Persian);
        }
        catch
        {
        }
    }

    private static string? GetInitialLanguage(
        string[] arguments)
    {
        foreach (string argument in arguments)
        {
            if (!argument.StartsWith(
                    InitialLanguageArgument,
                    StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            string value =
                argument[
                    InitialLanguageArgument.Length..];

            if (value.Equals(
                    "fa",
                    StringComparison.OrdinalIgnoreCase))
            {
                return "fa";
            }

            if (value.Equals(
                    "en",
                    StringComparison.OrdinalIgnoreCase))
            {
                return "en";
            }
        }

        return null;
    }

    private static bool HasArgument(
        string[] arguments,
        string expected)
    {
        return Array.Exists(
            arguments,
            argument =>
                string.Equals(
                    argument,
                    expected,
                    StringComparison.OrdinalIgnoreCase));
    }
}