import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// Adapter tests verify the bridge between the two type vocabularies, so
// unlike application code they legitimately need the raw core types too.
import 'package:layer_canvas/layer_canvas.dart';
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
    test('exact FontWeight maps to matching TextWeight', () {
      expect(FontWeight.w700.toTextWeight(), TextWeight.bold);
      expect(FontWeight.w400.toTextWeight(), TextWeight.normal);
      expect(FontWeight.w100.toTextWeight(), TextWeight.thin);
      expect(FontWeight.w900.toTextWeight(), TextWeight.black);
    });

    test('intermediate FontWeight maps to closest TextWeight', () {
      // w200 (value 200) is closer to thin (100) than to light (300)? No:
      // |200-100|=100, |200-300|=100 -> tie, first candidate (thin) wins.
      expect(FontWeight.w200.toTextWeight(), TextWeight.thin);
      // w800 (value 800) is closer to bold (700) than black (900).
      expect(FontWeight.w800.toTextWeight(), TextWeight.bold);
    });

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
}
