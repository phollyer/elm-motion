/* eslint-env browser */
/* global window, document, CSS, ScrollTimeline, ViewTimeline */
import { parseIterations, updateGroupIteration, easingFunctions, DEFAULT_TRANSFORM_ORDER } from './utils.js';
import { scrollDrivenIterationCounts, elementTransformOrders, cleanupAnimGroup, appliedWillChange } from './state.js';
import { getTransformState, buildTransformString } from './transform.js';
import { resolveNonTransformValues, buildPropertyKeyframes, resolveScrollDrivenTransformValues } from './properties.js';
import { sendScrollLifecycleEvent } from './ports.js';
import { findAnimTarget } from './targets.js';
import { reportError } from './errors.js';

// Shared load guard so multiple timeline commands do not trigger duplicate loads.
let timelinePolyfillLoadPromise = null;

/**
 * Returns true if the named timeline API is available in the current window.
 */
function hasTimelineApi(apiName) {
    return typeof window !== 'undefined' && typeof window[apiName] !== 'undefined';
}

/**
 * Lazy-load the scroll-timeline polyfill the first time it is needed.
 * Subsequent calls return the same Promise.
 *
 * The polyfill is bundled into the elm-motion distribution at build time
 * (rollup `inlineDynamicImports: true`), so the dynamic import resolves
 * synchronously from the bundle - no third-party CDN fetch, no SRI, no
 * version drift between npm dependency and runtime fetch.
 *
 * The polyfill module is a side-effect script: importing it runs an IIFE
 * that feature-detects ScrollTimeline / ViewTimeline and installs them on
 * `window` if absent.
 */
function loadTimelinePolyfill() {
    if (timelinePolyfillLoadPromise) {
        return timelinePolyfillLoadPromise;
    }

    timelinePolyfillLoadPromise = import('scroll-timeline-polyfill/dist/scroll-timeline.js')
        .then(() => undefined);

    return timelinePolyfillLoadPromise;
}

/**
 * Ensure a timeline API is available, loading the polyfill if necessary.
 * Returns true if the API is available after this call, false otherwise.
 */
export async function ensureTimelineApi(apiName) {
    if (hasTimelineApi(apiName)) {
        return true;
    }

    try {
        await loadTimelinePolyfill();
    } catch (error) {
        reportError(error, {
            source: 'polyfill',
            severity: 'warning',
            code: 'POLYFILL_LOAD_FAILED',
            engine: apiName
        });
        return false;
    }

    if (!hasTimelineApi(apiName)) {
        reportError('Timeline polyfill loaded but ' + apiName + ' is still unavailable', {
            source: 'polyfill',
            severity: 'warning',
            code: 'POLYFILL_API_MISSING',
            engine: apiName
        });
        return false;
    }

    return true;
}

/**
 * Read the current progress (0.0–1.0) of a scroll-driven Animation object.
 * Unlike time-based animations, currentTime is a CSSUnitValue, not a number.
 * getComputedTiming().progress is always a plain number in [0, 1] or null.
 */
function getScrollAnimationProgress(animation) {
    try {
        const timing = animation.effect && animation.effect.getComputedTiming();
        if (timing && timing.progress !== null && timing.progress !== undefined) {
            return Math.min(1.0, Math.max(0.0, timing.progress));
        }
    } catch (error) {
        reportError(error, {
            source: 'scroll',
            severity: 'warning',
            code: 'SCROLL_PROGRESS_READ_FAILED'
        });
    }
    return 0;
}

/**
 * Attach finish, cancel, and iteration listeners to a group of scroll-driven animations.
 * Emits port events to Elm matching the 'animationUpdate' format used by the WAAPI engine.
 */
function attachScrollDrivenListeners(animGroup, animations, engine, element, discreteExit, emitProgress) {
    const total = animations.length;
    let cancelFired = false;

    // Per-pass tracking: a scroll-driven animation can cross its end point
    // many times as the user scrolls back and forth, and the spec re-fires
    // 'finish' on every forward crossing. We dedupe the group-level
    // 'completed' event per pass and re-arm whenever any member animation
    // leaves the 'finished' playState.
    const perAnimFinished = new Array(total).fill(false);
    let passEmitted = false;

    // Initialise group iteration counter (reset on each animate call).
    scrollDrivenIterationCounts.set(animGroup, 0);

    // Per-animation iteration counts used to deduplicate the group event:
    // a group with N properties fires N native 'iteration' events per loop.
    const perAnimIterations = new Array(total).fill(0);

    function maybeEmitCompleted() {
        if (passEmitted) return;
        for (let i = 0; i < total; i++) {
            if (!perAnimFinished[i]) return;
        }
        passEmitted = true;
        if (element && discreteExit) {
            Object.entries(discreteExit).forEach(function ([prop, values]) {
                element.style[prop] = values.to;
            });
        }
        sendScrollLifecycleEvent('completed', animGroup, 1.0, engine);
    }

    // Synthetic 'started' watcher: scroll/view timelines have no native play
    // event, so we poll the representative animation's computed progress once
    // per frame. A 'started' event fires each time progress transitions from
    // null/0 (out of range) to > 0 (in range). The same tick also re-arms the
    // per-pass 'completed' flag when any animation leaves the 'finished'
    // state, so a subsequent forward crossing of the end emits another
    // 'completed'. When emitProgress is true, the loop also forwards every
    // in-range progress sample.
    //
    // The RAF handle is captured so 'cancel' (and an element-detached guard)
    // can stop the loop deterministically; otherwise the closure retains
    // `element`, `animations`, and `discreteExit` for the lifetime of the
    // page, even after the host element is unmounted from the DOM.
    let rafId = null;
    if (animations.length > 0 && typeof window !== 'undefined' && typeof window.requestAnimationFrame === 'function') {
        const representative = animations[0];
        let inRange = false;
        const tick = function () {
            if (cancelFired) {
                rafId = null;
                return;
            }
            // Element detached without an explicit cancel - stop polling and
            // release the closure so the GC can reclaim it.
            if (element && typeof element.isConnected === 'boolean' && !element.isConnected) {
                cancelFired = true;
                rafId = null;
                cleanupAnimGroup(animGroup);
                return;
            }
            for (let i = 0; i < total; i++) {
                if (perAnimFinished[i] && animations[i].playState !== 'finished') {
                    perAnimFinished[i] = false;
                    passEmitted = false;
                }
            }
            const progress = getScrollAnimationProgress(representative);
            if (!inRange && progress > 0) {
                inRange = true;
                sendScrollLifecycleEvent('started', animGroup, progress, engine);
            } else if (inRange && progress <= 0) {
                inRange = false;
            }
            if (emitProgress && inRange) {
                sendScrollLifecycleEvent('progress', animGroup, progress, engine);
            }
            rafId = window.requestAnimationFrame(tick);
        };
        rafId = window.requestAnimationFrame(tick);
    }

    animations.forEach(function (animation, i) {
        animation.addEventListener('finish', function () {
            perAnimFinished[i] = true;
            maybeEmitCompleted();
        });

        animation.addEventListener('cancel', function () {
            if (cancelFired) return;
            cancelFired = true;
            if (rafId !== null && typeof window !== 'undefined' && typeof window.cancelAnimationFrame === 'function') {
                window.cancelAnimationFrame(rafId);
                rafId = null;
            }
            const progress = getScrollAnimationProgress(animation);
            sendScrollLifecycleEvent('cancelled', animGroup, progress, engine);
            cleanupAnimGroup(animGroup);
        }, { once: true });

        animation.addEventListener('iteration', function () {
            perAnimIterations[i]++;
            const storedCount = scrollDrivenIterationCounts.get(animGroup) || 0;
            const nextGroupIteration = updateGroupIteration(perAnimIterations, i, perAnimIterations[i], storedCount);
            if (nextGroupIteration != null) {
                scrollDrivenIterationCounts.set(animGroup, nextGroupIteration);
                sendScrollLifecycleEvent('iteration', animGroup, nextGroupIteration, engine);
            }
        });
    });
}

/**
 * Apply a scroll/view-driven animation to a single element using the given timeline.
 * Builds start/end keyframes from each property config and calls element.animate().
 */
function applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, engine, discreteEntry, discreteExit, emitProgress) {
    // Apply discrete entry styles immediately so the element is in the correct
    // state when the animation begins.
    if (discreteEntry) {
        Object.entries(discreteEntry).forEach(function ([prop, value]) {
            element.style[prop] = value;
        });
    }

    // Scroll-driven animations are continuous for the lifetime of the scroll
    // interaction, so the GPU hint is seeded once at start and intentionally
    // never cleared (no `cleanupAnimGroup` runs for these engines).
    if (elementConfig.willChange && typeof elementConfig.willChange === 'string') {
        try {
            element.style.willChange = elementConfig.willChange;
            appliedWillChange.set(animGroup, { element: element, value: elementConfig.willChange });
        } catch (_) {
            // Non-fatal.
        }
    }
    const baseTimingOptions = Object.assign(
        { timeline: timeline, fill: 'both' },
        rangeOptions || {},
        playbackOptions ? { iterations: playbackOptions.iterations, direction: playbackOptions.direction } : {}
    );
    const properties = elementConfig.properties || [];

    const transformProperties = properties.filter(p =>
        p.type === 'translate' || p.type === 'scale' || p.type === 'rotate' || p.type === 'skew'
    );
    const nonTransformProperties = properties.filter(p =>
        p.type !== 'translate' && p.type !== 'scale' && p.type !== 'rotate' && p.type !== 'skew'
    );

    const animations = [];

    nonTransformProperties.forEach(function (property) {
        const resolved = resolveNonTransformValues(animGroup, element, property);
        if (!resolved) return;

        const { keyframes, animationEasing } = buildPropertyKeyframes(resolved, property.easingKeyframes, property.easing);
        if (!keyframes) return;

        const propertyTimingOptions = Object.assign({}, baseTimingOptions, { easing: animationEasing });
        animations.push(element.animate(keyframes, propertyTimingOptions));
    });

    if (transformProperties.length > 0) {
        const currentTransform = getTransformState(animGroup, element);
        const order = (elementConfig.transformOrder && elementConfig.transformOrder.length > 0)
            ? elementConfig.transformOrder
            : (elementTransformOrders.get(animGroup) || DEFAULT_TRANSFORM_ORDER);

        const { start: sv, end: ev } = resolveScrollDrivenTransformValues(transformProperties, currentTransform);

        // Force every keyframe to list the same set of transform functions
        // so WAAPI uses per-function interpolation instead of decomposing
        // to matrix3d (which silently drops rotation when an endpoint
        // produces an identity rotation matrix). See animations.js
        // computeForceGroups for the same logic on time-driven animations.
        const forceGroups = new Set();
        if (sv.x !== 0 || sv.y !== 0 || sv.z !== 0 || ev.x !== 0 || ev.y !== 0 || ev.z !== 0) {
            forceGroups.add('translate');
        }
        if (sv.scaleX !== 1 || sv.scaleY !== 1 || sv.scaleZ !== 1 || ev.scaleX !== 1 || ev.scaleY !== 1 || ev.scaleZ !== 1) {
            forceGroups.add('scale');
        }
        if (sv.rotateX !== 0 || sv.rotateY !== 0 || sv.rotateZ !== 0 || ev.rotateX !== 0 || ev.rotateY !== 0 || ev.rotateZ !== 0) {
            forceGroups.add('rotate');
        }
        if (sv.skewX !== 0 || sv.skewY !== 0 || ev.skewX !== 0 || ev.skewY !== 0) {
            forceGroups.add('skew');
        }

        const transformTimingOptions = Object.assign({}, baseTimingOptions);
        const firstTransform = transformProperties[0];

        let transformKeyframes;
        if (firstTransform.easingKeyframes && Array.isArray(firstTransform.easingKeyframes)) {
            transformKeyframes = firstTransform.easingKeyframes.map(function (sample) {
                const offset = sample.offset;
                const p = sample.value;
                return {
                    offset: offset,
                    transform: buildTransformString(
                        sv.x + (ev.x - sv.x) * p,
                        sv.y + (ev.y - sv.y) * p,
                        sv.z + (ev.z - sv.z) * p,
                        sv.scaleX + (ev.scaleX - sv.scaleX) * p,
                        sv.scaleY + (ev.scaleY - sv.scaleY) * p,
                        sv.scaleZ + (ev.scaleZ - sv.scaleZ) * p,
                        sv.rotateX + (ev.rotateX - sv.rotateX) * p,
                        sv.rotateY + (ev.rotateY - sv.rotateY) * p,
                        sv.rotateZ + (ev.rotateZ - sv.rotateZ) * p,
                        sv.skewX + (ev.skewX - sv.skewX) * p,
                        sv.skewY + (ev.skewY - sv.skewY) * p,
                        order, forceGroups,
                        ev.translateUnitX || sv.translateUnitX || 'px',
                        ev.translateUnitY || sv.translateUnitY || 'px',
                        ev.translateUnitZ || sv.translateUnitZ || 'px'
                    )
                };
            });
            transformTimingOptions.easing = 'linear';
        } else {
            const startTransform = buildTransformString(
                sv.x, sv.y, sv.z,
                sv.scaleX, sv.scaleY, sv.scaleZ,
                sv.rotateX, sv.rotateY, sv.rotateZ,
                sv.skewX, sv.skewY, order, forceGroups,
                sv.translateUnitX || 'px',
                sv.translateUnitY || 'px',
                sv.translateUnitZ || 'px'
            );
            const endTransform = buildTransformString(
                ev.x, ev.y, ev.z,
                ev.scaleX, ev.scaleY, ev.scaleZ,
                ev.rotateX, ev.rotateY, ev.rotateZ,
                ev.skewX, ev.skewY, order, forceGroups,
                ev.translateUnitX || 'px',
                ev.translateUnitY || 'px',
                ev.translateUnitZ || 'px'
            );
            transformKeyframes = [{ transform: startTransform }, { transform: endTransform }];
            if (firstTransform.easing) {
                transformTimingOptions.easing = easingFunctions[firstTransform.easing] || firstTransform.easing;
            }
        }

        animations.push(element.animate(transformKeyframes, transformTimingOptions));
    }

    if (animations.length > 0 && engine) {
        attachScrollDrivenListeners(animGroup, animations, engine, element, discreteExit || {}, !!emitProgress);
    }
}

/**
 * Build the {playbackOptions, discreteEntry, discreteExit} bundle shared by
 * both scroll-driven and view-driven processing.
 */
function buildSharedTimelineOptions(commandData) {
    return {
        playbackOptions: {
            iterations: parseIterations(commandData.iterations),
            direction: commandData.direction || 'normal'
        },
        discreteEntry: commandData.discreteEntry || {},
        discreteExit: commandData.discreteExit || {},
        defaultEmitProgress: !!commandData.emitProgress
    };
}

/**
 * Build the rangeOptions object for a ViewTimeline from its config.
 * Per-element overrides win over the timeline defaults.
 */
function buildViewRangeOptions(timelineConfig, elementConfig) {
    const rangeOptions = {};
    if (timelineConfig.rangeStart) rangeOptions.rangeStart = timelineConfig.rangeStart;
    if (timelineConfig.rangeEnd) rangeOptions.rangeEnd = timelineConfig.rangeEnd;
    if (elementConfig && elementConfig.rangeStart) rangeOptions.rangeStart = elementConfig.rangeStart;
    if (elementConfig && elementConfig.rangeEnd) rangeOptions.rangeEnd = elementConfig.rangeEnd;
    return rangeOptions;
}

/**
 * Validate that a timeline command has the expected shape and that the
 * required browser API is present. Reports the appropriate error and
 * returns false on failure.
 */
function validateTimelineCommand(commandData, source, engine, apiPresent) {
    if (!commandData || !commandData.elements) {
        reportError('Invalid ' + source + ' data', {
            source: source,
            severity: 'warning',
            code: 'COMMAND_INVALID',
            engine: engine
        });
        return false;
    }
    if (!apiPresent) {
        reportError(engine + ' is not supported in this browser', {
            source: source,
            severity: 'warning',
            code: 'API_UNSUPPORTED',
            engine: engine
        });
        return false;
    }
    return true;
}

/**
 * Resolve the scroll-source element from a timelineConfig.source id.
 * Returns null and reports an error if not found.
 */
function resolveScrollSource(sourceId) {
    if (sourceId === 'document') {
        return document.documentElement;
    }
    const element = document.querySelector('[data-anim-target="' + CSS.escape(sourceId) + '"]')
        || document.getElementById(sourceId);
    if (!element) {
        reportError('Scroll source element "' + sourceId + '" not found', {
            source: 'scrollDriven',
            severity: 'warning',
            code: 'SCROLL_SOURCE_NOT_FOUND',
            engine: 'ScrollTimeline',
            details: { sourceId: sourceId }
        });
    }
    return element;
}

/**
 * Resolve a per-element animation target. Returns null and reports an error
 * if the target cannot be found.
 */
function resolveTimelineTarget(targetId, animGroup, source, engine) {
    const element = findAnimTarget(targetId);
    if (!element) {
        reportError('Element target "' + targetId + '" not found for ' + source + ' animation', {
            source: source,
            severity: 'warning',
            code: 'TARGET_NOT_FOUND',
            engine: engine,
            elementId: targetId,
            details: { animGroup: animGroup }
        });
    }
    return element;
}

/**
 * Process a scroll-driven animation using ScrollTimeline.
 */
export function processScrollDrivenData(commandData) {
    if (!validateTimelineCommand(commandData, 'scrollDriven', 'ScrollTimeline', typeof ScrollTimeline !== 'undefined')) {
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const sourceId = timelineConfig.source || 'document';
    const axis = timelineConfig.axis || 'block';

    const sourceElement = resolveScrollSource(sourceId);
    if (!sourceElement) {
        return;
    }

    const timeline = new ScrollTimeline({ source: sourceElement, axis: axis });
    const { playbackOptions, discreteEntry, discreteExit, defaultEmitProgress } = buildSharedTimelineOptions(commandData);

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const targetId = elementConfig.target || animGroup;
        const element = resolveTimelineTarget(targetId, animGroup, 'scrollDriven', 'ScrollTimeline');
        if (!element) return;
        const emitProgress =
            typeof elementConfig.emitProgress === 'boolean'
                ? elementConfig.emitProgress
                : defaultEmitProgress;
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, null, playbackOptions, 'scrollTimeline', discreteEntry, discreteExit, emitProgress);
    });
}

/**
 * Apply a view-driven animation to a single element entry.
 */
function applyViewDrivenForEntry(animGroup, elementConfig, axis, rangeOptions, playbackOptions, discreteEntry, discreteExit, emitProgress) {
    const targetId = elementConfig.target || animGroup;
    const element = resolveTimelineTarget(targetId, animGroup, 'viewDriven', 'ViewTimeline');
    if (!element) return;

    const timeline = new ViewTimeline({ subject: element, axis: axis });
    applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, 'viewTimeline', discreteEntry, discreteExit, emitProgress);
}

/**
 * Process a view-driven animation using ViewTimeline.
 */
export function processViewDrivenData(commandData) {
    if (!validateTimelineCommand(commandData, 'viewDriven', 'ViewTimeline', typeof ViewTimeline !== 'undefined')) {
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const axis = timelineConfig.axis || 'block';
    const { playbackOptions, discreteEntry, discreteExit, defaultEmitProgress } = buildSharedTimelineOptions(commandData);

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const emitProgress =
            typeof elementConfig.emitProgress === 'boolean'
                ? elementConfig.emitProgress
                : defaultEmitProgress;
        const rangeOptions = buildViewRangeOptions(timelineConfig, elementConfig);
        applyViewDrivenForEntry(animGroup, elementConfig, axis, rangeOptions, playbackOptions, discreteEntry, discreteExit, emitProgress);
    });
}
