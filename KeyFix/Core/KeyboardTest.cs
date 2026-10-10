using System;
using System.Text;

namespace KeyFix.Core;

public static class KeyboardTest
{
    public static string Run()
    {
        var english = new KeyboardLayoutMap(
            KeyboardLayouts.English);

        var persian = new KeyboardLayoutMap(
            KeyboardLayouts.Persian);

        var result = new StringBuilder();

        result.AppendLine("=== ENGLISH ===");

        Add(
            result,
            english,
            'q');

        Add(
            result,
            english,
            'Q');

        result.AppendLine();
        result.AppendLine("=== PERSIAN ===");

        Add(
            result,
            persian,
            'ض');

        Add(
            result,
            persian,
            'ً');

        return result.ToString();
    }

    private static void Add(
        StringBuilder result,
        KeyboardLayoutMap map,
        char character)
    {
        string key = character.ToString();

        if (map.TextToKey.TryGetValue(
                key,
                out KeyStroke stroke))
        {
            result.AppendLine(
                $"{character} -> VK 0x{stroke.VirtualKey:X2}, " +
                $"Shift={stroke.Shift}, " +
                $"Caps={stroke.CapsLock}");
        }
        else
        {
            result.AppendLine(
                $"{character} -> NOT FOUND");
        }
    }
}