# Responsive Animations

Responsive design is a broad topic, so this page focuses on how Elm Motion keeps animations aligned when layout changes.

Elm Motion supports three responsive animation workflows:

1. **Relative CSS units** - re-evaluated by the browser as layout changes
2. **Snap Re-Anchoring** - snap to a given state when the layout changes
3. **Measured pixel targets** - proportional remapping on resize ([`Sub`](../engines/sub.md) and [`WAAPI`](../engines/waapi.md) only)

You can mix all strategies on the same page for different animations.

---

## Path 1 - Relative Units

The browser re-evaluates relative CSS units as layout changes. Express your animation in those units and resize behaviour comes for free - no subscriptions, no measurement, no remapping.

Elm Motion exposes the full set of relative units through [`Anim.Unit`](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Unit):

- element / font units - `Percent`, `Em`, `Rem`, `Lh`, `Ch`, ...
- viewport units - `Vw`, `Vh`, `Vi`, `Vb`, `Vmin`, `Vmax`, plus `Sv*` / `Lv*` / `Dv*` variants
- container units - `Cqi`, `Cqb`, `Cqw`, `Cqh`, `Cqmin`, `Cqmax`

??? example "View Source Code"

    ```elm
    dropBall : AnimBuilder eng -> AnimBuilder eng
    dropBall =
        Translate.for "ball"
            >> Translate.cssUnit Cqh
            >> Translate.fromY 0
            >> Translate.toY 88
            >> Translate.speed 75
            >> Translate.easing BounceOut
            >> Translate.build
    ```

    `1cqh` is `1%` of the nearest containment context's block size, so the ball drops 88% of the container's height regardless of how the container is sized, and it travels at 75% of the height per second. If you change `cssUnit`, adjust the numeric values accordingly.

For working examples see:

- [Controlling Animations](controlling-animations.md#example)
- [Interrupting Animations](interrupting-animations.md#multiple-properties)
- [Transform Order](transform-order.md)

---

## Path 2 - Snap Re-Anchoring

Use this any time you need to snap an animtion to a new state instantly, for example if a user action invalidates a running animation and you need to end it and move it to a new state.

`retarget` is available on:

- [`Transition`](../engines/transition.md)
- [`Keyframe`](../engines/keyframes.md)
- [`Sub`](../engines/sub.md)
- [`WAAPI`](../engines/waapi.md)

=== "Transition / Keyframe / Sub"

    ```elm
    TriggerLayoutChanged ->
        ( { model | animState = Engine.retarget model.animState newLayoutTarget }
        , Cmd.none
        )
    ```

=== "WAAPI"

    ```elm
    TriggerLayoutChanged ->
        let
            ( animState, animCmd ) =
                WAAPI.retarget model.animState newLayoutTarget
        in
        ( { model | animState = animState }
        , animCmd
        )
    ```

For `Sub` and `WAAPI`, if you retarget only some `Translate` axes, untouched axes can keep their existing interpolation. The touched target still snaps to the new correct value.

---

## Path 3 - Measured Pixel Values

Use this path when your animation depends on direct pixel values, it is supported by the [`Sub`](../engines/sub.md) and [`WAAPI`](../engines/waapi.md) engines via their `onResize` function.

When a resize message arrives, hand the engine the updated pixel ranges via `onResize`.

=== "Sub"

    ```elm
    import Anim.Engine.Sub as SubEngine
    import Anim.Property.Translate as Translate

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            OnResize w h ->
                ( { model
                    | animState =
                        SubEngine.onResize model.animState <|
                            Translate.bounds "cookieQuestionsAnim" (cookieBounds w h model)
                                >> Translate.bounds "modalAnim" (modalBounds w h)
                  }
                , Cmd.none
                )
    ```

=== "WAAPI"

    ```elm
    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Translate as Translate

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            OnResize w h ->
                let
                    ( animState, animCmd ) =
                        WAAPI.onResize model.animState <|
                            Translate.bounds "cookieQuestionsAnim" (cookieBounds w h model)
                                >> Translate.bounds "modalAnim" (modalBounds w h)
                in
                ( { model | animState = animState }
                , animCmd
                )
    ```

The bounds builder itself is engine-agnostic:

```elm
cookieBounds : Int -> Int -> Model -> { x : Maybe { min : Float, max : Float }, y : Maybe { min : Float, max : Float }, z : Maybe { min : Float, max : Float } }
cookieBounds w h model =
    { x = Just { min = 0, max = toFloat w }
    , y = Just { min = toFloat h - model.cqHeight, max = toFloat h }
    , z = Nothing
    }
```

Compose as many `bounds` updates into the `onResize` call as you need - one call per resize event covers every affected anim group.

---

## Responsive Tooling

Most animations only need one of the two paths above. If you need more control, these are the main tools to reach for.

| Function | Where | What it helps with |
| --- | --- | --- |
| `onResize` | [Sub](../engines/sub.md), [WAAPI](../engines/waapi.md) | Apply resize updates to active and idle animations. |
| `retarget` | [Transition](../engines/transition.md), [Keyframe](../engines/keyframes.md), [Sub](../engines/sub.md), [WAAPI](../engines/waapi.md) | Re-anchor elements immediately when a layout change makes the old target wrong. |
| `bounds` | [Translate](../properties/translate.md), [Scale](../properties/scale.md), [PerspectiveOrigin](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-PerspectiveOrigin#bounds) | Set min/max property bounds during `onResize`. |
| `clampX`, `clampY`, `clampZ` | [Translate](../properties/translate.md), [Rotate](../properties/rotate.md), [Scale](../properties/scale.md), [Skew](../properties/skew.md) | Keep animated values inside safe limits. |
| `clampWidth`, `clampHeight` | [Size](../properties/size.md) | Keep animated width and height inside safe limits. |
| `clamp`, `unclamp` | [Opacity](../properties/opacity.md), [Custom](../properties/custom-property.md) | Add or remove value limits as needed. |

Values are interpreted in the active CSS unit for each property, and updates apply only to the anim group(s) you target.

Start simple with relative units or measured pixels. Reach for these tools only when you need extra control.

---

## Engine Guidance

- [Transition](../engines/transition.md) and [Keyframe](../engines/keyframes.md) - use relative units. No `onResize` is exposed; re-render attributes if you need measured-pixel updates.
- [Sub](../engines/sub.md) and [WAAPI](../engines/waapi.md) - use relative units when you can. Reach for `onResize` with the `bounds` setter on the relevant property module when you need measured-pixel targets.
- [ScrollTimeline](../engines/scroll-timeline.md) and [ViewTimeline](../engines/view-timeline.md) - relative units are the responsive path.

---

## Next Steps

[Engines Overview](../engines/overview.md){ .md-button .md-button--primary }
[Controlling Animations](controlling-animations.md){ .md-button .md-button--primary }
