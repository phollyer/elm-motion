--8<-- [start:desc]
A horizontally-scrolling image gallery. The buttons jump between named cards, and the builder uses `onXAxis` so the gallery never drifts vertically. Shown in all three engines.
--8<-- [end:desc]

--8<-- [start:examples]
??? example "View Example"
    === "Cmd"

        <iframe src="../../../examples/src/Scroll/Cmd/HorizontalGallery/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Task"

        <iframe src="../../../examples/src/Scroll/Task/HorizontalGallery/index.html" class="example-iframe" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Scroll/Sub/HorizontalGallery/index.html" class="example-iframe" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Cmd"

        ```elm
        --8<-- "docs/examples/src/Scroll/Cmd/HorizontalGallery/Main.elm"
        ```

    === "Task"

        ```elm
        --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm"
        ```

--8<-- [end:code]

--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    Same six-step workflow as the vertical scrolling example. The only meaningful difference is in the builder - `onXAxis` tells the engine to scroll horizontally only.

    ### 1. Build

    Horizontal scrolling uses the same builder pattern, with `onXAxis` making the intended axis explicit:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/HorizontalGallery/Main.elm:build"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm:build"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:build"
            ```

    ### 2. Initialize

    Only the Sub engine keeps state in the model:

    ??? example "View Source Code"

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:model"
            ```

    ### 3. Subscribe

    Only the Sub engine needs subscriptions:

    ??? example "View Source Code"

        ```elm
        --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:subscriptions"
        ```

    ### 4. Trigger

    Each engine starts the same scroll definition a little differently:

    ??? example "View Source Code"

        === "Cmd"

            ```elm
            --8<-- "docs/examples/src/Scroll/Cmd/HorizontalGallery/Main.elm:trigger"
            ```

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm:trigger"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:trigger"
            ```

    ### 5. React

    Task reports success or failure when the scroll finishes, while Sub keeps the status bar updated with live X position and progress:

    ??? example "View Source Code"

        === "Task"

            ```elm
            --8<-- "docs/examples/src/Scroll/Task/HorizontalGallery/Main.elm:result"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Scroll/Sub/HorizontalGallery/Main.elm:updateScroll"
            ```

--8<-- [end:breaking-it-down]
