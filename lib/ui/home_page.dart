import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/localization.dart';
import '../services/app_controller.dart';
import '../services/shortcut_recorder.dart';
import 'fluent_theme.dart';
import 'shortcut_dialog.dart';
import 'widgets/caption_buttons.dart';
import 'widgets/fluent_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppController get c => widget.controller;
  ShortcutRecorder get r => c.recorder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[c, r]),
      builder: (BuildContext context, _) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              top: 32,
              child: _buildScrollBody(context),
            ),
            _buildTitleBar(context),
          ],
        );
      },
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    final FluentColors col = FluentTheme.of(context);

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 32,
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: DragToMoveArea(
                child: Padding(
                  padding: EdgeInsets.only(left: Platform.isMacOS ? 78 : 12),
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        'assets/title/KeyFix.png',
                        width: 16,
                        height: 16,
                        cacheWidth: 32,
                        filterQuality: FilterQuality.medium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KeyFix',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: col.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!Platform.isMacOS) const CaptionButtons(),
        ],
      ),
    );
  }

  Widget _buildScrollBody(BuildContext context) {
    final bool fa = c.isPersian;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHero(context, fa),
                const SizedBox(height: 14),
                _buildShortcutCard(context, fa),
                const SizedBox(height: 14),
                _buildExecutionCard(context, fa),
                const SizedBox(height: 14),
                _buildConversionCard(context, fa),
                const SizedBox(height: 14),
                _buildStatusCard(context, fa),
                const SizedBox(height: 18),
                _buildAbout(context, fa),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _ordered(bool fa, List<Widget> items) {
    return fa ? items.reversed.toList() : items;
  }

  Widget _buildHero(BuildContext context, bool fa) {
    final FluentColors col = FluentTheme.of(context);

    final Widget logo = Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: col.raised,
      ),
      child: Image.asset(
        'assets/title/KeyFix.png',
        cacheWidth: 128,
        filterQuality: FilterQuality.medium,
      ),
    );

    final Widget titles = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BidiText(
          'KeyFix',
          persian: fa,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          wrap: false,
          color: col.textPrimary,
        ),
        const SizedBox(height: 2),
        BidiText(
          c.L('Description'),
          persian: fa,
          fontSize: 14,
          opacity: 0.72,
        ),
      ],
    );

    final Widget language = SegmentedPill(
      items: <String>[c.L('Persian'), c.L('English')],
      selectedIndex: fa ? 0 : 1,
      onChanged: (int index) => c.setLanguage(
        index == 1 ? AppLanguage.english : AppLanguage.persian,
      ),
    );

    final Widget statusDot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.enabled ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (c.enabled ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                .withAlpha(150),
            blurRadius: 8,
          ),
        ],
      ),
    );

    final Widget statusRow = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: col.raised,
      ),
      child: Row(
        children: _ordered(fa, <Widget>[
          statusDot,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                BidiText(
                  c.L('KeyFixEnabled'),
                  persian: fa,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 2),
                BidiText(
                  c.L('KeyFixStatusDescription'),
                  persian: fa,
                  fontSize: 12.5,
                  opacity: 0.68,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ModernSwitch(value: c.enabled, onChanged: c.setEnabled),
        ]),
      ),
    );

    return Panel(
      radius: 28,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _ordered(fa, <Widget>[
              logo,
              const SizedBox(width: 16),
              Expanded(child: titles),
              const SizedBox(width: 12),
              language,
            ]),
          ),
          const SizedBox(height: 18),
          statusRow,
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    bool fa,
    IconData icon,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: _ordered(fa, <Widget>[
          IconBadge(icon: icon, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: BidiText(
              title,
              persian: fa,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              wrap: false,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildShortcutCard(BuildContext context, bool fa) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionHeader(
            context,
            fa,
            Icons.keyboard_command_key_rounded,
            c.L('ShortcutSection'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: BidiText(
              c.L('ShortcutDescription'),
              persian: fa,
              fontSize: 13,
              opacity: 0.68,
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: KeyCaps(parts: c.currentShortcut.parts),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Align(
              alignment: fa ? Alignment.centerRight : Alignment.centerLeft,
              child: AppButton(
                label: c.L('ChangeShortcut'),
                icon: Icons.edit_rounded,
                onPressed: () => showShortcutDialog(context, c),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionsCard(
    BuildContext context,
    bool fa, {
    required IconData icon,
    required String title,
    required List<Widget> rows,
  }) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionHeader(context, fa, icon, title),
          const SizedBox(height: 6),
          ...rows,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _optionRow(
    BuildContext context,
    bool fa, {
    required IconData icon,
    required String titleKey,
    required String descriptionKey,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final FluentColors col = FluentTheme.of(context);

    return InkWell(
      onTap: () => onChanged(!value),
      hoverColor: col.raised,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: _ordered(fa, <Widget>[
            Icon(icon, size: 22, color: col.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  BidiText(
                    c.L(titleKey),
                    persian: fa,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 2),
                  BidiText(
                    c.L(descriptionKey),
                    persian: fa,
                    fontSize: 12.5,
                    opacity: 0.66,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ModernSwitch(value: value, onChanged: onChanged),
          ]),
        ),
      ),
    );
  }

  Widget _buildExecutionCard(BuildContext context, bool fa) {
    return _optionsCard(
      context,
      fa,
      icon: Icons.tune_rounded,
      title: c.L('ExecutionOptions'),
      rows: <Widget>[
        _optionRow(
          context,
          fa,
          icon: Icons.power_settings_new_rounded,
          titleKey: 'Startup',
          descriptionKey: 'StartupDescription',
          value: c.settings.startWithWindows,
          onChanged: c.setStartWithWindows,
        ),
        _optionRow(
          context,
          fa,
          icon: Icons.layers_rounded,
          titleKey: 'KeepRunningInBackground',
          descriptionKey: 'KeepRunningInBackgroundDescription',
          value: c.settings.keepRunningInBackground,
          onChanged: c.setKeepRunningInBackground,
        ),
        _optionRow(
          context,
          fa,
          icon: Icons.push_pin_rounded,
          titleKey: 'ShowTrayIcon',
          descriptionKey: 'ShowTrayIconDescription',
          value: c.settings.showTrayIcon,
          onChanged: c.setShowTrayIcon,
        ),
        _optionRow(
          context,
          fa,
          icon: Icons.notifications_active_rounded,
          titleKey: 'StatusNotifications',
          descriptionKey: 'StatusNotificationsDescription',
          value: c.settings.statusNotifications,
          onChanged: c.setStatusNotifications,
        ),
      ],
    );
  }

  Widget _buildConversionCard(BuildContext context, bool fa) {
    return _optionsCard(
      context,
      fa,
      icon: Icons.sync_alt_rounded,
      title: c.L('ConversionOptions'),
      rows: <Widget>[
        _optionRow(
          context,
          fa,
          icon: Icons.translate_rounded,
          titleKey: 'AutoSwitchKeyboardLanguageTitle',
          descriptionKey: 'AutoSwitchKeyboardLanguageDescription',
          value: c.settings.autoSwitchKeyboardLanguage,
          onChanged: c.setAutoSwitchKeyboardLanguage,
        ),
        _optionRow(
          context,
          fa,
          icon: Icons.keyboard_capslock_rounded,
          titleKey: 'DetectCapsLockTitle',
          descriptionKey: 'DetectCapsLockDescription',
          value: c.settings.detectCapsLockInMixedCaseEnglish,
          onChanged: c.setDetectCapsLock,
        ),
        _optionRow(
          context,
          fa,
          icon: Icons.keyboard_double_arrow_left_rounded,
          titleKey: 'PersianToEnglish',
          descriptionKey: 'PersianToEnglishDescription',
          value: c.settings.ignoreShiftPersianToEnglish,
          onChanged: c.setIgnoreShiftPersianToEnglish,
        ),
        _optionRow(
          context,
          fa,
          icon: Icons.keyboard_double_arrow_right_rounded,
          titleKey: 'EnglishToPersian',
          descriptionKey: 'EnglishToPersianDescription',
          value: c.settings.ignoreShiftEnglishToPersian,
          onChanged: c.setIgnoreShiftEnglishToPersian,
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, bool fa) {
    return Panel(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _ordered(fa, <Widget>[
          const IconBadge(icon: Icons.bolt_rounded, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                BidiText(
                  c.L('StatusTitle'),
                  persian: fa,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  wrap: false,
                ),
                const SizedBox(height: 4),
                BidiText(
                  c.statusText,
                  persian: fa,
                  fontSize: 13,
                  opacity: 0.82,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAbout(BuildContext context, bool fa) {
    return Column(
      children: <Widget>[
        BidiText(
          c.L('About'),
          persian: fa,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          opacity: 0.8,
          center: true,
        ),
        const SizedBox(height: 4),
        BidiText(
          c.L('AboutDescription'),
          persian: fa,
          fontSize: 12,
          opacity: 0.58,
          center: true,
        ),
      ],
    );
  }
}
