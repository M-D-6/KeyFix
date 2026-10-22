import 'package:flutter/material.dart';

import '../fluent_theme.dart';

class BidiText extends StatelessWidget {
  const BidiText(
    this.text, {
    super.key,
    required this.persian,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w400,
    this.opacity = 1,
    this.wrap = true,
    this.center = false,
    this.color,
  });

  final String text;
  final bool persian;
  final double fontSize;
  final FontWeight fontWeight;
  final double opacity;
  final bool wrap;
  final bool center;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final FluentColors c = FluentTheme.of(context);

    final Text child = Text(
      text,
      textDirection: persian ? TextDirection.rtl : TextDirection.ltr,
      textAlign: center
          ? TextAlign.center
          : (persian ? TextAlign.right : TextAlign.left),
      softWrap: wrap,
      overflow: wrap ? TextOverflow.clip : TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? c.textPrimary,
        height: 1.45,
      ),
    );

    final Widget stretched = SizedBox(width: double.infinity, child: child);

    return opacity >= 1
        ? stretched
        : Opacity(opacity: opacity, child: stretched);
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.color,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final FluentColors c = FluentTheme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final FluentColors c = FluentTheme.of(context);
    final bool primary = widget.primary;

    final Color fill = primary
        ? (_hover || _down ? Color.lerp(c.accent, c.onAccent, 0.12)! : c.accent)
        : (_hover || _down ? c.raisedHover : c.raised);
    final Color foreground = primary ? c.onAccent : c.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, size: 18, color: foreground),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernSwitch extends StatelessWidget {
  const ModernSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final FluentColors c = FluentTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 50,
          height: 30,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: value ? c.accent : c.raised,
            border: Border.all(
              color: value ? c.accent : c.textSecondary.withAlpha(110),
              width: 1.5,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: value ? 20 : 16,
              height: value ? 20 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? c.onAccent : c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final FluentColors c = FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < items.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: i == selectedIndex ? c.accent : Colors.transparent,
                  ),
                  child: Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: i == selectedIndex ? c.onAccent : c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class KeyCaps extends StatelessWidget {
  const KeyCaps({super.key, required this.parts, this.large = true});

  final List<String> parts;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final FluentColors c = FluentTheme.of(context);
    final double fontSize = large ? 18 : 14;

    final List<Widget> children = <Widget>[];

    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '+',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ),
        );
      }

      children.add(
        Container(
          constraints: BoxConstraints(minWidth: large ? 52 : 40),
          padding: EdgeInsets.symmetric(
            horizontal: large ? 16 : 12,
            vertical: large ? 10 : 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(large ? 14 : 11),
            color: c.raised,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: c.textSecondary.withAlpha(70),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            parts[i],
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10,
      children: children,
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final FluentColors c = FluentTheme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.34),
        color: c.accentSoft,
      ),
      child: Icon(icon, size: size * 0.54, color: c.onAccentSoft),
    );
  }
}
