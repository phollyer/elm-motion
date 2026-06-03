/* eslint-env browser */
import { isTransformProperty, easingFunctions, parseIterations } from './utils.js';
import { activeAnimations, animationGroups, elementTransformOrders, cleanupAnimGroup, lastKnownTransforms, lastKnownPerspectiveOrigins, appliedWillChange } from './state.js';
import { getTransformState, getElementOrder, interpolateSubProperty, computeTransformFromResolved, buildTransformString, getDefaultTransformState } from './transform.js';
import { resolveNonTransformValues, createPropertyAnimation, extractPropertyConfig, buildPropertyKeyframes } from './properties.js';
import { sendLifecycleEvent } from './ports.js';
import { findAnimTarget, findAllAnimTargets } from './targets.js';
import { setupAnimationEvents } from './animationEvents.js';
import { reportError } from './errors.js';

function isFiniteNumber(value) {
    return typeof value === 'number' && Number.isFinite(value);
}

function distance3(a, b) {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    const dz = a.z - b.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

function distance2(a, b) {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
}

function computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation) {
    if (!isFiniteNumber(oldCurrentTime) || !isFiniteNumber(oldDuration) || oldDuration <= 0) {
        return null;
    }

    const oldRawProgress = (oldCurrentTime % oldDuration) / oldDuration;
    let oldLegProgress = oldRawProgress;
    if (oldDirection === 'alternate' || oldDirection === 'alternate-reverse') {
        const computed = animation?.effect?.getComputedTiming?.() || {};
        const iter = computed.currentIteration;
        if (Number.isFinite(iter)) {
            const startsReversed = oldDirection === 'alternate-reverse';
            const isReverseLeg = (iter % 2 === 1) !== startsReversed;
            if (isReverseLeg) {
                oldLegProgress = 1 - oldRawProgress;
            }
        }
    } else if (oldDirection === 'reverse') {
        oldLegProgress = 1 - oldRawProgress;
    }

    return oldLegProgress;
}

function axisBoundsChanged(oldStart, oldEnd, newStart, newEnd, epsilon = 0.001) {
    return Math.abs(oldStart - newStart) > epsilon || Math.abs(oldEnd - newEnd) > epsilon;
}

function chooseEffectiveAxisValue(oldStart, oldEnd, newStart, newEnd, commandValue, liveValue) {
    if (!isFiniteNumber(liveValue)) {
        return commandValue;
    }

    return axisBoundsChanged(oldStart, oldEnd, newStart, newEnd)
        ? commandValue
        : liveValue;
}

function chooseDominantAxis(spans, epsilon = 0.0001) {
    let chosenAxis = null;
    let maxAbsSpan = epsilon;

    ['x', 'y', 'z'].forEach((axis) => {
        const span = Number(spans[axis]);
        const absSpan = Math.abs(span);
        if (isFiniteNumber(span) && absSpan > maxAbsSpan) {
            chosenAxis = axis;
            maxAbsSpan = absSpan;
        }
    });

    return chosenAxis;
}

function sanitizeResizeDuration(candidateDuration, oldDuration) {
    if (!isFiniteNumber(candidateDuration) || candidateDuration <= 0) {
        return oldDuration;
    }

    if (!isFiniteNumber(oldDuration) || oldDuration <= 0) {
        return candidateDuration;
    }

    const maxDuration = oldDuration * 8;

    // Keep lower durations untouched - end-of-leg resizes legitimately
    // shorten the remaining leg time. Clamp only implausible huge jumps.
    if (candidateDuration > maxDuration) {
        return oldDuration;
    }

    return candidateDuration;
}

const DEFAULT_TRANSFORM_KEYFRAME_COUNT = 30;

function deriveTransformKeyframeCount(resolved) {
    const lengths = ['translate', 'scale', 'rotate', 'skew']
        .map((key) => resolved?.[key]?.easingKeyframes)
        .filter((keyframes) => Array.isArray(keyframes) && keyframes.length > 1)
        .map((keyframes) => keyframes.length);

    if (lengths.length === 0) {
        return DEFAULT_TRANSFORM_KEYFRAME_COUNT;
    }

    return Math.max(...lengths);
}

/**
 * Detect a resize cmd whose geometry exactly matches what the WAAPI
 * animation is already running. Used to short-circuit the cancel+recreate
 * path when Elm fires a resize purely because `currentTimeMs` advanced
 * (Progress event tick during a continuous drag) - if start/end/duration
 * for the resized slot are unchanged, recreating the animation would
 * needlessly seek the playhead and visually appear to speed the
 * animation up frame-by-frame during the drag.
 *
 * Comparison is strict (`===`) on the numbers Elm shipped: Elm's own
 * `noChange` guard already filters out near-equal geometry via its
 * epsilon, so any cmd that reaches JS with start/end/duration matching
 * the resolved slot byte-for-byte is the pure `currentTimeMs`-only case
 * we want to skip.
 */
function isResizeGeometryUnchanged(commandData, slot, oldDuration) {
    if (!slot) {
        return false;
    }
    const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
    const hasBaseline = commandData.hasAnimationBaseline !== false;
    const newDuration = hasBaseline ? payloadDuration : oldDuration;
    return Number(commandData.startX) === Number(slot.startX)
        && Number(commandData.startY) === Number(slot.startY)
        && Number(commandData.startZ) === Number(slot.startZ)
        && Number(commandData.endX) === Number(slot.endX)
        && Number(commandData.endY) === Number(slot.endY)
        && Number(commandData.endZ) === Number(slot.endZ)
        && newDuration === Number(slot.duration);
}

/**
 * Perspective-origin counterpart of `isResizeGeometryUnchanged`. Same
 * short-circuit purpose, with two differences from the translate version:
 *
 * - Perspective-origin is 2D, so Z is omitted.
 * - The slot has a `unit` (`%` / `px`); a unit change must invalidate the
 *   skip even if the numeric start/end are unchanged.
 *
 * Duration is read from `oldDuration` (the live WAAPI timing) because
 * the resolved non-transform slot does not store a `duration` field —
 * the animation's own effect timing is the source of truth.
 */
function isPerspectiveOriginGeometryUnchanged(commandData, slot, oldDuration) {
    if (!slot) {
        return false;
    }
    const incomingUnit = typeof commandData.unit === 'string' ? commandData.unit : '%';
    if (incomingUnit !== slot.unitX || incomingUnit !== slot.unitY) {
        return false;
    }
    const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
    const hasBaseline = commandData.hasAnimationBaseline !== false;
    const newDuration = hasBaseline ? payloadDuration : oldDuration;
    return Number(commandData.startX) === Number(slot.startX)
        && Number(commandData.startY) === Number(slot.startY)
        && Number(commandData.endX) === Number(slot.endX)
        && Number(commandData.endY) === Number(slot.endY)
        && newDuration === oldDuration;
}

function isSizeGeometryUnchanged(commandData, slot, oldDuration) {
    if (!slot) {
        return false;
    }
    const incomingUnit = typeof commandData.unit === 'string' ? commandData.unit : 'px';
    if (incomingUnit !== slot.unitWidth || incomingUnit !== slot.unitHeight) {
        return false;
    }
    const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
    const hasBaseline = commandData.hasAnimationBaseline !== false;
    const newDuration = hasBaseline ? payloadDuration : oldDuration;
    return Number(commandData.startX) === Number(slot.startWidth)
        && Number(commandData.startY) === Number(slot.startHeight)
        && Number(commandData.endX) === Number(slot.endWidth)
        && Number(commandData.endY) === Number(slot.endHeight)
        && newDuration === oldDuration;
}

const TRANSFORM_STATE_KEYS = {
    translate: { x: 'x', y: 'y', z: 'z' },
    scale: { x: 'scaleX', y: 'scaleY', z: 'scaleZ' },
    rotate: { x: 'rotateX', y: 'rotateY', z: 'rotateZ' },
    skew: { x: 'skewX', y: 'skewY' }
};

const START_FILL_AXES = {
    translate: [
        { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'x' },
        { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'y' },
        { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'z' }
    ],
    scale: [
        { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'scaleX' },
        { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'scaleY' },
        { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'scaleZ' }
    ],
    rotate: [
        { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'rotateX' },
        { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'rotateY' },
        { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'rotateZ' }
    ],
    skew: [
        { startKey: 'startX', stateKey: 'skewX' },
        { startKey: 'startY', stateKey: 'skewY' }
    ]
};

const RESOLVED_TRANSFORM_AXES = {
    translate: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'x', useDefault: true },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'y', useDefault: true },
        { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'z', useDefault: true }
    ],
    scale: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'scaleX', useDefault: true },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'scaleY', useDefault: true },
        { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'scaleZ', useDefault: true }
    ],
    rotate: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'rotateX', useDefault: true },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'rotateY', useDefault: true },
        { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'rotateZ', useDefault: true }
    ],
    skew: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'skewX', useDefault: false },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'skewY', useDefault: false }
    ]
};

function fillMissingTransformStarts(property, currentState) {
    const axes = START_FILL_AXES[property.type];
    if (!axes) {
        return;
    }

    axes.forEach(({ startKey, defaultKey, stateKey }) => {
        const defaultMissing = !defaultKey || property[defaultKey] == null;
        if (property[startKey] == null && defaultMissing) {
            property[startKey] = currentState[stateKey];
        }
    });
}

// For each axis Elm has declared frozen on this property, override both
// the start and end values with the live mid-flight transform reading
// from the running WAAPI animation. Elm's `runtimeBaseline` is updated
// asynchronously via the `motionMsg` port and is therefore one or more
// frames behind the actual rendered position; using its (stale) snapshot
// as both endpoints of a "frozen" axis produces a visible backward jump
// when the user retargets a sibling axis mid-flight. The live transform
// computed from the in-flight animation is the only source of truth.
const FROZEN_AXIS_LIVE_FIELDS = {
    translate: { x: 'x', y: 'y', z: 'z' },
    scale: { x: 'scaleX', y: 'scaleY', z: 'scaleZ' },
    rotate: { x: 'rotateX', y: 'rotateY', z: 'rotateZ' },
    skew: { x: 'skewX', y: 'skewY' }
};

function applyFrozenAxesFromLive(property, currentState) {
    const axes = property.frozenAxes;
    if (!Array.isArray(axes) || axes.length === 0) {
        return;
    }
    const fieldMap = FROZEN_AXIS_LIVE_FIELDS[property.type];
    if (!fieldMap) {
        return;
    }
    for (const axis of axes) {
        const stateKey = fieldMap[axis];
        if (!stateKey) continue;
        const liveValue = currentState[stateKey];
        if (!Number.isFinite(liveValue)) continue;
        const suffix = axis.toUpperCase();
        property[`start${suffix}`] = liveValue;
        property[`end${suffix}`] = liveValue;
    }
}

function patchTransformStartsFromAnimation(existingTransform, mergedTransformProperties) {
    if (!existingTransform.resolvedValues || !existingTransform.animation) {
        return;
    }

    const timing = existingTransform.animation.effect?.getTiming();
    const currentTime = existingTransform.animation.currentTime || 0;
    const duration = timing?.duration || 0;
    if (duration <= 0) {
        return;
    }

    const progress = Math.min(1.0, Math.max(0.0, currentTime / duration));
    const currentState = computeTransformFromResolved(existingTransform.resolvedValues, progress, duration);
    mergedTransformProperties.forEach(property => {
        fillMissingTransformStarts(property, currentState);
        applyFrozenAxesFromLive(property, currentState);
    });
}

function buildRetainedTransformProperty(oldProp, currentTransform, elapsedMs) {
    const keys = TRANSFORM_STATE_KEYS[oldProp.type];
    const originalDuration = oldProp.duration || 0;
    const remainingDuration = Math.max(0, originalDuration - elapsedMs);
    return {
        type: oldProp.type,
        // Start from the live mid-flight value so the axis continues smoothly
        // from where it currently is on screen.
        startX: currentTransform[keys.x],
        startY: currentTransform[keys.y],
        startZ: keys.z ? currentTransform[keys.z] : undefined,
        // Continue toward the ORIGINAL target rather than freezing at the
        // current value. Combined with remainingDuration below, this lets
        // untouched in-flight axes carry on toward their goal while a sibling
        // axis is re-animated.
        endX: oldProp.endX,
        endY: oldProp.endY,
        endZ: keys.z ? oldProp.endZ : undefined,
        // Easing approximation: applying the same easing function over the
        // remainder of the curve is exact for `linear` and a perceptual
        // approximation for non-linear curves (the true tail of e.g. an
        // `ease-out` curve is a different bezier, but the visual difference
        // is typically imperceptible). Complex pre-baked easingKeyframes
        // (bounce / elastic / spring) are dropped here because the array
        // covers 0..1 of the FULL animation and replaying it across the
        // remainder would produce visible artifacts. A future improvement
        // could slice the keyframe tail and rescale.
        easing: oldProp.easing || 'linear',
        easingKeyframes: null,
        duration: remainingDuration,
        version: oldProp.version || 1
    };
}

/**
 * Determine which transform sub-property groups must be force-emitted in
 * every keyframe of a WAAPI animation. Returns a Set containing any of
 * `'translate' | 'scale' | 'rotate' | 'skew'`.
 *
 * WAAPI requires every keyframe in an animation to list the same set of
 * transform functions to interpolate per-function (e.g. animating
 * `rotateX` directly). If keyframes differ, the browser falls back to
 * matrix3d decomposition, which silently drops rotation when either
 * endpoint produces an identity rotation matrix (e.g. `rotateX(360deg)`
 * decomposes to identity). The fix is to force-emit a group on every
 * keyframe whenever any endpoint of the resolved animation is non-identity
 * for that group, so the function lists match across all keyframes.
 */
function computeForceGroups(resolved) {
    const force = new Set();
    const isAxisActive = (group, identity, axes) => {
        const value = resolved[group];
        if (!value) return false;
        for (const axis of axes) {
            const start = value[`start${axis}`];
            const end = value[`end${axis}`];
            if (Number.isFinite(start) && start !== identity) return true;
            if (Number.isFinite(end) && end !== identity) return true;
        }
        return false;
    };
    if (isAxisActive('translate', 0, ['X', 'Y', 'Z'])) force.add('translate');
    if (isAxisActive('scale', 1, ['X', 'Y', 'Z'])) force.add('scale');
    if (isAxisActive('rotate', 0, ['X', 'Y', 'Z'])) force.add('rotate');
    if (isAxisActive('skew', 0, ['X', 'Y'])) force.add('skew');
    return force;
}

function buildDefaultResolvedTransform(currentTransform) {
    return {
        translate: {
            startX: currentTransform.x, startY: currentTransform.y, startZ: currentTransform.z,
            endX: currentTransform.x, endY: currentTransform.y, endZ: currentTransform.z,
            easing: null, easingKeyframes: null, duration: 0,
            unitX: currentTransform.translateUnitX || 'px',
            unitY: currentTransform.translateUnitY || 'px',
            unitZ: currentTransform.translateUnitZ || 'px'
        },
        scale: {
            startX: currentTransform.scaleX, startY: currentTransform.scaleY, startZ: currentTransform.scaleZ,
            endX: currentTransform.scaleX, endY: currentTransform.scaleY, endZ: currentTransform.scaleZ,
            easing: null, easingKeyframes: null, duration: 0
        },
        rotate: {
            startX: currentTransform.rotateX, startY: currentTransform.rotateY, startZ: currentTransform.rotateZ,
            endX: currentTransform.rotateX, endY: currentTransform.rotateY, endZ: currentTransform.rotateZ,
            easing: null, easingKeyframes: null, duration: 0
        },
        skew: {
            startX: currentTransform.skewX, startY: currentTransform.skewY,
            endX: currentTransform.skewX, endY: currentTransform.skewY,
            easing: null, easingKeyframes: null, duration: 0
        }
    };
}

function assignResolvedTransformProperty(target, property, currentTransform, axes) {
    axes.forEach(({ suffix, startKey, endKey, currentKey, useDefault }) => {
        const defaultValue = useDefault ? property[`default${suffix}`] : undefined;
        target[startKey] = property[`start${suffix}`] ?? defaultValue ?? currentTransform[currentKey];
        target[endKey] = property[`end${suffix}`] ?? currentTransform[currentKey];
    });
    target.easing = property.easing;
    target.easingKeyframes = property.easingKeyframes;
    target.duration = property.duration;
    if (property.type === 'translate') {
        if (typeof property.unitX === 'string' && property.unitX.length > 0) {
            target.unitX = property.unitX;
        }
        if (typeof property.unitY === 'string' && property.unitY.length > 0) {
            target.unitY = property.unitY;
        }
        if (typeof property.unitZ === 'string' && property.unitZ.length > 0) {
            target.unitZ = property.unitZ;
        }
    }
}

function carryForwardMissingTransformProperties(animGroup, element, existingTransform, mergedTransformProperties) {
    if (!existingTransform.transformProperties) {
        return;
    }

    const newPropTypes = new Set(mergedTransformProperties.map(property => property.type));

    // Compute the live mid-flight transform from the running animation so
    // retained axes can continue from where they actually are on screen at
    // this exact moment. Falls back to the cached transform state if the
    // running animation has no resolved values yet.
    let liveTransform = null;
    const timing = existingTransform.animation?.effect?.getTiming();
    const animationDuration = timing?.duration || 0;
    const currentTime = existingTransform.animation?.currentTime || 0;
    if (existingTransform.resolvedValues && animationDuration > 0) {
        const progress = Math.min(1.0, Math.max(0.0, currentTime / animationDuration));
        liveTransform = computeTransformFromResolved(existingTransform.resolvedValues, progress, animationDuration);
    }
    const currentTransform = liveTransform || getTransformState(animGroup, element);

    existingTransform.transformProperties.forEach(oldProp => {
        if (!newPropTypes.has(oldProp.type)) {
            mergedTransformProperties.push(buildRetainedTransformProperty(oldProp, currentTransform, currentTime));
        }
    });
}

function cancelLegacyTransformAnimations(elementAnims) {
    ['translate', 'scale', 'rotate', 'skew'].forEach(propType => {
        if (elementAnims.has(propType)) {
            const existing = elementAnims.get(propType);
            // Delete BEFORE cancel so the listener's `isActiveEntry()`
            // guard returns false and the listener exits silently.
            elementAnims.delete(propType);
            try {
                existing.animation.cancel();
            } catch (_) {
                // Already-cancelled / detached handles are safe to ignore.
            }
        }
    });
}

function markAnimationGroupStarted(animGroup) {
    const groupInfo = animationGroups.get(animGroup);
    if (groupInfo && !groupInfo.started) {
        groupInfo.started = true;
        sendLifecycleEvent('started', animGroup);
    }
}

/**
 * Convert the Elm-side `transformBaseline` payload (a snapshot of init/runtime
 * baseline values for translate, scale, rotate, skew) into the flat
 * transform-state shape used by `lastKnownTransforms`. Missing axes fall back
 * to identity defaults.
 */
function baselineToTransformState(baseline) {
    const state = getDefaultTransformState();
    if (!baseline) {
        return state;
    }
    const num = (v, fallback) => Number.isFinite(v) ? v : fallback;
    if (baseline.translate) {
        state.x = num(baseline.translate.x, state.x);
        state.y = num(baseline.translate.y, state.y);
        state.z = num(baseline.translate.z, state.z);
    }
    if (baseline.scale) {
        state.scaleX = num(baseline.scale.x, state.scaleX);
        state.scaleY = num(baseline.scale.y, state.scaleY);
        state.scaleZ = num(baseline.scale.z, state.scaleZ);
    }
    if (baseline.rotate) {
        state.rotateX = num(baseline.rotate.x, state.rotateX);
        state.rotateY = num(baseline.rotate.y, state.rotateY);
        state.rotateZ = num(baseline.rotate.z, state.rotateZ);
    }
    if (baseline.skew) {
        state.skewX = num(baseline.skew.x, state.skewX);
        state.skewY = num(baseline.skew.y, state.skewY);
    }
    return state;
}

export function processElementAnimation(animGroup, elementConfig, globalOptions = { iterations: 1, direction: 'normal' }, isRestart = false, resolvedElement = null) {
    const element = resolvedElement || findAnimTarget(animGroup);
    if (!element) {
        reportError(`Element with data-anim-target="${animGroup}" not found`, {
            source: 'animation',
            severity: 'warning',
            code: 'TARGET_NOT_FOUND',
            engine: 'WAAPI',
            elementId: animGroup
        });
        return;
    }

    const properties = elementConfig.properties || [];

    // Seed the GPU-hint optimisation before any keyframes are computed so
    // the compositor can promote the element to its own layer for the very
    // first frame. Cleared by `cleanupAnimGroup` once all animations on
    // this animGroup finish or cancel.
    if (elementConfig.willChange && typeof elementConfig.willChange === 'string') {
        try {
            element.style.willChange = elementConfig.willChange;
            appliedWillChange.set(animGroup, { element: element, value: elementConfig.willChange });
        } catch (_) {
            // Hostile environments (e.g. frozen styles) — non-fatal.
        }
    }

    const transformOrder = elementConfig.transformOrder;
    if (transformOrder && transformOrder.length > 0) {
        elementTransformOrders.set(animGroup, transformOrder);
    }

    // Seed `lastKnownTransforms` from the Elm-side snapshot baseline before
    // any keyframes are computed. This ensures init-only transform values
    // (e.g. `Translate.initZ animGroup 200`) survive the moment Elm hands
    // ownership of the inline `transform` style to JS — without this,
    // `getTransformState` would fall back to reading the (now-empty)
    // inline transform and silently default missing axes to identity.
    // We only seed when the cache is empty for this animGroup, so that
    // post-animation `commitStyles` results from prior generations remain
    // authoritative.
    if (elementConfig.transformBaseline && !lastKnownTransforms.has(animGroup)) {
        lastKnownTransforms.set(animGroup, baselineToTransformState(elementConfig.transformBaseline));
    }

    const transformProperties = properties.filter(property => isTransformProperty(property.type));
    const nonTransformProperties = properties.filter(property => !isTransformProperty(property.type));

    if (!activeAnimations.has(animGroup)) {
        activeAnimations.set(animGroup, new Map());
    }
    const elementAnims = activeAnimations.get(animGroup);

    const existingGroup = animationGroups.get(animGroup);
    const generation = isRestart ? (existingGroup?.generation || 0) : ((existingGroup?.generation || 0) + 1);

    // Reset the group bookkeeping for the new generation. `totalProperties`,
    // `propertyIterations` and `propertyConfigs` are filled in below as new
    // animations are created and as carryover (still-running, untouched)
    // animations are re-keyed to the new generation. Without carrying forward
    // those untouched entries, the new generation's `finalizeAnimationTracking`
    // would treat itself as complete as soon as the new (often very short)
    // animations finish - and `cleanupAnimGroup` would then wipe the still-
    // running animations' bookkeeping, freezing the per-frame propertyUpdate
    // values Elm uses for snapshot baselines.
    animationGroups.set(animGroup, {
        totalProperties: 0,
        completedProperties: 0,
        started: false,
        generation: generation,
        nextPropertyIndex: 0,
        lastIteration: 0,
        propertyIterations: [],
        propertyConfigs: []
    });

    if (transformProperties.length > 0) {
        const mergedTransformProperties = [...transformProperties];

        if (elementAnims.has('transform')) {
            const existingTransform = elementAnims.get('transform');
            patchTransformStartsFromAnimation(existingTransform, mergedTransformProperties);
            carryForwardMissingTransformProperties(animGroup, element, existingTransform, mergedTransformProperties);
            existingTransform.animation.cancel();
        }

        cancelLegacyTransformAnimations(elementAnims);

        const maxVersion = Math.max(...mergedTransformProperties.map(property => property.version || 1));
        const mergeResult = createMergedTransformAnimation(animGroup, element, mergedTransformProperties, globalOptions);

        if (mergeResult) {
            const { animation, resolved: resolvedTransformValues } = mergeResult;
            const entry = {
                animation: animation,
                version: maxVersion,
                animGroup: animGroup,
                easingKeyframes: null,
                transformProperties: mergedTransformProperties,
                resolvedValues: resolvedTransformValues,
                generation: generation,
                propertyIndex: allocatePropertyIndex(animGroup)
            };
            elementAnims.set('transform', entry);
            entry.updateFn = setupAnimationEvents(animGroup, 'transform', element, animation, maxVersion, resolvedTransformValues);

            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                transformProperties.forEach(property => {
                    groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
                });
            }

            markAnimationGroupStarted(animGroup);
        }
    }

    nonTransformProperties.forEach(property => {
        const propType = (property.type === 'customProperty')
            ? `custom:${property.cssProperty}`
            : (property.type === 'customColorProperty')
                ? `customColor:${property.cssProperty}`
                : property.type;
        const newVersion = property.version || 1;

        if (elementAnims.has(propType)) {
            elementAnims.get(propType).animation.cancel();
        }

        const resolvedNonTransform = resolveNonTransformValues(animGroup, element, property);
        const animation = createPropertyAnimation(element, resolvedNonTransform, property, globalOptions);

        if (animation) {
            const entry = {
                animation: animation,
                version: newVersion,
                animGroup: animGroup,
                easingKeyframes: property.easingKeyframes || null,
                resolvedNonTransform: resolvedNonTransform,
                generation: generation,
                propertyIndex: allocatePropertyIndex(animGroup)
            };
            elementAnims.set(propType, entry);
            entry.updateFn = setupAnimationEvents(animGroup, propType, element, animation, newVersion, null);

            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
            }

            markAnimationGroupStarted(animGroup);
        }
    });

    // Carry forward any entries that this call did not supersede so that the
    // new generation accounts for them. They were created in a previous
    // generation; without re-keying, their `finish`/`cancel` handlers would
    // skip `finalizeAnimationTracking` (generation mismatch) and the new
    // generation's totals would be wrong.
    elementAnims.forEach(entry => {
        if (entry.generation !== generation) {
            entry.generation = generation;
            entry.propertyIndex = allocatePropertyIndex(animGroup);
            const carryDuration = entry.animation?.effect?.getTiming()?.duration || 0;
            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                groupInfo.propertyConfigs.push({ duration: carryDuration });
            }
        }
    });

    const finalGroupInfo = animationGroups.get(animGroup);
    if (finalGroupInfo) {
        finalGroupInfo.totalProperties = elementAnims.size;
        finalGroupInfo.propertyIterations = new Array(elementAnims.size).fill(0);
    }

    if (elementAnims.size === 0) {
        cleanupAnimGroup(animGroup);
    }
}

function allocatePropertyIndex(animGroup) {
    const groupInfo = animationGroups.get(animGroup);
    if (!groupInfo) return 0;
    const index = groupInfo.nextPropertyIndex;
    groupInfo.nextPropertyIndex++;
    return index;
}

function createMergedTransformAnimation(animGroup, element, transformProperties, globalOptions = { iterations: 1, direction: 'normal' }) {
    const currentTransform = getTransformState(animGroup, element);
    const order = getElementOrder(element);
    const resolved = buildDefaultResolvedTransform(currentTransform);

    let maxDuration = 0;

    transformProperties.forEach(property => {
        const target = resolved[property.type];
        const axes = RESOLVED_TRANSFORM_AXES[property.type];
        if (target && axes) {
            assignResolvedTransformProperty(target, property, currentTransform, axes);
        }
        if (property.duration > maxDuration) {
            maxDuration = property.duration;
        }
    });

    const activeProps = transformProperties.map(property => resolved[property.type]);
    const allSameEasing = activeProps.every(item => !item.easingKeyframes && item.easing === activeProps[0].easing);
    const allSameDuration = activeProps.every(item => item.duration === activeProps[0].duration);

    const forceGroups = computeForceGroups(resolved);

    if (allSameEasing && allSameDuration) {
        const tUx = resolved.translate.unitX || 'px';
        const tUy = resolved.translate.unitY || 'px';
        const tUz = resolved.translate.unitZ || 'px';
        const startTransform = buildTransformString(
            resolved.translate.startX, resolved.translate.startY, resolved.translate.startZ,
            resolved.scale.startX, resolved.scale.startY, resolved.scale.startZ,
            resolved.rotate.startX, resolved.rotate.startY, resolved.rotate.startZ,
            resolved.skew.startX, resolved.skew.startY, order, forceGroups, tUx, tUy, tUz
        );
        const endTransform = buildTransformString(
            resolved.translate.endX, resolved.translate.endY, resolved.translate.endZ,
            resolved.scale.endX, resolved.scale.endY, resolved.scale.endZ,
            resolved.rotate.endX, resolved.rotate.endY, resolved.rotate.endZ,
            resolved.skew.endX, resolved.skew.endY, order, forceGroups, tUx, tUy, tUz
        );

        const easing = activeProps[0].easing;
        const animationEasing = easingFunctions[easing] || easing;
        return {
            animation: element.animate([
                { transform: startTransform },
                { transform: endTransform }
            ], {
                duration: maxDuration,
                easing: animationEasing,
                fill: 'forwards',
                iterations: globalOptions.iterations,
                direction: globalOptions.direction
            }),
            resolved: resolved
        };
    }

    const KEYFRAME_COUNT = deriveTransformKeyframeCount(resolved);
    const keyframes = [];

    for (let index = 0; index < KEYFRAME_COUNT; index++) {
        const globalProgress = index / (KEYFRAME_COUNT - 1);
        const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
        const interpScale = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
        const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
        const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);

        keyframes.push({
            transform: buildTransformString(
                interpTranslate.x, interpTranslate.y, interpTranslate.z,
                interpScale.x, interpScale.y, interpScale.z,
                interpRotate.x, interpRotate.y, interpRotate.z,
                interpSkew.x, interpSkew.y, order, forceGroups,
                resolved.translate.unitX || 'px',
                resolved.translate.unitY || 'px',
                resolved.translate.unitZ || 'px'
            )
        });
    }

    return {
        animation: element.animate(keyframes, {
            duration: maxDuration,
            easing: 'linear',
            fill: 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        }),
        resolved: resolved
    };
}

/**
 * Persist a resized translate or scale value into the `lastKnownTransforms`
 * cache and into the element's inline `style.transform`.
 *
 * Inline write rationale: once any transform sub-property is animated by
 * WAAPI, the transform slot is "JS-owned" and Elm's `WAAPI.attributes`
 * stops rendering inline `transform` to avoid fighting the running
 * animation. That means JS is now the sole writer for inline `transform`,
 * and resize must update it so the resized value is visible after the
 * animation finishes/cancels (and so the DOM truthfully reflects the
 * post-resize state in devtools). While an animation is running, WAAPI
 * fully shadows the inline value, so this write is invisible until the
 * animation releases the slot — exactly when we need it.
 */
function persistResizedTransform(animGroup, element, propertyKey, currentResized) {
    const current = getTransformState(animGroup, element);
    const updated = { ...current };
    if (propertyKey === 'scale') {
        updated.scaleX = currentResized.x;
        updated.scaleY = currentResized.y;
        updated.scaleZ = currentResized.z;
    } else {
        updated.x = currentResized.x;
        updated.y = currentResized.y;
        updated.z = currentResized.z;
    }
    lastKnownTransforms.set(animGroup, updated);

    const order = getElementOrder(element);
    const transformString = buildTransformString(
        updated.x, updated.y, updated.z,
        updated.scaleX, updated.scaleY, updated.scaleZ,
        updated.rotateX, updated.rotateY, updated.rotateZ,
        updated.skewX, updated.skewY, order, undefined,
        updated.translateUnitX || 'px',
        updated.translateUnitY || 'px',
        updated.translateUnitZ || 'px'
    );
    element.style.transform = transformString;
}

/**
 * Update the in-flight transform animation for a group's translate sub-property
 * to match new bounds, without restarting. Replaces the underlying
 * `Animation` with one that has the new keyframes/timing, then sets
 * `currentTime` so the box continues moving smoothly from where it is.
 *
 * Triggered by Elm `Anim.Engine.WAAPI.onResize`. The Elm side has already
 * computed the new translate `start` / `end` / `current` values, the new
 * leg duration, the resize `strategy`, and the `currentTime` to set —
 * see `Anim.Internal.Engine.WAAPI.computeResizePayload` and
 * `Anim.Internal.Engine.WAAPI.scaleDurationForResize` for the math.
 *
 * Strategy branches when seeking `currentTime`:
 * - `proportional` preserves the temporal progress ratio
 *   (`currentTime / duration`) so the eased visual position lands at the
 *   same fractional spot along the new leg, exactly, for any easing.
 * - `clamp` (and any unknown / missing value, for back-compat) solves
 *   for the `currentTime` that places the box at the Elm-supplied
 *   `currentX/Y/Z` value via a linear inversion of the leg span.
 *
 * Non-translate transform sub-properties (rotate, scale, skew) are
 * preserved at their current resolved values.
 *
 * Resize commands arrive at native input cadence (often 30+ per displayed
 * frame during a drag-resize). We coalesce them via `requestAnimationFrame`
 * so each unique `(animGroup, property)` does at most one cancel+recreate
 * per displayed frame. Without coalescing, the dot's compositor layer
 * spends most of each frame snapped to its base transform during the brief
 * gap between `animation.cancel()` and the new `Animation` being committed,
 * which visually freezes the dot during the drag.
 *
 * Tests bypass coalescing by importing `_resizeTransformAnimationImmediate`
 * directly (see `js/tests/resize.test.js`).
 *
 * @param {object} commandData - Decoded `resize` port command payload.
 */
export function resizeTransformAnimation(commandData) {
    scheduleResize(commandData);
}

/**
 * Per-frame resize coalescing. Keyed by `${animGroup}:${property || 'translate'}`
 * so commands targeting different properties of the same element do not
 * stomp each other. Only the latest payload per key per frame is applied.
 */
const pendingResizes = new Map();
let pendingResizeFrame = null;

function scheduleResize(commandData) {
    const animGroup = commandData.elementId || commandData.animGroup;
    if (!animGroup) {
        // Let the immediate path emit the missing-id error so behaviour
        // matches pre-coalescing tests and runtime diagnostics.
        _resizeTransformAnimationImmediate(commandData);
        return;
    }
    const key = `${animGroup}:${commandData.property || 'translate'}`;
    pendingResizes.set(key, commandData);
    armResizeFrame();
}

function armResizeFrame() {
    const raf = typeof globalThis !== 'undefined' && typeof globalThis.requestAnimationFrame === 'function'
        ? globalThis.requestAnimationFrame
        : null;
    if (raf === null) {
        // No rAF (non-browser host) — flush synchronously to preserve behaviour.
        flushPendingResizes();
        return;
    }
    if (pendingResizeFrame !== null) {
        return;
    }
    pendingResizeFrame = raf(() => {
        pendingResizeFrame = null;
        flushPendingResizes();
    });
}

/**
 * Drain the coalesced resize queue immediately. Exported so tests and
 * shutdown paths can force a flush without waiting for a rAF tick.
 */
export function flushPendingResizes() {
    if (pendingResizes.size === 0) {
        return;
    }
    const resizeBatch = Array.from(pendingResizes.values());
    pendingResizes.clear();
    for (const payload of resizeBatch) {
        try {
            _resizeTransformAnimationImmediate(payload);
        } catch (err) {
            reportError(`resize flush failed: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'error',
                code: 'COMMAND_FAILED',
                engine: 'WAAPI'
            });
        }
    }
}

/**
 * Synchronous resize worker. Direct callers (tests, `flushPendingResizes`)
 * use this to bypass the per-frame coalescing layer.
 *
 * @param {object} commandData - Decoded `resize` port command payload.
 */
export function _resizeTransformAnimationImmediate(commandData) {
    const animGroup = commandData.elementId || commandData.animGroup;
    if (!animGroup) {
        reportError('resize command missing elementId/animGroup', {
            source: 'animation',
            severity: 'warning',
            code: 'COMMAND_INVALID',
            engine: 'WAAPI'
        });
        return;
    }

    const element = findAnimTarget(animGroup);
    if (!element) {
        reportError(`Element with data-anim-target="${animGroup}" not found`, {
            source: 'animation',
            severity: 'warning',
            code: 'TARGET_NOT_FOUND',
            engine: 'WAAPI',
            elementId: animGroup
        });
        return;
    }

    if (commandData.property === 'perspectiveOrigin') {
        resizePerspectiveOriginAnimation(commandData, animGroup, element);
        return;
    }

    if (commandData.property === 'size') {
        resizeSizeAnimation(commandData, animGroup, element);
        return;
    }

    const propertyKey = commandData.property === 'scale' ? 'scale' : 'translate';

    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims || !elementAnims.has('transform')) {
        return;
    }

    const existing = elementAnims.get('transform');
    const resolved = existing.resolvedValues;
    if (!resolved || !resolved[propertyKey]) {
        return;
    }

    const animation = existing.animation;
    if (!animation || !animation.effect) {
        return;
    }

    // Fast path: when start/end/duration of the resized slot are identical
    // to what JS already has, the resize cmd is purely advisory (Elm fired
    // because `currentTimeMs` drifted as Progress events advanced — the
    // engine's geometry is unchanged). Skipping the cancel+recreate avoids
    // a per-rAF restart that the user perceives as the animation speeding
    // up during a continuous window drag, while leaving the running WAAPI
    // animation to keep ticking on its own undisturbed clock.
    if (isResizeGeometryUnchanged(commandData, resolved[propertyKey], Number(animation.effect.getTiming().duration) || 0)) {
        return;
    }

    // Read the live pre-resize state. WAAPI preserves `currentIteration`
    // and direction across `setKeyframes` / `updateTiming`, so all we need
    // to preserve manually is the box's target physical position. Elm
    // computes that target via `Resize.applyAxis` (honouring Proportional
    // vs Clamp) and ships it as `currentX/Y/Z` in the payload — JS must
    // solve for the `currentTime` that lands the box at that target,
    // otherwise the strategy choice is silently overridden.
    const oldTiming = animation.effect.getTiming() || {};
    const oldDuration = Number(oldTiming.duration) || 0;
    const oldCurrentTime = Number(animation.currentTime) || 0;
    const oldDirection = oldTiming.direction || 'normal';
    const oldLegProgress = computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation);

    // Strategy-aware target position from Elm. Falls back to the box's
    // current physical position derived from the running animation if the
    // payload omits it (older callers / safety).
    const hasCurrentFromCommand = commandData.currentX !== undefined
        && commandData.currentY !== undefined
        && commandData.currentZ !== undefined;
    const oldVisualPosition = oldLegProgress !== null
        ? interpolateSubProperty(resolved[propertyKey], oldLegProgress, oldDuration)
        : null;

    const hasElmCurrentTime = typeof commandData.currentTimeMs === 'number' && isFinite(commandData.currentTimeMs);

    let targetPosition = null;
    if (!hasElmCurrentTime && oldVisualPosition) {
        targetPosition = {
            x: chooseEffectiveAxisValue(
                Number(resolved[propertyKey].startX),
                Number(resolved[propertyKey].endX),
                Number(commandData.startX),
                Number(commandData.endX),
                hasCurrentFromCommand ? Number(commandData.currentX) : oldVisualPosition.x,
                oldVisualPosition.x
            ),
            y: chooseEffectiveAxisValue(
                Number(resolved[propertyKey].startY),
                Number(resolved[propertyKey].endY),
                Number(commandData.startY),
                Number(commandData.endY),
                hasCurrentFromCommand ? Number(commandData.currentY) : oldVisualPosition.y,
                oldVisualPosition.y
            ),
            z: chooseEffectiveAxisValue(
                Number(resolved[propertyKey].startZ),
                Number(resolved[propertyKey].endZ),
                Number(commandData.startZ),
                Number(commandData.endZ),
                hasCurrentFromCommand ? Number(commandData.currentZ) : oldVisualPosition.z,
                oldVisualPosition.z
            )
        };
    } else if (hasCurrentFromCommand) {
        targetPosition = {
            x: Number(commandData.currentX),
            y: Number(commandData.currentY),
            z: Number(commandData.currentZ)
        };
    } else if (oldVisualPosition) {
        targetPosition = oldVisualPosition;
    }

    const currentResized = targetPosition || {
        x: commandData.currentX !== undefined ? Number(commandData.currentX) : Number(commandData.endX),
        y: commandData.currentY !== undefined ? Number(commandData.currentY) : Number(commandData.endY),
        z: commandData.currentZ !== undefined ? Number(commandData.currentZ) : Number(commandData.endZ)
    };

    // Persist the resized values into lastKnownTransforms and inline style so
    // they survive across animation cleanup boundaries. The inline transform
    // is shadowed while a transform animation is running, but takes effect
    // the moment the animation is cancelled or finishes without `fill`,
    // ensuring the next `WAAPI.animate` cycle reads the resized values as its
    // start. Also handles the no-active-animation case directly.
    persistResizedTransform(animGroup, element, propertyKey, currentResized);

    // Patch the resized property slot with the Elm-supplied new bounds.
    // Other transform sub-properties keep their existing resolved values
    // so a resize on one property does not disturb the others.
    //
    // `hasAnimationBaseline === false` means Elm has no real animation for
    // this property (e.g. `Scale.init` paired with `Scale.onResize` while
    // a Rotate animation runs). The payload's `duration` is a synthetic
    // snapshot-bake value; using it would shrink the resized slot's
    // duration and (worse) starve the keyframe sampling for co-running
    // properties. Preserve the previous slot duration in that case.
    const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
    const hasBaseline = commandData.hasAnimationBaseline !== false;
    const newDuration = hasBaseline ? payloadDuration : oldDuration;
    const previousSlotDuration = resolved[propertyKey].duration;
    resolved[propertyKey] = {
        startX: Number(commandData.startX),
        startY: Number(commandData.startY),
        startZ: Number(commandData.startZ),
        endX: Number(commandData.endX),
        endY: Number(commandData.endY),
        endZ: Number(commandData.endZ),
        easing: resolved[propertyKey].easing,
        easingKeyframes: resolved[propertyKey].easingKeyframes,
        duration: hasBaseline ? payloadDuration : previousSlotDuration
    };

    const order = getElementOrder(element);

    // Build a 30-frame interpolated transform so non-linear timing on
    // co-running rotate/scale/skew is preserved. This mirrors the
    // multi-easing branch of createMergedTransformAnimation, which
    // samples every sub-property against the *maximum* duration across
    // all sub-properties — using a single sub-property's duration here
    // (e.g. the resized one) would scale the others' progress by
    // `subProp.duration / chosenDuration`, freezing co-running long
    // animations like an 8000 ms rotate when a 300 ms scale resizes.
    const maxDuration = Math.max(
        Number(resolved.translate?.duration) || 0,
        Number(resolved.scale?.duration) || 0,
        Number(resolved.rotate?.duration) || 0,
        Number(resolved.skew?.duration) || 0
    );
    const forceGroups = computeForceGroups(resolved);
    const KEYFRAME_COUNT = deriveTransformKeyframeCount(resolved);
    const keyframes = [];
    for (let index = 0; index < KEYFRAME_COUNT; index++) {
        const globalProgress = index / (KEYFRAME_COUNT - 1);
        const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
        const interpScale = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
        const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
        const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);

        keyframes.push({
            transform: buildTransformString(
                interpTranslate.x, interpTranslate.y, interpTranslate.z,
                interpScale.x, interpScale.y, interpScale.z,
                interpRotate.x, interpRotate.y, interpRotate.z,
                interpSkew.x, interpSkew.y, order, forceGroups,
                resolved.translate.unitX || 'px',
                resolved.translate.unitY || 'px',
                resolved.translate.unitZ || 'px'
            )
        });
    }

    // When Elm has no animation baseline for the resized property (init-only
    // value, e.g. `Scale.init` alongside a Rotate animation), the resize is
    // a "snapshot bake": we only want to splice the new value into the
    // running transform animation's keyframes so it stays visually current.
    // Recreating the animation here would restart the unrelated property's
    // animation (rotate, etc.) because the synthesized baseline carries
    // `duration=0` / `currentTimeMs=0`. Apply keyframes in place and exit.
    if (commandData.hasAnimationBaseline === false) {
        try {
            animation.effect.setKeyframes(keyframes);
        } catch (err) {
            reportError(`setKeyframes failed during resize: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'warning',
                code: 'RESIZE_SET_KEYFRAMES_FAILED',
                engine: 'WAAPI',
                elementId: animGroup
            });
        }
        return;
    }

    // Compute the target `currentTime` BEFORE we touch the running
    // animation, so we can apply it atomically on the freshly-created
    // replacement. Two paths:
    //
    // - Elm-supplied `currentTimeMs` (Proportional strategy): Elm has the
    //   authoritative answer (preserve full-iteration count + in-iteration
    //   progress for looping legs, restart from `0` for the collapsed
    //   one-shot leg). We just apply it.
    //
    // - Fallback (Clamp strategy / `currentTimeMs == null`): solve for
    //   the currentTime that places the box at the strategy-aware target
    //   position Elm computed via `Resize.applyAxis`. Reuse the box's
    //   pre-resize `oldIter` to preserve iteration count + leg parity.
    //   For a 1D translate (the common resize case) this is exact for
    //   Linear easing and approximate for non-linear, matching Clamp's
    //   "preserve current value" promise.
    //
    // Elm is the source of truth: when `currentTimeMs` is present, JS
    // must apply it as-is. Any second-guessing here masks Elm-side bugs.
    // `commandData.legRedefined === true` makes the intent explicit —
    // Elm has rebased `start` to the current visual position and the
    // authoritative seek is `0` on the redefined leg.
    let newCurrentTime = null;
    if (hasElmCurrentTime) {
        newCurrentTime = commandData.currentTimeMs;
    } else if (targetPosition !== null && newDuration > 0 && oldDuration > 0) {
        const newStartX = Number(commandData.startX);
        const newEndX = Number(commandData.endX);
        const newStartY = Number(commandData.startY);
        const newEndY = Number(commandData.endY);
        const newStartZ = Number(commandData.startZ);
        const newEndZ = Number(commandData.endZ);

        const spans = {
            x: newEndX - newStartX,
            y: newEndY - newStartY,
            z: newEndZ - newStartZ
        };

        const chosenAxis = chooseDominantAxis(spans);
        let pWanted = 0;
        if (chosenAxis === 'x') {
            pWanted = (targetPosition.x - newStartX) / spans.x;
        } else if (chosenAxis === 'y') {
            pWanted = (targetPosition.y - newStartY) / spans.y;
        } else if (chosenAxis === 'z') {
            pWanted = (targetPosition.z - newStartZ) / spans.z;
        }
        if (pWanted < 0) pWanted = 0;
        if (pWanted > 1) pWanted = 1;

        const oldIter = Math.floor(oldCurrentTime / oldDuration);
        let pWithinIter = pWanted;
        if (oldDirection === 'alternate' || oldDirection === 'alternate-reverse') {
            const startsReversed = oldDirection === 'alternate-reverse';
            const isReverseLeg = (oldIter % 2 === 1) !== startsReversed;
            if (isReverseLeg) {
                pWithinIter = 1 - pWanted;
            }
        } else if (oldDirection === 'reverse') {
            pWithinIter = 1 - pWanted;
        }
        newCurrentTime = (oldIter + pWithinIter) * newDuration;
    }

    // Cancel + recreate (not in-place mutate). The in-place approach
    // (`setKeyframes` → `updateTiming` → `currentTime =`) suffers from a
    // one-composited-frame race: between `setKeyframes` and the
    // `currentTime` write, the compositor can sample the new keyframes
    // at the *old* `currentTime`, producing a visible flicker
    // `tx = newEnd × (oldCurrentTime / oldDuration)` for one frame before
    // snapping to the correct seeked position. Recreating the Animation
    // with the new keyframes/timing already set, then seeking before the
    // first composite, avoids the mismatched-state frame entirely.
    //
    // Iteration count and alternate-leg parity survive the recreate
    // because the seeked `currentTime` (= `(oldIter + pWithin) × newDuration`)
    // already encodes them — WAAPI derives `currentIteration` from
    // `currentTime / duration`, so iter=N forward/reverse leg is restored
    // automatically without an explicit `iterationStart`.
    const transformEntry = elementAnims.get('transform');
    const oldVersion = transformEntry.version;
    const newVersion = oldVersion + 1;
    const wasPaused = animation.playState === 'paused';
    const oldIterations = oldTiming.iterations;
    const animateOptions = {
        duration: newDuration > 0 ? newDuration : oldDuration,
        easing: 'linear',
        fill: 'forwards',
        iterations: Number.isFinite(oldIterations) || oldIterations === Infinity ? oldIterations : 1,
        direction: oldDirection
    };

    // Bump entry.version BEFORE cancelling so the old animation's `cancel`
    // event handler sees `entry.version !== capturedVersion` and exits
    // early without emitting a `cancelled` lifecycle event. The new
    // animation's `setupAnimationEvents` call below installs fresh
    // listeners keyed on the new version.
    transformEntry.version = newVersion;
    try {
        animation.cancel();
    } catch (err) {
        reportError(`cancel failed during resize: ${err && err.message ? err.message : err}`, {
            source: 'animation',
            severity: 'warning',
            code: 'RESIZE_CANCEL_FAILED',
            engine: 'WAAPI',
            elementId: animGroup
        });
    }

    let newAnimation = null;
    try {
        newAnimation = element.animate(keyframes, animateOptions);
    } catch (err) {
        reportError(`element.animate failed during resize: ${err && err.message ? err.message : err}`, {
            source: 'animation',
            severity: 'warning',
            code: 'RESIZE_RECREATE_FAILED',
            engine: 'WAAPI',
            elementId: animGroup
        });
        return;
    }

    if (newCurrentTime !== null) {
        try {
            newAnimation.currentTime = newCurrentTime;
        } catch (err) {
            reportError(`currentTime assignment failed during resize: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'warning',
                code: 'RESIZE_CURRENT_TIME_FAILED',
                engine: 'WAAPI',
                elementId: animGroup
            });
        }
    }

    if (wasPaused) {
        try { newAnimation.pause(); } catch (_pauseErr) { /* non-fatal */ }
    }

    transformEntry.animation = newAnimation;
    transformEntry.updateFn = setupAnimationEvents(
        animGroup,
        'transform',
        element,
        newAnimation,
        newVersion,
        transformEntry.resolvedValues
    );
}


function resizePerspectiveOriginAnimation(commandData, animGroup, element) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims || !elementAnims.has('perspectiveOrigin')) {
        return;
    }

    const entry = elementAnims.get('perspectiveOrigin');
    const animation = entry.animation;
    if (!animation || !animation.effect) {
        return;
    }

    const oldTiming = animation.effect.getTiming() || {};
    const oldDuration = Number(oldTiming.duration) || 0;
    const oldCurrentTime = Number(animation.currentTime) || 0;
    const oldDirection = oldTiming.direction || 'normal';

    // Fast-path skip: when start/end/duration/unit of the perspective-origin
    // slot are identical to what JS already has, the resize cmd is purely
    // advisory (Elm fired because `currentTimeMs` advanced via Progress
    // ticks during a continuous drag). Mirrors the translate handler's
    // `isResizeGeometryUnchanged` early-return at the top of
    // `_resizeTransformAnimationImmediate` — without it, the perspective
    // animation gets cancel+recreate+seek-to-stale-`commandData.currentTimeMs`
    // every flush while its sibling translate just `setKeyframes` and
    // keeps ticking, so perspective falls 8-16 ms behind translate per
    // flush and the dot finishes the leg before the perspective container
    // catches up.
    const previousResolved = entry.resolvedNonTransform || null;
    if (isPerspectiveOriginGeometryUnchanged(commandData, previousResolved, oldDuration)) {
        return;
    }

    const oldLegProgress = computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation);

    const unit = typeof commandData.unit === 'string' ? commandData.unit : '%';
    const oldVisual =
        oldLegProgress !== null
            && previousResolved
            && isFiniteNumber(previousResolved.startX)
            && isFiniteNumber(previousResolved.endX)
            && isFiniteNumber(previousResolved.startY)
            && isFiniteNumber(previousResolved.endY)
            ? {
                x: previousResolved.startX + (previousResolved.endX - previousResolved.startX) * oldLegProgress,
                y: previousResolved.startY + (previousResolved.endY - previousResolved.startY) * oldLegProgress
            }
            : null;

    const hasElmCurrentTime = typeof commandData.currentTimeMs === 'number' && isFinite(commandData.currentTimeMs);
    const effectiveCurrentPosition = !hasElmCurrentTime && oldVisual
        ? {
            x: chooseEffectiveAxisValue(
                Number(previousResolved?.startX),
                Number(previousResolved?.endX),
                Number(commandData.startX),
                Number(commandData.endX),
                Number(commandData.currentX),
                oldVisual.x
            ),
            y: chooseEffectiveAxisValue(
                Number(previousResolved?.startY),
                Number(previousResolved?.endY),
                Number(commandData.startY),
                Number(commandData.endY),
                Number(commandData.currentY),
                oldVisual.y
            )
        }
        : {
            x: Number(commandData.currentX),
            y: Number(commandData.currentY)
        };

    const resolved = {
        type: 'perspectiveOrigin',
        startX: Number(commandData.startX),
        startY: Number(commandData.startY),
        endX: Number(commandData.endX),
        endY: Number(commandData.endY),
        unitX: unit,
        unitY: unit
    };

    const keyframeData = buildPropertyKeyframes(resolved, entry.easingKeyframes, 'linear');
    if (!keyframeData || !keyframeData.keyframes) {
        return;
    }

    const hasBaseline = commandData.hasAnimationBaseline !== false;
    const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
    const newDuration = hasBaseline ? payloadDuration : oldDuration;
    const wasPaused = animation.playState === 'paused';

    let newCurrentTime = null;
    if (hasElmCurrentTime) {
        // Elm is the source of truth for the seek target; apply unconditionally.
        newCurrentTime = commandData.currentTimeMs;
    } else if (oldDuration > 0 && newDuration > 0) {
        const oldIter = Math.floor(oldCurrentTime / oldDuration);
        const startsReversed = oldDirection === 'alternate-reverse';
        const isAlternate = oldDirection === 'alternate' || oldDirection === 'alternate-reverse';
        const isReverseLeg = isAlternate ? ((oldIter % 2 === 1) !== startsReversed) : oldDirection === 'reverse';

        const xStart = Number(commandData.startX);
        const xEnd = Number(commandData.endX);
        const yStart = Number(commandData.startY);
        const yEnd = Number(commandData.endY);

        const spans = {
            x: xEnd - xStart,
            y: yEnd - yStart,
            z: 0
        };

        const chosenAxis = chooseDominantAxis(spans);

        let pWanted = 0;
        if (chosenAxis === 'x') {
            pWanted = (effectiveCurrentPosition.x - xStart) / spans.x;
        } else if (chosenAxis === 'y') {
            pWanted = (effectiveCurrentPosition.y - yStart) / spans.y;
        }
        if (pWanted < 0) pWanted = 0;
        if (pWanted > 1) pWanted = 1;

        const pWithinIter = isReverseLeg ? 1 - pWanted : pWanted;
        newCurrentTime = (oldIter + pWithinIter) * newDuration;
    }

    const oldVersion = entry.version;
    const newVersion = oldVersion + 1;
    const oldIterations = oldTiming.iterations;
    const animateOptions = {
        duration: newDuration > 0 ? newDuration : oldDuration,
        easing: keyframeData.animationEasing || 'linear',
        fill: 'forwards',
        iterations: Number.isFinite(oldIterations) || oldIterations === Infinity ? oldIterations : 1,
        direction: oldDirection
    };

    entry.version = newVersion;
    try {
        animation.cancel();
    } catch (_err) {
        // Best-effort: keep going and recreate.
    }

    let newAnimation = null;
    try {
        newAnimation = element.animate(keyframeData.keyframes, animateOptions);
    } catch (_err) {
        return;
    }

    if (newCurrentTime !== null) {
        try {
            newAnimation.currentTime = newCurrentTime;
        } catch (_err) {
            // Non-fatal; animation still recreated with new bounds.
        }
    }

    if (wasPaused) {
        try { newAnimation.pause(); } catch (_pauseErr) { /* non-fatal */ }
    }

    element.style.perspectiveOrigin = `${effectiveCurrentPosition.x}${unit} ${effectiveCurrentPosition.y}${unit}`;

    entry.animation = newAnimation;
    entry.resolvedNonTransform = resolved;
    entry.updateFn = setupAnimationEvents(
        animGroup,
        'perspectiveOrigin',
        element,
        newAnimation,
        newVersion,
        null
    );
}

function resizeSizeAnimation(commandData, animGroup, element) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims || !elementAnims.has('size')) {
        return;
    }

    const entry = elementAnims.get('size');
    const animation = entry.animation;
    if (!animation || !animation.effect) {
        return;
    }

    const oldTiming = animation.effect.getTiming() || {};
    const oldDuration = Number(oldTiming.duration) || 0;
    const oldCurrentTime = Number(animation.currentTime) || 0;
    const oldDirection = oldTiming.direction || 'normal';

    // Fast-path skip mirroring the perspective-origin handler: a resize cmd
    // whose start/end/duration/unit match what JS already has is purely
    // advisory (Elm fired because `currentTimeMs` advanced via Progress
    // ticks during a continuous drag). Without this, every flush would
    // cancel+recreate and reset the animation's clock.
    const previousResolved = entry.resolvedNonTransform || null;
    if (isSizeGeometryUnchanged(commandData, previousResolved, oldDuration)) {
        return;
    }

    const oldLegProgress = computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation);

    const unit = typeof commandData.unit === 'string' ? commandData.unit : 'px';
    const oldVisual =
        oldLegProgress !== null
            && previousResolved
            && isFiniteNumber(previousResolved.startWidth)
            && isFiniteNumber(previousResolved.endWidth)
            && isFiniteNumber(previousResolved.startHeight)
            && isFiniteNumber(previousResolved.endHeight)
            ? {
                x: previousResolved.startWidth + (previousResolved.endWidth - previousResolved.startWidth) * oldLegProgress,
                y: previousResolved.startHeight + (previousResolved.endHeight - previousResolved.startHeight) * oldLegProgress
            }
            : null;

    const hasElmCurrentTime = typeof commandData.currentTimeMs === 'number' && isFinite(commandData.currentTimeMs);
    const effectiveCurrentPosition = !hasElmCurrentTime && oldVisual
        ? {
            x: chooseEffectiveAxisValue(
                Number(previousResolved?.startWidth),
                Number(previousResolved?.endWidth),
                Number(commandData.startX),
                Number(commandData.endX),
                Number(commandData.currentX),
                oldVisual.x
            ),
            y: chooseEffectiveAxisValue(
                Number(previousResolved?.startHeight),
                Number(previousResolved?.endHeight),
                Number(commandData.startY),
                Number(commandData.endY),
                Number(commandData.currentY),
                oldVisual.y
            )
        }
        : {
            x: Number(commandData.currentX),
            y: Number(commandData.currentY)
        };

    const resolved = {
        type: 'size',
        startWidth: Number(commandData.startX),
        startHeight: Number(commandData.startY),
        endWidth: Number(commandData.endX),
        endHeight: Number(commandData.endY),
        unitWidth: unit,
        unitHeight: unit
    };

    const keyframeData = buildPropertyKeyframes(resolved, entry.easingKeyframes, 'linear');
    if (!keyframeData || !keyframeData.keyframes) {
        return;
    }

    const hasBaseline = commandData.hasAnimationBaseline !== false;
    const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
    const newDuration = hasBaseline ? payloadDuration : oldDuration;
    const wasPaused = animation.playState === 'paused';

    let newCurrentTime = null;
    if (hasElmCurrentTime) {
        newCurrentTime = commandData.currentTimeMs;
    } else if (oldDuration > 0 && newDuration > 0) {
        const oldIter = Math.floor(oldCurrentTime / oldDuration);
        const startsReversed = oldDirection === 'alternate-reverse';
        const isAlternate = oldDirection === 'alternate' || oldDirection === 'alternate-reverse';
        const isReverseLeg = isAlternate ? ((oldIter % 2 === 1) !== startsReversed) : oldDirection === 'reverse';

        const xStart = Number(commandData.startX);
        const xEnd = Number(commandData.endX);
        const yStart = Number(commandData.startY);
        const yEnd = Number(commandData.endY);

        const spans = {
            x: xEnd - xStart,
            y: yEnd - yStart,
            z: 0
        };

        const chosenAxis = chooseDominantAxis(spans);

        let pWanted = 0;
        if (chosenAxis === 'x') {
            pWanted = (effectiveCurrentPosition.x - xStart) / spans.x;
        } else if (chosenAxis === 'y') {
            pWanted = (effectiveCurrentPosition.y - yStart) / spans.y;
        }
        if (pWanted < 0) pWanted = 0;
        if (pWanted > 1) pWanted = 1;

        const pWithinIter = isReverseLeg ? 1 - pWanted : pWanted;
        newCurrentTime = (oldIter + pWithinIter) * newDuration;
    }

    const oldVersion = entry.version;
    const newVersion = oldVersion + 1;
    const oldIterations = oldTiming.iterations;
    const animateOptions = {
        duration: newDuration > 0 ? newDuration : oldDuration,
        easing: keyframeData.animationEasing || 'linear',
        fill: 'forwards',
        iterations: Number.isFinite(oldIterations) || oldIterations === Infinity ? oldIterations : 1,
        direction: oldDirection
    };

    entry.version = newVersion;
    try {
        animation.cancel();
    } catch (_err) {
        // Best-effort: keep going and recreate.
    }

    let newAnimation = null;
    try {
        newAnimation = element.animate(keyframeData.keyframes, animateOptions);
    } catch (_err) {
        return;
    }

    if (newCurrentTime !== null) {
        try {
            newAnimation.currentTime = newCurrentTime;
        } catch (_err) {
            // Non-fatal; animation still recreated with new bounds.
        }
    }

    if (wasPaused) {
        try { newAnimation.pause(); } catch (_pauseErr) { /* non-fatal */ }
    }

    element.style.width = `${effectiveCurrentPosition.x}${unit}`;
    element.style.height = `${effectiveCurrentPosition.y}${unit}`;

    entry.animation = newAnimation;
    entry.resolvedNonTransform = resolved;
    entry.updateFn = setupAnimationEvents(
        animGroup,
        'size',
        element,
        newAnimation,
        newVersion,
        null
    );
}

export function processAnimationData(animationData) {
    if (!animationData || !animationData.elements) {
        reportError('Invalid animation data format received', {
            source: 'animation',
            severity: 'warning',
            code: 'COMMAND_INVALID',
            engine: 'WAAPI'
        });
        return;
    }

    const globalOptions = {
        iterations: parseIterations(animationData.iterations),
        direction: animationData.direction || 'normal'
    };
    const isRestart = animationData.isRestart || false;

    Object.entries(animationData.elements).forEach(([animGroup, elementConfig]) => {
        const targets = findAllAnimTargets(animGroup);
        if (targets.length <= 1) {
            processElementAnimation(animGroup, elementConfig, globalOptions, isRestart);
            return;
        }

        targets.forEach((element, index) => {
            const uniqueId = element.id || (animGroup + '__multi_' + index);
            processElementAnimation(uniqueId, elementConfig, globalOptions, isRestart, element);
        });
    });
}

/**
 * Snap touched properties to their new target values with no animation.
 *
 * For every property in `commandData.elements`, cancels any in-flight WAAPI
 * animation on that property and writes the target value as inline style.
 * Untouched properties on the same anim group are left alone (their
 * animations continue running).
 *
 * Builder timing (duration/delay/easing/spring) carried in the payload is
 * ignored — the snap writes the END state directly. A `cancelled`
 * lifecycle event is emitted via the in-flight animation's `cancel`
 * listener for any previously-playing animation that the snap kills.
 */
export function retargetAnimation(commandData) {
    if (!commandData || !commandData.elements) {
        reportError('Invalid retarget data format received', {
            source: 'animation',
            severity: 'warning',
            code: 'COMMAND_INVALID',
            engine: 'WAAPI'
        });
        return;
    }

    Object.entries(commandData.elements).forEach(([animGroup, elementConfig]) => {
        const targets = findAllAnimTargets(animGroup);
        if (targets.length <= 1) {
            retargetElement(animGroup, elementConfig);
            return;
        }

        targets.forEach((element, index) => {
            const uniqueId = element.id || (animGroup + '__multi_' + index);
            retargetElement(uniqueId, elementConfig, element);
        });
    });
}

function retargetElement(animGroup, elementConfig, resolvedElement = null) {
    const element = resolvedElement || findAnimTarget(animGroup);
    if (!element) {
        reportError(`Element with data-anim-target="${animGroup}" not found`, {
            source: 'animation',
            severity: 'warning',
            code: 'TARGET_NOT_FOUND',
            engine: 'WAAPI',
            elementId: animGroup
        });
        return;
    }

    const properties = elementConfig.properties || [];

    // Seed transformBaseline cache so a follow-up animate() reads the
    // correct start values when nothing has populated the cache yet.
    if (elementConfig.transformBaseline && !lastKnownTransforms.has(animGroup)) {
        lastKnownTransforms.set(animGroup, baselineToTransformState(elementConfig.transformBaseline));
    }

    if (elementConfig.transformOrder && elementConfig.transformOrder.length > 0) {
        elementTransformOrders.set(animGroup, elementConfig.transformOrder);
    }

    const transformProperties = properties.filter(property => isTransformProperty(property.type));
    const nonTransformProperties = properties.filter(property => !isTransformProperty(property.type));

    const elementAnims = activeAnimations.get(animGroup);

    let cancelledAnything = false;
    if (transformProperties.length > 0) {
        const continuationApplied = retargetTransformWithContinuation(
            animGroup, element, transformProperties, elementAnims
        );
        if (!continuationApplied) {
            cancelledAnything = snapTransformProperties(animGroup, element, transformProperties, elementAnims) || cancelledAnything;
        }
    }

    nonTransformProperties.forEach(property => {
        const continuationApplied = retargetNonTransformWithContinuation(
            animGroup, element, property, elementAnims
        );
        if (continuationApplied) {
            cancelledAnything = true;
        } else {
            cancelledAnything = snapNonTransformProperty(animGroup, element, property, elementAnims) || cancelledAnything;
        }
    });

    // Emit a single `cancelled` lifecycle event per group when at least
    // one in-flight animation was actually killed by the snap. The
    // per-property cancel listeners were short-circuited (see
    // `cancelSilently`) precisely so they could not race the snap by
    // pushing a stale mid-flight `propertyUpdate` that would regress the
    // snapshot Elm already advanced to the target.
    if (cancelledAnything) {
        sendLifecycleEvent('cancelled', animGroup);
    }
}

/**
 * Cancel the WAAPI Animation handle without letting its `cancel` event
 * listener fire its usual finalize path (which would emit a stale
 * mid-flight `propertyUpdate` and a `cancelled` lifecycle event).
 *
 * The listener guards every side-effect with `isActiveEntry()`, which
 * checks `activeAnimations.get(animGroup).get(propType).version`. By
 * deleting the entry before calling `.cancel()`, we make that lookup
 * fail and the listener exits silently. The snap emits its own
 * lifecycle event from `retargetElement` once for the whole group.
 *
 * Returns `true` when an entry existed and was cancelled.
 */
function cancelSilently(elementAnims, propType) {
    if (!elementAnims || !elementAnims.has(propType)) {
        return false;
    }
    const existing = elementAnims.get(propType);
    elementAnims.delete(propType);
    try {
        existing.animation.cancel();
    } catch (_) {
        // Already-cancelled / detached handles are safe to ignore.
    }
    return true;
}

/**
 * Compute the live mid-flight transform of an in-flight merged transform
 * animation. Falls back to the cached `lastKnownTransforms` state when
 * the animation has no resolved values or has not started ticking yet.
 */
function readLiveTransform(animGroup, element, existing) {
    if (existing && existing.resolvedValues) {
        const timing = existing.animation?.effect?.getTiming();
        const duration = timing?.duration || 0;
        const currentTime = existing.animation?.currentTime || 0;
        if (duration > 0) {
            const progress = Math.min(1.0, Math.max(0.0, currentTime / duration));
            return computeTransformFromResolved(existing.resolvedValues, progress, duration);
        }
    }
    return getTransformState(animGroup, element);
}

/**
 * Build a continuation transform animation when the retarget command
 * touches only a subset of axes on one or more bundled transform
 * properties (translate / scale / rotate / skew) and an in-flight
 * transform animation is mid-flight. Touched axes snap to the new
 * target via flat keyframes; untouched axes preserve the in-flight
 * animation's original (start, end, easing) so they continue smoothly
 * toward their existing target. The new WAAPI animation uses the same
 * total duration as the old one and starts with `delay: -oldT`,
 * putting it at the same progress where the old one was cancelled —
 * for untouched axes this is indistinguishable from the original
 * animation continuing.
 *
 * Returns `true` when a continuation animation was built; `false` when
 * the caller should fall back to the full-snap path (no in-flight
 * animation, no touched-axis flags on any transform property in the
 * command, or every axis is touched).
 */
function retargetTransformWithContinuation(animGroup, element, transformProperties, elementAnims) {
    if (!elementAnims) return false;
    const existing = elementAnims.get('transform');
    if (!existing || !existing.resolvedValues || !existing.animation) return false;

    const timing = existing.animation.effect?.getTiming();
    const oldDuration = timing?.duration || 0;
    if (!(oldDuration > 0)) return false;

    const oldT = existing.animation.currentTime;
    if (!Number.isFinite(oldT) || oldT < 0 || oldT >= oldDuration) return false;

    let hasAnyTouchedFlag = false;
    let hasAnyUntouched = false;
    for (const property of transformProperties) {
        const axes = RESOLVED_TRANSFORM_AXES[property.type];
        if (!axes) continue;
        for (const { suffix } of axes) {
            const flag = property[`touched${suffix}`];
            if (typeof flag === 'boolean') {
                hasAnyTouchedFlag = true;
                if (flag === false) hasAnyUntouched = true;
            }
        }
    }
    if (!hasAnyTouchedFlag || !hasAnyUntouched) return false;

    // Shallow clone preserves old per-axis start/end/easing/units;
    // mutations below only overwrite touched axes (snap) and any
    // transform property the retarget command does not address (left
    // entirely as-is from the in-flight resolved values).
    const oldResolved = existing.resolvedValues;
    const resolved = {
        translate: { ...oldResolved.translate },
        scale: { ...oldResolved.scale },
        rotate: { ...oldResolved.rotate },
        skew: { ...oldResolved.skew }
    };

    transformProperties.forEach(property => {
        const target = resolved[property.type];
        const axes = RESOLVED_TRANSFORM_AXES[property.type];
        if (!target || !axes) return;

        const hasTouchedFlags = axes.some(
            ({ suffix }) => typeof property[`touched${suffix}`] === 'boolean'
        );

        if (!hasTouchedFlags) {
            // No per-axis flags on this property: full-snap every axis.
            axes.forEach(({ suffix }) => {
                const newEnd = property[`end${suffix}`];
                if (!Number.isFinite(newEnd)) return;
                target[`start${suffix}`] = newEnd;
                target[`end${suffix}`] = newEnd;
            });
        } else {
            // Per-axis flags present: only touched axes snap; untouched
            // axes keep the in-flight start/end/easing.
            axes.forEach(({ suffix }) => {
                if (property[`touched${suffix}`] !== true) return;
                const newEnd = property[`end${suffix}`];
                if (!Number.isFinite(newEnd)) return;
                target[`start${suffix}`] = newEnd;
                target[`end${suffix}`] = newEnd;
            });
        }
    });

    // Carry forward any user-supplied units on the retarget command for
    // translate axes; absent values keep the in-flight units to avoid
    // unit-interpretation jumps. (Translate is the only bundled
    // transform property with per-axis CSS units.)
    const translateProp = transformProperties.find(property => property.type === 'translate');
    if (translateProp) {
        ['unitX', 'unitY', 'unitZ'].forEach(key => {
            const candidate = translateProp[key];
            if (typeof candidate === 'string' && candidate.length > 0) {
                resolved.translate[key] = candidate;
            }
        });
    }

    cancelSilently(elementAnims, 'transform');
    cancelLegacyTransformAnimations(elementAnims);

    const order = getElementOrder(element);
    const forceGroups = computeForceGroups(resolved);
    const KEYFRAME_COUNT = deriveTransformKeyframeCount(resolved);
    const keyframes = [];
    for (let index = 0; index < KEYFRAME_COUNT; index++) {
        const globalProgress = index / (KEYFRAME_COUNT - 1);
        const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, oldDuration);
        const interpScale = interpolateSubProperty(resolved.scale, globalProgress, oldDuration);
        const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, oldDuration);
        const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, oldDuration);
        keyframes.push({
            transform: buildTransformString(
                interpTranslate.x, interpTranslate.y, interpTranslate.z,
                interpScale.x, interpScale.y, interpScale.z,
                interpRotate.x, interpRotate.y, interpRotate.z,
                interpSkew.x, interpSkew.y, order, forceGroups,
                resolved.translate.unitX || 'px',
                resolved.translate.unitY || 'px',
                resolved.translate.unitZ || 'px'
            )
        });
    }

    // `delay: -oldT` advances the animation to oldT of progress at start,
    // so untouched axes resume on the same easing curve at the same point
    // the cancelled animation was sampling.
    const newAnimation = element.animate(keyframes, {
        duration: oldDuration,
        delay: -oldT,
        easing: 'linear',
        fill: 'forwards',
        iterations: 1,
        direction: 'normal'
    });

    const newVersion = (existing.version || 1) + 1;
    const entry = {
        animation: newAnimation,
        version: newVersion,
        animGroup: animGroup,
        easingKeyframes: null,
        transformProperties: transformProperties,
        resolvedValues: resolved,
        generation: existing.generation,
        propertyIndex: existing.propertyIndex
    };
    elementAnims.set('transform', entry);
    entry.updateFn = setupAnimationEvents(animGroup, 'transform', element, newAnimation, newVersion, resolved);

    return true;
}

const NON_TRANSFORM_RETARGET_AXES = {
    size: [
        { suffix: 'Width', startKey: 'startWidth', endKey: 'endWidth' },
        { suffix: 'Height', startKey: 'startHeight', endKey: 'endHeight' }
    ],
    perspectiveOrigin: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX' },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY' }
    ]
};

/**
 * Build a continuation animation for a non-transform multi-dimensional
 * property (`size`, `perspectiveOrigin`) when the retarget command
 * touches only a subset of its axes and an in-flight WAAPI animation
 * is mid-flight. Touched axes snap to the new target (start = end =
 * target so the per-axis curve is flat); untouched axes preserve the
 * in-flight animation's start / end so they continue along the
 * original easing curve. The new animation uses the same total
 * duration and starts with `delay: -oldT`, putting it at the same
 * progress where the old one was cancelled — for untouched axes this
 * is indistinguishable from the original animation continuing.
 *
 * Returns `true` when a continuation animation was built; `false` when
 * the caller should fall back to the full-snap path.
 */
function retargetNonTransformWithContinuation(animGroup, element, property, elementAnims) {
    const axes = NON_TRANSFORM_RETARGET_AXES[property.type];
    if (!axes) return false;
    if (!elementAnims) return false;

    const existing = elementAnims.get(property.type);
    if (!existing || !existing.resolvedNonTransform || !existing.animation) return false;

    const timing = existing.animation.effect?.getTiming();
    const oldDuration = timing?.duration || 0;
    if (!(oldDuration > 0)) return false;

    const oldT = existing.animation.currentTime;
    if (!Number.isFinite(oldT) || oldT < 0 || oldT >= oldDuration) return false;

    const hasAnyTouchedFlag = axes.some(
        ({ suffix }) => typeof property[`touched${suffix}`] === 'boolean'
    );
    if (!hasAnyTouchedFlag) return false;

    const hasAnyUntouched = axes.some(
        ({ suffix }) => property[`touched${suffix}`] === false
    );
    if (!hasAnyUntouched) return false;

    // Shallow clone preserves the in-flight start/end/units; mutations
    // below only overwrite touched axes.
    const resolved = { ...existing.resolvedNonTransform };

    axes.forEach(({ suffix, startKey, endKey }) => {
        if (property[`touched${suffix}`] !== true) return;
        const target = property[`end${suffix}`];
        if (!Number.isFinite(target)) return;
        resolved[startKey] = target;
        resolved[endKey] = target;
    });

    cancelSilently(elementAnims, property.type);

    const { keyframes, animationEasing } = buildPropertyKeyframes(
        resolved,
        existing.easingKeyframes || property.easingKeyframes,
        property.easing
    );
    if (!keyframes) return false;

    const newAnimation = element.animate(keyframes, {
        duration: oldDuration,
        delay: -oldT,
        easing: animationEasing,
        fill: 'forwards',
        iterations: 1,
        direction: 'normal'
    });

    const newVersion = (existing.version || 1) + 1;
    const entry = {
        animation: newAnimation,
        version: newVersion,
        animGroup: animGroup,
        easingKeyframes: existing.easingKeyframes || property.easingKeyframes || null,
        resolvedNonTransform: resolved,
        generation: existing.generation,
        propertyIndex: existing.propertyIndex
    };
    elementAnims.set(property.type, entry);
    entry.updateFn = setupAnimationEvents(animGroup, property.type, element, newAnimation, newVersion, null);

    return true;
}

function snapTransformProperties(animGroup, element, transformProperties, elementAnims) {
    // Read the live mid-flight transform BEFORE cancelling so axes the
    // build does not mention end up frozen at their actual on-screen
    // position rather than at the stale cached baseline.
    const existing = elementAnims ? elementAnims.get('transform') : null;
    const currentTransform = readLiveTransform(animGroup, element, existing);

    const cancelled = cancelSilently(elementAnims, 'transform');
    if (elementAnims) {
        cancelLegacyTransformAnimations(elementAnims);
    }

    const order = getElementOrder(element);
    const resolved = buildDefaultResolvedTransform(currentTransform);

    transformProperties.forEach(property => {
        const target = resolved[property.type];
        const axes = RESOLVED_TRANSFORM_AXES[property.type];
        if (target && axes) {
            assignResolvedTransformProperty(target, property, currentTransform, axes);
        }
    });

    const forceGroups = computeForceGroups(resolved);
    const tUx = resolved.translate.unitX || 'px';
    const tUy = resolved.translate.unitY || 'px';
    const tUz = resolved.translate.unitZ || 'px';

    element.style.transform = buildTransformString(
        resolved.translate.endX, resolved.translate.endY, resolved.translate.endZ,
        resolved.scale.endX, resolved.scale.endY, resolved.scale.endZ,
        resolved.rotate.endX, resolved.rotate.endY, resolved.rotate.endZ,
        resolved.skew.endX, resolved.skew.endY, order, forceGroups, tUx, tUy, tUz
    );

    // Update the cache so subsequent reads (animate, getTransformState)
    // see the snapped end state rather than the pre-snap current value.
    lastKnownTransforms.set(animGroup, {
        x: resolved.translate.endX, y: resolved.translate.endY, z: resolved.translate.endZ,
        scaleX: resolved.scale.endX, scaleY: resolved.scale.endY, scaleZ: resolved.scale.endZ,
        rotateX: resolved.rotate.endX, rotateY: resolved.rotate.endY, rotateZ: resolved.rotate.endZ,
        skewX: resolved.skew.endX, skewY: resolved.skew.endY,
        translateUnitX: tUx, translateUnitY: tUy, translateUnitZ: tUz
    });

    return cancelled;
}

function snapNonTransformProperty(animGroup, element, property, elementAnims) {
    const propType = (property.type === 'customProperty')
        ? `custom:${property.cssProperty}`
        : (property.type === 'customColorProperty')
            ? `customColor:${property.cssProperty}`
            : property.type;

    const cancelled = cancelSilently(elementAnims, propType);

    const resolved = resolveNonTransformValues(animGroup, element, property);
    if (!resolved) return cancelled;

    const { keyframes } = buildPropertyKeyframes(resolved, property.easingKeyframes, property.easing);
    if (!keyframes || keyframes.length === 0) return cancelled;

    applyKeyframeToInlineStyle(element, keyframes[keyframes.length - 1]);
    return cancelled;
}

/**
 * Apply a WAAPI keyframe object as inline style on the element. Skips
 * the WAAPI-internal `offset` / `easing` keys. Routes CSS custom
 * properties (those starting with `--`) through `setProperty`.
 */
function applyKeyframeToInlineStyle(element, keyframe) {
    Object.entries(keyframe).forEach(([key, value]) => {
        if (key === 'offset' || key === 'easing' || value === undefined || value === null) {
            return;
        }
        if (key.startsWith('--')) {
            element.style.setProperty(key, String(value));
        } else {
            element.style[key] = value;
        }
    });
}
