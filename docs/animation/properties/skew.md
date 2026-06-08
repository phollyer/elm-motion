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
            >> Skew.duration 400
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
| `fromXY` | `Float -> Float -> Builder -> Builder` | Starting X and Y skew (degrees) |
| `fromX` | `Float -> Builder -> Builder` | Starting X skew (degrees) |
| `fromY` | `Float -> Builder -> Builder` | Starting Y skew (degrees) |

### End Value (Absolute)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toXY` | `Float -> Float -> Builder -> Builder` | Ending X and Y skew (degrees) |
| `toX` | `Float -> Builder -> Builder` | Ending X skew (degrees) |
| `toY` | `Float -> Builder -> Builder` | Ending Y skew (degrees) |

### End Value (Relative)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `byXY` | `Float -> Float -> Builder -> Builder` | Skew by X and Y amounts (degrees) |
| `byX` | `Float -> Builder -> Builder` | Skew by X amount (degrees) |
| `byY` | `Float -> Builder -> Builder` | Skew by Y amount (degrees) |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder -> Builder` | Delay in ms before animation starts |
| `duration` | `Int -> Builder -> Builder` | Duration in ms |
| `speed` | `Float -> Builder -> Builder` | Degrees per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

### Spring

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `spring` | `Spring -> Builder -> Builder` | Use spring physics instead of easing |

## Next Steps

The Scale property.

[Scale →](scale.md){ .md-button .md-button--primary }
