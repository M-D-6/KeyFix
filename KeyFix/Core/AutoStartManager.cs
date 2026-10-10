using Microsoft.Win32;
using System;
using System.Diagnostics;
using System.IO;

namespace KeyFix.Core;

public sealed class AutoStartManager
{
    private const string RegistryPath =
        @"Software\Microsoft\Windows\CurrentVersion\Run";

    private const string RegistryValueName =
        "KeyFix";

    private const string StartupArgument =
        "--startup";

    public bool IsEnabled()
    {
        try
        {
            using RegistryKey? key =
                Registry.CurrentUser.OpenSubKey(
                    RegistryPath,
                    writable: false);

            if (key == null)
                return false;

            object? value =
                key.GetValue(
                    RegistryValueName);

            if (value is not string command)
                return false;

            string? executablePath =
                Environment.ProcessPath;

            if (string.IsNullOrWhiteSpace(
                    executablePath))
            {
                return false;
            }

            string expectedCommand =
                BuildCommand(
                    executablePath);

            return string.Equals(
                command,
                expectedCommand,
                StringComparison.OrdinalIgnoreCase);
        }
        catch
        {
            return false;
        }
    }

    public bool SetEnabled(
        bool enabled)
    {
        try
        {
            using RegistryKey key =
                Registry.CurrentUser.CreateSubKey(
                    RegistryPath);

            if (!enabled)
            {
                key.DeleteValue(
                    RegistryValueName,
                    throwOnMissingValue: false);

                return true;
            }

            string? executablePath =
                Environment.ProcessPath;

            if (string.IsNullOrWhiteSpace(
                    executablePath))
            {
                return false;
            }

            string command =
                BuildCommand(
                    executablePath);

            key.SetValue(
                RegistryValueName,
                command,
                RegistryValueKind.String);

            return true;
        }
        catch
        {
            return false;
        }
    }

    public void RefreshCurrentPath()
    {
        try
        {
            string? executablePath =
                Environment.ProcessPath;

            if (string.IsNullOrWhiteSpace(
                    executablePath))
            {
                return;
            }

            using RegistryKey? key =
                Registry.CurrentUser.OpenSubKey(
                    RegistryPath,
                    writable: true);

            if (key == null)
                return;

            object? existingValue =
                key.GetValue(
                    RegistryValueName);

            if (existingValue is not string)
                return;

            key.SetValue(
                RegistryValueName,
                BuildCommand(
                    executablePath),
                RegistryValueKind.String);
        }
        catch
        {
            
        }
    }

    private static string BuildCommand(
        string executablePath)
    {
        string fullPath =
            Path.GetFullPath(
                executablePath);

        return
            $"\"{fullPath}\" {StartupArgument}";
    }
}