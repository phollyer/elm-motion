# The Scroll Builder

Almost everything you'll ever write for scrolling lives in the **builder**: a small chain of functions that describes *what* to scroll, *how far*, and *how fast*.

The builder doesn't actually scroll anything on its own. It produces a value that one of the three engines ([Cmd](engines/cmd.md), [Task](engines/task.md), [Sub](engines/sub.md)) can run. The same builder works in every engine - only the wiring around it changes.

## Anatomy

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

---

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

---

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

### Restrict to One Axis

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

Useful if the container scrolls in both directions, but you just want to scroll to the vertical or horizontal position of the target.

### Offset the Landing Position

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

---

## 3. Timing

Pick **one** of `speed` or `duration` - `speed` is the better default for most scrolling.

| Function | What it means |
| -------- | ------------- |
| `speed n` | Move at `n` pixels per second. The duration depends on how far we have to scroll. |
| `duration n` | Take exactly `n` ms, regardless of distance. |
| `delay n` | Wait `n` ms before starting the scroll. |

If you set neither `speed` nor `duration`, the engine treats the duration as `0ms` and snaps instantly to the target.

📖 See [Timing](concepts/timing.md) for the full rundown, including why `speed` usually feels better.

---

## 4. Easing

Easing controls the *shape* of the motion - whether the scroll whooshes off and glides to a halt, ramps up gradually, or bounces past before settling.

??? example "View Source Code"

    ```elm
    Scroll.forDocument
        >> Scroll.toElement "features"
        >> Scroll.speed 800
        >> Scroll.easing QuintOut
        >> Scroll.build
    ```

Defaults to `Linear` if you don't set one.

📖 See [Easing](concepts/easing.md) for the full list and recommendations.

---

## Multiple Scrolls in One Builder

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

How that runs depends on the engine:

- [`Cmd`](engines/cmd.md) fires both at once.
- [`Task`](engines/task.md) runs them in pipeline order, fail-fast.
- [`Sub`](engines/sub.md) tracks each container independently.

---

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

---

## Running a Builder

A builder is just a description. To actually make something move, hand it to one of the engines from `update`. Same builder, three wirings:

??? example "View Source Code"

    === "Cmd"

        ```elm
        import Scroll.Engine.Cmd as Cmd


        ScrollTo targetId ->
            ( model
            , Cmd.scroll ScrollComplete <|
                scrollToSection targetId
            )
        ```

    === "Task"

        ```elm
        import Scroll.Engine.Task as Task
        import Task as TaskCore


        ScrollTo targetId ->
            ( model
            , scrollToSection targetId
                |> Task.scroll
                |> TaskCore.attempt GotScrollResult
            )
        ```

    === "Sub"

        ```elm
        import Scroll.Engine.Sub as Sub


        ScrollTo targetId ->
            let
                ( newScrollState, scrollCmd ) =
                    Sub.scroll GotScrollMsg model.scrollState <|
                        scrollToSection targetId
            in
            ( { model | scrollState = newScrollState }, scrollCmd )
        ```

## Next Steps

You've seen what the builder can describe. Next, pick the engine that fits your case.

[Engines Overview →](engines/overview.md){ .md-button .md-button--primary }
