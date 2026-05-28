## Spring Presets

Springs describe physical motion — stiffness, damping, mass — rather than time-and-curve. Their duration is _emergent_: the motion ends when the value has settled at the target. This makes springs the right primitive for anything that should feel physical: bouncy reveals, gesture-handoff momentum, anything where a tween's fixed-duration ramp would feel artificial.

All presets live in [`Motion.Spring`](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Motion-Spring).

### gentle

A soft, slow settle. Mild overshoot, takes its time.

Good for: hero-element reveals, large modals, anything where a sense of weight is welcome.

### wobbly

Lively and bouncy. Several visible oscillations before settling.

Good for: playful UI accents, attention-grabbing reveals, cartoony interactions.

### stiff

Snappy and direct. Small overshoot, settles quickly.

Good for: button presses, tooltip reveals, anything that should feel crisp and immediate.

### slow

Low stiffness with extra damping — a long, mellow approach.

Good for: ambient motion, slow-developing reveals, drifting-into-place effects.

### noWobble

Critically damped — the fastest approach to the target with no overshoot whatsoever.

Good for: when you want spring-like timing but tween-like absence of overshoot. Useful for scroll handoffs and other places where bounce would look like a bug.

## Custom

Hand-tune a spring's physics via [`Motion.Spring.custom`](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Motion-Spring#custom):

```elm
Motion.Spring.custom
    { stiffness = 220   -- Hooke's-law k. Higher = snappier. Typical 100..400.
    , damping = 16      -- viscous friction. Higher = less wobbly. Typical 10..40.
    , mass = 1          -- oscillator mass. Heavier = more sluggish. Typical 1.0.
    }
```

The damping ratio `c / (2·√(k·m))` decides the regime:

| Ratio | Regime | Feel |
| ----- | ------ | ---- |
| `< 1` | Under-damped | Oscillates and decays |
| `= 1` | Critically damped | Fastest no-overshoot settle |
| `> 1` | Over-damped | Slow no-overshoot approach |

Inputs are clamped: stiffness and damping below `0` become `0`; mass below `1e-6` becomes `1e-6`.
