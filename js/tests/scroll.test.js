/* eslint-env node */
/* global global */
import { afterEach, describe, expect, it, vi } from 'vitest';
import { processScrollDrivenData, processViewDrivenData } from '../src/scroll.js';
import { onError, _resetSubscribers } from '../src/errors.js';
import { resetPortMissingWarning } from '../src/ports.js';
import { portsRef } from '../src/state.js';
import { installDom, createFakeAnimation, cleanupDom } from './_publicApiHelpers.js';

const POLYFILL_SPECIFIER = 'scroll-timeline-polyfill/dist/scroll-timeline.js';

/**
 * Load a fresh copy of scroll.js (and the errors.js instance it wires into)
 * after installing a per-test mock for the scroll-timeline polyfill. Each call
 * resets the module registry so scroll.js's module-scoped load-promise cache
 * does not leak between tests.
 *
 * @param {() => (object|void)} polyfillFactory - Mock factory for the polyfill
 *   dynamic import. It runs as an import side effect, mirroring the real
 *   polyfill IIFE that installs ScrollTimeline / ViewTimeline on `window`.
 */
async function loadScroll(polyfillFactory) {
    vi.resetModules();
    vi.doMock(POLYFILL_SPECIFIER, polyfillFactory);

    const scroll = await import('../src/scroll.js');
    const errors = await import('../src/errors.js');

    const reports = [];
    errors.onError((error, context) => reports.push({ error, context }));

    return { ensureTimelineApi: scroll.ensureTimelineApi, reports };
}

afterEach(() => {
    vi.doUnmock(POLYFILL_SPECIFIER);
    vi.resetModules();
    delete global.window;
    delete global.__polyfillLoads;
});

describe('ensureTimelineApi', () => {
    it('returns true without loading the polyfill when the API already exists', async () => {
        global.window = { ScrollTimeline: function () { } };

        const { ensureTimelineApi, reports } = await loadScroll(() => {
            global.__polyfillLoads = (global.__polyfillLoads || 0) + 1;
            return {};
        });

        await expect(ensureTimelineApi('ScrollTimeline')).resolves.toBe(true);
        expect(global.__polyfillLoads).toBeUndefined();
        expect(reports).toHaveLength(0);
    });

    it('loads the polyfill and returns true once it installs the API', async () => {
        global.window = {};

        const { ensureTimelineApi, reports } = await loadScroll(() => {
            global.window.ScrollTimeline = function () { };
            return {};
        });

        await expect(ensureTimelineApi('ScrollTimeline')).resolves.toBe(true);
        expect(reports).toHaveLength(0);
    });

    it('reports POLYFILL_LOAD_FAILED and returns false when the import throws', async () => {
        global.window = {};

        const { ensureTimelineApi, reports } = await loadScroll(() => {
            throw new Error('network down');
        });

        await expect(ensureTimelineApi('ScrollTimeline')).resolves.toBe(false);
        expect(reports).toHaveLength(1);
        expect(reports[0].context).toMatchObject({
            source: 'polyfill',
            severity: 'warning',
            code: 'POLYFILL_LOAD_FAILED',
            engine: 'ScrollTimeline'
        });
    });

    it('reports POLYFILL_API_MISSING and returns false when load succeeds but the API is still absent', async () => {
        global.window = {};

        const { ensureTimelineApi, reports } = await loadScroll(() => ({}));

        await expect(ensureTimelineApi('ScrollTimeline')).resolves.toBe(false);
        expect(reports).toHaveLength(1);
        expect(reports[0].context).toMatchObject({
            source: 'polyfill',
            severity: 'warning',
            code: 'POLYFILL_API_MISSING',
            engine: 'ScrollTimeline'
        });
    });

    it('honours the requested API name for ViewTimeline', async () => {
        global.window = {};

        const { ensureTimelineApi, reports } = await loadScroll(() => {
            global.window.ViewTimeline = function () { };
            return {};
        });

        await expect(ensureTimelineApi('ViewTimeline')).resolves.toBe(true);
        expect(reports).toHaveLength(0);
    });
});

describe('processScrollDrivenData / processViewDrivenData', () => {
    let reports;

    function captureReports() {
        reports = [];
        onError((error, context) => reports.push({ error, context }));
    }

    function codes() {
        return reports.map((report) => report.context && report.context.code);
    }

    afterEach(() => {
        _resetSubscribers();
        resetPortMissingWarning();
        portsRef.ports = null;
        cleanupDom();
    });

    describe('command validation', () => {
        it('reports COMMAND_INVALID for null scroll-driven data', () => {
            captureReports();

            processScrollDrivenData(null);

            expect(reports).toHaveLength(1);
            expect(reports[0].context).toMatchObject({
                source: 'scrollDriven',
                severity: 'warning',
                code: 'COMMAND_INVALID',
                engine: 'ScrollTimeline'
            });
        });

        it('reports COMMAND_INVALID when scroll-driven data omits elements', () => {
            captureReports();

            processScrollDrivenData({ timeline: { source: 'document' } });

            expect(codes()).toEqual(['COMMAND_INVALID']);
        });

        it('reports API_UNSUPPORTED when ScrollTimeline is absent', () => {
            captureReports();

            processScrollDrivenData({ elements: {} });

            expect(reports[0].context).toMatchObject({
                code: 'API_UNSUPPORTED',
                engine: 'ScrollTimeline'
            });
        });

        it('reports COMMAND_INVALID for null view-driven data', () => {
            captureReports();

            processViewDrivenData(null);

            expect(reports[0].context).toMatchObject({
                source: 'viewDriven',
                code: 'COMMAND_INVALID',
                engine: 'ViewTimeline'
            });
        });

        it('reports API_UNSUPPORTED when ViewTimeline is absent', () => {
            captureReports();

            processViewDrivenData({ elements: {} });

            expect(reports[0].context).toMatchObject({
                code: 'API_UNSUPPORTED',
                engine: 'ViewTimeline'
            });
        });
    });

    describe('source and target resolution', () => {
        it('reports SCROLL_SOURCE_NOT_FOUND and animates nothing when the source is missing', () => {
            captureReports();
            const element = { style: {}, animate: vi.fn(() => createFakeAnimation()) };
            installDom({ element, targetId: 'box' });
            global.ScrollTimeline = class {
                constructor(options) { this.options = options; }
            };

            processScrollDrivenData({
                timeline: { source: 'missing-source' },
                elements: { box: { properties: [] } }
            });

            expect(codes()).toContain('SCROLL_SOURCE_NOT_FOUND');
            expect(element.animate).not.toHaveBeenCalled();
        });

        it('reports TARGET_NOT_FOUND and skips the entry when the element target is missing', () => {
            captureReports();
            installDom({ element: { style: {}, animate: vi.fn() }, targetId: 'present-box' });
            global.ScrollTimeline = class {
                constructor(options) { this.options = options; }
            };

            processScrollDrivenData({
                timeline: { source: 'document' },
                elements: { ghost: { properties: [] } }
            });

            expect(codes()).toContain('TARGET_NOT_FOUND');
            expect(reports[0].context).toMatchObject({ elementId: 'ghost' });
        });
    });

    describe('happy paths', () => {
        it('animates a resolved target through ScrollTimeline and emits a run event', () => {
            const events = [];
            portsRef.ports = { motionMsg: { send: (event) => events.push(event) } };
            captureReports();
            const animation = createFakeAnimation();
            const element = { style: {}, animate: vi.fn(() => animation) };
            installDom({ element, targetId: 'box' });
            const timelineOptions = [];
            global.ScrollTimeline = class {
                constructor(options) { timelineOptions.push(options); }
            };

            processScrollDrivenData({
                timeline: { source: 'document', axis: 'block' },
                iterations: 1,
                emitProgress: true,
                elements: {
                    box: {
                        target: 'box',
                        properties: [
                            { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 },
                            { type: 'translate', startX: 0, endX: 100, easing: 'linear' }
                        ]
                    }
                }
            });

            // One animate for the non-transform (opacity) property and one for
            // the combined transform property.
            expect(element.animate).toHaveBeenCalledTimes(2);
            expect(timelineOptions[0]).toMatchObject({ source: global.document.documentElement, axis: 'block' });
            expect(events.length).toBeGreaterThan(0);
            expect(reports).toHaveLength(0);
        });

        it('honours a per-element emitProgress override over the command default', () => {
            portsRef.ports = { motionMsg: { send() { } } };
            captureReports();
            const element = { style: {}, animate: vi.fn(() => createFakeAnimation()) };
            installDom({ element, targetId: 'box' });
            global.ScrollTimeline = class {
                constructor(options) { this.options = options; }
            };

            processScrollDrivenData({
                timeline: { source: 'document' },
                emitProgress: false,
                elements: {
                    box: {
                        emitProgress: true,
                        properties: [
                            { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                        ]
                    }
                }
            });

            expect(element.animate).toHaveBeenCalledTimes(1);
            expect(reports).toHaveLength(0);
        });

        it('animates a resolved target through ViewTimeline with per-element range overrides', () => {
            portsRef.ports = { motionMsg: { send() { } } };
            captureReports();
            const element = { style: {}, animate: vi.fn(() => createFakeAnimation()) };
            installDom({ element, targetId: 'box' });
            const timelineOptions = [];
            global.ViewTimeline = class {
                constructor(options) { timelineOptions.push(options); }
            };

            processViewDrivenData({
                timeline: { axis: 'block', rangeStart: 'cover 0%', rangeEnd: 'cover 100%' },
                elements: {
                    box: {
                        target: 'box',
                        rangeEnd: 'contain 100%',
                        properties: [
                            { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                        ]
                    }
                }
            });

            expect(element.animate).toHaveBeenCalledTimes(1);
            expect(timelineOptions[0]).toMatchObject({ subject: element, axis: 'block' });
            const [, timingOptions] = element.animate.mock.calls[0];
            expect(timingOptions).toMatchObject({ rangeStart: 'cover 0%', rangeEnd: 'contain 100%' });
            expect(reports).toHaveLength(0);
        });
    });
});
