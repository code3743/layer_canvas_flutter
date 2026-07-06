import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

import '../scenes/scenes.dart';
import 'layer_canvas_widget.dart';

/// Renders a fixed-size `layer_canvas` scene built from a flat list of
/// [children] — shaped like a Flutter layout widget (`Stack(children: [...])`)
/// instead of `Scene(...)..add(...)..add(...)` plus a separate [LayerCanvas].
///
/// **Rebuilds its [Scene] on every `build()`**, unlike [LayerCanvas] with a
/// fixed `scene:`, which only re-renders when the [Scene] *instance* it's
/// given changes. There is no cheap way to detect "same content, new list"
/// here — `layer_canvas`'s [Layer] types have no value equality to compare
/// against — so every rebuild is treated as new content. This is fine for
/// content that changes rarely (a decorative graphic, a badge...); if this
/// widget sits somewhere that rebuilds often (an animation, frequent
/// `setState`), each rebuild triggers a fresh native re-render. For that
/// case, build a [Scene] once (e.g. with [Scenes.of]) and pass it to
/// [LayerCanvas] directly instead, so re-renders are driven by *your*
/// decision to build a new [Scene], not by every rebuild.
///
/// [width]/[height] stay explicit, in whatever unit space [children] were
/// built in (see [Layers]' `pixelRatio` parameter) — same reasoning as
/// [Scenes.of].
class SceneWidget extends StatelessWidget {
  const SceneWidget({
    super.key,
    required this.width,
    required this.height,
    this.children = const [],
    this.background,
    this.renderer = const Renderer(),
    this.fit = BoxFit.contain,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  /// The rendered canvas width, in the same unit space as [children].
  final double width;

  /// The rendered canvas height, in the same unit space as [children].
  final double height;

  /// The scene's layers — actual compositing order is controlled by each
  /// layer's `zIndex`, not this list's order (matching `Scene.layers`).
  final List<Layer> children;

  /// Painted first, before any [children]. `null` means a transparent canvas.
  final LayerImageSource? background;

  /// The renderer used to rasterize the scene.
  final Renderer renderer;

  /// How the rendered PNG is fit into the widget's box.
  final BoxFit fit;

  /// Shown while the scene is rendering. Defaults to an empty box.
  final WidgetBuilder? placeholderBuilder;

  /// Shown if rendering throws (e.g. a [RenderException]).
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )?
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    return LayerCanvas(
      scene: Scenes.of(
        width: width,
        height: height,
        background: background,
        children: children,
      ),
      renderer: renderer,
      fit: fit,
      placeholderBuilder: placeholderBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
