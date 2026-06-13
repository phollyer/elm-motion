# Rotate

Rotate elements around the X, Y, and Z axes.

**Module:** `Anim.Property.Rotate`

**GPU Accelerated:** ✅

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Rotate as Rotate

    spin : AnimBuilder eng -> AnimBuilder eng
    spin =
        Rotate.begin
            >> Rotate.toZ 360
            >> Rotate.end
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
| `initXYZ` | `AnimGroupName -> Float -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X, Y, and Z rotation |
| `initXY` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X and Y rotation |
| `initXZ` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X and Z rotation |
| `initX` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X rotation |
| `initYZ` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Y and Z rotation |
| `initY` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Y rotation |
| `initZ` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Z rotation |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `begin` | `AnimGroupName -> AnimBuilder eng -> Builder eng` | Start building |
| `end` | `Builder eng -> AnimBuilder eng` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `fromXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Starting X, Y, and Z rotations (degrees) |
| `fromXY` | `Float -> Float -> Builder eng -> Builder eng` | Starting X and Y rotations (degrees) |
| `fromXZ` | `Float -> Float -> Builder eng -> Builder eng` | Starting X and Z rotations (degrees) |
| `fromX` | `Float -> Builder eng -> Builder eng` | Starting X-axis rotation (degrees) |
| `fromYZ` | `Float -> Float -> Builder eng -> Builder eng` | Starting Y and Z rotations (degrees) |
| `fromY` | `Float -> Builder eng -> Builder eng` | Starting Y-axis rotation (degrees) |
| `fromZ` | `Float -> Builder eng -> Builder eng` | Starting Z-axis rotation (degrees) |

### End Value (Absolute)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Ending X, Y, and Z rotations (degrees) |
| `toXY` | `Float -> Float -> Builder eng -> Builder eng` | Ending X and Y rotations (degrees) |
| `toXZ` | `Float -> Float -> Builder eng -> Builder eng` | Ending X and Z rotations (degrees) |
| `toX` | `Float -> Builder eng -> Builder eng` | Ending X-axis rotation (degrees) |
| `toYZ` | `Float -> Float -> Builder eng -> Builder eng` | Ending Y and Z rotations (degrees) |
| `toY` | `Float -> Builder eng -> Builder eng` | Ending Y-axis rotation (degrees) |
| `toZ` | `Float -> Builder eng -> Builder eng` | Ending Z-axis rotation (degrees) |

### End Value (Relative)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `byXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Rotate by X, Y, and Z amounts (degrees) |
| `byXY` | `Float -> Float -> Builder eng -> Builder eng` | Rotate by X and Y amounts (degrees) |
| `byXZ` | `Float -> Float -> Builder eng -> Builder eng` | Rotate by X and Z amounts (degrees) |
| `byX` | `Float -> Builder eng -> Builder eng` | Rotate by X amount (degrees) |
| `byYZ` | `Float -> Float -> Builder eng -> Builder eng` | Rotate by Y and Z amounts (degrees) |
| `byY` | `Float -> Builder eng -> Builder eng` | Rotate by Y amount (degrees) |
| `byZ` | `Float -> Builder eng -> Builder eng` | Rotate by Z amount (degrees) |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The duration in ms that the animation lasts for |
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

The Scale property.

[Scale →](scale.md){ .md-button .md-button--primary }

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }
