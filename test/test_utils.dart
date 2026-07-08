import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [tester] with real waits until [predicate] is true (or [timeout]
/// elapses) — call this from inside a `tester.runAsync(...)` block.
///
/// Rendering in this package runs the native call on a background isolate
/// (see `renderOffMainIsolate`), so a render's `Future` only completes via a
/// genuine cross-isolate message — something FakeAsync (what `pump()`/
/// `pumpAndSettle()` run under by default) can't fast-forward.
/// `tester.runAsync()` steps outside FakeAsync for real async work, but
/// isolate spawn latency varies (especially under a test sandbox), so this
/// polls with real waits instead of a single fixed delay, which would be
/// flaky either way (too short: fails before the isolate finishes; too
/// long: slows every test down for no reason).
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(step);
    await tester.pump();
  }
}

/// [pumpUntil] specialized for "at least one [Image] widget appears".
Future<void> pumpUntilImageRenders(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 100),
}) {
  return pumpUntil(
    tester,
    () => find.byType(Image).evaluate().isNotEmpty,
    timeout: timeout,
    step: step,
  );
}

/// The raw bytes of the sole [Image] widget currently in the tree, which
/// every widget in this package renders via `Image.memory`. `null` if none
/// is mounted yet.
Uint8List? renderedImageBytes(WidgetTester tester) {
  final finder = find.byType(Image);
  if (finder.evaluate().isEmpty) return null;
  final provider = tester.widget<Image>(finder).image;
  return (provider as MemoryImage).bytes;
}

/// Byte-for-byte equality, since [Uint8List] doesn't override `==`.
bool bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
