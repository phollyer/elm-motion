# API Reference

The complete API documentation is available on the official Elm package repository:

[**View Full API Documentation →**](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/){ .md-button .md-button--primary }

## Module Overview

### Core

| Module | Description |
| -------- | ------------- |
| [Anim.Builder](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Builder) | `AnimBuilder eng` type for reusable animations |

### Engines

| Module | Description |
| -------- | ------------- |
| [Anim.Engine.Transition](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Transition) | CSS transitions for A→B animations |
| [Anim.Engine.Keyframe](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Keyframe) | CSS keyframe animations for complex animations |
| [Anim.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Sub) | Subscription-based frame animations |
| [Anim.Engine.WAAPI](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-WAAPI) | Web Animations API via ports |
| [Anim.Engine.ScrollTimeline](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-ScrollTimeline) | Fire-and-forget scroll-driven animations |
| [Anim.Engine.ViewTimeline](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-ViewTimeline) | Fire-and-forget view-driven animations |
| [Scroll.Engine.Cmd](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Scroll-Engine-Cmd) | Fire-and-forget scrolling |
| [Scroll.Engine.Task](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Scroll-Engine-Task) | Composable scrolling with error handling |
| [Scroll.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Scroll-Engine-Sub) | Stateful scrolling with full control |

### Properties

| Module | Description |
| -------- | ------------- |
| [Anim.Property.Translate](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Translate) | Position/movement animations |
| [Anim.Property.Rotate](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Rotate) | Rotation animations |
| [Anim.Property.Scale](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Scale) | Scale/zoom animations |
| [Anim.Property.Skew](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Skew) | Skew/shear animations |
| [Anim.Property.Opacity](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Opacity) | Fade animations |
| [Anim.Property.Size](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Size) | Width/height animations |
| [Anim.Property.Custom](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Custom) | Numeric CSS property animations |
| [Anim.Property.CustomColor](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-CustomColor) | Color CSS property animations |

### Utilities

| Module | Description |
| -------- | ------------- |
| [Motion.Easing](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Motion-Easing) | Easing functions |
| [Motion.Spring](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Motion-Spring) | Spring physics presets and custom configuration |
| [Anim.Extra.Color](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Extra-Color) | Color utilities |
| [Anim.Extra.View3D](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Extra-View3D) | 3D perspective helpers |

## Common Patterns

### Animation Builder Signature

Reusable animation builders follow this pattern:

```elm
myAnimation : AnimBuilder eng -> AnimBuilder eng
```

This makes them composable with `>>` and reusable across engines.

### Engine Trigger Pipelines

State-tracked engines with pure Elm state updates (`Transition`, `Keyframe`, `Sub`) use this shape:

```elm
Engine.animate animState <|
    Engine.for "anim-group"
        >> myAnimation
```

`WAAPI` is state-tracked but returns both updated state and a `Cmd msg`:

```elm
let
    ( newAnimState, animCmd ) =
        WAAPI.animate model.animState <|
            WAAPI.for "anim-group"
                >> myAnimation
in
( { model | animState = newAnimState }, animCmd )
```

Timeline engines (`ScrollTimeline`, `ViewTimeline`) are fire-and-forget and return a `Cmd msg` directly:

```elm
ScrollTimeline.animate motionCmd Document myAnimation

ViewTimeline.animate motionCmd myAnimation
```

### Property Builder Pattern

All properties follow this pattern:

```elm
Engine.for "element-id"
    >> Property.begin
    >> Property.from startValue
    >> Property.to endValue
    >> Property.duration ms
    >> Property.easing easing
    >> Property.end
```
