# Scale

Scale elements uniformly or independently on each axis.

**Module:** `Anim.Property.Scale`

**GPU Accelerated:** ✅

## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Scale as Scale

    grow : AnimBuilder eng -> AnimBuilder eng
    grow =
        Scale.begin
            >> Scale.to 1.5
            >> Scale.end
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

 eng

### Types eng

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial scale (uniform) |
| `initXYZ` | `AnimGroupName -> Float -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X, Y, and Z scale |
| `initXY` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X and Y scale |
| `initXZ` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X and Z scale |
| `initX` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial X scale |
| `initYZ` | `AnimGroupName -> Float -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Y and Z scale |
| `initY` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Y scale |
| `initZ` | `AnimGroupName -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial Z scale |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> AnimBuilder eng -> Builder eng` | Start building |
| `build` | `Builder eng -> AnimBuilder eng` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Float -> Builder eng -> Builder eng` | Starting scale (uniform, 1.0 = 100%) |
| `fromXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Starting X, Y, and Z scales |
| `fromXY` | `Float -> Float -> Builder eng -> Builder eng` | Starting X and Y scales |
| `fromXZ` | `Float -> Float -> Builder eng -> Builder eng` | Starting X and Z scales |
| `fromX` | `Float -> Builder eng -> Builder eng` | Starting X-axis scale |
| `fromYZ` | `Float -> Float -> Builder eng -> Builder eng` | Starting Y and Z scales |
| `fromY` | `Float -> Builder eng -> Builder eng` | Starting Y-axis scale |
| `fromZ` | `Float -> Builder eng -> Builder eng` | Starting Z-axis scale |

### End Value (Absolute)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Float -> Builder eng -> Builder eng` | Ending scale (uniform, 1.0 = 100%) |
| `toXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Ending X, Y, and Z scales |
| `toXY` | `Float -> Float -> Builder eng -> Builder eng` | Ending X and Y scales |
| `toXZ` | `Float -> Float -> Builder eng -> Builder eng` | Ending X and Z scales |
| `toX` | `Float -> Builder eng -> Builder eng` | Ending X-axis scale |
| `toYZ` | `Float -> Float -> Builder eng -> Builder eng` | Ending Y and Z scales |
| `toY` | `Float -> Builder eng -> Builder eng` | Ending Y-axis scale |
| `toZ` | `Float -> Builder eng -> Builder eng` | Ending Z-axis scale |

### End Value (Relative)

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `byXYZ` | `Float -> Float -> Float -> Builder eng -> Builder eng` | Scale by X, Y, and Z amounts |
| `byXY` | `Float -> Float -> Builder eng -> Builder eng` | Scale by X and Y amounts |
| `byXZ` | `Float -> Float -> Builder eng -> Builder eng` | Scale by X and Z amounts |
| `byX` | `Float -> Builder eng -> Builder eng` | Scale by X amount |
| `byYZ` | `Float -> Float -> Builder eng -> Builder eng` | Scale by Y and Z amounts |
| `byY` | `Float -> Builder eng -> Builder eng` | Scale by Y amount |
| `byZ` | `Float -> Builder eng -> Builder eng` | Scale by Z amount |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder { eng | withTiming : () } -> Builder { eng | withTiming : () }` | Scale units per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

### Spring

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `spring` | `Spring -> Builder { eng | withSpring : () } -> Builder { eng | withSpring : () }` | Use spring physics instead of easing |

## Next Steps

The Skew property.

[Skew →](skew.md){ .md-button .md-button--primary }

