// Regenerates the README's hero banner (doc/hero.png). Run with:
//
//   dart run tool/generate_readme_assets.dart
//
// Built with plain `package:layer_canvas` (not layer_canvas_flutter itself)
// on purpose: this is a standalone script run via `dart run`, and Flutter's
// Color/Offset/Gradient types need a Flutter SDK context this script
// doesn't have. The pixels are identical either way — Layers.rectangle
// etc. just convert to these same core types before rendering.
import 'dart:io';

import 'package:layer_canvas/layer_canvas.dart';

Future<void> main() async {
  const width = 960.0;
  const height = 400.0;
  final scene = Scene(width: width.toInt(), height: height.toInt());

  // Background: near-black -> deep blue diagonal gradient (Flutter-blue
  // accent, distinct from the core package's purple/pink banner).
  scene.add(
    RectangleLayer(
      size: const Size2D(width, height),
      paint: LayerPaint(
        gradient: LinearGradient.colors(
          start: const Point2D(0, 0),
          end: const Point2D(1, 1),
          colors: [Color32.fromRGB(14, 18, 32), Color32.fromRGB(15, 44, 84)],
        ),
      ),
    ),
  );

  // Soft decorative circles, echoing the core banner's language.
  scene.add(
    PathLayer.filled(
      path: LayerPath.circle(const Point2D(780, 80), 140),
      color: const Color32.fromARGB(55, 39, 174, 255),
    ),
  );
  scene.add(
    PathLayer.filled(
      path: LayerPath.circle(const Point2D(880, 300), 110),
      color: const Color32.fromARGB(45, 100, 220, 255),
    ),
  );

  // Title + tagline.
  scene.add(
    TextLayer(
      text: 'layer_canvas_flutter',
      transform: const LayerTransform(position: Point2D(60, 100)),
      size: const Size2D(760, 80),
      fontSize: 52,
      fontWeight: TextWeight.bold,
      color: Color32.white,
    ),
  );
  scene.add(
    TextLayer(
      text: 'Native 2D rendering for Flutter',
      transform: const LayerTransform(position: Point2D(64, 168)),
      size: const Size2D(700, 32),
      fontSize: 22,
      color: const Color32.fromRGB(216, 230, 255),
    ),
  );
  scene.add(
    TextLayer(
      text: 'Color · Offset · Gradient · BoxFit — no dart:ui juggling',
      transform: const LayerTransform(position: Point2D(64, 206)),
      size: const Size2D(700, 26),
      fontSize: 16,
      color: const Color32.fromRGB(170, 190, 220),
    ),
  );

  // A small "device card" on the right, rendering exactly the README's own
  // Quick start scene, so the banner is a live example, not just branding.
  const cardX = 620.0, cardY = 250.0, cardW = 260.0, cardH = 120.0;
  scene.add(
    RectangleLayer(
      transform: const LayerTransform(position: Point2D(cardX, cardY)),
      size: const Size2D(cardW, cardH),
      paint: const LayerPaint(
        style: LayerPaintStyle.fillAndStroke,
        color: Color32.fromARGB(220, 30, 30, 46),
        strokeWidth: 1.5,
      ),
      cornerRadius: 14,
    ),
  );
  scene.add(
    RectangleLayer(
      transform: const LayerTransform(
        position: Point2D(cardX + 16, cardY + 16),
      ),
      size: const Size2D(cardW - 32, cardH - 48),
      paint: LayerPaint(
        gradient: LinearGradient.colors(
          start: const Point2D(0, 0),
          end: const Point2D(1, 1),
          colors: [Color32.fromRGB(30, 30, 46), Color32.fromRGB(43, 43, 69)],
        ),
      ),
      cornerRadius: 8,
    ),
  );
  scene.add(
    TextLayer(
      text: 'Hello, layer_canvas!',
      transform: const LayerTransform(
        position: Point2D(cardX + 26, cardY + 30),
      ),
      size: const Size2D(cardW - 52, 26),
      fontSize: 14,
      fontWeight: TextWeight.semiBold,
      color: Color32.white,
    ),
  );

  final scriptDir = File.fromUri(Platform.script).parent;
  final outputPath = scriptDir.uri.resolve('../doc/hero.png').toFilePath();
  await const Renderer().renderToFile(scene, outputPath);
  stdout.writeln('Wrote $outputPath');
}
