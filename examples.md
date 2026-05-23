# View Requirements for Examples

## Layout

- All examples should be responsive so that they play nicely on all devices

### Iframes

- they should expand to the full width of the device, maxing out at 600px
- they should expand to the full height of the device, with a min of 400px and max of 600px


### Elm View

- The body should be 100vh x 100vw
- The animation stage area shoud be 90vh x 90vw
- The animation stage area should sit middle centered on the page
- If the example does not currently use a visible stage area, it should be added, and should match the global styling for the stage area.
- All buttons should be styled the same across all examples, with only label and background color differentiating them to the viewer in each example
- All examples should be tagged in some way signify whether the Engine is responsive

---

## Engine × Example coverage grid

### Animation

| Example | Transition | Keyframe | Sub | WAAPI |
|---|:-:|:-:|:-:|:-:|
| Animate3D | ✓ | ✓ | ✓ | ✓ |
| BorderColor | ✓ | ✓ | ✓ | ✓ |
| BorderRadius | ✓ | ✓ | ✓ | ✓ |
| ButtonHovers | ✓ | ✓ | ✓ | ✓ |
| ControllingAnimations | ✓ | ✓ | ✓ | ✓ |
| DiscreteProperties | ✓ | ✓ | ✓ | ✓ |
| FadeInOut | ✓ | ✓ | ✓ | ✓ |
| HelloText | ✓ | ✓ | ✓ | ✓ |
| InterruptingAnimations/FreezeAxis | — | — | ✓ | ✓ |
| InterruptingAnimations/MultipleAxes | ✓ | ✓ | ✓ | ✓ |
| InterruptingAnimations/MultipleProperties | ✓ | ✓ | ✓ | ✓ |
| InterruptingAnimations/SingleProperty | ✓ | ✓ | ✓ | ✓ |
| ResponsiveAnimations/Responsive | — | — | ✓ | ✓ |
| TransformOrder | — | ✓ | ✓ | ✓ |

Standalone: `Animation/ScrollTimeline`, `Animation/ViewTimeline` (no engine cross-axis).

### Scroll

| Example | Cmd | Sub | Task |
|---|:-:|:-:|:-:|
| ControllingScrolls | — | ✓ | — |
| FirstScroll | ✓ | ✓ | ✓ |
| HorizontalGallery | ✓ | ✓ | ✓ |
| Spreadsheet | ✓ | ✓ | ✓ |

---

## Test checklist

Suggested Status values: `OK`, `FIX`, `BLOCK`, `?`.

### Animation

| # | Engine | Example | Status | Notes |
|---:|---|---|:-:|---|
| 1 | Transition | Animate3D | OK |  |
| 2 | Transition | BorderColor | OK |  |
| 3 | Transition | BorderRadius | OK |  |
| 4 | Transition | ButtonHovers | OK |  |
| 5 | Transition | ControllingAnimations | OK |  |
| 6 | Transition | DiscreteProperties | OK |  |
| 7 | Transition | FadeInOut | OK |  |
| 8 | Transition | HelloText | OK |  |
| 9 | Transition | InterruptingAnimations/MultipleAxes | OK |  |
| 10 | Transition | InterruptingAnimations/MultipleProperties | OK |  |
| 11 | Transition | InterruptingAnimations/SingleProperty | OK |  |
| 12 | Keyframe | Animate3D | FIX | Labels on each side need to scale with the side or the text overflows as the side scales down |
| 13 | Keyframe | BorderColor | OK |  |
| 14 | Keyframe | BorderRadius | OK |  |
| 15 | Keyframe | ButtonHovers | OK |  |
| 16 | Keyframe | ControllingAnimations | OK |  |
| 17 | Keyframe | DiscreteProperties | OK |  |
| 18 | Keyframe | FadeInOut | OK |  |
| 19 | Keyframe | HelloText | OK |  |
| 20 | Keyframe | InterruptingAnimations/MultipleAxes | OK |  |
| 21 | Keyframe | InterruptingAnimations/MultipleProperties | OK |  |
| 22 | Keyframe | InterruptingAnimations/SingleProperty | OK |  |
| 23 | Keyframe | TransformOrder |  |  |
| 24 | Sub | Animate3D | OK |  |
| 25 | Sub | BorderColor | OK |  |
| 26 | Sub | BorderRadius | OK |  |
| 27 | Sub | ButtonHovers | OK |  |
| 28 | Sub | ControllingAnimations | FIX | Once the animation has completed, and been Reset, the Resume button, if clicked will restart the animation, this is wrong behaviour. The Resume functionality should only be active during a Pause, like the keyframe and waapi engines. This is an Engine fix **not** an example fix. |
| 29 | Sub | DiscreteProperties | OK |  |
| 30 | Sub | FadeInOut | OK |  |
| 31 | Sub | HelloText | OK |  |
| 32 | Sub | InterruptingAnimations/FreezeAxis | OK |  |
| 33 | Sub | InterruptingAnimations/MultipleAxes | OK |  |
| 34 | Sub | InterruptingAnimations/MultipleProperties | OK |  |
| 35 | Sub | InterruptingAnimations/SingleProperty | OK |  |
| 36 | Sub | ResponsiveAnimations/Responsive |  |  |
| 37 | Sub | TransformOrder |  |  |
| 38 | WAAPI | Animate3D | OK |  |
| 39 | WAAPI | BorderColor | OK |  |
| 40 | WAAPI | BorderRadius | OK |  |
| 41 | WAAPI | ButtonHovers | OK |  |
| 42 | WAAPI | ControllingAnimations | OK |  |
| 43 | WAAPI | DiscreteProperties | OK |  |
| 44 | WAAPI | FadeInOut | OK |  |
| 45 | WAAPI | HelloText | OK |  |
| 46 | WAAPI | InterruptingAnimations/FreezeAxis | OK |  |
| 47 | WAAPI | InterruptingAnimations/MultipleAxes | OK |  |
| 48 | WAAPI | InterruptingAnimations/MultipleProperties | OK |  |
| 49 | WAAPI | InterruptingAnimations/SingleProperty | OK |  |
| 50 | WAAPI | ResponsiveAnimations/Responsive |  |  |
| 51 | WAAPI | TransformOrder |  |  |
| 52 | ScrollTimeline | (standalone) | OK |  |
| 53 | ViewTimeline | (standalone) | FIX | The panel number and title need to switch to column layout. |

### Scroll

| # | Engine | Example | Status | Notes |
|---:|---|---|:-:|---|
| 54 | Cmd | FirstScroll |  |  |
| 55 | Cmd | HorizontalGallery |  |  |
| 56 | Cmd | Spreadsheet |  |  |
| 57 | Sub | ControllingScrolls |  |  |
| 58 | Sub | FirstScroll |  |  |
| 59 | Sub | HorizontalGallery |  |  |
| 60 | Sub | Spreadsheet |  |  |
| 61 | Task | FirstScroll |  |  |
| 62 | Task | HorizontalGallery |  |  |
| 63 | Task | Spreadsheet |  |  |

