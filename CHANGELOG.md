## 0.1.0

Targets `layer_canvas: ^0.1.0` (was `^0.1.0-beta.4`) and surfaces everything the
core gained since — still with only Flutter types.

* **Stroke cap/join/miter/dash** — `Layers.rectangle`/`Layers.path` gain
  `strokeCap`/`strokeJoin`/`strokeMiterLimit`, using `dart:ui`'s own
  `StrokeCap`/`StrokeJoin`; `Layers.path` additionally accepts
  `dashArray`/`dashOffset` (scaled by `pixelRatio` like every other length),
  since dashing only applies to a `PathLayer`'s stroke in the core.
* **`clipBehavior`** — `Layers.rectangle`/`text`/`image`/`path` accept a
  `Clip clipBehavior` (any value but `Clip.none` clips the layer to its
  `size`), mapping to the core's `Layer.clipToBounds`. Not on `Layers.group`/
  `Layers.svg`: the core expands a `Group` into its concrete descendants
  before rendering, leaving no single surface to clip.
* **`scale`/`alignment`** — every `Layers` factory now accepts `scale`
  (uniform, via the core's `LayerTransform.scale`) and `alignment` (via the
  existing `AlignmentGeometryX.toFractionalPoint2D()`, so `rotation`/`scale`
  can pivot around a corner instead of the center), alongside `position`/
  `rotation`.
* **Word-wrap** — `Layers.text` word-wraps into a `size` with a width set
  (greedily, only at spaces), vertically centered within `size`'s height —
  no new parameter, this was already reachable, just newly documented.
* **Exact `FontWeight` mapping** — `FontWeightX.toTextWeight()` now uses the
  core's `TextWeight.fromValue` (added in `layer_canvas` 0.1.0-beta.6) for an
  exact 1:1 conversion, instead of snapping to the nearest of 7 named
  constants.
* **`AssetImageSource`** — a `LayerImageSource` that lazily loads a Flutter
  asset by key (optionally from a `package`) instead of eagerly reading bytes
  like `ImageSources.asset`, so it's cheap to build ahead of time and
  compact to serialize (a short string instead of a base64 blob). Every
  widget in this package (and the new `Scenes.encode`/`saveToFile`) resolves
  it against the ambient `AssetBundle` before rendering; registers its own
  `LayerRegistry` decoder automatically, so `Scene.fromJson` reconstructs it
  too.
* **Scene persistence** — `Scene.toJson()`/`Scene.fromJson()` (added in
  `layer_canvas` 0.1.0-beta.6) work as-is through this package's re-exported
  `Scene`; only documented here, no new API.
* **Export** — `Scenes.encode(scene, {format})` and
  `Scenes.saveToFile(scene, path, {format})` rasterize a `Scene` to
  `png`/`bmp`/`qoi` bytes or a file (via the re-exported `OutputFormat`),
  resolving any `AssetImageSource` first — for exporting a scene instead of
  displaying it, which every widget still does as PNG.
* Re-exports `OutputFormat` and `LayerRegistry` (+ its `LayerFromJson`/
  `ImageSourceFromJson` typedefs) alongside the previously re-exported core
  types.
* **Rendering never blocks the UI isolate** — `LayerCanvas`, `SceneWidget`,
  `SvgLayer`, and `Scenes.encode`/`saveToFile` now run the native render
  call on a background isolate internally (`renderOffMainIsolate`), instead
  of on the calling isolate. The core `layer_canvas` package's own
  `Renderer.render` stays synchronous-under-the-hood on purpose — it's
  plain Dart with no UI thread to protect, so a CLI/batch consumer isn't
  charged isolate-spawn overhead for a benefit only a Flutter app needs;
  this package is where that trade makes sense, so it's where the offload
  lives.

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
