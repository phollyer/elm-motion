/* eslint-env node */
/* global global */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { processAnimationData, processElementAnimation, retargetAnimation } from '../src/animations.js';
import { activeAnimations, animationGroups, elementTransformOrders, lastKnownTransforms, appliedWillChange, cleanupAnimGroup } from '../src/state.js';
import { onError, _resetSubscribers } from '../src/errors.js';
import { createFakeAnimation, installDom, cleanupDom } from './_publicApiHelpers.js';

function makeElement({ animGroup, animations = [createFakeAnimation()], order = null }) {
    const animateMock = vi.fn(() => animations.shift() || createFakeAnimation());
    return {
        id: animGroup,
        animate: animateMock,
        style: { transform: '' },
        getAnimations: () => [],
        getAttribute(name) {
            if (name === 'data-anim-target') return animGroup;
            if (name === 'data-elm-motion-order' && order) return order;
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

beforeEach(clearGlobalState);
afterEach(() => {
    cleanupDom();
    clearGlobalState();
    _resetSubscribers();
});

describe('processAnimationData (WAAPI engine)', () => {
    it('reports COMMAND_INVALID when animationData is missing or has no elements', () => {
        installDom({ element: makeElement({ animGroup: 'x' }), targetId: 'x' });
        const errorSpy = vi.fn();
        const off = onError(errorSpy);

        // Both branches: null and missing elements
        expect(() => processAnimationData(null)).not.toThrow();
        expect(() => processAnimationData({})).not.toThrow();

        expect(errorSpy).toHaveBeenCalledTimes(2);
        expect(errorSpy.mock.calls[0][1]).toMatchObject({
            source: 'animation',
            severity: 'warning',
            code: 'COMMAND_INVALID'
        });
        expect(errorSpy.mock.calls[1][1]).toMatchObject({
            source: 'animation',
            severity: 'warning',
            code: 'COMMAND_INVALID'
        });
        off();
    });

    it('reports TARGET_NOT_FOUND when no element matches the animGroup', () => {
        installDom({ element: null, targetId: 'absent' });
        const errorSpy = vi.fn();
        const off = onError(errorSpy);

        // querySelector returns null for any other selector → triggers reportError
        expect(() => processAnimationData({
            elements: {
                'missing-group': {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 100, easing: 'linear', version: 1 }
                    ]
                }
            }
        })).not.toThrow();

        expect(errorSpy).toHaveBeenCalledTimes(1);
        expect(errorSpy.mock.calls[0][1]).toMatchObject({
            source: 'animation',
            severity: 'warning',
            code: 'TARGET_NOT_FOUND'
        });
        off();
    });

    it('animates a single transform property (translate)', () => {
        const animGroup = 'box-translate';
        const animation = createFakeAnimation({ duration: 300 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'translate',
                        startX: 0, startY: 0, startZ: 0,
                        endX: 100, endY: 50, endZ: 0,
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        expect(element.animate).toHaveBeenCalledTimes(1);
        const [keyframes, options] = element.animate.mock.calls[0];
        expect(keyframes[0].transform).toContain('translate3d(0px, 0px, 0px)');
        expect(keyframes[keyframes.length - 1].transform).toContain('translate3d(100px, 50px, 0px)');
        expect(options.duration).toBe(300);
        const elementAnims = activeAnimations.get(animGroup);
        expect(elementAnims.has('transform')).toBe(true);
    });

    it('anchors a fresh transform start to the cached resting place, not the stale command start', () => {
        // Regression: after a previous animation settles, `cleanupAnimGroup`
        // removes the live entry so the next command takes the fresh path and
        // its start comes from Elm's `runtimeBaseline`. That baseline can
        // diverge from where the element actually rests (most visibly after a
        // frozen-axis animation), producing a first-frame snap. The JS-owned
        // `lastKnownTransforms` is the authoritative rest and must win.
        const animGroup = 'box-resettle';
        const animation = createFakeAnimation({ duration: 300 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        // Authoritative resting place committed by the prior (settled) anim.
        lastKnownTransforms.set(animGroup, {
            x: 67, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0,
            translateUnitX: 'cqw', translateUnitY: 'cqh', translateUnitZ: 'px'
        });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'translate',
                        // Stale baseline from Elm: X start trails the rest by
                        // 2cqw and a frozen Y carries a stale 1cqh target.
                        startX: 65, startY: 1, startZ: 0,
                        endX: 0, endY: 1, endZ: 0,
                        unitX: 'cqw', unitY: 'cqh', unitZ: 'px',
                        frozenAxes: ['y'],
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [keyframes] = element.animate.mock.calls[0];
        // X starts from the cached rest (67cqw), not the stale 65cqw.
        expect(keyframes[0].transform).toContain('translate3d(67cqw, 0cqh, 0px)');
        // Frozen Y is pinned to the rest (0cqh) at both ends, not Elm's 1cqh.
        expect(keyframes[keyframes.length - 1].transform).toContain('translate3d(0cqw, 0cqh, 0px)');
    });

    it('leaves the command start intact when units differ from the cached rest', () => {
        // Unit-safety guard: re-anchoring a px-authored animation to a cqw
        // cached value would reinterpret the number under the wrong unit.
        const animGroup = 'box-unit-mismatch';
        const animation = createFakeAnimation({ duration: 300 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        lastKnownTransforms.set(animGroup, {
            x: 67, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0,
            translateUnitX: 'cqw', translateUnitY: 'cqh', translateUnitZ: 'px'
        });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'translate',
                        startX: 120, startY: 0, startZ: 0,
                        endX: 0, endY: 0, endZ: 0,
                        unitX: 'px', unitY: 'px', unitZ: 'px',
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [keyframes] = element.animate.mock.calls[0];
        // px start is preserved because the cached rest is in cqw.
        expect(keyframes[0].transform).toContain('translate3d(120px, 0px, 0px)');
    });

    it('anchors mid-flight retarget starts to live translate position', () => {
        // Regression: when retargeting during an active animation, timeline-
        // derived progress can be slightly behind the compositor. Starting the
        // next animation from that stale value causes a visible snap backward.
        const animGroup = 'box-midflight-live';
        const firstAnimation = createFakeAnimation({ duration: 1000 });
        const secondAnimation = createFakeAnimation({ duration: 1000 });
        firstAnimation.currentTime = 500;
        firstAnimation.playState = 'running';

        const element = makeElement({ animGroup, animations: [firstAnimation, secondAnimation] });
        element.getAnimations = () => [firstAnimation];
        installDom({ element, targetId: animGroup });

        // Report a live compositor position ahead of timeline interpolation.
        global.window.getComputedStyle = vi.fn(() => ({
            transform: 'matrix(1, 0, 0, 1, 60, 0)',
            containerType: 'normal',
            getPropertyValue() {
                return '';
            }
        }));

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'translate',
                        startX: 0, startY: 0, startZ: 0,
                        endX: 100, endY: 0, endZ: 0,
                        unitX: 'px', unitY: 'px', unitZ: 'px',
                        duration: 1000, easing: 'linear', version: 1
                    }]
                }
            }
        });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'translate',
                        // Elm-side baseline trails the actual live value.
                        startX: 48, startY: 0, startZ: 0,
                        endX: 0, endY: 0, endZ: 0,
                        unitX: 'px', unitY: 'px', unitZ: 'px',
                        duration: 1000, easing: 'linear', version: 2
                    }]
                }
            }
        });

        const [retargetedKeyframes] = element.animate.mock.calls[1];
        expect(retargetedKeyframes[0].transform).toContain('translate3d(60px, 0px, 0px)');
    });

    it('animates mixed transform and non-transform properties in one command', () => {
        const animGroup = 'box-mixed';
        const transformAnim = createFakeAnimation({ duration: 300 });
        const opacityAnim = createFakeAnimation({ duration: 300 });
        const element = makeElement({ animGroup, animations: [transformAnim, opacityAnim] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 1
                        },
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(element.animate).toHaveBeenCalledTimes(2);
        const elementAnims = activeAnimations.get(animGroup);
        expect(elementAnims.has('transform')).toBe(true);
        expect(elementAnims.has('opacity')).toBe(true);
    });

    it('merges multiple transform types into a single animation when easing/duration match', () => {
        const animGroup = 'box-merged';
        const animation = createFakeAnimation({ duration: 400 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 50, endY: 0, endZ: 0,
                            duration: 400, easing: 'linear', version: 1
                        },
                        {
                            type: 'rotate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 90,
                            duration: 400, easing: 'linear', version: 1
                        },
                        {
                            type: 'scale',
                            startX: 1, startY: 1, startZ: 1,
                            endX: 2, endY: 2, endZ: 1,
                            duration: 400, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        // Single merged animation (same duration + same easing branch)
        expect(element.animate).toHaveBeenCalledTimes(1);
        const [keyframes, options] = element.animate.mock.calls[0];
        expect(keyframes).toHaveLength(2);
        expect(options.duration).toBe(400);
        expect(options.easing).toBe('linear');
    });

    it('falls back to keyframe interpolation when transform sub-properties have different durations', () => {
        const animGroup = 'box-keyframe';
        const animation = createFakeAnimation({ duration: 600 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 1
                        },
                        {
                            type: 'rotate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 180,
                            duration: 600, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        const [keyframes, options] = element.animate.mock.calls[0];
        // Keyframe interpolation path uses fallback sampling density.
        expect(keyframes.length).toBe(30);
        expect(options.duration).toBe(600);
        expect(options.easing).toBe('linear');
    });

    it('uses complex easing keyframe density for transform interpolation', () => {
        const animGroup = 'box-bounce-density';
        const animation = createFakeAnimation({ duration: 600 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 600,
                            easing: 'linear',
                            easingKeyframes: Array.from({ length: 60 }, (_, i) => {
                                const offset = i / 59;
                                return { offset, value: offset };
                            }),
                            version: 1
                        },
                        {
                            type: 'rotate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 180,
                            duration: 600,
                            easing: 'linear',
                            version: 1
                        }
                    ]
                }
            }
        });

        const [keyframes, options] = element.animate.mock.calls[0];
        expect(keyframes.length).toBe(60);
        expect(options.duration).toBe(600);
        expect(options.easing).toBe('linear');
    });

    it('cancels and restarts a transform animation, carrying forward retained sub-properties', () => {
        const animGroup = 'box-restart';
        const firstAnim = createFakeAnimation({ duration: 300 });
        firstAnim.currentTime = 150;
        firstAnim.playState = 'running';
        const secondAnim = createFakeAnimation({ duration: 300 });

        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        installDom({ element, targetId: animGroup });

        // First: translate + rotate
        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 1
                        },
                        {
                            type: 'rotate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 90,
                            duration: 300, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        // Second: only translate — rotate should be carried forward
        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 50, startY: 0, startZ: 0,
                            endX: 200, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 2
                        }
                    ]
                }
            }
        });

        expect(firstAnim.cancelCalls).toBe(1);
        expect(element.animate).toHaveBeenCalledTimes(2);
    });

    // When `animate` lands for one transform sub-property (translate) while
    // a DIFFERENT sub-property (rotate) is mid-flight as part of the same
    // merged transform animation, the untouched axis must continue toward
    // its ORIGINAL target on its own remaining timeline. It must not freeze
    // at the snapshot value. See `buildRetainedTransformProperty` and
    // `carryForwardMissingTransformProperties` for the implementation.
    it('continues an untouched in-flight transform sub-property toward its original target', () => {
        const animGroup = 'box-cross-subprop';
        const firstAnim = createFakeAnimation({ duration: 300 });
        const secondAnim = createFakeAnimation({ duration: 300 });
        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        installDom({ element, targetId: animGroup });

        // First: translate 0→100px and rotate 0→90deg, merged into one anim.
        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 1
                        },
                        {
                            type: 'rotate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 90,
                            duration: 300, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        // Advance the merged animation to 50% (rotate at ~45deg of its 0→90
        // path, with 150ms of remaining time on its own timeline).
        firstAnim.currentTime = 150;
        firstAnim.playState = 'running';

        // Second: animate ONLY translate. Rotate is untouched and must
        // continue toward its original 90deg target over its remaining
        // 150ms, NOT freeze at 45deg for the duration of the new animation.
        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 50, startY: 0, startZ: 0,
                            endX: 200, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 2
                        }
                    ]
                }
            }
        });

        expect(element.animate).toHaveBeenCalledTimes(2);

        const secondKeyframes = element.animate.mock.calls[1][0];
        expect(Array.isArray(secondKeyframes)).toBe(true);
        expect(secondKeyframes.length).toBeGreaterThanOrEqual(2);

        const extractRotateZ = (transformString) => {
            const match = /rotateZ\(([-\d.]+)deg\)/.exec(transformString || '');
            return match ? parseFloat(match[1]) : 0;
        };

        const startRotateZ = extractRotateZ(secondKeyframes[0].transform);
        const endRotateZ = extractRotateZ(secondKeyframes[secondKeyframes.length - 1].transform);

        // First keyframe: rotate starts from its current mid-flight value.
        expect(startRotateZ).toBeCloseTo(45, 1);
        // Last keyframe: rotate has reached its original 90deg target (and
        // holds there for the remainder of the new translate animation).
        expect(endRotateZ).toBeCloseTo(90, 1);
    });

    it('anchors frozen translate axes to live DOM transform over stale command starts', () => {
        const animGroup = 'box-frozen-live-anchor';
        const firstAnim = createFakeAnimation({ duration: 300 });
        firstAnim.currentTime = 120;
        firstAnim.playState = 'running';
        const secondAnim = createFakeAnimation({ duration: 300 });

        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        element.style.transform = 'translate3d(45px, 0px, 0px)';
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            // Deliberately stale value; frozen X must come from live DOM transform.
                            startX: 10, startY: 0, startZ: 0,
                            endX: 200, endY: 80, endZ: 0,
                            unitX: 'px', unitY: 'px', unitZ: 'px',
                            frozenAxes: ['x'],
                            duration: 300, easing: 'linear', version: 2
                        }
                    ]
                }
            }
        });

        const keyframes = element.animate.mock.calls[1][0];
        expect(keyframes[0].transform).toContain('translate3d(45px, 0px, 0px)');
        expect(keyframes[keyframes.length - 1].transform).toContain('translate3d(45px, 80px, 0px)');
    });

    it('re-anchors delayed interrupted translate starts to active in-flight position', () => {
        const animGroup = 'box-delayed-interrupt-anchor';
        const firstAnim = createFakeAnimation({ duration: 1000 });
        firstAnim.playState = 'running';
        // WAAPI currentTime includes delay; active progress should be (650-500)/1000 = 0.15.
        firstAnim.currentTime = 650;
        firstAnim.effect.getTiming = () => ({ duration: 1000, delay: 500 });
        const secondAnim = createFakeAnimation({ duration: 1000 });

        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 1000, delay: 500, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            // Stale command start should be ignored in favor of live in-flight state.
                            startX: 60, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 0,
                            duration: 1000, delay: 500, easing: 'linear', version: 2
                        }
                    ]
                }
            }
        });

        const keyframes = element.animate.mock.calls[1][0];
        expect(keyframes[0].transform).toContain('translate3d(15px, 0px, 0px)');
    });

    it('cancels a non-transform animation when restarted with a new version', () => {
        const animGroup = 'box-opacity-restart';
        const firstAnim = createFakeAnimation({ duration: 200 });
        const secondAnim = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 200, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0.5, endValue: 0, duration: 200, easing: 'linear', version: 2 }
                    ]
                }
            }
        });

        expect(firstAnim.cancelCalls).toBe(1);
        expect(element.animate).toHaveBeenCalledTimes(2);
    });

    it('scales non-transform opacity duration on mid-flight interruption', () => {
        const animGroup = 'box-opacity-interrupt-scale';
        const firstAnim = createFakeAnimation({ duration: 200, progress: 0.5 });
        firstAnim.playState = 'running';
        const secondAnim = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 200, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0.5, endValue: 0, duration: 200, easing: 'linear', version: 2 }
                    ]
                }
            }
        });

        const secondCallOptions = element.animate.mock.calls[1][1];
        expect(secondCallOptions.duration).toBeCloseTo(100, 1);
    });

    it('stores transformOrder for the element when provided', () => {
        const animGroup = 'box-order';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    transformOrder: ['rotate', 'translate', 'scale'],
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 200, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        expect(elementTransformOrders.get(animGroup)).toEqual(['rotate', 'translate', 'scale']);
    });

    it('uses per-group iteration and direction options', () => {
        const animGroup = 'box-iters';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        const iterations = { type: 'times', count: 3 };
        const direction = 'alternate';

        processAnimationData({
            iterations,
            direction,
            elements: {
                [animGroup]: {
                    iterations,
                    direction,
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 200, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        const [, options] = element.animate.mock.calls[0];
        expect(options.iterations).toBe(3);
        expect(options.direction).toBe(direction);
    });

    it('expands a group with multiple matching DOM targets into per-element animations', () => {
        const animGroup = 'box-multi';
        const elA = makeElement({ animGroup });
        const elB = makeElement({ animGroup });
        elA.animate = vi.fn(() => createFakeAnimation({ duration: 100 }));
        elB.animate = vi.fn(() => createFakeAnimation({ duration: 100 }));
        installDom({ element: elA, targetId: animGroup, queryAll: [elA, elB] });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 100, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(elA.animate).toHaveBeenCalledTimes(1);
        expect(elB.animate).toHaveBeenCalledTimes(1);
    });
});

describe('processElementAnimation', () => {
    it('returns early without erroring when target element is not provided and not found', () => {
        installDom({ element: null, targetId: 'never-found' });
        expect(() =>
            processElementAnimation('never-found', {
                properties: [
                    { type: 'opacity', startValue: 0, endValue: 1, duration: 100, easing: 'linear', version: 1 }
                ]
            })
        ).not.toThrow();

        expect(activeAnimations.has('never-found')).toBe(false);
        expect(animationGroups.has('never-found')).toBe(false);
    });

    it('carries a still-running non-transform animation forward when a transform-only call comes in, so its finish does not prematurely wipe activeAnimations', () => {
        // Regression: when a snapshot/resize-driven `animate` arrives with
        // only transform properties, the previously running bgcolor (or any
        // other non-transform) animation must remain in `activeAnimations`
        // and be counted toward the new generation's `totalProperties`. If
        // the new transform's `finish` event were to treat the group as
        // complete on its own, `cleanupAnimGroup` would wipe the still-
        // running bgcolor's entry, freezing the per-frame propertyUpdate
        // values Elm uses for snapshot baselines.
        const animGroup = 'carryover-box';
        const transformAnim1 = createFakeAnimation({ duration: 500 });
        const colorAnim = createFakeAnimation({ duration: 3000 });
        colorAnim.playState = 'running';
        const transformAnim2 = createFakeAnimation({ duration: 1 });

        const element = makeElement({
            animGroup,
            animations: [transformAnim1, colorAnim, transformAnim2]
        });
        installDom({ element, targetId: animGroup });

        // First call: starts a long-running bgcolor animation alongside a transform.
        processElementAnimation(animGroup, {
            properties: [
                {
                    type: 'translate',
                    startX: 0, startY: 0, startZ: 0,
                    endX: 100, endY: 0, endZ: 0,
                    duration: 500, easing: 'linear', version: 1
                },
                {
                    type: 'customColorProperty',
                    cssProperty: 'background-color',
                    startValue: 'rgb(118, 118, 118)',
                    endValue: 'rgb(255, 87, 51)',
                    duration: 3000, easing: 'linear', version: 1
                }
            ]
        });

        const elementAnims = activeAnimations.get(animGroup);
        expect(elementAnims.has('customColor:background-color')).toBe(true);
        expect(elementAnims.has('transform')).toBe(true);
        const colorEntryAfterFirst = elementAnims.get('customColor:background-color');
        const firstGeneration = animationGroups.get(animGroup).generation;
        expect(colorEntryAfterFirst.generation).toBe(firstGeneration);

        // Second call: transform-only (mimics a snapshot/resize-driven animate
        // while bgcolor is still running). This must NOT cancel or evict the
        // bgcolor entry, and the new generation must include bgcolor in its
        // totalProperties so the transform's finish does not wipe everything.
        processElementAnimation(animGroup, {
            properties: [
                {
                    type: 'translate',
                    startX: 50, startY: 0, startZ: 0,
                    endX: 200, endY: 0, endZ: 0,
                    duration: 1, easing: 'linear', version: 2
                }
            ]
        });

        expect(colorAnim.cancelCalls).toBe(0);
        expect(elementAnims.has('customColor:background-color')).toBe(true);

        const newGeneration = animationGroups.get(animGroup).generation;
        expect(newGeneration).toBe(firstGeneration + 1);

        const colorEntryAfterSecond = elementAnims.get('customColor:background-color');
        expect(colorEntryAfterSecond.generation).toBe(newGeneration);

        const groupInfo = animationGroups.get(animGroup);
        expect(groupInfo.totalProperties).toBe(2);

        // Now simulate the new (1ms) transform finishing. Because bgcolor is
        // counted toward totalProperties, the group must NOT be considered
        // complete and `activeAnimations` must still hold the bgcolor entry.
        const newTransformEntry = elementAnims.get('transform');
        newTransformEntry.animation.finish();

        expect(activeAnimations.get(animGroup)).toBeDefined();
        expect(activeAnimations.get(animGroup).has('customColor:background-color')).toBe(true);
        expect(animationGroups.get(animGroup)).toBeDefined();
    });
});

describe('processElementAnimation transformBaseline seeding', () => {
    it('seeds lastKnownTransforms from transformBaseline when cache is empty', () => {
        const animGroup = 'cube-baseline';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    transformBaseline: {
                        translate: { x: 0, y: 0, z: 200 },
                        scale: { x: 1, y: 1, z: 1 }
                    },
                    properties: [{
                        type: 'rotate',
                        startX: 0, startY: 0, startZ: 0,
                        endX: 360, endY: 360, endZ: 360,
                        duration: 200, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const cached = lastKnownTransforms.get(animGroup);
        expect(cached).toBeDefined();
        expect(cached.z).toBe(200);
        expect(cached.scaleX).toBe(1);
        expect(cached.x).toBe(0);
        expect(cached.y).toBe(0);
    });

    it('keyframes built after baseline seeding include translate3d with init Z value', () => {
        const animGroup = 'cube-keyframes';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    transformBaseline: {
                        translate: { x: 0, y: 0, z: 200 }
                    },
                    properties: [{
                        type: 'rotate',
                        startX: 0, startY: 0, startZ: 0,
                        endX: 360, endY: 360, endZ: 360,
                        duration: 200, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const [keyframes] = element.animate.mock.calls[0];
        // Every keyframe must include the init Z=200 translate, otherwise the
        // cube would visually shrink due to perspective foreshortening when
        // ownership of `transform` flips from Elm to JS.
        for (const frame of keyframes) {
            expect(frame.transform).toContain('translate3d(0px, 0px, 200px)');
        }
    });

    it('does not overwrite lastKnownTransforms when cache already has values', () => {
        const animGroup = 'cube-cached';
        lastKnownTransforms.set(animGroup, {
            x: 10, y: 20, z: 30,
            scaleX: 2, scaleY: 2, scaleZ: 2,
            rotateX: 45, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0
        });

        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    transformBaseline: {
                        translate: { x: 0, y: 0, z: 999 }
                    },
                    properties: [{
                        type: 'rotate',
                        startX: 0, startY: 0, startZ: 0,
                        endX: 0, endY: 0, endZ: 90,
                        duration: 200, easing: 'linear', version: 1
                    }]
                }
            }
        });

        const cached = lastKnownTransforms.get(animGroup);
        expect(cached.x).toBe(10);
        expect(cached.z).toBe(30);
        expect(cached.scaleX).toBe(2);
    });

    it('handles missing transformBaseline gracefully', () => {
        const animGroup = 'no-baseline';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        expect(() => processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'opacity',
                        startValue: 0, endValue: 1,
                        duration: 200, easing: 'linear', version: 1
                    }]
                }
            }
        })).not.toThrow();

        expect(element.animate).toHaveBeenCalledTimes(1);
        const elementAnims = activeAnimations.get(animGroup);
        expect(elementAnims.has('opacity')).toBe(true);
        expect(lastKnownTransforms.has(animGroup)).toBe(false);
    });

    it('preserves rotate end state across cleanup for next phase (360 -> 0)', () => {
        const animGroup = 'cube-cycle-rotate';
        const firstAnim = createFakeAnimation({ duration: 8000 });
        const secondAnim = createFakeAnimation({ duration: 8000 });
        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    transformBaseline: {
                        translate: { x: 0, y: 0, z: 200 }
                    },
                    properties: [{
                        type: 'rotate',
                        endX: 360, endY: 360, endZ: 360,
                        duration: 8000, easing: 'linear', version: 1
                    }]
                }
            }
        });

        firstAnim.finish();

        processAnimationData({
            elements: {
                [animGroup]: {
                    transformBaseline: {
                        translate: { x: 0, y: 0, z: 200 }
                    },
                    properties: [{
                        type: 'rotate',
                        endX: 0, endY: 0, endZ: 0,
                        duration: 8000, easing: 'linear', version: 2
                    }]
                }
            }
        });

        expect(element.animate).toHaveBeenCalledTimes(2);
        const secondKeyframes = element.animate.mock.calls[1][0];

        expect(secondKeyframes[0].transform).toContain('rotateZ(360deg)');
        expect(secondKeyframes[secondKeyframes.length - 1].transform).toContain('rotateZ(0deg)');
    });
});

describe('will-change application (WAAPI engine)', () => {
    it('applies elementConfig.willChange to the element and records it', () => {
        const animGroup = 'box-wc';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    willChange: 'transform, opacity',
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 200, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(element.style.willChange).toBe('transform, opacity');
        const entry = appliedWillChange.get(animGroup);
        expect(entry).toBeDefined();
        expect(entry.element).toBe(element);
        expect(entry.value).toBe('transform, opacity');
    });

    it('does not touch element.style.willChange when no willChange is provided', () => {
        const animGroup = 'box-no-wc';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 200, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(element.style.willChange).toBeUndefined();
        expect(appliedWillChange.has(animGroup)).toBe(false);
    });

    it('clears the inline will-change when cleanupAnimGroup runs', () => {
        const animGroup = 'box-wc-clear';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        // Mock "connectedness" so cleanup attempts to clear the style.
        element.isConnected = true;
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    willChange: 'transform',
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 50, endY: 0, endZ: 0,
                            duration: 200, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        expect(element.style.willChange).toBe('transform');

        cleanupAnimGroup(animGroup);

        expect(element.style.willChange).toBe('');
        expect(appliedWillChange.has(animGroup)).toBe(false);
    });

    it('does nothing on cleanup when element is no longer connected', () => {
        const animGroup = 'box-wc-detached';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        element.isConnected = true;
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    willChange: 'opacity',
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 200, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        // Element becomes detached before cleanup.
        element.isConnected = false;
        expect(() => cleanupAnimGroup(animGroup)).not.toThrow();
        expect(element.style.willChange).toBe('opacity'); // untouched
        expect(appliedWillChange.has(animGroup)).toBe(false);
    });
});

describe('retargetAnimation (WAAPI engine)', () => {
    it('does not throw when payload is missing or has no elements', () => {
        installDom({ element: makeElement({ animGroup: 'x' }), targetId: 'x' });
        expect(() => retargetAnimation(null)).not.toThrow();
        expect(() => retargetAnimation({})).not.toThrow();
    });

    it('snaps a touched transform property to the new target inline style', () => {
        const animGroup = 'ball';
        const element = makeElement({ animGroup });
        installDom({ element, targetId: animGroup });

        retargetAnimation({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 250, endY: 0, endZ: 0,
                            unit: 'px',
                            duration: 500,
                            easing: 'linear',
                            version: 1
                        }
                    ]
                }
            }
        });

        expect(element.style.transform).toContain('translate3d(250px, 0px, 0px)');
        expect(element.animate).not.toHaveBeenCalled();
    });

    it('cancels an in-flight transform animation before snapping', () => {
        const animGroup = 'ball';
        const element = makeElement({ animGroup });
        installDom({ element, targetId: animGroup });

        const inflight = createFakeAnimation();
        activeAnimations.set(animGroup, new Map([
            ['transform', { animation: inflight, version: 1 }]
        ]));

        retargetAnimation({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            unit: 'px',
                            duration: 500,
                            easing: 'linear',
                            version: 2
                        }
                    ]
                }
            }
        });

        expect(inflight.cancelCalls).toBe(1);
        expect(element.style.transform).toContain('translate3d(100px, 0px, 0px)');
    });
});

describe('retargetAnimation per-axis continuation', () => {
    function setupInflightTransform(animGroup, element, oldT, duration = 1000) {
        const inflight = createFakeAnimation({ duration });
        inflight.currentTime = oldT;
        inflight.playState = 'running';
        const resolvedValues = {
            translate: { startX: 0, startY: 0, startZ: 0, endX: 100, endY: 100, endZ: 0, unitX: 'px', unitY: 'px', unitZ: 'px' },
            scale: { startX: 1, startY: 1, startZ: 1, endX: 2, endY: 2, endZ: 1 },
            rotate: { startX: 0, startY: 0, startZ: 0, endX: 90, endY: 0, endZ: 0 },
            skew: { startX: 0, startY: 0, endX: 10, endY: 0 }
        };
        activeAnimations.set(animGroup, new Map([
            ['transform', {
                animation: inflight,
                version: 1,
                animGroup,
                easingKeyframes: null,
                transformProperties: [],
                resolvedValues,
                generation: 0,
                propertyIndex: 0
            }]
        ]));
        return inflight;
    }

    function setupInflightNonTransform(animGroup, type, resolvedNonTransform, oldT, duration = 1000) {
        const inflight = createFakeAnimation({ duration });
        inflight.currentTime = oldT;
        inflight.playState = 'running';
        activeAnimations.set(animGroup, new Map([
            [type, {
                animation: inflight,
                version: 1,
                animGroup,
                easingKeyframes: null,
                resolvedNonTransform,
                generation: 0,
                propertyIndex: 0
            }]
        ]));
        return inflight;
    }

    it('builds continuation animation for scale per-axis (touched X, untouched Y)', () => {
        const animGroup = 'box';
        const element = makeElement({ animGroup });
        installDom({ element, targetId: animGroup });
        const inflight = setupInflightTransform(animGroup, element, 300);

        retargetAnimation({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'scale',
                        endX: 3, endY: 1, endZ: 1,
                        touchedX: true, touchedY: false, touchedZ: false,
                        duration: 1000, easing: 'linear', version: 2
                    }]
                }
            }
        });

        expect(inflight.cancelCalls).toBe(1);
        expect(element.animate).toHaveBeenCalledTimes(1);
        const [, options] = element.animate.mock.calls[0];
        expect(options.delay).toBe(-300);
        expect(options.duration).toBe(1000);
    });

    it('builds continuation animation for rotate per-axis (touched Z only)', () => {
        const animGroup = 'box';
        const element = makeElement({ animGroup });
        installDom({ element, targetId: animGroup });
        const inflight = setupInflightTransform(animGroup, element, 250);

        retargetAnimation({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'rotate',
                        endX: 0, endY: 0, endZ: 180,
                        touchedX: false, touchedY: false, touchedZ: true,
                        duration: 1000, easing: 'linear', version: 2
                    }]
                }
            }
        });

        expect(inflight.cancelCalls).toBe(1);
        const [, options] = element.animate.mock.calls[0];
        expect(options.delay).toBe(-250);
    });

    it('builds continuation animation for skew per-axis (touched Y, untouched X)', () => {
        const animGroup = 'box';
        const element = makeElement({ animGroup });
        installDom({ element, targetId: animGroup });
        const inflight = setupInflightTransform(animGroup, element, 400);

        retargetAnimation({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'skew',
                        endX: 0, endY: 30,
                        touchedX: false, touchedY: true,
                        duration: 1000, easing: 'linear', version: 2
                    }]
                }
            }
        });

        expect(inflight.cancelCalls).toBe(1);
        const [, options] = element.animate.mock.calls[0];
        expect(options.delay).toBe(-400);
    });

    it('builds continuation animation for size per-axis (touched width, untouched height)', () => {
        const animGroup = 'box';
        const element = makeElement({ animGroup });
        installDom({ element, targetId: animGroup });
        const inflight = setupInflightNonTransform(animGroup, 'size', {
            type: 'size',
            startWidth: 100, startHeight: 50,
            endWidth: 200, endHeight: 150,
            unitWidth: 'px', unitHeight: 'px'
        }, 200);

        retargetAnimation({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'size',
                        endWidth: 400, endHeight: 150,
                        touchedWidth: true, touchedHeight: false,
                        unitWidth: 'px', unitHeight: 'px',
                        duration: 1000, easing: 'linear', version: 2
                    }]
                }
            }
        });

        expect(inflight.cancelCalls).toBe(1);
        expect(element.animate).toHaveBeenCalledTimes(1);
        const [keyframes, options] = element.animate.mock.calls[0];
        expect(options.delay).toBe(-200);
        expect(options.duration).toBe(1000);
        // Touched axis snapped: width start === end === 400
        expect(keyframes[0].width).toBe('400px');
        expect(keyframes[1].width).toBe('400px');
        // Untouched axis preserved from in-flight: 50 -> 150
        expect(keyframes[0].height).toBe('50px');
        expect(keyframes[1].height).toBe('150px');
    });

    it('builds continuation animation for perspectiveOrigin per-axis (touched X, untouched Y)', () => {
        const animGroup = 'box';
        const element = makeElement({ animGroup });
        installDom({ element, targetId: animGroup });
        const inflight = setupInflightNonTransform(animGroup, 'perspectiveOrigin', {
            type: 'perspectiveOrigin',
            startX: 0, startY: 0,
            endX: 50, endY: 50,
            unitX: '%', unitY: '%'
        }, 100);

        retargetAnimation({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'perspectiveOrigin',
                        endX: 100, endY: 50,
                        touchedX: true, touchedY: false,
                        unitX: '%', unitY: '%',
                        duration: 1000, easing: 'linear', version: 2
                    }]
                }
            }
        });

        expect(inflight.cancelCalls).toBe(1);
        const [keyframes, options] = element.animate.mock.calls[0];
        expect(options.delay).toBe(-100);
        // Touched X snapped to 100; untouched Y preserves 0 -> 50
        expect(keyframes[0].perspectiveOrigin).toBe('100% 0%');
        expect(keyframes[1].perspectiveOrigin).toBe('100% 50%');
    });

    it('falls back to full-snap when every axis is touched (no in-flight preservation needed)', () => {
        const animGroup = 'box';
        const element = makeElement({ animGroup });
        installDom({ element, targetId: animGroup });
        const inflight = setupInflightNonTransform(animGroup, 'size', {
            type: 'size',
            startWidth: 100, startHeight: 50,
            endWidth: 200, endHeight: 150,
            unitWidth: 'px', unitHeight: 'px'
        }, 200);

        retargetAnimation({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'size',
                        endWidth: 400, endHeight: 300,
                        touchedWidth: true, touchedHeight: true,
                        unitWidth: 'px', unitHeight: 'px',
                        duration: 1000, easing: 'linear', version: 2
                    }]
                }
            }
        });

        expect(inflight.cancelCalls).toBe(1);
        // Full snap path uses inline style, not element.animate
        expect(element.style.width).toBe('400px');
        expect(element.style.height).toBe('300px');
    });
});


