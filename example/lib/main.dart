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
    final width = (logicalSize.width * pixelRatio).round();
    final height = (logicalSize.height * pixelRatio).round();
    return Scene(width: width, height: height)
      ..add(Layers.rectangle(
        size: Size(width.toDouble(), height.toDouble()),
        color: const Color(0xFF1E1E2E),
      ))
      ..add(Layers.rectangle(
        size: const Size(120, 60),
        position: const Offset(24, 76),
        color: const Color(0xFFFF6B6B),
        cornerRadius: 12,
        pixelRatio: pixelRatio,
      ))
      ..add(Layers.text(
        text: fontFamily == null ? 'Hello, layer_canvas!' : 'Missing font family',
        position: const Offset(24, 24),
        color: const Color(0xFFFFFFFF),
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        pixelRatio: pixelRatio,
      ));
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
          ],
        ),
      ),
    );
  }
}
