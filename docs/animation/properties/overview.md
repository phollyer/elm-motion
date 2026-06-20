# Properties Overview

This page mainly covers the shared patterns that are used by each Property. For property-specific details, see each individual property page.

## Builder Pattern

Every property uses the same pattern: start the builder, set values, configure timing, and finish the property builder.

??? example "View Source Code"

    ```elm
    Property.begin                      -- Start the builder (required)
        >> Property.from startValue     -- Optional starting value
        >> Property.to endValue         -- Property specific alternatives to `to` are available
        >> Property.delay 100           -- ms
        >> Property.duration 500        -- ms, or `Property.speed 50` (units per second)
        >> Property.easing BounceOut    -- or `Property.spring wobbly`
        >> Property.end                 -- Finalize (required)
    ```

📖 See [The Builder Pattern](../workflow/build.md#the-builder-pattern) for more information.

## Begin

All property builders start with the `begin` function. This converts an `AnimBuilder` into a property specific builder, ensuring you don't mix property functions in the same builder chain.

## Start Values

All animations need a start value.

All properties have either an `init` function, or a variety of `init*` functions that are property specific, or both. These should be used in the Engine's `init` function to set initial values for properties.

??? example "View Source Code"

    ```elm
    Transition.init [ Opacity.init "animGroup" 0 ]

    Keyframe.init [ Size.initHW "animGroup" 80 100 ]

    Sub.init [ Skew.initX "animGroup" 10 ]

    WAAPI.init [ Translate.initXYZ "animGroup" 50 100 75 ]
    ```

This performs three functions:

- It sets initial values for first render
- It gives the Engine starting values to use for the first time the `animGroup` is animated
- It ensures the Engine and your view are in sync

### Optional `from`

All properties have either a `from` function, or a variety of `from*` functions that are property specific, or both. In general, these won't be needed - the Engines will always start animations from the last known end state.

The family of `from*` functions are made available in order to override this default Engine behaviour, and start your animations from a specific state.

If in doubt, start without; only add when needed.


## End Values

All animations need an end value.

All properties have either a `to` function, or a variety of `to*` functions that are property specific, or both.
`Translate` also has `by*` in order to translate by a delta value.

??? example "View Source Code"

    ```elm
    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Opacity.begin
            >> Opacity.to 1
            >> ... -- Continue configuring the animation

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Size.begin
            >> Size.toHW 150 120
            >> ... -- Continue configuring the animation

    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.begin
            >> Translate.toXYZ 120 150 100
            >> ... -- Continue configuring the animation
    ```

## Easing

Make your animations smooth and life-like with easing curves.

All properties have an `easing` function which takes an `Easing` type variant. This will override any default easing set by the Engine.

??? example "View Source"

    ```elm 
    import Motion.Easing as Easing exposing (Easing(..))

    slideInAnimation : AnimBuilder eng -> AnimBuilder eng
    alideInAnimation =
        Translate.begin
            >> Translate.toX 0
            >> Translate.easing BounceOut
            >> ... -- Continue configuring the animation
    ```

📖 See [Easing Type](../concepts/easing.md) for more information.

## Spring

Use physics-based motion instead of time-and-curve. The motion ends when the value has settled — there is no explicit duration.

All properties have a `spring` function which takes a `Spring`. This will override any default spring or easing set by the Engine.

??? example "View Source"

    ```elm
    import Motion.Spring as Spring

    bouncyReveal : AnimBuilder { eng | withSpring : () } -> AnimBuilder { eng | withSpring : () }
    bouncyReveal =
        Translate.begin
            >> Translate.toX 0
            >> Translate.spring Spring.wobbly
            >> ... -- Continue configuring the animation

    ```
    **Note**: Springs are not supported by all Engines, the Transition engine doesn't, so `spring` is a capablility restricted function denoted by `withSpring`. 

    📖 See [Engine Capabilities](../concepts/engine-capabilities.md) for more info.

📖 See [Spring](../concepts/spring.md) for the full preset list and tuning guidance.

## Delay

Add a delay before the animation starts.

All properties have a `delay` function which takes an `Int` representing milliseconds. This will override any default delay set by the Engine.

??? example "View Source Code"

    ```elm
    fadeInAfterDelay : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
    fadeInAfterDelay =
        Opacity.begin
            >> Opacity.to 1
            >> Opacity.delay 300
            >> ... -- Continue configuring the animation
    ```
    **Note**: Delay is part of the `withTiming` capabilities and is not supported by all Engines, the Timeline engines don't, they are driven by scroll position not time, so timing capabilities don't make sense for these engines.

    📖 See [Engine Capabilities](../concepts/engine-capabilities.md) for more info.

!!! tip "Staggering animations"
    Use different delays on properties within the same group to stagger their start times, creating a sequenced feel without needing separate animations.



## Duration

Set a fixed time for the animation to complete.

All properties have a `duration` function which takes an `Int` representing milliseconds. This will override any default duration set by the Engine.

??? example "View Source Code"

    ```elm
    slideIn : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
    slideIn =
        Translate.begin
            >> Translate.toX 0
            >> Translate.duration 500
            >> ... -- Continue configuring the animation
    ```
    **Note**: Duration is part of the `withTiming` capabilities and is not supported by all Engines, the Timeline engines don't, they are driven by scroll position not time, so timing capabilities don't make sense for these engines.

    📖 See [Engine Capabilities](../concepts/engine-capabilities.md) for more info.

📖 See [Duration vs Speed](../concepts/timing.md#duration-vs-speed) for more information.


## Speed

Set a consistent velocity for the animation, where time varies based on the distance between start and end values. Longer distances take longer, shorter distances take less time.

All properties have a `speed` function which takes a `Float`. The unit depends on the property. This will override any default speed set by the Engine.

??? example "View Source Code"

    ```elm
    moveToTarget : Float -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
    moveToTarget targetX =
        Translate.begin
            >> Translate.toX targetX
            >> Translate.speed 500
            >> ... -- Continue configuring the animation
    ```
    **Note**: Speed is part of the `withTiming` capabilities and is not supported by all Engines, the Timeline engines don't, they are driven by scroll position not time, so timing capabilities don't make sense for these engines.

    📖 See [Engine Capabilities](../concepts/engine-capabilities.md) for more info.

!!! tip "When to use `speed` over `duration`"
    `speed` is ideal when the distance varies at runtime — for example, drag-and-drop targets or scrolling to dynamic positions. It gives a consistent feel regardless of how far the element needs to travel.

📖 See [Duration vs Speed](../concepts/timing.md#duration-vs-speed) for more information.

## End

`end` completes the pattern and returns an `AnimBuilder`, allowing you to build another animation or pass the builder to an engine for triggering.

??? example "View Source Code"

    ```elm
    myAnimation : AnimBuilder eng -> AnimBuilder eng
    myAnimation =
        Translate.begin                   -- Transforms `AnimBuilder eng` into a `Translate.Builder eng`
            >> Translate.toX 100
            >> Translate.end              -- Returns AnimBuilder eng
            >> Opacity.begin              -- Transforms `AnimBuilder eng` into an `Opacity.builder eng` 
            >> Opacity.to 1
            >> Opacity.end                -- Returns AnimBuilder eng
            >> Rotate.begin               -- Transforms `AnimBuilder eng` into a `Rotate.builder eng` 
            >> Rotate.toY 90
            >> Rotate.end                 -- Returns AnimBuilder eng
    ```

📖 See [The Builder Pattern](../workflow/build.md#the-builder-pattern) for more information.

## Quick Reference

| Property | Module | GPU | Dimensions | Values |
| -------- | ------ | :-: | ---------- | ------ |
| [Opacity](opacity.md) | `Anim.Property.Opacity` | ✓ | Single value | `Float` (0.0 – 1.0) |
| [Rotate](rotate.md) | `Anim.Property.Rotate` | ✓ | X, Y, Z | `Float` degrees |
| [Scale](scale.md) | `Anim.Property.Scale` | ✓ | X, Y, Z | `Float` multiplier (1.0 = 100%) |
| [Skew](skew.md) | `Anim.Property.Skew` | ✓ | X, Y | `Float` degrees |
| [Size](size.md) | `Anim.Property.Size` | | W, H | `Float` with any [`Unit`](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Unit) (default `Px`) |
| [Translate](translate.md) | `Anim.Property.Translate` | ✓ | X, Y, Z | `Float` with any [`Unit`](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Unit) (default `Px`) |
| [Custom Property](custom-property.md) | `Anim.Property.Custom` | | Single value | `Float` with any [`Unit`](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Unit) |
| [Custom Color Property](custom-color-property.md) | `Anim.Property.CustomColor` | | Single value | `Color` |


## Next Steps

GPU Accelerated Properties.

[GPU Accelerated →](gpu.md){ .md-button .md-button--primary }

