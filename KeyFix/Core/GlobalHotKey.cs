using System;
using System.Runtime.InteropServices;
using System.Threading;

namespace KeyFix.Core;

public sealed class GlobalHotKey : IDisposable
{
    private const int WM_HOTKEY = 0x0312;
    private const int WM_QUIT = 0x0012;

    private const uint WM_APP_REGISTER = 0x8001;

    private const int HOTKEY_ID = 1001;

    private readonly ShortcutDefinition _shortcut;

    private readonly Thread _thread;

    private readonly ManualResetEventSlim _threadReady =
        new(false);

    private readonly ManualResetEventSlim _registrationComplete =
        new(false);

    private uint _threadId;

    private bool _registered;

    private bool _disposed;

    private int _registrationError;

    public event Action? Pressed;

    public GlobalHotKey(
        ShortcutDefinition shortcut)
    {
        _shortcut = shortcut;

        _thread =
            new Thread(
                HotKeyThread)
            {
                IsBackground = true,
                Name = "KeyFix HotKey Thread"
            };

        _thread.Start();

        _threadReady.Wait();
    }

    public bool Register(
        out int errorCode)
    {
        errorCode = 0;

        if (_disposed)
        {
            errorCode = -1;
            return false;
        }

        if (_registered)
        {
            return true;
        }

        _registrationComplete.Reset();

        if (!PostThreadMessage(
                _threadId,
                WM_APP_REGISTER,
                IntPtr.Zero,
                IntPtr.Zero))
        {
            errorCode =
                Marshal.GetLastWin32Error();

            return false;
        }

        _registrationComplete.Wait();

        errorCode =
            _registrationError;

        return _registered;
    }

    private void HotKeyThread()
    {
        _threadId =
            GetCurrentThreadId();

        PeekMessage(
            out _,
            IntPtr.Zero,
            0,
            0,
            0);

        _threadReady.Set();

        while (!_disposed)
        {
            int result =
                GetMessage(
                    out MSG message,
                    IntPtr.Zero,
                    0,
                    0);

            if (result == -1)
                break;

            if (result == 0)
                break;

            if (message.Message ==
                WM_APP_REGISTER)
            {
                RegisterOnThisThread();

                continue;
            }

            if (message.Message ==
                    WM_HOTKEY &&
                message.WParam.ToInt32() ==
                    HOTKEY_ID)
            {
                try
                {
                    Pressed?.Invoke();
                }
                catch
                {
                    
                }

                continue;
            }

            TranslateMessage(
                ref message);

            DispatchMessage(
                ref message);
        }

        if (_registered)
        {
            UnregisterHotKey(
                IntPtr.Zero,
                HOTKEY_ID);

            _registered = false;
        }
    }

    private void RegisterOnThisThread()
    {
        if (_registered)
        {
            _registrationError = 0;

            _registrationComplete.Set();

            return;
        }

        _registered =
            RegisterHotKey(
                IntPtr.Zero,
                HOTKEY_ID,
                _shortcut.Modifiers |
                MOD_NOREPEAT,
                _shortcut.VirtualKey);

        _registrationError =
            _registered
                ? 0
                : Marshal.GetLastWin32Error();

        _registrationComplete.Set();
    }

    public void Dispose()
    {
        if (_disposed)
            return;

        _disposed = true;

        if (_threadId != 0)
        {
            PostThreadMessage(
                _threadId,
                WM_QUIT,
                IntPtr.Zero,
                IntPtr.Zero);
        }

        _threadReady.Dispose();

        _registrationComplete.Dispose();
    }

    private const uint MOD_NOREPEAT =
        0x4000;

    private const uint MOD_ALT =
        0x0001;

    private const uint MOD_CONTROL =
        0x0002;

    private const uint MOD_SHIFT =
        0x0004;

    private const uint MOD_WIN =
        0x0008;

    [StructLayout(
        LayoutKind.Sequential)]
    private struct MSG
    {
        public IntPtr HWnd;

        public uint Message;

        public IntPtr WParam;

        public IntPtr LParam;

        public uint Time;

        public POINT Point;

        public uint Private;
    }

    [StructLayout(
        LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;

        public int Y;
    }

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern bool RegisterHotKey(
        IntPtr hWnd,
        int id,
        uint fsModifiers,
        uint vk);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern bool UnregisterHotKey(
        IntPtr hWnd,
        int id);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern bool PostThreadMessage(
        uint idThread,
        uint Msg,
        IntPtr wParam,
        IntPtr lParam);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern int GetMessage(
        out MSG lpMsg,
        IntPtr hWnd,
        uint wMsgFilterMin,
        uint wMsgFilterMax);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern bool PeekMessage(
        out MSG lpMsg,
        IntPtr hWnd,
        uint wMsgFilterMin,
        uint wMsgFilterMax,
        uint wRemoveMsg);

    [DllImport("user32.dll")]
    private static extern bool TranslateMessage(
        ref MSG lpMsg);

    [DllImport("user32.dll")]
    private static extern IntPtr DispatchMessage(
        ref MSG lpMsg);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();
}