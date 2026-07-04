import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

/// Converts a Flutter [BoxFit] to the core's [ImageFit].
///
/// [ImageFit] only has fill/contain/cover/none: [BoxFit.fitWidth] and
/// [BoxFit.fitHeight] approximate to `cover`, and [BoxFit.scaleDown]
/// approximates to `contain`.
extension BoxFitX on BoxFit {
  ImageFit toImageFit() {
    switch (this) {
      case BoxFit.fill:
        return ImageFit.fill;
      case BoxFit.contain:
      case BoxFit.scaleDown:
        return ImageFit.contain;
      case BoxFit.cover:
      case BoxFit.fitWidth:
      case BoxFit.fitHeight:
        return ImageFit.cover;
      case BoxFit.none:
        return ImageFit.none;
    }
  }
}

/// Builds core [LayerImageSource]s from Flutter image sources.
abstract final class ImageSources {
  /// Loads an asset (declared in the app's `pubspec.yaml`) as image bytes.
  static Future<LayerImageSource> asset(
    String key, {
    AssetBundle? bundle,
  }) async {
    final data = await (bundle ?? rootBundle).load(key);
    return MemoryImageSource(_bytesOf(data));
  }

  /// Encodes a decoded [ui.Image] (e.g. from a `dart:ui` canvas) to PNG bytes.
  static Future<LayerImageSource> fromImage(
    ui.Image image, {
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    final data = await image.toByteData(format: format);
    if (data == null) {
      throw StateError('Failed to encode ui.Image to bytes');
    }
    return MemoryImageSource(_bytesOf(data));
  }
}

Uint8List _bytesOf(ByteData data) =>
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
