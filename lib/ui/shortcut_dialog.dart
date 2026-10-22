import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_controller.dart';
import '../services/shortcut_recorder.dart';
import 'fluent_theme.dart';
import 'key_mapping.dart';
import 'widgets/fluent_widgets.dart';

Future<void> showShortcutDialog(BuildContext context, AppController c) async {
  c.recorder.begin();
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) => ShortcutDialog(controller: c),
  );
  c.recorder.close();
}

class ShortcutDialog extends StatefulWidget {
  const ShortcutDialog({super.key, required this.controller});

  final AppController controller;

  @override
  State<ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<ShortcutDialog> {
  final FocusNode _focus = FocusNode(debugLabel: 'ShortcutCapture');
  bool _showRules = false;

  AppController get c => widget.controller;
  ShortcutRecorder get r => c.recorder;

  static const Set<String> _errorKeys = <String>{
    'InvalidShortcut',
    'InvalidMainKey',
    'LoneKeyNotAllowed',
    'ShiftOnlyNotAllowed',
    'ShortcutReserved',
    'ShortcutUnavailable',
    'ResetShortcut',
  };

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final int vk = windowsVirtualKeyFor(event);

    if (event is KeyUpEvent) {
      r.processKeyUp(vk);
    } else if (event is KeyDownEvent && r.recording) {
      r.processKeyDown(vk);
    }

    return KeyEventResult.handled;
  }

  Future<void> _save() async {
    await c.saveShortcut();
    if (!r.visible && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _restart() {
    r.begin();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final FluentColors col = FluentTheme.of(context);
    final bool fa = c.isPersian;

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[c, r]),
      builder: (BuildContext context, _) {
        final List<String> parts = r.displayParts();
        final bool active = r.recording;
        final bool ready = r.complete;
        final String? key = r.helpKey;
        final bool isError = key != null && _errorKeys.contains(key);
        final String message =
            isError ? '${c.L(key)}${r.helpSuffix}' : '';

        final Widget capture = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _restart,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 112),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? col.accentSoft : col.raised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? col.accent : col.stroke,
                width: active ? 2 : 1,
              ),
            ),
            child: parts.isEmpty
                ? Text(
                    c.L('ShortcutPlaceholder'),
                    textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: col.textSecondary,
                    ),
                  )
                : KeyCaps(parts: parts, large: true),
          ),
        );

        final Widget infoButton = Tooltip(
          message: c.L('ShortcutRules'),
          child: InkResponse(
            onTap: () => setState(() => _showRules = !_showRules),
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                _showRules ? Icons.info_rounded : Icons.info_outline_rounded,
                size: 22,
                color: _showRules ? col.accent : col.textSecondary,
              ),
            ),
          ),
        );

        final Widget header = Row(
          children: fa
              ? <Widget>[
                  infoButton,
                  const SizedBox(width: 8),
                  Expanded(child: _title(fa)),
                ]
              : <Widget>[
                  Expanded(child: _title(fa)),
                  const SizedBox(width: 8),
                  infoButton,
                ],
        );

        final Widget rules = AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _showRules
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: col.raised,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: BidiText(
                      c.L('ShortcutHelp'),
                      persian: fa,
                      fontSize: 12.5,
                      opacity: 0.8,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        );

        final Widget error = AnimatedSize(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.topCenter,
          child: message.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: BidiText(
                    message,
                    persian: fa,
                    fontSize: 12.5,
                    color: const Color(0xFFEF4444),
                  ),
                ),
        );

        final Widget save = Opacity(
          opacity: ready ? 1 : 0.45,
          child: IgnorePointer(
            ignoring: !ready,
            child: AppButton(
              label: c.L('Save'),
              primary: true,
              onPressed: _save,
            ),
          ),
        );

        final Widget cancel = AppButton(
          label: c.L('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        );

        final Widget buttons = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: fa
              ? <Widget>[save, const SizedBox(width: 10), cancel]
              : <Widget>[cancel, const SizedBox(width: 10), save],
        );

        return Dialog(
          backgroundColor: col.card,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _onKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    rules,
                    const SizedBox(height: 18),
                    capture,
                    error,
                    const SizedBox(height: 22),
                    buttons,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _title(bool fa) {
    return BidiText(
      c.L('ShortcutEditor'),
      persian: fa,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      wrap: false,
    );
  }
}
