// @ts-nocheck
/* eslint-env node */
/* eslint-disable */
/* global global */
import { describe, expect, it, vi } from 'vitest';
import { processAnimationData } from '../src/animations.js';
import { processScrollDrivenData, processViewDrivenData } from '../src/scroll.js';
import { activeAnimations, animationGroups, elementTransformOrders, lastKnownTransforms, appliedWillChange, portsRef } from '../src/state.js';
import { _resetSubscribers } from '../src/errors.js';
import { resetPortMissingWarning } from '../src/ports.js';
import { createFakeAnimation, installDom, cleanupDom } from './_publicApiHelpers.js';

function clearGlobalState() {
    activeAnimations.clear();
    animationGroups.clear();
    elementTransformOrders.clear();
    lastKnownTransforms.clear();
    appliedWillChange.clear();
}

function cleanupTestContext() {
    cleanupDom();
    clearGlobalState();
    _resetSubscribers();
    resetPortMissingWarning();
    portsRef.ports = null;
}

describe('size partial-axis semantics across JS engines', () => {
    describe('WAAPI animate path', () => {
        it('for size.toH payload, omits width keyframes so untouched width CSS is not overwritten', () => {
            expect.assertions(4);
            try {
                clearGlobalState();
                portsRef.ports = { motionMsg: { send() { } } };

                const animGroup = 'box-size-toh';
                const animation = createFakeAnimation({ duration: 300 });
                const element = {
                    id: animGroup,
                    animate: vi.fn(() => animation),
                    style: { transform: '' },
                    getAnimations: () => [],
                    getAttribute(name) {
                        if (name === 'data-anim-target') return animGroup;
                        return null;
                    }
                };
                installDom({ element, targetId: animGroup });

                processAnimationData({
                    elements: {
                        [animGroup]: {
                            properties: [
                                {
                                    type: 'size',
                                    startHeight: 0,
                                    endHeight: 120,
                                    unitHeight: 'px',
                                    duration: 300,
                                    easing: 'linear',
                                    version: 1
                                }
                            ]
                        }
                    }
                });

                expect(element.animate).toHaveBeenCalledTimes(1);
                const [keyframes] = element.animate.mock.calls[0];
                expect(keyframes[0]).toMatchObject({ height: '0px' });
                expect(keyframes[1]).toMatchObject({ height: '120px' });
                expect([('width' in keyframes[0]), ('width' in keyframes[1])]).toStrictEqual([false, false]);
            } finally {
                cleanupTestContext();
            }
        });

        it('for size.toW payload, omits height keyframes so untouched height CSS is not overwritten', () => {
            expect.assertions(4);
            try {
                clearGlobalState();
                portsRef.ports = { motionMsg: { send() { } } };

                const animGroup = 'box-size-tow';
                const animation = createFakeAnimation({ duration: 300 });
                const element = {
                    id: animGroup,
                    animate: vi.fn(() => animation),
                    style: { transform: '' },
                    getAnimations: () => [],
                    getAttribute(name) {
                        if (name === 'data-anim-target') return animGroup;
                        return null;
                    }
                };
                installDom({ element, targetId: animGroup });

                processAnimationData({
                    elements: {
                        [animGroup]: {
                            properties: [
                                {
                                    type: 'size',
                                    startWidth: 0,
                                    endWidth: 240,
                                    unitWidth: 'px',
                                    duration: 300,
                                    easing: 'linear',
                                    version: 1
                                }
                            ]
                        }
                    }
                });

                expect(element.animate).toHaveBeenCalledTimes(1);
                const [keyframes] = element.animate.mock.calls[0];
                expect(keyframes[0]).toMatchObject({ width: '0px' });
                expect(keyframes[1]).toMatchObject({ width: '240px' });
                expect([('height' in keyframes[0]), ('height' in keyframes[1])]).toStrictEqual([false, false]);
            } finally {
                cleanupTestContext();
            }
        });
    });

    describe('ScrollTimeline path', () => {
        it('for size.toH payload, omits width keyframes so untouched width CSS is not overwritten', () => {
            expect.assertions(4);
            try {
                clearGlobalState();
                portsRef.ports = { motionMsg: { send() { } } };

                const element = { style: {}, animate: vi.fn(() => createFakeAnimation()) };
                installDom({ element, targetId: 'card' });
                global.ScrollTimeline = class {
                    constructor(options) { this.options = options; }
                };

                processScrollDrivenData({
                    timeline: { source: 'document', axis: 'block' },
                    elements: {
                        card: {
                            target: 'card',
                            properties: [
                                {
                                    type: 'size',
                                    startHeight: 0,
                                    endHeight: 120,
                                    unitHeight: 'px',
                                    duration: 300,
                                    easing: 'linear',
                                    version: 1
                                }
                            ]
                        }
                    }
                });

                expect(element.animate).toHaveBeenCalledTimes(1);
                const [keyframes] = element.animate.mock.calls[0];
                expect(keyframes[0]).toMatchObject({ height: '0px' });
                expect(keyframes[1]).toMatchObject({ height: '120px' });
                expect([('width' in keyframes[0]), ('width' in keyframes[1])]).toStrictEqual([false, false]);
            } finally {
                cleanupTestContext();
            }
        });

        it('for size.toW payload, omits height keyframes so untouched height CSS is not overwritten', () => {
            expect.assertions(4);
            try {
                clearGlobalState();
                portsRef.ports = { motionMsg: { send() { } } };

                const element = { style: {}, animate: vi.fn(() => createFakeAnimation()) };
                installDom({ element, targetId: 'card' });
                global.ScrollTimeline = class {
                    constructor(options) { this.options = options; }
                };

                processScrollDrivenData({
                    timeline: { source: 'document', axis: 'block' },
                    elements: {
                        card: {
                            target: 'card',
                            properties: [
                                {
                                    type: 'size',
                                    startWidth: 0,
                                    endWidth: 240,
                                    unitWidth: 'px',
                                    duration: 300,
                                    easing: 'linear',
                                    version: 1
                                }
                            ]
                        }
                    }
                });

                expect(element.animate).toHaveBeenCalledTimes(1);
                const [keyframes] = element.animate.mock.calls[0];
                expect(keyframes[0]).toMatchObject({ width: '0px' });
                expect(keyframes[1]).toMatchObject({ width: '240px' });
                expect([('height' in keyframes[0]), ('height' in keyframes[1])]).toStrictEqual([false, false]);
            } finally {
                cleanupTestContext();
            }
        });
    });

    describe('ViewTimeline path', () => {
        it('for size.toH payload, omits width keyframes so untouched width CSS is not overwritten', () => {
            expect.assertions(4);
            try {
                clearGlobalState();
                portsRef.ports = { motionMsg: { send() { } } };

                const element = { style: {}, animate: vi.fn(() => createFakeAnimation()) };
                installDom({ element, targetId: 'card' });
                global.ViewTimeline = class {
                    constructor(options) { this.options = options; }
                };

                processViewDrivenData({
                    timeline: { axis: 'block', rangeStart: 'cover 0%', rangeEnd: 'cover 100%' },
                    elements: {
                        card: {
                            target: 'card',
                            properties: [
                                {
                                    type: 'size',
                                    startHeight: 0,
                                    endHeight: 120,
                                    unitHeight: 'px',
                                    duration: 300,
                                    easing: 'linear',
                                    version: 1
                                }
                            ]
                        }
                    }
                });

                expect(element.animate).toHaveBeenCalledTimes(1);
                const [keyframes] = element.animate.mock.calls[0];
                expect(keyframes[0]).toMatchObject({ height: '0px' });
                expect(keyframes[1]).toMatchObject({ height: '120px' });
                expect([('width' in keyframes[0]), ('width' in keyframes[1])]).toStrictEqual([false, false]);
            } finally {
                cleanupTestContext();
            }
        });

        it('for size.toW payload, omits height keyframes so untouched height CSS is not overwritten', () => {
            expect.assertions(4);
            try {
                clearGlobalState();
                portsRef.ports = { motionMsg: { send() { } } };

                const element = { style: {}, animate: vi.fn(() => createFakeAnimation()) };
                installDom({ element, targetId: 'card' });
                global.ViewTimeline = class {
                    constructor(options) { this.options = options; }
                };

                processViewDrivenData({
                    timeline: { axis: 'block', rangeStart: 'cover 0%', rangeEnd: 'cover 100%' },
                    elements: {
                        card: {
                            target: 'card',
                            properties: [
                                {
                                    type: 'size',
                                    startWidth: 0,
                                    endWidth: 240,
                                    unitWidth: 'px',
                                    duration: 300,
                                    easing: 'linear',
                                    version: 1
                                }
                            ]
                        }
                    }
                });

                expect(element.animate).toHaveBeenCalledTimes(1);
                const [keyframes] = element.animate.mock.calls[0];
                expect(keyframes[0]).toMatchObject({ width: '0px' });
                expect(keyframes[1]).toMatchObject({ width: '240px' });
                expect([('height' in keyframes[0]), ('height' in keyframes[1])]).toStrictEqual([false, false]);
            } finally {
                cleanupTestContext();
            }
        });
    });
});
