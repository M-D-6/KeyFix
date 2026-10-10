using System;
using System.Text;
using System.Globalization;

namespace KeyFix.Core;

public enum ConversionDirection
{
    EnglishToPersian,
    PersianToEnglish
}

public sealed class KeyboardConverter
{
    private readonly KeyboardLayoutMap _englishMap;
    private readonly KeyboardLayoutMap _persianMap;

    
    public bool IgnoreShiftPersianToEnglish { get; set; } = false;

    public bool IgnoreShiftEnglishToPersian { get; set; } = false;

    public bool DetectCapsLockInMixedCaseEnglish { get; set; } = true;

    public KeyboardConverter(
        IntPtr englishLayout,
        IntPtr persianLayout)
    {
        _englishMap =
            new KeyboardLayoutMap(
                englishLayout);

        _persianMap =
            new KeyboardLayoutMap(
                persianLayout);
    }

    public string ConvertAutomatically(
        string text)
    {
        if (string.IsNullOrEmpty(text))
            return text;

        if (text.Length == 1)
        {
            return ConvertSingleCharacter(
                text[0]);
        }

        var result =
            new StringBuilder(
                text.Length);

        var segment =
            new StringBuilder();

        ConversionDirection? currentDirection =
            null;

        foreach (char character in text)
        {
            ConversionDirection? direction =
                GetLetterDirection(
                    character);

            if (direction == null)
            {
                segment.Append(character);

                continue;
            }

            if (currentDirection == null)
            {
                currentDirection =
                    direction;

                segment.Append(character);

                continue;
            }

            if (currentDirection == direction)
            {
                segment.Append(character);

                continue;
            }

            FlushSegment(
                result,
                segment,
                currentDirection);

            currentDirection =
                direction;

            segment.Append(character);
        }

        FlushSegment(
            result,
            segment,
            currentDirection);

        return result.ToString();
    }

    

    private string ConvertSingleCharacter(
        char character)
    {
        string value =
            character.ToString();

        if (_persianMap.TextToKey.TryGetValue(
                value,
                out KeyStroke persianKey))
        {
            return ConvertSingleKey(
                value,
                persianKey,
                _persianMap,
                _englishMap,
                ConversionDirection.PersianToEnglish,
                IgnoreShiftPersianToEnglish);
        }

        if (_englishMap.TextToKey.TryGetValue(
                value,
                out KeyStroke englishKey))
        {
            return ConvertSingleKey(
                value,
                englishKey,
                _englishMap,
                _persianMap,
                ConversionDirection.EnglishToPersian,
                IgnoreShiftEnglishToPersian);
        }

        return value;
    }

    private string ConvertSingleKey(
        string original,
        KeyStroke keyStroke,
        KeyboardLayoutMap source,
        KeyboardLayoutMap target,
        ConversionDirection direction,
        bool ignoreShift)
    {
        
        if (direction ==
                ConversionDirection.EnglishToPersian &&
            IsEnglishUppercase(
                original[0]) &&
            !ignoreShift)
        {
            keyStroke =
                keyStroke with
                {
                    Shift = true,
                    CapsLock = false
                };
        }

        if (ignoreShift)
        {
            keyStroke =
                keyStroke with
                {
                    Shift = false
                };
        }

        if (target.KeyToText.TryGetValue(
                keyStroke,
                out string? replacement))
        {
            return replacement;
        }

        if (keyStroke.CapsLock)
        {
            var fallback =
                keyStroke with
                {
                    CapsLock = false
                };

            if (target.KeyToText.TryGetValue(
                    fallback,
                    out replacement))
            {
                return replacement;
            }
        }

        if (keyStroke.Shift)
        {
            var fallback =
                keyStroke with
                {
                    Shift = false
                };

            if (target.KeyToText.TryGetValue(
                    fallback,
                    out replacement))
            {
                return replacement;
            }
        }

        return original;
    }

    

    private void FlushSegment(
        StringBuilder result,
        StringBuilder segment,
        ConversionDirection? direction)
    {
        if (segment.Length == 0 ||
            direction == null)
        {
            return;
        }

        string value =
            segment.ToString();

        result.Append(
            ConvertSegment(
                value,
                direction.Value));

        segment.Clear();
    }

    private string ConvertSegment(
        string text,
        ConversionDirection direction)
    {
        
        if (direction ==
            ConversionDirection.EnglishToPersian)
        {
            text =
                NormalizeEnglishCaps(
                    text);
        }

        KeyboardLayoutMap source;
        KeyboardLayoutMap target;

        bool ignoreShift;

        if (direction ==
            ConversionDirection.PersianToEnglish)
        {
            source =
                _persianMap;

            target =
                _englishMap;

            ignoreShift =
                IgnoreShiftPersianToEnglish;
        }
        else
        {
            source =
                _englishMap;

            target =
                _persianMap;

            ignoreShift =
                IgnoreShiftEnglishToPersian;
        }

        return ConvertSegmentUsingMaps(
            text,
            source,
            target,
            direction,
            ignoreShift);
    }

    private string ConvertSegmentUsingMaps(
        string text,
        KeyboardLayoutMap source,
        KeyboardLayoutMap target,
        ConversionDirection direction,
        bool ignoreShift)
    {
        var result =
            new StringBuilder(
                text.Length);

        foreach (char character in text)
        {
            string value =
                character.ToString();

            if (!source.TextToKey.TryGetValue(
                    value,
                    out KeyStroke keyStroke))
            {
                result.Append(character);

                continue;
            }

            if (direction ==
                    ConversionDirection.EnglishToPersian &&
                IsEnglishUppercase(character) &&
                !ignoreShift)
            {
                keyStroke =
                    keyStroke with
                    {
                        Shift = true,
                        CapsLock = false
                    };
            }

            if (ignoreShift)
            {
                keyStroke =
                    keyStroke with
                    {
                        Shift = false
                    };
            }

            if (target.KeyToText.TryGetValue(
                    keyStroke,
                    out string? replacement))
            {
                result.Append(
                    replacement);

                continue;
            }

            if (keyStroke.CapsLock)
            {
                var fallback =
                    keyStroke with
                    {
                        CapsLock = false
                    };

                if (target.KeyToText.TryGetValue(
                        fallback,
                        out replacement))
                {
                    result.Append(
                        replacement);

                    continue;
                }
            }

            if (keyStroke.Shift)
            {
                var fallback =
                    keyStroke with
                    {
                        Shift = false
                    };

                if (target.KeyToText.TryGetValue(
                        fallback,
                        out replacement))
                {
                    result.Append(
                        replacement);

                    continue;
                }
            }

            result.Append(character);
        }

        return result.ToString();
    }

    

    private string NormalizeEnglishCaps(
        string text)
    {
        int uppercaseCount = 0;
        int lowercaseCount = 0;

        foreach (char character in text)
        {
            if (character >= 'A' &&
                character <= 'Z')
            {
                uppercaseCount++;

                continue;
            }

            if (character >= 'a' &&
                character <= 'z')
            {
                lowercaseCount++;
            }
        }

        if (uppercaseCount +
            lowercaseCount == 0)
        {
            return text;
        }

        if (DetectCapsLockInMixedCaseEnglish &&
            uppercaseCount > lowercaseCount)
        {
            return ReverseEnglishCase(
                text);
        }

        return text;
    }

    private static string ReverseEnglishCase(
        string text)
    {
        var result =
            new StringBuilder(
                text.Length);

        foreach (char character in text)
        {
            if (character >= 'A' &&
                character <= 'Z')
            {
                result.Append(
                    char.ToLowerInvariant(
                        character));

                continue;
            }

            if (character >= 'a' &&
                character <= 'z')
            {
                result.Append(
                    char.ToUpperInvariant(
                        character));

                continue;
            }

            result.Append(character);
        }

        return result.ToString();
    }

    

    private static ConversionDirection?
        GetLetterDirection(
            char character)
    {
        if (IsEnglishLetter(character))
        {
            return
                ConversionDirection
                    .EnglishToPersian;
        }

        if (IsPersianLetterOrMark(
                character))
        {
            return
                ConversionDirection
                    .PersianToEnglish;
        }

        return null;
    }

    private static bool IsEnglishLetter(
        char character)
    {
        return
            (character >= 'A' &&
             character <= 'Z') ||

            (character >= 'a' &&
             character <= 'z');
    }

    private static bool IsEnglishUppercase(
        char character)
    {
        return
            character >= 'A' &&
            character <= 'Z';
    }

    private static bool IsPersianLetterOrMark(
        char character)
    {
        bool inArabicRange =
            (character >= '\u0600' &&
             character <= '\u06FF') ||

            (character >= '\u0750' &&
             character <= '\u077F') ||

            (character >= '\u08A0' &&
             character <= '\u08FF') ||

            (character >= '\uFB50' &&
             character <= '\uFDFF') ||

            (character >= '\uFE70' &&
             character <= '\uFEFF');

        if (!inArabicRange)
            return false;

        UnicodeCategory category =
            char.GetUnicodeCategory(
                character);

        return
            category ==
                UnicodeCategory.UppercaseLetter ||

            category ==
                UnicodeCategory.LowercaseLetter ||

            category ==
                UnicodeCategory.TitlecaseLetter ||

            category ==
                UnicodeCategory.ModifierLetter ||

            category ==
                UnicodeCategory.OtherLetter ||

            category ==
                UnicodeCategory.NonSpacingMark ||

            category ==
                UnicodeCategory.SpacingCombiningMark;
    }
}