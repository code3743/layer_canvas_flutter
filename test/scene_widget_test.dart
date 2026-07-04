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
  testWidgets('renders an Image from its children, like a Stack',
      (tester) async {
    await tester.pumpWidget(_wrap(SceneWidget(
      width: 100,
      height: 100,
      children: [
        Layers.rectangle(size: const Size(100, 100)),
        Layers.text(text: 'hi'),
      ],
    )));

    expect(find.byType(Image), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('re-renders on every rebuild, unlike a stable LayerCanvas scene',
      (tester) async {
    final renderer = _CountingRenderer();

    Widget build() => _wrap(SceneWidget(
          width: 100,
          height: 100,
          renderer: renderer,
          children: [Layers.rectangle(size: const Size(100, 100))],
        ));

    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(renderer.calls, 1);

    // Same width/height/content, but a freshly-built Scene each time — no
    // rebuildKey needed to force this, unlike a fixed LayerCanvas(scene:).
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(renderer.calls, 2);
  });
}
