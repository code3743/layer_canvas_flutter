## 0.1.0-beta.1

Initial release.

* `Layers`: static factories (`rectangle`, `text`, `image`, `path`, `svg`,
  `group`) that build `layer_canvas` layers from Flutter types (`Color`,
  `Offset`, `Size`, `FontWeight`, `TextAlign`, `BoxFit`, `Gradient`,
  `PathFillType`) instead of the core's
  `Color32`/`Point2D`/`TextWeight`/`FillRule`. Every factory takes an
  optional `pixelRatio` so layers built in logical units land at
  physical-pixel resolution without scaling each measurement by hand.
* `Layers.rectangle`/`Layers.path` accept a `gradient:` — a Flutter
  `LinearGradient`, `RadialGradient`, or `SweepGradient` — converted via the
  new `GradientX.toLayerGradient()` to the core's `LinearGradient`/
  `RadialGradient`/`ConicGradient` (added in `layer_canvas` 0.1.0-beta.3).
* `LayerPathBuilder`: builds a `PathLayer`'s vector geometry with the same
  method names and shapes as `dart:ui`'s own `Path` (`moveTo`, `lineTo`,
  `quadraticBezierTo`, `cubicTo`, `arcToPoint`, `close`, plus `.polygon`/
  `.polyline`/`.circle`/`.oval` factories), so drawing a `Layers.path` shape
  reads the same as drawing one in a `CustomPainter`.
* `Layers.svg`: places an already-`SvgDocument.parse`d document as a group,
  with the same `position`/`size`/`pixelRatio` shape as every other
  `Layers` factory.
* `SvgLayer`: a widget that displays an `SvgDocument` at a given
  `width`/`height` with a real `BoxFit` (via Flutter's own `FittedBox` —
  `layer_canvas` has no native crop/cover for a vector group). Not named
  `SvgPicture` on purpose: that's `package:flutter_svg`'s widget, and the
  two render through entirely different paths.
* `LayerCanvas.onLayerTap`: reports the topmost `Layer` under a tap, via
  the core's new `hitTestScene` (`layer_canvas` 0.1.0-beta.4). Coordinates
  are mapped through `fit` (via `applyBoxFit`), so this is correct whether
  the widget's box matches the scene's own aspect ratio or not. A
  bounding-box test against each layer's `size` (not its exact painted
  shape), and a layer with no explicit `size` never matches — see
  `hitTestScene`'s own doc comment for the precise contract.
* `Scenes.of`: builds a `Scene` from a `children` list instead of the core's
  mutate-after-construction `Scene(...)..add(...)..add(...)`.
* `LayerCanvas`: a widget that renders a `Scene` — fixed, or built via
  `sceneBuilder(logicalSize, pixelRatio)` — scaled for the device pixel
  ratio, with the render `Future` cached by scene identity/size/pixel
  ratio/`rebuildKey`, and `placeholderBuilder`/`errorBuilder` hooks.
* `SceneWidget`: a thin wrapper over `Scenes.of` + `LayerCanvas` shaped like
  a Flutter layout widget (`SceneWidget(width:, height:, children: [...])`,
  similar to `Stack`) for fixed-size scenes that don't need per-build DPR
  scaling. Rebuilds its `Scene` on every `build()` — no render caching
  across rebuilds, unlike a `LayerCanvas` given a stable `scene:`.
* `LayerCanvasFonts`: loads fonts declared in the app's `pubspec.yaml` into
  the native `FontRegistry` at startup (`ensureInitialized`), optionally
  scoped to a `families` allow-list, so an app can turn off
  `layer_canvas`'s embedded default font
  (`hooks.user_defines.layer_canvas.embed_default_font: false`) and preload
  its own font instead. Now registers **every** declared weight of a
  family (via `FontRegistry`'s `weight:` param from 0.1.0-beta.3), not just
  its first face — italic faces are skipped, since `FontRegistry` has no
  italic/upright concept to register them under.
* Adapters (`ColorX`, `OffsetX`/`SizeX`, `FontWeightX`/`TextAlignX`,
  `BoxFitX`, `PathFillTypeX`, `GradientX`/`TileModeX`/`AlignmentGeometryX`,
  `ImageSources`) converting between Flutter and `layer_canvas` core types,
  exported for advanced/manual use.
* Requires `layer_canvas: ^0.1.0-beta.4` (was `^0.1.0-beta.2`).
