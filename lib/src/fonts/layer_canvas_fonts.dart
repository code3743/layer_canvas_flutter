import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:layer_canvas/layer_canvas.dart';

/// Loads fonts declared in a Flutter app's `pubspec.yaml` into the
/// `layer_canvas` native [FontRegistry], so text renders correctly without
/// relying on the core's embedded default font
/// (`hooks.user_defines.layer_canvas.embed_default_font`, which only the
/// final app's `pubspec.yaml` can turn off).
abstract final class LayerCanvasFonts {
  /// Family used by `FLayer.text` when no `fontFamily` is given.
  ///
  /// Set via [ensureInitialized]'s `asDefault` parameter, or directly.
  static String? defaultFamily;

  /// Reads `FontManifest.json` from [bundle] (or [rootBundle]) and registers
  /// families declared in the app's `pubspec.yaml` `flutter: fonts:` section
  /// with [FontRegistry].
  ///
  /// `FontManifest.json` isn't scoped to this app's own fonts — it also
  /// lists every font any dependency ships (e.g. an icon-font package), so
  /// by default this loads and registers **all of them**, which wastes
  /// memory and FFI calls on fonts `layer_canvas` will never draw. Pass
  /// [families] to register only the family names this app actually uses
  /// with `FLayer.text`/`TextLayer` — recommended whenever any dependency
  /// bundles its own fonts. Family names for a package's own fonts are
  /// prefixed `packages/<package>/` in the manifest, matching exactly what
  /// `fontFamily` on a package-provided `TextStyle` would use.
  ///
  /// **Limitation:** [FontRegistry] stores a single face per family name —
  /// the native backend only ever picks bold/regular among *embedded* faces.
  /// For a family with multiple weights, only its first declared face (the
  /// "normal"/first entry) is registered under the family name; real
  /// multi-weight support requires core changes.
  ///
  /// Pass [asDefault] to also set [defaultFamily] to that family name.
  static Future<void> ensureInitialized({
    AssetBundle? bundle,
    String? asDefault,
    Set<String>? families,
  }) async {
    final resolvedBundle = bundle ?? rootBundle;
    final manifestJson = await resolvedBundle.loadString('FontManifest.json');
    final manifest = jsonDecode(manifestJson) as List<dynamic>;

    for (final entry in manifest) {
      final map = entry as Map<String, dynamic>;
      final family = map['family'] as String;
      if (families != null && !families.contains(family)) continue;

      final fonts = (map['fonts'] as List<dynamic>).cast<Map<String, dynamic>>();
      if (fonts.isEmpty) continue;

      final asset = fonts.first['asset'] as String;
      final data = await resolvedBundle.load(asset);
      FontRegistry.register(family, _bytesOf(data));
    }

    if (asDefault != null) {
      defaultFamily = asDefault;
    }
  }

  /// Registers a single font [assetPath] under [family] explicitly, without
  /// scanning `FontManifest.json`.
  static Future<void> registerAsset(
    String family,
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final data = await (bundle ?? rootBundle).load(assetPath);
    FontRegistry.register(family, _bytesOf(data));
  }
}

Uint8List _bytesOf(ByteData data) =>
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
