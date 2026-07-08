import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// Adapter tests verify the bridge between the two type vocabularies, so
// unlike application code they legitimately need the raw core types too.
// `Gradient`/`LinearGradient`/`RadialGradient` and `StrokeCap`/`StrokeJoin`
// collide with Flutter's own — this file needs both sides at once (build a
// Flutter value, assert on the core one it converts to), so those five are
// only reachable via the `lc.` prefix below; everything else in the core
// package (`Color32`, `GradientStop`, `ConicGradient`, `FillRule`...)
// doesn't collide and stays unprefixed.
import 'package:layer_canvas/layer_canvas.dart'
    hide Gradient, LinearGradient, RadialGradient, StrokeCap, StrokeJoin;
import 'package:layer_canvas/layer_canvas.dart'
    as lc
    show LinearGradient, RadialGradient, StrokeCap, StrokeJoin;
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

void main() {
  group('color_adapter', () {
    test('Color -> Color32 round trip', () {
      const color = Color(0xFF3366FF);
      expect(color.toColor32().value, 0xFF3366FF);
      expect(color.toColor32().toColor(), color);
    });

    test('Color32 -> Color round trip', () {
      const color32 = Color32(0x80112233);
      expect(color32.toColor().toColor32(), color32);
    });
  });

  group('geometry_adapter', () {
    test('Offset <-> Point2D round trip', () {
      const offset = Offset(12.5, -4.0);
      final point = offset.toPoint2D();
      expect(point.x, offset.dx);
      expect(point.y, offset.dy);
      expect(point.toOffset(), offset);
    });

    test('Size <-> Size2D round trip', () {
      const size = Size(200, 80);
      final size2d = size.toSize2D();
      expect(size2d.width, size.width);
      expect(size2d.height, size.height);
      expect(size2d.toSize(), size);
    });
  });

  group('text_adapter', () {
    test('named FontWeight maps to the matching TextWeight value', () {
      // TextWeight has no value equality (unlike LayerTransform/Point2D/
      // Size2D/Color32), so compare `.value` rather than instance equality.
      expect(FontWeight.w700.toTextWeight().value, TextWeight.bold.value);
      expect(FontWeight.w400.toTextWeight().value, TextWeight.normal.value);
      expect(FontWeight.w100.toTextWeight().value, TextWeight.thin.value);
      expect(FontWeight.w900.toTextWeight().value, TextWeight.black.value);
    });

    test(
      'intermediate FontWeight maps exactly, not to the closest named '
      'TextWeight',
      () {
        // TextWeight.fromValue is exact (layer_canvas 0.1.0-beta.6+), so a
        // FontWeight with no matching named constant round-trips to its own
        // raw value instead of snapping to the nearest named one.
        expect(FontWeight.w200.toTextWeight().value, 200);
        expect(FontWeight.w800.toTextWeight().value, 800);
      },
    );

    test('TextAlign maps to TextAlignment', () {
      expect(TextAlign.left.toTextAlignment(), TextAlignment.left);
      expect(TextAlign.start.toTextAlignment(), TextAlignment.left);
      expect(TextAlign.justify.toTextAlignment(), TextAlignment.left);
      expect(TextAlign.center.toTextAlignment(), TextAlignment.center);
      expect(TextAlign.right.toTextAlignment(), TextAlignment.right);
      expect(TextAlign.end.toTextAlignment(), TextAlignment.right);
    });

    test('TextWeight -> FontWeight is exact', () {
      for (final weight in [
        TextWeight.thin,
        TextWeight.light,
        TextWeight.normal,
        TextWeight.medium,
        TextWeight.semiBold,
        TextWeight.bold,
        TextWeight.black,
      ]) {
        expect(weight.toFontWeight().value, weight.value);
      }
    });

    test('TextAlignment -> TextAlign round trip', () {
      expect(TextAlignment.left.toTextAlign(), TextAlign.left);
      expect(TextAlignment.center.toTextAlign(), TextAlign.center);
      expect(TextAlignment.right.toTextAlign(), TextAlign.right);
    });
  });

  group('Layers.rectangle paint style', () {
    test('defaults to fill', () {
      final layer = Layers.rectangle(
        size: const Size(10, 10),
        color: const Color(0xFFFF0000),
      );
      expect(layer.paint.style, LayerPaintStyle.fill);
      expect(layer.paint.color, const Color(0xFFFF0000).toColor32());
    });

    test('PaintingStyle.stroke maps to LayerPaintStyle.stroke', () {
      final layer = Layers.rectangle(
        size: const Size(10, 10),
        style: PaintingStyle.stroke,
        strokeWidth: 3,
      );
      expect(layer.paint.style, LayerPaintStyle.stroke);
      expect(layer.paint.strokeWidth, 3);
    });

    test('fillAndStroke overrides style', () {
      final layer = Layers.rectangle(
        size: const Size(10, 10),
        style: PaintingStyle.stroke,
        fillAndStroke: true,
      );
      expect(layer.paint.style, LayerPaintStyle.fillAndStroke);
    });
  });

  group('image_adapter', () {
    test('BoxFit maps to ImageFit', () {
      expect(BoxFit.fill.toImageFit(), ImageFit.fill);
      expect(BoxFit.contain.toImageFit(), ImageFit.contain);
      expect(BoxFit.scaleDown.toImageFit(), ImageFit.contain);
      expect(BoxFit.cover.toImageFit(), ImageFit.cover);
      expect(BoxFit.fitWidth.toImageFit(), ImageFit.cover);
      expect(BoxFit.fitHeight.toImageFit(), ImageFit.cover);
      expect(BoxFit.none.toImageFit(), ImageFit.none);
    });
  });

  group('paint_adapter', () {
    test('StrokeCap maps 1:1 to the core StrokeCap', () {
      expect(StrokeCap.butt.toLayerStrokeCap(), lc.StrokeCap.butt);
      expect(StrokeCap.round.toLayerStrokeCap(), lc.StrokeCap.round);
      expect(StrokeCap.square.toLayerStrokeCap(), lc.StrokeCap.square);
    });

    test('StrokeJoin maps 1:1 to the core StrokeJoin', () {
      expect(StrokeJoin.miter.toLayerStrokeJoin(), lc.StrokeJoin.miter);
      expect(StrokeJoin.round.toLayerStrokeJoin(), lc.StrokeJoin.round);
      expect(StrokeJoin.bevel.toLayerStrokeJoin(), lc.StrokeJoin.bevel);
    });
  });

  group('Layers', () {
    test('rectangle converts Flutter types', () {
      final layer = Layers.rectangle(
        size: const Size(200, 80),
        position: const Offset(10, 20),
        color: const Color(0xFF00FF00),
        cornerRadius: 12,
      );
      expect(layer.size, const Size2D(200, 80));
      expect(layer.transform.position, const Point2D(10, 20));
      expect(layer.paint.color, const Color(0xFF00FF00).toColor32());
      expect(layer.cornerRadius, 12);
    });

    test('text falls back to LayerCanvasFonts.defaultFamily', () {
      LayerCanvasFonts.defaultFamily = 'Brand';
      addTearDown(() => LayerCanvasFonts.defaultFamily = null);

      final layer = Layers.text(text: 'hello');
      expect(layer.fontFamily, 'Brand');

      final withExplicit = Layers.text(text: 'hi', fontFamily: 'Other');
      expect(withExplicit.fontFamily, 'Other');
    });

    test('pixelRatio scales rectangle measurements together', () {
      final layer = Layers.rectangle(
        size: const Size(100, 50),
        position: const Offset(10, 20),
        cornerRadius: 4,
        strokeWidth: 2,
        style: PaintingStyle.stroke,
        pixelRatio: 2.0,
      );
      expect(layer.size, const Size2D(200, 100));
      expect(layer.transform.position, const Point2D(20, 40));
      expect(layer.cornerRadius, 8);
      expect(layer.paint.strokeWidth, 4);
    });

    test('pixelRatio scales text measurements together', () {
      final layer = Layers.text(
        text: 'hi',
        position: const Offset(10, 20),
        fontSize: 14,
        pixelRatio: 2.0,
      );
      expect(layer.transform.position, const Point2D(20, 40));
      expect(layer.fontSize, 28);
    });
  });

  group('Scenes', () {
    test('of rounds width/height and adds children in order', () {
      final a = Layers.rectangle(size: const Size(10, 10));
      final b = Layers.rectangle(size: const Size(20, 20));

      final scene = Scenes.of(width: 100.4, height: 200.6, children: [a, b]);

      expect(scene.width, 100);
      expect(scene.height, 201);
      expect(scene.layers, [a, b]);
    });

    test('of defaults to no children', () {
      final scene = Scenes.of(width: 50, height: 50);
      expect(scene.layers, isEmpty);
    });
  });

  group('path_adapter', () {
    test('PathFillType <-> FillRule round trip', () {
      expect(PathFillType.nonZero.toFillRule(), FillRule.nonZero);
      expect(PathFillType.evenOdd.toFillRule(), FillRule.evenOdd);
      expect(FillRule.nonZero.toPathFillType(), PathFillType.nonZero);
      expect(FillRule.evenOdd.toPathFillType(), PathFillType.evenOdd);
    });
  });

  group('LayerPathBuilder', () {
    test('mirrors Path\'s moveTo/lineTo/close', () {
      final path =
          (LayerPathBuilder()
                ..moveTo(const Offset(0, 0))
                ..lineTo(const Offset(10, 0))
                ..lineTo(const Offset(10, 10))
                ..close())
              .build();
      expect(path.commands, [
        const MoveTo(Point2D(0, 0)),
        const LineTo(Point2D(10, 0)),
        const LineTo(Point2D(10, 10)),
        const ClosePath(),
      ]);
    });

    test('quadraticBezierTo and cubicTo match core command shapes', () {
      final path =
          (LayerPathBuilder()
                ..moveTo(const Offset(0, 0))
                ..quadraticBezierTo(const Offset(5, 10), const Offset(10, 0))
                ..cubicTo(
                  const Offset(2, 2),
                  const Offset(8, 2),
                  const Offset(10, 0),
                ))
              .build();
      expect(
        path.commands[1],
        const QuadraticBezierTo(Point2D(5, 10), Point2D(10, 0)),
      );
      expect(
        path.commands[2],
        const CubicBezierTo(Point2D(2, 2), Point2D(8, 2), Point2D(10, 0)),
      );
    });

    test('arcToPoint maps clockwise to the SVG sweep flag', () {
      final path =
          (LayerPathBuilder()
                ..moveTo(const Offset(0, 0))
                ..arcToPoint(
                  const Offset(10, 10),
                  radius: const Radius.elliptical(5, 3),
                  rotation: 0.4,
                  largeArc: true,
                  clockwise: false,
                ))
              .build();
      expect(
        path.commands[1],
        const ArcTo(
          radiusX: 5,
          radiusY: 3,
          xAxisRotation: 0.4,
          largeArc: true,
          sweep: false,
          point: Point2D(10, 10),
        ),
      );
    });

    test('polygon/polyline/circle/oval match the core factories', () {
      final polygon = LayerPathBuilder.polygon(const [
        Offset(0, 0),
        Offset(10, 0),
        Offset(5, 10),
      ]).build();
      expect(
        polygon.commands,
        LayerPath.polygon(const [
          Point2D(0, 0),
          Point2D(10, 0),
          Point2D(5, 10),
        ]).commands,
      );

      final circle = LayerPathBuilder.circle(const Offset(5, 5), 5).build();
      expect(
        circle.commands,
        LayerPath.circle(const Point2D(5, 5), 5).commands,
      );

      final oval = LayerPathBuilder.oval(
        const Rect.fromLTWH(0, 0, 20, 10),
      ).build();
      expect(
        oval.commands,
        LayerPath.ellipse(const Point2D(10, 5), 10, 5).commands,
      );
    });

    test('build(scale:) multiplies every coordinate and arc radius', () {
      final path =
          (LayerPathBuilder()
                ..moveTo(const Offset(1, 2))
                ..arcToPoint(
                  const Offset(3, 4),
                  radius: const Radius.circular(2),
                ))
              .build(scale: 2.0);
      expect(path.commands[0], const MoveTo(Point2D(2, 4)));
      expect(
        // arcToPoint's default clockwise:true maps to sweep:true.
        path.commands[1],
        const ArcTo(radiusX: 4, radiusY: 4, sweep: true, point: Point2D(6, 8)),
      );
    });

    test('build() throws for an empty builder', () {
      expect(() => LayerPathBuilder().build(), throwsA(isA<StateError>()));
    });
  });

  group('gradient_adapter', () {
    test('TileMode maps to GradientExtendMode', () {
      expect(TileMode.clamp.toGradientExtendMode(), GradientExtendMode.pad);
      expect(
        TileMode.repeated.toGradientExtendMode(),
        GradientExtendMode.repeat,
      );
      expect(
        TileMode.mirror.toGradientExtendMode(),
        GradientExtendMode.reflect,
      );
      expect(TileMode.decal.toGradientExtendMode(), GradientExtendMode.pad);
    });

    test('Alignment maps to fractional 0.0..1.0 coordinates', () {
      expect(Alignment.topLeft.toFractionalPoint2D(), const Point2D(0, 0));
      expect(Alignment.bottomRight.toFractionalPoint2D(), const Point2D(1, 1));
      expect(Alignment.center.toFractionalPoint2D(), const Point2D(0.5, 0.5));
    });

    test('LinearGradient converts to the core LinearGradient', () {
      const gradient = LinearGradient(
        colors: [Color(0xFFFF0000), Color(0xFF0000FF)],
      );
      final converted = gradient.toLayerGradient();
      expect(converted, isA<lc.LinearGradient>());
      final linear = converted as lc.LinearGradient;
      expect(linear.start, Alignment.centerLeft.toFractionalPoint2D());
      expect(linear.end, Alignment.centerRight.toFractionalPoint2D());
      expect(linear.stops, [
        const GradientStop(0, Color32.fromRGB(0xFF, 0, 0)),
        const GradientStop(1, Color32.fromRGB(0, 0, 0xFF)),
      ]);
    });

    test('RadialGradient converts to the core RadialGradient', () {
      const gradient = RadialGradient(
        radius: 0.7,
        colors: [Color(0xFFFF0000), Color(0xFF00FF00)],
        tileMode: TileMode.repeated,
      );
      final converted = gradient.toLayerGradient() as lc.RadialGradient;
      expect(converted.center, Alignment.center.toFractionalPoint2D());
      expect(converted.radius, 0.7);
      expect(converted.extendMode, GradientExtendMode.repeat);
    });

    test('SweepGradient converts to the core ConicGradient', () {
      const gradient = SweepGradient(
        startAngle: 0.5,
        colors: [Color(0xFFFF0000), Color(0xFF00FF00)],
      );
      final converted = gradient.toLayerGradient() as ConicGradient;
      expect(converted.center, Alignment.center.toFractionalPoint2D());
      expect(converted.angle, 0.5);
    });

    test('explicit stops carry over unevenly spaced', () {
      const gradient = LinearGradient(
        colors: [Color(0xFFFF0000), Color(0xFF00FF00), Color(0xFF0000FF)],
        stops: [0.0, 0.2, 1.0],
      );
      final converted = gradient.toLayerGradient();
      expect(converted.stops.map((s) => s.offset), [0.0, 0.2, 1.0]);
    });

    test('an unsupported Gradient subtype throws ArgumentError', () {
      expect(
        () => const _UnknownGradient().toLayerGradient(),
        throwsArgumentError,
      );
    });
  });

  group('Layers.path', () {
    test('builds a PathLayer with the given fill/stroke/fillType', () {
      final layer = Layers.path(
        path: LayerPathBuilder.circle(const Offset(5, 5), 5),
        color: const Color(0xFF00FF00),
        fillType: PathFillType.evenOdd,
      );
      expect(layer.paint.color, const Color(0xFF00FF00).toColor32());
      expect(layer.fillRule, FillRule.evenOdd);
    });

    test('gradient overrides the solid color, like Layers.rectangle', () {
      final layer = Layers.path(
        path: LayerPathBuilder.circle(const Offset(5, 5), 5),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFF0000FF)],
        ),
      );
      expect(layer.paint.gradient, isNotNull);
    });

    test('pixelRatio scales the path geometry along with position/size', () {
      final layer = Layers.path(
        path: LayerPathBuilder()
          ..moveTo(const Offset(1, 1))
          ..lineTo(const Offset(2, 2)),
        position: const Offset(10, 10),
        pixelRatio: 2.0,
      );
      expect(layer.transform.position, const Point2D(20, 20));
      expect(layer.path.commands.first, const MoveTo(Point2D(2, 2)));
    });
  });

  group('Layers.svg', () {
    test('places a parsed SvgDocument as a Group, scaled by pixelRatio', () {
      final document = SvgDocument.parse(
        '<svg viewBox="0 0 10 10"><rect width="10" height="10" fill="#ff0000"/></svg>',
      );
      final group = Layers.svg(
        document,
        position: const Offset(5, 5),
        size: const Size(20, 20),
        pixelRatio: 2.0,
      );
      expect(group.transform.position, const Point2D(10, 10));
      expect(group.size, const Size2D(40, 40));
      expect(group.children, hasLength(1));
    });
  });

  group('Layers stroke cap/join/miter/dash', () {
    test('rectangle passes strokeCap/strokeJoin/strokeMiterLimit through', () {
      final layer = Layers.rectangle(
        size: const Size(10, 10),
        style: PaintingStyle.stroke,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.bevel,
        strokeMiterLimit: 2.5,
      );
      expect(layer.paint.strokeCap, lc.StrokeCap.round);
      expect(layer.paint.strokeJoin, lc.StrokeJoin.bevel);
      expect(layer.paint.miterLimit, 2.5);
    });

    test('rectangle defaults match dart:ui Paint defaults', () {
      final layer = Layers.rectangle(size: const Size(10, 10));
      expect(layer.paint.strokeCap, lc.StrokeCap.butt);
      expect(layer.paint.strokeJoin, lc.StrokeJoin.miter);
      expect(layer.paint.miterLimit, 4.0);
      expect(layer.paint.dashArray, isEmpty);
    });

    test('path scales dashArray/dashOffset by pixelRatio', () {
      final layer = Layers.path(
        path: LayerPathBuilder.circle(const Offset(5, 5), 5),
        style: PaintingStyle.stroke,
        dashArray: const [4, 2],
        dashOffset: 1,
        pixelRatio: 2.0,
      );
      expect(layer.paint.dashArray, [8, 4]);
      expect(layer.paint.dashOffset, 2);
    });
  });

  group('Layers clipBehavior', () {
    test('Clip.none leaves clipToBounds false (the default)', () {
      final layer = Layers.rectangle(size: const Size(10, 10));
      expect(layer.clipToBounds, isFalse);
    });

    test('any non-none Clip sets clipToBounds true', () {
      expect(
        Layers.rectangle(
          size: const Size(10, 10),
          clipBehavior: Clip.hardEdge,
        ).clipToBounds,
        isTrue,
      );
      expect(
        Layers.image(
          source: MemoryImageSource(Uint8List.fromList([])),
          size: const Size(10, 10),
          clipBehavior: Clip.antiAlias,
        ).clipToBounds,
        isTrue,
      );
      expect(
        Layers.text(
          text: 'hi',
          size: const Size(10, 10),
          clipBehavior: Clip.hardEdge,
        ).clipToBounds,
        isTrue,
      );
      expect(
        Layers.path(
          path: LayerPathBuilder.circle(const Offset(5, 5), 5),
          clipBehavior: Clip.hardEdge,
        ).clipToBounds,
        isTrue,
      );
    });
  });

  group('Layers scale/alignment', () {
    test('scale becomes a uniform LayerTransform.scale', () {
      final layer = Layers.rectangle(size: const Size(10, 10), scale: 1.5);
      expect(layer.transform.scale, const Point2D(1.5, 1.5));
    });

    test('default alignment matches the core default anchor', () {
      final layer = Layers.rectangle(size: const Size(10, 10));
      expect(layer.transform.anchor, const Point2D(0.5, 0.5));
    });

    test('alignment maps like gradient_adapter\'s AlignmentGeometryX', () {
      final layer = Layers.rectangle(
        size: const Size(10, 10),
        alignment: Alignment.topLeft,
      );
      expect(layer.transform.anchor, const Point2D(0, 0));
    });

    test('group/svg also accept scale and alignment', () {
      final group = Layers.group(
        children: [Layers.rectangle(size: const Size(10, 10))],
        scale: 2.0,
        alignment: Alignment.bottomRight,
      );
      expect(group.transform.scale, const Point2D(2.0, 2.0));
      expect(group.transform.anchor, const Point2D(1, 1));
    });
  });

  group('AssetImageSource', () {
    test('toJson/fromJson round trip, without a package', () {
      final source = AssetImageSource('images/logo.png');
      final json = source.toJson();
      expect(json, {'type': 'asset', 'key': 'images/logo.png'});

      final decoded = AssetImageSource.fromJson(json);
      expect(decoded.assetKey, 'images/logo.png');
      expect(decoded.package, isNull);
      expect(decoded.bundleKey, 'images/logo.png');
    });

    test('toJson/fromJson round trip, with a package', () {
      final source = AssetImageSource('images/logo.png', package: 'brand_kit');
      final json = source.toJson();
      expect(json, {
        'type': 'asset',
        'key': 'images/logo.png',
        'package': 'brand_kit',
      });

      final decoded = AssetImageSource.fromJson(json);
      expect(decoded.package, 'brand_kit');
      expect(decoded.bundleKey, 'packages/brand_kit/images/logo.png');
    });

    test('registers itself with LayerRegistry so Scene.fromJson decodes it', () {
      final scene = Scene(width: 10, height: 10)
        ..add(
          Layers.image(
            source: AssetImageSource('images/logo.png'),
            size: const Size(10, 10),
          ),
        );

      final decodedScene = Scene.fromJson(
        jsonDecodeRoundTrip(scene.toJson()),
      );
      final decodedLayer = decodedScene.layers.single as ImageLayer;
      expect(decodedLayer.source, isA<AssetImageSource>());
      expect(
        (decodedLayer.source as AssetImageSource).assetKey,
        'images/logo.png',
      );
    });
  });
}

/// Round-trips a `toJson()` map through `jsonEncode`/`jsonDecode` — the same
/// path a real save/load would take — rather than passing the `Map` object
/// straight to `fromJson`, so this also exercises that every value in the
/// map is actually JSON-safe (no stray `Color32`/enum instances left
/// un-encoded).
Map<String, Object?> jsonDecodeRoundTrip(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

/// A minimal [Gradient] subtype that isn't [LinearGradient], [RadialGradient],
/// or [SweepGradient] — exercises [GradientX.toLayerGradient]'s fallback,
/// which none of Flutter's own gradient types can reach.
class _UnknownGradient extends Gradient {
  const _UnknownGradient()
    : super(colors: const [Color(0xFF000000), Color(0xFFFFFFFF)]);

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) =>
      throw UnimplementedError();

  @override
  Gradient scale(double factor) => this;

  @override
  Gradient withOpacity(double opacity) => this;
}
