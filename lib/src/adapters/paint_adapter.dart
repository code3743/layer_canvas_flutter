import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart' as lc;

/// Converts a Flutter [StrokeCap] (as used by `dart:ui`'s own [Paint]) to
/// the core's [lc.StrokeCap].
///
/// Both packages name this enum (and its three values) identically, so —
/// like [Gradient]/`lc.Gradient` in `gradient_adapter.dart` — this file is
/// the one place that imports `layer_canvas` with an `lc.` prefix instead of
/// hiding the core's copy; callers keep using Flutter's own [StrokeCap].
extension StrokeCapX on StrokeCap {
  lc.StrokeCap toLayerStrokeCap() => switch (this) {
    StrokeCap.butt => lc.StrokeCap.butt,
    StrokeCap.round => lc.StrokeCap.round,
    StrokeCap.square => lc.StrokeCap.square,
  };
}

/// Converts a Flutter [StrokeJoin] to the core's [lc.StrokeJoin] — see
/// [StrokeCapX] for why this needs the `lc.` prefix.
extension StrokeJoinX on StrokeJoin {
  lc.StrokeJoin toLayerStrokeJoin() => switch (this) {
    StrokeJoin.miter => lc.StrokeJoin.miter,
    StrokeJoin.round => lc.StrokeJoin.round,
    StrokeJoin.bevel => lc.StrokeJoin.bevel,
  };
}
