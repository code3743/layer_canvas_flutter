import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

import '../adapters/geometry_adapter.dart';
import '../rendering/isolate_render.dart';
import '../scenes/scene_asset_resolver.dart';

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
///
/// Before rendering, any `AssetImageSource` reachable from the scene is
/// resolved against `DefaultAssetBundle.of(context)` (see
/// `resolveSceneAssetSources`) — a scene built entirely from
/// `FileImageSource`/`MemoryImageSource` skips this step untouched. The
/// actual native render then runs on a background isolate (see
/// `renderOffMainIsolate`), so a large scene rasterizing never blocks this
/// app's UI isolate.
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
    this.onLayerTap,
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
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )?
  errorBuilder;

  /// Called with the topmost [Layer] under a tap, found via the core's
  /// `hitTestScene` — a bounding-box test against each layer's own `size`
  /// (respecting its `transform`), not its exact painted shape, and never
  /// matching a layer with no explicit `size` (see `hitTestScene`'s own doc
  /// comment for the precise contract). `null` if the tap didn't land on
  /// any layer.
  ///
  /// Setting this installs a [GestureDetector] around the rendered image;
  /// leaving it `null` (the default) leaves taps to pass through untouched,
  /// same as before this existed. Coordinates are mapped through [fit] (via
  /// `applyBoxFit`), so this is correct whether the widget's box matches the
  /// scene's own aspect ratio or not.
  final void Function(Layer? layer, Offset localPosition)? onLayerTap;

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
        final scene =
            widget.scene ?? widget.sceneBuilder!(logicalSize, pixelRatio);

        // Cache key: scene identity + measured size + pixel ratio +
        // rebuildKey. A resize or a new scene produces a new future, which
        // FutureBuilder swaps to and any in-flight result for the old future
        // is discarded.
        final cacheKey = (scene, logicalSize, pixelRatio, widget.rebuildKey);
        if (_cacheKey != cacheKey) {
          _cacheKey = cacheKey;
          final bundle = DefaultAssetBundle.of(context);
          _future = resolveSceneAssetSources(scene, bundle).then(
            (resolved) => renderOffMainIsolate(widget.renderer, resolved),
          );
        }

        Widget content = SizedBox(
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

        final onLayerTap = widget.onLayerTap;
        if (onLayerTap != null) {
          content = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => onLayerTap(
              _hitTest(scene, logicalSize, details.localPosition),
              details.localPosition,
            ),
            child: content,
          );
        }

        return content;
      },
    );
  }

  /// Maps [localPosition] (in the widget's own logical-pixel box) through
  /// [widget.fit] into [scene]'s own coordinate space, the same mapping
  /// `Image`'s `fit` itself uses to place the rendered PNG — so this stays
  /// correct whether [logicalSize] matches the scene's aspect ratio or not
  /// (e.g. a fixed `scene:` shown in a box shaped differently than it).
  Layer? _hitTest(Scene scene, Size logicalSize, Offset localPosition) {
    final sceneSize = Size(scene.width.toDouble(), scene.height.toDouble());
    final destinationSize = applyBoxFit(
      widget.fit,
      sceneSize,
      logicalSize,
    ).destination;
    final origin = Offset(
      (logicalSize.width - destinationSize.width) / 2,
      (logicalSize.height - destinationSize.height) / 2,
    );
    final withinImage = localPosition - origin;
    if (withinImage.dx < 0 ||
        withinImage.dy < 0 ||
        withinImage.dx > destinationSize.width ||
        withinImage.dy > destinationSize.height) {
      return null; // Tapped in the fit's letterbox padding, not the image.
    }

    final scenePoint = Offset(
      withinImage.dx / destinationSize.width * sceneSize.width,
      withinImage.dy / destinationSize.height * sceneSize.height,
    );
    return hitTestScene(scene, scenePoint.toPoint2D());
  }
}
