# Responsive Animations

Responsive design is a broad topic, so this page focuses on how Elm Motion keeps animations aligned when layout changes.

Elm Motion supports three responsive animation workflows:

1. **Relative CSS units** - re-evaluated by the browser as layout changes
2. **Snap Re-Anchoring** - snap to a given state when the layout changes
3. **Measured pixel targets** - proportional remapping on resize ([`Sub`](../engines/sub.md) and [`WAAPI`](../engines/waapi.md) only)

You can mix all strategies on the same page for different animations, or even for different properties or axes in the same animation group.

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
        Translate.begin
            >> Translate.cssUnit Cqh
            >> Translate.fromY 0
            >> Translate.toY 88
            >> Translate.speed 75
            >> Translate.easing BounceOut
            >> Translate.end
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

The Sub and WAAPI engines have access to mid-flight values, so untouched properties/axes can continue on their way untouched, as intended.

Mid-flight values are not available for CSS transitions or @keframes animations, so untouched properties/axes can't be reconfigured when mid-flight. Therefore they snap to their targeted end state to ensure they finish correctly and as intended.



---

## Path 3 - Measured Pixel Values

Use this path when your animation depends on direct pixel values, it is supported by the [`Sub`](../engines/sub.md) and [`WAAPI`](../engines/waapi.md) engines.

Unlike relative values which the browser can re-evaluate when the layout changes, pixel values remain fixed, so animations using pixel values need to be told about the layout change.

This is done by giving the Engine the new bounds for the animation. The bounds represent the space on the page the animation can operate in. All supporting properties have their own `bounds` builder function which takes a `Bounds` record - which is then passed to the Engine's `onResize` function:

??? example "View Source Code"
    === "Sub"

        ```elm
        import Anim.Property.Translate exposing (AxisBounds)

        bounds : AxisBounds
        bounds =
            { x = Nothing
            , y = Nothing
            , z = Nothing
            }

        OnResize w h ->
            let
                max =
                    case getOrientation w h of
                        Portrait ->
                            50

                        Landscape ->
                            100
            in
            ( { model
                | animState =
                    Sub.onResize model.animState <|
                        Translate.bounds "logoAnim" { bounds | x = Just {min = 0, max = max} }
                }
            , Cmd.none
            )
        ```

    === "WAAPI"

        ```elm
        import Anim.Property.Translate exposing (AxisBounds)

        bounds : AxisBounds
        bounds =
            { x = Nothing
            , y = Nothing
            , z = Nothing
            }

        OnResize w h ->
            let
                max =
                    case getOrientation w h of
                        Portrait ->
                            50

                        Landscape ->
                            100

                ( animState, animCmd ) =
                    WAAPI.onResize model.animState <|
                        Translate.bounds "logoAnim" { bounds | x = Just {min = 0, max = max} }
            in
            ( { model | animState = animState }
            , animCmd
            )
        ```

    When switching from Portrait to Landscape, the `logoAnim` animation group will adjust it's position on the X axis proportionally. So if it is at `x=25` in Portrait (50% of the width) and the user switches to Landscape, it will be remapped to `x=50` (50% of the new width), and it's X axis end value will be remapped to `x=100`, the new `max`.

`bounds` can only be paired with `onResize`, attempting to use it with a Trigger function like `animate` will produce a type error.

---

## Responsive Tooling

| Function | Where | What it helps with |
| --- | --- | --- |
| `retarget` | [Transition](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Transition#retarget), [Keyframe](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Keyframe#retarget), [Sub](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Sub#retarget), [WAAPI](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-WAAPI#retarget) | Re-anchor elements immediately when a layout change makes the old target wrong. |
| `onResize` | [Sub](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Sub#onResize), [WAAPI](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-WAAPI#onResize) | Apply new bounds to active and idle animations after a layout change. |
| `bounds` | [Translate](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Translate#bounds), [Scale](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Scale#bounds), [PerspectiveOrigin](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-PerspectiveOrigin#bounds), [Size](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Size#bounds) | Set min/max property bounds after a layout change. |
| `clamp*` | [Translate](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Translate#clampX), [Rotate](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Rotate#clampX), [Scale](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Scale#clampX), [Skew](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Skew#clampX), [Opacity](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Opacity#clamp), [Custom](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Custom#clamp) | Keep animated values inside safe limits. |
| `unclamp*` | [Translate](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Translate#unclampX), [Rotate](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Rotate#unclampX), [Scale](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Scale#unclampX), [Skew](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Skew#unclampX), [Opacity](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Opacity#unclamp), [Custom](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Property-Custom#unclamp) | Remove animation limits. |

---

## Next Steps

[Engines Overview](../engines/overview.md){ .md-button .md-button--primary }
[Controlling Animations](controlling-animations.md){ .md-button .md-button--primary }
