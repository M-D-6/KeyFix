import 'dart:io';

class AppLog {
  AppLog._();

  static String? _path;
  static const int _maxBytes = 256 * 1024;

  static String get path {
    final String? cached = _path;
    if (cached != null) return cached;

    final String base = Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['APPDATA'] ??
        Directory.systemTemp.path;
    final String dir = '$base${Platform.pathSeparator}KeyFix';
    try {
      Directory(dir).createSync(recursive: true);
    } catch (_) {}
    return _path = '$dir${Platform.pathSeparator}log.txt';
  }

  static void write(String line) {
    try {
      final File file = File(path);
      if (file.existsSync() && file.lengthSync() > _maxBytes) {
        file.writeAsStringSync('');
      }
      file.writeAsStringSync(
        '${DateTime.now().toIso8601String()}  $line\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }
}
