/* eslint-env node */
import { describe, expect, it } from 'vitest';
import {
    computeLegProgress,
    axisBoundsChanged,
    chooseEffectiveAxisValue,
    chooseDominantAxis,
    sanitizeResizeDuration,
    deriveTransformKeyframeCount,
    getAnimationActiveTiming,
    isResizeGeometryUnchanged,
    isPerspectiveOriginGeometryUnchanged,
    isSizeGeometryUnchanged
} from '../src/animations.js';

function fakeIterationAnimation(currentIteration) {
    return {
        effect: {
            getComputedTiming: () => ({ currentIteration })
        }
    };
}

describe('computeLegProgress', () => {
    it('returns null when the old current time is not finite', () => {
        expect(computeLegProgress(NaN, 1000, 'normal', null)).toBeNull();
    });

    it('returns null when the old duration is not finite', () => {
        expect(computeLegProgress(500, Infinity, 'normal', null)).toBeNull();
    });

    it('returns null when the old duration is zero or negative', () => {
        expect(computeLegProgress(500, 0, 'normal', null)).toBeNull();
        expect(computeLegProgress(500, -100, 'normal', null)).toBeNull();
    });

    it('returns the raw progress for a normal direction', () => {
        expect(computeLegProgress(250, 1000, 'normal', null)).toBeCloseTo(0.25);
    });

    it('wraps the raw progress across iterations for a normal direction', () => {
        // 1250 % 1000 = 250 -> 0.25
        expect(computeLegProgress(1250, 1000, 'normal', null)).toBeCloseTo(0.25);
    });

    it('mirrors the progress for a reverse direction', () => {
        expect(computeLegProgress(250, 1000, 'reverse', null)).toBeCloseTo(0.75);
    });

    it('keeps the forward leg on an even iteration for alternate', () => {
        expect(computeLegProgress(250, 1000, 'alternate', fakeIterationAnimation(0))).toBeCloseTo(0.25);
    });

    it('mirrors the reverse leg on an odd iteration for alternate', () => {
        expect(computeLegProgress(250, 1000, 'alternate', fakeIterationAnimation(1))).toBeCloseTo(0.75);
    });

    it('mirrors the first leg for alternate-reverse (even iteration)', () => {
        expect(computeLegProgress(250, 1000, 'alternate-reverse', fakeIterationAnimation(0))).toBeCloseTo(0.75);
    });

    it('keeps the forward leg on an odd iteration for alternate-reverse', () => {
        expect(computeLegProgress(250, 1000, 'alternate-reverse', fakeIterationAnimation(1))).toBeCloseTo(0.25);
    });

    it('falls back to the raw progress when the iteration is not available', () => {
        expect(computeLegProgress(250, 1000, 'alternate', fakeIterationAnimation(undefined))).toBeCloseTo(0.25);
    });

    it('falls back to the raw progress when the animation has no effect timing', () => {
        expect(computeLegProgress(250, 1000, 'alternate', {})).toBeCloseTo(0.25);
    });
});

describe('axisBoundsChanged', () => {
    it('reports a change when the start moves beyond epsilon', () => {
        expect(axisBoundsChanged(0, 10, 1, 10)).toBe(true);
    });

    it('reports a change when the end moves beyond epsilon', () => {
        expect(axisBoundsChanged(0, 10, 0, 11)).toBe(true);
    });

    it('reports no change when both bounds are within epsilon', () => {
        expect(axisBoundsChanged(0, 10, 0.0005, 10.0005)).toBe(false);
    });

    it('honours a custom epsilon', () => {
        expect(axisBoundsChanged(0, 10, 0.5, 10, 1)).toBe(false);
        expect(axisBoundsChanged(0, 10, 2, 10, 1)).toBe(true);
    });
});

describe('chooseEffectiveAxisValue', () => {
    it('returns the command value when the live value is not finite', () => {
        expect(chooseEffectiveAxisValue(0, 10, 0, 10, 42, NaN)).toBe(42);
    });

    it('returns the command value when the bounds changed', () => {
        expect(chooseEffectiveAxisValue(0, 10, 5, 10, 42, 7)).toBe(42);
    });

    it('returns the live value when the bounds are unchanged', () => {
        expect(chooseEffectiveAxisValue(0, 10, 0, 10, 42, 7)).toBe(7);
    });
});

describe('chooseDominantAxis', () => {
    it('chooses the axis with the largest absolute span', () => {
        expect(chooseDominantAxis({ x: 1, y: -5, z: 2 })).toBe('y');
    });

    it('returns null when every span is below the epsilon', () => {
        expect(chooseDominantAxis({ x: 0, y: 0, z: 0 })).toBeNull();
    });

    it('ignores non-finite spans', () => {
        expect(chooseDominantAxis({ x: NaN, y: 3, z: 'nope' })).toBe('y');
    });

    it('respects a custom epsilon threshold', () => {
        expect(chooseDominantAxis({ x: 0.5, y: 0.4, z: 0.3 }, 1)).toBeNull();
    });
});

describe('sanitizeResizeDuration', () => {
    it('falls back to the old duration for a non-positive candidate', () => {
        expect(sanitizeResizeDuration(0, 400)).toBe(400);
        expect(sanitizeResizeDuration(-10, 400)).toBe(400);
    });

    it('falls back to the old duration for a non-finite candidate', () => {
        expect(sanitizeResizeDuration(NaN, 400)).toBe(400);
    });

    it('accepts the candidate when the old duration is invalid', () => {
        expect(sanitizeResizeDuration(250, 0)).toBe(250);
        expect(sanitizeResizeDuration(250, NaN)).toBe(250);
    });

    it('keeps a plausible candidate unchanged', () => {
        expect(sanitizeResizeDuration(250, 400)).toBe(250);
    });

    it('clamps an implausibly large candidate back to the old duration', () => {
        expect(sanitizeResizeDuration(5000, 400)).toBe(400);
    });

    it('allows a candidate exactly at the 8x ceiling', () => {
        expect(sanitizeResizeDuration(3200, 400)).toBe(3200);
    });
});

describe('deriveTransformKeyframeCount', () => {
    it('returns the default count when no easing keyframes are present', () => {
        expect(deriveTransformKeyframeCount({})).toBe(30);
        expect(deriveTransformKeyframeCount(null)).toBe(30);
    });

    it('ignores easing keyframe arrays of length one or less', () => {
        expect(deriveTransformKeyframeCount({ translate: { easingKeyframes: [{ offset: 0 }] } })).toBe(30);
    });

    it('returns the largest keyframe length across transform kinds', () => {
        const resolved = {
            translate: { easingKeyframes: [{}, {}, {}] },
            scale: { easingKeyframes: [{}, {}, {}, {}, {}] },
            rotate: { easingKeyframes: [{}, {}] }
        };
        expect(deriveTransformKeyframeCount(resolved)).toBe(5);
    });
});

describe('getAnimationActiveTiming', () => {
    function timingAnimation({ duration, delay = 0, currentTime }) {
        return {
            currentTime,
            effect: {
                getTiming: () => ({ duration, delay })
            }
        };
    }

    it('returns null when the duration is zero or missing', () => {
        expect(getAnimationActiveTiming(timingAnimation({ duration: 0, currentTime: 100 }))).toBeNull();
        expect(getAnimationActiveTiming({})).toBeNull();
    });

    it('returns null when the current time is not finite', () => {
        expect(getAnimationActiveTiming(timingAnimation({ duration: 1000, currentTime: NaN }))).toBeNull();
    });

    it('computes the active elapsed time and progress', () => {
        const t = getAnimationActiveTiming(timingAnimation({ duration: 1000, currentTime: 250 }));
        expect(t).toEqual({ duration: 1000, activeElapsed: 250, progress: 0.25 });
    });

    it('subtracts the delay and clamps at zero before the active phase', () => {
        const t = getAnimationActiveTiming(timingAnimation({ duration: 1000, delay: 300, currentTime: 100 }));
        expect(t.activeElapsed).toBe(0);
        expect(t.progress).toBe(0);
    });

    it('clamps the active elapsed time at the duration', () => {
        const t = getAnimationActiveTiming(timingAnimation({ duration: 1000, currentTime: 5000 }));
        expect(t.activeElapsed).toBe(1000);
        expect(t.progress).toBe(1);
    });
});

describe('isResizeGeometryUnchanged', () => {
    const slot = { startX: 0, startY: 0, startZ: 0, endX: 100, endY: 50, endZ: 0, duration: 400 };

    it('returns false when there is no slot', () => {
        expect(isResizeGeometryUnchanged({}, null, 400)).toBe(false);
    });

    it('returns true when start/end/duration all match', () => {
        const cmd = { startX: 0, startY: 0, startZ: 0, endX: 100, endY: 50, endZ: 0, duration: 400 };
        expect(isResizeGeometryUnchanged(cmd, slot, 400)).toBe(true);
    });

    it('uses the old duration when the command has no animation baseline', () => {
        const cmd = { startX: 0, startY: 0, startZ: 0, endX: 100, endY: 50, endZ: 0, duration: 999, hasAnimationBaseline: false };
        expect(isResizeGeometryUnchanged(cmd, slot, 400)).toBe(true);
    });

    it('returns false when a coordinate differs', () => {
        const cmd = { startX: 0, startY: 0, startZ: 0, endX: 101, endY: 50, endZ: 0, duration: 400 };
        expect(isResizeGeometryUnchanged(cmd, slot, 400)).toBe(false);
    });
});

describe('isPerspectiveOriginGeometryUnchanged', () => {
    const slot = { startX: 10, startY: 20, endX: 80, endY: 90, unitX: '%', unitY: '%' };

    it('returns false when there is no slot', () => {
        expect(isPerspectiveOriginGeometryUnchanged({}, null, 400)).toBe(false);
    });

    it('returns false when the incoming unit differs from the slot units', () => {
        const cmd = { startX: 10, startY: 20, endX: 80, endY: 90, unit: 'px', duration: 400 };
        expect(isPerspectiveOriginGeometryUnchanged(cmd, slot, 400)).toBe(false);
    });

    it('returns true when the 2D geometry and duration match with the default unit', () => {
        const cmd = { startX: 10, startY: 20, endX: 80, endY: 90, duration: 400 };
        expect(isPerspectiveOriginGeometryUnchanged(cmd, slot, 400)).toBe(true);
    });

    it('returns false when a coordinate differs', () => {
        const cmd = { startX: 10, startY: 20, endX: 81, endY: 90, unit: '%', duration: 400 };
        expect(isPerspectiveOriginGeometryUnchanged(cmd, slot, 400)).toBe(false);
    });
});

describe('isSizeGeometryUnchanged', () => {
    const slot = { startWidth: 10, startHeight: 20, endWidth: 80, endHeight: 90, unitWidth: 'px', unitHeight: 'px' };

    it('returns false when there is no slot', () => {
        expect(isSizeGeometryUnchanged({}, null, 400)).toBe(false);
    });

    it('returns false when the incoming unit differs from the slot units', () => {
        const cmd = { startX: 10, startY: 20, endX: 80, endY: 90, unit: '%', duration: 400 };
        expect(isSizeGeometryUnchanged(cmd, slot, 400)).toBe(false);
    });

    it('returns true when the size geometry and duration match with the default unit', () => {
        const cmd = { startX: 10, startY: 20, endX: 80, endY: 90, duration: 400 };
        expect(isSizeGeometryUnchanged(cmd, slot, 400)).toBe(true);
    });

    it('returns false when a dimension differs', () => {
        const cmd = { startX: 10, startY: 21, endX: 80, endY: 90, unit: 'px', duration: 400 };
        expect(isSizeGeometryUnchanged(cmd, slot, 400)).toBe(false);
    });
});
