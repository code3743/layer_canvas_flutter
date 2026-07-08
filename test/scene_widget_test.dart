import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

import 'test_utils.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(devicePixelRatio: 1.0),
      child: Center(child: SizedBox(width: 100, height: 100, child: child)),
    ),
  );
}

void main() {
  testWidgets('renders an Image from its children, like a Stack', (
    tester,
  ) async {
    // See pumpUntilImageRenders's doc comment for why this needs runAsync.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _wrap(
          SceneWidget(
            width: 100,
            height: 100,
            children: [
              Layers.rectangle(size: const Size(100, 100)),
              Layers.text(text: 'hi'),
            ],
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      await pumpUntilImageRenders(tester);
    });
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets(
    're-renders on every rebuild, unlike a stable LayerCanvas scene',
    (tester) async {
      Widget build(Color color) => _wrap(
        SceneWidget(
          width: 100,
          height: 100,
          children: [
            Layers.rectangle(size: const Size(100, 100), color: color),
          ],
        ),
      );

      late Uint8List firstBytes;
      await tester.runAsync(() async {
        await tester.pumpWidget(build(const Color(0xFFFF0000)));
        await pumpUntilImageRenders(tester);
        firstBytes = renderedImageBytes(tester)!;
      });

      // A freshly-built Scene each build (no rebuildKey needed, unlike a
      // fixed LayerCanvas(scene:)) — changing just the color between builds
      // proves each build actually re-renders instead of reusing a cached
      // image, since a plain Scene has no value equality to cache against.
      await tester.runAsync(() async {
        await tester.pumpWidget(build(const Color(0xFF0000FF)));
        await pumpUntil(
          tester,
          () => !bytesEqual(renderedImageBytes(tester)!, firstBytes),
        );
      });
      expect(bytesEqual(renderedImageBytes(tester)!, firstBytes), isFalse);
    },
  );
}
