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

`retarget` will stop the animation and snap it to the new state. It is available on:

- [`Transition`](../engines/transition.md)
- [`Keyframe`](../engines/keyframes.md)
- [`Sub`](../engines/sub.md)
- [`WAAPI`](../engines/waapi.md)

??? example "View Source Code"

    === "Transition"

        ```elm
        TriggerLayoutChanged ->
            ( { model | animState = Transition.retarget model.animState newLayoutTarget }
            , Cmd.none
            )
        ```


    === "Keyframe"

        ```elm
        TriggerLayoutChanged ->
            ( { model | animState = Keyframe.retarget model.animState newLayoutTarget }
            , Cmd.none
            )
        ```


    === "Sub"

        ```elm
        TriggerLayoutChanged ->
            ( { model | animState = Sub.retarget model.animState newLayoutTarget }
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

### How each engine behaves

`retarget` only touches what your builder mentions. Anything you don't mention is left alone - but what "left alone" looks like depends on the engine:

- **Transition** and **Keyframe** - untouched properties/axes snap to their targeted end state. If you retarget only the Y axis of a `Translate` animation, and the X axis is also animating, the Y axis snaps to the targeted value, while the X axis snaps to it's end target value.
- **Sub** and **WAAPI** - untouched values *keep animating* along their existing curve. Retargeting only Y snaps Y while X carries on toward its original target uninterrupted.

### Example

Press **Animate diagonally**, then mid-flight press **Retarget Y to 0** - the builder only mentions the Y axis. Watch what the X axis does:

- `Transition` and `Keyframe` - X snaps to it's end value - the right edge.
- `Sub` and `WAAPI` - X keeps gliding toward the right edge.

??? example "View Example"
    === "Transition"

        <iframe src="../../examples/src/Animation/Transition/Retarget/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Keyframe"

        <iframe src="../../examples/src/Animation/Keyframe/Retarget/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../examples/src/Animation/Sub/Retarget/index.html" class="example-iframe" loading="lazy"></iframe>

    === "WAAPI"

        <iframe src="../../examples/src/Animation/WAAPI/Retarget/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Source Code"
    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Animation/Transition/Retarget/Main.elm"
        ```

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/Retarget/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/Retarget/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/Retarget/Main.elm"
        ```

#### Why the difference?

Mid-flight values are not available for CSS transitions or @keframes animations, so they snap to their targeted end state to ensure they finish correctly.

The Sub and WAAPI engines do have access to mid-flight values, so untouched properties/axes can continue on their way untouched, as intended.


---

## Path 3 - Measured Pixel Values

Use this path when your animation depends on direct pixel values, it is supported by the [`Sub`](../engines/sub.md) and [`WAAPI`](../engines/waapi.md) engines.

Unlike relative values which the browser can reinterpret when the layout changes, pixel values remain fixed, so animations using pixel values need to be told about the layout change.

This is done by giving the Engine the new bounds for the animation. The bounds represent the space on the page the animation can operate in and the animation will adjust proportionally.

The bounds are just a simple record:

```elm

```



Imagine a `Translate` animation is looping between `x=0` and `x=100`, and the animation is at `x=50` when the user flips from landscape to portrait. You might want to reduce the width the animation takes up, lets say, to `50px` so that the animation moves between `x=0` and `x=50`.

To do this you'd just set new bounds on the X axis: `{ bounds | x = Just {min = 0, max = 50} }`

When a resize message arrives, hand the new bounds to the Engine's `onResize` function.

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
