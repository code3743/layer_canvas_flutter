import 'package:layer_canvas/layer_canvas.dart';

/// An image loaded from a Flutter asset bundle, by asset key.
///
/// Unlike [ImageSources.asset] (in `image_adapter.dart`), which loads the
/// asset's bytes immediately into a [MemoryImageSource], this is a *lazy*
/// descriptor: it stores [assetKey] (and [package]) rather than bytes, so
/// it's cheap to build ahead of time, compact to serialize via
/// [Scene.toJson] (a short string instead of a base64 blob), and portable
/// across app installs where the same asset key still resolves. It only
/// becomes bytes when a [LayerCanvas] actually renders it — see
/// `resolveSceneAssetSources` in `scene_asset_resolver.dart`, which every
/// widget in this package runs a scene through first, since the native
/// renderer itself only understands `file`/`memory` sources.
///
/// Registers its own [LayerRegistry] decoder (so `Scene.fromJson` can
/// reconstruct one) the first time one is built or deserialized — no setup
/// call needed.
class AssetImageSource extends LayerImageSource {
  /// The asset key, as declared in `pubspec.yaml`'s `flutter: assets:` (or
  /// `flutter: fonts:`-style) section — the same string `Image.asset` or
  /// `AssetBundle.load` would take, without a `packages/<package>/` prefix
  /// even when [package] is set (see [bundleKey]).
  final String assetKey;

  /// The package this asset ships from, when it isn't part of the app's own
  /// bundle — same meaning as `Image.asset`'s `package` argument.
  final String? package;

  /// Creates a source that lazily loads [assetKey] (optionally from
  /// [package]) when a scene containing it is rendered.
  AssetImageSource(this.assetKey, {this.package}) {
    _ensureRegistered();
  }

  /// The key to actually hand an [AssetBundle], with the `packages/<package>/`
  /// prefix `Image.asset`/`AssetImage` add for a package asset — applied
  /// unless [assetKey] already carries it.
  String get bundleKey {
    final pkg = package;
    if (pkg == null || assetKey.startsWith('packages/$pkg/')) {
      return assetKey;
    }
    return 'packages/$pkg/$assetKey';
  }

  @override
  String toString() =>
      'AssetImageSource($assetKey'
      '${package == null ? '' : ', package: $package'})';

  @override
  Map<String, Object?> toJson() => {
    'type': 'asset',
    'key': assetKey,
    if (package != null) 'package': package,
  };

  /// Reconstructs an [AssetImageSource] from [toJson]'s output.
  factory AssetImageSource.fromJson(Map<String, Object?> json) {
    return AssetImageSource(
      json['key'] as String,
      package: json['package'] as String?,
    );
  }

  static bool _registered = false;

  /// Registers [AssetImageSource]'s decoder with [LayerRegistry] exactly
  /// once, however many instances get built — so `Scene.fromJson` can
  /// reconstruct an `'asset'`-typed source without the caller having to
  /// remember a separate setup step.
  static void _ensureRegistered() {
    if (_registered) return;
    _registered = true;
    LayerRegistry.registerImageSource('asset', AssetImageSource.fromJson);
  }
}
