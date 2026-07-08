import 'package:flutter/services.dart';
import 'package:layer_canvas/layer_canvas.dart';

import '../adapters/asset_image_source.dart';

/// Resolves every [AssetImageSource] reachable from [scene] — its own
/// [Scene.background], any [ImageLayer.source], recursing into
/// [Group.children] — into a [MemoryImageSource] loaded from [bundle].
///
/// The native renderer only understands `file`/`memory` sources, and
/// loading an asset is inherently async, so this has to run before a
/// [Scene] reaches `Renderer.render`. Every widget/helper in this package
/// that renders or encodes a [Scene] runs it through this first.
///
/// Returns [scene] itself, unchanged, when it contains no
/// [AssetImageSource] — the common case for scenes built entirely from
/// [FileImageSource]/[MemoryImageSource] — so [LayerCanvas]'s render cache,
/// keyed on [Scene] identity, isn't defeated by a pointless rebuild.
Future<Scene> resolveSceneAssetSources(Scene scene, AssetBundle bundle) async {
  var changed = false;

  Future<LayerImageSource> resolveSource(LayerImageSource source) async {
    if (source is! AssetImageSource) return source;
    changed = true;
    final data = await bundle.load(source.bundleKey);
    return MemoryImageSource(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<Layer> resolveLayer(Layer layer) async {
    if (layer is ImageLayer) {
      return ImageLayer(
        id: layer.id,
        source: await resolveSource(layer.source),
        fit: layer.fit,
        transform: layer.transform,
        size: layer.size,
        opacity: layer.opacity,
        zIndex: layer.zIndex,
        visible: layer.visible,
        clipToBounds: layer.clipToBounds,
      );
    }
    if (layer is Group) {
      return Group(
        id: layer.id,
        children: await Future.wait(layer.children.map(resolveLayer)),
        transform: layer.transform,
        size: layer.size,
        opacity: layer.opacity,
        zIndex: layer.zIndex,
        visible: layer.visible,
      );
    }
    return layer;
  }

  final resolvedBackground = scene.background == null
      ? null
      : await resolveSource(scene.background!);
  final resolvedLayers = await Future.wait(scene.layers.map(resolveLayer));

  // Every ImageLayer/Group above gets rebuilt regardless of whether it (or
  // a descendant) actually held an AssetImageSource — cheap relative to the
  // render this scene is about to go through, and simpler than threading an
  // extra "did this subtree change" return value through the recursion.
  // `changed` is what decides whether that rebuilt tree is used at all.
  if (!changed) return scene;

  return Scene(
    width: scene.width,
    height: scene.height,
    background: resolvedBackground,
  )..addAll(resolvedLayers);
}
