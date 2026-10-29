import 'dart:io';

enum _ClipboardTool { xclip, xsel, wayland }

class LinuxClipboard {
  LinuxClipboard._(this._tool);

  factory LinuxClipboard.detect() {
    final Map<String, String> env = Platform.environment;
    final bool wayland = (env['XDG_SESSION_TYPE'] ?? '').toLowerCase() ==
            'wayland' &&
        (env['WAYLAND_DISPLAY'] ?? '').isNotEmpty;

    final List<_ClipboardTool> order = wayland
        ? <_ClipboardTool>[
            _ClipboardTool.wayland,
            _ClipboardTool.xclip,
            _ClipboardTool.xsel,
          ]
        : <_ClipboardTool>[
            _ClipboardTool.xclip,
            _ClipboardTool.xsel,
            _ClipboardTool.wayland,
          ];

    for (final _ClipboardTool tool in order) {
      if (_exists(_binary(tool))) {
        return LinuxClipboard._(tool);
      }
    }
    return LinuxClipboard._(null);
  }

  final _ClipboardTool? _tool;

  bool get available => _tool != null;

  static String _binary(_ClipboardTool tool) {
    switch (tool) {
      case _ClipboardTool.xclip:
        return 'xclip';
      case _ClipboardTool.xsel:
        return 'xsel';
      case _ClipboardTool.wayland:
        return 'wl-paste';
    }
  }

  static bool _exists(String name) {
    try {
      final ProcessResult result = Process.runSync(
        'sh',
        <String>['-c', 'command -v "\$1" >/dev/null 2>&1', 'sh', name],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  String? read({bool primary = false}) {
    final _ClipboardTool? tool = _tool;
    if (tool == null) {
      return null;
    }

    final List<String> command;
    switch (tool) {
      case _ClipboardTool.xclip:
        command = <String>[
          'xclip',
          '-o',
          '-selection',
          primary ? 'primary' : 'clipboard',
        ];
      case _ClipboardTool.xsel:
        command = <String>[
          'xsel',
          primary ? '--primary' : '--clipboard',
          '--output',
        ];
      case _ClipboardTool.wayland:
        command = <String>[
          'wl-paste',
          '--no-newline',
          if (primary) '--primary',
        ];
    }

    try {
      final ProcessResult result = _run(command);
      if (result.exitCode != 0) {
        return null;
      }
      final Object? out = result.stdout;
      if (out is! String || out.isEmpty) {
        return null;
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  bool write(String text) {
    final _ClipboardTool? tool = _tool;
    if (tool == null) {
      return false;
    }

    final String pipe;
    switch (tool) {
      case _ClipboardTool.xclip:
        pipe = 'xclip -selection clipboard -i';
      case _ClipboardTool.xsel:
        pipe = 'xsel --clipboard --input';
      case _ClipboardTool.wayland:
        pipe = 'wl-copy';
    }

    try {
      final ProcessResult result = Process.runSync(
        'sh',
        <String>['-c', 'printf %s "\$1" | $pipe >/dev/null 2>&1', 'sh', text],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static ProcessResult _run(List<String> command) {
    try {
      return Process.runSync('timeout', <String>['1', ...command]);
    } on ProcessException {
      return Process.runSync(command.first, command.sublist(1));
    }
  }
}
