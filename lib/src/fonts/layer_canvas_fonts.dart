import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:layer_canvas/layer_canvas.dart';

import '../adapters/text_adapter.dart';

/// Loads fonts declared in a Flutter app's `pubspec.yaml` into the
/// `layer_canvas` native [FontRegistry], so text renders correctly without
/// relying on the core's embedded default font
/// (`hooks.user_defines.layer_canvas.embed_default_font`, which only the
/// final app's `pubspec.yaml` can turn off).
abstract final class LayerCanvasFonts {
  /// Family used by `Layers.text` when no `fontFamily` is given.
  ///
  /// Set via [ensureInitialized]'s `asDefault` parameter, or directly.
  static String? defaultFamily;

  /// Reads `FontManifest.json` from [bundle] (or [rootBundle]) and registers
  /// families declared in the app's `pubspec.yaml` `flutter: fonts:` section
  /// with [FontRegistry] — every declared weight of a family, not just its
  /// first face, since `FontRegistry.register` takes a `weight` (added in
  /// `layer_canvas` 0.1.0-beta.3): a `TextLayer` with that `fontFamily` then
  /// renders with whichever registered weight is closest to its own
  /// `fontWeight`, the same as declaring several weights under one
  /// `family:` in `pubspec.yaml`'s own `flutter: fonts:` section.
  ///
  /// Italic faces are skipped — [FontRegistry] has no italic/upright
  /// concept, so registering one under its family would silently make that
  /// weight always render upright instead of failing loudly, which is
  /// worse than just not registering it.
  ///
  /// `FontManifest.json` isn't scoped to this app's own fonts — it also
  /// lists every font any dependency ships (e.g. an icon-font package), so
  /// by default this loads and registers **all of them**, which wastes
  /// memory and FFI calls on fonts `layer_canvas` will never draw. Pass
  /// [families] to register only the family names this app actually uses
  /// with `Layers.text`/`TextLayer` — recommended whenever any dependency
  /// bundles its own fonts. Family names for a package's own fonts are
  /// prefixed `packages/<package>/` in the manifest, matching exactly what
  /// `fontFamily` on a package-provided `TextStyle` would use.
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

      final fonts = (map['fonts'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final font in fonts) {
        final style = font['style'] as String? ?? 'normal';
        if (style == 'italic') continue;

        final asset = font['asset'] as String;
        final data = await resolvedBundle.load(asset);
        FontRegistry.register(
          family,
          _bytesOf(data),
          weight: _weightFromManifestValue(font['weight'] as int?),
        );
      }
    }

    if (asDefault != null) {
      defaultFamily = asDefault;
    }
  }

  /// Registers a single font [assetPath] under [family] and [weight],
  /// without scanning `FontManifest.json`.
  static Future<void> registerAsset(
    String family,
    String assetPath, {
    AssetBundle? bundle,
    TextWeight weight = TextWeight.normal,
  }) async {
    final data = await (bundle ?? rootBundle).load(assetPath);
    FontRegistry.register(family, _bytesOf(data), weight: weight);
  }
}

/// `FontManifest.json` weights are raw 100-900 integers (Flutter's own
/// `FontWeight.value` range) — routed through [FontWeightX] rather than
/// duplicating its nearest-match logic.
TextWeight _weightFromManifestValue(int? manifestWeight) {
  final raw = manifestWeight ?? 400;
  final index = ((raw / 100).round() - 1).clamp(
    0,
    FontWeight.values.length - 1,
  );
  return FontWeight.values[index].toTextWeight();
}

Uint8List _bytesOf(ByteData data) =>
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
