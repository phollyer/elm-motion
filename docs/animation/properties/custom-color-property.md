# Custom Color Property

Animate any color CSS property.

**Module:** `Anim.Property.CustomColor`

**GPU Accelerated:** No


## Example

--8<-- "docs/animation/properties/custom-color-property/border-color.md:examples"

--8<-- "docs/animation/properties/custom-color-property/border-color.md:code"


## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Extra.Color as Color
    import Anim.Property.CustomColor as CustomColor

    borderColorAnimation : AnimBuilder eng -> AnimBuilder eng
    borderColorAnimation =
        CustomColor.for "animGroup" CustomColor.BorderColor
            >> CustomColor.to (Color.rgb 255 0 0)
            >> CustomColor.duration 500
            >> CustomColor.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |
| `ColorProperty` | Typed property names |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> ColorProperty -> Color -> AnimBuilder eng -> AnimBuilder eng` | Set the initial color — takes group name, typed color property, and color |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> ColorProperty -> AnimBuilder eng -> Builder mode` | Start building — takes group name and typed color property |
| `build` | `Builder mode -> AnimBuilder eng` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Color -> Builder -> Builder` | Starting color |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Color -> Builder -> Builder` | Ending color |

### Timing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `delay` | `Int -> Builder -> Builder` | The delay in ms before the animation starts |
| `duration` | `Int -> Builder -> Builder` | The duration in ms that the animation lasts for |
| `speed` | `Float -> Builder -> Builder` | The rate of change per second |

### Easing

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `easing` | `Easing -> Builder -> Builder` | Add natural motion |

### Spring

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `spring` | `Spring -> Builder -> Builder` | Use spring physics instead of easing |


## Next Steps

Learn about animating with Discrete Properties.

[Discrete Properties →](../concepts/discrete-properties.md){ .md-button .md-button--primary }
