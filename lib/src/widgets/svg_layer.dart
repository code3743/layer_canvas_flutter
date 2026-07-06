import 'package:flutter/widgets.dart';
import 'package:layer_canvas/layer_canvas.dart';

import '../adapters/geometry_adapter.dart';
import '../layers/layers.dart';
import '../scenes/scenes.dart';
import 'layer_canvas_widget.dart';

/// Displays an already-[SvgDocument.parse]d document as a widget, scaled
/// into its box with a real [BoxFit] — the SVG equivalent of `Image.asset`.
///
/// Not named `SvgPicture` on purpose: that's `package:flutter_svg`'s own
/// widget, and the two aren't interchangeable (this one renders through
/// `layer_canvas`'s native Blend2D path, not `flutter_svg`'s `dart:ui`
/// one) — `SvgLayer` instead, matching this package's own naming for
/// layer-shaped things (`RectangleLayer`, `TextLayer`, `ImageLayer`,
/// `PathLayer`).
///
/// [fit] is real Flutter box-fitting (via [FittedBox]), not something
/// `layer_canvas` does natively — unlike [ImageLayer]'s `fit`, a
/// [SvgDocument] placed as a [Group] has no native crop/cover concept
/// (there's nothing to clip a vector group against), so this widget
/// rasterizes the document at its own natural size and lets Flutter's
/// ordinary layout fit that result into the box, the same way it would fit
/// any other fixed-aspect-ratio child.
///
/// ```dart
/// class _MyIconState extends State<MyIcon> {
///   static final _logo = SvgDocument.parse(myLogoSvgSource);
///
///   @override
///   Widget build(BuildContext context) {
///     return SvgLayer(_logo, width: 48, height: 48);
///   }
/// }
/// ```
class SvgLayer extends StatelessWidget {
  const SvgLayer(
    this.document, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.renderer = const Renderer(),
    this.placeholderBuilder,
    this.errorBuilder,
  });

  /// The parsed document to display. Parse it once (real XML work) and
  /// reuse the result — see [Layers.svg] for why.
  final SvgDocument document;

  /// The widget's box. `null` lets that axis size to [document]'s own
  /// natural size (from its `viewBox`/`width`/`height`), same as
  /// `Image`'s `width`/`height`.
  final double? width;
  final double? height;

  /// How [document] is fit into the box — see the class doc comment for
  /// why this is Flutter's own box-fitting, not a native one.
  final BoxFit fit;
  final AlignmentGeometry alignment;

  /// The renderer used to rasterize the document.
  final Renderer renderer;

  /// Shown while the scene is rendering. Defaults to an empty box.
  final WidgetBuilder? placeholderBuilder;

  /// Shown if rendering throws (e.g. a [RenderException]).
  final Widget Function(BuildContext context, Object error, StackTrace stackTrace)?
      errorBuilder;

  @override
  Widget build(BuildContext context) {
    final natural = document.naturalSize?.toSize();
    final resolvedSize = _resolveSize(natural);

    return SizedBox.fromSize(
      size: resolvedSize,
      child: FittedBox(
        fit: fit,
        alignment: alignment,
        child: SizedBox.fromSize(
          // The FittedBox's child is laid out at the document's own
          // natural aspect ratio (falling back to resolvedSize when there
          // is none to preserve) and then scaled/positioned by FittedBox
          // to fit resolvedSize per [fit] — the same two-step Image itself
          // does internally.
          size: natural ?? resolvedSize,
          child: LayerCanvas(
            sceneBuilder: (logicalSize, pixelRatio) => Scenes.of(
              width: logicalSize.width * pixelRatio,
              height: logicalSize.height * pixelRatio,
              children: [Layers.svg(document, size: logicalSize, pixelRatio: pixelRatio)],
            ),
            renderer: renderer,
            placeholderBuilder: placeholderBuilder,
            errorBuilder: errorBuilder,
          ),
        ),
      ),
    );
  }

  /// Resolves this widget's own definite box size: [width]/[height] when
  /// both are given; either one combined with [natural]'s aspect ratio when
  /// only one is given (matching how `Image` derives a missing dimension
  /// from the image's own aspect ratio); [natural] itself when neither is
  /// given. Throws [ArgumentError] if none of the three sources leaves a
  /// size fully determined.
  Size _resolveSize(Size? natural) {
    if (width != null && height != null) return Size(width!, height!);
    if (natural == null) {
      throw ArgumentError(
        'SvgLayer: document has no naturalSize (no viewBox/width/height in '
        'its source), so width and height must both be given explicitly.',
      );
    }
    if (width != null) return Size(width!, width! * natural.height / natural.width);
    if (height != null) return Size(height! * natural.width / natural.height, height!);
    return natural;
  }
}
