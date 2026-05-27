/* eslint-env node */
/* global global */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { processAnimationData, processElementAnimation, retargetAnimation } from '../src/animations.js';
import { activeAnimations, animationGroups, elementTransformOrders, lastKnownTransforms, appliedWillChange, cleanupAnimGroup } from '../src/state.js';
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
});

describe('processAnimationData (WAAPI engine)', () => {
    it('reports COMMAND_INVALID when animationData is missing or has no elements', () => {
        installDom({ element: makeElement({ animGroup: 'x' }), targetId: 'x' });
        const errorSpy = vi.fn();
        global.window.addEventListener = (_, handler) => { errorSpy.handler = handler; };

        // Both branches: null and missing elements
        expect(() => processAnimationData(null)).not.toThrow();
        expect(() => processAnimationData({})).not.toThrow();
    });

    it('reports TARGET_NOT_FOUND when no element matches the animGroup', () => {
        installDom({ element: null, targetId: 'absent' });
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
        const elementAnims = activeAnimations.get(animGroup);
        expect(elementAnims.has('transform')).toBe(true);
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
                        { type: 'opacity', startValue: 1, endValue: 0, duration: 200, easing: 'linear', version: 2 }
                    ]
                }
            }
        });

        expect(firstAnim.cancelCalls).toBe(1);
        expect(element.animate).toHaveBeenCalledTimes(2);
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

    it('passes through global iteration and direction options', () => {
        const animGroup = 'box-iters';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            iterations: { type: 'times', count: 3 },
            direction: 'alternate',
            elements: {
                [animGroup]: {
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
        expect(options.direction).toBe('alternate');
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

        expect(lastKnownTransforms.has(animGroup)).toBe(false);
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

