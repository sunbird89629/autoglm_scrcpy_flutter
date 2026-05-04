import 'package:flutter/services.dart';

/// Android `KeyEvent` metastate bitmask constants.
class AndroidMetastate {
  static const int shiftOn = 0x00000001;
  static const int altOn = 0x00000002;
  static const int ctrlOn = 0x00001000;
  static const int metaOn = 0x00010000;
}

/// Tracks modifier key state and produces the Android metastate bitmask
/// to attach to key injection messages.
class ScrcpyMetastate {
  bool _shift = false;
  bool _alt = false;
  bool _ctrl = false;
  bool _meta = false;

  /// Current metastate bitmask for inclusion in key injection messages.
  int get bitmask {
    int m = 0;
    if (_shift) m |= AndroidMetastate.shiftOn;
    if (_alt) m |= AndroidMetastate.altOn;
    if (_ctrl) m |= AndroidMetastate.ctrlOn;
    if (_meta) m |= AndroidMetastate.metaOn;
    return m;
  }

  /// Updates internal modifier state based on [logicalKey].
  ///
  /// Returns `true` if the key is a modifier (Shift/Alt/Ctrl/Meta),
  /// `false` otherwise.
  bool handleKey(LogicalKeyboardKey logicalKey, {required bool isDown}) {
    if (_isShift(logicalKey)) {
      _shift = isDown;
      return true;
    }
    if (_isAlt(logicalKey)) {
      _alt = isDown;
      return true;
    }
    if (_isCtrl(logicalKey)) {
      _ctrl = isDown;
      return true;
    }
    if (_isMeta(logicalKey)) {
      _meta = isDown;
      return true;
    }
    return false;
  }

  static bool _isShift(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.shift ||
      k == LogicalKeyboardKey.shiftLeft ||
      k == LogicalKeyboardKey.shiftRight;

  static bool _isAlt(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.alt ||
      k == LogicalKeyboardKey.altLeft ||
      k == LogicalKeyboardKey.altRight;

  static bool _isCtrl(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.control ||
      k == LogicalKeyboardKey.controlLeft ||
      k == LogicalKeyboardKey.controlRight;

  static bool _isMeta(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.meta ||
      k == LogicalKeyboardKey.metaLeft ||
      k == LogicalKeyboardKey.metaRight;
}
