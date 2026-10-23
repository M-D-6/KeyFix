import 'win32.dart' as w;

class MemoryTrimmer {
  MemoryTrimmer._();

  static void trim() {
    try {
      w.SetProcessWorkingSetSize(w.GetCurrentProcess(), -1, -1);
    } catch (_) {}
  }
}
