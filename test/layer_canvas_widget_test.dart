import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

class _CountingRenderer extends Renderer {
  int calls = 0;

  @override
  Future<Uint8List> render(Scene scene) {
    calls++;
    return super.render(scene);
  }
}

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

  testWidgets('rebuildKey forces a re-render for an in-place scene mutation',
      (tester) async {
    final renderer = _CountingRenderer();
    final scene = Scene(width: 100, height: 100)
      ..add(Layers.rectangle(size: const Size(100, 100)));

    Widget build(int rebuildKey) => _wrap(LayerCanvas(
          scene: scene,
          renderer: renderer,
          rebuildKey: rebuildKey,
        ));

    await tester.pumpWidget(build(0));
    await tester.pumpAndSettle();
    expect(renderer.calls, 1);

    // Mutate the same Scene instance in place: identity is unchanged, so
    // re-passing the same rebuildKey must NOT trigger a re-render.
    scene.add(Layers.rectangle(
      size: const Size(50, 50),
      color: const Color(0xFF0000FF),
    ));
    await tester.pumpWidget(build(0));
    await tester.pumpAndSettle();
    expect(renderer.calls, 1);

    // Bumping rebuildKey is the documented escape hatch to force a refresh.
    await tester.pumpWidget(build(1));
    await tester.pumpAndSettle();
    expect(renderer.calls, 2);
  });
}
