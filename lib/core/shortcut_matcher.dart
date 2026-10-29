import 'shortcut_definition.dart';

class MatchDecision {
  const MatchDecision({
    this.fire = false,
    this.swallow = false,
    this.needsMask = false,
  });

  static const MatchDecision none = MatchDecision();

  final bool fire;
  final bool swallow;
  final bool needsMask;
}

class ShortcutMatcher {
  ShortcutMatcher(this.modifiers, this.key);

  factory ShortcutMatcher.of(ShortcutDefinition shortcut) {
    return ShortcutMatcher(shortcut.modifiers, shortcut.virtualKey);
  }

  final int modifiers;
  final int key;

  bool _armed = false;
  bool _tainted = false;
  bool _swallowing = false;

  void reset() {
    _armed = false;
    _tainted = false;
    _swallowing = false;
  }

  MatchDecision handle({
    required bool modifierEvent,
    required int virtualKey,
    required bool down,
    required int mods,
  }) {
    if (key == 0) {
      return _handleModifierOnly(modifierEvent, down, mods);
    }
    return _handleKey(modifierEvent, virtualKey, down, mods);
  }

  MatchDecision _handleModifierOnly(bool modifierEvent, bool down, int mods) {
    if (!modifierEvent) {
      if (down) {
        _tainted = mods != 0;
        if (mods != 0) {
          _armed = false;
        }
      }
      return MatchDecision.none;
    }

    if (down) {
      if ((mods & ~modifiers) != 0) {
        _tainted = true;
        _armed = false;
      } else if (mods == modifiers && !_armed && !_tainted) {
        _armed = true;
        return const MatchDecision(needsMask: true);
      }
      return MatchDecision.none;
    }

    final bool fire = _armed && !_tainted;
    _armed = false;

    if (mods == 0) {
      _tainted = false;
    }

    return fire ? const MatchDecision(fire: true) : MatchDecision.none;
  }

  MatchDecision _handleKey(
    bool modifierEvent,
    int virtualKey,
    bool down,
    int mods,
  ) {
    if (modifierEvent) {
      return MatchDecision.none;
    }

    if (virtualKey != key) {
      if (down) {
        _swallowing = false;
      }
      return MatchDecision.none;
    }

    if (down) {
      if (_swallowing) {
        return const MatchDecision(swallow: true);
      }

      if (mods != modifiers) {
        return MatchDecision.none;
      }

      _swallowing = true;
      return MatchDecision(
        fire: true,
        swallow: true,
        needsMask: (modifiers &
                (ShortcutDefinition.modAlt | ShortcutDefinition.modWin)) !=
            0,
      );
    }

    if (_swallowing) {
      _swallowing = false;
      return const MatchDecision(swallow: true);
    }
    return MatchDecision.none;
  }
}
