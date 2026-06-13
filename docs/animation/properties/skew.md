# Skew

Skew elements along the X and Y axes.

**Module:** `Anim.Property.Skew`

**GPU Accelerated:** ✅

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Skew as Skew

    tilt : AnimBuilder eng -> AnimBuilder eng
    tilt =
        Skew.begin
            >> Skew.toXY 12 0
            >> Skew.end
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `initXY` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X and Y skew |
| `initX` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X skew |
| `initY` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Y skew |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder eng -> Builder eng` | Start building |
| `build` | `Builder eng -> AnimBuilder eng` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `fromXY` | `Float -> Float -> Builder eng -> Builder eng` | Starting X and Y skew (degrees) |
| `fromX` | `Float -> Builder eng -> Builder eng` | Starting X skew (degrees) |
| `fromY` | `Float -> Builder eng -> Builder eng` | Starting Y skew (degrees) |

### End Value (Absolute)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toXY` | `Float -> Float -> Builder eng -> Builder eng` | Ending X and Y skew (degrees) |
| `toX` | `Float -> Builder eng -> Builder eng` | Ending X skew (degrees) |
| `toY` | `Float -> Builder eng -> Builder eng` | Ending Y skew (degrees) |

### End Value (Relative)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `byXY` | `Float -> Float -> Builder eng -> Builder eng` | Skew by X and Y amounts (degrees) |
| `byX` | `Float -> Builder eng -> Builder eng` | Skew by X amount (degrees) |
| `byY` | `Float -> Builder eng -> Builder eng` | Skew by Y amount (degrees) |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | Delay in ms before animation starts |
| `duration` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | Duration in ms |
| `speed` | `Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | Degrees per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

### Spring

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `spring` | `Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }` | Use spring physics instead of easing |

## Next Steps

The Translate property.

[Translate →](translate.md){ .md-button .md-button--primary }
