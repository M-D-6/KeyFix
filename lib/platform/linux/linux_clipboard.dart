import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum _ClipboardTool { xclip, xsel, wayland }

class _TextCommandResult {
  const _TextCommandResult(this.output);

  final String output;
}

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
      if (_available(tool)) {
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

  static bool _available(_ClipboardTool tool) {
    if (tool == _ClipboardTool.wayland) {
      return _exists('wl-paste') && _exists('wl-copy');
    }
    return _exists(_binary(tool));
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

  Future<_TextCommandResult?> _runTextCommand(
    List<String> command, {
    bool allowMalformed = true,
  }) async {
    Process? process;
    try {
      process = await Process.start(command.first, command.sublist(1));
      final Future<String> output = process.stdout
          .transform(Utf8Decoder(allowMalformed: allowMalformed))
          .join();
      final Future<void> errors = process.stderr.drain<void>();
      final int exitCode = await process.exitCode.timeout(
        const Duration(milliseconds: 900),
        onTimeout: () {
          process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      final String value = await output.timeout(
        const Duration(milliseconds: 250),
        onTimeout: () => '',
      );
      await errors.timeout(
        const Duration(milliseconds: 250),
        onTimeout: () {},
      );
      if (exitCode != 0) {
        return null;
      }
      return _TextCommandResult(value);
    } catch (_) {
      process?.kill(ProcessSignal.sigkill);
      return null;
    }
  }

  List<String>? _readCommand({bool primary = false}) {
    final _ClipboardTool? tool = _tool;
    if (tool == null) {
      return null;
    }

    switch (tool) {
      case _ClipboardTool.xclip:
        return <String>[
          'xclip',
          '-o',
          '-selection',
          primary ? 'primary' : 'clipboard',
          '-target',
          'UTF8_STRING',
        ];
      case _ClipboardTool.xsel:
        return <String>[
          'xsel',
          primary ? '--primary' : '--clipboard',
          '--output',
        ];
      case _ClipboardTool.wayland:
        return <String>[
          'wl-paste',
          '--no-newline',
          '--type',
          'text/plain',
          if (primary) '--primary',
        ];
    }
  }

  Future<String?> read({bool primary = false}) async {
    final List<String>? command = _readCommand(primary: primary);
    if (command == null) {
      return null;
    }
    final _TextCommandResult? result = await _runTextCommand(
      command,
      allowMalformed: _tool != _ClipboardTool.xsel,
    );
    if (result == null || result.output.contains('\u0000')) {
      return null;
    }
    return result.output;
  }

  Future<bool> hasClipboardContent() async {
    final _ClipboardTool? tool = _tool;
    if (tool == null) {
      return false;
    }

    final List<String> command;
    switch (tool) {
      case _ClipboardTool.xclip:
        command = <String>[
          'xclip',
          '-o',
          '-selection',
          'clipboard',
          '-target',
          'TARGETS',
        ];
      case _ClipboardTool.xsel:
        command = <String>['xsel', '--clipboard', '--output'];
      case _ClipboardTool.wayland:
        command = <String>['wl-paste', '--list-types'];
    }

    final _TextCommandResult? result = await _runTextCommand(command);
    return result != null && result.output.trim().isNotEmpty;
  }

  Future<bool> write(String text) async {
    final _ClipboardTool? tool = _tool;
    if (tool == null) {
      return false;
    }

    final List<String> command;
    switch (tool) {
      case _ClipboardTool.xclip:
        command = <String>['xclip', '-selection', 'clipboard', '-i'];
      case _ClipboardTool.xsel:
        command = <String>['xsel', '--clipboard', '--input'];
      case _ClipboardTool.wayland:
        command = <String>['wl-copy', '--type', 'text/plain;charset=utf-8'];
    }

    Process? process;
    try {
      process = await Process.start(command.first, command.sublist(1));
      if (tool == _ClipboardTool.wayland) {
        process.stdout.listen((_) {});
        process.stderr.listen((_) {});
      }
      process.stdin.add(utf8.encode(text));
      await process.stdin.close();

      if (tool == _ClipboardTool.wayland) {
        try {
          return await process.exitCode.timeout(
            const Duration(milliseconds: 250),
          ) == 0;
        } on TimeoutException {
          return true;
        }
      }

      final int exitCode = await process.exitCode.timeout(
        const Duration(milliseconds: 900),
        onTimeout: () {
          process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      return exitCode == 0;
    } catch (_) {
      if (_tool != _ClipboardTool.wayland) {
        process?.kill(ProcessSignal.sigkill);
      }
      return false;
    }
  }
}
