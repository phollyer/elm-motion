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
    animationFunction : AnimBuilder eng -> AnimBuilder eng
    animationFunction =
        Property.begin                      -- Start the animation configuration (required)
            >> Property.from startValue     -- Optional starting value
            >> Property.to endValue         -- Property specific alternatives to `to` are available
            >> Property.delay 100           -- ms
            >> Property.duration 500        -- ms, or `Property.speed 50` (units per second)
            >> Property.easing BounceOut    -- or `Property.spring wobbly`
            >> Property.end                 -- Finalize (required)
    ```

    `begin` and `end` are required to start and end the builder chain respectively. All other configurations are optional, although without an `endValue` the animations won't have 
    anywhere to go!!

All animations are created by building them up with property specific builder functions. Each property has the same basic API, while multi-dimensional properties like `Translate` also have axis specific builders.

Once built, an animation can be passed to any Engine that has the capabilities to run it.

📖 See [Properties Overview](../properties/overview.md) for more information.

## Engine Capabilities

A typical builder function has the following type signature:

??? example "View Source Code"

    ```elm
    f : AnimBuilder eng -> AnimBuilder eng
    ```

The builder type signature includes the `eng` type parameter, a phantom type. This is used by the compiler to determine if an Engine has the capabilities to run the animation - if it doesn't the compiler will complain with a type error.

📖 See [Engine Capabilities](../concepts/engine-capabilities.md) for more information.

## Animation Group Names

All animations for an element need to be grouped so that they can all be applied together.
To do this, you use the `for` function for the Engine that is consuming the animation configuration.

??? example "View Source Code"

    === "Transition"
        ```elm
        Transition.for "animGroupName"
        ```

    === "Keyframe"
        ```elm
        Keyframe.for "animGroupName"
        ```

    === "Sub"
        ```elm
        Sub.for "animGroupName"
        ```

    === "WAAPI"
        ```elm
        WAAPI.for "animGroupName"
        ```

    === "ScrollTimeline"
        ```elm
        ScrollTimeline.for "animGroupName"
        ```

    === "ViewTimeline"
        ```elm
        ViewTimeline.for "animGroupName"
        ```

The group name is then applied to the animation configurations that follow:

??? example "View Source Code"

    === "Transition"
        ```elm
        Transition.for "animGroupName"
            >> fadeIn
            >> slideIn
        ```

    === "Keyframe"
        ```elm
        Keyframe.for "animGroupName"
            >> fadeIn
            >> slideIn
        ```

    === "Sub"
        ```elm
        Sub.for "animGroupName"
            >> fadeIn
            >> slideIn
        ```

    === "WAAPI"
        ```elm
        WAAPI.for "animGroupName"
            >> fadeIn
            >> slideIn
        ```

    === "ScrollTimeline"
        ```elm
        ScrollTimeline.for "animGroupName"
            >> fadeIn
            >> slideIn
        ```

    === "ViewTimeline"
        ```elm
        ViewTimeline.for "animGroupName"
            >> fadeIn
            >> slideIn
        ```

### Multiple Properties

Properties in the same group animate together and are applied to the same element:

??? example "View Source Code"

    === "Transition"

        ```elm
        -- Both properties share "boxAnim" - they animate together on the same element
        enterAnimation : AnimBuilder eng -> AnimBuilder eng
        enterAnimation =
            Transition.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Translate.begin
                >> Translate.toY 0
                >> Translate.end
        ```

    === "Keyframe"

        ```elm
        -- Both properties share "boxAnim" - they animate together on the same element
        enterAnimation : AnimBuilder eng -> AnimBuilder eng
        enterAnimation =
            Keyframe.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Translate.begin
                >> Translate.toY 0
                >> Translate.end
        ```

    === "Sub"

        ```elm
        -- Both properties share "boxAnim" - they animate together on the same element
        enterAnimation : AnimBuilder eng -> AnimBuilder eng
        enterAnimation =
            Sub.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Translate.begin
                >> Translate.toY 0
                >> Translate.end
        ```

    === "WAAPI"

        ```elm
        -- Both properties share "boxAnim" - they animate together on the same element
        enterAnimation : AnimBuilder eng -> AnimBuilder eng
        enterAnimation =
            WAAPI.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Translate.begin
                >> Translate.toY 0
                >> Translate.end
        ```

    === "ScrollTimeline"

        ```elm
        -- Both properties share "boxAnim" - they animate together on the same element
        enterAnimation : AnimBuilder eng -> AnimBuilder eng
        enterAnimation =
            ScrollTimeline.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Translate.begin
                >> Translate.toY 0
                >> Translate.end
        ```

    === "ViewTimeline"

        ```elm
        -- Both properties share "boxAnim" - they animate together on the same element
        enterAnimation : AnimBuilder eng -> AnimBuilder eng
        enterAnimation =
            ViewTimeline.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Translate.begin
                >> Translate.toY 0
                >> Translate.end
        ```

### Multiple Animations

Use different group names when you want separate animation sets for different elements:

??? example "View Source Code"

    === "Transition"

        ```elm
        -- Different groups for different element animations
        pageAnimations : AnimBuilder eng -> AnimBuilder eng
        pageAnimations =
            Transition.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Transition.for "slideInAnim"
                >> Translate.begin
                >> Translate.toX 0
                >> Translate.end
        ```

    === "Keyframe"

        ```elm
        -- Different groups for different element animations
        pageAnimations : AnimBuilder eng -> AnimBuilder eng
        pageAnimations =
            Keyframe.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Keyframe.for "slideInAnim"
                >> Translate.begin
                >> Translate.toX 0
                >> Translate.end
        ```

    === "Sub"

        ```elm
        -- Different groups for different element animations
        pageAnimations : AnimBuilder eng -> AnimBuilder eng
        pageAnimations =
            Sub.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> Sub.for "slideInAnim"
                >> Translate.begin
                >> Translate.toX 0
                >> Translate.end
        ```

    === "WAAPI"

        ```elm
        -- Different groups for different element animations
        pageAnimations : AnimBuilder eng -> AnimBuilder eng
        pageAnimations =
            WAAPI.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> WAAPI.for "slideInAnim"
                >> Translate.begin
                >> Translate.toX 0
                >> Translate.end
        ```

    === "ScrollTimeline"

        ```elm
        -- Different groups for different element animations
        pageAnimations : AnimBuilder eng -> AnimBuilder eng
        pageAnimations =
            ScrollTimeline.for "boxAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> ScrollTimeline.for "slideInAnim"
                >> Translate.begin
                >> Translate.toX 0
                >> Translate.end
        ```

    === "ViewTimeline"

        ```elm
        -- Different groups for different element animations
        pageAnimations : AnimBuilder eng -> AnimBuilder eng
        pageAnimations =
            ViewTimeline.for "headerAnim"
                >> Opacity.begin
                >> Opacity.to 1
                >> Opacity.end
                >> ViewTimeline.for "sidebarAnim"
                >> Translate.begin
                >> Translate.toX 0
                >> Translate.end
        ```

## Best Practices

!!! tip "Keep animations small and focused"
    Create small, single-purpose animation functions and compose them together.

!!! tip "Use meaningful names"
    Name your animation functions based on what they do: `fadeIn`, `slideLeft`, `bounceOnHover`.

!!! tip "Extract common patterns"
    If you use the same configurations often, create reusable builder functions.

## Next Steps

After building your animations the next step is to initialize your animation state ready for rendering and triggering.

[Initialize →](init.md){ .md-button .md-button--primary }

