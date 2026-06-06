# Engine Capabilities

All animations are built using the property modules, they all use the same API. What differs are Engine capabilities.

Each Engine has its own set of capabilities in line with it's target output - CSS transitions, @keyframes, JS Web Animations API etc. CSS transitions for instance, do not natively support looping or alternating, and it would be lax of this library to allow animations into production with capabilities not supported by the Engine consuming it.

The last thing you need is for someone to switch a nice looping animation from the Keyframe Engine to the Transition Engine, and then silently lose the looping behaviour.

This is where **engine capabilities** come in; if an animation is built using a capability an Engine does not support, the compiler will complain, and any relevant tooling you may be using like [Elm Language Server](https://github.com/elm-tooling/elm-language-server) will flag the type error immediately.

For example, here is a builder function with the Timing capability:

```elm
f : AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () }
```

The Timing capability covers three functions: `delay`, `duration` and `speed`. Wherever you see these functions in the property modules, they will declare the `withTiming` capability in their type signature.

So when you see:

```elm
delay : Int -> AnimBuilder { eng | withTiming : () } -> AnimBuilder { eng | withTiming : () } 
```

You can just read it naturally as "an `AnimBuider` for an Engine with timing capabilities".

In general, you will only need these capability type annotations for reference, and then only if you want to preempt the compiler. Most of the time you should only need to think about these when the compiler complains. The type annotations you write for your builder functions will mostly be like:

- `AnimBuilder eng` - portable across every engine
- `Engine.EngineBuilder` - locked to a single engine (e.g. `Transition.EngineBuilder`)

The compiler will then tell you if an animation is being consumed by an Engine that does not support some of the capabilities the animation uses.

---

## Capability Reference

Each capability is declared by one or more functions in the API. If your builder composes any of them, the corresponding capability is added to its inferred type, and any Engine that lacks that capability is barred from running it.

| Capability           | Declared by                  | Supported by                       |
| -------------------- | ---------------------------- | ---------------------------------- |
| `withTiming`         | `delay`, `duration`, `speed` | Transition, Keyframe, Sub, WAAPI   |
| `withSpring`         | `spring`                     | Keyframe, Sub, WAAPI, ScrollTimeline, ViewTimeline |
| `withIterations`     | `iterations`                 | Keyframe, Sub, WAAPI, ScrollTimeline, ViewTimeline |
| `withAlternate`      | `alternate`                  | Keyframe, Sub, WAAPI, ScrollTimeline, ViewTimeline |
| `withLoopForever`    | `loopForever`                | Keyframe, Sub, WAAPI               |
| `withTransformOrder` | `transformOrder`             | Keyframe, Sub, WAAPI, ScrollTimeline, ViewTimeline |
| `withProgressEvents` | progress event subscriptions | Sub, WAAPI, ScrollTimeline, ViewTimeline           |

The capability field names (`withTiming`, `withSpring`, ...) are what the compiler reports when there's a mismatch - you don't write them, you just read them in the error.


## Locking to a Single Engine

If you ever wish to enforce the use of a particular Engine, maybe if using a different Engine would be considered a bug, then you can use each Engine's own `EngineBuilder`.

Annotate the builder with a specific Engine's `EngineBuilder` type and the compiler will only allow that Engine to consume it:

```elm
heroEntrance : AnimGroupName -> Transition.EngineBuilder -> Transition.EngineBuilder
heroEntrance group =
    Opacity.for group
        >> Opacity.to 1
        >> Opacity.duration 400
        >> Opacity.build
```

Each Engine module exposes its own alias:

- `Transition.EngineBuilder`
- `Keyframe.EngineBuilder`
- `Sub.EngineBuilder`
- `WAAPI.EngineBuilder`
- `ScrollTimeline.EngineBuilder`
- `ViewTimeline.EngineBuilder`

## Next Steps

[Interrupting Animations →](../concepts/interrupting-animations.md){ .md-button .md-button--primary }
