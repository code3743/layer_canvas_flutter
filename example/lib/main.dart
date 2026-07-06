import 'package:flutter/material.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // This app's pubspec.yaml sets `embed_default_font: false`, so the native
  // engine has no fallback font: preload the app's own Roboto asset (see
  // pubspec.yaml `flutter: fonts:`) and make it the default for Layers.text.
  // `families` scopes registration to just this font — without it, every
  // font any dependency ships would also get loaded and registered.
  await LayerCanvasFonts.ensureInitialized(
    asDefault: 'Roboto',
    families: {'Roboto'},
  );
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'layer_canvas_flutter example',
      home: const DemoPage(),
    );
  }
}

const _demoLogoSvg = '''
<svg viewBox="0 0 64 64">
  <defs>
    <linearGradient id="mark" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#4C6EF5"/>
      <stop offset="1" stop-color="#3B5BDB"/>
    </linearGradient>
  </defs>
  <rect x="4" y="4" width="40" height="40" rx="10" fill="url(#mark)"/>
  <circle cx="44" cy="44" r="16" fill="#FFD93D"/>
</svg>
''';

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  // Parsed once (real XML work) and reused by every rebuild — see the
  // "SVG" section of the README for why this isn't parsed inside a
  // sceneBuilder, which runs on every build/resize.
  static final _logo = SvgDocument.parse(_demoLogoSvg);

  Scene _buildScene(Size logicalSize, double pixelRatio, {String? fontFamily}) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF1E1E2E)),
        Layers.rectangle(
          size: const Size(120, 60),
          position: const Offset(24, 76),
          color: const Color(0xFFFF6B6B),
          cornerRadius: 12,
          pixelRatio: pixelRatio,
        ),
        Layers.text(
          text: fontFamily == null
              ? 'Hello, layer_canvas!'
              : 'Missing font family',
          position: const Offset(24, 24),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  Scene _buildGroupScene(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF1E1E2E)),
        // A Group shares one transform/opacity across its children, so
        // moving, rotating or fading the card below moves the rectangle
        // and the text together instead of updating each layer by hand.
        Layers.group(
          position: const Offset(60, 60),
          rotation: -0.08,
          pixelRatio: pixelRatio,
          children: [
            Layers.rectangle(
              size: const Size(160, 70),
              color: const Color(0xFF4C6EF5),
              cornerRadius: 10,
              pixelRatio: pixelRatio,
            ),
            Layers.text(
              text: 'Grouped!',
              position: const Offset(16, 22),
              color: const Color(0xFFFFFFFF),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              pixelRatio: pixelRatio,
            ),
          ],
        ),
      ],
    );
  }

  Scene _buildGradientScene(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF1E1E2E)),
        // Layers.rectangle/Layers.path take a plain Flutter Gradient — the
        // same LinearGradient/RadialGradient/SweepGradient you'd give a
        // BoxDecoration, converted internally to layer_canvas's own
        // gradient types.
        Layers.rectangle(
          size: const Size(150, 100),
          position: const Offset(20, 30),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          cornerRadius: 14,
          pixelRatio: pixelRatio,
        ),
        Layers.path(
          path: LayerPathBuilder.circle(const Offset(45, 45), 45),
          position: const Offset(200, 30),
          gradient: const RadialGradient(colors: [Color(0xFF63E6BE), Color(0xFF1098AD)]),
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  Scene _buildPathScene(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF1E1E2E)),
        // LayerPathBuilder mirrors dart:ui's Path (moveTo/lineTo/cubicTo/
        // arcToPoint/close) so a shape you'd know how to draw in a
        // CustomPainter reads the same way here.
        Layers.path(
          path: LayerPathBuilder()
            ..moveTo(const Offset(60, 0))
            ..lineTo(const Offset(120, 100))
            ..lineTo(const Offset(0, 100))
            ..close(),
          position: const Offset(24, 20),
          color: const Color(0xFF06D6A0),
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  Scene _buildSvgScene(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF1E1E2E)),
        Layers.svg(
          _logo,
          position: const Offset(24, 20),
          size: const Size(64, 64),
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('layer_canvas_flutter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Preloaded font (embed_default_font: false, Roboto '
              'registered via LayerCanvasFonts.ensureInitialized):',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayerCanvas(
                sceneBuilder: (logicalSize, pixelRatio) =>
                    _buildScene(logicalSize, pixelRatio),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Same scene with an unregistered font family: with the embed '
              'off there is no fallback, so this TextLayer renders nothing '
              'while the rest of the scene still renders:',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayerCanvas(
                sceneBuilder: (logicalSize, pixelRatio) => _buildScene(
                  logicalSize,
                  pixelRatio,
                  fontFamily: 'NotRegistered',
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Layers.group: a rectangle and a text layer rotated and '
              'moved together as one unit via a single shared transform:',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayerCanvas(
                sceneBuilder: _buildGroupScene,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gradients: Layers.rectangle/Layers.path accept a plain '
              'Flutter LinearGradient/RadialGradient/SweepGradient:',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayerCanvas(
                sceneBuilder: _buildGradientScene,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'LayerPathBuilder: a custom shape drawn with the same '
              'method names as dart:ui\'s own Path:',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayerCanvas(
                sceneBuilder: _buildPathScene,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Layers.svg: an SvgDocument parsed once (above, as a static '
              'field) and placed here like any other layer:',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayerCanvas(
                sceneBuilder: _buildSvgScene,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SceneWidget: layers passed as children, like Stack, for a '
              'fixed-size scene that does not need per-build DPR scaling:',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: SceneWidget(
                width: 300,
                height: 160,
                children: [
                  Layers.rectangle(
                    size: const Size(300, 160),
                    color: const Color(0xFF1E1E2E),
                  ),
                  Layers.rectangle(
                    size: const Size(64, 64),
                    position: const Offset(24, 24),
                    color: const Color(0xFF63E6BE),
                    cornerRadius: 8,
                  ),
                  Layers.text(
                    text: 'SceneWidget',
                    position: const Offset(100, 44),
                    color: const Color(0xFFFFFFFF),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
