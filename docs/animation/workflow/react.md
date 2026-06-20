# React

After [triggering](trigger.md) an animation, you'll often want to react to its lifecycle.

## Wiring Up `update`

Each engine communicates with your app via a `Msg` - DOM events, subscription ticks,
or port messages depending on the engine.

All engines return a `Maybe AnimEvent` with the exception of the Sub engine which returns a `List AnimEvent`.

??? example "View Source Code"

    === "Transition"

        ```elm
        type Msg 
            = GotAnimMsg Transition.AnimMsg
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotAnimMsg animMsg ->
                    let
                        ( animState, maybeAnimEvent ) =
                            Transition.update animMsg model.animState
                    in
                    (reactToAnimEvent maybeAnimEvent { model | animState = animState }
                    , Cmd.none
                    )

                ...

        reactToAnimEvent : Maybe AnimEvent -> Model -> Model
        reactToAnimEvent maybeAnimEvent model =
            case maybeAnimEvent of 
                Just (Ended _ _ "introAnim") ->
                    { model | animState = Transition.animate model.animState nextAnimation }

                _ ->
                    model
        ```

    === "Keyframe"

        ```elm
        type Msg 
            = GotAnimMsg Keyframe.AnimMsg
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotAnimMsg animMsg ->
                    let
                        ( animState, maybeAnimEvent ) =
                            Keyframe.update animMsg model.animState
                    in
                    (reactToAnimEvent maybeAnimEvent { model | animState = animState }
                    , Cmd.none
                    )

                ...

        reactToAnimEvent : Maybe AnimEvent -> Model -> Model
        reactToAnimEvent maybeAnimEvent model =
            case maybeAnimEvent of 
                Just (Ended _ _ "introAnim") ->
                    { model | animState = Keyframe.animate model.animState nextAnimation }

                _ ->
                    model
        ```

    === "Sub"

        ```elm
        type Msg 
            = GotAnimMsg Sub.AnimMsg
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotAnimMsg animMsg ->
                    let
                        ( animState, animEvents ) =
                            Sub.update animMsg model.animState
                    in
                    (List.foldl reactToAnimEvent { model | animState = animState } animEvents
                    , Cmd.none
                    )

                ...
            
        reactToAnimEvent : AnimEvent -> Model -> Model
        reactToAnimEvent animEvent model =
            case animEvent of
                Ended "introAnim" ->
                    { model | animState = Sub.animate model.animState nextAnimation }

                _ ->
                    model
        ```
        
        Sub drives all animations from a single `onAnimationFrameDelta` subscription, 
        so multiple animations can advance and complete within the same frame.
        `Sub.update` therefore returns a `List` of events which you fold over to handle each in turn.

    === "WAAPI"

        ```elm
        type Msg 
            = GotAnimMsg WAAPI.AnimMsg
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotAnimMsg animMsg ->
                    let
                        ( animState, maybeAnimEvent ) =
                            WAAPI.update animMsg model.animState
                    in
                    reactToAnimEvent maybeAnimEvent { model | animState = animState }

                ...

        reactToAnimEvent : Maybe AnimEvent -> Model -> (Model, Cmd Msg)
        reactToAnimEvent maybeAnimEvent model =
            case maybeAnimEvent of
                Nothing ->
                    (model, Cmd.none)

                Just (Ended "introAnim") ->
                    let
                        ( animState, cmd ) =
                            WAAPI.animate model.animState nextAnimation
                    in
                    ( { model | animState = animState }, cmd )

                ...

        ```

        This Engine shares the same incoming and outgoing ports as the  ScrollTimeline and ViewTimeline Engines, therefore, `Nothing` represents a message from the JS companion that is not for this Engine.

    === "ScrollTimeline"

        ```elm
        type Msg 
            = GotScrollMsg ScrollTimeline.AnimMsg
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotScrollMsg animMsg ->
                    (model
                    , reactToScrollEvent <|
                        ScrollTimeline.update animMsg
                    )

                ...

        reactToScrollEvent : Maybe AnimEvent -> (Cmd Msg)
        reactToScrollEvent maybeAnimEvent =
            case maybeAnimEvent of
                Nothing ->
                    Cmd.none

                Just (Ended "introAnim") ->
                    ScrollTimeline.animate motionCmd Document nextAnimation

                ...

        ```

        This Engine shares the same incoming and outgoing ports as the  WAAPI and ViewTimeline Engines, therefore, `Nothing` represents a message from the JS companion that is not for this Engine.

    === "ViewTimeline"

        ```elm
        type Msg 
            = GotViewMsg ViewTimeline.AnimMsg
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotViewMsg animMsg ->
                    (model
                    , reactToViewEvent <|
                        ViewTimeline.update animMsg
                    )

                ...

        reactToViewEvent : Maybe AnimEvent ->  Cmd Msg
        reactToViewEvent maybeAnimEvent =
            case maybeAnimEvent of
                Nothing ->
                    Cmd.none
                
                Just (Ended "heroCard") ->
                    ViewTimeline.animate motionCmd nextAnimation

                ...

        ```

        This Engine shares the same incoming and outgoing ports as the  WAAPI and ScrollTimeline Engines, therefore, `Nothing` represents a message from the JS companion that is not for this Engine.


## Reacting to Events

### Setting Up Event Sources

How you receive events depends on the engine - DOM events vs subscriptions:

| Engine | Event Source | Setup |
| ------ | ------------ | ----- |
| Transition | DOM events | Add `events` to animated elements |
| Keyframe | DOM events | Add `events` to animated elements |
| Sub | Internal tracking | Add `subscriptions` to your app |
| WAAPI | JavaScript ports | Add `subscriptions` to your app |
| ScrollTimeline | JavaScript ports | Add `subscriptions` to your app |
| ViewTimeline | JavaScript ports | Add `subscriptions` to your app |


### DOM-Based Setup (Transition, Keyframe)

Add the `events` function to your animated elements:

??? example "View Source Code"

    === "Transition"

        ```elm
        view model =
            div 
                (Transition.attributes "box" model.animState
                    ++ Transition.events GotAnimMsg
                )
                [ text "Animated box" ]
        ```


    === "Keyframe"

        ```elm
        view model =
            div 
                (Keyframe.attributes "box" model.animState
                    ++ Keyframe.events GotAnimMsg
                )
                [ text "Animated box" ]
        ```


### Subscription-Based Setup (Sub, WAAPI, ScrollTimeline, ViewTimeline)

Wire up subscriptions:

??? example "View Source Code"

    === "Sub"
        ```elm
        subscriptions : Model -> Sub Msg
        subscriptions model =
            Sub.subscriptions GotAnimMsg model.animState
        ```

    === "WAAPI"
        ```elm
        subscriptions : Model -> Sub Msg
        subscriptions model =
            WAAPI.subscriptions GotAnimMsg model.animState
        ```

    === "ScrollTimeline"
        ```elm
        subscriptions : Model -> Sub Msg
        subscriptions _ =
            ScrollTimeline.subscriptions GotScrollMsg motionMsg
        ```

    === "ViewTimeline"
        ```elm
        subscriptions : Model -> Sub Msg
        subscriptions _ =
            ViewTimeline.subscriptions GotViewMsg motionMsg
        ```


## Events by Engine

| Event | Transition | Keyframe | Sub | WAAPI | ScrollTimeline | ViewTimeline |
| ----- | :---------: | :-------: | :-: | :---: | :------------: | :----------: |
| Run | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Started | ✓ | | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Iteration | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Paused | | ✓ | ✓ | ✓ | | |
| Resumed | | ✓ | ✓ | ✓ | | |
| Restarted | | ✓ | ✓ | ✓ | | |
| Progress | | | ✓¹ | ✓¹ | ✓¹ | ✓¹ |

¹ Sub, WAAPI, ScrollTimeline, and ViewTimeline emit `Progress` only when the builder opts in with `withProgressEvents True`.


### Native Events

These events come directly from the underlying technology - CSS DOM events or Web Animations API callbacks:

??? example "View Native Events"

    | Event | Transition | Keyframe | WAAPI | ScrollTimeline | ViewTimeline |
    | ----- | :--------: | :------: | :---: | :------------: | :----------: |
    | Run | ✓ | ✓ | | | |
    | Started | ✓ | | | | |
    | Ended | ✓ | ✓ | ✓ | ✓ | ✓ |
    | Cancelled | ✓ | ✓ | ✓ | ✓ | ✓ |
    | Iteration | | ✓ | | | |


### Engine-Generated Events

These events are generated internally by the engine:

??? example "View Engine Generated Events"

    | Event | Sub | WAAPI | ScrollTimeline | ViewTimeline |
    | ----- | :-: | :---: | :------------: | :----------: |
    | Run | ✓ | ✓ | ✓ | ✓ |
    | Started | ✓ | ✓ | ✓ | ✓ |
    | Ended | ✓ | | | |
    | Cancelled | ✓ | | | |
    | Paused | ✓ | ✓ | | |
    | Resumed | ✓ | ✓ | | |
    | Restarted | ✓ | ✓ | | |
    | Iteration | ✓ | ✓ | ✓ | ✓ |
    | Progress | ✓ | ✓ | ✓ | ✓ |



## Event Reference

### Run

Fired the moment an animation is applied, before any configured delay. Use this if you need to react before the visual movement begins - `Started` fires only after the delay has elapsed.

Supported by all engines. For **Transition** and **Keyframe**, this comes from native DOM events (`transitionrun` and `animationrun`). For **Sub**, **WAAPI**, **ScrollTimeline**, and **ViewTimeline**, this is emitted by engine/runtime bookkeeping when a group is first registered.

### Started

Fired when an animation begins playing.

For **Transition**, this fires after any configured delay has elapsed. Use `Run` to react before the delay.

**Keyframe** does not surface a public `Started` event - use `Run` for start-of-lifecycle handling.

For **ScrollTimeline** and **ViewTimeline**, `Started` fires each time the timeline enters its active range. Scrolling out of range and back in produces another `Started`.


### Ended

Fired when an animation completes naturally, reaching its end state.

For **ScrollTimeline** and **ViewTimeline**, `Ended` fires every time the scroll position crosses the end of the animation range. Scrolling back across the end and then forward again produces another `Ended`, so keep handlers idempotent.


### Cancelled

Fired when an animation is interrupted by something outside the engine's control:

- The element is removed from the DOM mid-animation
- A conflicting CSS rule or external animation displaces the running one
- The browser invalidates the animation


For **ScrollTimeline** and **ViewTimeline**, `Cancelled` also carries the progress value (0.0–1.0) at the time of cancellation.


### Iteration

Fired at the end of each iteration for looping animations. Useful for tracking progress through multi-iteration animations or triggering effects on each loop.


### Paused

Fired when animations are paused with the `pause` control function.

### Resumed

Fired when animations are resumed with the `resume` control function.


### Restarted

Fired when an animation is restarted from the beginning with the `restart` control function.


### Progress

Fired on each animation frame (at the display's refresh rate) with the current progress value (0.0 to 1.0). Use sparingly - this fires frequently and is intended for progress indicators or debugging rather than complex logic.

For **Sub**, **WAAPI**, **ScrollTimeline**, and **ViewTimeline**, `Progress` is opt-in. Set `withProgressEvents True` on the builder to receive one event per frame while the animation is running (or while a scroll/view timeline is in range).


## Next Steps

Now that you understand the full animation workflow, learn more about the Engines and what they can do.

[Engines Overview →](../engines/overview.md){ .md-button .md-button--primary }
