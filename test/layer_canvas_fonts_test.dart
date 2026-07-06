import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle({required this.manifestJson, required this.fontBytes});

  final String manifestJson;
  final Uint8List fontBytes;
  final List<String> loadedKeys = [];

  @override
  Future<ByteData> load(String key) async {
    loadedKeys.add(key);
    if (key == 'FontManifest.json') {
      return ByteData.sublistView(
        Uint8List.fromList(utf8.encode(manifestJson)),
      );
    }
    return ByteData.sublistView(fontBytes);
  }
}

void main() {
  test(
    'ensureInitialized only loads and registers allow-listed families',
    () async {
      final fontBytes = Uint8List.fromList(
        await File('test/fixtures/Roboto-Regular.ttf').readAsBytes(),
      );
      final bundle = _FakeAssetBundle(
        manifestJson: jsonEncode([
          {
            'family': 'Included',
            'fonts': [
              {'asset': 'fonts/Included.ttf'},
            ],
          },
          {
            'family': 'Excluded',
            'fonts': [
              {'asset': 'fonts/Excluded.ttf'},
            ],
          },
        ]),
        fontBytes: fontBytes,
      );

      await LayerCanvasFonts.ensureInitialized(
        bundle: bundle,
        families: {'Included'},
      );

      expect(bundle.loadedKeys, contains('fonts/Included.ttf'));
      expect(bundle.loadedKeys, isNot(contains('fonts/Excluded.ttf')));
    },
  );

  test(
    'ensureInitialized registers every weight of a family, skipping italics',
    () async {
      final fontBytes = Uint8List.fromList(
        await File('test/fixtures/Roboto-Regular.ttf').readAsBytes(),
      );
      final bundle = _FakeAssetBundle(
        manifestJson: jsonEncode([
          {
            'family': 'Brand',
            'fonts': [
              {'asset': 'fonts/Brand-Regular.ttf'},
              {'asset': 'fonts/Brand-Bold.ttf', 'weight': 700},
              {'asset': 'fonts/Brand-Italic.ttf', 'style': 'italic'},
            ],
          },
        ]),
        fontBytes: fontBytes,
      );

      // Doesn't throw: both non-italic weights register as distinct faces
      // under the same family, per FontRegistry's per-(name, weight) storage.
      await LayerCanvasFonts.ensureInitialized(bundle: bundle);

      expect(
        bundle.loadedKeys,
        containsAll(['fonts/Brand-Regular.ttf', 'fonts/Brand-Bold.ttf']),
      );
      expect(bundle.loadedKeys, isNot(contains('fonts/Brand-Italic.ttf')));
    },
  );
}
