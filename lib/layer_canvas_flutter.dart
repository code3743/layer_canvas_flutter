/// Flutter widgets and adapters for the `layer_canvas` 2D compositor.
///
/// Re-exports only the `layer_canvas` core types this package's own public
/// API surfaces as parameters or return types (`Scene`, the `Layer`
/// subclasses, `SvgDocument`, `Renderer`...), plus this package's
/// Flutter-typed adapters, layer factories, font loader and render widget.
/// Value types that `Layers` and the adapters exist specifically to shield
/// callers from (`Color32`, `Point2D`/`Size2D`, `TextWeight`,
/// `TextAlignment`, `ImageFit`, `LayerPaint`, `LayerTransform`, `FillRule`,
/// and the core's own `Gradient`/`LinearGradient`/`RadialGradient`/
/// `ConicGradient`, which would otherwise collide with Flutter's own
/// same-named gradient types) are intentionally *not* re-exported here —
/// building UI with this package should never require importing
/// `package:layer_canvas` directly.
library;

export 'package:layer_canvas/layer_canvas.dart'
    show
        Scene,
        Layer,
        Group,
        RectangleLayer,
        TextLayer,
        ImageLayer,
        PathLayer,
        LayerImageSource,
        FileImageSource,
        MemoryImageSource,
        Renderer,
        RenderException,
        FontRegistry,
        FontRegistrationException,
        SvgDocument,
        SvgParseException;

export 'src/adapters/color_adapter.dart';
export 'src/adapters/geometry_adapter.dart';
export 'src/adapters/gradient_adapter.dart';
export 'src/adapters/image_adapter.dart';
export 'src/adapters/path_adapter.dart';
export 'src/adapters/text_adapter.dart';
export 'src/fonts/layer_canvas_fonts.dart';
export 'src/layers/layers.dart';
export 'src/paths/layer_path_builder.dart';
export 'src/scenes/scenes.dart';
export 'src/widgets/layer_canvas_widget.dart';
export 'src/widgets/scene_widget.dart';
export 'src/widgets/svg_layer.dart';
