import 'package:flutter/widgets.dart';
// `Gradient` (and its Linear/Radial/Conic subtypes) and `StrokeCap`/
// `StrokeJoin` hidden: this file's own factories take Flutter's own
// same-named types as parameters (see `rectangle`/`path` below) and convert
// them via `GradientX.toLayerGradient`/`StrokeCapX.toLayerStrokeCap`/
// `StrokeJoinX.toLayerStrokeJoin` — the core's copies are never referenced
// by name here, only produced by those adapters, so importing both
// unprefixed would be a real ambiguous-import error, not just a style
// nitpick.
import 'package:layer_canvas/layer_canvas.dart'
    hide Gradient, LinearGradient, RadialGradient, StrokeCap, StrokeJoin;

import '../adapters/color_adapter.dart';
import '../adapters/geometry_adapter.dart';
import '../adapters/gradient_adapter.dart';
import '../adapters/image_adapter.dart';
import '../adapters/paint_adapter.dart';
import '../adapters/path_adapter.dart';
import '../adapters/text_adapter.dart';
import '../fonts/layer_canvas_fonts.dart';
import '../paths/layer_path_builder.dart';

/// Factories that build `layer_canvas` [Layer]s from Flutter types
/// (`Color`, `Offset`, `Size`, `FontWeight`, `TextAlign`, `BoxFit`,
/// `Gradient`, `Path`-shaped builders…), so callers never have to touch
/// `Color32`/`Point2D`/`TextWeight` directly.
///
/// Dart has no extension constructors, so these are static factories on a
/// namespace class rather than constructors on the core layer types — the
/// same pattern as `Colors`/`Icons`/`Curves` in Flutter itself.
abstract final class Layers {
  /// Builds a filled and/or stroked rectangle.
  ///
  /// [gradient] — a Flutter `LinearGradient`/`RadialGradient`/
  /// `SweepGradient` — paints over [color] when given.
  ///
  /// [strokeCap]/[strokeJoin]/[strokeMiterLimit] shape a stroke's open ends
  /// and corners exactly like `dart:ui`'s own [Paint] fields of the same
  /// name; there's no `dashArray` here since a rectangle has no path
  /// geometry of its own to dash (see [path]).
  ///
  /// [clipBehavior] set to anything but [Clip.none] clips this layer's own
  /// paint to its [size] box — the rectangle's fill/stroke already stay
  /// within [size], so this mainly matters once [cornerRadius] or a
  /// gradient/stroke could otherwise bleed past a rotated/scaled edge.
  ///
  /// [scale] and [alignment] extend [rotation]: [scale] grows/shrinks the
  /// layer in place, and [alignment] moves the pivot [rotation]/[scale] turn
  /// around away from the box's center (the default).
  ///
  /// [pixelRatio] scales [size], [position], [cornerRadius] and
  /// [strokeWidth] together — pass the value a [LayerCanvas.sceneBuilder]
  /// received so layers built in logical units land at physical-pixel
  /// resolution without scaling each measurement by hand.
  static RectangleLayer rectangle({
    required Size size,
    Offset position = Offset.zero,
    Color color = const Color(0xFF000000),
    Gradient? gradient,
    PaintingStyle? style,
    double strokeWidth = 1.0,
    StrokeCap strokeCap = StrokeCap.butt,
    StrokeJoin strokeJoin = StrokeJoin.miter,
    double strokeMiterLimit = 4.0,
    bool fillAndStroke = false,
    double cornerRadius = 0,
    Clip clipBehavior = Clip.none,
    double rotation = 0,
    double scale = 1.0,
    AlignmentGeometry alignment = Alignment.center,
    double opacity = 1,
    double pixelRatio = 1.0,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return RectangleLayer(
      id: id,
      size: (size * pixelRatio).toSize2D(),
      paint: _paintFrom(
        color: color,
        gradient: gradient,
        style: style,
        strokeWidth: strokeWidth * pixelRatio,
        strokeCap: strokeCap,
        strokeJoin: strokeJoin,
        miterLimit: strokeMiterLimit,
        fillAndStroke: fillAndStroke,
      ),
      cornerRadius: cornerRadius * pixelRatio,
      clipToBounds: clipBehavior != Clip.none,
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
        scale: Point2D(scale, scale),
        anchor: alignment.toFractionalPoint2D(),
      ),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  /// Builds a filled and/or stroked vector shape from a [LayerPathBuilder]
  /// — see its doc comment for how to draw one (it mirrors `dart:ui`'s
  /// `Path`). [gradient] paints over [color] when given.
  ///
  /// [strokeCap]/[strokeJoin]/[strokeMiterLimit] shape a stroke's open ends
  /// and corners exactly like `dart:ui`'s own [Paint] fields of the same
  /// name. [dashArray] (alternating on/off lengths, e.g. `[4, 2]`) and
  /// [dashOffset] divide the stroke into dashes instead of a solid line —
  /// an odd-length [dashArray] repeats, matching SVG/CSS (`[4]` behaves like
  /// `[4, 4]`); both are ignored when [dashArray] is empty (the default).
  ///
  /// [clipBehavior] set to anything but [Clip.none] clips this layer's own
  /// paint to its [size] box (required for clipping to apply) — [size]
  /// otherwise still never scales the drawn geometry, as with the core's
  /// own `PathLayer`; it only places the [rotation]/[scale] pivot when that
  /// needs to turn around the shape's visual center rather than its local
  /// origin.
  ///
  /// [scale] and [alignment] extend [rotation] — see [rectangle] for how.
  ///
  /// [pixelRatio] scales [path]'s own coordinates (via
  /// [LayerPathBuilder.build]) along with [position], [size], [strokeWidth]
  /// and [dashArray]/[dashOffset] — see [rectangle] for why.
  static PathLayer path({
    required LayerPathBuilder path,
    Offset position = Offset.zero,
    Size? size,
    Color color = const Color(0xFF000000),
    Gradient? gradient,
    PaintingStyle? style,
    double strokeWidth = 1.0,
    StrokeCap strokeCap = StrokeCap.butt,
    StrokeJoin strokeJoin = StrokeJoin.miter,
    double strokeMiterLimit = 4.0,
    List<double> dashArray = const [],
    double dashOffset = 0,
    bool fillAndStroke = false,
    PathFillType fillType = PathFillType.nonZero,
    Clip clipBehavior = Clip.none,
    double rotation = 0,
    double scale = 1.0,
    AlignmentGeometry alignment = Alignment.center,
    double opacity = 1,
    double pixelRatio = 1.0,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return PathLayer(
      id: id,
      path: path.build(scale: pixelRatio),
      paint: _paintFrom(
        color: color,
        gradient: gradient,
        style: style,
        strokeWidth: strokeWidth * pixelRatio,
        strokeCap: strokeCap,
        strokeJoin: strokeJoin,
        miterLimit: strokeMiterLimit,
        dashArray: [for (final length in dashArray) length * pixelRatio],
        dashOffset: dashOffset * pixelRatio,
        fillAndStroke: fillAndStroke,
      ),
      fillRule: fillType.toFillRule(),
      clipToBounds: clipBehavior != Clip.none,
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
        scale: Point2D(scale, scale),
        anchor: alignment.toFractionalPoint2D(),
      ),
      size: size == null ? null : (size * pixelRatio).toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  /// Builds a run of styled text.
  ///
  /// Text always breaks on an explicit `\n`; passing a [size] with a width
  /// additionally word-wraps to fit it — greedily, only at spaces (a single
  /// word wider than [size]'s width overflows on its own line rather than
  /// being split mid-word) — and the wrapped block is vertically centered
  /// within [size]'s height.
  ///
  /// [clipBehavior] set to anything but [Clip.none] clips overflowing text
  /// to [size] (required for clipping to apply) instead of letting it
  /// overflow past the box.
  ///
  /// [scale] and [alignment] extend [rotation] — see [rectangle] for how.
  ///
  /// [pixelRatio] scales [size], [position] and [fontSize] together — see
  /// [rectangle] for why.
  static TextLayer text({
    required String text,
    Offset position = Offset.zero,
    Size? size,
    Color color = const Color(0xFF000000),
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    TextAlign align = TextAlign.left,
    String? fontFamily,
    Clip clipBehavior = Clip.none,
    double rotation = 0,
    double scale = 1.0,
    AlignmentGeometry alignment = Alignment.center,
    double opacity = 1,
    double pixelRatio = 1.0,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return TextLayer(
      id: id,
      text: text,
      fontFamily: fontFamily ?? LayerCanvasFonts.defaultFamily,
      fontSize: fontSize * pixelRatio,
      color: color.toColor32(),
      align: align.toTextAlignment(),
      fontWeight: fontWeight.toTextWeight(),
      clipToBounds: clipBehavior != Clip.none,
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
        scale: Point2D(scale, scale),
        anchor: alignment.toFractionalPoint2D(),
      ),
      size: size == null ? null : (size * pixelRatio).toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  /// Builds an image layer.
  ///
  /// [clipBehavior] set to anything but [Clip.none] clips this layer's own
  /// paint to its [size] box (required for clipping to apply) — the natural
  /// case is `fit: BoxFit.cover` together with `clipBehavior:
  /// Clip.hardEdge`, so the overflow a cover fit produces is cropped away
  /// exactly like an `Image` inside a clipped box.
  ///
  /// [scale] and [alignment] extend [rotation] — see [rectangle] for how.
  ///
  /// [pixelRatio] scales [size] and [position] together — see [rectangle]
  /// for why.
  static ImageLayer image({
    required LayerImageSource source,
    Offset position = Offset.zero,
    Size? size,
    BoxFit fit = BoxFit.contain,
    Clip clipBehavior = Clip.none,
    double rotation = 0,
    double scale = 1.0,
    AlignmentGeometry alignment = Alignment.center,
    double opacity = 1,
    double pixelRatio = 1.0,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return ImageLayer(
      id: id,
      source: source,
      fit: fit.toImageFit(),
      clipToBounds: clipBehavior != Clip.none,
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
        scale: Point2D(scale, scale),
        anchor: alignment.toFractionalPoint2D(),
      ),
      size: size == null ? null : (size * pixelRatio).toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  /// Places an already-[SvgDocument.parse]d SVG document as a group.
  ///
  /// Takes a parsed [SvgDocument] rather than raw SVG text on purpose —
  /// parsing is real XML work, and the same document is often placed more
  /// than once (or re-placed every `sceneBuilder` call); parse it once
  /// (e.g. into a `final` field) and pass the result here each time,
  /// instead of parsing it again per layer/frame.
  ///
  /// No `clipBehavior` here: like [group], this places a [Group], and the
  /// core expands groups into their concrete descendants before rendering,
  /// leaving no single composited surface to clip.
  ///
  /// [scale] and [alignment] extend [rotation] — see [rectangle] for how.
  ///
  /// [pixelRatio] scales [position] and [size] — see [rectangle] for why.
  static Group svg(
    SvgDocument document, {
    Offset position = Offset.zero,
    Size? size,
    double rotation = 0,
    double scale = 1.0,
    AlignmentGeometry alignment = Alignment.center,
    double opacity = 1,
    double pixelRatio = 1.0,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return document.toGroup(
      id: id,
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
        scale: Point2D(scale, scale),
        anchor: alignment.toFractionalPoint2D(),
      ),
      size: size == null ? null : (size * pixelRatio).toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  /// Groups [children] under a shared transform/opacity.
  ///
  /// No `clipBehavior` here — the core expands a [Group] into its concrete
  /// descendants before rendering, leaving no single composited surface to
  /// clip; clip an individual child via its own factory instead.
  ///
  /// [scale] and [alignment] extend [rotation] — see [rectangle] for how.
  /// Prefer scaling each child individually (via its own factory's
  /// `pixelRatio`) over relying on this [scale] for resolution changes,
  /// since a group's transform composes geometrically and does not
  /// re-rasterize its children at a different resolution.
  ///
  /// [pixelRatio] scales [position] — see [rectangle] for why.
  static Group group({
    required List<Layer> children,
    Offset position = Offset.zero,
    double rotation = 0,
    double scale = 1.0,
    AlignmentGeometry alignment = Alignment.center,
    double opacity = 1,
    double pixelRatio = 1.0,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return Group(
      id: id,
      children: children,
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
        scale: Point2D(scale, scale),
        anchor: alignment.toFractionalPoint2D(),
      ),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }
}

/// [PaintingStyle] has no `fillAndStroke` counterpart, so [fillAndStroke]
/// `true` requests [LayerPaintStyle.fillAndStroke] explicitly regardless of
/// [style]. [gradient], when given, paints over [color] — same rule as the
/// core's own `LayerPaint.gradient`.
LayerPaint _paintFrom({
  required Color color,
  required PaintingStyle? style,
  required double strokeWidth,
  required bool fillAndStroke,
  Gradient? gradient,
  StrokeCap strokeCap = StrokeCap.butt,
  StrokeJoin strokeJoin = StrokeJoin.miter,
  double miterLimit = 4.0,
  List<double> dashArray = const [],
  double dashOffset = 0.0,
}) {
  return LayerPaint(
    color: color.toColor32(),
    gradient: gradient?.toLayerGradient(),
    style: fillAndStroke
        ? LayerPaintStyle.fillAndStroke
        : switch (style) {
            PaintingStyle.stroke => LayerPaintStyle.stroke,
            PaintingStyle.fill || null => LayerPaintStyle.fill,
          },
    strokeWidth: strokeWidth,
    strokeCap: strokeCap.toLayerStrokeCap(),
    strokeJoin: strokeJoin.toLayerStrokeJoin(),
    miterLimit: miterLimit,
    dashArray: dashArray,
    dashOffset: dashOffset,
  );
}
