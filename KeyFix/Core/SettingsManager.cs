using System;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace KeyFix.Core;

public sealed class KeyFixSettings
{
    
    public uint ShortcutModifiers { get; set; } =
        0x0002;

    public uint ShortcutVirtualKey { get; set; } =
        0x4B;

    public bool DetectCapsLockInMixedCaseEnglish { get; set; } =
        true;

    public bool AutoSwitchKeyboardLanguage { get; set; } =
        true;

    public bool IgnoreShiftPersianToEnglish { get; set; } =
        false;

    public bool IgnoreShiftEnglishToPersian { get; set; } =
        false;

    public bool IsEnabled { get; set; } =
        true;

    public bool StartWithWindows { get; set; } =
        true;

    public bool KeepRunningInBackground { get; set; } =
        true;

    public bool ShowTrayIcon { get; set; } =
        true;

    public bool StatusNotifications { get; set; } =
        true;

    public string Language { get; set; } =
        "fa";
}

public sealed class SettingsManager
{
    private readonly string _settingsPath;

    private static readonly JsonSerializerOptions JsonOptions =
        new()
        {
            WriteIndented = true
        };

    public KeyFixSettings Settings { get; private set; }

    public SettingsManager()
    {
        string folder =
            Environment.GetFolderPath(
                Environment.SpecialFolder.LocalApplicationData);

        string keyFixFolder =
            Path.Combine(
                folder,
                "KeyFix");

        Directory.CreateDirectory(
            keyFixFolder);

        _settingsPath =
            Path.Combine(
                keyFixFolder,
                "Settings.json");

        Settings =
            Load();
    }

    private readonly object _saveLock =
        new();

    private CancellationTokenSource? _saveCancellation;
    private Task _pendingSave =
        Task.CompletedTask;
    private int _saveVersion;

    public void Save()
    {
        try
        {
            lock (_saveLock)
            {
                _saveVersion++;
                int version = _saveVersion;

                _saveCancellation?.Cancel();

                var cancellation =
                    new CancellationTokenSource();

                _saveCancellation =
                    cancellation;

                _pendingSave =
                    SaveAfterDelayAsync(
                        version,
                        cancellation);
            }
        }
        catch
        {
        }
    }

    private async Task SaveAfterDelayAsync(
        int version,
        CancellationTokenSource cancellation)
    {
        try
        {
            await Task.Delay(500, cancellation.Token);

            lock (_saveLock)
            {
                if (version != _saveVersion)
                    return;

                string json =
                    JsonSerializer.Serialize(
                        Settings,
                        JsonOptions);

                try
                {
                    File.WriteAllText(
                        _settingsPath,
                        json);
                }
                catch
                {
                }
            }
        }
        catch (OperationCanceledException)
        {
        }
        catch
        {
        }
        finally
        {
            lock (_saveLock)
            {
                if (ReferenceEquals(
                        _saveCancellation,
                        cancellation))
                {
                    _saveCancellation = null;
                }
            }

            cancellation.Dispose();
        }
    }

    public void FlushPendingSaves()
    {
        Task pending;

        lock (_saveLock)
        {
            _saveCancellation?.Cancel();
            pending = _pendingSave;
        }

        try
        {
            pending.GetAwaiter().GetResult();

            lock (_saveLock)
            {
                string json =
                    JsonSerializer.Serialize(
                        Settings,
                        JsonOptions);

                File.WriteAllText(
                    _settingsPath,
                    json);
            }
        }
        catch
        {
        }
    }

    private KeyFixSettings Load()
    {
        try
        {
            if (!File.Exists(_settingsPath))
            {
                return new KeyFixSettings();
            }

            string json =
                File.ReadAllText(
                    _settingsPath);

            KeyFixSettings? settings =
                JsonSerializer.Deserialize<KeyFixSettings>(
                    json,
                    JsonOptions);

            return Validate(
                settings ??
                new KeyFixSettings());
        }
        catch
        {
            
            return new KeyFixSettings();
        }
    }

    private static KeyFixSettings Validate(
        KeyFixSettings settings)
    {
        var defaults =
            new KeyFixSettings();

        const uint AllowedModifierMask =
            0x0001 | 0x0002 | 0x0004 | 0x0008;

        if ((settings.ShortcutModifiers &
             ~AllowedModifierMask) != 0)
        {
            settings.ShortcutModifiers =
                defaults.ShortcutModifiers;
        }

        if (settings.ShortcutVirtualKey == 0 ||
            settings.ShortcutVirtualKey > 0xFE)
        {
            settings.ShortcutVirtualKey =
                defaults.ShortcutVirtualKey;
        }

        if (settings.Language != "fa" &&
            settings.Language != "en")
        {
            settings.Language =
                defaults.Language;
        }

        return settings;
    }

    public ShortcutDefinition GetShortcut()
    {
        return new ShortcutDefinition(
            Settings.ShortcutModifiers,
            Settings.ShortcutVirtualKey);
    }

    public void SetShortcut(
        ShortcutDefinition shortcut)
    {
        Settings.ShortcutModifiers =
            shortcut.Modifiers;

        Settings.ShortcutVirtualKey =
            shortcut.VirtualKey;

        Save();
    }

    public void SetDetectCapsLock(
        bool value)
    {
        Settings.DetectCapsLockInMixedCaseEnglish =
            value;

        Save();
    }

    public void SetAutoSwitchKeyboardLanguage(
        bool value)
    {
        Settings.AutoSwitchKeyboardLanguage =
            value;

        Save();
    }

    public void SetIgnoreShiftPersianToEnglish(
        bool value)
    {
        Settings.IgnoreShiftPersianToEnglish =
            value;

        Save();
    }

    public void SetIgnoreShiftEnglishToPersian(
        bool value)
    {
        Settings.IgnoreShiftEnglishToPersian =
            value;

        Save();
    }

    public void SetEnabled(
        bool value)
    {
        Settings.IsEnabled =
            value;

        Save();
    }

    public void SetStartWithWindows(
        bool value)
    {
        Settings.StartWithWindows =
            value;

        Save();
    }

    public void SetKeepRunningInBackground(
        bool value)
    {
        Settings.KeepRunningInBackground =
            value;
        Save();
    }

    public void SetShowTrayIcon(
        bool value)
    {
        Settings.ShowTrayIcon =
            value;

        Save();
    }

    public void SetStatusNotifications(
        bool value)
    {
        Settings.StatusNotifications =
            value;

        Save();
    }

    public void SetLanguage(
        AppLanguage language)
    {
        Settings.Language =
            Localization.ToCode(
                language);

        Save();
    }

    public AppLanguage GetLanguage()
    {
        return Localization.Parse(
            Settings.Language);
    }
}