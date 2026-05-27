## Standard Easings

These are the standard easing curves calculated using the functions from [elm-community/easing-functions](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease).

### Linear

Constant speed throughout. Useful when you want neutral movement with no acceleration or deceleration.

### Ease

The standard CSS easing functions.

| Easing | Feel |
| -------- | ------ |
| `EaseIn` | Starts slow, ends fast |
| `EaseOut` | Starts fast, ends slow |
| `EaseInOut` | Slow at both ends |

### Sine

Gentle, subtle easing based on sine curve.

| Easing | Feel |
| -------- | ------ |
| `SineIn` | Gentle acceleration |
| `SineOut` | Gentle deceleration |
| `SineInOut` | Gentle both ends |

### Quad

Quadratic (power of 2) — slightly more pronounced than sine.

| Easing | Feel |
| -------- | ------ |
| `QuadIn` | Moderate acceleration |
| `QuadOut` | Moderate deceleration |
| `QuadInOut` | Moderate both ends |

### Cubic

Cubic (power of 3) — more noticeable acceleration/deceleration.

| Easing | Feel |
| -------- | ------ |
| `CubicIn` | Noticeable acceleration |
| `CubicOut` | Noticeable deceleration |
| `CubicInOut` | Noticeable both ends |

### Quart

Quartic (power of 4) — dramatic effect.

| Easing | Feel |
| -------- | ------ |
| `QuartIn` | Strong acceleration |
| `QuartOut` | Strong deceleration |
| `QuartInOut` | Strong both ends |

### Quint

Quintic (power of 5) — very dramatic.

| Easing | Feel |
| -------- | ------ |
| `QuintIn` | Very strong acceleration |
| `QuintOut` | Very strong deceleration |
| `QuintInOut` | Very strong both ends |

### Expo

Exponential — extremely dramatic.

| Easing | Feel |
| -------- | ------ |
| `ExpoIn` | Explosive acceleration |
| `ExpoOut` | Explosive deceleration |
| `ExpoInOut` | Explosive both ends |

### Circ

Circular — based on quarter circle.

| Easing | Feel |
| -------- | ------ |
| `CircIn` | Circular acceleration |
| `CircOut` | Circular deceleration |
| `CircInOut` | Circular both ends |

### Back

Overshoots slightly then returns.

| Easing | Feel |
| -------- | ------ |
| `BackIn` | Pulls back then accelerates |
| `BackOut` | Overshoots then settles |
| `BackInOut` | Both effects |

### Elastic

Spring-like bounce effect.

| Easing | Feel |
| -------- | ------ |
| `ElasticIn` | Winds up like a spring |
| `ElasticOut` | Springs and oscillates |
| `ElasticInOut` | Both effects |

### Bounce

Bouncing ball effect.

| Easing | Feel |
| -------- | ------ |
| `BounceIn` | Bounces at start |
| `BounceOut` | Bounces at end |
| `BounceInOut` | Both effects |

### CubicBezier

Custom easing curve defined by two control points — the same format used by CSS `cubic-bezier()`.

??? example "View Source Code"

    ```elm
    CubicBezier 0.68 -0.55 0.265 1.55
    ```

The four parameters (`x1 y1 x2 y2`) define the curve's control points. Use tools like [cubic-bezier.com](https://cubic-bezier.com) to visualize and create custom curves.
