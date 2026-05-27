# Builder Modes

Builder modes are used in the type signatures of your builder functions, and determine how portable your animations are. Use the default mode for maximum portability, narrow the mode when the need arises.

## The Default: `AnimBuilder mode`

Most builders should look like this:

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder)

    f : AnimBuilder mode -> AnimBuilder mode
    ```
    The lowercase `mode` is a type variable - "whatever `mode` the caller has, this builder accepts it and returns the same one". A builder defined this way can be used by all animation engines, and in general this is exacly what you want.

    If you're new to type variables, `mode` can be expressed however you want, it just needs to be consistent: `AnimBuilder m -> AnimBuilder m` works just the same. Throughout these docs we use `mode`.



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

However, there may be times when you intentionally want to narrow the `mode` of a builder to a particular Timeline or Engine:

- When requiring Engine specific behaviour and using a different Engine would be considered a bug
- When the builder only makes sense on a particular Timeline - for example a parallax effect that has no meaning on the Document timeline

### Restricting by Timeline

If you want a builder that is restricted to a specific timeline, just replace `mode` with the required timeline type:

??? example "View Source Code"

    ```elm
    f : AnimBuilder ForScrollTimeline -> AnimBuilder ForScrollTimeline
    
    f : AnimBuilder ForViewTimeline -> AnimBuilder FoeViewTimeline
    
    f : AnimBuilder (ForDocumentTimeline engine)  -> AnimBuilder (ForDocumentTimeline engine)
    ```

### Restricting by Engine

If you want a builder tied to one specific engine on the Document timeline, just replace the `engine` type variable with the required Engine type:

??? example "View Source Code"

    ```elm
    -- all engines
    f : AnimBuilder (ForDocumentTimeline engine)  -> AnimBuilder (ForDocumentTimeline engine)

    -- specific engines
    f : AnimBuilder (ForDocumentTimeline ForTransition)  -> AnimBuilder (ForDocumentTimeline ForTransition)

    f : AnimBuilder (ForDocumentTimeline ForWAAPI)  -> AnimBuilder (ForDocumentTimeline ForWAAPI)
    ```

## Shorthand `modes`

The engine modules also export shorter aliases, for example:

- `Transition.EngineBuilder` == `AnimBuilder (ForDocumentTimeline ForTransition)`

## Next Steps

Learn about Interrupting Animations mid-flight.

[Interrupting Animations →](../concepts/interrupting-animations.md){ .md-button .md-button--primary }

Or go back to [Build](../workflow/build.md) to continue the core animation workflow.
