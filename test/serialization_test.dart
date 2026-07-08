import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// `ImageFit`/`Point2D`/`Size2D` are core value types the public barrel
// intentionally doesn't re-export (see layer_canvas_flutter.dart) — tests
// legitimately need them to assert on a resolved/decoded Layer's raw
// fields. Every symbol below also exists in the barrel and refers to the
// exact same declaration, so importing both isn't ambiguous.
import 'package:layer_canvas/layer_canvas.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';
import 'package:layer_canvas_flutter/src/scenes/scene_asset_resolver.dart';

/// A fake [AssetBundle] that hands back the same fixed bytes for every key,
/// recording which keys were asked for — enough to exercise
/// `resolveSceneAssetSources` without needing a real decodable image, since
/// the resolver only swaps `LayerImageSource` types and never decodes them
/// itself (decoding happens natively, inside `Renderer.render`).
class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this.bytes);

  final Uint8List bytes;
  final List<String> loadedKeys = [];

  @override
  Future<ByteData> load(String key) async {
    loadedKeys.add(key);
    return ByteData.sublistView(bytes);
  }
}

void main() {
  group('Scene JSON round trip', () {
    test('round-trips width/height/background/layers', () {
      final scene =
          Scene(
            width: 200,
            height: 100,
            background: MemoryImageSource(Uint8List.fromList([1, 2, 3])),
          )..addAll([
            Layers.rectangle(
              size: const Size(50, 50),
              color: const Color(0xFFFF0000),
            ),
            Layers.text(text: 'hello', fontWeight: FontWeight.w600),
            Layers.group(
              children: [Layers.rectangle(size: const Size(10, 10))],
            ),
          ]);

      final decoded = Scene.fromJson(
        jsonDecode(jsonEncode(scene.toJson())) as Map<String, Object?>,
      );

      expect(decoded.width, 200);
      expect(decoded.height, 100);
      expect(decoded.background, isA<MemoryImageSource>());
      expect(decoded.layers, hasLength(3));
      expect(decoded.layers[0], isA<RectangleLayer>());
      expect(decoded.layers[1], isA<TextLayer>());
      expect(decoded.layers[2], isA<Group>());
    });
  });

  group('resolveSceneAssetSources', () {
    test(
      'returns the same Scene instance when no AssetImageSource exists',
      () async {
        final scene = Scene(width: 10, height: 10)
          ..add(
            Layers.image(
              source: MemoryImageSource(Uint8List.fromList([1])),
              size: const Size(10, 10),
            ),
          );
        final bundle = _FakeAssetBundle(Uint8List.fromList([9, 9, 9]));

        final resolved = await resolveSceneAssetSources(scene, bundle);

        expect(identical(resolved, scene), isTrue);
        expect(bundle.loadedKeys, isEmpty);
      },
    );

    test(
      'resolves an AssetImageSource background into MemoryImageSource',
      () async {
        final scene = Scene(
          width: 10,
          height: 10,
          background: AssetImageSource('images/bg.png'),
        );
        final bundle = _FakeAssetBundle(Uint8List.fromList([1, 2, 3]));

        final resolved = await resolveSceneAssetSources(scene, bundle);

        expect(resolved.background, isA<MemoryImageSource>());
        expect((resolved.background as MemoryImageSource).bytes, [1, 2, 3]);
        expect(bundle.loadedKeys, ['images/bg.png']);
      },
    );

    test(
      'resolves an AssetImageSource on an ImageLayer, preserving fields',
      () async {
        final scene = Scene(width: 10, height: 10)
          ..add(
            Layers.image(
              source: AssetImageSource('images/logo.png'),
              size: const Size(10, 10),
              fit: BoxFit.cover,
              position: const Offset(1, 2),
            ),
          );
        final bundle = _FakeAssetBundle(Uint8List.fromList([4, 5, 6]));

        final resolved = await resolveSceneAssetSources(scene, bundle);

        final layer = resolved.layers.single as ImageLayer;
        expect(layer.source, isA<MemoryImageSource>());
        expect(layer.fit, ImageFit.cover);
        expect(layer.transform.position, const Point2D(1, 2));
        expect(layer.size, const Size2D(10, 10));
      },
    );

    test('recurses into Group children', () async {
      final scene = Scene(width: 10, height: 10)
        ..add(
          Layers.group(
            children: [
              Layers.image(
                source: AssetImageSource('images/nested.png'),
                size: const Size(5, 5),
              ),
              Layers.rectangle(size: const Size(5, 5)),
            ],
          ),
        );
      final bundle = _FakeAssetBundle(Uint8List.fromList([7]));

      final resolved = await resolveSceneAssetSources(scene, bundle);

      final group = resolved.layers.single as Group;
      final nested = group.children[0] as ImageLayer;
      expect(nested.source, isA<MemoryImageSource>());
      expect(group.children[1], isA<RectangleLayer>());
      expect(bundle.loadedKeys, ['images/nested.png']);
    });

    test('uses the packages/<package>/ prefix for a package asset', () async {
      final scene = Scene(width: 10, height: 10)
        ..add(
          Layers.image(
            source: AssetImageSource('images/logo.png', package: 'brand_kit'),
            size: const Size(10, 10),
          ),
        );
      final bundle = _FakeAssetBundle(Uint8List.fromList([1]));

      await resolveSceneAssetSources(scene, bundle);

      expect(bundle.loadedKeys, ['packages/brand_kit/images/logo.png']);
    });
  });
}
