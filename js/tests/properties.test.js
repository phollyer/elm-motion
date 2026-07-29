import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import {
    interpolateColor,
    buildSimplePropertyKeyframes,
    buildComplexPropertyKeyframes,
    buildPropertyKeyframes,
    resolveScrollDrivenTransformValues,
    resolveNonTransformValues,
    extractPropertyConfig,
    createPropertyAnimation
} from '../src/properties.js';
import { lastKnownPerspectiveOrigins, lastKnownTransforms } from '../src/state.js';

describe('interpolateColor', () => {
    it('returns the start color at progress 0', () => {
        const r = interpolateColor('rgb(0, 0, 0)', 'rgb(255, 255, 255)', 0);
        expect(r).toBe('rgba(0, 0, 0, 1)');
    });

    it('returns the end color at progress 1', () => {
        const r = interpolateColor('rgb(0, 0, 0)', 'rgb(255, 255, 255)', 1);
        expect(r).toBe('rgba(255, 255, 255, 1)');
    });

    it('interpolates rgb channels at the midpoint', () => {
        const r = interpolateColor('rgb(0, 0, 0)', 'rgb(100, 200, 50)', 0.5);
        expect(r).toBe('rgba(50, 100, 25, 1)');
    });

    it('interpolates rgba alpha channels', () => {
        const r = interpolateColor('rgba(0, 0, 0, 0)', 'rgba(0, 0, 0, 1)', 0.5);
        expect(r).toBe('rgba(0, 0, 0, 0.5)');
    });

    it('parses hex colors', () => {
        const r = interpolateColor('#000000', '#ffffff', 0.5);
        // 255 * 0.5 = 127.5 -> rounded to 128
        expect(r).toBe('rgba(128, 128, 128, 1)');
    });

    it('rounds rgb channels to integers', () => {
        const r = interpolateColor('rgb(0, 0, 0)', 'rgb(1, 1, 1)', 0.5);
        // 0.5 -> rounded to 1
        expect(r).toBe('rgba(1, 1, 1, 1)');
    });

    it('falls back to transparent black for unrecognised colors', () => {
        const r = interpolateColor('not-a-color', 'also-not', 0.5);
        expect(r).toBe('rgba(0, 0, 0, 1)');
    });
});

describe('buildSimplePropertyKeyframes', () => {
    it('builds opacity keyframes as strings', () => {
        const k = buildSimplePropertyKeyframes({ type: 'opacity', startValue: 0, endValue: 1 });
        expect(k).toEqual([{ opacity: '0' }, { opacity: '1' }]);
    });

    it('builds size keyframes with px units', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'size',
            startWidth: 10, startHeight: 20,
            endWidth: 30, endHeight: 40
        });
        expect(k).toEqual([
            { width: '10px', height: '20px' },
            { width: '30px', height: '40px' }
        ]);
    });

    it('builds customProperty keyframes with camelCased property name and unit', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'customProperty',
            cssProperty: 'border-radius',
            startValue: 0,
            endValue: 50,
            unit: 'px'
        });
        expect(k).toEqual([
            { borderRadius: '0px' },
            { borderRadius: '50px' }
        ]);
    });

    it('builds customColorProperty keyframes with raw color strings', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'customColorProperty',
            cssProperty: 'background-color',
            startColor: 'rgb(0, 0, 0)',
            endColor: 'rgb(255, 0, 0)'
        });
        expect(k).toEqual([
            { backgroundColor: 'rgb(0, 0, 0)' },
            { backgroundColor: 'rgb(255, 0, 0)' }
        ]);
    });

    it('builds perspectiveOrigin keyframes', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'perspectiveOrigin',
            startX: 0, startY: 0,
            endX: 100, endY: 100,
            unitX: '%', unitY: '%'
        });
        expect(k).toEqual([
            { perspectiveOrigin: '0% 0%' },
            { perspectiveOrigin: '100% 100%' }
        ]);
    });

    it('builds perspectiveOrigin keyframes with mixed per-axis units', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'perspectiveOrigin',
            startX: 0, startY: 0,
            endX: 100, endY: 50,
            unitX: '%', unitY: 'px'
        });
        expect(k).toEqual([
            { perspectiveOrigin: '0% 0px' },
            { perspectiveOrigin: '100% 50px' }
        ]);
    });

    it('builds size keyframes with mixed per-axis units', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'size',
            startWidth: 0, startHeight: 0,
            endWidth: 50, endHeight: 100,
            unitWidth: '%', unitHeight: 'px'
        });
        expect(k).toEqual([
            { width: '0%', height: '0px' },
            { width: '50%', height: '100px' }
        ]);
    });

    it('returns null for unknown property types', () => {
        expect(buildSimplePropertyKeyframes({ type: 'translate' })).toBeNull();
        expect(buildSimplePropertyKeyframes({ type: 'unknown' })).toBeNull();
    });
});

describe('buildComplexPropertyKeyframes', () => {
    it('emits one keyframe per easing keyframe entry for opacity', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'opacity', startValue: 0, endValue: 1 },
            [{ offset: 0, value: 0 }, { offset: 0.5, value: 0.5 }, { offset: 1, value: 1 }]
        );
        expect(k).toEqual([
            { offset: 0, opacity: '0' },
            { offset: 0.5, opacity: '0.5' },
            { offset: 1, opacity: '1' }
        ]);
    });

    it('emits per-keyframe size values', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'size', startWidth: 0, startHeight: 0, endWidth: 100, endHeight: 100 },
            [{ offset: 0, value: 0 }, { offset: 0.5, value: 0.5 }, { offset: 1, value: 1 }]
        );
        expect(k).toEqual([
            { offset: 0, width: '0px', height: '0px' },
            { offset: 0.5, width: '50px', height: '50px' },
            { offset: 1, width: '100px', height: '100px' }
        ]);
    });

    it('emits per-keyframe customProperty values with unit', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'customProperty', cssProperty: 'border-width', startValue: 0, endValue: 10, unit: 'px' },
            [{ offset: 0, value: 0 }, { offset: 0.25, value: 0.25 }, { offset: 1, value: 1 }]
        );
        expect(k).toEqual([
            { offset: 0, borderWidth: '0px' },
            { offset: 0.25, borderWidth: '2.5px' },
            { offset: 1, borderWidth: '10px' }
        ]);
    });

    it('emits per-keyframe interpolated colors for customColorProperty', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'customColorProperty', cssProperty: 'color', startColor: 'rgb(0, 0, 0)', endColor: 'rgb(100, 100, 100)' },
            [{ offset: 0, value: 0 }, { offset: 0.5, value: 0.5 }, { offset: 1, value: 1 }]
        );
        expect(k).toEqual([
            { offset: 0, color: 'rgba(0, 0, 0, 1)' },
            { offset: 0.5, color: 'rgba(50, 50, 50, 1)' },
            { offset: 1, color: 'rgba(100, 100, 100, 1)' }
        ]);
    });

    it('emits per-keyframe perspectiveOrigin values', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'perspectiveOrigin', startX: 0, startY: 0, endX: 100, endY: 100, unitX: '%', unitY: '%' },
            [{ offset: 0, value: 0 }, { offset: 0.5, value: 0.5 }, { offset: 1, value: 1 }]
        );
        expect(k).toEqual([
            { offset: 0, perspectiveOrigin: '0% 0%' },
            { offset: 0.5, perspectiveOrigin: '50% 50%' },
            { offset: 1, perspectiveOrigin: '100% 100%' }
        ]);
    });

    it('uses the sample offset (not the index) when offsets are non-uniform', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'opacity', startValue: 0, endValue: 1 },
            [{ offset: 0, value: 0 }, { offset: 0.3636, value: 0.75 }, { offset: 1, value: 1 }]
        );
        expect(k).toEqual([
            { offset: 0, opacity: '0' },
            { offset: 0.3636, opacity: '0.75' },
            { offset: 1, opacity: '1' }
        ]);
    });

    it('returns null for unknown property types', () => {
        expect(buildComplexPropertyKeyframes({ type: 'translate' }, [{ offset: 0, value: 0 }, { offset: 1, value: 1 }])).toBeNull();
    });
});

describe('buildPropertyKeyframes', () => {
    it('returns simple keyframes and a CSS easing string when no easingKeyframes are given', () => {
        const r = buildPropertyKeyframes({ type: 'opacity', startValue: 0, endValue: 1 }, undefined, 'ease-in');
        expect(r.keyframes).toEqual([{ opacity: '0' }, { opacity: '1' }]);
        expect(r.animationEasing).toBe('ease-in');
    });

    it('maps named easings to their cubic-bezier equivalents', () => {
        const r = buildPropertyKeyframes({ type: 'opacity', startValue: 0, endValue: 1 }, undefined, 'ease-in-cubic');
        expect(r.animationEasing).toBe('cubic-bezier(0.55, 0.055, 0.675, 0.19)');
    });

    it('passes through unknown easing strings verbatim', () => {
        const r = buildPropertyKeyframes({ type: 'opacity', startValue: 0, endValue: 1 }, undefined, 'cubic-bezier(0.1, 0.2, 0.3, 0.4)');
        expect(r.animationEasing).toBe('cubic-bezier(0.1, 0.2, 0.3, 0.4)');
    });

    it('builds complex keyframes and forces linear easing when easingKeyframes are given', () => {
        const r = buildPropertyKeyframes(
            { type: 'opacity', startValue: 0, endValue: 1 },
            [{ offset: 0, value: 0 }, { offset: 0.5, value: 0.5 }, { offset: 1, value: 1 }],
            'ease-in'
        );
        expect(r.keyframes).toEqual([
            { offset: 0, opacity: '0' },
            { offset: 0.5, opacity: '0.5' },
            { offset: 1, opacity: '1' }
        ]);
        expect(r.animationEasing).toBe('linear');
    });

    it('falls back to simple keyframes when complex builder returns null', () => {
        // 'translate' has no SIMPLE_KEYFRAME_BUILDERS entry, so simple build also returns null
        const r = buildPropertyKeyframes({ type: 'translate' }, [{ offset: 0, value: 0 }, { offset: 1, value: 1 }], 'linear');
        expect(r.keyframes).toBeNull();
        expect(r.animationEasing).toBe('linear');
    });
});

describe('resolveScrollDrivenTransformValues', () => {
    const currentTransform = {
        x: 0, y: 0, z: 0,
        scaleX: 1, scaleY: 1, scaleZ: 1,
        rotateX: 0, rotateY: 0, rotateZ: 0,
        skewX: 0, skewY: 0,
        translateUnitX: 'px', translateUnitY: 'px', translateUnitZ: 'px'
    };

    it('returns the current transform as both start and end when given no properties', () => {
        const { start, end } = resolveScrollDrivenTransformValues([], currentTransform);
        expect(start).toEqual(currentTransform);
        expect(end).toEqual(currentTransform);
    });

    it('defaults the base translate units to px when the current transform omits them', () => {
        const noUnits = { x: 0, y: 0, z: 0, scaleX: 1, scaleY: 1, scaleZ: 1, rotateX: 0, rotateY: 0, rotateZ: 0, skewX: 0, skewY: 0 };
        const { start, end } = resolveScrollDrivenTransformValues([], noUnits);
        expect(start.translateUnitX).toBe('px');
        expect(start.translateUnitY).toBe('px');
        expect(start.translateUnitZ).toBe('px');
        expect(end.translateUnitZ).toBe('px');
    });

    it('returns independent start and end objects (no shared reference)', () => {
        const { start, end } = resolveScrollDrivenTransformValues([], currentTransform);
        start.x = 99;
        expect(end.x).toBe(0);
    });

    it('applies a translate property to the end state on resolved axes', () => {
        const props = [{ type: 'translate', startX: 0, endX: 100, startY: 0, endY: 50, startZ: 0, endZ: 0 }];
        const { start, end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(start.x).toBe(0);
        expect(end.x).toBe(100);
        expect(end.y).toBe(50);
        expect(end.z).toBe(0);
    });

    it('applies a scale property to the end state', () => {
        const props = [{ type: 'scale', startX: 1, endX: 2, startY: 1, endY: 2, startZ: 1, endZ: 1 }];
        const { end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(end.scaleX).toBe(2);
        expect(end.scaleY).toBe(2);
        expect(end.scaleZ).toBe(1);
    });

    it('applies multiple transform properties together', () => {
        const props = [
            { type: 'translate', startX: 0, endX: 10, startY: 0, endY: 0, startZ: 0, endZ: 0 },
            { type: 'rotate', startX: 0, endX: 0, startY: 0, endY: 0, startZ: 0, endZ: 90 }
        ];
        const { end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(end.x).toBe(10);
        expect(end.rotateZ).toBe(90);
    });

    it('falls back to the current value when a translate axis omits start/end', () => {
        const seeded = { ...currentTransform, x: 7, y: 8, z: 9 };
        const props = [{ type: 'translate', endX: 100 }];
        const { start, end } = resolveScrollDrivenTransformValues(props, seeded);
        expect(start.x).toBe(7);
        expect(end.x).toBe(100);
        expect(end.y).toBe(8);
        expect(end.z).toBe(9);
    });

    it('resolves skew axes without a per-axis default, falling back to current', () => {
        const seeded = { ...currentTransform, skewX: 4, skewY: 5 };
        const props = [{ type: 'skew', endX: 30 }];
        const { start, end } = resolveScrollDrivenTransformValues(props, seeded);
        expect(start.skewX).toBe(4);
        expect(end.skewX).toBe(30);
        expect(end.skewY).toBe(5);
    });

    it('ignores properties of unknown type', () => {
        const props = [{ type: 'opacity', startValue: 0, endValue: 1 }];
        const { start, end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(start).toEqual(currentTransform);
        expect(end).toEqual(currentTransform);
    });

    it('overrides translate units on both start and end when provided', () => {
        const props = [{
            type: 'translate',
            startX: 0, endX: 10, startY: 0, endY: 20, startZ: 0, endZ: 30,
            unitX: '%', unitY: 'vh', unitZ: 'em'
        }];
        const { start, end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(start.translateUnitX).toBe('%');
        expect(end.translateUnitX).toBe('%');
        expect(start.translateUnitY).toBe('vh');
        expect(end.translateUnitY).toBe('vh');
        expect(start.translateUnitZ).toBe('em');
        expect(end.translateUnitZ).toBe('em');
    });

    it('keeps the current translate units when a translate omits them', () => {
        const props = [{ type: 'translate', startX: 0, endX: 10, startY: 0, endY: 0, startZ: 0, endZ: 0 }];
        const { start, end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(start.translateUnitX).toBe('px');
        expect(end.translateUnitX).toBe('px');
        expect(start.translateUnitY).toBe('px');
        expect(end.translateUnitY).toBe('px');
        expect(start.translateUnitZ).toBe('px');
        expect(end.translateUnitZ).toBe('px');
    });

    it('ignores empty-string translate units and keeps the current units', () => {
        const props = [{
            type: 'translate',
            startX: 0, endX: 10, startY: 0, endY: 0, startZ: 0, endZ: 0,
            unitX: '', unitY: '', unitZ: ''
        }];
        const { start, end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(start.translateUnitX).toBe('px');
        expect(end.translateUnitZ).toBe('px');
    });
});

describe('perspectiveOrigin keyframe unit defaults', () => {
    it('defaults simple perspectiveOrigin units to percent when omitted', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'perspectiveOrigin',
            startX: 0, startY: 0, endX: 100, endY: 100
        });
        expect(k).toEqual([
            { perspectiveOrigin: '0% 0%' },
            { perspectiveOrigin: '100% 100%' }
        ]);
    });

    it('defaults complex perspectiveOrigin units to percent when omitted', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'perspectiveOrigin', startX: 0, startY: 0, endX: 100, endY: 100 },
            [{ offset: 0, value: 0 }, { offset: 1, value: 1 }]
        );
        expect(k).toEqual([
            { offset: 0, perspectiveOrigin: '0% 0%' },
            { offset: 1, perspectiveOrigin: '100% 100%' }
        ]);
    });
});

describe('resolveNonTransformValues', () => {
    let computed;

    beforeEach(() => {
        lastKnownPerspectiveOrigins.clear();
        computed = {
            opacity: '0.4',
            width: '100px',
            height: '50px',
            perspectiveOrigin: '30% 70%',
            getPropertyValue(prop) {
                if (prop === '--foo') return '12';
                if (prop === 'color') return 'rgb(1, 2, 3)';
                return '';
            }
        };
        global.window = { getComputedStyle: () => computed };
    });

    afterEach(() => {
        delete global.window;
        lastKnownPerspectiveOrigins.clear();
    });

    it('returns null for an unknown property type', () => {
        expect(resolveNonTransformValues({}, {}, { type: 'translate' })).toBeNull();
    });

    it('uses the explicit opacity startValue when present', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'opacity', startValue: 0.2, endValue: 1 });
        expect(r).toEqual({ type: 'opacity', startValue: 0.2, endValue: 1 });
    });

    it('falls back to opacity defaultValue when startValue is absent', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'opacity', defaultValue: 0.9, endValue: 1 });
        expect(r.startValue).toBe(0.9);
    });

    it('falls back to computed opacity when both startValue and defaultValue are absent', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'opacity', endValue: 1 });
        expect(r.startValue).toBe(0.4);
    });

    it('resolves size from computed width/height when start dimensions are absent', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'size', endWidth: 200, endHeight: 100 });
        expect(r).toEqual({
            type: 'size',
            startWidth: 100, startHeight: 50,
            endWidth: 200, endHeight: 100,
            unitWidth: 'px', unitHeight: 'px'
        });
    });

    it('honours explicit size start dimensions and per-axis units', () => {
        const r = resolveNonTransformValues({}, {}, {
            type: 'size',
            startWidth: 5, startHeight: 6,
            endWidth: 9, endHeight: 9,
            unitWidth: '%', unitHeight: 'em'
        });
        expect(r.startWidth).toBe(5);
        expect(r.startHeight).toBe(6);
        expect(r.unitWidth).toBe('%');
        expect(r.unitHeight).toBe('em');
    });

    it('resolves customProperty start from the explicit value', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'customProperty', cssProperty: '--foo', startValue: 3, endValue: 20, unit: 'px' });
        expect(r.startValue).toBe(3);
    });

    it('resolves customProperty start from the computed value when absent', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'customProperty', cssProperty: '--foo', endValue: 20, unit: 'px' });
        expect(r.startValue).toBe(12);
    });

    it('falls back to 0 for a customProperty with no computed value', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'customProperty', cssProperty: '--missing', endValue: 20, unit: 'px' });
        expect(r.startValue).toBe(0);
    });

    it('resolves customColorProperty start from the explicit color', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'customColorProperty', cssProperty: 'color', startColor: 'rgb(5, 5, 5)', endColor: 'rgb(9, 9, 9)' });
        expect(r.startColor).toBe('rgb(5, 5, 5)');
    });

    it('resolves customColorProperty start from the computed color when absent', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'customColorProperty', cssProperty: 'color', endColor: 'rgb(9, 9, 9)' });
        expect(r.startColor).toBe('rgb(1, 2, 3)');
    });

    it('falls back to opaque black for a customColorProperty with no computed color', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'customColorProperty', cssProperty: 'background-color', endColor: 'rgb(9, 9, 9)' });
        expect(r.startColor).toBe('rgba(0, 0, 0, 1)');
    });

    it('resolves perspectiveOrigin from the computed origin with default percent units', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'perspectiveOrigin', endX: 80, endY: 90 });
        expect(r.startX).toBe(30);
        expect(r.startY).toBe(70);
        expect(r.unitX).toBe('%');
        expect(r.unitY).toBe('%');
    });

    it('honours explicit perspectiveOrigin start coordinates and units', () => {
        const r = resolveNonTransformValues({}, {}, { type: 'perspectiveOrigin', startX: 10, startY: 20, endX: 80, endY: 90, unitX: 'px', unitY: 'px' });
        expect(r.startX).toBe(10);
        expect(r.startY).toBe(20);
        expect(r.unitX).toBe('px');
    });

    it('mirrors a single-value computed perspectiveOrigin onto the Y axis', () => {
        computed.perspectiveOrigin = '40%';
        const r = resolveNonTransformValues({}, {}, { type: 'perspectiveOrigin', endX: 0, endY: 0 });
        expect(r.startX).toBe(40);
        expect(r.startY).toBe(40);
    });

    it('falls back to 50/50 for a non-numeric computed perspectiveOrigin', () => {
        computed.perspectiveOrigin = 'foo bar';
        const r = resolveNonTransformValues({}, {}, { type: 'perspectiveOrigin', endX: 0, endY: 0 });
        expect(r.startX).toBe(50);
        expect(r.startY).toBe(50);
    });

    it('falls back to the default origin string when the computed origin is empty', () => {
        computed.perspectiveOrigin = '';
        const r = resolveNonTransformValues({}, {}, { type: 'perspectiveOrigin', endX: 0, endY: 0 });
        expect(r.startX).toBe(50);
        expect(r.startY).toBe(50);
    });

    it('reuses the last-known perspectiveOrigin as the fallback on a matching follow-up resolve', () => {
        const animGroup = {};
        resolveNonTransformValues(animGroup, {}, { type: 'perspectiveOrigin', endX: 25, endY: 65, unitX: '%', unitY: '%' });
        const r = resolveNonTransformValues(animGroup, {}, { type: 'perspectiveOrigin', endX: 0, endY: 0, unitX: '%', unitY: '%' });
        expect(r.startX).toBe(25);
        expect(r.startY).toBe(65);
    });

    it('ignores the cached perspectiveOrigin when the units differ', () => {
        const animGroup = {};
        resolveNonTransformValues(animGroup, {}, { type: 'perspectiveOrigin', endX: 25, endY: 65, unitX: '%', unitY: '%' });
        const r = resolveNonTransformValues(animGroup, {}, { type: 'perspectiveOrigin', endX: 0, endY: 0, unitX: 'px', unitY: 'px' });
        expect(r.startX).toBe(30);
        expect(r.startY).toBe(70);
    });
});

describe('extractPropertyConfig', () => {
    let computed;

    beforeEach(() => {
        computed = {
            opacity: '0.4',
            width: '100px',
            height: '50px',
            getPropertyValue(prop) {
                if (prop === '--foo') return '12';
                if (prop === 'color') return 'rgb(1, 2, 3)';
                return '';
            }
        };
        global.window = { getComputedStyle: () => computed };
    });

    afterEach(() => {
        delete global.window;
    });

    it('leaves from/to empty for an unknown property type', () => {
        const config = extractPropertyConfig({}, {}, { type: 'mystery', duration: 100, easing: 'linear' });
        expect(config).toEqual({ property: 'mystery', duration: 100, easing: 'linear', from: '', to: '' });
    });

    it('builds translate config from cached transform state, falling back per axis', () => {
        const animGroup = {};
        lastKnownTransforms.set(animGroup, {
            x: 5, y: 6, z: 7,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0,
            translateUnitX: 'px', translateUnitY: 'px', translateUnitZ: 'px'
        });
        const config = extractPropertyConfig(animGroup, {}, { type: 'translate', startX: 1, endX: 2, duration: 100, easing: 'linear' });
        lastKnownTransforms.delete(animGroup);
        // startY/startZ absent -> current 6/7; endY/endZ absent -> current 6/7.
        expect(config.from).toBe('1,6,7');
        expect(config.to).toBe('2,6,7');
    });

    it('builds skew config without applying per-axis default values', () => {
        const animGroup = {};
        lastKnownTransforms.set(animGroup, {
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 1, skewY: 2,
            translateUnitX: 'px', translateUnitY: 'px', translateUnitZ: 'px'
        });
        const config = extractPropertyConfig(animGroup, {}, { type: 'skew', startX: 3, defaultX: 9, duration: 100, easing: 'linear' });
        lastKnownTransforms.delete(animGroup);
        // useDefault:false means defaultX is ignored; startY absent -> current 2.
        expect(config.from).toBe('3,2');
        expect(config.to).toBe('1,2');
    });

    it('builds opacity config from the computed value when start is absent', () => {
        const config = extractPropertyConfig({}, {}, { type: 'opacity', endValue: 1, duration: 100, easing: 'linear' });
        expect(config.from).toBe('0.4');
        expect(config.to).toBe('1');
    });

    it('builds opacity config from the explicit start value when present', () => {
        const config = extractPropertyConfig({}, {}, { type: 'opacity', startValue: 0.1, endValue: 1, duration: 100, easing: 'linear' });
        expect(config.from).toBe('0.1');
    });

    it('builds opacity config from the default value when only the default is present', () => {
        const config = extractPropertyConfig({}, {}, { type: 'opacity', defaultValue: 0.7, endValue: 1, duration: 100, easing: 'linear' });
        expect(config.from).toBe('0.7');
    });

    it('builds size config from computed dimensions with default units', () => {
        const config = extractPropertyConfig({}, {}, { type: 'size', endWidth: 200, endHeight: 100, duration: 100, easing: 'linear' });
        expect(config.from).toBe('100,50');
        expect(config.to).toBe('200,100');
        expect(config.unitWidth).toBe('px');
        expect(config.unitHeight).toBe('px');
    });

    it('builds size config from explicit start dimensions when present', () => {
        const config = extractPropertyConfig({}, {}, { type: 'size', startWidth: 12, startHeight: 34, endWidth: 200, endHeight: 100, duration: 100, easing: 'linear' });
        expect(config.from).toBe('12,34');
    });

    it('builds customProperty config with the css property name and unit', () => {
        const config = extractPropertyConfig({}, {}, { type: 'customProperty', cssProperty: '--foo', endValue: 20, unit: 'px', duration: 100, easing: 'linear' });
        expect(config.property).toBe('--foo');
        expect(config.from).toBe('12px');
        expect(config.to).toBe('20px');
    });

    it('builds customProperty config from the explicit start value when present', () => {
        const config = extractPropertyConfig({}, {}, { type: 'customProperty', cssProperty: '--foo', startValue: 3, endValue: 20, unit: 'px', duration: 100, easing: 'linear' });
        expect(config.from).toBe('3px');
    });

    it('builds customProperty config with a zero fallback when the computed value is empty', () => {
        const config = extractPropertyConfig({}, {}, { type: 'customProperty', cssProperty: '--missing', endValue: 20, unit: 'px', duration: 100, easing: 'linear' });
        expect(config.from).toBe('0px');
    });

    it('builds customColorProperty config falling back to the computed color', () => {
        const config = extractPropertyConfig({}, {}, { type: 'customColorProperty', cssProperty: 'color', endColor: 'rgb(9, 9, 9)', duration: 100, easing: 'linear' });
        expect(config.property).toBe('color');
        expect(config.from).toBe('rgb(1, 2, 3)');
        expect(config.to).toBe('rgb(9, 9, 9)');
    });

    it('builds customColorProperty config with the opaque-black fallback when the computed color is empty', () => {
        const config = extractPropertyConfig({}, {}, { type: 'customColorProperty', cssProperty: 'background-color', endColor: 'rgb(9, 9, 9)', duration: 100, easing: 'linear' });
        expect(config.from).toBe('rgba(0, 0, 0, 1)');
    });

    it('builds perspectiveOrigin config with default percent units', () => {
        const config = extractPropertyConfig({}, {}, { type: 'perspectiveOrigin', startX: 10, startY: 20, endX: 80, endY: 90, duration: 100, easing: 'linear' });
        expect(config.from).toBe('10% 20%');
        expect(config.to).toBe('80% 90%');
    });

    it('builds perspectiveOrigin config with explicit per-axis units', () => {
        const config = extractPropertyConfig({}, {}, { type: 'perspectiveOrigin', startX: 10, startY: 20, endX: 80, endY: 90, unitX: 'px', unitY: 'vh', duration: 100, easing: 'linear' });
        expect(config.from).toBe('10px 20vh');
        expect(config.to).toBe('80px 90vh');
    });
});

describe('createPropertyAnimation', () => {
    function fakeElement() {
        const calls = [];
        return {
            calls,
            animate(keyframes, options) {
                calls.push({ keyframes, options });
                return { keyframes, options };
            }
        };
    }

    beforeEach(() => {
        global.window = {};
    });

    afterEach(() => {
        delete global.window;
    });

    it('returns null when there is no resolved value', () => {
        expect(createPropertyAnimation(fakeElement(), null, { type: 'opacity' })).toBeNull();
    });

    it('returns null when no keyframes can be built', () => {
        const el = fakeElement();
        expect(createPropertyAnimation(el, { type: 'translate' }, { type: 'translate', duration: 100 })).toBeNull();
        expect(el.calls).toHaveLength(0);
    });

    it('uses fill "forwards" with no delay', () => {
        const el = fakeElement();
        createPropertyAnimation(el, { type: 'opacity', startValue: 0, endValue: 1 }, { type: 'opacity', duration: 100, easing: 'linear' });
        expect(el.calls).toHaveLength(1);
        expect(el.calls[0].options.fill).toBe('forwards');
        expect(el.calls[0].options.delay).toBe(0);
        expect(el.calls[0].options.duration).toBe(100);
    });

    it('uses fill "both" and the supplied delay when a delay is set', () => {
        const el = fakeElement();
        createPropertyAnimation(
            el,
            { type: 'opacity', startValue: 0, endValue: 1 },
            { type: 'opacity', duration: 100, delay: 50, easing: 'linear' },
            { iterations: 2, direction: 'alternate' }
        );
        expect(el.calls[0].options.fill).toBe('both');
        expect(el.calls[0].options.delay).toBe(50);
        expect(el.calls[0].options.iterations).toBe(2);
        expect(el.calls[0].options.direction).toBe('alternate');
    });
});
