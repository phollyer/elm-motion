# Start Here

## What is a Scroll Animation?

When the user clicks "Back to top" and the page glides up smoothly instead of jumping, that's a scroll animation. The browser already knows how to *jump* an element to a new scroll position - this library knows how to *animate* it there.

Elm Motion lets you animate the scroll position of:

- the whole **document** (the page itself), or
- any **scrollable container** in your view (a sidebar, a film strip, a spreadsheet).

You describe *what* to scroll to using a shared builder pipeline, then pick the engine that gives you the level of control you need.

## The Three Scroll Engines

| Engine | One-liner |
| ------ | --------- |
| [`Scroll.Cmd`](engines/cmd.md) | Fire-and-forget. The simplest possible setup. |
| [`Scroll.Task`](engines/task.md) | Like `Cmd`, but returns a `Task` so you get typed success/failure results. |
| [`Scroll.Sub`](engines/sub.md) | Stateful. Subscribes for frame updates. Lets you pause, resume, stop, query position, react to progress events, and interrupt scrolls mid-flight. |

All three share the same `Scroll.Builder` pipeline, so the way you *describe* a scroll never changes. Only the way you *run* it does.

📖 See [Scroll Engines Overview](engines/overview.md) for a side-by-side comparison.

## Coding Style

The library codebase and all the examples use function composition (`>>`) extensively.

??? note "New to function composition (`>>`)?"

    If you are more used to Elm's pipeline operator (`|>`), here's how they compare:

    ```elm
    -- Using pipelines (|>)
    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement targetId scrollBuilder =
        scrollBuilder
            |> Scroll.forContainer "scroll-container"
            |> Scroll.toElement targetId
            |> Scroll.speed 250
            |> Scroll.easing BounceOut
            |> Scroll.build

    -- Using function composition (>>)
    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement targetId =
        Scroll.forContainer "scroll-container"
            >> Scroll.toElement targetId
            >> Scroll.speed 250
            >> Scroll.easing BounceOut
            >> Scroll.build
    ```

    Both produce identical results. Because these builders are all functions of type `ScrollBuilder -> ScrollBuilder`, they compose naturally with `>>`. This codebase prefers the composition style because it keeps builder definitions concise and usually reads more cleanly than threading an explicit `scrollBuilder` through a pipeline.

    The composition style works because each builder step is itself a *partially-applied* function of type `ScrollBuilder -> ScrollBuilder` - every argument except the builder has been supplied. `>>` then chains those partially-applied functions end-to-end into one larger function with the same `ScrollBuilder -> ScrollBuilder` shape.

## Examples

The examples below show the **same scroll** built with each of the three engines, so you can see how the engine choice affects the surrounding code without changing what the scroll does.

!!! info "Responsive by default"

    All examples in this documentation are responsive - they adapt smoothly when the viewport is resized.

### 1. Vertical Scrolling

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:examples"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:code"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:breaking-it-down"

---

### 2. Horizontal Scrolling

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:examples"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:code"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:breaking-it-down"

---

### 3. Spreadsheet Navigation

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:desc"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:examples"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:code"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:breaking-it-down"

## Next Steps

Now that you've seen what a scroll animation looks like, dig into the builder - the small composable API every scroll is described with.

[The Scroll Builder →](builder.md){ .md-button .md-button--primary }
