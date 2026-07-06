import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

import '../adapters/geometry_adapter.dart';

/// Builds a [LayerPath] using the same method names and parameter shapes as
/// `dart:ui`'s own [Path] — `moveTo`, `lineTo`, `quadraticBezierTo`,
/// `cubicTo`, `arcToPoint`, `close` — so drawing a shape for a
/// [Layers.path] layer reads the same as drawing one on a `Canvas` inside a
/// `CustomPainter`. Unlike [Path], there's no way to read commands back out
/// of a built [Path] — this builder exists precisely to give
/// `layer_canvas_flutter` a Flutter-shaped way to construct one instead.
///
/// ```dart
/// Layers.path(
///   path: LayerPathBuilder()
///     ..moveTo(const Offset(50, 0))
///     ..lineTo(const Offset(100, 100))
///     ..lineTo(const Offset(0, 100))
///     ..close(),
///   color: const Color(0xFF06D6A0),
/// )
/// ```
class LayerPathBuilder {
  final List<PathCommand> _commands;

  /// An empty builder — build it up with `moveTo`/`lineTo`/etc.
  LayerPathBuilder() : _commands = [];

  LayerPathBuilder._(this._commands);

  /// A closed shape connecting [points] in order, with a final edge back to
  /// the first point — mirrors [Path.addPolygon] (with `close: true`).
  factory LayerPathBuilder.polygon(List<Offset> points) =>
      LayerPathBuilder._(LayerPath.polygon(_toPoints(points)).commands);

  /// An open shape connecting [points] in order — mirrors [Path.addPolygon]
  /// with `close: false`.
  factory LayerPathBuilder.polyline(List<Offset> points) =>
      LayerPathBuilder._(LayerPath.polyline(_toPoints(points)).commands);

  /// A circle centered at [center] with the given [radius] — mirrors
  /// [Path.addOval] for the common equal-radius case.
  factory LayerPathBuilder.circle(Offset center, double radius) =>
      LayerPathBuilder._(LayerPath.circle(center.toPoint2D(), radius).commands);

  /// An ellipse inscribed in [rect] — mirrors [Path.addOval].
  factory LayerPathBuilder.oval(Rect rect) => LayerPathBuilder._(
    LayerPath.ellipse(
      rect.center.toPoint2D(),
      rect.width / 2,
      rect.height / 2,
    ).commands,
  );

  /// Starts a new subpath at [point] without drawing anything.
  void moveTo(Offset point) => _commands.add(MoveTo(point.toPoint2D()));

  /// Draws a straight line from the current point to [point].
  void lineTo(Offset point) => _commands.add(LineTo(point.toPoint2D()));

  /// Draws a quadratic Bézier curve from the current point to [point],
  /// using [control] as its single control point.
  void quadraticBezierTo(Offset control, Offset point) =>
      _commands.add(QuadraticBezierTo(control.toPoint2D(), point.toPoint2D()));

  /// Draws a cubic Bézier curve from the current point to [point], using
  /// [control1] and [control2] as its two control points — same parameter
  /// order as [Path.cubicTo].
  void cubicTo(Offset control1, Offset control2, Offset point) => _commands.add(
    CubicBezierTo(
      control1.toPoint2D(),
      control2.toPoint2D(),
      point.toPoint2D(),
    ),
  );

  /// Draws an elliptical arc from the current point to [arcEnd] — same
  /// name, parameters, and meaning as [Path.arcToPoint]: [clockwise]
  /// corresponds exactly to [Path.arcToPoint]'s own `clockwise` (both are
  /// the SVG arc syntax's sweep flag under the hood).
  void arcToPoint(
    Offset arcEnd, {
    Radius radius = Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    _commands.add(
      ArcTo(
        radiusX: radius.x,
        radiusY: radius.y,
        xAxisRotation: rotation,
        largeArc: largeArc,
        sweep: clockwise,
        point: arcEnd.toPoint2D(),
      ),
    );
  }

  /// Closes the current subpath with a straight line back to its start.
  void close() => _commands.add(const ClosePath());

  /// Builds the immutable [LayerPath], multiplying every coordinate (and
  /// arc radius) by [scale] — called by [Layers.path] with its own
  /// `pixelRatio`, not normally needed directly.
  LayerPath build({double scale = 1.0}) {
    if (_commands.isEmpty) {
      throw StateError(
        'LayerPathBuilder needs at least one command (moveTo/lineTo/...) before use.',
      );
    }
    if (scale == 1.0) return LayerPath(List.of(_commands));
    return LayerPath([
      for (final command in _commands) _scaled(command, scale),
    ]);
  }
}

Point2D _scaledPoint(Point2D point, double factor) =>
    Point2D(point.x * factor, point.y * factor);

PathCommand _scaled(PathCommand command, double factor) => switch (command) {
  MoveTo(:final point) => MoveTo(_scaledPoint(point, factor)),
  LineTo(:final point) => LineTo(_scaledPoint(point, factor)),
  QuadraticBezierTo(:final control, :final point) => QuadraticBezierTo(
    _scaledPoint(control, factor),
    _scaledPoint(point, factor),
  ),
  CubicBezierTo(:final control1, :final control2, :final point) =>
    CubicBezierTo(
      _scaledPoint(control1, factor),
      _scaledPoint(control2, factor),
      _scaledPoint(point, factor),
    ),
  ArcTo(
    :final radiusX,
    :final radiusY,
    :final xAxisRotation,
    :final largeArc,
    :final sweep,
    :final point,
  ) =>
    ArcTo(
      radiusX: radiusX * factor,
      radiusY: radiusY * factor,
      xAxisRotation: xAxisRotation,
      largeArc: largeArc,
      sweep: sweep,
      point: _scaledPoint(point, factor),
    ),
  ClosePath() => const ClosePath(),
};

List<Point2D> _toPoints(List<Offset> offsets) => [
  for (final o in offsets) o.toPoint2D(),
];
