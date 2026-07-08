import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';
import 'package:layer_canvas_flutter/src/rendering/isolate_render.dart';

void main() {
  test(
    'renderOffMainIsolate does not block the calling isolate\'s event loop',
    () async {
      // Deliberately heavy (large canvas, many gradient-filled shapes) so
      // the native render reliably takes tens of milliseconds — long
      // enough for a concurrently-ticking Timer to prove the calling
      // isolate's event loop kept running while it was in flight. A plain
      // `renderer.render(scene)` call would occupy the isolate's single
      // thread for the whole render, so this Timer could not fire even
      // once until it returned; renderOffMainIsolate runs the native call
      // on a background isolate instead, so the caller's event loop stays
      // free — this is exactly what every widget/helper in this package
      // relies on to avoid blocking Flutter's UI isolate.
      final scene = Scene(width: 3000, height: 3000);
      for (var i = 0; i < 300; i++) {
        scene.add(
          Layers.path(
            path: LayerPathBuilder.circle(
              Offset((i % 20) * 150.0 + 75, (i ~/ 20) * 200.0 + 100),
              70,
            ),
            gradient: RadialGradient(
              colors: [
                Color.fromARGB(255, i % 255, 0, 255 - i % 255),
                Color.fromARGB(255, 0, i % 255, i % 255),
              ],
            ),
          ),
        );
      }

      var ticks = 0;
      final ticker = Timer.periodic(
        const Duration(milliseconds: 1),
        (_) => ticks++,
      );

      await renderOffMainIsolate(const Renderer(), scene);
      ticker.cancel();

      expect(
        ticks,
        greaterThan(0),
        reason:
            'expected the 1ms Timer to have fired at least once while '
            'renderOffMainIsolate() was in flight — 0 ticks means the '
            'calling isolate was blocked for the whole render, not just '
            'slow test timing',
      );
    },
  );
}
