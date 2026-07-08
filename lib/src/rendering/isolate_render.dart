import 'dart:isolate';
import 'dart:typed_data';

import 'package:layer_canvas/layer_canvas.dart';

/// Runs [renderer].render(scene, format:) on a fresh background isolate via
/// [Isolate.run], instead of on the calling isolate.
///
/// The core `layer_canvas` package's own `Renderer.render` runs the native
/// call synchronously under the hood — it's plain Dart with no opinion on
/// whether its caller has a UI thread to protect, so it doesn't pay
/// isolate-spawn overhead on every call for a benefit only some callers
/// need. Every widget/helper in this package that renders calls this
/// instead, so Flutter's UI isolate stays free to keep building/laying
/// out/painting frames while a (possibly large) scene rasterizes, instead
/// of blocking on it like any other synchronous, CPU-bound Dart call would.
///
/// Safe to run off-isolate because `@Native` symbol resolution is
/// isolate-group-wide (no per-isolate library re-init needed) and the
/// native backend keeps no rendering state shared across calls — the one
/// piece of process-global native state, the font registry, is already
/// guarded by a mutex on both the write path
/// (`FontRegistry.register`/`unregister`) and the read path a render
/// exercises internally.
Future<Uint8List> renderOffMainIsolate(
  Renderer renderer,
  Scene scene, {
  OutputFormat format = OutputFormat.png,
}) {
  return Isolate.run(() => renderer.render(scene, format: format));
}

/// Like [renderOffMainIsolate], but writes straight to [path] — see
/// [Renderer.renderToFile].
Future<void> renderToFileOffMainIsolate(
  Renderer renderer,
  Scene scene,
  String path, {
  OutputFormat format = OutputFormat.png,
}) {
  return Isolate.run(
    () => renderer.renderToFile(scene, path, format: format),
  );
}
