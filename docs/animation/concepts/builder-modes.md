# Builder Modes

Builder modes are used in the type signatures of your builder functions, and determine how portable your animations are. Use the default mode for maximum portability, narrow the mode when the need arises.

## The Default: `AnimBuilder mode`

Most builders should look like this:

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder)


    myAnim : AnimBuilder mode -> AnimBuilder mode
    myAnim =
        ...
    ```

The lowercase `mode` is a type variable - "whatever `mode` the caller has, this builder accepts it and returns the same one". The same `myAnim` can be passed to `Transition.animate`, `Keyframe.animate`, `WAAPI.animate`, `ScrollTimeline.animate`, and so on without any change.

If you can write a builder this way, do it. You get the maximum flexibility for free.

## Narrowing the `mode`

In general, you'll want to keep your builders as portable as you can, but if you introduce engine specific behaviour it will narrow the `mode`. The narrowed `mode` will then bleed into any other builders it composes with and makes the builders less portable:

??? example "View Source Code"

    ```elm
    fadeIn : AnimGroupName -> AnimBuilder (ForDocumentTimeline ForTransitionEngine) -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)
    fadeIn  animGroup =
        Transition.discreteEntry "display" "flex" -- Engine specific behaviour
            >> Opacity.for animGroup
            >> Opacity.to 1
            >> Opacity.duration 400
            >> Opacity.build
    ```

    Only works with Transition engine. Every other engine is now barred from using this `fadeIn` builder.


The obvious way to avoid this is to simply put your engine specific behaviour with the trigger:

??? example "View Source Code"

    ```elm
    Transition.animate model.animState <|
        Transition.discreteEntry "display" "flex"
            >> fadeIn
    ```

    `fadeIn` can now be made portable again for use by any engine.

### Restricting by Timeline

If you want a builder that is restricted to a specific timeline, such as the Document timeline, and nothing else:

??? example "View Source Code"

    ```elm
    import Anim.Builder as Builder exposing (AnimBuilder, ForDocumentTimeline)


    staggeredIntro : AnimBuilder (ForDocumentTimeline engine)  -> AnimBuilder (ForDocumentTimeline engine)
    staggeredIntro =
        Builder.delay 200
            >> fadeIn
            >> slideInSidebar
    ```

    Works with Transition, Keyframe, Sub, and WAAPI. Passing `staggeredIntro` to `ScrollTimeline.animate` or `ViewTimeline.animate` is a type error.

### Restricting by Engine

If you want a builder locked to one engine - for example a Transition-specific builder that always sets `display: flex` - write the narrow signature down:

??? example "View Source Code"

    ```elm
    import Anim.Builder
        exposing
            ( AnimBuilder
            , ForDocumentTimeline
            , ForTransitionEngine
            )
    import Anim.Engine.Transition as Transition


    fadeInWithDisplay :  AnimBuilder (ForDocumentTimeline ForTransitionEngine) -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)
    fadeInWithDisplay =
        Transition.discreteEntry "display" "flex"
            >> fadeIn
    ```

    Passing `fadeInWithDisplay` to any other engine is a type error.


## Picking a Mode

| Use case | Signature |
| -------- | --------- |
| Reusable across every engine | `AnimBuilder mode -> AnimBuilder mode` |
| Any Document timeline engine | `AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)` |
| Transition only | `AnimBuilder (ForDocumentTimeline ForTransitionEngine) -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)` |
| Keyframe only | `AnimBuilder (ForDocumentTimeline ForKeyframeEngine) -> AnimBuilder (ForDocumentTimeline ForKeyframeEngine)` |
| Sub only | `AnimBuilder (ForDocumentTimeline ForSubEngine) -> AnimBuilder (ForDocumentTimeline ForSubEngine)` |
| WAAPI only | `AnimBuilder (ForDocumentTimeline ForWAAPIEngine) -> AnimBuilder (ForDocumentTimeline ForWAAPIEngine)` |
| ScrollTimeline only | `AnimBuilder ForScrollTimeline -> AnimBuilder ForScrollTimeline` |
| ViewTimeline only | `AnimBuilder ForViewTimeline -> AnimBuilder ForViewTimeline` |

The engine modules also re-export shorter aliases (for example `Transition.EngineBuilder`), equivalent to the fully expanded form.

## Next Steps

Learn about Interrupting Animations mid-flight.

[Interrupting Animations →](../concepts/interrupting-animations.md){ .md-button .md-button--primary }

Or go back to [Build](../workflow/build.md) to continue the core animation workflow.
