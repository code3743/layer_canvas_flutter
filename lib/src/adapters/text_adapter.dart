import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

/// Converts a Flutter [FontWeight] to the core's [TextWeight].
///
/// Exact: [TextWeight.fromValue] accepts any 100..900 weight, and
/// [FontWeight.value] is already one of those nine steps, so no
/// nearest-match rounding is needed (unlike [TextWeightX.toFontWeight]'s
/// reverse direction being exact for a different reason — every named
/// [TextWeight] constant already lands on one of Flutter's nine steps).
extension FontWeightX on FontWeight {
  TextWeight toTextWeight() => TextWeight.fromValue(value);
}

/// Converts a core [TextWeight] to a Flutter [FontWeight].
///
/// Unlike [FontWeightX.toTextWeight], this is exact: every [TextWeight]
/// static value is already one of the nine 100-900 steps [FontWeight] has.
extension TextWeightX on TextWeight {
  FontWeight toFontWeight() => FontWeight.values[(value ~/ 100) - 1];
}

/// Converts a Flutter [TextAlign] to the core's [TextAlignment].
///
/// [TextAlignment] only has left/center/right: [TextAlign.start] and
/// [TextAlign.justify] map to `left`, [TextAlign.end] maps to `right`.
extension TextAlignX on TextAlign {
  TextAlignment toTextAlignment() {
    switch (this) {
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
        return TextAlignment.left;
      case TextAlign.center:
        return TextAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return TextAlignment.right;
    }
  }
}

/// Converts a core [TextAlignment] back to a Flutter [TextAlign].
extension TextAlignmentX on TextAlignment {
  TextAlign toTextAlign() => switch (this) {
    TextAlignment.left => TextAlign.left,
    TextAlignment.center => TextAlign.center,
    TextAlignment.right => TextAlign.right,
  };
}
