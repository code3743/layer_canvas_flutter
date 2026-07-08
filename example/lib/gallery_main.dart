// Throwaway screenshot generator for the README gallery — not part of the
// shipped example. Run with:
//   flutter run -d <device> -t lib/gallery_main.dart
// Tap anywhere to advance to the next scene.
import 'package:flutter/material.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LayerCanvasFonts.ensureInitialized(
    asDefault: 'Roboto',
    families: {'Roboto'},
  );
  runApp(const GalleryApp());
}

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GalleryPage(),
    );
  }
}

typedef _SceneBuilder = Scene Function(Size logicalSize, double pixelRatio);

const _gallerySvg = '''
<svg viewBox="0 0 100 100">
  <defs>
    <linearGradient id="g1" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FF6B6B"/>
      <stop offset="1" stop-color="#FFD93D"/>
    </linearGradient>
  </defs>
  <circle cx="35" cy="35" r="30" fill="url(#g1)"/>
  <circle cx="70" cy="58" r="24" fill="#4C6EF5" opacity="0.88"/>
  <circle cx="52" cy="78" r="15" fill="#63E6BE"/>
</svg>
''';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  static final _svg = SvgDocument.parse(_gallerySvg);

  late final List<_SceneBuilder> _scenes = [
    _gradientBurst,
    _vectorBlob,
    _bauhausGrid,
    _svgPattern,
    _constellation,
    _editorialCard,
  ];

  int _index = 0;

  Scene _gradientBurst(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF0B0B14)),
        // Gradients are fractional relative to the layer's own `size` — an
        // explicit `size` centered on the circle (path centered at
        // (radius, radius), so the box exactly bounds it) is what makes the
        // gradient actually fade across the shape instead of collapsing to
        // a solid fill.
        _gradientCircle(
          center: const Offset(150, 220),
          radius: 170,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFD93D), Color(0x00FFD93D)],
          ),
          opacity: 0.9,
          pixelRatio: pixelRatio,
        ),
        _gradientCircle(
          center: const Offset(260, 480),
          radius: 190,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4C6EF5), Color(0xFF63E6BE)],
          ),
          opacity: 0.85,
          pixelRatio: pixelRatio,
        ),
        _gradientCircle(
          center: const Offset(190, 740),
          radius: 210,
          gradient: const SweepGradient(
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFF4C6EF5),
              Color(0xFFFFD93D),
              Color(0xFFFF6B6B),
            ],
          ),
          opacity: 0.85,
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  /// A filled circle sized/positioned so its `Layers.path` `size` box exactly
  /// bounds it — see the comment in [_gradientBurst] for why that matters
  /// for [gradient] to render as an actual fade instead of a solid fill.
  PathLayer _gradientCircle({
    required Offset center,
    required double radius,
    required Gradient gradient,
    required double pixelRatio,
    double opacity = 1,
  }) {
    return Layers.path(
      path: LayerPathBuilder.circle(Offset(radius, radius), radius),
      position: Offset(center.dx - radius, center.dy - radius),
      size: Size(radius * 2, radius * 2),
      gradient: gradient,
      opacity: opacity,
      pixelRatio: pixelRatio,
    );
  }

  /// A smooth, clearly-asymmetric organic blob through [vertices] — the
  /// "rounded polygon" trick: draw quadratic curves between each edge's
  /// midpoint, using the shared vertex as the curve's control point, so the
  /// silhouette bulges through every vertex instead of having sharp corners.
  static LayerPathBuilder _blob(List<Offset> vertices) {
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

    final builder = LayerPathBuilder()..moveTo(mid(vertices.last, vertices[0]));
    for (var i = 0; i < vertices.length; i++) {
      final next = vertices[(i + 1) % vertices.length];
      builder.quadraticBezierTo(vertices[i], mid(vertices[i], next));
    }
    return builder..close();
  }

  Scene _vectorBlob(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    // 8 vertices around center (170,170) at 45° steps, radius sequence
    // 155/95/145/110/150/90/135/120 — deliberately irregular (no repeating
    // big/small alternation) so the quadratic "rounded polygon" trick (see
    // [_blob]) reads as an organic blob instead of a symmetric rounded
    // square/diamond (which a strict alternating radius produces).
    final blob = _blob(const [
      Offset(325, 170),
      Offset(237, 237),
      Offset(170, 315),
      Offset(92, 248),
      Offset(20, 170),
      Offset(106, 106),
      Offset(170, 35),
      Offset(255, 85),
    ]);

    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF14141F)),
        Layers.path(
          path: blob,
          position: const Offset(30, 220),
          // The blob's own local coordinates span roughly (20,35)-(325,315)
          // — size it to that bounding box so the gradient (fractional
          // relative to `size`) actually fades across the shape instead of
          // collapsing to a solid fill (Layer.size defaults to 0x0 when
          // unset).
          size: const Size(305, 280),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1098AD), Color(0xFF63E6BE)],
          ),
          pixelRatio: pixelRatio,
        ),
        Layers.path(
          path: LayerPathBuilder.circle(const Offset(300, 180), 16),
          color: const Color(0xFFFFD93D),
          position: const Offset(30, 220),
          pixelRatio: pixelRatio,
        ),
        Layers.path(
          path: LayerPathBuilder.circle(const Offset(60, 620), 26),
          color: const Color(0xFFFF6B6B),
          pixelRatio: pixelRatio,
        ),
        Layers.path(
          path: LayerPathBuilder.circle(const Offset(280, 700), 10),
          color: const Color(0xFFFFFFFF),
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  Scene _bauhausGrid(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFFF5F0E6)),
        Layers.rectangle(
          size: const Size(220, 220),
          position: Offset(logicalSize.width / 2 - 110, 90),
          color: const Color(0xFFE03131),
          rotation: 0.12,
          pixelRatio: pixelRatio,
        ),
        Layers.path(
          path: LayerPathBuilder.circle(Offset.zero, 90),
          position: Offset(logicalSize.width - 130, 260),
          color: const Color(0xFF1864AB),
          pixelRatio: pixelRatio,
        ),
        Layers.rectangle(
          size: const Size(260, 90),
          position: const Offset(30, 470),
          color: const Color(0xFFFFD43B),
          rotation: -0.06,
          pixelRatio: pixelRatio,
        ),
        Layers.rectangle(
          size: const Size(70, 320),
          position: Offset(logicalSize.width / 2 - 35, 560),
          color: const Color(0xFF1A1A1A),
          pixelRatio: pixelRatio,
        ),
        Layers.path(
          path: LayerPathBuilder.circle(Offset.zero, 40),
          position: const Offset(70, 700),
          color: const Color(0xFFE03131),
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  Scene _svgPattern(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(
          size: physicalSize,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E2E), Color(0xFF2B2B45)],
          ),
        ),
        // `size:` is Group metadata (anchor/gradient reference box), not a
        // rescale — the artwork's own viewBox (0 0 100 100) is its true
        // visual size, so growing/shrinking it needs `scale:` instead.
        // `size: Size(100,100)` keeps the default center anchor pivoting
        // rotation around the artwork's actual middle. With the default
        // center anchor, `position` places where that anchor ends up — i.e.
        // the artwork's *center*, not its top-left corner — so each is
        // placed with enough margin for its scaled radius to stay on
        // screen.
        Layers.svg(
          _svg,
          position: const Offset(150, 190),
          size: const Size(100, 100),
          scale: 4.0,
          rotation: -0.15,
          opacity: 0.5,
          pixelRatio: pixelRatio,
        ),
        Layers.svg(
          _svg,
          position: const Offset(280, 400),
          size: const Size(100, 100),
          scale: 5.0,
          rotation: 0.1,
          pixelRatio: pixelRatio,
        ),
        Layers.svg(
          _svg,
          position: const Offset(160, 750),
          size: const Size(100, 100),
          scale: 3.0,
          rotation: 0.3,
          opacity: 0.75,
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  Scene _constellation(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    const nodes = [
      Offset(60, 120),
      Offset(220, 90),
      Offset(300, 260),
      Offset(150, 320),
      Offset(90, 480),
      Offset(260, 520),
      Offset(180, 650),
      Offset(300, 760),
    ];
    final links = [
      (0, 1),
      (1, 2),
      (0, 3),
      (2, 3),
      (3, 4),
      (4, 5),
      (3, 6),
      (5, 6),
      (6, 7),
    ];

    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF0B0F1F)),
        for (final (a, b) in links)
          Layers.path(
            path: LayerPathBuilder()
              ..moveTo(nodes[a])
              ..lineTo(nodes[b]),
            color: const Color(0x8863E6BE),
            style: PaintingStyle.stroke,
            strokeWidth: 2,
            strokeCap: StrokeCap.round,
            dashArray: const [10, 8],
            pixelRatio: pixelRatio,
          ),
        for (final node in nodes)
          Layers.path(
            path: LayerPathBuilder.circle(Offset.zero, 8),
            position: node,
            color: const Color(0xFFFFD93D),
            pixelRatio: pixelRatio,
          ),
      ],
    );
  }

  Scene _editorialCard(Size logicalSize, double pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(
          size: physicalSize,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B2B45), Color(0xFF4C6EF5)],
          ),
        ),
        Layers.image(
          source: AssetImageSource('assets/images/logo.png'),
          position: const Offset(24, 24),
          size: const Size(56, 56),
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          pixelRatio: pixelRatio,
        ),
        Layers.text(
          text: 'Native 2D rendering,\nbuilt for Flutter.',
          position: const Offset(24, 110),
          size: const Size(300, 220),
          color: const Color(0xFFFFFFFF),
          fontSize: 30,
          fontWeight: FontWeight.w700,
          pixelRatio: pixelRatio,
        ),
        Layers.path(
          path: LayerPathBuilder()
            ..moveTo(const Offset(24, 0))
            ..lineTo(const Offset(140, 0)),
          position: const Offset(0, 380),
          color: const Color(0xFFFFD93D),
          style: PaintingStyle.stroke,
          strokeWidth: 4,
          strokeCap: StrokeCap.round,
          pixelRatio: pixelRatio,
        ),
      ],
    );
  }

  void _next() {
    setState(() => _index = (_index + 1) % _scenes.length);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _next,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(
          child: LayerCanvas(sceneBuilder: _scenes[_index]),
        ),
      ),
    );
  }
}
