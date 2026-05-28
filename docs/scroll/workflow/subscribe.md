# Subscribe

!!! note "Sub engine only"
    [Cmd](../engines/cmd.md) and [Task](../engines/task.md) handle their own timing internally - no subscription needed. This page applies only to [`Scroll.Sub`](../engines/sub.md).

The Sub engine advances each scroll frame-by-frame using `Browser.Events.onAnimationFrameDelta`. That means it needs to be wired into your app's `subscriptions` function so the runtime can deliver those frame events.

## The One-Liner

Pass your tagger and the current `ScrollState` to `Sub.subscriptions`:

??? example "View Source Code"

    ```elm
    import Scroll.Engine.Sub as Sub


    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions GotScrollMsg model.scrollState
    ```

The subscription is **dormant when nothing is scrolling** - it only listens for frames while a scroll is actually in flight. So there's no runtime cost from leaving it permanently wired in.

## Wiring it into `main`

??? example "View Source Code"

    ```elm
    main : Program () Model Msg
    main =
        Browser.element
            { init = init
            , view = view
            , update = update
            , subscriptions = subscriptions
            }
    ```

## Multiple `ScrollState`s

If you keep more than one `ScrollState` in your model - say one for the main page and one for a sidebar - combine their subscriptions with `Sub.batch`:

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.batch
            [ Sub.subscriptions GotMainScrollMsg model.mainScrollState
            , Sub.subscriptions GotSidebarScrollMsg model.sidebarScrollState
            ]
    ```

!!! tip "Each `ScrollState` is independent"
    Separate states each track their own scrolls, fire their own events, and can be controlled and queried independently. Use separate states (and separate message wrappers) whenever you want isolated scroll behaviour.

## Next Steps

You've covered the whole scroll workflow. Now compare the engines side by side and pick the one that fits your case.

[Engines Overview →](../engines/overview.md){ .md-button .md-button--primary }
