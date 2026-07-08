import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

import 'test_utils.dart';

class _ThrowingRenderer extends Renderer {
  @override
  Future<Uint8List> render(
    Scene scene, {
    OutputFormat format = OutputFormat.png,
  }) => Future.error(RenderException('boom'), StackTrace.current);
}

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
  testWidgets('renders an Image once the scene finishes rendering', (
    tester,
  ) async {
    final scene = Scene(width: 100, height: 100)
      ..add(
        Layers.rectangle(
          size: const Size(100, 100),
          color: const Color(0xFFFF0000),
        ),
      );

    // See pumpUntilImageRenders's doc comment for why this needs runAsync.
    await tester.runAsync(() async {
      await tester.pumpWidget(_wrap(LayerCanvas(scene: scene)));

      // Renderer.render is async; nothing decoded yet on the first frame.
      expect(find.byType(Image), findsNothing);

      await pumpUntilImageRenders(tester);
    });

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('sceneBuilder receives the measured logical size and DPR', (
    tester,
  ) async {
    Size? seenSize;
    double? seenPixelRatio;

    // See the previous test's comment on runAsync — needed here too since
    // this asserts an Image eventually renders.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _wrap(
          LayerCanvas(
            sceneBuilder: (logicalSize, pixelRatio) {
              seenSize = logicalSize;
              seenPixelRatio = pixelRatio;
              return Scene(width: 100, height: 100)
                ..add(Layers.rectangle(size: const Size(100, 100)));
            },
          ),
        ),
      );

      expect(seenSize, const Size(100, 100));
      expect(seenPixelRatio, 1.0);

      await pumpUntilImageRenders(tester);
    });
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('rebuildKey forces a re-render for an in-place scene mutation', (
    tester,
  ) async {
    final scene = Scene(width: 100, height: 100)
      ..add(Layers.rectangle(size: const Size(100, 100)));

    Widget build(int rebuildKey) =>
        _wrap(LayerCanvas(scene: scene, rebuildKey: rebuildKey));

    late Uint8List firstBytes;
    await tester.runAsync(() async {
      await tester.pumpWidget(build(0));
      await pumpUntilImageRenders(tester);
      firstBytes = renderedImageBytes(tester)!;
    });

    // Mutate the same Scene instance in place: identity is unchanged, so
    // re-passing the same rebuildKey must NOT trigger a re-render — the
    // rendered bytes stay the (stale) first render's, ignoring the added
    // blue rectangle.
    scene.add(
      Layers.rectangle(
        size: const Size(50, 50),
        color: const Color(0xFF0000FF),
      ),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(build(0));
      await tester.pump();
      await tester.pump();
    });
    expect(bytesEqual(renderedImageBytes(tester)!, firstBytes), isTrue);

    // Bumping rebuildKey is the documented escape hatch to force a refresh
    // — this time the bytes must actually change once it completes.
    await tester.runAsync(() async {
      await tester.pumpWidget(build(1));
      await pumpUntil(
        tester,
        () => !bytesEqual(renderedImageBytes(tester)!, firstBytes),
      );
    });
    expect(bytesEqual(renderedImageBytes(tester)!, firstBytes), isFalse);
  });

  testWidgets('errorBuilder receives the error and its stack trace', (
    tester,
  ) async {
    Object? seenError;
    StackTrace? seenStackTrace;

    final scene = Scene(width: 10, height: 10)
      ..add(Layers.rectangle(size: const Size(10, 10)));

    // See pumpUntilImageRenders's doc comment on why this needs runAsync —
    // even a Renderer that fails immediately still goes through
    // renderOffMainIsolate's real background isolate.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _wrap(
          LayerCanvas(
            scene: scene,
            renderer: _ThrowingRenderer(),
            errorBuilder: (context, error, stackTrace) {
              seenError = error;
              seenStackTrace = stackTrace;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await pumpUntil(tester, () => seenError != null);
    });

    expect(seenError, isA<RenderException>());
    expect(seenStackTrace, isNotNull);
  });

  group('onLayerTap', () {
    testWidgets('reports the topmost layer under a tap', (tester) async {
      Layer? tappedLayer;
      Offset? tappedPosition;

      final scene = Scene(width: 100, height: 100)
        ..add(
          Layers.rectangle(
            size: const Size(100, 100),
            color: const Color(0xFF1E1E2E),
          ),
        )
        ..add(
          Layers.rectangle(
            id: 'button',
            position: const Offset(10, 10),
            size: const Size(20, 20),
            color: const Color(0xFFFF0000),
          ),
        );

      await tester.pumpWidget(
        _wrap(
          LayerCanvas(
            scene: scene,
            onLayerTap: (layer, position) {
              tappedLayer = layer;
              tappedPosition = position;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final topLeft = tester.getTopLeft(find.byType(LayerCanvas));
      await tester.tapAt(topLeft + const Offset(15, 15));
      await tester.pump();

      expect(tappedLayer?.id, 'button');
      expect(tappedPosition, const Offset(15, 15));
    });

    testWidgets('reports null when the tap misses every layer', (tester) async {
      Layer? tappedLayer;
      var called = false;

      final scene = Scene(width: 100, height: 100)
        ..add(Layers.rectangle(id: 'button', size: const Size(20, 20)));

      await tester.pumpWidget(
        _wrap(
          LayerCanvas(
            scene: scene,
            onLayerTap: (layer, position) {
              called = true;
              tappedLayer = layer;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final topLeft = tester.getTopLeft(find.byType(LayerCanvas));
      await tester.tapAt(topLeft + const Offset(90, 90));
      await tester.pump();

      expect(called, isTrue);
      expect(tappedLayer, isNull);
    });

    testWidgets('maps taps through BoxFit letterboxing correctly', (
      tester,
    ) async {
      Layer? tappedLayer;

      // A 200x100 (2:1) scene shown in a 100x100 box with the default
      // BoxFit.contain fits to 100x50, centered with 25px of padding
      // above and below.
      final scene = Scene(width: 200, height: 100)
        ..add(
          Layers.rectangle(
            id: 'wide',
            size: const Size(200, 100),
            color: const Color(0xFF00FF00),
          ),
        );

      await tester.pumpWidget(
        _wrap(
          LayerCanvas(
            scene: scene,
            onLayerTap: (layer, position) => tappedLayer = layer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final topLeft = tester.getTopLeft(find.byType(LayerCanvas));

      // Inside the top letterbox padding - misses despite a layer covering
      // the entire scene.
      await tester.tapAt(topLeft + const Offset(50, 5));
      await tester.pump();
      expect(tappedLayer, isNull);

      // Inside the actually-fitted image (vertically centered on y=50).
      await tester.tapAt(topLeft + const Offset(50, 50));
      await tester.pump();
      expect(tappedLayer?.id, 'wide');
    });

    testWidgets('taps pass through untouched when onLayerTap is not set', (
      tester,
    ) async {
      final scene = Scene(width: 100, height: 100)
        ..add(Layers.rectangle(size: const Size(100, 100)));

      await tester.pumpWidget(_wrap(LayerCanvas(scene: scene)));
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
