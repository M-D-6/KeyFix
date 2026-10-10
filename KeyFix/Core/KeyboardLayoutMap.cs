using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;

namespace KeyFix.Core;

public readonly record struct KeyStroke(
    byte VirtualKey,
    bool Shift,
    bool CapsLock
);

public sealed class KeyboardLayoutMap
{
    private const uint MAPVK_VK_TO_VSC = 0;

    private const byte VK_SHIFT = 0x10;
    private const byte VK_CAPITAL = 0x14;

    private static readonly byte[] VirtualKeys = BuildVirtualKeys();

    private readonly Dictionary<KeyStroke, string> _keyToText = new();
    private readonly Dictionary<string, KeyStroke> _textToKey = new();

    public IReadOnlyDictionary<KeyStroke, string> KeyToText => _keyToText;
    public IReadOnlyDictionary<string, KeyStroke> TextToKey => _textToKey;

    public KeyboardLayoutMap(IntPtr keyboardLayout)
    {
        Build(keyboardLayout);
    }

    private void Build(IntPtr keyboardLayout)
    {
        foreach (byte virtualKey in VirtualKeys)
        {
            foreach (bool shift in new[] { false, true })
            {
                foreach (bool capsLock in new[] { false, true })
                {
                    var keyStroke = new KeyStroke(
                        virtualKey,
                        shift,
                        capsLock
                    );

                    string? text = TranslateKey(
                        virtualKey,
                        shift,
                        capsLock,
                        keyboardLayout
                    );

                    if (string.IsNullOrEmpty(text))
                        continue;

                    _keyToText[keyStroke] = text;

                    if (!_textToKey.ContainsKey(text))
                    {
                        _textToKey[text] = keyStroke;
                    }
                }
            }
        }
    }

    private static string? TranslateKey(
        byte virtualKey,
        bool shift,
        bool capsLock,
        IntPtr keyboardLayout)
    {
        uint scanCode = MapVirtualKeyEx(
            virtualKey,
            MAPVK_VK_TO_VSC,
            keyboardLayout
        );

        if (scanCode == 0)
            return null;

        var keyboardState = new byte[256];

        if (shift)
        {
            keyboardState[VK_SHIFT] = 0x80;
        }

        if (capsLock)
        {
            keyboardState[VK_CAPITAL] = 0x01;
        }

        var buffer = new StringBuilder(16);

        const uint TO_UNICODE_NO_STATE_CHANGE = 0x0004;

        int result = ToUnicodeEx(
            virtualKey,
            scanCode,
            keyboardState,
            buffer,
            buffer.Capacity,
            TO_UNICODE_NO_STATE_CHANGE,
            keyboardLayout
        );

        if (result < 0)
        {
            if (buffer.Length == 0)
                return null;

            return buffer.ToString();
        }

        if (result == 0)
            return null;

        return buffer.ToString();
    }

    private static byte[] BuildVirtualKeys()
    {
        var keys = new List<byte>();

        for (byte key = 0x30; key <= 0x39; key++)
        {
            keys.Add(key);
        }

        for (byte key = 0x41; key <= 0x5A; key++)
        {
            keys.Add(key);
        }

        keys.Add(0xBA); 
        keys.Add(0xBB); 
        keys.Add(0xBC); 
        keys.Add(0xBD); 
        keys.Add(0xBE); 
        keys.Add(0xBF); 
        keys.Add(0xC0); 
        keys.Add(0xDB); 
        keys.Add(0xDC); 
        keys.Add(0xDD); 
        keys.Add(0xDE); 
        keys.Add(0xDF); 
        keys.Add(0xE2); 

        keys.Add(0x20);

        return keys.ToArray();
    }

    [DllImport(
        "user32.dll",
        CharSet = CharSet.Unicode,
        SetLastError = true)]
    private static extern int ToUnicodeEx(
        uint wVirtKey,
        uint wScanCode,
        byte[] lpKeyState,
        [Out] StringBuilder pwszBuff,
        int cchBuff,
        uint wFlags,
        IntPtr dwhkl
    );

    [DllImport("user32.dll")]
    private static extern uint MapVirtualKeyEx(
        uint uCode,
        uint uMapType,
        IntPtr dwhkl
    );
}