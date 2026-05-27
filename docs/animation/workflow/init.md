# Initialize

This page relates to Document Timeline Engines only (Transition, Keyframe, Sub and WAAPI). ScrollTimeline and ViewTimeline Engines do not require initializing, and have no `AnimState` - scroll position drives them directly, so there is nothing to track between frames.

All Document Timeline Engines should be initialized ready for rendering and triggering.

## Why Initialize?

Initialization performs three functions:

- It sets initial values for first render
- It gives the Engine starting values to use for the first time the `animGroup` is animated
- It ensures the Engine and your view are in sync

## The Init Pattern

### Property Init Functions

Each Property module provides `init` functions for setting initial values, the range of functions depends on the property:

- Opacity only has `init` - there is only one value to set
- Size has `init`, `initH`, `initW` & `initHW` - Size has height and width

Refer to each property's documentation for specifics.

### Engine Init Functions

The `init` function is available for all Document timeline Egnines. It creates an `AnimState` with initial property values:

??? example "View Source Code"

    === "Transition"

        ```elm
        initialAnimState : Transition.AnimState
        initialAnimState =
            Transition.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initX "slideBox" -100 
                ]
        ```

    === "Keyframe"

        ```elm
        initialAnimState : Keyframe.AnimState
        initialAnimState =
            Keyframe.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initX "slideBox" -100 
                ]
        ```

    === "Sub"

        ```elm
        initialAnimState : Sub.AnimState
        initialAnimState =
            Sub.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initX "slideBox" -100 
                ]
        ```

    === "WAAPI"

        ```elm
        initialAnimState : WAAPI.AnimState Msg
        initialAnimState =
            WAAPI.init motionCmd motionMsg <|
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initX "slideBox" -100 
                ]
        ```

        The WAAPI Engine also requires it's port functions [`motionCmd` & `motionMsg`] so that it can talk to JS. 
        [More on these](../engines/waapi.md#3-define-ports-in-elm) later.
    
    These properties are rendered in your view with the values set here.


### Store it in Your Model

Store the initialized `AnimState` in your model:

??? example "View Source Code"

    === "Transition"
        ```elm
        type alias Model =
            { animState : Transition.AnimState
            , -- other fields
            }

        init : Model
        init =
            { animState = initialAnimState
            , -- other fields
            }
        ```

    === "Keyframe"
        ```elm
        type alias Model =
            { animState : Keyframe.AnimState
            , -- other fields
            }

        init : Model
        init =
            { animState = initialAnimState
            , -- other fields
            }
        ```

    === "Sub"
        ```elm
        type alias Model =
            { animState : Sub.AnimState
            , -- other fields
            }

        init : Model
        init =
            { animState = initialAnimState
            , -- other fields
            }
        ```

    === "WAAPI"
        ```elm
        type alias Model =
            { animState : WAAPI.AnimState Msg
            , -- other fields
            }

        init : Model
        init =
            { animState = initialAnimState
            , -- other fields
            }
        ```

        The WAAPI Engine's `AnimState` takes a `Msg` type parameter because it stores the port functions internally — this keeps their `Cmd msg` and `Sub msg` types in sync with your application's own `Msg` type, which also means you won't need to reach for `Cmd.map` or `Sub.map`.

## Next Steps

Once you have initialized your `AnimState`, the next step is to render your animations.

[Render →](render.md){ .md-button .md-button--primary }
