# Scroll Examples

A gallery of every scroll example in the docs. Each entry runs the same scroll across all three engines so you can flip between tabs and compare the behaviour without re-reading anything.

Click **Go to page** on any example to see its full breakdown - builder, trigger, react wiring, and per-engine notes.

## Vertical Scrolling

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:examples"

[Go to page](start-here.md#1-vertical-scrolling){ .md-button .md-button--primary }

---

## Horizontal Scrolling

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:examples"

[Go to page](start-here.md#2-horizontal-scrolling){ .md-button .md-button--primary }

---

## Spreadsheet Navigation

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:desc"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:examples"

[Go to page](start-here.md#3-spreadsheet-navigation){ .md-button .md-button--primary }

---

## Controlling Scrolls

Pause, resume, restart, stop, and reset a scroll while it's running. Sub engine only.

??? example "View Example"

    <iframe src="../../examples/src/Scroll/Sub/ControllingScrolls/index.html" class="example-iframe" loading="lazy"></iframe>

[Go to page](engines/sub.md#controls){ .md-button .md-button--primary }

---

## Interrupting Scrolls

The same scroll, re-triggered mid-flight in all three engines. Shows the cost of fire-and-forget vs the smoothness of state-tracked redirection.

??? example "View Example - Cmd"

    <iframe src="../../examples/src/Scroll/Cmd/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Example - Task"

    <iframe src="../../examples/src/Scroll/Task/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

??? example "View Example - Sub"

    <iframe src="../../examples/src/Scroll/Sub/Interrupting/index.html" class="example-iframe" loading="lazy"></iframe>

[Go to page](concepts/interrupting-scrolls.md){ .md-button .md-button--primary }
