# Builder Modes

Builder modes let you control how broadly a builder function can be used.
Use them when you want stronger intent signaling in type signatures,
or when a builder only makes sense for a specific timeline or engine.

## Generic Mode

Use a generic `mode` when a builder should work across engines.

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder)
    import Anim.Property.Opacity as Opacity


    -- Works with any animation engine.
    fadeIn : AnimBuilder mode -> AnimBuilder mode
    fadeIn =
        Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.build
    ```

## Document Timeline Restrictions

`ForDocumentTimeline engine` restricts usage to Document timeline engines:

- Transition
- Keyframe
- Sub
- WAAPI

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder, ForDocumentTimeline)
    import Anim.Engine.Transition as Transition


    -- These are equivalent.
    f : Transition.TimelineBuilder engine -> Transition.TimelineBuilder engine
    f : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)
    f =
        identity
    ```

## Engine-Specific Restrictions

Use an Engine `mode` when a builder must only work with one specific engine.

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder, ForDocumentTimeline, ForTransitionEngine)
    import Anim.Engine.Transition as Transition


    -- All three are equivalent.
    transitionOnlyA : Transition.EngineBuilder -> Transition.EngineBuilder
    transitionOnlyA =
        identity


    transitionOnlyB : Transition.TimelineBuilder ForTransitionEngine -> Transition.TimelineBuilder ForTransitionEngine
    transitionOnlyB =
        identity


    transitionOnlyC : AnimBuilder (ForDocumentTimeline ForTransitionEngine) -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)
    transitionOnlyC =
        identity
    ```

## Choosing the Narrowest Useful Mode

Use the narrowest mode that matches your intent:

- Reusable across engines and timelines: `AnimBuilder mode -> AnimBuilder mode`
- Any Document timeline engine: `AnimBuilder (ForDocumentTimeline engine) -> ...`
- Sub specific engine: `AnimBuilder (ForDocumentTimeline ForSubEngine) -> ...`

## Why Tighten Builder Modes?

Using a more specific `mode` can improve both readability and maintenance:

- Intent signaling: type signatures communicate purpose immediately (for example, "Transition-only builder").
- Faster bug triage: when a bug is tied to one engine or timeline, builder functions with incompatible modes can be ruled out quickly.

## Next Steps

Learn about Interrupting Animations mid-flight.

[Interrupting Animations →](../concepts/interrupting-animations.md){ .md-button .md-button--primary }

Or go back to [Build](../workflow/build.md) to continue the core animation workflow.
