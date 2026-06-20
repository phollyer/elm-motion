/* eslint-env browser */
import { activeAnimations, animationGroups, portsRef } from './state.js';
import { reportError } from './errors.js';

// Whether we have already reported the missing-motionMsg-port warning.
// Reset by index.js init() so a fresh app gets a fresh chance to warn.
let portMissingWarned = false;

export function resetPortMissingWarning() {
    portMissingWarned = false;
}

/**
 * Send data to Elm via the motionMsg port.
 * All port communication funnels through this single function so the
 * port-presence check lives in exactly one place. If the port is missing,
 * we report once via reportError and then silently no-op for the rest of
 * the session (so per-frame senders don't spam the reporter).
 */
function sendToElm(data) {
    const ports = portsRef.ports;
    if (ports && ports.motionMsg && typeof ports.motionMsg.send === 'function') {
        ports.motionMsg.send(data);
        return;
    }
    if (!portMissingWarned) {
        portMissingWarned = true;
        reportError('motionMsg port is not available; outbound events will be dropped', {
            source: 'ports',
            severity: 'warning',
            code: 'MOTION_MSG_PORT_MISSING'
        });
    }
}

function getGroupMaxDuration(animGroup) {
    const properties = animationGroups.get(animGroup)?.propertyConfigs || [];
    return properties.length > 0
        ? Math.max(...properties.map(property => property.duration))
        : 0;
}

function getRunningAnimationProgress(animGroup, maxDuration) {
    if (maxDuration <= 0) {
        return 0;
    }

    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims || elementAnims.size === 0) {
        return 0;
    }

    const firstAnim = elementAnims.values().next().value;
    if (!firstAnim || !firstAnim.animation) {
        return 0;
    }

    const currentTime = firstAnim.animation.currentTime || 0;
    return Math.min(1.0, Math.max(0.0, currentTime / maxDuration));
}

function getLifecycleProgress(status, animGroup) {
    if (status === 'completed' || status === 'stopped') {
        return 1.0;
    }

    if (status === 'run' || status === 'started' || status === 'reset' || status === 'restarted') {
        return 0.0;
    }

    return getRunningAnimationProgress(animGroup, getGroupMaxDuration(animGroup));
}

/**
 * Send iteration event to Elm when an animation crosses an iteration boundary.
 * The iteration count is sent as the progress value so Elm can decode it
 * via: Iteration animGroupName (round progress)
 */
export function sendIterationEvent(animGroup, iterationNumber) {
    sendToElm({
        type: 'animationUpdate',
        payload: {
            elementId: animGroup,
            animGroup: animGroup,
            status: 'iteration',
            progress: iterationNumber
        }
    });
}

/**
 * Send lifecycle event to Elm (started, completed, cancelled, paused, resumed, etc.)
 * Includes current progress calculated from the active animation state.
 */
export function sendLifecycleEvent(status, animGroup) {
    sendToElm({
        type: 'animationUpdate',
        engine: 'waapi',
        payload: {
            elementId: animGroup,
            animGroup: animGroup,
            status: status,
            progress: getLifecycleProgress(status, animGroup)
        }
    });
}

/**
 * Send a lifecycle event for a scroll-driven animation group to Elm.
 * Payload matches the 'animationUpdate' shape used by the WAAPI engine, plus
 * an 'engine' field so Elm decoders can filter to their own events.
 */
export function sendScrollLifecycleEvent(status, animGroup, progress, engine) {
    sendToElm({
        type: 'animationUpdate',
        engine: engine,
        payload: {
            elementId: animGroup,
            animGroup: animGroup,
            status: status,
            progress: progress
        }
    });
}

/**
 * Send property update to Elm (during animation).
 * Uses 'propertyUpdate' type which Elm routes to PropertyUpdate handling.
 */
export function sendPropertyUpdate(propertyData) {
    sendToElm({ type: 'propertyUpdate', ...propertyData });
}

/**
 * Build the property-update payload sent to Elm during an animation.
 *
 * Phase 4: JS no longer sends absolute interpolated values. The Elm side
 * (`Anim.Internal.Engine.WAAPI.ProgressApply`) interpolates each property
 * from its anchored start to its end using the raw progress emitted here,
 * combined with the easing and config stored in the property's `PropertyState`.
 *
 * `propertyProgress` is a plain object keyed by Elm's property-type strings
 * (`'translate'`, `'rotate'`, `'skew'`, `'scale'`, `'opacity'`, `'size'`,
 * `'perspectiveOrigin'`, `'custom:<css>'`, `'customColor:<css>'`), with raw
 * 0..1 per-iteration progress values (no easing applied — Elm applies the
 * easing curve).
 */
export function buildAnimatedPropertyData(propertyProgress) {
    return { propertyProgress };
}

/**
 * Send settled (committed) transform values to Elm after animation completes.
 * This establishes the runtime baseline for the next animation on the same group,
 * ensuring Elm and JS use the same committed start values for frozen-axis anchoring.
 *
 * Payload includes per-axis values and units so Elm can reconstruct the exact
 * transform state that was committed to the DOM, preventing Elm baseline drift.
 */
export function sendSettledTransformValues(animGroup, settledTransform) {
    if (!settledTransform || typeof settledTransform !== 'object') {
        return;
    }
    sendToElm({
        type: 'settledValues',
        animGroup: animGroup,
        payload: {
            translate: settledTransform.translate || null,
            scale: settledTransform.scale || null,
            rotate: settledTransform.rotate || null,
            skew: settledTransform.skew || null,
            committedAt: performance.now()
        }
    });
}

/**
 * Send frozen-axes acknowledgment to Elm after a retarget with frozen axes.
 * This tells Elm the exact values that JS used for each frozen axis,
 * preventing Elm from recomputing different start values on the next animate.
 */
export function sendFrozenAxesAcknowledgment(animGroup, frozenAxesApplied, commandVersion) {
    sendToElm({
        type: 'frozenAxesApplied',
        animGroup: animGroup,
        frozenStates: frozenAxesApplied,
        commandVersion: commandVersion,
        appliedAt: performance.now()
    });
}

