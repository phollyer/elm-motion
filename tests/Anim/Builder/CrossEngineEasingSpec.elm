module Anim.Builder.CrossEngineEasingSpec exposing (suite)

{-| Compile-time guard: the engine-agnostic `Anim.Builder.easing` setter
must be applicable to every engine's builder.

`easing` is unconstrained (`AnimBuilder eng -> AnimBuilder eng`) because
every engine supports easing. If a phantom capability constraint (such as
a `withEasing` row field that no engine record declares) is reintroduced,
the per-engine bindings below stop compiling — which is exactly the
regression this module exists to catch.

-}

import Anim.Builder as Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Engine.ScrollTimeline as ScrollTimeline
import Anim.Engine.Sub as Sub
import Anim.Engine.Transition as Transition
import Anim.Engine.ViewTimeline as ViewTimeline
import Anim.Engine.WAAPI as WAAPI
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


{-| Engine-agnostic helper built on the umbrella easing setter.
-}
applyEasing : AnimBuilder eng -> AnimBuilder eng
applyEasing =
    Builder.easing EaseInOut


forTransition : Transition.EngineBuilder -> Transition.EngineBuilder
forTransition =
    applyEasing


forKeyframe : Keyframe.EngineBuilder -> Keyframe.EngineBuilder
forKeyframe =
    applyEasing


forSub : Sub.EngineBuilder -> Sub.EngineBuilder
forSub =
    applyEasing


forWAAPI : WAAPI.EngineBuilder -> WAAPI.EngineBuilder
forWAAPI =
    applyEasing


forScroll : ScrollTimeline.EngineBuilder -> ScrollTimeline.EngineBuilder
forScroll =
    applyEasing


forView : ViewTimeline.EngineBuilder -> ViewTimeline.EngineBuilder
forView =
    applyEasing


suite : Test
suite =
    describe "Anim.Builder.easing is engine-agnostic"
        [ test "the umbrella easing setter applies to every engine builder" <|
            \_ ->
                -- The per-engine bindings above are type-checked by the
                -- compiler whether or not they are called, so this module
                -- failing to compile IS the regression signal. The runtime
                -- assertion is a formality.
                Expect.pass
        ]
