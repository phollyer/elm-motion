/* eslint-env node */
import { afterEach, describe, expect, it, vi } from 'vitest';
import ElmMotion from '../src/index.js';
import { createFakeAnimation, installDom, createPorts, cleanupDom } from './_publicApiHelpers.js';

afterEach(cleanupDom);


describe('ElmMotion public API', () => {
    it('subscribes to motionCmd and emits started for animate commands', async () => {
        const animGroup = 'box-started';
        const animation = createFakeAnimation();
        const element = {
            id: animGroup,
            animate: vi.fn(() => animation)
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(element.animate).toHaveBeenCalledTimes(1);
        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({
                        animGroup,
                        status: 'started',
                        progress: 0
                    })
                })
            ])
        );
    });

    it('emits propertyUpdate payloads during WAAPI animation frames', async () => {
        const animGroup = 'box-property-update';
        const animation = createFakeAnimation({ duration: 300 });
        animation.currentTime = 150;
        animation.playState = 'running';

        const element = {
            id: animGroup,
            animate: vi.fn(() => animation)
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        const rafCallback = global.requestAnimationFrame.mock.calls[0][0];
        rafCallback();

        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'propertyUpdate',
                    animGroup,
                    propertyProgress: expect.objectContaining({ opacity: 0.5 }),
                    progress: 0.5,
                    isAnimating: true
                })
            ])
        );
    });

    it('keys customColorProperty propertyVersions as customColor:<css> so Elm can read them (regression: WAAPI mid-flight color interrupt)', async () => {
        const animGroup = 'box-color-update';
        const animation = createFakeAnimation({ duration: 300 });
        animation.currentTime = 150;
        animation.playState = 'running';

        const element = {
            id: animGroup,
            animate: vi.fn(() => animation)
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'customColorProperty', cssProperty: 'background-color', startColor: 'rgb(0, 0, 0)', endColor: 'rgb(255, 0, 0)', duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        const rafCallback = global.requestAnimationFrame.mock.calls[0][0];
        rafCallback();

        const propertyUpdate = events.find((event) => event.type === 'propertyUpdate' && event.animGroup === animGroup);
        expect(propertyUpdate).toBeDefined();
        expect(propertyUpdate.propertyVersions).toEqual(
            expect.objectContaining({ 'customColor:background-color': 1 })
        );
        // Phase 4: JS emits raw per-property progress rather than absolute
        // interpolated color values. Elm interpolates from its anchored start
        // colour (snapshotted in the Generator) using this progress, so the
        // mid-flight interrupt regression is now covered by the propertyProgress
        // payload presence rather than a specific colour string.
        expect(propertyUpdate.propertyProgress).toEqual(
            expect.objectContaining({ 'customColor:background-color': 0.5 })
        );
    });

    it('emits completed, paused, resumed, and cancelled events for WAAPI commands', async () => {
        const animGroup = 'box-controls';
        const animation = createFakeAnimation({ duration: 400 });
        animation.currentTime = 200;

        const element = {
            id: animGroup,
            animate: vi.fn(() => animation)
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 400, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        await ports.send({ type: 'pause', elementId: animGroup });
        await ports.send({ type: 'resume', elementId: animGroup });
        animation.finish();

        const lifecycleStatuses = events
            .filter((event) => event.type === 'animationUpdate')
            .map((event) => event.payload?.status);

        expect(lifecycleStatuses).toEqual(
            expect.arrayContaining(['started', 'paused', 'resumed', 'completed'])
        );
        expect(animation.pauseCalls).toBe(1);
        expect(animation.playCalls).toBe(1);

        const secondAnimation = createFakeAnimation({ duration: 400 });
        element.animate.mockImplementationOnce(() => secondAnimation);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 1, endValue: 0, duration: 400, easing: 'linear', version: 2 }
                    ]
                }
            }
        });

        secondAnimation.cancel();

        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({
                        animGroup,
                        status: 'cancelled'
                    })
                })
            ])
        );
    });

    it('does not emit a cancelled event when retarget interrupts a running WAAPI animation', async () => {
        const animGroup = 'box-retarget-silent';
        const animation = createFakeAnimation({ duration: 400 });
        animation.currentTime = 200;

        const element = {
            id: animGroup,
            animate: vi.fn(() => animation)
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 400, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        await ports.send({
            type: 'retarget',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0.5, endValue: 0.5, duration: 0, easing: 'linear', version: 2 }
                    ]
                }
            }
        });

        const lifecycleStatuses = events
            .filter((event) => event.type === 'animationUpdate')
            .map((event) => event.payload?.status);

        expect(lifecycleStatuses).not.toContain('cancelled');
    });

    it('does not collapse next animate after reset on a completed transform animation', async () => {
        const animGroup = 'box-reset-then-animate';
        const firstAnimation = createFakeAnimation({ duration: 300 });
        const secondAnimation = createFakeAnimation({ duration: 300 });

        const animateSpy = vi.fn()
            .mockImplementationOnce(() => firstAnimation)
            .mockImplementationOnce(() => secondAnimation);

        const element = {
            id: animGroup,
            style: {},
            getAnimations: () => [],
            getAttribute: () => null,
            animate: animateSpy
        };
        installDom({ element, targetId: animGroup });

        const ports = createPorts(() => {});
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0,
                            startY: 0,
                            startZ: 0,
                            endX: 0,
                            endY: 88,
                            endZ: 0,
                            duration: 300,
                            easing: 'linear',
                            version: 1
                        }
                    ]
                }
            }
        });

        firstAnimation.finish();

        await ports.send({ type: 'reset', elementId: animGroup });

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0,
                            startY: 0,
                            startZ: 0,
                            endX: 0,
                            endY: 88,
                            endZ: 0,
                            duration: 300,
                            easing: 'linear',
                            version: 2
                        }
                    ]
                }
            }
        });

        expect(animateSpy).toHaveBeenCalledTimes(2);
        const secondCall = animateSpy.mock.calls[1];
        const keyframes = secondCall[0];

        expect(keyframes[0].transform).toContain('translate3d(0px, 0px, 0px)');
        expect(keyframes[keyframes.length - 1].transform).toContain('translate3d(0px, 88px, 0px)');
    });

    it('emits a single scroll-driven iteration event when all property animations complete the loop', async () => {
        const animGroup = 'box-scroll';
        const sourceId = 'source-scroll';
        const animations = [createFakeAnimation(), createFakeAnimation()];
        const element = {
            id: animGroup,
            animate: vi.fn(() => animations.shift())
        };
        installDom({ element, targetId: animGroup, sourceId });
        global.ScrollTimeline = class ScrollTimeline {
            constructor(config) {
                this.config = config;
            }
        };
        global.window.ScrollTimeline = global.ScrollTimeline;

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'scrollDriven',
            iterations: { type: 'times', count: 3 },
            timeline: { source: sourceId, axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear' },
                        { type: 'customColorProperty', cssProperty: 'color', startColor: 'rgb(0, 0, 0)', endColor: 'rgb(255, 0, 0)', duration: 300, easing: 'linear' }
                    ]
                }
            }
        });

        const createdAnimations = element.animate.mock.results.map((result) => result.value);
        createdAnimations[0].trigger('iteration');
        expect(events.filter((event) => event.payload?.status === 'iteration')).toHaveLength(0);

        createdAnimations[1].trigger('iteration');
        const iterationEvents = events.filter((event) => event.payload?.status === 'iteration');
        expect(iterationEvents).toHaveLength(1);
        expect(iterationEvents[0]).toEqual(
            expect.objectContaining({
                type: 'animationUpdate',
                engine: 'scrollTimeline',
                payload: expect.objectContaining({
                    animGroup,
                    progress: 1
                })
            })
        );
    });

    it('emits a synthetic started event each time a scroll-driven timeline enters range', async () => {
        const animGroup = 'box-scroll-start';
        const sourceId = 'source-scroll-start';
        const progressBox = { value: null };
        const buildAnimation = () => {
            const anim = createFakeAnimation();
            anim.effect.getComputedTiming = () => ({ progress: progressBox.value });
            return anim;
        };
        const animations = [buildAnimation(), buildAnimation()];
        const element = {
            id: animGroup,
            animate: vi.fn(() => animations.shift())
        };
        installDom({ element, targetId: animGroup, sourceId });
        global.ScrollTimeline = class ScrollTimeline {
            constructor(config) {
                this.config = config;
            }
        };
        global.window.ScrollTimeline = global.ScrollTimeline;

        // Capture rAF callbacks so the test can drive the watcher manually.
        const rafQueue = [];
        const rafFn = vi.fn((cb) => {
            rafQueue.push(cb);
            return rafQueue.length;
        });
        global.requestAnimationFrame = rafFn;
        global.window.requestAnimationFrame = rafFn;
        const tick = () => {
            const pending = rafQueue.splice(0);
            pending.forEach((cb) => cb());
        };

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'scrollDriven',
            iterations: { type: 'times', count: 3 },
            timeline: { source: sourceId, axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear' }
                    ]
                }
            }
        });

        const startedEvents = () =>
            events.filter((e) => e.type === 'animationUpdate' && e.payload?.status === 'started');

        // Out of range: watcher ticks but emits nothing.
        progressBox.value = null;
        tick();
        expect(startedEvents()).toHaveLength(0);

        // Entered range: started fires once with the entry progress.
        progressBox.value = 0.3;
        tick();
        expect(startedEvents()).toHaveLength(1);
        expect(startedEvents()[0]).toMatchObject({
            type: 'animationUpdate',
            engine: 'scrollTimeline',
            payload: { animGroup, status: 'started', progress: 0.3 }
        });

        // Still in range: no duplicate started.
        progressBox.value = 0.5;
        tick();
        expect(startedEvents()).toHaveLength(1);

        // Scrolled back out of range.
        progressBox.value = null;
        tick();
        expect(startedEvents()).toHaveLength(1);

        // Re-entered: another started event.
        progressBox.value = 0.1;
        tick();
        expect(startedEvents()).toHaveLength(2);
        expect(startedEvents()[1].payload.progress).toBe(0.1);
    });

    it('emits per-frame progress events while in range when emitProgress is enabled', async () => {
        const animGroup = 'box-scroll-progress';
        const sourceId = 'source-scroll-progress';
        const progressBox = { value: null };
        const buildAnimation = () => {
            const anim = createFakeAnimation();
            anim.effect.getComputedTiming = () => ({ progress: progressBox.value });
            return anim;
        };
        const animations = [buildAnimation()];
        const element = {
            id: animGroup,
            animate: vi.fn(() => animations.shift())
        };
        installDom({ element, targetId: animGroup, sourceId });
        global.ScrollTimeline = class ScrollTimeline {
            constructor(config) {
                this.config = config;
            }
        };
        global.window.ScrollTimeline = global.ScrollTimeline;

        const rafQueue = [];
        const rafFn = vi.fn((cb) => {
            rafQueue.push(cb);
            return rafQueue.length;
        });
        global.requestAnimationFrame = rafFn;
        global.window.requestAnimationFrame = rafFn;
        const tick = () => {
            const pending = rafQueue.splice(0);
            pending.forEach((cb) => cb());
        };

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'scrollDriven',
            emitProgress: true,
            iterations: { type: 'times', count: 1 },
            timeline: { source: sourceId, axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear' }
                    ]
                }
            }
        });

        const progressEvents = () =>
            events.filter((e) => e.type === 'animationUpdate' && e.payload?.status === 'progress');

        // Out of range: no progress events.
        progressBox.value = null;
        tick();
        expect(progressEvents()).toHaveLength(0);

        // Enter range: progress event fires every frame.
        progressBox.value = 0.25;
        tick();
        expect(progressEvents()).toHaveLength(1);
        expect(progressEvents()[0]).toMatchObject({
            type: 'animationUpdate',
            engine: 'scrollTimeline',
            payload: { animGroup, status: 'progress', progress: 0.25 }
        });

        progressBox.value = 0.6;
        tick();
        expect(progressEvents()).toHaveLength(2);
        expect(progressEvents()[1].payload.progress).toBe(0.6);

        // Out of range again: no further progress events.
        progressBox.value = null;
        tick();
        expect(progressEvents()).toHaveLength(2);
    });

    it('does not emit progress events when emitProgress is omitted', async () => {
        const animGroup = 'box-scroll-no-progress';
        const sourceId = 'source-scroll-no-progress';
        const progressBox = { value: null };
        const buildAnimation = () => {
            const anim = createFakeAnimation();
            anim.effect.getComputedTiming = () => ({ progress: progressBox.value });
            return anim;
        };
        const animations = [buildAnimation()];
        const element = {
            id: animGroup,
            animate: vi.fn(() => animations.shift())
        };
        installDom({ element, targetId: animGroup, sourceId });
        global.ScrollTimeline = class ScrollTimeline {
            constructor(config) {
                this.config = config;
            }
        };
        global.window.ScrollTimeline = global.ScrollTimeline;

        const rafQueue = [];
        const rafFn = vi.fn((cb) => {
            rafQueue.push(cb);
            return rafQueue.length;
        });
        global.requestAnimationFrame = rafFn;
        global.window.requestAnimationFrame = rafFn;
        const tick = () => {
            const pending = rafQueue.splice(0);
            pending.forEach((cb) => cb());
        };

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'scrollDriven',
            iterations: { type: 'times', count: 1 },
            timeline: { source: sourceId, axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear' }
                    ]
                }
            }
        });

        progressBox.value = 0.5;
        tick();

        const progressEvents = events.filter((e) => e.type === 'animationUpdate' && e.payload?.status === 'progress');
        expect(progressEvents).toHaveLength(0);
    });

    it('re-emits scroll-driven completed each time all member animations finish a pass', async () => {
        const animGroup = 'box-scroll-recompletes';
        const sourceId = 'source-scroll-recompletes';
        const buildAnimation = () => {
            const anim = createFakeAnimation();
            anim.effect.getComputedTiming = () => ({ progress: 1 });
            return anim;
        };
        const animations = [buildAnimation(), buildAnimation()];
        const element = {
            id: animGroup,
            animate: vi.fn(() => animations.shift())
        };
        installDom({ element, targetId: animGroup, sourceId });
        global.ScrollTimeline = class ScrollTimeline {
            constructor(config) {
                this.config = config;
            }
        };
        global.window.ScrollTimeline = global.ScrollTimeline;

        const rafQueue = [];
        const rafFn = vi.fn((cb) => {
            rafQueue.push(cb);
            return rafQueue.length;
        });
        global.requestAnimationFrame = rafFn;
        global.window.requestAnimationFrame = rafFn;
        const tick = () => {
            const pending = rafQueue.splice(0);
            pending.forEach((cb) => cb());
        };

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'scrollDriven',
            iterations: { type: 'times', count: 1 },
            timeline: { source: sourceId, axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear' },
                        { type: 'customColorProperty', cssProperty: 'color', startColor: 'rgb(0, 0, 0)', endColor: 'rgb(255, 0, 0)', duration: 300, easing: 'linear' }
                    ]
                }
            }
        });

        const createdAnimations = element.animate.mock.results.map((result) => result.value);
        const completedEvents = () =>
            events.filter((e) => e.type === 'animationUpdate' && e.payload?.status === 'completed');

        // First pass: both member animations finish → one completed event.
        createdAnimations.forEach((a) => a.finish());
        expect(completedEvents()).toHaveLength(1);

        // Triggering finish again without leaving the finished state must not
        // double-fire completed.
        createdAnimations.forEach((a) => a.finish());
        expect(completedEvents()).toHaveLength(1);

        // Simulate the user scrolling back into range: playState returns to
        // running. The rAF watcher should clear the per-pass flag.
        createdAnimations.forEach((a) => { a.playState = 'running'; });
        tick();

        // Second pass: finish fires again on the next forward crossing of the end.
        createdAnimations.forEach((a) => a.finish());
        expect(completedEvents()).toHaveLength(2);
    });

    it('emits view-driven lifecycle events through the public API', async () => {
        const animGroup = 'box-view';
        const animations = [createFakeAnimation(), createFakeAnimation()];
        const element = {
            id: animGroup,
            animate: vi.fn(() => animations.shift())
        };
        installDom({ element, targetId: animGroup });
        global.ViewTimeline = class ViewTimeline {
            constructor(config) {
                this.config = config;
            }
        };
        global.window.ViewTimeline = global.ViewTimeline;

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'viewDriven',
            iterations: { type: 'times', count: 2 },
            timeline: { axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear' },
                        { type: 'customColorProperty', cssProperty: 'color', startColor: 'rgb(0, 0, 0)', endColor: 'rgb(255, 0, 0)', duration: 300, easing: 'linear' }
                    ]
                }
            }
        });

        const createdAnimations = element.animate.mock.results.map((result) => result.value);
        createdAnimations.forEach((animation) => animation.finish());

        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'viewTimeline',
                    payload: expect.objectContaining({
                        animGroup,
                        status: 'completed',
                        progress: 1
                    })
                })
            ])
        );
    });

    it('merges per-element ViewTimeline ranges over the global timeline defaults', async () => {
        const globalRangeStart = 'cover 10%';
        const globalRangeEnd = 'exit 90%';
        const overrideRangeStart = 'entry 0%';
        const overrideRangeEnd = 'exit 50%';

        const elements = new Map();
        function registerElement(id) {
            const animation = createFakeAnimation();
            const element = {
                id,
                animate: vi.fn(() => animation)
            };
            elements.set(id, element);
            return element;
        }

        const firstElement = registerElement('section-a');
        const secondElement = registerElement('section-b');

        global.CSS = { escape: (value) => value };
        global.performance = { now: () => 100 };
        global.requestAnimationFrame = vi.fn(() => 1);
        global.cancelAnimationFrame = vi.fn();
        global.document = {
            documentElement: { id: 'document' },
            head: { appendChild() { } },
            createElement() {
                return {
                    setAttribute() { },
                    addEventListener() { },
                    onload: null,
                    onerror: null
                };
            },
            querySelector(selector) {
                const targetMatch = selector.match(/^\[data-anim-target="(.+)"\]$/);
                if (!targetMatch) return null;
                return elements.get(targetMatch[1]) || null;
            },
            querySelectorAll(selector) {
                const targetMatch = selector.match(/^\[data-anim-target="(.+)"\]$/);
                if (!targetMatch) return [];
                const element = elements.get(targetMatch[1]);
                return element ? [element] : [];
            },
            getElementById(id) {
                return elements.get(id) || null;
            }
        };
        global.window = {
            getComputedStyle() {
                return {
                    opacity: '0.4',
                    width: '100px',
                    height: '50px',
                    getPropertyValue(prop) {
                        if (prop === '--progress') return '12';
                        if (prop === 'color') return 'rgb(255, 255, 255)';
                        if (prop === 'background-color') return 'rgb(0, 0, 0)';
                        return '';
                    }
                };
            },
            ViewTimeline: class ViewTimeline {
                constructor(config) {
                    this.config = config;
                }
            }
        };
        global.ViewTimeline = global.window.ViewTimeline;

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'viewDriven',
            iterations: { type: 'times', count: 1 },
            timeline: { axis: 'block', rangeStart: globalRangeStart, rangeEnd: globalRangeEnd },
            elements: {
                'section-a': {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ],
                    rangeStart: overrideRangeStart,
                    rangeEnd: overrideRangeEnd
                },
                'section-b': {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(firstElement.animate).toHaveBeenCalledTimes(1);
        expect(secondElement.animate).toHaveBeenCalledTimes(1);

        const firstTiming = firstElement.animate.mock.calls[0][1];
        const secondTiming = secondElement.animate.mock.calls[0][1];

        expect(firstTiming).toEqual(
            expect.objectContaining({
                rangeStart: overrideRangeStart,
                rangeEnd: overrideRangeEnd
            })
        );
        expect(secondTiming).toEqual(
            expect.objectContaining({
                rangeStart: globalRangeStart,
                rangeEnd: globalRangeEnd
            })
        );
        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'viewTimeline',
                    payload: expect.objectContaining({
                        elementId: 'section-a',
                        animGroup: 'section-a',
                        status: 'run',
                        progress: 0
                    })
                }),
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'viewTimeline',
                    payload: expect.objectContaining({
                        elementId: 'section-b',
                        animGroup: 'section-b',
                        status: 'run',
                        progress: 0
                    })
                })
            ])
        );
        expect(events.filter((event) => event?.payload?.status !== 'run')).toEqual([]);
    });

    it('merges per-element discrete entry and exit settings over the timeline defaults', async () => {
        const root = globalThis;
        const elements = new Map();
        const sourceId = 'source-scroll-discrete';

        function registerElement(id, animation) {
            const element = {
                id,
                style: {},
                animate: vi.fn(() => animation)
            };
            elements.set(id, element);
            return element;
        }

        const firstAnimation = createFakeAnimation();
        const secondAnimation = createFakeAnimation();
        const firstElement = registerElement('section-a', firstAnimation);
        const secondElement = registerElement('section-b', secondAnimation);
        elements.set(sourceId, { id: sourceId });

        root.CSS = { escape: (value) => value };
        root.performance = { now: () => 100 };
        root.requestAnimationFrame = vi.fn(() => 1);
        root.cancelAnimationFrame = vi.fn();
        root.document = {
            documentElement: { id: 'document' },
            head: { appendChild() { } },
            createElement() {
                return {
                    setAttribute() { },
                    addEventListener() { },
                    onload: null,
                    onerror: null
                };
            },
            querySelector(selector) {
                const targetMatch = selector.match(/^\[data-anim-target="(.+)"\]$/);
                if (!targetMatch) return null;
                return elements.get(targetMatch[1]) || null;
            },
            querySelectorAll(selector) {
                const targetMatch = selector.match(/^\[data-anim-target="(.+)"\]$/);
                if (!targetMatch) return [];
                const element = elements.get(targetMatch[1]);
                return element ? [element] : [];
            },
            getElementById(id) {
                return elements.get(id) || null;
            }
        };
        root.window = {
            getComputedStyle() {
                return {
                    opacity: '0.4',
                    width: '100px',
                    height: '50px',
                    getPropertyValue(prop) {
                        if (prop === '--progress') return '12';
                        if (prop === 'color') return 'rgb(255, 255, 255)';
                        if (prop === 'background-color') return 'rgb(0, 0, 0)';
                        return '';
                    }
                };
            },
            ScrollTimeline: class ScrollTimeline {
                constructor(config) {
                    this.config = config;
                }
            }
        };
        root.ScrollTimeline = root.window.ScrollTimeline;

        const ports = createPorts(() => { });
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'scrollDriven',
            iterations: { type: 'times', count: 1 },
            timeline: { source: sourceId, axis: 'block' },
            discreteEntry: { display: 'block' },
            discreteExit: { display: { from: 'block', to: 'none' } },
            elements: {
                'section-a': {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ],
                    discreteEntry: { display: 'flex' },
                    discreteExit: { display: { from: 'flex', to: 'grid' } }
                },
                'section-b': {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(firstElement.style.display).toBe('flex');
        expect(secondElement.style.display).toBe('block');

        firstAnimation.finish();
        secondAnimation.finish();

        expect(firstElement.style.display).toBe('grid');
        expect(secondElement.style.display).toBe('none');
    });

    it('handles stop, reset, and restart commands through the public API', async () => {
        const elements = new Map();
        const sourceMap = new Map();
        global.CSS = { escape: (value) => value };
        global.performance = { now: () => 100 };
        global.requestAnimationFrame = vi.fn(() => 1);
        global.cancelAnimationFrame = vi.fn();
        global.document = {
            documentElement: { id: 'document' },
            head: { appendChild() { } },
            createElement() {
                return {
                    setAttribute() { },
                    addEventListener() { },
                    onload: null,
                    onerror: null
                };
            },
            querySelector(selector) {
                const targetMatch = selector.match(/^\[data-anim-target="(.+)"\]$/);
                if (!targetMatch) return null;
                return elements.get(targetMatch[1]) || sourceMap.get(targetMatch[1]) || null;
            },
            querySelectorAll(selector) {
                const targetMatch = selector.match(/^\[data-anim-target="(.+)"\]$/);
                if (!targetMatch) return [];
                const element = elements.get(targetMatch[1]);
                return element ? [element] : [];
            },
            getElementById(id) {
                return elements.get(id) || sourceMap.get(id) || null;
            }
        };
        global.window = {
            getComputedStyle() {
                return {
                    opacity: '0.4',
                    width: '100px',
                    height: '50px',
                    getPropertyValue(prop) {
                        if (prop === '--progress') return '12';
                        if (prop === 'color') return 'rgb(255, 255, 255)';
                        if (prop === 'background-color') return 'rgb(0, 0, 0)';
                        return '';
                    }
                };
            }
        };

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        const stoppedGroup = 'box-stop';
        const stoppedAnimation = createFakeAnimation({ duration: 250 });
        const stoppedElement = {
            id: stoppedGroup,
            animate: vi.fn(() => stoppedAnimation)
        };
        elements.set(stoppedGroup, stoppedElement);

        await ports.send({
            type: 'animate',
            elements: {
                [stoppedGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 250, easing: 'linear', version: 1 }
                    ]
                }
            }
        });
        await ports.send({ type: 'stop', elementId: stoppedGroup });

        const resetGroup = 'box-reset';
        const resetAnimation = createFakeAnimation({ duration: 250 });
        const resetElement = {
            id: resetGroup,
            animate: vi.fn(() => resetAnimation)
        };
        elements.set(resetGroup, resetElement);

        await ports.send({
            type: 'animate',
            elements: {
                [resetGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 250, easing: 'linear', version: 1 }
                    ]
                }
            }
        });
        await ports.send({ type: 'reset', elementId: resetGroup });

        const restartGroup = 'box-restart';
        const restartAnimation = createFakeAnimation({ duration: 250 });
        const restartElement = {
            id: restartGroup,
            animate: vi.fn(() => restartAnimation)
        };
        elements.set(restartGroup, restartElement);

        await ports.send({
            type: 'animate',
            elements: {
                [restartGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 250, easing: 'linear', version: 1 }
                    ]
                }
            }
        });
        await ports.send({ type: 'restart', elementId: restartGroup });

        expect(stoppedAnimation.finishCalls).toBeGreaterThanOrEqual(1);
        expect(resetAnimation.cancelCalls).toBeGreaterThanOrEqual(1);
        expect(restartAnimation.cancelCalls).toBeGreaterThanOrEqual(1);
        expect(restartAnimation.playCalls).toBeGreaterThanOrEqual(1);

        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({ animGroup: stoppedGroup, status: 'stopped' })
                }),
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({ animGroup: resetGroup, status: 'reset' })
                }),
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({ animGroup: restartGroup, status: 'restarted' })
                })
            ])
        );
    });

    it('setProperties sets inline styles and cancels existing animations', async () => {
        const animGroup = 'box-set-props';
        const animation = createFakeAnimation({ duration: 300 });
        const element = {
            id: animGroup,
            style: {},
            animate: vi.fn(() => animation),
            getAnimations: vi.fn(() => [animation])
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        await ports.send({
            type: 'setProperties',
            updates: [
                {
                    elementId: animGroup,
                    properties: {
                        opacity: 0.5,
                        x: 10, y: 20, z: 0,
                        scaleX: 1, scaleY: 1, scaleZ: 1,
                        rotateX: 0, rotateY: 0, rotateZ: 45,
                        skewX: 0, skewY: 0
                    }
                }
            ]
        });

        expect(animation.cancelCalls).toBeGreaterThanOrEqual(1);
        expect(element.style.opacity).toBe('0.5');
        expect(element.style.transform).toBeDefined();
    });

    it('runs animations on multiple elements sharing the same data-anim-target', async () => {
        const animGroup = 'box-multi';
        const animations = [createFakeAnimation({ duration: 200 }), createFakeAnimation({ duration: 200 })];
        const elements = [
            { id: animGroup + '__multi_0', animate: vi.fn(() => animations[0]) },
            { id: animGroup + '__multi_1', animate: vi.fn(() => animations[1]) }
        ];

        global.CSS = { escape: (value) => value };
        global.performance = { now: () => 100 };
        global.requestAnimationFrame = vi.fn(() => 1);
        global.cancelAnimationFrame = vi.fn();
        global.document = {
            documentElement: { id: 'document' },
            head: { appendChild() { } },
            createElement() {
                return { setAttribute() { }, addEventListener() { }, onload: null, onerror: null };
            },
            querySelector(selector) {
                if (selector === `[data-anim-target="${animGroup}"]`) return elements[0];
                return null;
            },
            querySelectorAll(selector) {
                if (selector === `[data-anim-target="${animGroup}"]`) return elements;
                return [];
            },
            getElementById() { return null; }
        };
        global.window = {
            getComputedStyle() {
                return {
                    opacity: '1',
                    width: '50px',
                    height: '50px',
                    getPropertyValue(prop) {
                        if (prop === 'color') return 'rgb(0,0,0)';
                        if (prop === 'background-color') return 'rgb(0,0,0)';
                        return '';
                    }
                };
            }
        };

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 200, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(elements[0].animate).toHaveBeenCalledTimes(1);
        expect(elements[1].animate).toHaveBeenCalledTimes(1);

        const startedEvents = events
            .filter((event) => event.type === 'animationUpdate' && event.payload?.status === 'started');
        expect(startedEvents).toHaveLength(2);

        const groups = startedEvents.map((event) => event.payload.animGroup);
        expect(groups).toContain(animGroup + '__multi_0');
        expect(groups).toContain(animGroup + '__multi_1');
    });

    it('treats deprecated setUpdateThrottle port command as unknown', async () => {
        const events = [];
        const errors = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);
        const offError = ElmMotion.onError((err, ctx) => errors.push({ err, ctx }));

        await ports.send({ type: 'setUpdateThrottle', intervalMs: 16 });
        expect(errors.some(e => e.ctx && e.ctx.code === 'COMMAND_TYPE_UNKNOWN')).toBe(true);

        offError();
    });
});
