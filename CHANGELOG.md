## 0.1.0

Initial release.

* `Layers`: static factories (`rectangle`, `text`, `image`, `group`) that build
  `layer_canvas` layers from Flutter types (`Color`, `Offset`, `Size`,
  `FontWeight`, `TextAlign`, `BoxFit`) instead of the core's
  `Color32`/`Point2D`/`TextWeight`. Every factory takes an optional
  `pixelRatio` so layers built in logical units land at physical-pixel
  resolution without scaling each measurement by hand.
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
  its own font instead.
* Adapters (`ColorX`, `OffsetX`/`SizeX`, `FontWeightX`/`TextAlignX`,
  `BoxFitX`, `ImageSources`) converting between Flutter and `layer_canvas`
  core types, exported for advanced/manual use.
