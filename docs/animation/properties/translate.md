# Translate

Move elements in 2D or 3D space by animating their position.

**Module:** `Anim.Property.Translate`

**GPU Accelerated:** ✅

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Translate as Translate

    slideRight : AnimBuilder eng -> AnimBuilder eng
    slideRight =
        Translate.begin
            >> Translate.toX 100
            >> Translate.end
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
| `initXYZ` | `AnimGroupName -> Float -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X, Y, and Z position |
| `initXY` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X and Y position |
| `initXZ` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X and Z position |
| `initX` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X position |
| `initYZ` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Y and Z position |
| `initY` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Y position |
| `initZ` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Z position |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder eng -> Builder eng` | Start building |
| `build` | `Builder eng -> AnimBuilder eng` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `fromXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Starting X, Y, and Z positions |
| `fromXY` | `Float -> Float -> Builder eng -> Builder eng` | Starting X and Y positions |
| `fromXZ` | `Float -> Float -> Builder eng -> Builder eng` | Starting X and Z positions |
| `fromX` | `Float -> Builder eng -> Builder eng` | Starting X position (pixels) |
| `fromYZ` | `Float -> Float -> Builder eng -> Builder eng` | Starting Y and Z positions |
| `fromY` | `Float -> Builder eng -> Builder eng` | Starting Y position (pixels) |
| `fromZ` | `Float -> Builder eng -> Builder eng` | Starting Z position (pixels) |

### End Value (Absolute)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `toXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Ending X, Y, and Z positions |
| `toXY` | `Float -> Float -> Builder eng -> Builder eng` | Ending X and Y positions |
| `toXZ` | `Float -> Float -> Builder eng -> Builder eng` | Ending X and Z positions |
| `toX` | `Float -> Builder eng -> Builder eng` | Ending X position (pixels) |
| `toYZ` | `Float -> Float -> Builder eng -> Builder eng` | Ending Y and Z positions |
| `toY` | `Float -> Builder eng -> Builder eng` | Ending Y position (pixels) |
| `toZ` | `Float -> Builder eng -> Builder eng` | Ending Z position (pixels) |

### End Value (Relative)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `byXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Move by X, Y, and Z amounts |
| `byXY` | `Float -> Float -> Builder eng -> Builder eng` | Move by X and Y amounts |
| `byXZ` | `Float -> Float -> Builder eng -> Builder eng` | Move by X and Z amounts |
| `byX` | `Float -> Builder eng -> Builder eng` | Move by X amount |
| `byYZ` | `Float -> Float -> Builder eng -> Builder eng` | Move by Y and Z amounts |
| `byY` | `Float -> Builder eng -> Builder eng` | Move by Y amount |
| `byZ` | `Float -> Builder eng -> Builder eng` | Move by Z amount |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | Pixels per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

### Spring

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `spring` | `Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }` | Use spring physics instead of easing |

## Next Steps

Non-GPU Accelerated Properties.

[Non-GPU →](non-gpu.md){ .md-button .md-button--primary }

