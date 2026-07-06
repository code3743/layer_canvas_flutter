import 'package:flutter/widgets.dart';
// `Gradient` (and its Linear/Radial/Conic subtypes) hidden: this file's own
// factories take Flutter's own `Gradient` as a parameter type (see
// `rectangle`/`path` below) and convert it via `GradientX.toLayerGradient`
// — the core's same-named type is never referenced by name here, only
// produced by that adapter, so importing both unprefixed would be a real
// ambiguous-import error, not just a style nitpick.
import 'package:layer_canvas/layer_canvas.dart' hide Gradient, LinearGradient, RadialGradient;

import '../adapters/color_adapter.dart';
import '../adapters/geometry_adapter.dart';
import '../adapters/gradient_adapter.dart';
import '../adapters/image_adapter.dart';
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
    bool fillAndStroke = false,
    double cornerRadius = 0,
    double rotation = 0,
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
        fillAndStroke: fillAndStroke,
      ),
      cornerRadius: cornerRadius * pixelRatio,
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
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
  /// [pixelRatio] scales [path]'s own coordinates (via
  /// [LayerPathBuilder.build]) along with [position], [size] and
  /// [strokeWidth] — see [rectangle] for why. Unlike [rectangle], [size] is
  /// never used to scale or clip the drawn geometry — as with the core's
  /// own `PathLayer`, it only places the rotation/scale pivot when
  /// [rotation] (or a caller-managed scale) needs to pivot around the
  /// shape's visual center rather than its local origin.
  static PathLayer path({
    required LayerPathBuilder path,
    Offset position = Offset.zero,
    Size? size,
    Color color = const Color(0xFF000000),
    Gradient? gradient,
    PaintingStyle? style,
    double strokeWidth = 1.0,
    bool fillAndStroke = false,
    PathFillType fillType = PathFillType.nonZero,
    double rotation = 0,
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
        fillAndStroke: fillAndStroke,
      ),
      fillRule: fillType.toFillRule(),
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
      ),
      size: size == null ? null : (size * pixelRatio).toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  /// Builds a run of styled text.
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
    double rotation = 0,
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
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
      ),
      size: size == null ? null : (size * pixelRatio).toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  /// Builds an image layer.
  ///
  /// [pixelRatio] scales [size] and [position] together — see [rectangle]
  /// for why.
  static ImageLayer image({
    required LayerImageSource source,
    Offset position = Offset.zero,
    Size? size,
    BoxFit fit = BoxFit.contain,
    double rotation = 0,
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
      transform: LayerTransform(
        position: (position * pixelRatio).toPoint2D(),
        rotation: rotation,
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
  /// [pixelRatio] scales [position] and [size] — see [rectangle] for why.
  static Group svg(
    SvgDocument document, {
    Offset position = Offset.zero,
    Size? size,
    double rotation = 0,
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
      ),
      size: size == null ? null : (size * pixelRatio).toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  /// Groups [children] under a shared transform/opacity.
  ///
  /// [pixelRatio] scales [position] — scale each child individually (via its
  /// own factory's `pixelRatio`) rather than relying on this to also scale
  /// their sizes, since a group's transform composes geometrically and does
  /// not re-rasterize its children at a different resolution.
  static Group group({
    required List<Layer> children,
    Offset position = Offset.zero,
    double rotation = 0,
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
  );
}
