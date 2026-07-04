import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

const _textWeights = [
  TextWeight.thin,
  TextWeight.light,
  TextWeight.normal,
  TextWeight.medium,
  TextWeight.semiBold,
  TextWeight.bold,
  TextWeight.black,
];

/// Converts a Flutter [FontWeight] to the core's [TextWeight].
///
/// [TextWeight] only exposes 7 static values (thin/light/normal/medium/
/// semiBold/bold/black) with a private constructor, so [FontWeight.value]
/// is mapped to the closest one rather than a 1:1 conversion.
extension FontWeightX on FontWeight {
  TextWeight toTextWeight() {
    var closest = _textWeights.first;
    var closestDiff = (value - closest.value).abs();
    for (final candidate in _textWeights.skip(1)) {
      final diff = (value - candidate.value).abs();
      if (diff < closestDiff) {
        closest = candidate;
        closestDiff = diff;
      }
    }
    return closest;
  }
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
