/* eslint-env node */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { _perspectiveOriginPositionAnimationImmediate as perspectiveOriginPositionAnimation } from '../src/animations.js';
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
        style: { perspectiveOrigin: '' },
        getAnimations: () => [],
        getAttribute(name) {
            if (name === 'data-anim-target') return animGroup;
            return null;
        }
    };
}

function defaultResolved({
    startX = 50, endX = 50,
    startY = 50, endY = 50,
    unit = '%'
} = {}) {
    return {
        type: 'perspectiveOrigin',
        startX: startX,
        startY: startY,
        endX: endX,
        endY: endY,
        unit: unit
    };
}

function seedPerspectiveOriginAnimation(animGroup, resolved) {
    const anim = createFakeAnimation({ duration: 1000 });
    anim.playState = 'running';
    anim.currentTime = 250;
    const elementAnims = new Map();
    elementAnims.set('perspectiveOrigin', {
        animation: anim,
        version: 1,
        animGroup: animGroup,
        easingKeyframes: null,
        resolvedNonTransform: resolved,
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

describe('perspectiveOriginPositionAnimation', () => {
    it('writes inline perspectiveOrigin and cache when no animation is in flight', () => {
        const element = makeElement('camera');
        installDom({ element: element, targetId: 'camera' });

        expect(() => perspectiveOriginPositionAnimation({
            elementId: 'camera',
            x: 480, y: null, unit: 'px'
        })).not.toThrow();

        const cached = lastKnownPerspectiveOrigins.get('camera');
        expect(cached.x).toBe(480);
        expect(cached.unit).toBe('px');
        expect(element.style.perspectiveOrigin).toContain('480px');
    });

    it('snaps a static axis (startY === endY) into the resolved slot', () => {
        const element = makeElement('camera');
        installDom({ element: element, targetId: 'camera' });
        const resolved = defaultResolved({ startX: 0, endX: 500, startY: 0, endY: 0, unit: 'px' });
        const anim = seedPerspectiveOriginAnimation('camera', resolved);

        perspectiveOriginPositionAnimation({
            elementId: 'camera',
            x: null, y: 250, unit: 'px'
        });

        // Static Y axis snapped: both endpoints land on 250.
        expect(resolved.startY).toBe(250);
        expect(resolved.endY).toBe(250);
        // Animating X axis untouched.
        expect(resolved.startX).toBe(0);
        expect(resolved.endX).toBe(500);
        // Keyframes rebuilt in place — no cancel, no currentTime write.
        expect(anim.setKeyframesCalls.length).toBe(1);
        expect(anim.cancelCalls).toBe(0);
        // Inline style + cache reflect the snap.
        expect(element.style.perspectiveOrigin).toContain('250px');
        expect(lastKnownPerspectiveOrigins.get('camera').y).toBe(250);
    });

    it('leaves an animating axis (startX !== endX) untouched', () => {
        const element = makeElement('camera');
        installDom({ element: element, targetId: 'camera' });
        const resolved = defaultResolved({ startX: 0, endX: 500, unit: 'px' });
        const anim = seedPerspectiveOriginAnimation('camera', resolved);

        perspectiveOriginPositionAnimation({
            elementId: 'camera',
            x: 9999, y: null, unit: 'px'
        });

        // Animating X axis: directive ignored.
        expect(resolved.startX).toBe(0);
        expect(resolved.endX).toBe(500);
        // Nothing snapped → no keyframes rebuild.
        expect(anim.setKeyframesCalls.length).toBe(0);
    });

    it('preserves the live animation reference and currentTime (no cancel / no seek)', () => {
        const element = makeElement('camera');
        installDom({ element: element, targetId: 'camera' });
        const resolved = defaultResolved({ startX: 0, endX: 500, startY: 0, endY: 0, unit: 'px' });
        const anim = seedPerspectiveOriginAnimation('camera', resolved);
        const animationReferenceBefore = activeAnimations.get('camera').get('perspectiveOrigin').animation;
        const currentTimeBefore = anim.currentTime;

        perspectiveOriginPositionAnimation({
            elementId: 'camera',
            x: null, y: 300, unit: 'px'
        });

        const animationReferenceAfter = activeAnimations.get('camera').get('perspectiveOrigin').animation;
        expect(animationReferenceAfter).toBe(animationReferenceBefore);
        expect(anim.currentTime).toBe(currentTimeBefore);
        expect(anim.cancelCalls).toBe(0);
    });

    it('returns silently when both axes are null', () => {
        const element = makeElement('camera');
        installDom({ element: element, targetId: 'camera' });
        const resolved = defaultResolved();
        const anim = seedPerspectiveOriginAnimation('camera', resolved);

        perspectiveOriginPositionAnimation({
            elementId: 'camera',
            x: null, y: null, unit: '%'
        });

        expect(anim.setKeyframesCalls.length).toBe(0);
        expect(lastKnownPerspectiveOrigins.has('camera')).toBe(false);
    });
});
