# Installation

## Elm Package

Install the Elm package:

```bash
elm install phollyer/elm-motion
```

## WAAPI JavaScript

If you plan to use the [WAAPI Engine](animation/engines/waapi.md), [Scroll Timeline Engine](animation/engines/scroll-timeline.md), or [View Timeline Engine](animation/engines/view-timeline.md), you'll also need the JavaScript companion:

=== "CDN"

    Add the script tag before your Elm app script:

    ```html
    <script src="https://unpkg.com/@phollyer/elm-motion/elm-motion.js"></script>
    ```

    Then initialise it:

    ```html
    <script>
        const app = Elm.Main.init({
            node: document.getElementById('app')
        });

        ElmMotion.init(app.ports);
    </script>
    ```

=== "npm"

    ```bash
    npm install @phollyer/elm-motion
    ```

    Then initialise it:

    ```javascript
    import ElmMotion from '@phollyer/elm-motion';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmMotion.init(app.ports);
    ```

=== "yarn"

    ```bash
    yarn add @phollyer/elm-motion
    ```

    Then initialise it:
    
    ```javascript
    import ElmMotion from '@phollyer/elm-motion';

    const app = Elm.Main.init({
        node: document.getElementById('app')
    });

    ElmMotion.init(app.ports);
    ```

## Version Compatibility

The Elm package and the `@phollyer/elm-motion` companion carry separate version numbers - they do not need to match. Any `1.x` companion works with any `1.x` Elm package.

The companion is only needed for the WAAPI, ScrollTimeline and ViewTimeline engines. The Transition, Keyframe and Sub engines, and all scroll engines, are pure Elm and need no JavaScript.

## Handling JS Runtime Errors

The JS is silent by default. To surface internal warnings during development or forward errors to a service in production, opt in via `ElmMotion.useConsoleReporter()` or `ElmMotion.onError(handler)`. See the [Error Reporting guide](shared/error-reporting.md) for the full API and the list of error codes.

## Tearing down and re-initialising

Most apps call `ElmMotion.init(app.ports)` once at startup and never need to think about cleanup — completed and cancelled animations release their per-element state automatically, and calling `init` again with a different ports object disposes the previous state for you.

The one case that needs explicit teardown is unmounting the Elm app without re-initialising — for example, a vanilla-JS host that removes the Elm widget from the page - for that there is `dispose()`:

```javascript
// clear internal state and ports references
// release references to DOM elements so they can be garbage collected
ElmMotion.dispose();
```

## Throttling per-frame property updates

When using the WAAPI Engine, the JS companion will emit progress events on each animation frame so subscribers reading live mid-animation values see them at the display refresh rate — 60 Hz, 120 Hz, 144 Hz, etc.

This is almost always what you want. Visual playback runs on the browser compositor and is unaffected by the emission rate; only the cadence of port traffic into Elm is. If your app runs many simultaneous animations on a high-refresh display and the resulting port traffic becomes a bottleneck, cap the rate with:

```javascript
ElmMotion.setPropertyUpdateThrottle(16);   // ~60 Hz
ElmMotion.setPropertyUpdateThrottle(33);   // ~30 Hz
ElmMotion.setPropertyUpdateThrottle(0);    // restore default (no throttle)
```

The value is the minimum interval, in milliseconds, between two progress emissions for the same animation. It can be changed at any time and applies to every animation that runs after the call. Non-numeric or negative values are ignored and reported as a `THROTTLE_INVALID` warning.

The same setting is reachable from Elm via [`WAAPI.setUpdateThrottle`](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/Anim-Engine-WAAPI#setUpdateThrottle), so apps that prefer to keep configuration in Elm can call it from `init` (or dynamically from `update`):

```elm
init flags =
    let
        animState =
            WAAPI.init motionCmd motionMsg []
    in
    ( { animState = animState }
    , WAAPI.setUpdateThrottle 16 animState
    )
```

## Next Steps

Now that you have the package installed, let's start using it:

[Your First Animations](animation/start-here.md){ .md-button .md-button--primary }
or
[Your First Scrolls](scroll/start-here.md){ .md-button .md-button--primary }
