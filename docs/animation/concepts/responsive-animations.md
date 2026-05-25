# Responsive Animations

Responsive design is a broad topic, so this page focuses on how Elm Motion keeps animations aligned when layout changes.

Elm Motion supports two responsive animation workflows:

1. measured pixel targets, updated on resize
2. relative CSS units, re-evaluated by the browser as layout changes

You can mix both strategies on the same page for different animations, and can also switch strategies during the lifetime of the page.

---

## Path 1 - Measured Pixel Values

Use this path when your animations depend on measured pixel layout, or need to remain at, or be constrained to fixed pixel values.

This path is supported by the [Sub](../engines/sub.md), [WAAPI](../engines/waapi.md), [Transition](../engines/transition.md) and
[Keyframe](../engines/keyframes.md) engines, but behaviour differs slightly.

- Sub & WAAPI: mid-flight animations remap proportionally to new resized values, idle animations re-position proportionally inside their container.
- Transition and Keyframe: no proportional remap API for resize updates. For engine-specific responsive strategies, see [Transition](../engines/transition.md) and [Keyframe](../engines/keyframes.md).

### Workflow

#### Step 1 - Listen for resize

Use `Browser.Events.onResize` to listen for layout changes.

??? example "Example: subscribe to resize events"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.batch
            [ Browser.Events.onResize OnResize
            , ... -- other subscriptions
            ]
    ```

#### Step 2 - Update the animation bounds

When a resize happens, give the engine the updated pixel bounds.

??? example "Example: measure the track again"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            OnResize w h ->
                (  handleResize (toFloat w) (toFloat h) model
                , Cmd.none
                )

    handleResize : Float -> Float -> Model -> Model
    handleResize w h model =
        let
            cookieBounds =
                { x = Just { min = 0, max = w }
                , y = Just { min = h - model.cqHeight, max = h }
                , z = Nothing
                }

            modalBounds =
                { x = Just { min = 0, max = w }
                , y = Just { min = 0, max = h }
                , z = Nothing 
                }

        in
        { model
            | animState =
                AnimEngine.onResize model.animState <|
                    Translate.bounds "cookieQuestionsAnim" cookieBounds
                        >> Translate.bounds "modalAnim" modalBounds
        }
    ```

Any time the pixel range changes, tell the engine the new range for every affected anim group. The engine keeps the animations aligned with the new bounds.

---

## Path 2 - Using Relative Units

Follow this path when your targets use relative positioning inside their parent container. This is the quickest and simplest path, but it helps to have a good understanding of the various [CSS relative length units](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/length).

Elm Motion supports a broad set of relative units through [`Anim.Unit`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Unit), including element/font units (`Percent`, `Em`, `Rem`, `Lh`, `Ch`, etc.), viewport units (`Vw`, `Vh`, `Vi`, `Vb`, `Vmin`, `Vmax` plus `Sv*`/`Lv*`/`Dv*` variants), and container units (`Cqi`, `Cqb`, `Cqw`, `Cqh`, `Cqmin`, `Cqmax`).

When your animation can be expressed in those units, the browser re-evaluates values as layout changes. That means the animation stays responsive without resize subscriptions, DOM measurement, or remapping logic.

This works well when the motion should scale naturally with the layout - for example, moving something across half a container or positioning something relative to viewport or container size.

Relative units are the best fit when:

- you want the browser to handle responsiveness for you
- your animation values can be expressed without measuring layout in Elm

??? example "Example: responsive animation with relative units"

    ```elm
    dropBall : AnimBuilder mode -> AnimBuilder mode
    dropBall =
        Translate.for "ball"
            >> Translate.cssUnit Cqh
            >> Translate.fromY 0
            >> Translate.toY 88
            >> Translate.speed 75
            >> Translate.easing BounceOut
            >> Translate.build
    ```

Animation-wise, that’s the full setup. It assumes the surrounding view/layout is already responsive.

In the example code, the unit values (0, 88, 75) are effectively percentage values of the element being animated's container height. `1cqh == 1%` of the container height.
If you change the CSS Unit, be sure to adjust your builder values accordingly.

To see this in action check out the following examples:

- [Controlling Animations](controlling-animations.md#example)
- [Interrupting Animations](interrupting-animations.md#multiple-properties)
- [Transform Order](transform-order.md)

---

## Responsive Tooling

Most animations only need one of the two paths above. If you need more control, these are the main tools to reach for.

| Function | Where | What it helps with |
| --- | --- | --- |
| `retarget` | [Sub](../engines/sub.md), [WAAPI](../engines/waapi.md), [Transition](../engines/transition.md), [Keyframe](../engines/keyframes.md) | Change target while an animation is running. Sub and WAAPI continue smoothly; Transition and Keyframe snap to the new end value. |
| `onResize` | [Sub](../engines/sub.md), [WAAPI](../engines/waapi.md) | Apply resize updates to active animations. |
| `bounds` | [Anim.Resize](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Resize#bounds), [Translate](../properties/translate.md), [Scale](../properties/scale.md) | Set min/max movement ranges after a resize. |
| `position` | [Translate](../properties/translate.md) | Set explicit x/y/z positions after a resize. |
| `clampX`, `clampY`, `clampZ` | [Translate](../properties/translate.md), [Rotate](../properties/rotate.md), [Scale](../properties/scale.md), [Skew](../properties/skew.md) | Keep animated values inside safe limits. |
| `clampWidth`, `clampHeight` | [Size](../properties/size.md) | Keep animated width and height inside safe limits. |
| `clamp`, `unclamp` | [Opacity](../properties/opacity.md), [Custom](../properties/custom-property.md) | Add or remove value limits as needed. |


Note: Values are interpreted in the active CSS unit for each property, and updates apply only to the anim group(s) you target.

Start simple with relative units or measured pixels. Reach for these tools only when you need extra control.

---

## Engine Guidance

- [Transition](../engines/transition.md) and [Keyframe](../engines/keyframes.md): use relative units for responsive behavior.
- [Sub](../engines/sub.md) and [WAAPI](../engines/waapi.md): use relative units when you can, and use `onResize` with [`Anim.Resize.bounds`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Resize#bounds) when you need measured pixel targets.
- [ScrollTimeline](../engines/scroll-timeline.md) and [ViewTimeline](../engines/view-timeline.md): relative units are the responsive path.

---

## Next Steps

[Engines Overview](../engines/overview.md){ .md-button .md-button--primary }
[Controlling Animations](controlling-animations.md){ .md-button .md-button--primary }
