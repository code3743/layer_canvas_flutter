import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(devicePixelRatio: 1.0),
      child: Center(
        child: SizedBox(width: 100, height: 100, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('renders an Image once the scene finishes rendering',
      (tester) async {
    final scene = Scene(width: 100, height: 100)
      ..add(Layers.rectangle(
        size: const Size(100, 100),
        color: const Color(0xFFFF0000),
      ));

    await tester.pumpWidget(_wrap(LayerCanvas(scene: scene)));

    // Renderer.render is async; nothing decoded yet on the first frame.
    expect(find.byType(Image), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('sceneBuilder receives the measured logical size and DPR',
      (tester) async {
    Size? seenSize;
    double? seenPixelRatio;

    await tester.pumpWidget(_wrap(LayerCanvas(
      sceneBuilder: (logicalSize, pixelRatio) {
        seenSize = logicalSize;
        seenPixelRatio = pixelRatio;
        return Scene(width: 100, height: 100)
          ..add(Layers.rectangle(size: const Size(100, 100)));
      },
    )));

    expect(seenSize, const Size(100, 100));
    expect(seenPixelRatio, 1.0);

    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });
}
