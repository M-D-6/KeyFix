import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'platform/windows/menu_theme.dart';
import 'platform/windows/window_icon.dart';
import 'services/app_controller.dart';

const String _startupArgument = '--startup';
const String _initialLanguageArgument = '--initial-language=';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isWindows) {
    stderr.writeln('KeyFix: this build supports Windows only for now.');
    exit(1);
  }

  final bool startedFromStartup = args.any(
    (String a) => a.toLowerCase() == _startupArgument,
  );

  String? initialLanguage;
  for (final String a in args) {
    if (a.toLowerCase().startsWith(_initialLanguageArgument)) {
      final String v = a.substring(_initialLanguageArgument.length).toLowerCase();
      if (v == 'fa' || v == 'en') {
        initialLanguage = v;
      }
    }
  }

  PaintingBinding.instance.imageCache
    ..maximumSize = 16
    ..maximumSizeBytes = 4 * 1024 * 1024;

  enableSystemThemedMenus();

  await windowManager.ensureInitialized();

  final AppController controller = await AppController.create(
    backgroundMode: startedFromStartup,
    initialLanguage: initialLanguage,
  );

  const WindowOptions options = WindowOptions(
    size: Size(960, 680),
    minimumSize: Size(760, 380),
    center: true,
    title: 'KeyFix',
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Color(0xFF151718),
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    if (!startedFromStartup) {
      await controller.showMainWindow();
    }
  });

  applyWindowIcon();

  runApp(KeyFixApp(controller: controller));
}
