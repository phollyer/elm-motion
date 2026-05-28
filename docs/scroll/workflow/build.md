# Build

Every scroll starts as a **builder** - a small chain of functions that describes *what* to scroll, *how far*, and *how fast*. This page walks through the builder API.

The builder is the same in every engine. Once you've written it, you decide whether to run it with [Cmd](../engines/cmd.md), [Task](../engines/task.md), or [Sub](../engines/sub.md).

## Anatomy of a Builder

Every scroll has the same shape:

??? example "View Source Code"

    ```elm
    scrollToSection : ScrollBuilder -> ScrollBuilder
    scrollToSection =
        Scroll.forContainer "container-id"   -- 1. What surface to scroll       (required)
            >> Scroll.toElement "target-id"  -- 2. Where to scroll to
            >> Scroll.speed 300              -- 3. How fast (or use `duration`)
            >> Scroll.easing QuintOut        -- 4. How it should feel
            >> Scroll.build                  -- 5. Finalize                     (required)
    ```

Only steps 1 and 5 (`forContainer`/`forDocument` and `build`) are mandatory. Everything in between is optional - but without a target, the scroll has nowhere to go.

## 1. Pick a Surface

A scroll runs against either the whole document or a specific scrollable element.

### `forDocument`

Scrolls the page itself - the browser viewport. Use this for "jump to section" links inside a long article or single-page-app screen.

??? example "View Source Code"

    ```elm
    scrollPageToSection : String -> ScrollBuilder -> ScrollBuilder
    scrollPageToSection sectionId =
        Scroll.forDocument
            >> Scroll.toElement sectionId
            >> Scroll.speed 300
            >> Scroll.build
    ```

### `forContainer`

Scrolls a specific element identified by its `id`. Use this for sidebars, panels, tables, image galleries, modals - anything with its own scrollbar.

??? example "View Source Code"

    ```elm
    scrollPanelToItem : String -> ScrollBuilder -> ScrollBuilder
    scrollPanelToItem itemId =
        Scroll.forContainer "results-panel"
            >> Scroll.toElement itemId
            >> Scroll.speed 300
            >> Scroll.build
    ```

The element with `id="results-panel"` must actually be scrollable in CSS (`overflow: auto` / `overflow: scroll`).

## 2. Pick a Target

| Function | Scrolls to... |
| -------- | ------------- |
| `toElement id` | The element with the given `id` (both axes, by default). |
| `toTop` / `toBottom` | The top or bottom edge of the surface. |
| `toLeft` / `toRight` | The left or right edge of the surface. |
| `toTopLeft` / `toTopRight` / `toBottomLeft` / `toBottomRight` | The named corner. |
| `toCenter` | The centre of the surface. |
| `toX n` / `toY n` / `toXY x y` | Exact pixel coordinates. |
| `toPercentageX n` / `toPercentageY n` / `toPercentageXY x y` | A `0`–`100` percentage of the scrollable area. |

### Restricting to One Axis

`toElement` scrolls both axes by default. Add `onXAxis` or `onYAxis` to restrict it:

??? example "View Source Code"

    ```elm
    scrollGalleryToCard : String -> ScrollBuilder -> ScrollBuilder
    scrollGalleryToCard cardId =
        Scroll.forContainer "gallery"
            >> Scroll.toElement cardId
            >> Scroll.onXAxis            -- only move horizontally
            >> Scroll.speed 600
            >> Scroll.build
    ```

### Offsetting the Landing Position

`withOffsetX`, `withOffsetY`, and `withOffsetXY` shift the final scroll position. Useful for keeping sticky headers clear of the target:

??? example "View Source Code"

    ```elm
    scrollToCell : String -> ScrollBuilder -> ScrollBuilder
    scrollToCell cellId =
        Scroll.forContainer "spreadsheet"
            >> Scroll.toElement cellId
            >> Scroll.withOffsetXY -80 -40   -- leave room for sticky row + column
            >> Scroll.speed 800
            >> Scroll.build
    ```

## 3. Pick Timing and Easing

📖 See [Timing](../concepts/timing.md) and [Easing](../concepts/easing.md) for the full rundown.

The short version:

- `speed n` - pixels per second. Best default for most scrolling.
- `duration n` - milliseconds. Useful when distances are all similar.
- `delay n` - milliseconds to wait before starting.
- `easing e` - any easing curve from `Motion.Easing`.

## 4. Multiple Scrolls in One Builder

You can chain several `build` calls into a single pipeline. Each one becomes a separate scroll - they can target different surfaces and have different settings:

??? example "View Source Code"

    ```elm
    resetBothPanels : ScrollBuilder -> ScrollBuilder
    resetBothPanels =
        Scroll.forContainer "results-panel"
            >> Scroll.toTop
            >> Scroll.speed 300
            >> Scroll.build
            >> Scroll.forContainer "chat-panel"
            >> Scroll.toBottom
            >> Scroll.speed 300
            >> Scroll.build
    ```

How that runs depends on the engine: [Cmd](../engines/cmd.md) fires both at once, [Task](../engines/task.md) runs them in pipeline order, [Sub](../engines/sub.md) tracks each independently.

## Reusable Helpers

Extract recurring settings into a small helper and compose it into other builders:

??? example "View Source Code"

    ```elm
    withStandardTiming : ScrollBuilder -> ScrollBuilder
    withStandardTiming =
        Scroll.speed 300
            >> Scroll.easing QuintOut


    scrollToSection : String -> ScrollBuilder -> ScrollBuilder
    scrollToSection sectionId =
        withStandardTiming
            >> Scroll.forDocument
            >> Scroll.toElement sectionId
            >> Scroll.build
    ```

## Next Steps

The builder doesn't *do* anything on its own - it just describes the scroll. Next, hand it to an engine to run it.

[Trigger →](trigger.md){ .md-button .md-button--primary }
