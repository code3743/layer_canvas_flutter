import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

/// Converts a Flutter [Offset] to the core's [Point2D].
extension OffsetX on Offset {
  Point2D toPoint2D() => Point2D(dx, dy);
}

/// Converts a core [Point2D] to a Flutter [Offset].
extension Point2DX on Point2D {
  Offset toOffset() => Offset(x, y);
}

/// Converts a Flutter [Size] to the core's [Size2D].
extension SizeX on Size {
  Size2D toSize2D() => Size2D(width, height);
}

/// Converts a core [Size2D] to a Flutter [Size].
extension Size2DX on Size2D {
  Size toSize() => Size(width, height);
}
