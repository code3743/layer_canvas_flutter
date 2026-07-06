import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart' as lc;

import 'color_adapter.dart';

/// Converts a Flutter [TileMode] to the core's [lc.GradientExtendMode].
///
/// [TileMode.decal] (transparent beyond the gradient's extent) has no
/// equivalent — [lc.GradientExtendMode] only covers pad/repeat/reflect —
/// so it falls back to [lc.GradientExtendMode.pad], the closest of the
/// three to "don't tile".
extension TileModeX on TileMode {
  lc.GradientExtendMode toGradientExtendMode() => switch (this) {
    TileMode.clamp => lc.GradientExtendMode.pad,
    TileMode.repeated => lc.GradientExtendMode.repeat,
    TileMode.mirror => lc.GradientExtendMode.reflect,
    TileMode.decal => lc.GradientExtendMode.pad,
  };
}

/// Converts a Flutter [AlignmentGeometry] (as used by [Gradient.begin]/
/// `.end`/`.center`) to the core's fractional `0.0..1.0` gradient-geometry
/// coordinates: `Alignment.topLeft` (-1,-1) becomes (0,0), `bottomRight`
/// (1,1) becomes (1,1), matching how [lc.LayerTransform.anchor] already
/// uses fractional coordinates over the same (-1..1 vs 0..1) difference.
///
/// Resolved against [textDirection] since [AlignmentGeometry] can be
/// direction-dependent (e.g. `AlignmentDirectional`); defaults to `ltr`.
extension AlignmentGeometryX on AlignmentGeometry {
  lc.Point2D toFractionalPoint2D({TextDirection textDirection = TextDirection.ltr}) {
    final resolved = resolve(textDirection);
    return lc.Point2D((resolved.x + 1) / 2, (resolved.y + 1) / 2);
  }
}

/// Converts a Flutter [Gradient] — a [LinearGradient], [RadialGradient], or
/// [SweepGradient] — to the core's [lc.Gradient], for use as a
/// [Layers.rectangle]/[Layers.path] `gradient:` argument.
///
/// This file is the one place in the package that imports `layer_canvas`
/// with a prefix: [Gradient] and its subclasses are Flutter types this
/// package re-exports unprefixed (via `package:flutter/widgets.dart`), so
/// converting to the *core's* same-named types needs `lc.` to tell them
/// apart — unlike `Color`/`Color32` or `Offset`/`Point2D`, there's no way
/// to import both unprefixed here.
extension GradientX on Gradient {
  /// Throws [ArgumentError] for any [Gradient] subtype other than the three
  /// Flutter ships — there's no fourth core gradient kind to fall back to.
  lc.Gradient toLayerGradient({TextDirection textDirection = TextDirection.ltr}) {
    final self = this;
    final stops = _resolveStops(self.colors, self.stops);

    if (self is LinearGradient) {
      return lc.LinearGradient(
        start: self.begin.toFractionalPoint2D(textDirection: textDirection),
        end: self.end.toFractionalPoint2D(textDirection: textDirection),
        stops: stops,
        extendMode: self.tileMode.toGradientExtendMode(),
      );
    }
    if (self is RadialGradient) {
      // Core's `radius` is fractional relative to the layer's own width;
      // Flutter's is fractional relative to the paint box's *shortest*
      // side. The two agree exactly on a square layer and are a close
      // approximation otherwise.
      return lc.RadialGradient(
        center: self.center.toFractionalPoint2D(textDirection: textDirection),
        radius: self.radius,
        stops: stops,
        extendMode: self.tileMode.toGradientExtendMode(),
      );
    }
    if (self is SweepGradient) {
      // Core's ConicGradient always sweeps a full circle from a single
      // `angle` — there's no `endAngle` to narrow the sweep to a sector,
      // so `startAngle` carries over and `endAngle` is dropped.
      return lc.ConicGradient(
        center: self.center.toFractionalPoint2D(textDirection: textDirection),
        angle: self.startAngle,
        stops: stops,
        extendMode: self.tileMode.toGradientExtendMode(),
      );
    }

    throw ArgumentError.value(
      self,
      'this',
      'Unsupported Gradient subtype — only LinearGradient, RadialGradient, '
          'and SweepGradient can be converted to a layer_canvas Gradient.',
    );
  }
}

List<lc.GradientStop> _resolveStops(List<Color> colors, List<double>? stops) {
  final resolvedStops =
      stops ?? [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)];
  return [
    for (var i = 0; i < colors.length; i++) lc.GradientStop(resolvedStops[i], colors[i].toColor32()),
  ];
}
