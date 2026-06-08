# Sub Engine

This page is a practical guide to using the Sub engine.
Read [Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

The Sub Engine uses Elm subscriptions to update animation state on every frame. This provides full programmatic control over animations, including mid-flight queries and mid-flight redirections.

## Example

Animation control - use the buttons to control the bouncing ball animation.

??? example "View Example"

    --8<-- "docs/animation/concepts/controlling-animations/drop-the-ball/sub.md:example"

??? example "View Source Code"

    --8<-- "docs/animation/concepts/controlling-animations/drop-the-ball/sub.md:code"



---

## Quick Walkthrough

Here's a general workflow to get up an running quickly.

### 1. Build

??? example "View Source Code"

    ```elm
    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity


    fadeIn : Sub.AnimBuilder eng -> Sub.AnimBuilder eng
    fadeIn =
        Sub.for "card"
            >> Opacity.begin
            >> Opacity.to 1
            >> Opacity.duration 350
            >> Opacity.end
    ```

### 2. Initialize

??? example "View Source Code"

    ```elm
    type alias Model =
        { animState : Sub.AnimState }


    init : ( Model, Cmd Msg )
    init =
        ( { animState = Sub.init [ Opacity.init "card" 0 ] }
        , Cmd.none
        )
    ```

### 3. Render

Render animation attributes on the element being animated.

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        div []
            [ button [ onClick TriggerFadeIn ] [ text "Fade In" ]
            , div (Sub.attributes "card" model.animState) [ text "Animated card" ]
            ]
    ```

### 4. Trigger with `animate`

Call `animate` to apply the animation config to the current `AnimState`.

??? example "View Source Code"

    ```elm
    TriggerFadeIn ->
        ( { model | animState = Sub.animate model.animState fadeIn }
        , Cmd.none
        )
    ```

### 5. React


Use `update` for incoming Sub events.

??? example "View Source Code"

    ```elm
    type Msg
        = TriggerFadeIn
        | GotAnimMsg Sub.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( animState, events ) =
                        Sub.update animMsg model.animState
                in
                ( List.foldl handleAnimEvent { model | animState = animState } events
                , Cmd.none 
                )

            _ ->
                ( model, Cmd.none )


    handleAnimEvent : Sub.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimEvent event model =
        case event of
            Sub.Ended "card" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState

    ```
---

## In Detail

### Initialize

Pass a list of property initializers to `init`. Each registers an animation group name and sets the element's starting inline style from the first render.

??? example "View Source Code"

    ```elm
    init : ( Model, Cmd Msg )
    init =
        ( { animState = Sub.init [ Opacity.init "ball" 0 ] }
        , Cmd.none
        )
    ```

📖 See [Initialize](../workflow/init.md) for more info.

### Trigger

Call `animate` to apply an animation to the current `AnimState`.

??? example "View Source Code"

    ```elm
    TriggerDrop ->
        ( { model | animState = Sub.animate model.animState dropBall }
        , Cmd.none
        )
    ```

📖 See [Triggering Animations](../workflow/trigger.md) for more info.

### Mid-Flight Interruptions

Sub keeps frame-by-frame runtime state, so interrupting with a new animation continues smoothly from the current in-flight position.

📖 See [Interrupting Animations](../concepts/interrupting-animations.md) for more info.

### OnLoad Animations

For on-load animations, trigger `animate` when the page initializes, the animation runs immediately.

### Update

Use `update` to process incoming animation messages. It returns the updated `AnimState` and a list of any events that occurred during that frame.

??? example "View Source Code"

    ```elm
    GotAnimMsg animMsg ->
        let
            ( animState, events ) =
                Sub.update animMsg model.animState
        in
        List.foldl handleAnimEvent ( { model | animState = animState }, Cmd.none ) events
    ```

### Events

`update` returns a `List AnimEvent` per call — multiple events can occur in a single frame. Use `List.foldl` to process them.

Every event carries the animation group name. Some events carry an additional value:

- `Cancelled` and `Paused` include the progress at the moment of cancellation/pause (`Float`, 0.0–1.0)
- `Iteration` includes the iteration count (`Int`)
- `Progress` fires every frame with the current progress (`Float`, 0.0–1.0)

??? example "View Source Code"

    ```elm
    handleAnimEvent : AnimEvent -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
    handleAnimEvent event ( model, cmd ) =
        case event of
            Started "ball" ->
                ( model, cmd )

            Ended "ball" ->
                ( model, cmd )

            Cancelled "ball" _ ->
                ( model, cmd )

            Progress "ball" progress ->
                ( { model | ballProgress = progress }, cmd )

            _ ->
                ( model, cmd )
    ```

| Event | Fires when... |
| ----- | ------------- |
| `Started` | Animation begins playing |
| `Ended` | Animation completes |
| `Cancelled` | Animation is interrupted by something outside the engine's control. |
| `Iteration` | Each iteration completes (looping or alternating) |
| `Progress` | Every frame while the animation is running |
| `Paused` | `pause` is called on a running animation |
| `Resumed` | `resume` is called on a paused animation |
| `Restarted` | `restart` is called |

### Subscriptions

The Sub engine requires a subscription to receive animation frame updates. The subscription is dormant when no animations are active.

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotAnimMsg model.animState
    ```

📖 See [React](../workflow/react.md) for more info.

### View

Apply `attributes` to the animated element to apply the current inline styles on each frame.

??? example "View Source Code"

    ```elm
    div (Sub.attributes "ball" model.animState) [ text "Ball" ]
    ```

📖 See [Render](../workflow/render.md) for more info.

### Responsive Strategy

Use relative CSS units whenever the motion can be defined in layout-relative terms.

For measured pixel targets, Sub supports proportional remap for resize updates. Therefore:

- On resize, update bounds with `onResize` and `Translate.bounds` / `Scale.bounds` / `PerspectiveOrigin.bounds`.
- Running animations remap to the equivalent relative position inside the updated bounds.
- Idle animations also re-position proportionally inside the updated bounds.

📖 See [Responsive Animations](../concepts/responsive-animations.md) for more info.

### Playback

Set `iterations`, `loopForever`, and `alternate` in the animation builder.

??? example "View Source Code"

    ```elm
    spinForever =
        Sub.loopForever
            >> Sub.alternate
            >> Sub.for "icon"
            >> Rotate.begin
            >> Rotate.toZ 360
            >> Rotate.duration 1000
            >> Rotate.end
    ```

📖 See [Playback](../concepts/playback.md) for the full `looping`, `iterations`, and `alternate` API with live examples.

### Timing

Set the default `duration`, `speed`, and `delay`. Inherited by every property that doesn't override them.

- `duration` — animation length in milliseconds.
- `speed` — alternative to `duration`; set a rate in property units per second.
- `delay` — wait before the animation begins, in milliseconds.

??? example "View Source Code"

    ```elm
    fadeIn =
        Sub.delay 500
            >> Sub.duration 800
            >> Sub.for "card"
            >> Opacity.begin
            >> Opacity.to 1
            >> Opacity.end
    ```

📖 See [Timing](../concepts/timing.md) for more info.

### Easing

Sub animations use the full Easing library with exact mathematical curves — including bounce and elastic.

Set the default easing for all properties that don't override it:

??? example "View Source Code"

    ```elm
    fadeIn =
        Sub.easing CubicInOut
            >> Sub.for "card"
            >> Opacity.begin
            >> Opacity.to 1
            >> Opacity.duration 300
            >> Opacity.delay 50
            >> Opacity.end
    ```

📖 See [Easing](../concepts/easing.md) for all available easing functions.

### Spring

Sub animations evaluate the spring's analytic solution every frame — exact damped-harmonic-oscillator motion with no sampling.

Set the default spring for all properties that don't override it: The motion ends when each value has settled at the target — there is no explicit duration.

??? example "View Source Code"

    ```elm
    bouncyReveal =
        Sub.spring Spring.wobbly
            >> Sub.for "card"
            >> Opacity.begin
            >> Opacity.to 1
            >> Opacity.end
    ```

📖 See [Spring](../concepts/spring.md) for the full preset list and tuning guidance.

### Controls

| Function | Description |
| -------- | ----------- |
| `stop` | Jump to end state |
| `reset` | Jump to start state |
| `restart` | Reset and begin playing again |
| `pause` | Freeze at current position |
| `resume` | Continue from paused position |

??? example "View Source Code"

    ```elm
    Stop ->
        ( { model | animState = Sub.stop "card" model.animState }, Cmd.none )

    Reset ->
        ( { model | animState = Sub.reset "card" model.animState }, Cmd.none )
    Restart ->
        ( { model | animState = Sub.restart "card" model.animState }, Cmd.none )

    Pause ->
        ( { model | animState = Sub.pause "card" model.animState }, Cmd.none )
    Resume ->
        ( { model | animState = Sub.resume "card" model.animState }, Cmd.none )

    ```


📖 See [Controlling Animations](../concepts/controlling-animations.md) for more info.

### Discrete Properties

The Sub engine manages discrete properties as inline styles. `discreteEntry` values are applied from the first animation frame, and `discreteExit` values flip on the last frame. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

### Transform Order

Use `transformOrder` to set the order in which transform properties are applied for the next animation.

??? example "View Source Code"

    ```elm
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    animateBox =
        Sub.transformOrder [ Scale, Rotate, Translate ]
            >> Sub.for "box"
            >> Translate.begin
            >> ...
    ```

📖 See [Transform Order](../concepts/transform-order.md) for full details.

### Freeze Axes

Freeze one or more transform axes so they stop updating during subsequent frames, while the rest of the animation continues.

??? example "View Source Code"

    ```elm
    Sub.animate model.animState <|
        Sub.freezeX [ Sub.translate ]
            >> Sub.for "box"
            >> Translate.begin
            >> Translate.toY 0
            >> Translate.end
    ```

📖 See [Freezing Axes with `freeze*`](../concepts/interrupting-animations.md#freezing-axes-with-freeze) for more info.

### State Queries

Query animation state.

??? example "View Source Code"

    ```elm
    Sub.anyRunning model.animState           -- Maybe Bool
    Sub.isRunning "ball" model.animState     -- Maybe Bool
    Sub.allComplete model.animState          -- Maybe Bool
    Sub.isComplete "ball" model.animState    -- Maybe Bool
    Sub.isCancelled "ball" model.animState   -- Maybe Bool
    Sub.getProgress "ball" model.animState   -- Maybe Float (0.0–1.0)
    ```

`Nothing` is returned when no animation exists for the given group.

### Property Queries

Because the Sub engine updates on every frame, current values are always accessible.

All query functions follow the same pattern:

- `get[Property]Start`, and return `Maybe [PropertyValue]`.
- `get[Property]Current`, and return `Maybe [PropertyValue]`.
- `get[Property]End`, and return `Maybe [PropertyValue]`

??? example "View Source Code"

    ```elm
    Sub.getOpacityStart "ball" model.animState      -- Maybe Float
    Sub.getOpacityCurrent "ball" model.animState    -- Maybe Float
    Sub.getOpacityEnd "ball" model.animState        -- Maybe Float
    Sub.getTranslateStart "ball" model.animState    -- Maybe { x, y, z }
    Sub.getTranslateCurrent "ball" model.animState  -- Maybe { x, y, z }
    Sub.getTranslateEnd "ball" model.animState      -- Maybe { x, y, z }
    ```

`Nothing` is returned when no animation exists for the given group.

### When to Choose This Engine

Choose Sub when you want maximum Elm-side control with per-frame updates and current-value access.

- Best for: gameplay-style interactions, simulation-like motion, and logic that reacts continuously to animation progress.
- Avoid when: you prefer browser-native animation execution with less Elm runtime work.

### API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder eng` | Carries all animation configurations |
| `AnimMsg` | Messages from animation frame subscription |
| `AnimEvent` | Events returned by `update` |
| `AnimGroupName` | `String` type alias for the animation group name |
| `TransformProperty` | Custom transform ordering |
| `FreezeProperty` | Axis to freeze (`Translate`, `Rotate`, `Scale`, `Skew`) |

### Initialize

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `List (AnimBuilder eng -> AnimBuilder eng) -> AnimState` | Create initial animation state |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `AnimState -> (AnimBuilder eng -> AnimBuilder eng) -> AnimState` | Apply an animation to the current state |

### Events

| Event | Description |
| ----- | ----------- |
| `Started AnimGroupName` | Animation begins playing |
| `Ended AnimGroupName` | Animation completes |
| `Cancelled AnimGroupName Float` | Animation cancelled; `Float` is progress at cancellation |
| `Restarted AnimGroupName` | Animation is restarted |
| `Paused AnimGroupName Float` | Animation paused; `Float` is progress at pause |
| `Resumed AnimGroupName` | Animation resumed |
| `Iteration AnimGroupName Int` | Loop iteration completes; `Int` is iteration count |
| `Progress AnimGroupName Float` | Each frame; `Float` is current progress (0.0–1.0) |

### Update

| Function | Type | Description |
| -------- | ---- | ----------- |
| `update` | `AnimMsg -> AnimState -> ( AnimState, List AnimEvent )` | Process messages and return events |

### Subscriptions

| Function | Type | Description |
| -------- | ---- | ----------- |
| `subscriptions` | `(AnimMsg -> msg) -> AnimState -> Sub msg` | Animation frame subscription |

### View

| Function | Type | Description |
| -------- | ---- | ----------- |
| `attributes` | `AnimGroupName -> AnimState -> List (Html.Attribute msg)` | Get animation attributes for an element |

### Playback

| Function | Type | Description |
| -------- | ---- | ----------- |
| `iterations` | `Int -> AnimBuilder eng -> AnimBuilder eng` | Set number of iterations |
| `loopForever` | `AnimBuilder eng -> AnimBuilder eng` | Loop animation infinitely |
| `alternate` | `AnimBuilder eng -> AnimBuilder eng` | Reverse direction on each iteration |

### Timing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `duration` | `Int -> AnimBuilder eng -> AnimBuilder eng` | Set duration (ms) |
| `speed` | `Float -> AnimBuilder eng -> AnimBuilder eng` | Set speed (property units/sec) |
| `delay` | `Int -> AnimBuilder eng -> AnimBuilder eng` | Set delay before animation starts (ms) |

### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> AnimBuilder eng -> AnimBuilder eng` | Set easing function |

### Spring

| Function | Type | Description |
| -------- | ---- | ----------- |
| `spring` | `Spring -> AnimBuilder eng -> AnimBuilder eng` | Set spring physics |

### Controls

| Function | Type | Description |
| -------- | ---- | ----------- |
| `stop` | `AnimGroupName -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `AnimGroupName -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `AnimGroupName -> AnimState -> AnimState` | Reset and begin playing again |
| `pause` | `AnimGroupName -> AnimState -> AnimState` | Freeze at current position |
| `resume` | `AnimGroupName -> AnimState -> AnimState` | Continue from paused position |

### Discrete Properties

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder eng -> AnimBuilder eng` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder eng -> AnimBuilder eng` | Set a CSS property value during and after the animation |

### Transform Order

| Function | Type | Description |
| -------- | ---- | ----------- |
| `transformOrder` | `List TransformProperty -> AnimBuilder eng -> AnimBuilder eng` | Set custom transform order |

### Freeze Axes

| Function | Type | Description |
| -------- | ---- | ----------- |
| `freeze` | `AnimGroupName -> List FreezeProperty -> AnimState -> AnimState` | Freeze the specified axes |
| `unfreeze` | `AnimGroupName -> List FreezeProperty -> AnimState -> AnimState` | Unfreeze the specified axes |

### State Queries

| Function | Type | Description |
| -------- | ---- | ----------- |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any animation is running |
| `isRunning` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group's animation is complete |
| `isCancelled` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group's animation was cancelled |
| `getProgress` | `AnimGroupName -> AnimState -> Maybe Float` | Get current progress (0.0–1.0) |

### Property Queries

| Function | Type | Description |
| -------- | ---- | ----------- |
| `getOpacityStart` | `AnimGroupName -> AnimState -> Maybe Float` | Get start opacity |
| `getOpacityEnd` | `AnimGroupName -> AnimState -> Maybe Float` | Get end opacity |
| `getOpacityCurrent` | `AnimGroupName -> AnimState -> Maybe Float` | Get current opacity |
| `getTranslateStart` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get start translate |
| `getTranslateEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end translate |
| `getTranslateCurrent` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get current translate |
| `getRotateStart` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get start rotate |
| `getRotateEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end rotate |
| `getRotateCurrent` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get current rotate |
| `getScaleStart` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get start scale |
| `getScaleEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end scale |
| `getScaleCurrent` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get current scale |
| `getSizeStart` | `AnimGroupName -> AnimState -> Maybe { width, height }` | Get start size |
| `getSizeEnd` | `AnimGroupName -> AnimState -> Maybe { width, height }` | Get end size |
| `getSizeCurrent` | `AnimGroupName -> AnimState -> Maybe { width, height }` | Get current size |
| `getSkewStart` | `AnimGroupName -> AnimState -> Maybe { x, y }` | Get start skew |
| `getSkewEnd` | `AnimGroupName -> AnimState -> Maybe { x, y }` | Get end skew |
| `getSkewCurrent` | `AnimGroupName -> AnimState -> Maybe { x, y }` | Get current skew |
| `getPropertyStart` | `AnimGroupName -> String -> AnimState -> Maybe Float` | Get start value for a custom numeric property |
| `getPropertyEnd` | `AnimGroupName -> String -> AnimState -> Maybe Float` | Get end value for a custom numeric property |
| `getPropertyCurrent` | `AnimGroupName -> String -> AnimState -> Maybe Float` | Get current value for a custom numeric property |
| `getColorPropertyStart` | `AnimGroupName -> String -> AnimState -> Maybe Color` | Get start value for a custom color property |
| `getColorPropertyEnd` | `AnimGroupName -> String -> AnimState -> Maybe Color` | Get end value for a custom color property |
| `getColorPropertyCurrent` | `AnimGroupName -> String -> AnimState -> Maybe Color` | Get current value for a custom color property |

`Nothing` is returned when no animation exists for the given group.

For complete API details, see the [Anim.Engine.Sub](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Sub) documentation.

### Next Steps

The WAAPI Engine provides all of the features of the Transition, Keyframe, and Sub engines combined, with native browser control.

[WAAPI Engine →](waapi.md){ .md-button .md-button--primary }

Or explore the fire-and-forget timeline engines:

[Scroll Timeline Engine →](scroll-timeline.md){ .md-button .md-button--primary }
Or
[View Timeline Engine →](view-timeline.md){ .md-button .md-button--primary }
