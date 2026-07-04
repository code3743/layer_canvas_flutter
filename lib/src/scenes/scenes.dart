import 'package:layer_canvas/layer_canvas.dart';

/// Builds a `layer_canvas` [Scene] with its layers passed as a list, instead
/// of the core's mutate-after-construction `Scene(...)..add(...)..add(...)`.
///
/// Dart has no extension constructors, so this is a static factory on a
/// namespace class — the same pattern as `Layers`.
///
/// `width`/`height` stay explicit, unlike a Flutter `Stack`: the native
/// backend rasterizes onto a fixed-size canvas, allocated before any layer
/// is drawn, so there is no content-driven auto-sizing pass to lean on (and
/// no honest way to add one from `layer_canvas_flutter` alone — an
/// auto-sized `TextLayer`'s natural bounds are resolved by native text
/// shaping, invisible on the Dart side). If the scene should fill whatever
/// box contains it, pass the `logicalSize`/`pixelRatio`
/// `LayerCanvas.sceneBuilder` already hands you.
abstract final class Scenes {
  static Scene of({
    required double width,
    required double height,
    LayerImageSource? background,
    List<Layer> children = const [],
  }) {
    return Scene(
      width: width.round(),
      height: height.round(),
      background: background,
    )..addAll(children);
  }
}
