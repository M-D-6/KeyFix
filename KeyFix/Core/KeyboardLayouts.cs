using System;
using System.Runtime.InteropServices;

namespace KeyFix.Core;

public static class KeyboardLayouts
{
    public static readonly IntPtr English =
        LoadKeyboardLayout(
            "00000409",
            KLF_ACTIVATE);

    public static readonly IntPtr Persian =
        LoadKeyboardLayout(
            "00000429",
            KLF_ACTIVATE);

    private const uint KLF_ACTIVATE = 0x00000001;

    private const uint WM_INPUTLANGCHANGEREQUEST = 0x0050;

    [DllImport(
        "user32.dll",
        CharSet = CharSet.Unicode)]
    private static extern IntPtr LoadKeyboardLayout(
        string pwszKLID,
        uint flags);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern IntPtr GetForegroundWindow();

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern IntPtr PostMessage(
        IntPtr hWnd,
        uint msg,
        IntPtr wParam,
        IntPtr lParam);

    public static void SetForegroundLanguage(
        IntPtr keyboardLayout)
    {
        if (keyboardLayout == IntPtr.Zero)
            return;

        IntPtr foregroundWindow =
            GetForegroundWindow();

        if (foregroundWindow == IntPtr.Zero)
            return;

        PostMessage(
            foregroundWindow,
            WM_INPUTLANGCHANGEREQUEST,
            IntPtr.Zero,
            keyboardLayout);
    }
}