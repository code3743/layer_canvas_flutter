import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

/// Converts a Flutter [PathFillType] (as used by `dart:ui`'s own [Path]) to
/// the core's [FillRule].
extension PathFillTypeX on PathFillType {
  FillRule toFillRule() => switch (this) {
    PathFillType.nonZero => FillRule.nonZero,
    PathFillType.evenOdd => FillRule.evenOdd,
  };
}

/// Converts a core [FillRule] back to a Flutter [PathFillType].
extension FillRuleX on FillRule {
  PathFillType toPathFillType() => switch (this) {
    FillRule.nonZero => PathFillType.nonZero,
    FillRule.evenOdd => PathFillType.evenOdd,
  };
}
