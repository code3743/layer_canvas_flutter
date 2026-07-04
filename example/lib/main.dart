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

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

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
