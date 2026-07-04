import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

/// Builds a [Scene] sized to [logicalSize] (the widget's measured box, in
/// logical pixels) and [pixelRatio] (the device pixel ratio). Build the
/// scene at physical pixels — i.e. `logicalSize * pixelRatio` — so the
/// rendered PNG is crisp on high-DPI displays.
typedef SceneBuilder = Scene Function(Size logicalSize, double pixelRatio);

/// Renders a `layer_canvas` [Scene] as a Flutter widget.
///
/// Provide either a fixed [scene], or a [sceneBuilder] that receives the
/// widget's measured logical size and the device pixel ratio so it can
/// build the scene at physical-pixel resolution for a crisp result.
///
/// **Treat [Scene] as immutable.** Re-rendering is triggered by identity —
/// a *new* [Scene] instance (or [sceneBuilder] returning one) — not by
/// content. Calling `scene.add(...)`/`remove(...)`/`clear()` on a [Scene]
/// already passed to a live [LayerCanvas] does not refresh it, silently,
/// because the object identity the widget is keying off of hasn't changed.
/// Build a new [Scene] whenever its contents change; if you must mutate one
/// in place, pass a changing [rebuildKey] to force a re-render.
class LayerCanvas extends StatefulWidget {
  const LayerCanvas({
    super.key,
    this.scene,
    this.sceneBuilder,
    this.renderer = const Renderer(),
    this.pixelRatio,
    this.fit = BoxFit.contain,
    this.rebuildKey,
    this.placeholderBuilder,
    this.errorBuilder,
  }) : assert(
          (scene == null) != (sceneBuilder == null),
          'Provide exactly one of scene or sceneBuilder',
        );

  /// A fixed scene to render. Mutually exclusive with [sceneBuilder].
  final Scene? scene;

  /// Builds the scene from the widget's measured size and pixel ratio.
  /// Mutually exclusive with [scene].
  final SceneBuilder? sceneBuilder;

  /// The renderer used to rasterize the scene. Stateless, so the default
  /// instance is fine unless a custom [Renderer] is needed.
  final Renderer renderer;

  /// Overrides `MediaQuery.devicePixelRatioOf(context)` when set.
  final double? pixelRatio;

  /// How the rendered PNG is fit into the widget's box.
  final BoxFit fit;

  /// Forces a re-render when it changes, even if [scene]'s identity and the
  /// measured size/pixel ratio didn't — the escape hatch for callers that
  /// mutate a [Scene] in place instead of building a new one (e.g. bump an
  /// `int` counter on every mutation and pass it here).
  final Object? rebuildKey;

  /// Shown while the scene is rendering. Defaults to an empty box.
  final WidgetBuilder? placeholderBuilder;

  /// Shown if rendering throws (e.g. a [RenderException]).
  final Widget Function(BuildContext context, Object error, StackTrace stackTrace)?
      errorBuilder;

  @override
  State<LayerCanvas> createState() => _LayerCanvasState();
}

class _LayerCanvasState extends State<LayerCanvas> {
  Object? _cacheKey;
  Future<Uint8List>? _future;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalSize = constraints.biggest;
        final pixelRatio =
            widget.pixelRatio ?? MediaQuery.devicePixelRatioOf(context);
        final scene = widget.scene ?? widget.sceneBuilder!(logicalSize, pixelRatio);

        // Cache key: scene identity + measured size + pixel ratio +
        // rebuildKey. A resize or a new scene produces a new future, which
        // FutureBuilder swaps to and any in-flight result for the old future
        // is discarded.
        final cacheKey = (scene, logicalSize, pixelRatio, widget.rebuildKey);
        if (_cacheKey != cacheKey) {
          _cacheKey = cacheKey;
          _future = widget.renderer.render(scene);
        }

        return SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: FutureBuilder<Uint8List>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return widget.errorBuilder?.call(
                      context,
                      snapshot.error!,
                      snapshot.stackTrace ?? StackTrace.empty,
                    ) ??
                    const SizedBox.shrink();
              }
              final bytes = snapshot.data;
              if (bytes == null) {
                return widget.placeholderBuilder?.call(context) ??
                    const SizedBox.shrink();
              }
              return Image.memory(
                bytes,
                gaplessPlayback: true,
                fit: widget.fit,
                width: logicalSize.width,
                height: logicalSize.height,
              );
            },
          ),
        );
      },
    );
  }
}
