using System.Collections.Generic;

namespace KeyFix.Core;

public sealed record ShortcutDefinition(
    uint Modifiers,
    uint VirtualKey)
{
    public override string ToString()
    {
        var parts =
            new List<string>();

        if ((Modifiers & 0x0002) != 0)
            parts.Add("Ctrl");

        if ((Modifiers & 0x0001) != 0)
            parts.Add("Alt");

        if ((Modifiers & 0x0004) != 0)
            parts.Add("Shift");

        if ((Modifiers & 0x0008) != 0)
            parts.Add("Win");

        parts.Add(
            GetKeyName(
                VirtualKey));

        return string.Join(
            " + ",
            parts);
    }

    private static string GetKeyName(
        uint key)
    {
        if (key >= 0x41 &&
            key <= 0x5A)
        {
            return ((char)key).ToString();
        }

        if (key >= 0x30 &&
            key <= 0x39)
        {
            return ((char)key).ToString();
        }

        if (key >= 0x70 &&
            key <= 0x87)
        {
            return $"F{key - 0x6F}";
        }

        return key switch
        {
            0x20 => "Space",
            0x09 => "Tab",
            0x0D => "Enter",
            0x2D => "Insert",
            0x2E => "Delete",
            0x24 => "Home",
            0x23 => "End",
            0x21 => "Page Up",
            0x22 => "Page Down",
            0x25 => "Left",
            0x26 => "Up",
            0x27 => "Right",
            0x28 => "Down",

            _ => $"VK 0x{key:X2}"
        };
    }
}