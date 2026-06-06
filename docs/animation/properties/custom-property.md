# Custom Property

Animate any numeric CSS property with a unit. This is an escape hatch for CSS properties not covered by the first-class property modules.

**Module:** `Anim.Property.Custom`

**GPU Accelerated:** No — the only GPU-accelerated numeric property is opacity, which has its own [first-class module](opacity.md).

## Example

--8<-- "docs/animation/properties/custom-property/border-radius.md:examples"

--8<-- "docs/animation/properties/custom-property/border-radius.md:code"


## Basic Usage

??? example "View Source Code"

    ```elm
    import Anim.Property.Custom as Property exposing (Property(..))
    import Anim.Unit exposing (Unit(..))

    borderRadiusAnimation : AnimBuilder eng -> AnimBuilder eng
    borderRadiusAnimation =
        Property.for "animGroup" (BorderRadius Px)
            >> Property.to 24
            >> Property.duration 500
            >> Property.build
    ```

See the [Properties Overview](overview.md) page for the shared usage patterns.

!!! tip "When to use `Anim.Property.Custom`"
    Use this module when Elm Motion doesn't provide a first-class module for the CSS property you need to animate. For color-based properties, use [`Anim.Property.CustomColor`](custom-color-property.md) instead.

## API

### Types

| Type | Description |
| -------- | ----------- |
| `Builder` | Alias for the Internal builder used to configure the animation |
| `AnimGroupName` | Alias for the animation group name |
| `Property` | Typed property names |

### Initialization

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `init` | `AnimGroupName -> Property -> Float -> AnimBuilder eng -> AnimBuilder eng` | Set the initial value — takes group name, CSS property (with unit embedded), and value |

### Build

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `for` | `AnimGroupName -> Property -> AnimBuilder eng -> Builder eng` | Start building — takes group name and CSS property (with unit embedded) |
| `build` | `Builder eng -> AnimBuilder eng` | Finish building |

### Start Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `from` | `Float -> Builder -> Builder` | Start value |

### End Value

| Function | Signature | Description |
| -------- | --------- | ----------- |
| `to` | `Float -> Builder -> Builder` | Absolute End value |
| `by` | `Float -> Builder -> Builder` | Relative End value |

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

The Custom Color Property.

[Custom Color Property →](custom-color-property.md){ .md-button .md-button--primary }
