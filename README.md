Flutter widgets and adapters for [`layer_canvas`](https://pub.dev/packages/layer_canvas),
a Dart-only 2D compositing engine built on Blend2D. This package lets you
build and render `layer_canvas` scenes using only Flutter types — `Color`,
`Offset`, `Size`, `FontWeight`, `TextAlign`, `BoxFit` — instead of the core's
own `Color32`, `Point2D`/`Size2D`, `TextWeight`, `TextAlignment`, `ImageFit`.

## Features

* **`Layers`** — static factories (`rectangle`, `text`, `image`, `group`)
  that build `layer_canvas` layers from Flutter types, with an optional
  `pixelRatio` to scale a layer built in logical units to physical-pixel
  resolution.
* **`Scenes.of`** — builds a `Scene` from a `children` list instead of the
  core's mutate-after-construction `Scene(...)..add(...)..add(...)`.
* **`LayerCanvas`** — a widget that renders a `Scene` (fixed, or built from
  the widget's measured size and device pixel ratio) as an `Image`, with
  render caching, a placeholder while it's rendering, and an error builder.
* **`SceneWidget`** — `Scenes.of` + `LayerCanvas` in one widget, shaped like
  `Stack(children: [...])`, for fixed-size scenes that don't need per-build
  DPR scaling.
* **`LayerCanvasFonts`** — loads fonts declared in your app's `pubspec.yaml`
  into `layer_canvas`'s native font registry at startup, so you can turn off
  the core's embedded default font and use your own.

## Getting started

Add both packages:

```yaml
dependencies:
  layer_canvas: ^0.1.0-beta.2
  layer_canvas_flutter: ^0.1.0
```

`layer_canvas` embeds a default font (Roboto) in its native library so text
renders out of the box, at a cost of roughly 1.4 MB. Since a Flutter app
already ships its own fonts, you can turn the embed off in **your app's**
`pubspec.yaml` (this only works in the final app, not in a package):

```yaml
hooks:
  user_defines:
    layer_canvas:
      embed_default_font: false
```

Then declare a font your app uses for canvas text and preload it with
`LayerCanvasFonts` before `runApp`:

```yaml
flutter:
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
```

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LayerCanvasFonts.ensureInitialized(
    asDefault: 'Roboto',
    families: {'Roboto'}, // scopes registration to just this font
  );
  runApp(const MyApp());
}
```

See `example/` for a full app wired up this way.

## Usage

Build layers with `Layers`, a scene with `Scenes.of`, and render it with the
`LayerCanvas` widget:

```dart
LayerCanvas(
  sceneBuilder: (logicalSize, pixelRatio) {
    final physicalSize = logicalSize * pixelRatio;
    return Scenes.of(
      width: physicalSize.width,
      height: physicalSize.height,
      children: [
        Layers.rectangle(size: physicalSize, color: const Color(0xFF1E1E2E)),
        Layers.text(
          text: 'Hello, layer_canvas!',
          position: const Offset(24, 24),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w600,
          pixelRatio: pixelRatio,
        ),
      ],
    );
  },
)
```

Passing `pixelRatio` to each `Layers` factory scales its measurements
(position, size, and type-specific lengths like `cornerRadius`/`fontSize`)
together, so a scene built in logical units still rasterizes at physical-pixel
resolution.

`Layers.group` shares one transform/opacity across a set of children, so
moving, rotating or fading a cluster of layers only requires updating the
group, not every child:

```dart
Layers.group(
  position: const Offset(60, 60),
  rotation: -0.08,
  pixelRatio: pixelRatio,
  children: [
    Layers.rectangle(
      size: const Size(160, 70),
      color: const Color(0xFF4C6EF5),
      cornerRadius: 10,
      pixelRatio: pixelRatio,
    ),
    Layers.text(
      text: 'Grouped!',
      position: const Offset(16, 22),
      color: const Color(0xFFFFFFFF),
      fontSize: 20,
      fontWeight: FontWeight.w600,
      pixelRatio: pixelRatio,
    ),
  ],
)
```

### SceneWidget

`SceneWidget` combines `Scenes.of` and `LayerCanvas` in one widget shaped
like `Stack`, for fixed-size scenes whose layers you'd rather write as a
plain `children` list instead of a `sceneBuilder` callback:

```dart
SceneWidget(
  width: 300,
  height: 160,
  children: [
    Layers.rectangle(size: const Size(300, 160), color: const Color(0xFF1E1E2E)),
    Layers.text(text: 'SceneWidget', position: const Offset(24, 24)),
  ],
)
```

Unlike `LayerCanvas(scene: someStableScene)`, `SceneWidget` builds a new
`Scene` on every `build()` — there's no cheap way to tell "same content,
new list" apart from "different content" (`layer_canvas`'s `Layer` types
have no value equality). That's fine for content that changes rarely; if
`SceneWidget` sits somewhere that rebuilds often (an animation, frequent
`setState`), prefer building a `Scene` once with `Scenes.of` and passing it
to `LayerCanvas` directly, so re-renders happen only when you decide to
build a new one.

### Treat `Scene` as immutable

`LayerCanvas` re-renders when it sees a *new* `Scene` instance (or a change
in measured size/pixel ratio) — not when an existing `Scene`'s contents
change. Build a new `Scene` whenever its contents change; if you must mutate
one in place, pass a changing `rebuildKey` to force a re-render:

```dart
LayerCanvas(scene: scene, rebuildKey: generation)
```

### Escape hatch

Need the raw core types (`Color32`, `Point2D`, `TextWeight`...)? `layer_canvas`
is a normal dependency of this package, so you can always:

```dart
import 'package:layer_canvas/layer_canvas.dart';
```

## Additional information

This package only depends on `layer_canvas` and re-exports the pieces of its
API needed to use `Layers`/`LayerCanvas` (`Scene`, `Renderer`,
`RenderException`, the `Layer` subclasses, `FontRegistry`). See
[`layer_canvas`](https://pub.dev/packages/layer_canvas) for the underlying
model and rendering engine, and its known limitation that `FontRegistry`
stores a single face per font family (no real multi-weight support yet).

File issues at the [`layer_canvas`](https://github.com/code3743/layer_canvas)
repository.
