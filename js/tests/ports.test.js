import { describe, expect, it } from 'vitest';
import { buildAnimatedPropertyData } from '../src/ports.js';

describe('buildAnimatedPropertyData', () => {
    it('wraps a propertyProgress dict under the propertyProgress key', () => {
        const propertyProgress = { translate: 0.5, rotate: 0.25 };
        expect(buildAnimatedPropertyData(propertyProgress)).toEqual({
            propertyProgress: { translate: 0.5, rotate: 0.25 }
        });
    });

    it('preserves an empty progress dict (Elm side falls back to baseline)', () => {
        expect(buildAnimatedPropertyData({})).toEqual({ propertyProgress: {} });
    });

    it('passes the supplied propertyProgress object through by reference', () => {
        const propertyProgress = { opacity: 0.75 };
        const wrapped = buildAnimatedPropertyData(propertyProgress);
        expect(wrapped.propertyProgress).toBe(propertyProgress);
    });
});
