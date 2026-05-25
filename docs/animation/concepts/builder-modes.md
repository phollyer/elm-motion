# Builder Modes

When you write your own builder functions to compose animations, you have to give them a type signature. The "mode" is the little type variable inside `AnimBuilder` that decides which engines a builder can be plugged into.

This page shows the three sensible choices, when to reach for each one, and how the Elm compiler will help you spot misuse.

## The Default: `AnimBuilder mode`

Most builders should look like this:

??? example "View Source Code"

    ```elm
    import Anim.Builder exposing (AnimBuilder)
    import Anim.Property.Opacity as Opacity
    import Motion.Easing exposing (Easing(..))


    fadeIn : AnimBuilder mode -> AnimBuilder mode
    fadeIn =
        Opacity.for "card"
            >> Opacity.to 1
            >> Opacity.duration 400
            >> Opacity.easing QuadInOut
            >> Opacity.build
    ```

The lowercase `mode` is a type variable - "whatever mode the caller has, this builder accepts it and returns the same one". That single annotation makes `fadeIn` reusable with every engine in the package.

You can pass it straight to the Transition engine today:

??? example "View Source Code"

    ```elm
    Transition.animate model.animState fadeIn
    ```

And tomorrow, if you swap to Keyframe or WAAPI, the builder does not need to change:

??? example "View Source Code"

    ```elm
    Keyframe.animate model.animState fadeIn
    WAAPI.animate model.animState fadeIn
    ```

This is the portability story for the package - if you can write a builder with `AnimBuilder mode -> AnimBuilder mode`, do it. You get the maximum flexibility for free.

## When You Need Something Tighter

Sometimes a builder genuinely only makes sense for a subset of engines. The two reasons that come up in practice:

1. The builder uses a setting that only Document timeline engines understand - `delay`, `duration`, or `speed` from [Anim.Builder](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Builder).
2. The builder is wired so tightly to a single engine's behaviour that letting someone use it elsewhere would be a bug.

For (1) you narrow to **any** Document timeline engine. For (2) you narrow all the way down to a single engine.

### Restricting to Document Timeline Engines

The Document timeline engines are Transition, Keyframe, Sub, and WAAPI. They share the concept of a global per-pipeline `delay` / `duration` / `speed`. The two scroll-driven engines (ScrollTimeline, ViewTimeline) do not.

If your builder uses one of those settings, the compiler already forces a tighter signature on you:

??? example "View Source Code"

    ```elm
    import Anim.Builder as Builder exposing (AnimBuilder, ForDocumentTimeline)


    staggeredIntro :
        AnimBuilder (ForDocumentTimeline engine)
        -> AnimBuilder (ForDocumentTimeline engine)
    staggeredIntro =
        Builder.delay 200
            >> fadeIn
            >> slideInSidebar
    ```

The `engine` is still a type variable, so this builder works with **any** of the four Document timeline engines, just not with the scroll timelines. Try to use it with `ScrollTimeline.animate` and Elm will tell you the modes do not line up.

### Restricting to One Specific Engine

When a builder relies on engine-specific behaviour - for example, a Transition-only fallback - lock the mode down to that one engine:

??? example "View Source Code"

    ```elm
    import Anim.Builder
        exposing
            ( AnimBuilder
            , ForDocumentTimeline
            , ForTransitionEngine
            )
    import Anim.Engine.Transition as Transition


    fadeInWithDisplay :
        AnimBuilder (ForDocumentTimeline ForTransitionEngine)
        -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)
    fadeInWithDisplay =
        Transition.discreteEntry "display" "flex"
            >> fadeIn
    ```

Now if a teammate later tries to reuse `fadeInWithDisplay` with Keyframe, they get a compile error pointing straight at the mismatch instead of a confusing runtime surprise.

## How the Compiler Helps You

Tightening the mode turns "this builder does not belong here" into a type error. Here is the same misuse with each signature, and what happens.

With the loose default - the compiler accepts it everywhere:

??? example "View Source Code"

    ```elm
    fadeIn : AnimBuilder mode -> AnimBuilder mode

    -- All four compile.
    Transition.animate state fadeIn
    Keyframe.animate state fadeIn
    Sub.animate state fadeIn
    WAAPI.animate state fadeIn
    ```

With the Document timeline restriction - scroll engines are rejected:

??? example "View Source Code"

    ```elm
    staggeredIntro :
        AnimBuilder (ForDocumentTimeline engine)
        -> AnimBuilder (ForDocumentTimeline engine)

    -- Compiles.
    Transition.animate state staggeredIntro

    -- Compile error - ScrollTimeline is not a Document timeline.
    ScrollTimeline.animate state staggeredIntro
    ```

With the single-engine restriction - everything except the chosen engine is rejected:

??? example "View Source Code"

    ```elm
    fadeInWithDisplay :
        AnimBuilder (ForDocumentTimeline ForTransitionEngine)
        -> AnimBuilder (ForDocumentTimeline ForTransitionEngine)

    -- Compiles.
    Transition.animate state fadeInWithDisplay

    -- Compile error - mode is ForTransitionEngine, not ForKeyframeEngine.
    Keyframe.animate state fadeInWithDisplay
    ```

The earlier you narrow, the earlier the compiler catches a mistake.

## Picking a Mode

A short checklist:

1. Start with `AnimBuilder mode -> AnimBuilder mode`. If it compiles and the builder does what you mean, you are done.
2. If you need `Builder.delay`, `Builder.duration`, or `Builder.speed`, the compiler will push you to `AnimBuilder (ForDocumentTimeline engine) -> ...`. Accept that signature.
3. If the builder is meaningless or wrong outside one specific engine, lock it down to `AnimBuilder (ForDocumentTimeline ForXxxEngine) -> ...` so the compiler enforces it.

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

The engine modules also re-export their own narrower aliases (for example `Transition.EngineBuilder`) if you prefer the shorter spelling - they are equivalent to the fully expanded `AnimBuilder (ForDocumentTimeline ForTransitionEngine)` form.

## Next Steps

Learn about Interrupting Animations mid-flight.

[Interrupting Animations →](../concepts/interrupting-animations.md){ .md-button .md-button--primary }

Or go back to [Build](../workflow/build.md) to continue the core animation workflow.
