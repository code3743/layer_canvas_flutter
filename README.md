# layer_canvas_flutter

![layer_canvas_flutter — native 2D rendering for Flutter](https://raw.githubusercontent.com/code3743/layer_canvas_flutter/main/doc/hero.png)

Native 2D rendering for Flutter, using only the Flutter types you already
know. [`layer_canvas`](https://pub.dev/packages/layer_canvas) composites
typed layers to a PNG through [Blend2D](https://blend2d.com) via FFI. 
This package is the Flutter-native 
front door to it: build a scene with `Color`, `Offset`, `Gradient`, and a
`Path`-shaped builder, drop it in a widget, done.

## Quick start

```dart
LayerCanvas(
  sceneBuilder: (logicalSize, pixelRatio) => Scenes.of(
    width: logicalSize.width * pixelRatio,
    height: logicalSize.height * pixelRatio,
    children: [
      Layers.rectangle(
        size: logicalSize,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF2B2B45)],
        ),
        pixelRatio: pixelRatio,
      ),
      Layers.text(
        text: 'Hello, layer_canvas!',
        position: const Offset(24, 24),
        color: const Color(0xFFFFFFFF),
        fontSize: 22,
        fontWeight: FontWeight.w600,
        pixelRatio: pixelRatio,
      ),
    ],
  ),
)
```

That's a native Blend2D render, dropped into your widget tree like any
other `Image` — no `Color32`, no `Point2D`, nothing from the core package
imported directly. See [Usage](#usage) below for gradients, custom shapes,
SVG, and tap handling.

## Gallery

A few scenes built entirely from `Layers`/`Scenes.of`/`LayerPathBuilder` —
gradients, hand-drawn vector paths, SVG, dashed strokes, and wrapped text —
to give a sense of what a `LayerCanvas` can render.

<table>
<tr>
<td width="33%"><img src="https://raw.githubusercontent.com/code3743/layer_canvas_flutter/main/doc/gallery/gradient-burst.png" alt="Overlapping radial, linear, and sweep gradients"></td>
<td width="33%"><img src="https://raw.githubusercontent.com/code3743/layer_canvas_flutter/main/doc/gallery/vector-blob.png" alt="An organic blob drawn with LayerPathBuilder cubic and quadratic curves"></td>
<td width="33%"><img src="https://raw.githubusercontent.com/code3743/layer_canvas_flutter/main/doc/gallery/bauhaus-grid.png" alt="An abstract Bauhaus-style geometric composition"></td>
</tr>
<tr>
<td width="33%"><img src="https://raw.githubusercontent.com/code3743/layer_canvas_flutter/main/doc/gallery/svg-pattern.png" alt="A parsed SVG document placed as a scattered pattern"></td>
<td width="33%"><img src="https://raw.githubusercontent.com/code3743/layer_canvas_flutter/main/doc/gallery/constellation.png" alt="A dashed-stroke constellation/network diagram"></td>
<td width="33%"><img src="https://raw.githubusercontent.com/code3743/layer_canvas_flutter/main/doc/gallery/editorial-card.png" alt="An editorial card with wrapped text, a clipped image badge, and a gradient background"></td>
</tr>
</table>

## Features

* **`Layers`** — static factories (`rectangle`, `text`, `image`, `path`,
  `svg`, `group`) that build `layer_canvas` layers from Flutter types, with
  an optional `pixelRatio` to scale a layer built in logical units to
  physical-pixel resolution.
* **Gradients** — pass a Flutter `LinearGradient`/`RadialGradient`/
  `SweepGradient` as `Layers.rectangle`/`Layers.path`'s `gradient:`, no core
  gradient types involved.
* **Stroke cap/join/miter/dash** — `strokeCap`/`strokeJoin` (`dart:ui`'s own
  enums), `strokeMiterLimit`, and (on `Layers.path`) `dashArray`/
  `dashOffset` for a dashed stroke.
* **`clipBehavior`** — clips a sized layer to its own box, same idea as
  `Container`'s `clipBehavior`.
* **`scale`/`alignment`** — every factory's `rotation` gets a uniform
  `scale` and an `alignment` to pivot around, instead of always the center.
* **`LayerPathBuilder`** — draws a `Layers.path` shape with the same method
  names as `dart:ui`'s own `Path` (`moveTo`, `lineTo`, `cubicTo`,
  `arcToPoint`, `close`...), so it reads like drawing on a `Canvas`.
* **`Layers.svg`** — places an already-parsed `SvgDocument` as a layer.
* **`SvgLayer`** — a widget that displays an `SvgDocument` at a given
  size with a real `BoxFit` — not `SvgPicture` (that's `flutter_svg`'s
  widget; a different rendering path entirely).
* **`Scenes.of`** — builds a `Scene` from a `children` list instead of the
  core's mutate-after-construction `Scene(...)..add(...)..add(...)`.
* **`AssetImageSource`** — an image layer/background source that lazily
  loads a Flutter asset by key, resolved automatically before every render.
* **Scene persistence** — `Scene.toJson()`/`fromJson()` save and restore a
  whole scene, `AssetImageSource` included.
* **`Scenes.encode`/`Scenes.saveToFile`** — export a `Scene` to
  `png`/`bmp`/`qoi` bytes or a file, instead of displaying it.
* **`LayerCanvas`** — a widget that renders a `Scene` (fixed, or built from
  the widget's measured size and device pixel ratio) as an `Image`, with
  render caching, a placeholder while it's rendering, an error builder, and
  an `onLayerTap` to find which `Layer` was tapped.
* **`SceneWidget`** — `Scenes.of` + `LayerCanvas` in one widget, shaped like
  `Stack(children: [...])`, for fixed-size scenes that don't need per-build
  DPR scaling.
* **`LayerCanvasFonts`** — loads every declared weight of the fonts in your
  app's `pubspec.yaml` into `layer_canvas`'s native font registry at
  startup, so you can turn off the core's embedded default font and use
  your own.

## Getting started

Requires Flutter 3.27+ (for `Color.toARGB32()`, which the color adapter
relies on). Add this package — `layer_canvas` comes along transitively, so
you don't need to add it yourself, and you shouldn't need to import it
directly either: `Layers`, `Scenes.of`, `LayerCanvas` and `SceneWidget`
cover the whole surface you need from Flutter code.

```yaml
dependencies:
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

The snippets below build on [Quick start](#quick-start) above and assume:

```dart
import 'package:flutter/material.dart';
import 'package:layer_canvas_flutter/layer_canvas_flutter.dart';
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

### Gradients

Pass a Flutter `LinearGradient`, `RadialGradient`, or `SweepGradient` as
`gradient:` — same types you'd give a `BoxDecoration`:

```dart
Layers.rectangle(
  size: const Size(300, 120),
  gradient: const LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  cornerRadius: 16,
  pixelRatio: pixelRatio,
)
```

### Strokes: cap, join, miter, dash

`strokeCap`/`strokeJoin` take `dart:ui`'s own enums — the same ones a
`Paint` would — and `strokeMiterLimit` controls how far a `StrokeJoin.miter`
corner may extend before it's clamped to a bevel. `Layers.path` additionally
takes `dashArray`/`dashOffset` for a dashed stroke (only `PathLayer`s dash —
a `RectangleLayer` has no path geometry of its own to dash):

```dart
Layers.path(
  path: LayerPathBuilder()
    ..moveTo(const Offset(0, 50))
    ..lineTo(const Offset(300, 50)),
  color: const Color(0xFF4C6EF5),
  style: PaintingStyle.stroke,
  strokeWidth: 4,
  strokeCap: StrokeCap.round,
  dashArray: const [12, 8],
  pixelRatio: pixelRatio,
)
```

### Clipping with clipBehavior

`clipBehavior` (any value but the default `Clip.none`) clips a sized layer
to its own box — same idea as `Container`'s `clipBehavior`. The natural
case is cropping a `cover`-fit image, exactly like `Image` inside a clipped
box:

```dart
Layers.image(
  source: MemoryImageSource(bytes),
  size: const Size(200, 120),
  fit: BoxFit.cover,
  clipBehavior: Clip.hardEdge,
  pixelRatio: pixelRatio,
)
```

Not available on `Layers.group`/`Layers.svg`: the core expands a `Group`
into its concrete descendants before rendering, leaving no single surface
to clip — clip an individual child via its own factory instead.

### scale and alignment

Every factory's `rotation` gets two companions: `scale` (uniform) and
`alignment` (where `rotation`/`scale` pivot from — `Alignment.center` by
default, same as the core):

```dart
Layers.rectangle(
  size: const Size(80, 80),
  color: const Color(0xFFFF6B6B),
  rotation: 0.3,
  scale: 1.2,
  alignment: Alignment.topLeft, // pivot from the corner, not the center
  pixelRatio: pixelRatio,
)
```

### Custom shapes with LayerPathBuilder

`LayerPathBuilder` mirrors `dart:ui`'s `Path` — the same method names, in
the same order, so a shape you'd know how to draw in a `CustomPainter`
reads the same way here:

```dart
Layers.path(
  path: LayerPathBuilder()
    ..moveTo(const Offset(60, 0))
    ..lineTo(const Offset(120, 100))
    ..lineTo(const Offset(0, 100))
    ..close(),
  color: const Color(0xFF06D6A0),
  pixelRatio: pixelRatio,
)
```

`LayerPathBuilder.circle`/`.oval`/`.polygon`/`.polyline` cover the common
shapes without building one command at a time.

### SVG

Parse an `SvgDocument` once (it's real XML parsing — don't do it inside a
`sceneBuilder` that runs every frame) and place it with `Layers.svg`:

```dart
class _MyWidgetState extends State<MyWidget> {
  static final _logo = SvgDocument.parse(myLogoSvgSource);

  @override
  Widget build(BuildContext context) {
    return LayerCanvas(
      sceneBuilder: (logicalSize, pixelRatio) => Scenes.of(
        width: logicalSize.width * pixelRatio,
        height: logicalSize.height * pixelRatio,
        children: [
          Layers.svg(_logo, size: const Size(64, 64), pixelRatio: pixelRatio),
        ],
      ),
    );
  }
}
```

Displaying one SVG on its own (not composed with other layers) is simpler
with `SvgLayer`, the `Image.asset`-shaped widget for a single document:

```dart
class _MyIconState extends State<MyIcon> {
  static final _logo = SvgDocument.parse(myLogoSvgSource);

  @override
  Widget build(BuildContext context) => SvgLayer(_logo, width: 48, height: 48);
}
```

`SvgLayer` is not `flutter_svg`'s `SvgPicture` — same idea (display a
parsed SVG at a size, with a `BoxFit`), different rendering path entirely
(this one goes through `layer_canvas`'s native Blend2D renderer). `fit`
here is real Flutter box-fitting (`FittedBox`), not something
`layer_canvas` does natively: a `Group` (what a placed `SvgDocument` is)
has no native crop/cover concept to clip against, so `SvgLayer` rasterizes
the document at its own natural size and lets Flutter's ordinary layout
scale/position that result, the same way it would any other
fixed-aspect-ratio child.

### Word-wrap

`Layers.text` word-wraps into a `size` with a width set — greedily,
breaking only at spaces (a single word wider than the box overflows on its
own line rather than being split mid-word) — and the wrapped block is
vertically centered within `size`'s height:

```dart
Layers.text(
  text: 'A longer caption that should wrap across a few lines.',
  size: const Size(220, 80),
  fontSize: 16,
  pixelRatio: pixelRatio,
)
```

Leave `size` unset (or give it no width) for a single, possibly overflowing
line — the same as before this existed.

### Tap handling with onLayerTap

`LayerCanvas.onLayerTap` reports which `Layer` (if any) was under a tap,
using the core's `hitTestScene`:

```dart
LayerCanvas(
  scene: scene,
  onLayerTap: (layer, localPosition) {
    if (layer?.id == 'submit-button') {
      submit();
    }
  },
)
```

It's a bounding-box test against each layer's own `size` (not its exact
painted shape — a circular `PathLayer` hit-tests as its bounding square),
and a layer with no explicit `size` (intrinsic sizing, e.g. an unset-size
`TextLayer`) never matches, since its true rendered bounds are only known
to the native backend once it's actually laid out. Give an interactive
layer an explicit `size` if it needs to receive taps. Coordinates are
mapped through `fit`, so this works whether the widget's box matches the
scene's own aspect ratio or not.

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

### Saving and loading a Scene

`Scene` round-trips through JSON as-is — `toJson()`/`fromJson` recurse
through every layer, paint, gradient, transform, and image source:

```dart
final json = jsonEncode(scene.toJson());
// ...later, or on another device:
final restored = Scene.fromJson(jsonDecode(json) as Map<String, Object?>);
```

For an image that should serialize as a short asset key instead of a
base64 blob, use `AssetImageSource` instead of `ImageSources.asset`
(which reads the bytes immediately):

```dart
Layers.image(
  source: AssetImageSource('assets/logo.png'),
  size: const Size(120, 40),
)
```

Every widget in this package resolves an `AssetImageSource` against the
ambient `AssetBundle` right before rendering, and its `LayerRegistry`
decoder is registered automatically the first time one is built or
deserialized — no setup call needed.

### Exporting a Scene

Every widget in this package always displays a `Scene` as PNG. To export
one instead — to a file, or as bytes in another format — use `Scenes`:

```dart
final pngBytes = await Scenes.encode(scene); // png by default
await Scenes.saveToFile(scene, '/path/to/export.qoi', format: OutputFormat.qoi);
```

Both resolve any `AssetImageSource` in `scene` first, same as `LayerCanvas`.

## Additional information

This package only depends on `layer_canvas` and re-exports only the pieces
of its API that this package's own public API surfaces as parameters or
return types: `Scene`, `Layer` and its subclasses (`RectangleLayer`,
`TextLayer`, `ImageLayer`, `PathLayer`, `Group`), `LayerImageSource` (with
`FileImageSource`/`MemoryImageSource`), `SvgDocument`/`SvgParseException`,
`Renderer`/`RenderException`, `OutputFormat`,
`FontRegistry`/`FontRegistrationException`, and `LayerRegistry` (with its
`LayerFromJson`/`ImageSourceFromJson` typedefs, for registering a custom
`Layer`/`LayerImageSource` subclass of your own). Value types the core
exposes that `Layers` and the adapters exist specifically to shield you
from (`Color32`, `Point2D`/`Size2D`, `TextWeight`, `TextAlignment`,
`ImageFit`, `LayerPaint`, `LayerTransform`, `FillRule`, the core's own
`StrokeCap`/`StrokeJoin`, and its `Gradient`/`LinearGradient`/
`RadialGradient`/`ConicGradient`, which would otherwise collide with
Flutter's own same-named types) are intentionally not re-exported —
building UI with this package should never require importing
`package:layer_canvas` directly.

See [`layer_canvas`](https://pub.dev/packages/layer_canvas) and its
[repository](https://github.com/code3743/layer_canvas) for the underlying
model and rendering engine.
