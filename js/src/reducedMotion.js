/* eslint-env browser */
/* global window */
import { reportError } from './errors.js';

/**
 * Reduced-motion policy for the compositor-driven engines (WAAPI,
 * ScrollTimeline, ViewTimeline).
 *
 * These engines drive the browser compositor directly from JS, so - unlike
 * the pure-Elm engines - they can honour the user's motion preference at the
 * point an animation is committed.
 *
 * Modes:
 *   'auto'   - follow the OS `prefers-reduced-motion: reduce` setting (default)
 *   'always' - always collapse animations to their end state
 *   'never'  - always animate, ignoring the OS setting
 *
 * When reduced motion is active, an animation is committed with a zero
 * duration (and, for scroll/view engines, with its timeline dropped) so the
 * element snaps straight to its end state. The lifecycle events Elm relies on
 * (`started`/`run` then `completed`) still fire, keeping Elm state consistent.
 */

const VALID_MODES = ['auto', 'always', 'never'];

let reducedMotionMode = 'auto';

/**
 * Set how the compositor-driven engines respond to the user's motion
 * preference. Defaults to `'auto'` (follow the OS setting).
 *
 * @param {'auto'|'always'|'never'} mode
 */
export function setReducedMotion(mode) {
    if (!VALID_MODES.includes(mode)) {
        reportError('setReducedMotion requires one of: ' + VALID_MODES.join(', '), {
            source: 'setReducedMotion',
            severity: 'warning',
            code: 'REDUCED_MOTION_MODE_INVALID',
            details: { mode: mode }
        });
        return;
    }
    reducedMotionMode = mode;
}

/**
 * Read the current reduced-motion mode.
 *
 * @returns {'auto'|'always'|'never'}
 */
export function getReducedMotion() {
    return reducedMotionMode;
}

function prefersReducedMotion() {
    if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
        return false;
    }
    try {
        return window.matchMedia('(prefers-reduced-motion: reduce)').matches === true;
    } catch (_) {
        // Hostile / partial environments (e.g. jsdom without matchMedia) —
        // treat as "no preference" rather than throwing into the animation path.
        return false;
    }
}

/**
 * Resolve whether motion should be reduced right now, combining the
 * configured mode with the live OS preference.
 *
 * @returns {boolean}
 */
export function isReducedMotionActive() {
    if (reducedMotionMode === 'always') {
        return true;
    }
    if (reducedMotionMode === 'never') {
        return false;
    }
    return prefersReducedMotion();
}

// Timeline-range keys that only make sense alongside a scroll/view timeline.
// They are dropped for the instant path so the element becomes a static,
// time-based snap to its end state instead of tracking scroll position.
const INSTANT_DROP_KEYS = ['timeline', 'rangeStart', 'rangeEnd'];

/**
 * Collapse a WAAPI timing object to an instant "snap to end" so the element
 * jumps straight to its committed end state. The end state is held via
 * `fill`, and the lifecycle events fire exactly as they would for a normal
 * finite animation.
 *
 * @param {object} timing - A WAAPI `KeyframeAnimationOptions` timing object.
 * @returns {object} A new timing object; the input is not mutated.
 */
export function toInstantTiming(timing) {
    const instant = Object.assign({}, timing);
    instant.duration = 0;
    instant.delay = 0;
    if ('endDelay' in instant) {
        instant.endDelay = 0;
    }
    // Infinite animations settle at the end of their first iteration.
    instant.iterations = 1;
    INSTANT_DROP_KEYS.forEach((key) => {
        delete instant[key];
    });
    instant.fill = instant.fill === 'both' ? 'both' : 'forwards';
    return instant;
}

/**
 * Return the timing to actually use for `element.animate`, applying the
 * instant "snap to end" transform when reduced motion is active.
 *
 * @param {object} timing - The animation's normal timing object.
 * @returns {object} The original timing, or its instant equivalent.
 */
export function applyReducedMotion(timing) {
    return isReducedMotionActive() ? toInstantTiming(timing) : timing;
}
