/// Flutter widgets and adapters for the `layer_canvas` 2D compositor.
///
/// Re-exports only the `layer_canvas` core types this package's own public
/// API surfaces as parameters or return types (`Scene`, the `Layer`
/// subclasses, `Renderer`...), plus this package's Flutter-typed adapters,
/// layer factories, font loader and render widget. Value types that
/// `Layers` and the adapters exist specifically to shield callers from
/// (`Color32`, `Point2D`/`Size2D`, `TextWeight`, `TextAlignment`,
/// `ImageFit`, `LayerPaint`, `LayerTransform`...) are intentionally *not*
/// re-exported here — code that genuinely needs them can still `import
/// 'package:layer_canvas/layer_canvas.dart'` directly, since it's a normal
/// (non-dev) dependency of this package.
library;

export 'package:layer_canvas/layer_canvas.dart'
    show
        Scene,
        Layer,
        Group,
        RectangleLayer,
        TextLayer,
        ImageLayer,
        LayerImageSource,
        FileImageSource,
        MemoryImageSource,
        Renderer,
        RenderException,
        FontRegistry,
        FontRegistrationException;

export 'src/adapters/color_adapter.dart';
export 'src/adapters/geometry_adapter.dart';
export 'src/adapters/image_adapter.dart';
export 'src/adapters/text_adapter.dart';
export 'src/fonts/layer_canvas_fonts.dart';
export 'src/layers/layers.dart';
export 'src/scenes/scenes.dart';
export 'src/widgets/layer_canvas_widget.dart';
export 'src/widgets/scene_widget.dart';
