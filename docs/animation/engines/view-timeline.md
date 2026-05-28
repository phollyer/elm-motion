# ViewTimeline Engine

This page is a practical guide to using the ViewTimeline engine.
Read [Engines Overview](overview.md) when you want side-by-side comparisons and tradeoffs.

The ViewTimeline Engine is a lightweight engine that uses the Browsers native `ViewTimeline` API.
It ties animation progress to the view position of an element inside a scrollable container. As
the user scrolls the element into, then out of, view, the animation progresses — no `AnimState`
required. `update` and `subscriptions` are optional, and only needed if you want to react to
lifecycle events.

## Example

--8<-- "docs/animation/engines/waapi/timeline-animations.md:view-timeline-example"

---

## Quick Walkthrough

Here's a general workflow to get up an running quickly.

### 1. Build

Set `rangeStart` and `rangeEnd` to control when the animation begins and ends.

??? example "View Source Code"

    ```elm
    import Anim.Property.Opacity as Opacity


    reveal : ViewTimeline.AnimBuilder mode -> ViewTimeline.AnimBuilder mode
    reveal =
        ViewTimeline.rangeStart (ViewTimeline.Entry 0 ViewTimeline.Perc)
            >> ViewTimeline.rangeEnd (ViewTimeline.Entry 100 ViewTimeline.Perc)
            >> Opacity.for "section"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```

### 2. Render

Render attributes on the element being tracked by the view timeline.

??? example "View Source Code"

    ```elm
    view : Html Msg
    view =
        section (ViewTimeline.attributes "section") [ text "Reveal me" ]
    ```

### 3. Trigger with `animate`

Call `animate` to send a fire-and-forget view-driven animation command.

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Anim.Engine.ViewTimeline as ViewTimeline
    import Json.Encode


    port motionCmd : Json.Encode.Value -> Cmd msg


    startReveal : Cmd Msg
    startReveal =
        ViewTimeline.animate motionCmd reveal
    ```

### 4. Optional React

Subscribe only when you need lifecycle events in Elm.

??? example "View Source Code"

    ```elm
    import Json.Decode


    port motionMsg : (Json.Decode.Value -> msg) -> Sub msg


    type Msg
        = GotViewMsg ViewTimeline.AnimMsg


    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ViewTimeline.subscriptions GotViewMsg motionMsg


    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotViewMsg animMsg ->
                case ViewTimeline.update animMsg of
                    Just (ViewTimeline.Ended _) ->
                        ( model, Cmd.none )

                    _ ->
                        ( model, Cmd.none )
    ```

---

## In Detail

### Trigger

This engine uses the same JavaScript companion as the WAAPI engine, but only the outgoing port is needed, the incoming port is optional.

📖 See [WAAPI JavaScript](../../installation.md#waapi-javascript) for CDN and NPM install instructions.

!!! info "Browser support"
    `ViewTimeline` is part of the [CSS Scroll-Driven Animations](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_scroll-driven_animations) spec. Check [caniuse.com](https://caniuse.com/css-scroll-driven-animations) for current browser support.
    The `@phollyer/elm-motion` companion automatically loads the [`scroll-timeline-polyfill`](https://github.com/flackr/scroll-timeline) when the native API is not available.

Fire-and-forget, returns a `Cmd msg` with no state to store.

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Encode

    port motionCmd : Json.Encode.Value -> Cmd msg

    ViewTimeline.animate motionCmd scrollAnimation
    ```

📖 See [Triggering Animations](../workflow/trigger.md) for more info.

### Update

Use `update` to process incoming messages and return a `Maybe AnimEvent`.

??? example "View Source Code"

    ```elm
    GotViewMsg animMsg ->
        case ViewTimeline.update animMsg of
            Just (ViewTimeline.Ended animGroup) ->
                handleAnimationEnd animGroup model

            Just (ViewTimeline.Iteration animGroup count) ->
                handleIteration animGroup count model

            _ ->
                ( model, Cmd.none )
    ```

### Events

The ViewTimeline, ScrollTimeline and WAAPI Engines all utilize the JavaScript Web Animations API, and they all use the same ports to communicate with the JS companion. If you use two or more of these engines in your Elm App, depending on your setup, there is the potential for them all to receive the same messages from JS at the same time, which could be confusing.

The library has you covered here though, all incoming messages are gated by each Engine, which is why `update` returns a `Maybe AnimEvent` - `Nothing` means the message was not for this Engine.

Every event carries the animation group name. Some events carry an additional value:

- `Iteration` includes the iteration count (`Int`)
- `AnimError` carries an error string from the JavaScript layer

??? example "View Source Code"

    ```elm
    handleAnimEvent : Maybe ViewTimeline.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimEvent maybeEvent model =
        case maybeEvent of
            Just (ViewTimeline.Ended "hero-card") ->
                ( model, Cmd.none )

            Just (ViewTimeline.Iteration "hero-card" count) ->
                ( model, Cmd.none )

            Just (ViewTimeline.AnimError err) ->
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
| `AnimError` | The JavaScript layer reports an error |

### Subscriptions

Pass the message constructor and the incoming events port to receive lifecycle events.

??? example "View Source Code"

    ```elm
    port motionMsg : (Json.Decode.Value -> msg) -> Sub msg

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        ViewTimeline.subscriptions GotViewMsg motionMsg
    ```

📖 See [React](../workflow/react.md) for more info.

### View

Apply `attributes` to the animated element to attach the required animation group identifier.

??? example "View Source Code"

    ```elm
    div
        (ViewTimeline.attributes "hero-card")
        [ text "I animate as the user scrolls" ]
    ```

📖 See [Render](../workflow/render.md) for more info.

### Axis

Vertical tracking is the default. Use `horizontal` in the animation pipeline when the element is inside a container that scrolls left and right.

??? example "View Source Code"

    ```elm
    ViewTimeline.animate motionCmd <|
        ViewTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```

### Range

Setting the range determines when the animation starts and ends relative to the element's position in the viewport.

Use `rangeStart` and `rangeEnd` with `Range` constructor values. Both are optional — omitting them defaults to `Cover 0 Perc` through `Cover 100 Perc`.

??? example "View Source Code"

    ```elm
    ViewTimeline.animate motionCmd <|
        ViewTimeline.rangeStart (Entry 0 Perc)
            >> ViewTimeline.rangeEnd (Entry 100 Perc)
            >> ...
    ```

| Constructor | 0 is when… | 100% / max is when… |
| ----------- | ----------- | -------------------- |
| `Cover` | Element's leading edge first enters the viewport | Element's trailing edge leaves the viewport |
| `Contain` | Element is fully contained in the viewport | Element is no longer fully contained in the viewport |
| `Entry` | Element's leading edge first enters the viewport | Element has fully entered the viewport |
| `EntryCrossing` | Element's leading edge first enters the viewport | Element has fully entered the viewport |
| `Exit` | Element's leading edge starts to leave the viewport | Element has fully left the viewport |
| `ExitCrossing` | Element's leading edge starts to leave the viewport | Element has fully left the viewport |
| `Scroll` | Scroll container is at its very start | Scroll container is at its very end |

Try this [interactive tool](https://scroll-driven-animations.style/tools/view-timeline/ranges) to see the different `Range`s in action.

### Playback

`iterations` and `alternate` work the same as in other engines, but `loopForever` is not supported - it makes no sense for a scroll driven timeline.

📖 See [Playback](../concepts/playback.md) for `iterations` and `alternate` APIs with live examples.

### Easing

Set the default easing for all properties that don't override it.

??? example "View Source Code"

    ```elm
    fadeIn =
        ViewTimeline.easing CubicInOut
            >> Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.build
    ```

📖 See [Easing](../concepts/easing.md) for available easing functions.

### Spring

Set the default spring for all properties that don't override it. The spring's motion is pre-baked into densely-spaced keyframe stops driven by the view timeline.

??? example "View Source Code"

    ```elm
    bouncyReveal =
        ViewTimeline.spring Spring.wobbly
            >> Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.build
    ```

📖 See [Spring](../concepts/spring.md) for the full preset list and tuning guidance.

### Discrete Properties

The ViewTimeline engine manages discrete properties as inline styles. `discreteEntry` values are applied immediately when the animation starts, and `discreteExit` values flip when the animation completes. No additional view setup is needed.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

### Transform Order

Use `transformOrder` to set the order in which transform properties are applied.

??? example "View Source Code"

    ```elm
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    ViewTimeline.animate motionCmd <|
        ViewTimeline.transformOrder [ Scale, Rotate, Translate ]
            >> Translate.for "slide"
            >> ...
    ```

📖 See [Transform Order](../concepts/transform-order.md) for full details.


### When to Choose This Engine

Choose ViewTimeline when playback should follow how an element moves through the viewport.

- Best for: section reveals, scroll storytelling, and enter/exit viewport choreography.
- Avoid when: you need a time based Engine with related behaviour.

### API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimBuilder mode` | Carries all animation configuration |
| `AnimMsg` | Internal engine messages |
| `AnimEvent` | Events returned by `update` |
| `AnimGroupName` | `String` type alias for the animation group name |
| `Range` | A position along the view timeline |
| `Unit` | The unit for a range offset — `Perc` or `Px` |
| `TransformProperty` | Custom transform ordering |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `(Value -> Cmd msg) -> (AnimBuilder mode -> AnimBuilder mode) -> Cmd msg` | Fire-and-forget view-driven animation |

### Events

| Event | Description |
| ----- | ----------- |
| `Ended AnimGroupName` | Animation completes |
| `Cancelled AnimGroupName Float` | Animation cancelled; `Float` is progress at cancellation |
| `Iteration AnimGroupName Int` | Loop iteration completes; `Int` is iteration count |
| `AnimError String` | JavaScript-layer error |

### Update

| Function | Type | Description |
| -------- | ---- | ----------- |
| `update` | `AnimMsg -> Maybe AnimEvent` | Process messages and return an optional event |

### Subscriptions

| Function | Type | Description |
| -------- | ---- | ----------- |
| `subscriptions` | `(AnimMsg -> msg) -> ((Value -> msg) -> Sub msg) -> Sub msg` | Subscribe to animation events from JavaScript |

### View

| Function | Type | Description |
| -------- | ---- | ----------- |
| `attributes` | `AnimGroupName -> List (Html.Attribute msg)` | Attach the animation group identifier to an element |

### Axis

| Function | Type | Description |
| -------- | ---- | ----------- |
| `horizontal` | `AnimBuilder mode -> AnimBuilder mode` | Use horizontal viewport tracking |

### Range

| Function | Type | Description |
| -------- | ---- | ----------- |
| `rangeStart` | `Range -> AnimBuilder mode -> AnimBuilder mode` | Set when the animation begins |
| `rangeEnd` | `Range -> AnimBuilder mode -> AnimBuilder mode` | Set when the animation ends |
| `Cover` | `Float -> Unit -> Range` | Full element coverage — start or end |
| `Contain` | `Float -> Unit -> Range` | Full element containment — start or end |
| `Entry` | `Float -> Unit -> Range` | Element entering the viewport |
| `EntryCrossing` | `Float -> Unit -> Range` | Leading edge crossing |
| `Exit` | `Float -> Unit -> Range` | Element leaving the viewport |
| `ExitCrossing` | `Float -> Unit -> Range` | Trailing edge crossing |
| `Scroll` | `Float -> Unit -> Range` | Full scroll container range — start or end |
| `Perc` | `Unit` | Percentage unit |
| `Px` | `Unit` | Pixel unit |

### Playback

| Function | Type | Description |
| -------- | ---- | ----------- |
| `iterations` | `Int -> AnimBuilder mode -> AnimBuilder mode` | Set number of iterations |
| `alternate` | `AnimBuilder mode -> AnimBuilder mode` | Reverse direction on each iteration |

### Easing

| Function | Type | Description |
| -------- | ---- | ----------- |
| `easing` | `Easing -> AnimBuilder mode -> AnimBuilder mode` | Set the easing function |

### Spring

| Function | Type | Description |
| -------- | ---- | ----------- |
| `spring` | `Spring -> AnimBuilder mode -> AnimBuilder mode` | Set spring physics |

### Discrete Properties

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a CSS property value during and after the animation |

### Transform Order

| Function | Type | Description |
| -------- | ---- | ----------- |
| `transformOrder` | `List TransformProperty -> AnimBuilder mode -> AnimBuilder mode` | Set custom transform order |

For complete API details, see the [Anim.Engine.ViewTimeline](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-ViewTimeline) documentation.

### Next Steps

Get started with Properties.

[Properties →](../properties/getting-started.md){ .md-button .md-button--primary }

