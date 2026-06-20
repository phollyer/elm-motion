# Animation Engines Overview

This page compares the engines side by side.

Use this page to compare features and choose an engine.
For implementation details, each engine page includes the complete usage flow for that engine.

- [Transition](transition.md) - CSS transitions, simplest setup
- [Keyframe](keyframes.md) - CSS @keyframes, pause/resume support
- [Sub](sub.md) - Elm subscriptions, full Elm-side control
- [WAAPI](waapi.md) - Web Animations API, browser-native with JS
- [Scroll Timeline](scroll-timeline.md) - fire-and-forget, progress tied to container scroll
- [View Timeline](view-timeline.md) - fire-and-forget, progress tied to viewport position

## Choosing an Engine

### Quick Recommendation

| Use Case | Recommended Engine |
| -------- | ------------------ |
| Simple hover/click effects | Transition |
| Entry animations and loops | Keyframe |
| Full Elm-side control and frame-level events | Sub |
| Broad feature set with browser-native playback | WAAPI |
| Animate from container scroll position | Scroll Timeline |
| Animate from viewport entry/exit position | View Timeline |

### Feature Comparison

| Feature | Transition | Keyframe | Sub | WAAPI | Scroll Timeline | View Timeline |
| ------- | :--------: | :------: | :-: | :---: | :-------------: | :-----------: |
| **Rendering** |
| Browser-native interpolation | ✓ | ✓ | | ✓ | ✓ | ✓ |
| Hardware acceleration | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| JavaScript required | | | | ✓ | ✓ | ✓ |
| **Playback** |
| Iterations | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Looping | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Alternate (ping-pong) | | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Animation Control** |
| Stop | ✓ | ✓ | ✓ | ✓ | | |
| Reset | ✓ | ✓ | ✓ | ✓ | | |
| Restart | | ✓ | ✓ | ✓ | | |
| Pause | | ✓ | ✓ | ✓ | | |
| Resume | | ✓ | ✓ | ✓ | | |
| **Events** |
| Run | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Started | ✓ | | ✓ | ✓ | ✓ | ✓ |
| Ended | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Cancelled | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Restarted | | ✓ | ✓ | ✓ | | |
| Paused | | ✓ | ✓ | ✓ | | |
| Resumed | | ✓ | ✓ | ✓ | | |
| Iteration | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Progress | | | ✓ | ✓ | ✓ | ✓ |
| **Mid-Flight Access** |
| Query current values | | | ✓ | ✓ | | |
| Smooth dynamic redirects | ✓ | | ✓ | ✓ | | |
| **Properties** |
| Custom transform order | | ✓ | ✓ | ✓ | ✓ | ✓ |
| Discrete properties | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

All engines work with responsive layouts; see [Responsive Animations](../concepts/responsive-animations.md) for the techniques available and which engines support measured-pixel updates.

"Smooth dynamic redirects" means retargeting from the current in-flight value without snapping. Keyframe still supports `retarget` for re-anchoring after layout truth changes, but it does not provide smooth in-flight redirects.

## Engine Families

### State-Tracked Engines

`Transition`, `Keyframe`, `Sub`, and `WAAPI` all use `AnimState`.

You initialize state, render attributes with state, and update state when engine messages arrive.

### Timeline Engines

`Scroll Timeline` and `View Timeline` are fire-and-forget.

They do not require `AnimState`.
You can optionally subscribe to lifecycle events if you need to react in `update`.

## Switching Engines

Animations are portable because builder pipelines are shared.
In most migrations, you primarily change:

- imports
- engine function calls
- return-type handling in `update`
- WAAPI/timeline ports when applicable

## Next Steps

Explore each engine page for complete usage flows:

- [Transition](transition.md)
- [Keyframe](keyframes.md)
- [Sub](sub.md)
- [WAAPI](waapi.md)
- [Scroll Timeline](scroll-timeline.md)
- [View Timeline](view-timeline.md)

[Transition Engine ->](transition.md){ .md-button .md-button--primary }
