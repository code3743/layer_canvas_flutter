import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

import '../adapters/color_adapter.dart';
import '../adapters/geometry_adapter.dart';
import '../adapters/image_adapter.dart';
import '../adapters/text_adapter.dart';
import '../fonts/layer_canvas_fonts.dart';

/// Factories that build `layer_canvas` [Layer]s from Flutter types
/// (`Color`, `Offset`, `Size`, `FontWeight`, `TextAlign`, `BoxFit`…), so
/// callers never have to touch `Color32`/`Point2D`/`TextWeight` directly.
///
/// Dart has no extension constructors, so these are static factories on a
/// namespace class rather than constructors on the core layer types — the
/// same pattern as `Colors`/`Icons`/`Curves` in Flutter itself.
abstract final class Layers {
  static RectangleLayer rectangle({
    required Size size,
    Offset position = Offset.zero,
    Color color = const Color(0xFF000000),
    PaintingStyle? style,
    double strokeWidth = 1.0,
    bool fillAndStroke = false,
    double cornerRadius = 0,
    double rotation = 0,
    double opacity = 1,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return RectangleLayer(
      id: id,
      size: size.toSize2D(),
      paint: _paintFrom(
        color: color,
        style: style,
        strokeWidth: strokeWidth,
        fillAndStroke: fillAndStroke,
      ),
      cornerRadius: cornerRadius,
      transform: LayerTransform(position: position.toPoint2D(), rotation: rotation),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

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
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return TextLayer(
      id: id,
      text: text,
      fontFamily: fontFamily ?? LayerCanvasFonts.defaultFamily,
      fontSize: fontSize,
      color: color.toColor32(),
      align: align.toTextAlignment(),
      fontWeight: fontWeight.toTextWeight(),
      transform: LayerTransform(position: position.toPoint2D(), rotation: rotation),
      size: size?.toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  static ImageLayer image({
    required LayerImageSource source,
    Offset position = Offset.zero,
    Size? size,
    BoxFit fit = BoxFit.contain,
    double rotation = 0,
    double opacity = 1,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return ImageLayer(
      id: id,
      source: source,
      fit: fit.toImageFit(),
      transform: LayerTransform(position: position.toPoint2D(), rotation: rotation),
      size: size?.toSize2D(),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }

  static Group group({
    required List<Layer> children,
    Offset position = Offset.zero,
    double rotation = 0,
    double opacity = 1,
    String? id,
    int zIndex = 0,
    bool visible = true,
  }) {
    return Group(
      id: id,
      children: children,
      transform: LayerTransform(position: position.toPoint2D(), rotation: rotation),
      opacity: opacity,
      zIndex: zIndex,
      visible: visible,
    );
  }
}

/// [PaintingStyle] has no `fillAndStroke` counterpart, so [fillAndStroke]
/// `true` requests [LayerPaintStyle.fillAndStroke] explicitly regardless of
/// [style].
LayerPaint _paintFrom({
  required Color color,
  required PaintingStyle? style,
  required double strokeWidth,
  required bool fillAndStroke,
}) {
  return LayerPaint(
    color: color.toColor32(),
    style: fillAndStroke
        ? LayerPaintStyle.fillAndStroke
        : switch (style) {
            PaintingStyle.stroke => LayerPaintStyle.stroke,
            PaintingStyle.fill || null => LayerPaintStyle.fill,
          },
    strokeWidth: strokeWidth,
  );
}
