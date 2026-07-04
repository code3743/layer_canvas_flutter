import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

/// Converts a Flutter [Color] to the core's [Color32].
extension FlutterColorX on Color {
  Color32 toColor32() => Color32(toARGB32());
}

/// Converts a core [Color32] to a Flutter [Color].
extension Color32FlutterX on Color32 {
  Color toColor() => Color(value);
}
