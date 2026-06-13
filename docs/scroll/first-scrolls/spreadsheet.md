--8<-- [start:desc]
A spreadsheet-style grid with sticky row and column headers. Region buttons jump to named cells using both axes at once, and `withOffsetXY` keeps the cell clear of the sticky headers when the scroll settles. Shown in all three engines.
--8<-- [end:desc]

--8<-- [start:examples]
??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Scroll/Cmd/Spreadsheet/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Scroll/Task/Spreadsheet/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Scroll/Sub/Spreadsheet/index.html" class="example-iframe" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Scroll/Cmd/Spreadsheet/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm"
        ```

--8<-- [end:code]

--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    Same six-step workflow as the vertical scrolling example. The two new ingredients are both in the builder: `toElement` naturally scrolls *both* axes, and `withOffsetXY` shifts the final position so the cell isn't hidden behind the sticky headers.

    ### 1. Build

    `toElement` scrolls both axes by default, and `withOffsetXY` leaves room for the sticky headers:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/Spreadsheet/Main.elm:build"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm:build"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:build"
            ```

    ### 2. Initialize

    Only the Sub engine keeps state in the model:

    ??? example "View Source Code"

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:model"
            ```

    ### 3. Subscribe

    Only the Sub engine needs subscriptions:

    ??? example "View Source Code"

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:subscriptions"
            ```

    ### 4. Trigger

    Each engine starts the same scroll definition a little differently:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/Spreadsheet/Main.elm:trigger"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm:trigger"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:trigger"
            ```

    ### 5. React

    Task gives you completion or failure at the end of the scroll, while Sub reports live `x` and `y` coordinates plus overall progress:

    ??? example "View Source Code"

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/Spreadsheet/Main.elm:result"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/Spreadsheet/Main.elm:updateScroll"
            ```

--8<-- [end:breaking-it-down]
