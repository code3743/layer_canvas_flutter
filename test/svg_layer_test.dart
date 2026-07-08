import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';

import 'test_utils.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(devicePixelRatio: 1.0),
      child: Center(child: child),
    ),
  );
}

void main() {
  testWidgets('sizes from naturalSize when width/height are omitted', (
    tester,
  ) async {
    final document = SvgDocument.parse(
      '<svg viewBox="0 0 100 50"><rect width="100" height="50" fill="#ff0000"/></svg>',
    );

    // See pumpUntilImageRenders's doc comment for why this needs runAsync.
    await tester.runAsync(() async {
      await tester.pumpWidget(_wrap(SvgLayer(document)));
      await pumpUntilImageRenders(tester);
    });

    expect(find.byType(Image), findsOneWidget);
    expect(tester.getSize(find.byType(SvgLayer)), const Size(100, 50));
  });

  testWidgets('derives the missing dimension from the aspect ratio', (
    tester,
  ) async {
    final document = SvgDocument.parse(
      '<svg viewBox="0 0 100 50"><rect width="100" height="50" fill="#ff0000"/></svg>',
    );

    await tester.pumpWidget(_wrap(SvgLayer(document, width: 200)));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SvgLayer)), const Size(200, 100));
  });

  testWidgets('accepts explicit width/height when there is no naturalSize', (
    tester,
  ) async {
    final document = SvgDocument.parse(
      '<svg><rect width="10" height="10" fill="#00ff00"/></svg>',
    );

    // See pumpUntilImageRenders's doc comment for why this needs runAsync.
    await tester.runAsync(() async {
      await tester.pumpWidget(_wrap(SvgLayer(document, width: 40, height: 30)));
      await pumpUntilImageRenders(tester);
    });

    expect(find.byType(Image), findsOneWidget);
    expect(tester.getSize(find.byType(SvgLayer)), const Size(40, 30));
  });

  testWidgets(
    'throws when there is no naturalSize and width/height are missing',
    (tester) async {
      final document = SvgDocument.parse(
        '<svg><rect width="10" height="10"/></svg>',
      );

      await tester.pumpWidget(_wrap(SvgLayer(document)));
      expect(tester.takeException(), isA<ArgumentError>());
    },
  );
}
