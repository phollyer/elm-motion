/* eslint-env node */
/* global global */
import { afterEach, describe, expect, it, vi } from 'vitest';

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
