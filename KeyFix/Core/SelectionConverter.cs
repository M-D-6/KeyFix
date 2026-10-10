using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace KeyFix.Core;

public enum ConversionResult
{


    Success,



    NoSelectionFound,



    NothingToConvert,



    FocusChanged,



    InputInjectionFailed,



    ClipboardError
}

public sealed class SelectionConverter
{
    private readonly KeyboardConverter _converter;

    private ShortcutDefinition _shortcut;




    public bool AutoSwitchKeyboardLanguage { get; set; } =
        true;

    private readonly SemaphoreSlim _conversionLock =
        new(1, 1);

    public SelectionConverter(
        KeyboardConverter converter,
        ShortcutDefinition shortcut)
    {
        _converter = converter;
        _shortcut = shortcut;
    }



    public void UpdateShortcut(
        ShortcutDefinition shortcut)
    {
        _shortcut = shortcut;
    }

    public async Task<ConversionResult> ConvertSelectedTextAsync()
    {

        if (!await _conversionLock.WaitAsync(0))
        {
            return ConversionResult.FocusChanged;
        }

        ClipboardSnapshot? snapshot = null;

        bool ourClipboardWasInstalled = false;

        try
        {

            IntPtr targetWindow =
                GetForegroundWindow();

            if (targetWindow == IntPtr.Zero)
            {
                return ConversionResult.FocusChanged;
            }

            HotKeyReleaseResult releaseResult =
                await WaitForHotKeyReleaseAsync(
                    targetWindow);

            if (releaseResult ==
                HotKeyReleaseResult.FocusChanged)
            {
                return ConversionResult.FocusChanged;
            }

            if (releaseResult ==
                HotKeyReleaseResult.TimedOut)
            {
                return ConversionResult.InputInjectionFailed;
            }

            if (!IsTargetStillForeground(targetWindow))
            {
                return ConversionResult.FocusChanged;
            }

            snapshot =
                SaveClipboard();

            // Clipboard content is only a restore point. If Windows reports
            // the clipboard as temporarily locked or unreadable, keep going.
            // Ctrl+C below will populate it with the actual selection.
            if (snapshot == null)
            {
                snapshot =
                    new ClipboardSnapshot(
                        null,
                        false,
                        false);
            }

            if (!IsTargetStillForeground(targetWindow))
            {
                return ConversionResult.FocusChanged;
            }

            uint clipboardBeforeCopy =
                GetClipboardSequenceNumber();

            bool copySent =
                await SendCtrlCAsync(
                    targetWindow);

            if (!copySent)
            {
                return ConversionResult.InputInjectionFailed;
            }

            ClipboardWaitResult clipboardWait =
                await WaitForClipboardChangeAsync(
                    clipboardBeforeCopy,
                    targetWindow,
                    150);

            if (clipboardWait ==
                ClipboardWaitResult.FocusChanged)
            {
                return ConversionResult.FocusChanged;
            }

            if (clipboardWait ==
                ClipboardWaitResult.TimedOut)
            {
                return ConversionResult.NoSelectionFound;
            }

            string? selectedText =
                await WaitForClipboardTextAsync(
                    targetWindow,
                    150);

            if (string.IsNullOrEmpty(selectedText))
            {
                return ConversionResult.NoSelectionFound;
            }

            if (!IsTargetStillForeground(targetWindow))
            {
                return ConversionResult.FocusChanged;
            }

            string converted =
                _converter.ConvertAutomatically(
                    selectedText);

            if (string.IsNullOrEmpty(converted) ||
                string.Equals(
                    converted,
                    selectedText,
                    StringComparison.Ordinal))
            {
                return ConversionResult.NothingToConvert;
            }

            if (!IsTargetStillForeground(targetWindow))
            {
                return ConversionResult.FocusChanged;
            }

            bool clipboardSet =
                await SetClipboardTextWithRetryAsync(
                    converted,
                    targetWindow,
                    250);

            if (!clipboardSet)
            {
                return ConversionResult.ClipboardError;
            }

            ourClipboardWasInstalled = true;

            uint sequenceAfterOurSet =
                GetClipboardSequenceNumber();

            if (!IsTargetStillForeground(targetWindow))
            {
                return ConversionResult.FocusChanged;
            }

            bool pasteSent =
                await SendCtrlVAsync(
                    targetWindow);

            if (!pasteSent)
            {
                return ConversionResult.InputInjectionFailed;
            }

            // Give the target application a short chance to consume the
            // clipboard, but do not delay the whole conversion flow too much.
            // A long wait here makes notifications appear late and can cause
            // rapid conversions to overlap with user input.
            await Task.Delay(80);

            if (IsTargetStillForeground(targetWindow) &&
                GetClipboardSequenceNumber() ==
                sequenceAfterOurSet)
            {
                if (snapshot.CanRestore)
                {
                    RestoreClipboard(
                        snapshot);
                }
            }

            ourClipboardWasInstalled = false;

            if (AutoSwitchKeyboardLanguage &&
                IsTargetStillForeground(targetWindow))
            {
                SetKeyboardLanguageFromLastLetter(
                    targetWindow,
                    converted);
            }

            return ConversionResult.Success;
        }
        catch
        {

            if (ourClipboardWasInstalled &&
                snapshot != null &&
                snapshot.CanRestore)
            {
                try
                {

                    RestoreClipboardIfStillOurs(
                        snapshot);
                }
                catch
                {

                }
            }

            return ConversionResult.ClipboardError;
        }
        finally
        {

            snapshot?.DataObject?.Dispose();

            _conversionLock.Release();
        }
    }



    private static bool IsTargetStillForeground(
        IntPtr targetWindow)
    {
        if (targetWindow == IntPtr.Zero)
        {
            return false;
        }

        return GetForegroundWindow() ==
               targetWindow;
    }



    private static void SetKeyboardLanguageFromLastLetter(
        IntPtr targetWindow,
        string text)
    {
        if (targetWindow == IntPtr.Zero ||
            string.IsNullOrEmpty(text))
        {
            return;
        }

        if (GetForegroundWindow() != targetWindow)
        {
            return;
        }

        for (int i = text.Length - 1; i >= 0; i--)
        {
            char character = text[i];

            if (IsPersianCharacter(character))
            {
                KeyboardLayouts.SetForegroundLanguage(
                    KeyboardLayouts.Persian);

                return;
            }

            if (IsEnglishLetter(character))
            {
                KeyboardLayouts.SetForegroundLanguage(
                    KeyboardLayouts.English);

                return;
            }
        }
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

    private static bool IsPersianCharacter(
        char character)
    {
        return
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
    }



    private enum HotKeyReleaseResult
    {
        Released,
        FocusChanged,
        TimedOut
    }

    private async Task<HotKeyReleaseResult>
        WaitForHotKeyReleaseAsync(
            IntPtr targetWindow)
    {
        const int timeoutMilliseconds = 1200;
        const int pollIntervalMilliseconds = 5;

        int elapsed = 0;

        while (elapsed < timeoutMilliseconds)
        {

            if (!IsTargetStillForeground(
                    targetWindow))
            {
                return HotKeyReleaseResult.FocusChanged;
            }

            if (!AreShortcutKeysDown(
                    _shortcut))
            {
                return HotKeyReleaseResult.Released;
            }

            await Task.Delay(
                pollIntervalMilliseconds);

            elapsed +=
                pollIntervalMilliseconds;
        }

        return HotKeyReleaseResult.TimedOut;
    }

    private static bool AreShortcutKeysDown(
        ShortcutDefinition shortcut)
    {
        if ((shortcut.Modifiers & MOD_CONTROL) != 0 &&
            IsKeyDown(VK_CONTROL))
        {
            return true;
        }

        if ((shortcut.Modifiers & MOD_ALT) != 0 &&
            IsKeyDown(VK_MENU))
        {
            return true;
        }

        if ((shortcut.Modifiers & MOD_SHIFT) != 0 &&
            IsKeyDown(VK_SHIFT))
        {
            return true;
        }

        if ((shortcut.Modifiers & MOD_WIN) != 0 &&
            (IsKeyDown(VK_LWIN) ||
             IsKeyDown(VK_RWIN)))
        {
            return true;
        }

        if (shortcut.VirtualKey != 0 &&
            IsKeyDown(
                (int)shortcut.VirtualKey))
        {
            return true;
        }

        return false;
    }

    private static bool IsKeyDown(
        int virtualKey)
    {
        return
            (GetAsyncKeyState(virtualKey) &
             0x8000) != 0;
    }



    private enum ClipboardWaitResult
    {
        Changed,
        FocusChanged,
        TimedOut
    }

    private static async Task<ClipboardWaitResult>
        WaitForClipboardChangeAsync(
            uint previousSequence,
            IntPtr targetWindow,
            int timeoutMilliseconds)
    {
        const int pollIntervalMilliseconds = 5;

        int elapsed = 0;

        while (elapsed < timeoutMilliseconds)
        {

            if (!IsTargetStillForeground(
                    targetWindow))
            {
                return ClipboardWaitResult.FocusChanged;
            }

            uint currentSequence =
                GetClipboardSequenceNumber();

            if (currentSequence !=
                previousSequence)
            {
                return ClipboardWaitResult.Changed;
            }

            await Task.Delay(
                pollIntervalMilliseconds);

            elapsed +=
                pollIntervalMilliseconds;
        }

        if (!IsTargetStillForeground(
                targetWindow))
        {
            return ClipboardWaitResult.FocusChanged;
        }

        return ClipboardWaitResult.TimedOut;
    }



    private static async Task<string?>
        WaitForClipboardTextAsync(
            IntPtr targetWindow,
            int timeoutMilliseconds)
    {
        const int pollIntervalMilliseconds = 5;

        int elapsed = 0;

        while (elapsed < timeoutMilliseconds)
        {
            if (!IsTargetStillForeground(
                    targetWindow))
            {
                return null;
            }

            string? text =
                GetClipboardText();

            if (!string.IsNullOrEmpty(text))
            {
                return text;
            }

            await Task.Delay(
                pollIntervalMilliseconds);

            elapsed +=
                pollIntervalMilliseconds;
        }

        return null;
    }



    private static async Task<bool>
        SendCtrlCAsync(
            IntPtr targetWindow)
    {
        if (!IsTargetStillForeground(
                targetWindow))
        {
            return false;
        }

        bool sent =
            SendKeyChord(
                VK_CONTROL,
                VK_C);

        await Task.CompletedTask;

        return sent;
    }

    private static async Task<bool>
        SendCtrlVAsync(
            IntPtr targetWindow)
    {
        if (!IsTargetStillForeground(
                targetWindow))
        {
            return false;
        }

        bool sent =
            SendKeyChord(
                VK_CONTROL,
                VK_V);

        await Task.CompletedTask;

        return sent;
    }

    private static bool SendKeyChord(
        ushort modifierVirtualKey,
        ushort mainVirtualKey)
    {
        int inputSize =
            Marshal.SizeOf<INPUT>();

        INPUT[] inputs =
        {
            CreateKeyboardInput(
                modifierVirtualKey,
                keyUp: false),

            CreateKeyboardInput(
                mainVirtualKey,
                keyUp: false),

            CreateKeyboardInput(
                mainVirtualKey,
                keyUp: true),

            CreateKeyboardInput(
                modifierVirtualKey,
                keyUp: true)
        };

        uint sent =
            SendInput(
                (uint)inputs.Length,
                inputs,
                inputSize);

        return sent ==
               (uint)inputs.Length;
    }

    private static INPUT CreateKeyboardInput(
        ushort virtualKey,
        bool keyUp)
    {
        return new INPUT
        {
            Type =
                INPUT_KEYBOARD,

            Data =
                new InputUnion
                {
                    Keyboard =
                        new KEYBDINPUT
                        {
                            VirtualKey =
                                virtualKey,

                            ScanCode =
                                0,

                            Flags =
                                keyUp
                                    ? KEYEVENTF_KEYUP
                                    : 0,

                            Time =
                                0,

                            ExtraInfo =
                                IntPtr.Zero
                        }
                }
        };
    }



    private static string? GetClipboardText()
    {
        if (!OpenClipboard(
                IntPtr.Zero))
        {
            return null;
        }

        try
        {
            IntPtr handle =
                GetClipboardData(
                    CF_UNICODETEXT);

            if (handle == IntPtr.Zero)
            {
                return null;
            }

            IntPtr pointer =
                GlobalLock(handle);

            if (pointer == IntPtr.Zero)
            {
                return null;
            }

            try
            {
                return Marshal.PtrToStringUni(
                    pointer);
            }
            finally
            {
                GlobalUnlock(handle);
            }
        }
        finally
        {
            CloseClipboard();
        }
    }



    private static async Task<bool>
        SetClipboardTextWithRetryAsync(
            string text,
            IntPtr targetWindow,
            int timeoutMilliseconds)
    {
        const int retryIntervalMilliseconds = 5;

        int elapsed = 0;

        while (elapsed < timeoutMilliseconds)
        {
            if (!IsTargetStillForeground(
                    targetWindow))
            {
                return false;
            }

            if (SetClipboardText(text))
            {
                return true;
            }

            await Task.Delay(
                retryIntervalMilliseconds);

            elapsed +=
                retryIntervalMilliseconds;
        }

        return false;
    }

    private static bool SetClipboardText(
        string text)
    {
        if (!OpenClipboard(
                IntPtr.Zero))
        {
            return false;
        }

        IntPtr memory =
            IntPtr.Zero;

        try
        {
            if (!EmptyClipboard())
            {
                return false;
            }

            byte[] bytes =
                Encoding.Unicode.GetBytes(
                    text + "\0");

            memory =
                GlobalAlloc(
                    GMEM_MOVEABLE,
                    (UIntPtr)bytes.Length);

            if (memory == IntPtr.Zero)
            {
                return false;
            }

            IntPtr pointer =
                GlobalLock(memory);

            if (pointer == IntPtr.Zero)
            {
                return false;
            }

            try
            {
                Marshal.Copy(
                    bytes,
                    0,
                    pointer,
                    bytes.Length);
            }
            finally
            {
                GlobalUnlock(memory);
            }

            IntPtr result =
                SetClipboardData(
                    CF_UNICODETEXT,
                    memory);

            if (result == IntPtr.Zero)
            {
                return false;
            }

            memory =
                IntPtr.Zero;

            return true;
        }
        finally
        {
            if (memory != IntPtr.Zero)
            {
                GlobalFree(memory);
            }

            CloseClipboard();
        }
    }



    private sealed class ClipboardSnapshot
    {
        public SnapshotDataObject? DataObject { get; }

        public bool WasEmpty { get; }

        public bool CanRestore { get; }

        public ClipboardSnapshot(
            SnapshotDataObject? dataObject,
            bool wasEmpty,
            bool canRestore)
        {
            DataObject =
                dataObject;

            WasEmpty =
                wasEmpty;

            CanRestore =
                canRestore;
        }
    }

    private static ClipboardSnapshot?
        SaveClipboard()
    {
        const int attempts = 5;

        for (int attempt = 0; attempt < attempts; attempt++)
        {
            if (!OpenClipboard(
                    IntPtr.Zero))
            {
                Thread.Sleep(5);
                continue;
            }

            bool wasEmpty;

            try
            {
                wasEmpty =
                    EnumClipboardFormats(0) == 0;
            }
            finally
            {
                CloseClipboard();
            }

            if (wasEmpty)
            {
                return new ClipboardSnapshot(
                    null,
                    true,
                    true);
            }

            int hResult =
                OleGetClipboard(
                    out IDataObject? liveDataObject);

            if (hResult != 0 ||
                liveDataObject == null)
            {
                Thread.Sleep(5);
                continue;
            }

            SnapshotDataObject? snapshot = null;

            try
            {
                snapshot =
                    CaptureSnapshot(
                        liveDataObject);
            }
            finally
            {
                Marshal.ReleaseComObject(
                    liveDataObject);
            }

            if (snapshot != null && !snapshot.IsEmpty)
            {
                return new ClipboardSnapshot(
                    snapshot,
                    false,
                    true);
            }

            snapshot?.Dispose();
            Thread.Sleep(5);
        }

        return new ClipboardSnapshot(
            null,
            false,
            false);
    }

    private static bool RestoreClipboard(
        ClipboardSnapshot snapshot)
    {
        if (snapshot.WasEmpty)
        {
            return ClearClipboardWithRetry();
        }

        if (snapshot.DataObject == null)
        {
            return false;
        }

        int hResult =
            OleSetClipboard(
                snapshot.DataObject);

        if (hResult != 0)
        {
            return false;
        }

        int flushResult =
            OleFlushClipboard();

        return flushResult == 0;
    }

    private static bool RestoreClipboardIfStillOurs(
        ClipboardSnapshot snapshot)
    {

        return RestoreClipboard(
            snapshot);
    }

    private static bool ClearClipboardWithRetry()
    {
        const int attempts = 5;

        for (int i = 0; i < attempts; i++)
        {
            if (!OpenClipboard(
                    IntPtr.Zero))
            {
                Thread.Sleep(5);

                continue;
            }

            try
            {
                return EmptyClipboard();
            }
            finally
            {
                CloseClipboard();
            }
        }

        return false;
    }



    private static SnapshotDataObject?
        CaptureSnapshot(
            IDataObject source)
    {
        var snapshot =
            new SnapshotDataObject();

        IEnumFORMATETC? enumerator =
            null;

        try
        {
            enumerator =
                source.EnumFormatEtc(
                    DATADIR.DATADIR_GET);

            if (enumerator == null)
            {
                snapshot.Dispose();

                return null;
            }

            var formatBuffer =
                new FORMATETC[1];

            var fetchedBuffer =
                new int[1];

            while (true)
            {
                int hr =
                    enumerator.Next(
                        1,
                        formatBuffer,
                        fetchedBuffer);

                if (hr != 0 ||
                    fetchedBuffer[0] == 0)
                {
                    break;
                }

                TryCaptureFormat(
                    source,
                    formatBuffer[0],
                    snapshot);
            }
        }
        catch
        {
            snapshot.Dispose();

            return null;
        }
        finally
        {
            if (enumerator != null)
            {
                Marshal.ReleaseComObject(
                    enumerator);
            }
        }

        return snapshot;
    }

    private static void TryCaptureFormat(
        IDataObject source,
        FORMATETC format,
        SnapshotDataObject snapshot)
    {
        try
        {
            format.tymed =
                TYMED.TYMED_HGLOBAL |
                TYMED.TYMED_GDI |
                TYMED.TYMED_MFPICT |
                TYMED.TYMED_ENHMF |
                TYMED.TYMED_ISTREAM;

            source.GetData(
                ref format,
                out STGMEDIUM medium);

            try
            {
                STGMEDIUM? duplicated =
                    DuplicateMedium(
                        format,
                        medium);

                if (duplicated == null)
                {
                    return;
                }

                format.tymed =
                    (TYMED)medium.tymed;

                snapshot.Add(
                    format,
                    duplicated.Value);
            }
            finally
            {
                ReleaseStgMedium(
                    ref medium);
            }
        }
        catch
        {

        }
    }

    private static STGMEDIUM?
        DuplicateMedium(
            FORMATETC format,
            STGMEDIUM medium)
    {
        switch ((TYMED)medium.tymed)
        {
            case TYMED.TYMED_HGLOBAL:
            case TYMED.TYMED_GDI:
            case TYMED.TYMED_MFPICT:
            case TYMED.TYMED_ENHMF:
                {
                    if (medium.unionmember ==
                        IntPtr.Zero)
                    {
                        return null;
                    }

                    IntPtr duplicatedHandle =
                        OleDuplicateData(
                            medium.unionmember,
                            unchecked(
                                (uint)(ushort)format.cfFormat),
                            GMEM_MOVEABLE |
                            GMEM_DDESHARE);

                    if (duplicatedHandle ==
                        IntPtr.Zero)
                    {
                        return null;
                    }

                    return new STGMEDIUM
                    {
                        tymed =
                            (TYMED)medium.tymed,

                        unionmember =
                            duplicatedHandle,

                        pUnkForRelease =
                            null!
                    };
                }

            case TYMED.TYMED_ISTREAM:
                return DuplicateStreamMedium(
                    medium);

            default:

                return null;
        }
    }

    private static STGMEDIUM?
        DuplicateStreamMedium(
            STGMEDIUM medium)
    {
        if (medium.unionmember ==
            IntPtr.Zero)
        {
            return null;
        }

        object comObject =
            Marshal.GetObjectForIUnknown(
                medium.unionmember);

        try
        {
            if (comObject is not IStream sourceStream)
            {
                return null;
            }

            byte[] bytes =
                ReadAllBytes(
                    sourceStream);

            int hResult =
                CreateStreamOnHGlobal(
                    IntPtr.Zero,
                    true,
                    out IStream newStream);

            if (hResult != 0 ||
                newStream == null)
            {
                return null;
            }

            try
            {
                if (bytes.Length > 0)
                {
                    newStream.Write(
                        bytes,
                        bytes.Length,
                        IntPtr.Zero);

                    newStream.Seek(
                        0,
                        0,
                        IntPtr.Zero);
                }

                IntPtr streamPointer =
                    Marshal.GetIUnknownForObject(
                        newStream);

                return new STGMEDIUM
                {
                    tymed =
                        TYMED.TYMED_ISTREAM,

                    unionmember =
                        streamPointer,

                    pUnkForRelease =
                        null!
                };
            }
            finally
            {
                Marshal.ReleaseComObject(
                    newStream);
            }
        }
        finally
        {
            Marshal.ReleaseComObject(
                comObject);
        }
    }

    private static byte[] ReadAllBytes(
        IStream stream)
    {
        stream.Stat(
            out STATSTG stat,
            1);

        stream.Seek(
            0,
            0,
            IntPtr.Zero);

        long length =
            stat.cbSize;

        if (length <= 0 ||
            length > int.MaxValue)
        {
            return Array.Empty<byte>();
        }

        byte[] buffer =
            new byte[(int)length];

        int totalRead = 0;

        IntPtr bytesReadPtr =
            Marshal.AllocHGlobal(
                sizeof(int));

        try
        {
            while (totalRead <
                   buffer.Length)
            {
                int chunkSize =
                    Math.Min(
                        81920,
                        buffer.Length -
                        totalRead);

                byte[] chunkBuffer =
                    new byte[chunkSize];

                stream.Read(
                    chunkBuffer,
                    chunkSize,
                    bytesReadPtr);

                int bytesRead =
                    Marshal.ReadInt32(
                        bytesReadPtr);

                if (bytesRead <= 0)
                {
                    break;
                }

                bytesRead =
                    Math.Min(
                        bytesRead,
                        chunkSize);

                Array.Copy(
                    chunkBuffer,
                    0,
                    buffer,
                    totalRead,
                    bytesRead);

                totalRead +=
                    bytesRead;
            }
        }
        finally
        {
            Marshal.FreeHGlobal(
                bytesReadPtr);
        }

        if (totalRead !=
            buffer.Length)
        {
            Array.Resize(
                ref buffer,
                totalRead);
        }

        return buffer;
    }



    private sealed class SnapshotDataObject :
        IDataObject,
        IDisposable
    {
        private readonly
            List<(FORMATETC Format, STGMEDIUM Medium)>
            _entries =
                new();

        private bool _disposed;

        public bool IsEmpty =>
            _entries.Count == 0;

        public void Add(
            FORMATETC format,
            STGMEDIUM medium)
        {
            if (_disposed)
            {
                throw new ObjectDisposedException(
                    nameof(SnapshotDataObject));
            }

            _entries.Add(
                (format, medium));
        }

        public void GetData(
            ref FORMATETC format,
            out STGMEDIUM medium)
        {
            if (_disposed)
            {
                throw new ObjectDisposedException(
                    nameof(SnapshotDataObject));
            }

            foreach (
                (FORMATETC entryFormat,
                 STGMEDIUM entryMedium)
                in _entries)
            {
                if (!FormatsMatch(
                        entryFormat,
                        format))
                {
                    continue;
                }

                STGMEDIUM? clone =
                    DuplicateMedium(
                        entryFormat,
                        entryMedium);

                if (clone != null)
                {
                    medium =
                        clone.Value;

                    return;
                }
            }

            throw new COMException(
                "Format not available in Clipboard snapshot.",
                unchecked(
                    (int)0x80040064));
        }

        public void GetDataHere(
            ref FORMATETC format,
            ref STGMEDIUM medium)
        {
            throw new COMException(
                null,
                unchecked(
                    (int)0x80004001));
        }

        public int QueryGetData(
            ref FORMATETC format)
        {
            if (_disposed)
            {
                return unchecked(
                    (int)0x80040064);
            }

            foreach (
                (FORMATETC entryFormat, _)
                in _entries)
            {
                if (FormatsMatch(
                        entryFormat,
                        format))
                {
                    return 0;
                }
            }

            return unchecked(
                (int)0x80040064);
        }

        public int GetCanonicalFormatEtc(
            ref FORMATETC formatIn,
            out FORMATETC formatOut)
        {
            formatOut = default;

            return unchecked(
                (int)0x00040130);
        }

        public void SetData(
            ref FORMATETC formatIn,
            ref STGMEDIUM medium,
            bool release)
        {
            throw new COMException(
                null,
                unchecked(
                    (int)0x80004001));
        }

        public IEnumFORMATETC EnumFormatEtc(
            DATADIR direction)
        {
            if (direction !=
                DATADIR.DATADIR_GET)
            {
                throw new COMException(
                    null,
                    unchecked(
                        (int)0x80004001));
            }

            if (_disposed)
            {
                throw new ObjectDisposedException(
                    nameof(SnapshotDataObject));
            }

            FORMATETC[] formats =
                new FORMATETC[
                    _entries.Count];

            for (int i = 0;
                 i < _entries.Count;
                 i++)
            {
                formats[i] =
                    _entries[i].Format;
            }

            return new FormatEtcEnumerator(
                formats);
        }

        public int DAdvise(
            ref FORMATETC pFormatetc,
            ADVF advf,
            IAdviseSink adviseSink,
            out int connection)
        {
            connection = 0;

            return unchecked(
                (int)0x80040003);
        }

        public void DUnadvise(
            int connection)
        {
        }

        public int EnumDAdvise(
            out IEnumSTATDATA enumAdvise)
        {
            enumAdvise =
                null!;

            return unchecked(
                (int)0x80040003);
        }

        private static bool FormatsMatch(
            FORMATETC a,
            FORMATETC b)
        {
            return
                a.cfFormat ==
                    b.cfFormat &&

                a.dwAspect ==
                    b.dwAspect &&

                a.lindex ==
                    b.lindex;
        }

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }

            _disposed = true;

            foreach (
                (_, STGMEDIUM medium)
                in _entries)
            {
                STGMEDIUM releasable =
                    medium;

                try
                {
                    ReleaseStgMedium(
                        ref releasable);
                }
                catch
                {

                }
            }

            _entries.Clear();
        }
    }

    private sealed class FormatEtcEnumerator :
        IEnumFORMATETC
    {
        private readonly
            FORMATETC[] _formats;

        private int _index;

        public FormatEtcEnumerator(
            FORMATETC[] formats)
            : this(
                formats,
                0)
        {
        }

        private FormatEtcEnumerator(
            FORMATETC[] formats,
            int index)
        {
            _formats =
                formats;

            _index =
                index;
        }

        public int Next(
            int celt,
            FORMATETC[] rgelt,
            int[] pceltFetched)
        {
            int fetched = 0;

            while (
                fetched < celt &&
                _index < _formats.Length)
            {
                rgelt[fetched] =
                    _formats[_index];

                _index++;
                fetched++;
            }

            if (pceltFetched != null &&
                pceltFetched.Length > 0)
            {
                pceltFetched[0] =
                    fetched;
            }

            return fetched == celt
                ? 0
                : 1;
        }

        public int Skip(
            int celt)
        {
            _index =
                Math.Min(
                    _index + celt,
                    _formats.Length);

            return 0;
        }

        public int Reset()
        {
            _index = 0;

            return 0;
        }

        public void Clone(
            out IEnumFORMATETC newEnum)
        {
            newEnum =
                new FormatEtcEnumerator(
                    _formats,
                    _index);
        }
    }



    private const int VK_CONTROL = 0x11;
    private const int VK_SHIFT = 0x10;
    private const int VK_MENU = 0x12;

    private const int VK_LWIN = 0x5B;
    private const int VK_RWIN = 0x5C;

    private const ushort VK_C = 0x43;
    private const ushort VK_V = 0x56;

    private const uint MOD_ALT = 0x0001;
    private const uint MOD_CONTROL = 0x0002;
    private const uint MOD_SHIFT = 0x0004;
    private const uint MOD_WIN = 0x0008;

    private const uint INPUT_KEYBOARD = 1;

    private const uint KEYEVENTF_KEYUP = 0x0002;

    private const uint CF_UNICODETEXT = 13;

    private const uint GMEM_MOVEABLE = 0x0002;
    private const uint GMEM_DDESHARE = 0x2000;



    [StructLayout(
        LayoutKind.Sequential)]
    private struct INPUT
    {
        public uint Type;

        public InputUnion Data;
    }

    [StructLayout(
        LayoutKind.Explicit)]
    private struct InputUnion
    {
        [FieldOffset(0)]
        public MOUSEINPUT Mouse;

        [FieldOffset(0)]
        public KEYBDINPUT Keyboard;

        [FieldOffset(0)]
        public HARDWAREINPUT Hardware;
    }

    [StructLayout(
        LayoutKind.Sequential)]
    private struct MOUSEINPUT
    {
        public int Dx;
        public int Dy;
        public uint MouseData;
        public uint Flags;
        public uint Time;
        public IntPtr ExtraInfo;
    }

    [StructLayout(
        LayoutKind.Sequential)]
    private struct HARDWAREINPUT
    {
        public uint Message;
        public ushort ParamLow;
        public ushort ParamHigh;
    }

    [StructLayout(
        LayoutKind.Sequential)]
    private struct KEYBDINPUT
    {
        public ushort VirtualKey;
        public ushort ScanCode;
        public uint Flags;
        public uint Time;
        public IntPtr ExtraInfo;
    }



    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern uint SendInput(
        uint numberOfInputs,
        INPUT[] inputs,
        int structSize);

    [DllImport(
        "user32.dll")]
    private static extern IntPtr
        GetForegroundWindow();

    [DllImport(
        "user32.dll")]
    private static extern short
        GetAsyncKeyState(
            int vKey);

    [DllImport(
        "ole32.dll",
        PreserveSig = true)]
    private static extern int
        OleGetClipboard(
            out IDataObject? dataObject);

    [DllImport(
        "ole32.dll",
        PreserveSig = true)]
    private static extern int
        OleSetClipboard(
            IDataObject dataObject);

    [DllImport(
        "ole32.dll",
        PreserveSig = true)]
    private static extern int
        OleFlushClipboard();

    [DllImport(
        "ole32.dll",
        SetLastError = true)]
    private static extern IntPtr
        OleDuplicateData(
            IntPtr hSrc,
            uint cfFormat,
            uint grfFlags);

    [DllImport(
        "ole32.dll",
        PreserveSig = true)]
    private static extern int
        CreateStreamOnHGlobal(
            IntPtr hGlobal,
            [MarshalAs(UnmanagedType.Bool)]
            bool fDeleteOnRelease,
            out IStream stream);

    [DllImport(
        "ole32.dll")]
    private static extern void
        ReleaseStgMedium(
            ref STGMEDIUM pmedium);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern uint
        GetClipboardSequenceNumber();

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern bool
        OpenClipboard(
            IntPtr hWndNewOwner);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern bool
        CloseClipboard();

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern bool
        EmptyClipboard();

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern IntPtr
        GetClipboardData(
            uint uFormat);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern IntPtr
        SetClipboardData(
            uint uFormat,
            IntPtr hMem);

    [DllImport(
        "user32.dll",
        SetLastError = true)]
    private static extern uint
        EnumClipboardFormats(
            uint format);

    [DllImport(
        "kernel32.dll",
        SetLastError = true)]
    private static extern IntPtr
        GlobalAlloc(
            uint uFlags,
            UIntPtr dwBytes);

    [DllImport(
        "kernel32.dll",
        SetLastError = true)]
    private static extern IntPtr
        GlobalLock(
            IntPtr hMem);

    [DllImport(
        "kernel32.dll",
        SetLastError = true)]
    private static extern bool
        GlobalUnlock(
            IntPtr hMem);

    [DllImport(
        "kernel32.dll",
        SetLastError = true)]
    private static extern IntPtr
        GlobalFree(
            IntPtr hMem);

    [DllImport(
        "kernel32.dll",
        SetLastError = true)]
    private static extern UIntPtr
        GlobalSize(
            IntPtr hMem);
}