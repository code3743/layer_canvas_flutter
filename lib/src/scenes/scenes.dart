import 'package:flutter/services.dart';
import 'package:layer_canvas/layer_canvas.dart';

import '../rendering/isolate_render.dart';
import 'scene_asset_resolver.dart';

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

  /// Rasterizes [scene] to encoded image bytes, [format] (`png` by default,
  /// or `bmp`/`qoi`) instead of the PNG [LayerCanvas] always shows on
  /// screen — for exporting a scene rather than displaying it. Resolves any
  /// `AssetImageSource` in [scene] against [bundle] (or `rootBundle`) first,
  /// same as every widget in this package, before delegating to [renderer].
  static Future<Uint8List> encode(
    Scene scene, {
    OutputFormat format = OutputFormat.png,
    Renderer renderer = const Renderer(),
    AssetBundle? bundle,
  }) async {
    final resolved = await resolveSceneAssetSources(
      scene,
      bundle ?? rootBundle,
    );
    return renderOffMainIsolate(renderer, resolved, format: format);
  }

  /// Rasterizes [scene] and writes it to [path] — see [encode] for
  /// [format]/[bundle]; use this instead of [encode] to write straight to
  /// disk rather than holding the encoded bytes in memory.
  static Future<void> saveToFile(
    Scene scene,
    String path, {
    OutputFormat format = OutputFormat.png,
    Renderer renderer = const Renderer(),
    AssetBundle? bundle,
  }) async {
    final resolved = await resolveSceneAssetSources(
      scene,
      bundle ?? rootBundle,
    );
    await renderToFileOffMainIsolate(renderer, resolved, path, format: format);
  }
}
