# Build

## The Builder Pattern

Elm Motion uses a fluent builder pattern for defining animations.
This approach provides a consistent, composable API across all engines
and properties that reads naturally and is easy to reason about — you can
see at a glance what an animation does and how it behaves.

## Basic Structure

Every animation follows this pattern:


??? example "View Source Code"

    ```elm
    animationFunction : AnimBuilder mode -> AnimBuilder mode
    animationFunction =
        Property.for animGroup              -- Animation group name (required)
            >> Property.from startValue     -- Optional starting value
            >> Property.to endValue         -- Property specific alternatives to `to` are available
            >> Property.delay 100           -- ms
            >> Property.duration 500        -- ms, or `Property.speed 50` (units per second)
            >> Property.easing BounceOut    -- or `Property.spring wobbly`
            >> Property.build               -- Finalize (required)
    ```

    `for` and `build` are required to start and end the builder chain respectively. All other configurations are optional,
    although without an `endValue` the animations won't have anywhere to go!!

All animations are created by building them up with property specific builder functions. Each property has the same basic API, while multi-dimensional properties like `Translate` also have axis specific builders.

Once built, the animations can be passed to any animation engine.

📖 See [Properties Overview](../properties/overview.md) for more information.

## Builder Modes

A typical builder function has the following type signature:

```elm
f : AnimBuilder mode -> AnimBuilder mode
```

The builder type signature includes the `mode` type parameter which can be used to tighten the use of a function, and trigger compiler errors if used outside of the specified use.

📖 See [Builder Modes](../concepts/builder-modes.md) for more information.

## Animation Group Names

The first argument to `Property.for` is the **animation group name** — a string that groups
animation configurations together. Use it to animate multiple properties at once, or to create
multiple animations for different elements.

### Multiple Properties

Properties with the same group name animate together and are applied to the same element:

??? example "View Source Code"

    ```elm
    -- Both properties share "boxAnim" - they animate together on the same element
    enterAnimation : AnimBuilder mode -> AnimBuilder mode
    enterAnimation =
        Opacity.for "boxAnim"
            >> Opacity.to 1
            >> Opacity.build
            >> Translate.for "boxAnim"
            >> Translate.toY 0
            >> Translate.build
    ```

### Multiple Animations

Use different group names when you want separate animation sets for different elements:

??? example "View Source Code"

    ```elm
    -- Different groups for different element animations
    pageAnimations : AnimBuilder mode -> AnimBuilder mode
    pageAnimations =
        Opacity.for "header"            -- Header fades in
            >> Opacity.to 1
            >> Opacity.build
            >> Translate.for "sidebar"  -- Sidebar slides in
            >> Translate.toX 0
            >> Translate.build
    ```

## Best Practices

!!! tip "Keep animations small and focused"
    Create small, single-purpose animation functions and compose them together.

!!! tip "Use meaningful names"
    Name your animation functions based on what they do: `fadeIn`, `slideLeft`, `bounceOnHover`.

!!! tip "Extract common patterns"
    If you use the same configurations often, create reusable builder functions.

??? example "View Source Code"

    ```elm
    -- Reusable Fade Builders
    fadeTo :  Float -> AnimGroupName -> AnimBuilder mode -> AnimBuilder mode
    fadeTo opacity groupName  =
        Opacity.for groupName
            >> Opacity.to opacity
            >> Opacity.duration 400
            >> Opacity.build

    fadeIn : AnimGroupName -> AnimBuilder mode -> AnimBuilder mode
    fadeIn =
        fadeTo 1

    fadeOut : AnimGroupName -> AnimBuilder mode -> AnimBuilder mode
    fadeOut =
        fadeTo 0

    -- Reusable Slide Builder
    slideTo : AnimGroupName -> (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
    slideTo groupName slideTo =
        Translate.for groupName
            >> slideTo
            >> Translate.speed 200
            >> Translate.spring Spring.wobbly
            >> Translate.build

    -- Reusable Sidebar Builder
    slideSidebar : Float -> AnimBuilder mode -> AnimBuilder mode
    slideSidebar toX =
        slideTo "sidebarAnim" <|
            Translate.toX toX

    -- Reusable Content Builder
    slideContent : Float -> AnimBuilder mode -> AnimBuilder mode
    slideContent toY =
        slideTo "contentAnim" <|
            Translate.toY toY


    -- Specific Sidebar Builders
    sidebarEntrance : AnimBuilder mode -> AnimBuilder mode
    sidebarEntrance =
        fadeIn "sidebarAnim" 
            >> slideSidebar 0

    sidebarExit : AnimBuilder mode -> AnimBuilder mode
    sidebarExit =
        fadeOut "sidebarAnim" 
            >> slideSidebar -300

    -- Specific Content Builders
    contentEntrance : AnimBuilder mode -> AnimBuilder mode
    contentEntrance =
        fadeIn "contentAnim"
            >> slideContent 0

    contentExit : AnimBuilder mode -> AnimBuilder mode
    contentExit =
        fadeOut "contentAnim"
            >> slideContent 300

    -- Specific Page Builders
    pageEntrance : AnimBuilder mode -> AnimBuilder mode
    pageEntrance =
        sidebarEntrance
            >> contentEntrance

    pageExit : AnimBuilder mode -> AnimBuilder mode
    pageExit =
        sidebarExit
            >> contentExit
    ```

## Next Steps

Now that you've defined your animations, the next step is initializing your animation state.

[Initialize →](init.md){ .md-button .md-button--primary }

