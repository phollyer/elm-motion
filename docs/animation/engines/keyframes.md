# CSS Keyframe Engine

This page is a practical guide to using the Keyframe engine.
Read [Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

This Engine builds native browser CSS `@keyframes` animations. The browser handles all rendering, providing excellent performance.

## Example

A dot in the middle of the screen that pulses by scaling and fading in and out - looping forever and alternating direction on each iteration.

??? example "View Example"

    --8<-- "docs/animation/first-animations/pulsing-dot/keyframe.md:example"

??? example "View Source Code"

    --8<-- "docs/animation/first-animations/pulsing-dot/keyframe.md:code"



---

## Quick Walkthrough

Here's a general workflow to get up an running quickly.

### 1. Build

??? example "View Source Code"

    ```elm
    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity


    fadeIn : Keyframe.AnimBuilder mode -> Keyframe.AnimBuilder mode
    fadeIn =
        Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.duration 300
            >> Opacity.build
    ```

### 2. Initialize

??? example "View Source Code"

    ```elm
    type alias Model =
        { animState : Keyframe.AnimState }


    init : ( Model, Cmd Msg )
    init =
        ( { animState = Keyframe.init [ Opacity.init "card" 0 ] }
        , Cmd.none
        )
    ```

### 3. Render

Render the generated `@keyframes` style node, element attributes and event listeners.

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        div []
            [ Keyframe.styleNodeFor "card" model.animState
            , div 
                (Keyframe.attributes "card" model.animState
                    ++ Keyframe.events GotAnimMsg
                )
                [ text "Animated card" ]
            ]
    ```

### 4. Trigger with `animate`

Call `animate` to apply the animation config to the current `AnimState`.

??? example "View Source Code"

    ```elm
    TriggerFadeIn ->
        ( { model | animState = Keyframe.animate model.animState fadeIn }
        , Cmd.none
        )
    ```

### 5. React

Use `update` for incoming Keyframe events.

??? example "View Source Code"

    ```elm
    type Msg
        = TriggerFadeIn
        | GotAnimMsg Keyframe.AnimMsg


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotAnimMsg animMsg ->
                let
                    ( animState, event ) =
                        Keyframe.update animMsg model.animState
                in
                ( { model | animState = animState }, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```
---

## In Detail

### Initialize

Pass a list of property initializers to `init`. Each registers an animation group name and sets the element's starting inline style from the first render.

??? example "View Source Code"

    ```elm
    init : ( Model, Cmd Msg )
    init =
        ( { animState = Keyframe.init [ Opacity.init "card" 0 ] }
        , Cmd.none
        )
    ```

📖 See [Initialize](../workflow/init.md) for more info.

### Trigger

Call `animate` to apply an animation to the current `AnimState`.

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            TriggerFadeIn ->
                ( { model | animState = Keyframe.animate model.animState fadeIn }
                , Cmd.none
                )
    ```

📖 See [Triggering Animations](../workflow/trigger.md) for more info.

### Mid-Flight Interruptions

Mid-flight values are not available for `@keyframes` animations, which means triggering with `animate` while an animation is running cancels the current animation and replaces it with the new one. This will cause a jump in state from wherever the animation was, to the start state of the new animation.

📖 See [Interrupting Animations](../concepts/interrupting-animations.md) for more info.

### OnLoad Animations

For on-load animations, trigger `animate` when the page initializes, the animation runs immediately.

### Update

Use `update` to process incoming keyframe messages. It returns the updated `AnimState` and the corresponding `AnimEvent`.

??? example "View Source Code"

    ```elm
    GotAnimMsg animMsg ->
        let
            ( animState, event ) =
                Keyframe.update animMsg model.animState
        in
        ( handleEvent event { model | animState = animState }, Cmd.none )
    ```

### Events

`update` returns a single `AnimEvent` per call.

DOM events (`Started`, `Ended`, `Cancelled`, `Iteration`) carry three values:

- the `id` (if one exists) of the element that fired the event (`CurrentTargetId`),
- the `id` (if one exists) of the element that owns the listener (`TargetId`), and,
- the animation group name.

`Iteration` carries an additional iteration count (`Int`).

In most cases only the group name is needed. `CurrentTargetId` and `TargetId` may or may not be the same depending on whether the event has bubbled up.

Synthetic events (`Paused`, `Resumed`, `Restarted`) are generated by the engine when the corresponding control functions are called, and carry only the animation group name.

??? example "View Source Code"

    ```elm
    handleAnimEvent : Keyframe.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimEvent event model =
        case event of
            Keyframe.Ended _ _ "card" ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )
    ```

| Event | Fires when... |
| ----- | ------------- |
| `Started` | Animation begins playing |
| `Ended` | Animation completes |
| `Cancelled` | Animation is cancelled before completing |
| `Iteration` | Each iteration completes (looping or alternating) |
| `Paused` | `pause` is called on a running animation |
| `Resumed` | `resume` is called on a paused animation |
| `Restarted` | `restart` is called |

📖 See [React](../workflow/react.md) for more info.

### View

Apply `attributes` to the animated element and include `styleNode` in your view to inject the generated `@keyframes` CSS rules.

??? example "View Source Code"

    ```elm
    view : Model -> Html Msg
    view model =
        div []
            [ Keyframe.styleNode model.animState
            , div (Keyframe.attributes "card" model.animState) [ text "Animated card" ]
            ]
    ```

Use `styleNodeFor` to inject rules for a single group.

!!! tip "Positioning the style node"
    Keyframe animations restart whenever the browser re-renders their `<style>` node.

    Place `styleNode` in a stable part of your DOM — ideally near the root, outside any conditionally-rendered elements or frequently-updating regions.

### Event Listeners

Apply `events` alongside `attributes` to attach the DOM animation event listeners that drive `update`.

??? example "View Source Code"

    ```elm
    div
        (Keyframe.attributes "card" model.animState
            ++ Keyframe.events GotAnimMsg
        )
        [ text "Card" ]
    ```

Use `eventsStopPropagation` to prevent events from bubbling to parent elements.

📖 See [Render](../workflow/render.md) for more info.

### Responsive Strategy

Use relative CSS units whenever the motion can be defined in layout-relative terms and the Browser does the work.

For measured pixel targets, Keyframe has no proportional remap API for resize updates because mid-flight values are not available. Therefore:

- On resize, recompute pixel targets and re-position with `retarget`.
- The animation instantly moves to the `retarget`ed position and stops.
- Idle animations stay at their last resolved value until you trigger a new target with `retarget`.

📖 See [Responsive Animations](../concepts/responsive-animations.md) for more info.

### Playback

Set `iterations`, `loopForever`, and `alternate` in the animation builder.

??? example "View Source Code"

    ```elm
    spinForever =
        Keyframe.loopForever
            >> Keyframe.alternate
            >> Rotate.for "icon"
            >> Rotate.toZ 360
            >> Rotate.duration 1000
            >> Rotate.build
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
        Keyframe.delay 500
            >> Keyframe.duration 800
            >> Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.build
    ```

📖 See [Timing](../concepts/timing.md) for more info.

### Easing

Keyframe animations support the full Easing library, including bounce and elastic. Complex curves are sampled into densely-spaced `@keyframes` stops, and the browser interpolates linearly between them — visually faithful to the source curve.

Set the default easing for all properties that don't override it:

??? example "View Source Code"

    ```elm
    fadeIn =
        Keyframe.easing CubicInOut
            >> Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.duration 300
            >> Opacity.delay 50
            >> Opacity.build
    ```

📖 See [Easing](../concepts/easing.md) for all available easing functions.

### Spring

Keyframe animations support springs. The spring's motion is pre-baked into densely-spaced `@keyframes` stops, and the browser interpolates linearly between them — visually faithful to the analytic solution.

The motion ends when each value has settled at the target according to the spring settings — there is no explicit duration, therefore any `duration` or `speed` settings on the builder are ignored.

Set the default spring for all properties that don't override it:

??? example "View Source Code"

    ```elm
    bouncyReveal =
        Keyframe.spring Spring.wobbly
            >> Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.build
    ```

📖 See [Spring](../concepts/spring.md) for the full preset list and tuning guidance.

### Controls

| Function | Returns | Notes |
| -------- | ------- | ----- |
| `stop` | `AnimState` | Jump to end state |
| `reset` | `AnimState` | Jump to start state |
| `restart` | `( AnimState, Cmd msg )` | Reset and play again; `Cmd` fires `Restarted` |
| `pause` | `( AnimState, Cmd msg )` | Freeze at current position; `Cmd` fires `Paused` |
| `resume` | `( AnimState, Cmd msg )` | Continue from paused position; `Cmd` fires `Resumed` |

??? example "View Source Code"

    ```elm
    Stop ->
        ( { model | animState = Keyframe.stop "card" model.animState }, Cmd.none )

    Reset ->
        ( { model | animState = Keyframe.reset "card" model.animState }, Cmd.none )

    Restart ->
        let
            ( animState, cmd ) =
                Keyframe.restart "card" GotAnimMsg model.animState
        in
        ( { model | animState = animState }, cmd )

    Pause ->
        let
            ( animState, cmd ) =
                Keyframe.pause "card" GotAnimMsg model.animState
        in
        ( { model | animState = animState }, cmd )

    Resume ->
        let
            ( animState, cmd ) =
                Keyframe.resume "card" GotAnimMsg model.animState
        in
        ( { model | animState = animState }, cmd )
    ```

📖 See [Controlling Animations](../concepts/controlling-animations.md) for more info.

### Discrete Properties

The Keyframe engine bakes discrete properties into the generated `@keyframes` rule. `discreteEntry` values are emitted on every step, and `discreteExit` values emit the entry value on all steps, then flip to the exit value on the final frame. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

### Transform Order

Use `transformOrder` to set the order in which transform properties are applied for the next animation.

??? example "View Source Code"

    ```elm
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    animateBox =
        Keyframe.transformOrder [ Scale, Rotate, Translate ]
            >> Translate.for "box"
            >> ...
    ```

📖 See [Transform Order](../concepts/transform-order.md) for full details.

### State Queries

Query animation state at any time without waiting for events.

??? example "View Source Code"

    ```elm
    Keyframe.anyRunning model.animState           -- Maybe Bool
    Keyframe.isRunning "card" model.animState     -- Maybe Bool
    Keyframe.allComplete model.animState          -- Maybe Bool
    Keyframe.isComplete "card" model.animState    -- Maybe Bool
    Keyframe.isCancelled "card" model.animState   -- Maybe Bool
    ```

`Nothing` is returned when no animation exists for the given group.

### Property Queries

CSS keyframes don't provide access to mid-flight values, so only start and end values are tracked.

All query functions follow the same pattern:

- `get[Property]Start`, and return `Maybe [PropertyValue]`.
- `get[Property]End`, and return `Maybe [PropertyValue]`

??? example "View Source Code"

    ```elm
    Keyframe.getOpacityStart "card" model.animState    -- Maybe Float
    Keyframe.getOpacityEnd "card" model.animState      -- Maybe Float
    Keyframe.getTranslateStart "card" model.animState  -- Maybe { x, y, z }
    Keyframe.getTranslateEnd "card" model.animState    -- Maybe { x, y, z }
    ```

For mid-flight current values, use the [Sub](sub.md) or [WAAPI](waapi.md) engine.

`Nothing` is returned when no animation exists for the given group.

### When to Choose This Engine

Choose Keyframe when you want browser-native keyframes with state-tracked lifecycle and playback controls.

- Best for: on-load animations, loops, and timelines that benefit from pause/resume/restart.
- Avoid when: you need true mid-flight value access or smooth redirection from current playhead position.

### API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder mode` | Carries all animation configurations |
| `AnimMsg` | Internal engine messages |
| `AnimEvent` | Events received during a keyframe animation's lifecycle |
| `AnimGroupName` | `String` type alias for the animation group name |
| `CurrentTargetId` | `String` type alias for the element that fired the event |
| `TargetId` | `String` type alias for the element that owns the listener |
| `TransformProperty` | Custom transform ordering |

### Initialize

| Function | Type | Description |
| -------- | ---- | ----------- |
| `init` | `List (AnimBuilder mode -> AnimBuilder mode) -> AnimState` | Create initial animation state |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `AnimState -> (AnimBuilder mode -> AnimBuilder mode) -> AnimState` | Apply an animation to the current state |

### Events

| Event | Fires when... |
| ----- | ------------- |
| `Started CurrentTargetId TargetId AnimGroupName` | Animation begins playing |
| `Ended CurrentTargetId TargetId AnimGroupName` | Animation completes |
| `Cancelled CurrentTargetId TargetId AnimGroupName` | Animation is interrupted |
| `Iteration CurrentTargetId TargetId AnimGroupName Int` | Each cycle completes |
| `Paused AnimGroupName` | `pause` is called (synthetic) |
| `Resumed AnimGroupName` | `resume` is called (synthetic) |
| `Restarted AnimGroupName` | `restart` is called (synthetic) |

### Update

| Function | Type | Description |
| -------- | ---- | ----------- |
| `update` | `AnimMsg -> AnimState -> (AnimState, AnimEvent)` | Process keyframe messages |

### View

| Function | Type | Description |
| -------- | ---- | ----------- |
| `attributes` | `AnimGroupName -> AnimState -> List (Html.Attribute msg)` | Get animation attributes for an element |
| `styleNode` | `AnimState -> Html msg` | Generate `@keyframes` rules for all groups |
| `styleNodeFor` | `AnimGroupName -> AnimState -> Html msg` | Generate `@keyframes` rules for a specific group |
| `maybeString` | `AnimGroupName -> AnimState -> Maybe String` | Get the raw `@keyframes` CSS as a string |

### Event Listeners

| Function | Type | Description |
| -------- | ---- | ----------- |
| `events` | `(AnimMsg -> msg) -> List (Html.Attribute msg)` | Attach all animation event listeners |
| `eventsStopPropagation` | `(AnimMsg -> msg) -> List (Html.Attribute msg)` | Attach all listeners, stops propagation |

### Playback

| Function | Type | Description |
| -------- | ---- | ----------- |
| `iterations` | `Int -> AnimBuilder mode -> AnimBuilder mode` | Set number of iterations |
| `loopForever` | `AnimBuilder mode -> AnimBuilder mode` | Loop animation infinitely |
| `alternate` | `AnimBuilder mode -> AnimBuilder mode` | Reverse direction on each iteration |

### Timing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `duration` | `Int -> AnimBuilder mode -> AnimBuilder mode` | Set duration (ms) |
| `speed` | `Float -> AnimBuilder mode -> AnimBuilder mode` | Set speed (property units/sec) |
| `delay` | `Int -> AnimBuilder mode -> AnimBuilder mode` | Set delay before animation starts (ms) |

### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> AnimBuilder mode -> AnimBuilder mode` | Set easing function |

### Spring

| Function | Type | Description |
| -------- | ---- | ----------- |
| `spring` | `Spring -> AnimBuilder mode -> AnimBuilder mode` | Set spring physics |

### Controls

| Function | Type | Description |
| -------- | ---- | ----------- |
| `stop` | `AnimGroupName -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `AnimGroupName -> AnimState -> AnimState` | Jump to start state and stop |
| `restart` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Reset and begin playing again |
| `pause` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Freeze at current position |
| `resume` | `AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )` | Continue from paused position |

### Discrete Properties

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a CSS property value during and after the animation |

### Transform Order

| Function | Type | Description |
| -------- | ---- | ----------- |
| `transformOrder` | `List TransformProperty -> AnimBuilder mode -> AnimBuilder mode` | Set custom transform order |

### State Queries

| Function | Type | Description |
| -------- | ---- | ----------- |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any animation is running |
| `isRunning` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group's animation is complete |
| `isCancelled` | `AnimGroupName -> AnimState -> Maybe Bool` | Check if a specific group's animation was cancelled |

### Property Queries

CSS keyframes track only start and end values.

| Function | Type | Description |
| -------- | ---- | ----------- |
| `getOpacityStart` | `AnimGroupName -> AnimState -> Maybe Float` | Get start opacity |
| `getOpacityEnd` | `AnimGroupName -> AnimState -> Maybe Float` | Get end opacity |
| `getTranslateStart` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get start translate |
| `getTranslateEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end translate |
| `getRotateStart` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get start rotate |
| `getRotateEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end rotate |
| `getScaleStart` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get start scale |
| `getScaleEnd` | `AnimGroupName -> AnimState -> Maybe { x, y, z }` | Get end scale |
| `getSizeStart` | `AnimGroupName -> AnimState -> Maybe { width, height }` | Get start size |
| `getSizeEnd` | `AnimGroupName -> AnimState -> Maybe { width, height }` | Get end size |
| `getSkewStart` | `AnimGroupName -> AnimState -> Maybe { x, y }` | Get start skew |
| `getSkewEnd` | `AnimGroupName -> AnimState -> Maybe { x, y }` | Get end skew |
| `getPropertyStart` | `AnimGroupName -> String -> AnimState -> Maybe Float` | Get start value for a custom numeric property |
| `getPropertyEnd` | `AnimGroupName -> String -> AnimState -> Maybe Float` | Get end value for a custom numeric property |
| `getColorPropertyStart` | `AnimGroupName -> String -> AnimState -> Maybe Color` | Get start value for a custom color property |
| `getColorPropertyEnd` | `AnimGroupName -> String -> AnimState -> Maybe Color` | Get end value for a custom color property |

`Nothing` is returned when no animation exists for the given group.

For complete API details, see the [Anim.Engine.Keyframe](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-Keyframe) documentation.

### Next Steps

The Sub Engine which provides a few more features than you get with keyframes.

[Sub Engine →](sub.md){ .md-button .md-button--primary }
