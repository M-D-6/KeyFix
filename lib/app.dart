import 'package:flutter/material.dart';

import 'services/app_controller.dart';
import 'ui/fluent_theme.dart';
import 'ui/home_page.dart';

class KeyFixApp extends StatefulWidget {
  const KeyFixApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<KeyFixApp> createState() => _KeyFixAppState();
}

class _KeyFixAppState extends State<KeyFixApp> with WidgetsBindingObserver {
  late Brightness _brightness;
  late final Color _accent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _accent = Color(AppController.readAccentColor());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness next =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    if (next != _brightness) {
      setState(() => _brightness = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentColors.of(
      dark: _brightness == Brightness.dark,
      accent: _accent,
    );

    return FluentTheme(
      colors: colors,
      child: MaterialApp(
        title: 'KeyFix',
        debugShowCheckedModeBanner: false,
        theme: buildMaterialTheme(colors),
        builder: (BuildContext context, Widget? child) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(
          backgroundColor: colors.background,
          body: HomePage(controller: widget.controller),
        ),
      ),
    );
  }
}
