import 'dart:io';

import '../autostart.dart';

class MacAutoStart implements AutoStart {
  static const String _label = 'app.keyfix.agent';

  static String get _path {
    final String home = Platform.environment['HOME'] ?? '.';
    return '$home/Library/LaunchAgents/$_label.plist';
  }

  static String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  static List<String> get _programArguments {
    final String executable = File(Platform.resolvedExecutable).absolute.path;
    final int marker = executable.indexOf('/Contents/MacOS/');
    if (marker >= 0) {
      final String appBundle = executable.substring(0, marker);
      return <String>[
        '/usr/bin/open',
        '-a',
        appBundle,
        '--args',
        '--startup',
      ];
    }
    return <String>[executable, '--startup'];
  }

  static String get _content {
    final List<String> args = _programArguments.map(_escape).toList();
    final String arguments = args.map((String arg) => '    <string>$arg</string>\n').join();
    return '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
        '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
        '<plist version="1.0">\n'
        '<dict>\n'
        '  <key>Label</key>\n'
        '  <string>$_label</string>\n'
        '  <key>ProgramArguments</key>\n'
        '  <array>\n'
        '$arguments'
        '  </array>\n'
        '  <key>RunAtLoad</key>\n'
        '  <true/>\n'
        '  <key>ProcessType</key>\n'
        '  <string>Interactive</string>\n'
        '  <key>LimitLoadToSessionType</key>\n'
        '  <string>Aqua</string>\n'
        '</dict>\n'
        '</plist>\n';
  }

  @override
  bool isEnabled() {
    try {
      return File(_path).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  bool setEnabled(bool enabled) {
    try {
      final File file = File(_path);
      if (!enabled) {
        if (file.existsSync()) {
          file.deleteSync();
        }
        return true;
      }
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(_content);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void refreshCurrentPath() {
    try {
      final File file = File(_path);
      if (file.existsSync() && file.readAsStringSync() != _content) {
        file.writeAsStringSync(_content);
      }
    } catch (_) {}
  }
}
