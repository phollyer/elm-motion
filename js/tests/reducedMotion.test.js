/* eslint-env node */
/* global global */
import { afterEach, describe, expect, it, vi } from 'vitest';
import {
    setReducedMotion,
    getReducedMotion,
    isReducedMotionActive,
    toInstantTiming,
    applyReducedMotion
} from '../src/reducedMotion.js';
import { processAnimationData } from '../src/animations.js';
import { processScrollDrivenData, processViewDrivenData } from '../src/scroll.js';
import ElmMotion from '../src/index.js';
import {
    activeAnimations,
    animationGroups,
    elementTransformOrders,
    lastKnownTransforms,
    appliedWillChange
} from '../src/state.js';
import { onError, _resetSubscribers } from '../src/errors.js';
import { createFakeAnimation, installDom, createPorts, cleanupDom } from './_publicApiHelpers.js';

function makeElement(animGroup) {
    return {
        id: animGroup,
        animate: vi.fn(() => createFakeAnimation()),
        style: { transform: '' },
        getAnimations: () => [],
        getAttribute(name) {
            if (name === 'data-anim-target') return animGroup;
            return null;
        }
    };
}

function clearGlobalState() {
    activeAnimations.clear();
    animationGroups.clear();
    elementTransformOrders.clear();
    lastKnownTransforms.clear();
    appliedWillChange.clear();
}

afterEach(() => {
    // Reduced-motion mode is a module-level singleton shared across the whole
    // companion; restore the default so tests do not leak state into one another.
    setReducedMotion('auto');
    cleanupDom();
    clearGlobalState();
    _resetSubscribers();
});

describe('reducedMotion mode configuration', () => {
    it('defaults to auto', () => {
        expect(getReducedMotion()).toBe('auto');
    });

    it('accepts the three valid modes', () => {
        setReducedMotion('always');
        expect(getReducedMotion()).toBe('always');
        setReducedMotion('never');
        expect(getReducedMotion()).toBe('never');
        setReducedMotion('auto');
        expect(getReducedMotion()).toBe('auto');
    });

    it('reports an error and leaves the mode unchanged for an invalid value', () => {
        setReducedMotion('always');
        const errorSpy = vi.fn();
        const off = onError(errorSpy);

        setReducedMotion('sometimes');

        expect(getReducedMotion()).toBe('always');
        expect(errorSpy).toHaveBeenCalledTimes(1);
        expect(errorSpy.mock.calls[0][1]).toMatchObject({
            source: 'setReducedMotion',
            severity: 'warning',
            code: 'REDUCED_MOTION_MODE_INVALID'
        });
        off();
    });
});

describe('isReducedMotionActive', () => {
    it('is true for "always" regardless of the OS preference', () => {
        setReducedMotion('always');
        expect(isReducedMotionActive()).toBe(true);
    });

    it('is false for "never" even when the OS prefers reduced motion', () => {
        global.window = { matchMedia: () => ({ matches: true }) };
        setReducedMotion('never');
        expect(isReducedMotionActive()).toBe(false);
    });

    it('follows the OS preference under "auto"', () => {
        global.window = { matchMedia: vi.fn(() => ({ matches: true })) };
        setReducedMotion('auto');
        expect(isReducedMotionActive()).toBe(true);
        expect(global.window.matchMedia).toHaveBeenCalledWith('(prefers-reduced-motion: reduce)');

        global.window.matchMedia = () => ({ matches: false });
        expect(isReducedMotionActive()).toBe(false);
    });

    it('is false under "auto" when matchMedia is unavailable', () => {
        global.window = {};
        setReducedMotion('auto');
        expect(isReducedMotionActive()).toBe(false);
    });

    it('is false under "auto" when matchMedia throws', () => {
        global.window = { matchMedia: () => { throw new Error('nope'); } };
        setReducedMotion('auto');
        expect(isReducedMotionActive()).toBe(false);
    });
});

describe('toInstantTiming', () => {
    it('collapses duration, delay and iterations and holds the end state', () => {
        const instant = toInstantTiming({
            duration: 500,
            delay: 100,
            endDelay: 20,
            easing: 'ease',
            fill: 'forwards',
            iterations: Infinity,
            direction: 'normal'
        });

        expect(instant.duration).toBe(0);
        expect(instant.delay).toBe(0);
        expect(instant.endDelay).toBe(0);
        expect(instant.iterations).toBe(1);
        expect(instant.fill).toBe('forwards');
        // Untouched fields are preserved.
        expect(instant.easing).toBe('ease');
        expect(instant.direction).toBe('normal');
    });

    it('drops timeline and range options so scroll/view animations become a static snap', () => {
        const instant = toInstantTiming({
            duration: 500,
            timeline: { fake: true },
            rangeStart: 'cover 0%',
            rangeEnd: 'cover 100%',
            fill: 'both'
        });

        expect('timeline' in instant).toBe(false);
        expect('rangeStart' in instant).toBe(false);
        expect('rangeEnd' in instant).toBe(false);
        // A `both` fill is preserved (scroll/view engines use it).
        expect(instant.fill).toBe('both');
    });

    it('does not mutate the input timing', () => {
        const input = { duration: 500, delay: 100, timeline: {} };
        toInstantTiming(input);
        expect(input.duration).toBe(500);
        expect(input.delay).toBe(100);
        expect('timeline' in input).toBe(true);
    });
});

describe('applyReducedMotion', () => {
    it('returns the original timing untouched when reduced motion is inactive', () => {
        setReducedMotion('never');
        const timing = { duration: 500 };
        expect(applyReducedMotion(timing)).toBe(timing);
    });

    it('returns an instant timing when reduced motion is active', () => {
        setReducedMotion('always');
        const result = applyReducedMotion({ duration: 500, delay: 100 });
        expect(result.duration).toBe(0);
        expect(result.delay).toBe(0);
    });
});

describe('reduced motion — WAAPI engine integration', () => {
    it('animates normally (full duration) when reduced motion is off', () => {
        setReducedMotion('never');
        const animGroup = 'box-rm-off';
        const element = makeElement(animGroup);
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'translate',
                        startX: 0, startY: 0, startZ: 0,
                        endX: 100, endY: 0, endZ: 0,
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [, options] = element.animate.mock.calls[0];
        expect(options.duration).toBe(300);
    });

    it('snaps transform animations to their end state when reduced motion is on', () => {
        setReducedMotion('always');
        const animGroup = 'box-rm-transform';
        const element = makeElement(animGroup);
        installDom({ element, targetId: animGroup });

        processAnimationData({
            iterations: 'infinite',
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'translate',
                        startX: 0, startY: 0, startZ: 0,
                        endX: 100, endY: 0, endZ: 0,
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [keyframes, options] = element.animate.mock.calls[0];
        expect(options.duration).toBe(0);
        expect(options.iterations).toBe(1);
        // The end keyframe still targets the authored destination.
        expect(keyframes[keyframes.length - 1].transform).toContain('translate3d(100px, 0px, 0px)');
    });

    it('snaps non-transform (opacity) animations to their end state when reduced motion is on', () => {
        setReducedMotion('always');
        const animGroup = 'box-rm-opacity';
        const element = makeElement(animGroup);
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'opacity', startValue: 0, endValue: 1,
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [, options] = element.animate.mock.calls[0];
        expect(options.duration).toBe(0);
        expect(options.iterations).toBe(1);
    });

    it('still fires started and completed lifecycle events under reduced motion', async () => {
        setReducedMotion('always');
        const animGroup = 'box-rm-lifecycle';
        const animation = createFakeAnimation({ duration: 300 });
        const element = { id: animGroup, animate: vi.fn(() => animation) };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        // A duration-0 animation finishes immediately in a real browser; the
        // fake animation exposes finish() to drive the same code path.
        animation.finish();

        const statuses = events
            .filter((event) => event.type === 'animationUpdate')
            .map((event) => event.payload?.status);

        expect(statuses).toContain('started');
        expect(statuses).toContain('completed');
    });
});

describe('reduced motion — scroll/view engine integration', () => {
    it('keeps the scroll timeline and full duration when reduced motion is off', () => {
        setReducedMotion('never');
        global.ScrollTimeline = class { constructor(opts) { this.opts = opts; } };
        const animGroup = 'box';
        const element = makeElement(animGroup);
        installDom({ element, targetId: animGroup });

        processScrollDrivenData({
            timeline: { source: 'document', axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'opacity', startValue: 0, endValue: 1,
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [, options] = element.animate.mock.calls[0];
        expect(options.timeline).toBeDefined();
        expect(options.duration).toBeUndefined();
    });

    it('pins scroll-driven animations to their end value when reduced motion is on', () => {
        setReducedMotion('always');
        global.ScrollTimeline = class { constructor(opts) { this.opts = opts; } };
        const animGroup = 'box';
        const element = makeElement(animGroup);
        installDom({ element, targetId: animGroup });

        processScrollDrivenData({
            timeline: { source: 'document', axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'opacity', startValue: 0, endValue: 1,
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [, options] = element.animate.mock.calls[0];
        expect('timeline' in options).toBe(false);
        expect(options.duration).toBe(0);
    });

    it('pins view-driven animations to their end value when reduced motion is on', () => {
        setReducedMotion('always');
        global.ViewTimeline = class { constructor(opts) { this.opts = opts; } };
        const animGroup = 'box';
        const element = makeElement(animGroup);
        installDom({ element, targetId: animGroup });

        processViewDrivenData({
            timeline: { axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'opacity', startValue: 0, endValue: 1,
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [, options] = element.animate.mock.calls[0];
        expect('timeline' in options).toBe(false);
        expect(options.duration).toBe(0);
    });
});
