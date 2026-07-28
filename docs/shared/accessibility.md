# Accessibility

Some people configure their operating system to **reduce motion** — because animation triggers motion sickness, vestibular disorders, migraines, or simply because they prefer a calmer interface. Browsers expose this as the [`prefers-reduced-motion`](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion) media query, and [WCAG 2.1 Success Criterion 2.3.3 (Animation from Interactions)](https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html) asks that you honour it.

Elm Motion's JavaScript-companion Engines honour this preference out of the box.

!!! note "Who this applies to"
    Reduced-motion handling is built into the [WAAPI](../animation/engines/waapi.md), [ScrollTimeline](../animation/engines/scroll-timeline.md) and [ViewTimeline](../animation/engines/view-timeline.md) Engines — the Engines that use the JavaScript companion. The pure-Elm `Transition`, `Keyframe` and `Sub` Engines do not read the media query themselves; see [Pure-Elm Engines](#pure-elm-engines) below for the recommended pattern there.

## What happens under reduced motion

When reduced motion is active, the companion **collapses each animation to its end state instead of playing it**:

- The element jumps straight to its authored destination — no visible movement.
- Looping animations settle at the end of their first iteration rather than repeating.
- Scroll- and view-driven animations are pinned to their end value rather than tracking the scroll position.
- The lifecycle events your Elm code relies on (`started` / `run`, then `completed`) **still fire**, so your Elm state stays exactly as consistent as it would after a normal animation.

Because the end state and the lifecycle are unchanged, your `update` logic does not need to know whether motion was reduced — the animation simply arrives instantly.

## Default behaviour

No configuration is required. By default the companion follows the operating-system setting: if the user has "reduce motion" enabled, animations snap; otherwise they play normally.

```javascript
import ElmMotion from '@phollyer/elm-motion';

const app = Elm.Main.init({ node: document.getElementById('app') });

// Nothing to do — prefers-reduced-motion is respected automatically.
ElmMotion.init(app.ports);
```

## Overriding the policy

Use `setReducedMotion` to override how the companion responds, for example to expose an in-app "reduce motion" toggle independent of the OS setting.

```javascript
import ElmMotion from '@phollyer/elm-motion';

// Follow the OS setting (the default).
ElmMotion.setReducedMotion('auto');

// Always snap to the end state, regardless of the OS setting.
ElmMotion.setReducedMotion('always');

// Always animate, ignoring the OS setting.
ElmMotion.setReducedMotion('never');
```

The mode is evaluated fresh for every animation, so you can flip it at runtime — for instance from a settings screen — and it takes effect on the next animation without re-initialising.

## API Reference

### `ElmMotion.setReducedMotion(mode)`

Set how the compositor-driven Engines respond to the user's motion preference.

```typescript
type ReducedMotionMode = 'auto' | 'always' | 'never';

function setReducedMotion(mode: ReducedMotionMode): void;
```

| Mode       | Behaviour                                                             |
| ---------- | -------------------------------------------------------------------- |
| `'auto'`   | Follow the OS `prefers-reduced-motion: reduce` setting. **Default.** |
| `'always'` | Always collapse animations to their end state.                       |
| `'never'`  | Always animate, ignoring the OS setting.                             |

An invalid mode is ignored and reported through the [error reporting](error-reporting.md) system with code `REDUCED_MOTION_MODE_INVALID`; the previous mode is left unchanged.

## Pure-Elm Engines

The `Transition`, `Keyframe` and `Sub` Engines run entirely in Elm and render inline styles, so they do not read `prefers-reduced-motion` directly. To honour the preference with these Engines, drive the choice from your own state and either skip the animation or use a near-zero duration when the user prefers reduced motion.

You can read the preference in JavaScript and pass it to Elm as a flag:

```javascript
const app = Elm.Main.init({
    node: document.getElementById('app'),
    flags: {
        prefersReducedMotion: window.matchMedia('(prefers-reduced-motion: reduce)').matches
    }
});
```

Then branch on that flag when you build or trigger the animation, choosing a very short duration (so the element still lands in the correct place) when reduced motion is preferred.
