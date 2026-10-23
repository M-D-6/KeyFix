// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:ffi';

import 'package:ffi/ffi.dart';

final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');
final DynamicLibrary _advapi32 = DynamicLibrary.open('advapi32.dll');

const int WM_QUIT = 0x0012;
const int WM_HOTKEY = 0x0312;
const int WM_INPUTLANGCHANGEREQUEST = 0x0050;

const int MOD_NOREPEAT = 0x4000;

const int INPUT_KEYBOARD = 1;
const int KEYEVENTF_KEYUP = 0x0002;

const int VK_SHIFT = 0x10;
const int VK_CONTROL = 0x11;
const int VK_MENU = 0x12;
const int VK_LWIN = 0x5B;
const int VK_RWIN = 0x5C;
const int VK_C = 0x43;
const int VK_V = 0x56;

const int CF_UNICODETEXT = 13;

const int GMEM_MOVEABLE = 0x0002;

const int KLF_ACTIVATE = 0x00000001;

const int WH_KEYBOARD_LL = 13;
const int HC_ACTION = 0;
const int WM_KEYDOWN = 0x0100;
const int WM_KEYUP = 0x0101;
const int WM_SYSKEYDOWN = 0x0104;
const int WM_SYSKEYUP = 0x0105;
const int LLKHF_INJECTED = 0x00000010;

const int VK_MASK = 0xE8;

const int MAPVK_VK_TO_VSC = 0;

final int HKEY_CURRENT_USER = 0x80000001.toSigned(32);

const int KEY_READ = 0x20019;
const int KEY_WRITE = 0x20006;
const int REG_SZ = 1;
const int REG_DWORD = 4;

const int ERROR_SUCCESS = 0;
const int ERROR_ALREADY_EXISTS = 183;

const int WAIT_OBJECT_0 = 0;

const int EVENT_MODIFY_STATE = 0x0002;
const int SYNCHRONIZE = 0x00100000;

final int Function() GetForegroundWindow = _user32
    .lookupFunction<IntPtr Function(), int Function()>('GetForegroundWindow');

final int Function(int) GetAsyncKeyState = _user32
    .lookupFunction<Int16 Function(Int32), int Function(int)>(
        'GetAsyncKeyState');

final int Function(int, Pointer<Void>, int) SendInput = _user32.lookupFunction<
    Uint32 Function(Uint32, Pointer<Void>, Int32),
    int Function(int, Pointer<Void>, int)>('SendInput');

final int Function(int, int, int, int) RegisterHotKey = _user32.lookupFunction<
    Int32 Function(IntPtr, Int32, Uint32, Uint32),
    int Function(int, int, int, int)>('RegisterHotKey');

final int Function(int, int) UnregisterHotKey = _user32.lookupFunction<
    Int32 Function(IntPtr, Int32), int Function(int, int)>('UnregisterHotKey');

final int Function(Pointer<Void>, int, int, int) GetMessageW =
    _user32.lookupFunction<Int32 Function(Pointer<Void>, IntPtr, Uint32, Uint32),
        int Function(Pointer<Void>, int, int, int)>('GetMessageW');

final int Function(Pointer<Void>, int, int, int, int) PeekMessageW =
    _user32.lookupFunction<
        Int32 Function(Pointer<Void>, IntPtr, Uint32, Uint32, Uint32),
        int Function(Pointer<Void>, int, int, int, int)>('PeekMessageW');

final int Function(int, int, int, int) PostThreadMessageW =
    _user32.lookupFunction<Int32 Function(Uint32, Uint32, IntPtr, IntPtr),
        int Function(int, int, int, int)>('PostThreadMessageW');

final int Function(int, int, int, int) PostMessageW = _user32.lookupFunction<
    Int32 Function(IntPtr, Uint32, IntPtr, IntPtr),
    int Function(int, int, int, int)>('PostMessageW');

final int Function(int) OpenClipboard = _user32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('OpenClipboard');

final int Function() CloseClipboard = _user32
    .lookupFunction<Int32 Function(), int Function()>('CloseClipboard');

final int Function() EmptyClipboard = _user32
    .lookupFunction<Int32 Function(), int Function()>('EmptyClipboard');

final int Function(int) GetClipboardData = _user32
    .lookupFunction<IntPtr Function(Uint32), int Function(int)>(
        'GetClipboardData');

final int Function(int, int) SetClipboardData = _user32.lookupFunction<
    IntPtr Function(Uint32, IntPtr), int Function(int, int)>('SetClipboardData');

final int Function(int) EnumClipboardFormats = _user32
    .lookupFunction<Uint32 Function(Uint32), int Function(int)>(
        'EnumClipboardFormats');

final int Function() GetClipboardSequenceNumber = _user32
    .lookupFunction<Uint32 Function(), int Function()>(
        'GetClipboardSequenceNumber');

final int Function(Pointer<Utf16>, Pointer<Utf16>) FindWindowW =
    _user32.lookupFunction<IntPtr Function(Pointer<Utf16>, Pointer<Utf16>),
        int Function(Pointer<Utf16>, Pointer<Utf16>)>('FindWindowW');

final int Function(int, Pointer<Utf16>, int, int, int, int) LoadImageW =
    _user32.lookupFunction<
        IntPtr Function(IntPtr, Pointer<Utf16>, Uint32, Int32, Int32, Uint32),
        int Function(int, Pointer<Utf16>, int, int, int, int)>('LoadImageW');

final int Function(int, int, int, int) SendMessageW = _user32.lookupFunction<
    IntPtr Function(IntPtr, Uint32, IntPtr, IntPtr),
    int Function(int, int, int, int)>('SendMessageW');

final int Function(Pointer<Utf16>, int) LoadKeyboardLayoutW =
    _user32.lookupFunction<IntPtr Function(Pointer<Utf16>, Uint32),
        int Function(Pointer<Utf16>, int)>('LoadKeyboardLayoutW');

typedef HookProcNative = IntPtr Function(Int32, IntPtr, IntPtr);

final int Function(int, Pointer<NativeFunction<HookProcNative>>, int, int)
    SetWindowsHookExW = _user32.lookupFunction<
        IntPtr Function(
            Int32, Pointer<NativeFunction<HookProcNative>>, IntPtr, Uint32),
        int Function(int, Pointer<NativeFunction<HookProcNative>>, int,
            int)>('SetWindowsHookExW');

final int Function(int) UnhookWindowsHookEx = _user32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'UnhookWindowsHookEx');

final int Function(int, int, int, int) CallNextHookEx = _user32.lookupFunction<
    IntPtr Function(IntPtr, Int32, IntPtr, IntPtr),
    int Function(int, int, int, int)>('CallNextHookEx');

final int Function(int, int, int) MapVirtualKeyExW = _user32.lookupFunction<
    Uint32 Function(Uint32, Uint32, IntPtr),
    int Function(int, int, int)>('MapVirtualKeyExW');

final int Function(int, int, Pointer<Uint8>, Pointer<Uint16>, int, int, int)
    ToUnicodeEx = _user32.lookupFunction<
        Int32 Function(Uint32, Uint32, Pointer<Uint8>, Pointer<Uint16>, Int32,
            Uint32, IntPtr),
        int Function(int, int, Pointer<Uint8>, Pointer<Uint16>, int, int,
            int)>('ToUnicodeEx');

final int Function(int, int) GlobalAlloc = _kernel32.lookupFunction<
    IntPtr Function(Uint32, IntPtr), int Function(int, int)>('GlobalAlloc');

final Pointer<Void> Function(int) GlobalLock = _kernel32.lookupFunction<
    Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('GlobalLock');

final int Function(int) GlobalUnlock = _kernel32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('GlobalUnlock');

final int Function(int) GlobalFree = _kernel32
    .lookupFunction<IntPtr Function(IntPtr), int Function(int)>('GlobalFree');

final int Function(int) GlobalSize = _kernel32
    .lookupFunction<IntPtr Function(IntPtr), int Function(int)>('GlobalSize');

final int Function() GetCurrentThreadId = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetCurrentThreadId');

final int Function(Pointer<Utf16>) GetModuleHandleW = _kernel32.lookupFunction<
    IntPtr Function(Pointer<Utf16>), int Function(Pointer<Utf16>)>(
    'GetModuleHandleW');

final int Function() GetLastError = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetLastError');

final int Function(Pointer<Void>, int, Pointer<Utf16>) CreateMutexW =
    _kernel32.lookupFunction<
        IntPtr Function(Pointer<Void>, Int32, Pointer<Utf16>),
        int Function(Pointer<Void>, int, Pointer<Utf16>)>('CreateMutexW');

final int Function(Pointer<Void>, int, int, Pointer<Utf16>) CreateEventW =
    _kernel32.lookupFunction<
        IntPtr Function(Pointer<Void>, Int32, Int32, Pointer<Utf16>),
        int Function(
            Pointer<Void>, int, int, Pointer<Utf16>)>('CreateEventW');

final int Function(int, int, Pointer<Utf16>) OpenEventW =
    _kernel32.lookupFunction<IntPtr Function(Uint32, Int32, Pointer<Utf16>),
        int Function(int, int, Pointer<Utf16>)>('OpenEventW');

final int Function(int) SetEvent = _kernel32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('SetEvent');

final int Function(int, int) WaitForSingleObject = _kernel32.lookupFunction<
    Uint32 Function(IntPtr, Uint32), int Function(int, int)>(
    'WaitForSingleObject');

final int Function(int) CloseHandle = _kernel32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');

final int Function(int, Pointer<Utf16>, int, Pointer<Utf16>, int, int,
        Pointer<Void>, Pointer<IntPtr>, Pointer<Uint32>) RegCreateKeyExW =
    _advapi32.lookupFunction<
        Int32 Function(IntPtr, Pointer<Utf16>, Uint32, Pointer<Utf16>, Uint32,
            Uint32, Pointer<Void>, Pointer<IntPtr>, Pointer<Uint32>),
        int Function(int, Pointer<Utf16>, int, Pointer<Utf16>, int, int,
            Pointer<Void>, Pointer<IntPtr>, Pointer<Uint32>)>('RegCreateKeyExW');

final int Function(int, Pointer<Utf16>, int, int, Pointer<IntPtr>)
    RegOpenKeyExW = _advapi32.lookupFunction<
        Int32 Function(IntPtr, Pointer<Utf16>, Uint32, Uint32, Pointer<IntPtr>),
        int Function(int, Pointer<Utf16>, int, int,
            Pointer<IntPtr>)>('RegOpenKeyExW');

final int Function(int, Pointer<Utf16>, int, int, Pointer<Uint8>, int)
    RegSetValueExW = _advapi32.lookupFunction<
        Int32 Function(
            IntPtr, Pointer<Utf16>, Uint32, Uint32, Pointer<Uint8>, Uint32),
        int Function(int, Pointer<Utf16>, int, int, Pointer<Uint8>,
            int)>('RegSetValueExW');

final int Function(int, Pointer<Utf16>, Pointer<Uint32>, Pointer<Uint32>,
        Pointer<Uint8>, Pointer<Uint32>) RegQueryValueExW =
    _advapi32.lookupFunction<
        Int32 Function(IntPtr, Pointer<Utf16>, Pointer<Uint32>, Pointer<Uint32>,
            Pointer<Uint8>, Pointer<Uint32>),
        int Function(int, Pointer<Utf16>, Pointer<Uint32>, Pointer<Uint32>,
            Pointer<Uint8>, Pointer<Uint32>)>('RegQueryValueExW');

final int Function(int, Pointer<Utf16>) RegDeleteValueW =
    _advapi32.lookupFunction<Int32 Function(IntPtr, Pointer<Utf16>),
        int Function(int, Pointer<Utf16>)>('RegDeleteValueW');

final int Function(int, Pointer<Utf16>) RegDeleteKeyW =
    _advapi32.lookupFunction<Int32 Function(IntPtr, Pointer<Utf16>),
        int Function(int, Pointer<Utf16>)>('RegDeleteKeyW');

final int Function(int) RegCloseKey = _advapi32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>('RegCloseKey');

final bool is64Bit = sizeOf<IntPtr>() == 8;

final int inputSize = is64Bit ? 40 : 28;

final int inputUnionOffset = is64Bit ? 8 : 4;

final int msgSize = is64Bit ? 48 : 28;

final int Function() GetCurrentProcess = _kernel32
    .lookupFunction<IntPtr Function(), int Function()>('GetCurrentProcess');

final int Function(int, int, int) SetProcessWorkingSetSize =
    _kernel32.lookupFunction<Int32 Function(IntPtr, IntPtr, IntPtr),
        int Function(int, int, int)>('SetProcessWorkingSetSize');
