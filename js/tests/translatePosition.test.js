/* eslint-env node */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { _translatePositionAnimationImmediate as translatePositionAnimation } from '../src/animations.js';
import {
    activeAnimations,
    animationGroups,
    elementTransformOrders,
    lastKnownPerspectiveOrigins,
    lastKnownTransforms
} from '../src/state.js';
import { createFakeAnimation, installDom, cleanupDom } from './_publicApiHelpers.js';

function makeElement(animGroup, animateImpl) {
    return {
        id: animGroup,
        animate: animateImpl || vi.fn(),
        style: { transform: '' },
        getAnimations: () => [],
        getAttribute(name) {
            if (name === 'data-anim-target') return animGroup;
            return null;
        }
    };
}

function defaultResolved({
    startX = 0, endX = 0,
    startY = 0, endY = 0,
    startZ = 0, endZ = 0
} = {}) {
    return {
        translate: {
            startX: startX, startY: startY, startZ: startZ,
            endX: endX, endY: endY, endZ: endZ,
            easing: 'linear', easingKeyframes: null, duration: 1000
        },
        scale: {
            startX: 1, startY: 1, startZ: 1,
            endX: 1, endY: 1, endZ: 1,
            easing: 'linear', easingKeyframes: null, duration: 0
        },
        rotate: {
            startX: 0, startY: 0, startZ: 0,
            endX: 0, endY: 0, endZ: 0,
            easing: 'linear', easingKeyframes: null, duration: 0
        },
        skew: {
            startX: 0, startY: 0,
            endX: 0, endY: 0,
            easing: 'linear', easingKeyframes: null, duration: 0
        }
    };
}

function seedTransformAnimation(animGroup, resolved) {
    const anim = createFakeAnimation({ duration: 1000 });
    anim.playState = 'running';
    anim.currentTime = 250;
    const elementAnims = new Map();
    elementAnims.set('transform', {
        animation: anim,
        version: 1,
        animGroup: animGroup,
        easingKeyframes: null,
        transformProperties: [],
        resolvedValues: resolved,
        generation: 1,
        propertyIndex: 0,
        updateFn: vi.fn()
    });
    activeAnimations.set(animGroup, elementAnims);
    animationGroups.set(animGroup, {
        totalProperties: 1,
        completedProperties: 0,
        started: true,
        generation: 1,
        nextPropertyIndex: 1,
        lastIteration: 0,
        propertyIterations: [0],
        propertyConfigs: []
    });
    return anim;
}

function clearGlobalState() {
    activeAnimations.clear();
    animationGroups.clear();
    elementTransformOrders.clear();
    lastKnownPerspectiveOrigins.clear();
    lastKnownTransforms.clear();
}

beforeEach(clearGlobalState);
afterEach(() => {
    cleanupDom();
    clearGlobalState();
});

describe('translatePositionAnimation', () => {
    it('is a no-op when no transform animation is in flight (and writes inline transform)', () => {
        const element = makeElement('box');
        installDom({ element: element, targetId: 'box' });
        expect(() => translatePositionAnimation({
            elementId: 'box',
            x: 100, y: 200, z: null
        })).not.toThrow();
        // With no active animation, axes snap unconditionally and the
        // inline transform reflects the snapped values.
        const known = lastKnownTransforms.get('box');
        expect(known.x).toBe(100);
        expect(known.y).toBe(200);
        expect(element.style.transform).toContain('translate3d(100px, 200px, 0px)');
    });

    it('snaps a static axis (startY === endY) into the resolved translate', () => {
        const element = makeElement('box');
        installDom({ element: element, targetId: 'box' });
        const resolved = defaultResolved({ startX: 0, endX: 500, startY: 0, endY: 0 });
        const anim = seedTransformAnimation('box', resolved);

        translatePositionAnimation({
            elementId: 'box',
            x: null, y: 250, z: null
        });

        // Static Y axis snapped: both start and end set to 250.
        expect(resolved.translate.startY).toBe(250);
        expect(resolved.translate.endY).toBe(250);
        // Animating X axis untouched.
        expect(resolved.translate.startX).toBe(0);
        expect(resolved.translate.endX).toBe(500);
        // Keyframes rebuilt via setKeyframes (no cancel/recreate).
        expect(anim.setKeyframesCalls.length).toBe(1);
        expect(anim.cancelCalls).toBe(0);
        const newKeyframes = anim.setKeyframesCalls[0];
        // Every keyframe holds the snapped Y at 250px.
        expect(newKeyframes.length).toBeGreaterThan(1);
        for (const frame of newKeyframes) {
            expect(frame.transform).toContain(', 250px,');
        }
        // lastKnownTransforms reflects the snapped Y.
        expect(lastKnownTransforms.get('box').y).toBe(250);
    });

    it('leaves an animating axis (startX !== endX) untouched', () => {
        const element = makeElement('box');
        installDom({ element: element, targetId: 'box' });
        const resolved = defaultResolved({ startX: 0, endX: 500 });
        const anim = seedTransformAnimation('box', resolved);

        translatePositionAnimation({
            elementId: 'box',
            x: 9999, y: null, z: null
        });

        // Animating X axis: directive ignored.
        expect(resolved.translate.startX).toBe(0);
        expect(resolved.translate.endX).toBe(500);
        // No keyframes rebuild — no axis was snapped, so nothing to do.
        expect(anim.setKeyframesCalls.length).toBe(0);
        // lastKnownTransforms must NOT be updated for the rejected axis.
        // (`lastKnownTransforms.get('box')` may be undefined if never touched.)
        const known = lastKnownTransforms.get('box');
        if (known) {
            expect(known.x).not.toBe(9999);
        }
    });

    it('ignores null axes and snaps only the provided ones', () => {
        const element = makeElement('box');
        installDom({ element: element, targetId: 'box' });
        const resolved = defaultResolved({
            startX: 0, endX: 0,
            startY: 0, endY: 0,
            startZ: 50, endZ: 50
        });
        seedTransformAnimation('box', resolved);

        translatePositionAnimation({
            elementId: 'box',
            x: 10, y: null, z: 80
        });

        expect(resolved.translate.startX).toBe(10);
        expect(resolved.translate.endX).toBe(10);
        // Y untouched: still 0/0.
        expect(resolved.translate.startY).toBe(0);
        expect(resolved.translate.endY).toBe(0);
        expect(resolved.translate.startZ).toBe(80);
        expect(resolved.translate.endZ).toBe(80);
    });

    it('returns silently when every axis is null', () => {
        const element = makeElement('box');
        installDom({ element: element, targetId: 'box' });
        const resolved = defaultResolved();
        const anim = seedTransformAnimation('box', resolved);

        translatePositionAnimation({
            elementId: 'box',
            x: null, y: null, z: null
        });

        expect(anim.setKeyframesCalls.length).toBe(0);
        expect(lastKnownTransforms.has('box')).toBe(false);
    });

    it('handles a mix of static-snap and animating-skip in one call', () => {
        const element = makeElement('box');
        installDom({ element: element, targetId: 'box' });
        const resolved = defaultResolved({ startX: 0, endX: 500, startY: 0, endY: 0 });
        const anim = seedTransformAnimation('box', resolved);

        translatePositionAnimation({
            elementId: 'box',
            x: 9999, y: 300, z: null
        });

        // X animating → ignored.
        expect(resolved.translate.startX).toBe(0);
        expect(resolved.translate.endX).toBe(500);
        // Y static → snapped.
        expect(resolved.translate.startY).toBe(300);
        expect(resolved.translate.endY).toBe(300);
        // Y snap triggered a keyframes rebuild.
        expect(anim.setKeyframesCalls.length).toBe(1);
    });

    it('does not throw when the element cannot be found', () => {
        installDom({ element: makeElement('box'), targetId: 'box' });
        expect(() => translatePositionAnimation({
            elementId: 'missing',
            x: 10, y: null, z: null
        })).not.toThrow();
    });
});
