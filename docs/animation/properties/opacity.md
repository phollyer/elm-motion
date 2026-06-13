# Opacity

Fade elements in and out by animating their opacity value.

**Module:** `Anim.Property.Opacity`

**GPU Accelerated:** ✅

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Opacity as Opacity

    fadeIn : AnimBuilder eng -> AnimBuilder eng
    fadeIn =
        Opacity.begin
            >> Opacity.to 1
            >> Opacity.end
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial opacity value |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `begin` | `AnimBuilder eng -> Builder eng` | Start building |
| `end` | `Builder eng -> AnimBuilder eng` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Float -> Builder eng -> Builder eng` | Start value (0.0 to 1.0) |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Float -> Builder eng -> Builder eng` | Absolute End value (0.0 to 1.0) |
| `by` | `Float -> Builder eng -> Builder eng` | Relative End value |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The rate of change per second - 0 -> 1 = 1 sec |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder eng -> Builder eng` | Add natural motion |

### Spring

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `spring` | `Spring -> Builder { eng | withSpring } -> Builder { eng | withSpring }` | Use spring physics instead of easing |


## Next Steps

The Rotate property.

[Rotate →](rotate.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }
