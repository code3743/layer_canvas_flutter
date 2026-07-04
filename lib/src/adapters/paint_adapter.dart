import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

import 'color_adapter.dart';

/// Builds a [LayerPaint] from Flutter painting types.
///
/// [PaintingStyle] has no `fillAndStroke` counterpart, so pass
/// [fillAndStroke] `true` to request [LayerPaintStyle.fillAndStroke]
/// explicitly regardless of [style].
abstract final class FPaint {
  static LayerPaint from({
    Color color = const Color(0xFF000000),
    PaintingStyle? style,
    double strokeWidth = 1.0,
    bool fillAndStroke = false,
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
}
