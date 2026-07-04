import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });

  group('paint_adapter', () {
    test('defaults to fill', () {
      final paint = FPaint.from(color: const Color(0xFFFF0000));
      expect(paint.style, LayerPaintStyle.fill);
      expect(paint.color, const Color(0xFFFF0000).toColor32());
    });

    test('PaintingStyle.stroke maps to LayerPaintStyle.stroke', () {
      final paint = FPaint.from(style: PaintingStyle.stroke, strokeWidth: 3);
      expect(paint.style, LayerPaintStyle.stroke);
      expect(paint.strokeWidth, 3);
    });

    test('fillAndStroke overrides style', () {
      final paint = FPaint.from(style: PaintingStyle.stroke, fillAndStroke: true);
      expect(paint.style, LayerPaintStyle.fillAndStroke);
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

  group('FLayer', () {
    test('rectangle converts Flutter types', () {
      final layer = FLayer.rectangle(
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

      final layer = FLayer.text(text: 'hello');
      expect(layer.fontFamily, 'Brand');

      final withExplicit = FLayer.text(text: 'hi', fontFamily: 'Other');
      expect(withExplicit.fontFamily, 'Other');
    });
  });
}
