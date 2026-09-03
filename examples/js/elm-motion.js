var ElmMotion = (function (exports) {
    'use strict';

    // Pure utility functions — no browser globals, no DOM access, no side effects.

    /** Default CSS transform property order. */
    const DEFAULT_TRANSFORM_ORDER = ['translate', 'rotate', 'skew', 'scale'];

    /** CSS easing function map: Elm name → WAAPI CSS value. */
    const easingFunctions = {
        'linear': 'linear',
        'ease': 'ease',
        'ease-in': 'ease-in',
        'ease-out': 'ease-out',
        'ease-in-out': 'ease-in-out',
        'ease-in-cubic': 'cubic-bezier(0.55, 0.055, 0.675, 0.19)',
        'ease-out-cubic': 'cubic-bezier(0.215, 0.61, 0.355, 1)',
        'ease-in-out-cubic': 'cubic-bezier(0.645, 0.045, 0.355, 1)',
        'ease-in-back': 'cubic-bezier(0.6, -0.28, 0.735, 0.045)',
        'ease-out-back': 'cubic-bezier(0.175, 0.885, 0.32, 1.275)',
        'ease-in-out-back': 'cubic-bezier(0.68, -0.55, 0.265, 1.55)'
    };

    /**
     * Returns true if the property type is a CSS transform sub-property.
     * @param {string} type
     */
    function isTransformProperty(type) {
        return type === 'translate' || type === 'scale' || type === 'rotate' || type === 'skew';
    }

    /**
     * Parse an Elm iterations config object to a WAAPI iterations value.
     * @param {object|undefined} iterations
     * @returns {number}
     */
    function parseIterations(iterations) {
        if (!iterations) return 1;
        switch (iterations.type) {
            case 'infinite': return Infinity;
            case 'times': return iterations.count;
            case 'once':
            default: return 1;
        }
    }

    /**
     * Convert a kebab-case CSS property name to camelCase for WAAPI keyframes.
     * e.g. "border-radius" → "borderRadius"
     * @param {string} str
     */
    function camelCase(str) {
        return str.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
    }

    /**
     * Slowest-wins group iteration tracking.
     * Each property updates its own slot in perAnimIterations. The group iteration
     * event fires only when ALL properties have completed the same loop
     * (i.e. Math.min of all slots advances past storedCount).
     * @param {number[]} perAnimIterations - Per-property iteration slots (mutated)
     * @param {number} propertyIndex - Index of the updating property
     * @param {number|undefined} currentIteration - Current iteration from WAAPI timing
     * @param {number} storedCount - Last emitted iteration count
     * @returns {number|null} New group iteration count, or null if unchanged
     */
    function updateGroupIteration(perAnimIterations, propertyIndex, currentIteration, storedCount) {
        if (currentIteration == null || propertyIndex < 0 || propertyIndex >= perAnimIterations.length) {
            return null;
        }
        perAnimIterations[propertyIndex] = currentIteration;
        const minIteration = Math.min.apply(null, perAnimIterations);
        return minIteration > storedCount ? minIteration : null;
    }

    // Shared mutable state for all animation tracking.

    // Active WAAPI animations per animation group.
    // Map<animGroup, Map<propertyType, { animation, version, updateFn, animGroup, ... }>>
    const activeAnimations = new Map();

    // Animation group lifecycle tracking.
    // Map<animGroup, { totalProperties, completedProperties, started, generation,
    //                  nextPropertyIndex, lastIteration, propertyIterations,
    //                  propertyConfigs, throttleIntervalMs }>
    const animationGroups = new Map();

    // Last-known correct transform values per animation group (in original CSS units).
    // Avoids matrix decomposition normalisation (360° → 0°, 270° → -90°).
    // Map<animGroup, { x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY }>
    const lastKnownTransforms = new Map();

    // Last-known perspectiveOrigin end values per animation group in original units.
    // commitStyles() bakes resolved pixels into inline style, causing unit mismatch.
    // Map<animGroup, { x: number, y: number, unit: string }>
    const lastKnownPerspectiveOrigins = new Map();

    // Group-level iteration counts for scroll-driven animations.
    // Deduplicates iteration events: N properties fire N native events per loop, we emit one.
    // Map<animGroup, number>
    const scrollDrivenIterationCounts = new Map();

    // Per-element transform order for consistent CSS transform rendering.
    // Map<animGroup, string[]>  e.g. ['translate', 'rotate', 'skew', 'scale']
    const elementTransformOrders = new Map();

    // Per-element `will-change` values applied by the engine so they can be
    // reverted on completion / cancel. Set only when Elm derives a non-empty
    // `willChange` string for an element. Scroll-driven animations seed this
    // once at start and intentionally never clear it (the optimisation must
    // persist for the lifetime of the scroll interaction); time-driven
    // animations clear it via `cleanupAnimGroup`.
    // Map<animGroup, { element: HTMLElement, value: string }>
    const appliedWillChange = new Map();

    // Reference to the Elm app's ports object, set by init() in index.js.
    // Module-scoped instead of window-scoped to avoid global pollution and
    // silent collisions with host code that already uses `window.app`.
    // { ports: object | null }
    const portsRef = { ports: null };

    /**
     * Drop per-`animGroup` runtime entries when an animation lifecycle ends.
     *
     * `lastKnownTransforms` is intentionally NOT cleared here. WAAPI/cached
     * transform continuity depends on preserving the previous end state across
     * sequential animations in the same group (e.g. rotate 360 -> rotate 0).
     * If this cache is cleared on every completion, equivalent-angle endpoints
     * collapse to identity and the next animation can become a no-op.
     *
     * `lastKnownPerspectiveOrigins` is intentionally NOT cleared here. CSS
     * `getComputedStyle(...).perspectiveOrigin` always reports pixels, so once
     * the cached unit is gone we cannot tell whether the user originally chose
     * `%` or `px`. Without that, the runtime baseline reported back to Elm
     * after an animation finishes would silently switch to pixels, causing the
     * next animation to be encoded with mismatched start (px) and end (%) values.
     * The entry is keyed by user-supplied `animGroup` and overwritten on every
     * resolve, so retention across cleanup does not leak.
     */
    function cleanupAnimGroup(animGroup) {
        const wc = appliedWillChange.get(animGroup);
        if (wc && wc.element && wc.element.isConnected) {
            try {
                wc.element.style.willChange = '';
            } catch (_) {
                // Element may have been detached or styles frozen; safe to ignore.
            }
        }
        appliedWillChange.delete(animGroup);
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);
        scrollDrivenIterationCounts.delete(animGroup);
        elementTransformOrders.delete(animGroup);
    }

    /**
     * Clear every Map. Called by `dispose()` when the host Elm app is being
     * torn down (typical SPA teardown / hot-reload).
     */
    function clearAllState() {
        activeAnimations.clear();
        animationGroups.clear();
        lastKnownTransforms.clear();
        lastKnownPerspectiveOrigins.clear();
        scrollDrivenIterationCounts.clear();
        elementTransformOrders.clear();
        appliedWillChange.clear();
    }

    /* eslint-env browser */
    /* global window */

    /**
     * Get the default identity transform state (no translation, no rotation, unit scale).
     * Used as a fallback when no prior transform state is known.
     */
    function getDefaultTransformState() {
        return {
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0,
            translateUnitX: 'px', translateUnitY: 'px', translateUnitZ: 'px'
        };
    }

    /**
     * Ensure transform state is complete and numeric.
     * Guards against partial cached objects (missing skew fields) and NaN values.
     */
    function normalizeTransformState(state) {
        const defaults = getDefaultTransformState();
        const source = state || defaults;

        const num = (value, fallback) => Number.isFinite(value) ? value : fallback;

        return {
            x: num(source.x, defaults.x),
            y: num(source.y, defaults.y),
            z: num(source.z, defaults.z),
            scaleX: num(source.scaleX, defaults.scaleX),
            scaleY: num(source.scaleY, defaults.scaleY),
            scaleZ: num(source.scaleZ, defaults.scaleZ),
            rotateX: num(source.rotateX, defaults.rotateX),
            rotateY: num(source.rotateY, defaults.rotateY),
            rotateZ: num(source.rotateZ, defaults.rotateZ),
            skewX: num(source.skewX, defaults.skewX),
            skewY: num(source.skewY, defaults.skewY),
            translateUnitX: typeof source.translateUnitX === 'string' ? source.translateUnitX : defaults.translateUnitX,
            translateUnitY: typeof source.translateUnitY === 'string' ? source.translateUnitY : defaults.translateUnitY,
            translateUnitZ: typeof source.translateUnitZ === 'string' ? source.translateUnitZ : defaults.translateUnitZ
        };
    }

    /**
     * Get the current transform state for an element, preferring cached values from
     * lastKnownTransforms over DOM reads via getCurrentTransform().
     * This avoids matrix decomposition normalisation that loses angle information.
     */
    function getTransformState(animGroup, element) {
        const cached = lastKnownTransforms.get(animGroup);
        if (cached) {
            return normalizeTransformState(cached);
        }
        return normalizeTransformState(getCurrentTransform(element));
    }

    /**
     * Get the stored transform order for a DOM element.
     */
    function getElementOrder(element) {
        const id = element.getAttribute('data-anim-target') || element.id;
        return elementTransformOrders.get(id) || DEFAULT_TRANSFORM_ORDER;
    }

    /**
     * Build a complete transform string with 3D support.
     * The order parameter controls the order of translate, rotate, and scale
     * in the output string. Rotation axes are always applied X → Y → Z within
     * the rotate group.
     *
     * `forceGroups` (optional Set or Array of `'translate'|'rotate'|'scale'|'skew'`)
     * forces the listed groups to emit *all* their axis functions even when the
     * values are at identity (e.g. `rotateX(0deg)`). This is required when
     * building WAAPI keyframes: every keyframe in an animation must list the same
     * set of transform functions or the browser falls back to matrix3d
     * interpolation, which decomposes rotations into a matrix and silently drops
     * any rotation that lands on an identity matrix at either endpoint.
     */
    function buildTransformString(x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY, order, forceGroups, translateUnitX, translateUnitY, translateUnitZ) {
        const asNumber = (value, fallback) => Number.isFinite(value) ? value : fallback;
        const tx = asNumber(x, 0);
        const ty = asNumber(y, 0);
        const tz = asNumber(z, 0);
        const sx = asNumber(scaleX, 1);
        const sy = asNumber(scaleY, 1);
        const sz = asNumber(scaleZ, 1);
        const rx = asNumber(rotateX, 0);
        const ry = asNumber(rotateY, 0);
        const rz = asNumber(rotateZ, 0);
        const kx = asNumber(skewX, 0);
        const ky = asNumber(skewY, 0);
        const asUnit = u => (typeof u === 'string' && u.length > 0 ? u : 'px');
        const tUx = asUnit(translateUnitX);
        const tUy = asUnit(translateUnitY);
        const tUz = asUnit(translateUnitZ);

        const transformOrder = order || DEFAULT_TRANSFORM_ORDER;
        const force = forceGroups instanceof Set
            ? forceGroups
            : (Array.isArray(forceGroups) ? new Set(forceGroups) : null);
        const isForced = group => force !== null && force.has(group);
        const parts = [];

        for (const group of transformOrder) {
            switch (group) {
                case 'translate':
                    if (isForced('translate')) {
                        parts.push(`translate3d(${tx}${tUx}, ${ty}${tUy}, ${tz}${tUz})`);
                    } else if (tx !== 0 || ty !== 0 || tz !== 0) {
                        parts.push(`translate3d(${tx}${tUx}, ${ty}${tUy}, ${tz}${tUz})`);
                    }
                    break;
                case 'rotate':
                    if (isForced('rotate')) {
                        parts.push(`rotateX(${rx}deg)`);
                        parts.push(`rotateY(${ry}deg)`);
                        parts.push(`rotateZ(${rz}deg)`);
                    } else {
                        if (rx !== 0) {
                            parts.push(`rotateX(${rx}deg)`);
                        }
                        if (ry !== 0) {
                            parts.push(`rotateY(${ry}deg)`);
                        }
                        if (rz !== 0) {
                            parts.push(`rotateZ(${rz}deg)`);
                        }
                    }
                    break;
                case 'skew':
                    if (isForced('skew')) {
                        parts.push(`skewX(${kx}deg)`);
                        parts.push(`skewY(${ky}deg)`);
                    } else {
                        if (kx !== 0) {
                            parts.push(`skewX(${kx}deg)`);
                        }
                        if (ky !== 0) {
                            parts.push(`skewY(${ky}deg)`);
                        }
                    }
                    break;
                case 'scale':
                    if (isForced('scale')) {
                        parts.push(`scaleX(${sx})`);
                        parts.push(`scaleY(${sy})`);
                        parts.push(`scaleZ(${sz})`);
                    } else {
                        if (sx !== 1) {
                            parts.push(`scaleX(${sx})`);
                        }
                        if (sy !== 1) {
                            parts.push(`scaleY(${sy})`);
                        }
                        if (sz !== 1) {
                            parts.push(`scaleZ(${sz})`);
                        }
                    }
                    break;
            }
        }

        return parts.join(' ') || 'none';
    }

    /**
     * Parse a CSS transform string (e.g. "translate3d(10px, 20px, 30px) rotateY(90deg)")
     * into individual transform components. This preserves axis-specific values that
     * are lost when the browser computes a matrix3d.
     */
    function parseTransformString(transformStr) {
        const result = {
            transform: transformStr,
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0,
            translateUnitX: 'px', translateUnitY: 'px', translateUnitZ: 'px'
        };

        // Length units supported on translate values. Mirrors `Anim.Internal.Unit`.
        const UNIT_PATTERN = '(?:px|%|vw|vh|dvw|dvh|svw|svh|lvw|lvh|rem|em|cqi|cqb|cqw|cqh|cqmin|cqmax)';

        // translate3d(X<unit>, Y<unit>, Z<unit>) — capture each axis's unit independently.
        const translate3dRe = new RegExp(
            `translate3d\\(\\s*([-\\d.]+)(${UNIT_PATTERN})\\s*,\\s*([-\\d.]+)(${UNIT_PATTERN})\\s*,\\s*([-\\d.]+)(${UNIT_PATTERN})\\s*\\)`
        );
        const translate3d = transformStr.match(translate3dRe);
        if (translate3d) {
            result.x = parseFloat(translate3d[1]);
            result.y = parseFloat(translate3d[3]);
            result.z = parseFloat(translate3d[5]);
            result.translateUnitX = translate3d[2];
            result.translateUnitY = translate3d[4];
            result.translateUnitZ = translate3d[6];
        }

        // translateX(X<unit>), translateY(Y<unit>), translateZ(Z<unit>)
        const translateAxisRe = unit => new RegExp(`translate${unit}\\(\\s*([-\\d.]+)(${UNIT_PATTERN})\\s*\\)`);
        const translateX = transformStr.match(translateAxisRe('X'));
        const translateY = transformStr.match(translateAxisRe('Y'));
        const translateZ = transformStr.match(translateAxisRe('Z'));
        if (translateX) { result.x = parseFloat(translateX[1]); result.translateUnitX = translateX[2]; }
        if (translateY) { result.y = parseFloat(translateY[1]); result.translateUnitY = translateY[2]; }
        if (translateZ) { result.z = parseFloat(translateZ[1]); result.translateUnitZ = translateZ[2]; }

        // rotateX(Xdeg), rotateY(Ydeg), rotateZ(Zdeg)
        const rotateX = transformStr.match(/rotateX\(\s*([-\d.]+)deg\s*\)/);
        const rotateY = transformStr.match(/rotateY\(\s*([-\d.]+)deg\s*\)/);
        const rotateZ = transformStr.match(/rotateZ\(\s*([-\d.]+)deg\s*\)/);
        if (rotateX) result.rotateX = parseFloat(rotateX[1]);
        if (rotateY) result.rotateY = parseFloat(rotateY[1]);
        if (rotateZ) result.rotateZ = parseFloat(rotateZ[1]);

        // skewX(Xdeg), skewY(Ydeg)
        const skewX = transformStr.match(/skewX\(\s*([-\d.]+)deg\s*\)/);
        const skewY = transformStr.match(/skewY\(\s*([-\d.]+)deg\s*\)/);
        if (skewX) result.skewX = parseFloat(skewX[1]);
        if (skewY) result.skewY = parseFloat(skewY[1]);

        // skew(Xdeg, Ydeg) - 2D shorthand
        const skew2d = transformStr.match(/skew\(\s*([-\d.]+)deg\s*(?:,\s*([-\d.]+)deg\s*)?\)/);
        if (skew2d && !skewX && !skewY) {
            result.skewX = parseFloat(skew2d[1]);
            result.skewY = skew2d[2] ? parseFloat(skew2d[2]) : 0;
        }

        // scale3d(X, Y, Z)
        const scale3d = transformStr.match(/scale3d\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)/);
        if (scale3d) {
            result.scaleX = parseFloat(scale3d[1]);
            result.scaleY = parseFloat(scale3d[2]);
            result.scaleZ = parseFloat(scale3d[3]);
        }

        // scaleX(X), scaleY(Y), scaleZ(Z)
        const scaleX = transformStr.match(/scaleX\(\s*([-\d.]+)\s*\)/);
        const scaleY = transformStr.match(/scaleY\(\s*([-\d.]+)\s*\)/);
        const scaleZ = transformStr.match(/scaleZ\(\s*([-\d.]+)\s*\)/);
        if (scaleX) result.scaleX = parseFloat(scaleX[1]);
        if (scaleY) result.scaleY = parseFloat(scaleY[1]);
        if (scaleZ) result.scaleZ = parseFloat(scaleZ[1]);

        // scale(X, Y) - 2D shorthand
        const scale2d = transformStr.match(/scale\(\s*([-\d.]+)\s*(?:,\s*([-\d.]+)\s*)?\)/);
        if (scale2d && !scale3d) {
            result.scaleX = parseFloat(scale2d[1]);
            result.scaleY = scale2d[2] ? parseFloat(scale2d[2]) : parseFloat(scale2d[1]);
        }

        return result;
    }

    /**
     * Get current transform state of an element with 3D support.
     * When a WAAPI animation is active, uses getComputedStyle which reflects the
     * real animated values (including the WAAPI compositing layer). When no animation
     * is running, falls back to reading the inline style which preserves committed
     * final values with individual transform functions (rotateX, rotateY, etc.).
     */
    function getCurrentTransform(element) {
        // Check if this element has active WAAPI animations.
        // If so, getComputedStyle reflects the real animated state (including the
        // WAAPI layer), while inline style only has the optimistic end values from Elm.
        const hasActiveAnimation = element.getAnimations && element.getAnimations().length > 0;

        if (!hasActiveAnimation) {
            // No WAAPI animation running - parse inline style which preserves
            // individual transform functions (rotateX, rotateY, etc.) from commitStyles
            const inlineTransform = element.style.transform;
            if (inlineTransform && inlineTransform !== 'none') {
                return parseTransformString(inlineTransform);
            }
        }

        // Use computed style - this reflects the actual animated transform
        const style = window.getComputedStyle(element);
        const transform = style.transform;

        if (transform === 'none' || !transform) {
            return {
                transform: 'none',
                x: 0, y: 0, z: 0,
                scaleX: 1, scaleY: 1, scaleZ: 1,
                rotateX: 0, rotateY: 0, rotateZ: 0,
                skewX: 0, skewY: 0
            };
        }

        // Parse transform matrix (2D or 3D)
        const matrix2d = transform.match(/matrix\((.+)\)/);
        const matrix3d = transform.match(/matrix3d\((.+)\)/);

        if (matrix3d) {
            const values = matrix3d[1].split(', ').map(parseFloat);

            if (values.length === 16) {
                const tx = values[12] || 0;
                const ty = values[13] || 0;
                const tz = values[14] || 0;

                // Extract scale from column vector lengths
                const scaleX = Math.sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2]);
                const scaleY = Math.sqrt(values[4] * values[4] + values[5] * values[5] + values[6] * values[6]);
                const scaleZ = Math.sqrt(values[8] * values[8] + values[9] * values[9] + values[10] * values[10]);

                // Extract rotation matrix by dividing out scale
                const r00 = scaleX !== 0 ? values[0] / scaleX : 0;
                const r10 = scaleX !== 0 ? values[1] / scaleX : 0;
                const r20 = scaleX !== 0 ? values[2] / scaleX : 0;
                const r01 = scaleY !== 0 ? values[4] / scaleY : 0;
                const r11 = scaleY !== 0 ? values[5] / scaleY : 0;
                const r21 = scaleY !== 0 ? values[6] / scaleY : 0;
                const r22 = scaleZ !== 0 ? values[10] / scaleZ : 0;

                // Euler angles (XYZ convention) from rotation matrix
                const RAD_TO_DEG = 180 / Math.PI;
                let rotateX, rotateY, rotateZ;

                const sinY = -r20;
                if (sinY >= 1) {
                    // Gimbal lock at +90 degrees
                    rotateY = 90;
                    rotateX = Math.atan2(r01, r11) * RAD_TO_DEG;
                    rotateZ = 0;
                } else if (sinY <= -1) {
                    // Gimbal lock at -90 degrees
                    rotateY = -90;
                    rotateX = Math.atan2(r01, r11) * RAD_TO_DEG;
                    rotateZ = 0;
                } else {
                    rotateY = Math.asin(sinY) * RAD_TO_DEG;
                    rotateX = Math.atan2(r21, r22) * RAD_TO_DEG;
                    rotateZ = Math.atan2(r10, r00) * RAD_TO_DEG;
                }

                return { transform, x: tx, y: ty, z: tz, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX: 0, skewY: 0 };
            }
        } else if (matrix2d) {
            const values = matrix2d[1].split(', ').map(parseFloat);

            if (values.length === 6) {
                const a = values[0];
                const b = values[1];
                const c = values[2];
                const d = values[3];
                const tx = values[4] || 0;
                const ty = values[5] || 0;

                const scaleX = Math.sqrt(a * a + b * b);
                const scaleY = Math.sqrt(c * c + d * d);
                const rotateZ = Math.atan2(b, a) * (180 / Math.PI);

                return {
                    transform,
                    x: tx, y: ty, z: 0,
                    scaleX, scaleY, scaleZ: 1,
                    rotateX: 0, rotateY: 0, rotateZ,
                    skewX: 0, skewY: 0
                };
            }
        }

        return {
            transform,
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0
        };
    }

    /**
     * Interpolate a transform sub-property at a given global progress,
     * accounting for its own duration and easing.
     */
    function interpolateSubProperty(subProp, globalProgress, maxDuration) {
        // Scale progress by duration ratio (shorter animations complete before globalProgress=1)
        const durationRatio = subProp.duration > 0 ? subProp.duration / maxDuration : 1;
        const localProgress = Math.min(1.0, durationRatio > 0 ? globalProgress / durationRatio : 1.0);

        // Apply easing
        let easedProgress;
        if (subProp.easingKeyframes && Array.isArray(subProp.easingKeyframes) && subProp.easingKeyframes.length > 1) {
            // Complex easing (bounce, elastic, spring): pre-baked samples arrive
            // as `[{ offset, value }, ...]` where `offset` is the sample's true
            // time on `[0, 1]`. Linearly interpolate `value` between the two
            // samples that bracket `localProgress` so this mirrors how the
            // browser will render the corresponding WAAPI keyframes (which carry
            // explicit `offset`s, see properties.js COMPLEX_KEYFRAME_BUILDERS).
            easedProgress = sampleAtOffset(subProp.easingKeyframes, localProgress);
        } else {
            // Simple easing: the browser handles easing via CSS animation-timing-function.
            // Use linear here since the CSS easing is applied by the browser, not by us.
            easedProgress = localProgress;
        }

        return {
            x: subProp.startX + (subProp.endX - subProp.startX) * easedProgress,
            y: subProp.startY + (subProp.endY - subProp.startY) * easedProgress,
            z: subProp.startZ + (subProp.endZ - subProp.startZ) * easedProgress
        };
    }

    /**
     * Find the eased value at `t` (in [0, 1]) within a list of pre-baked
     * `{ offset, value }` samples by linear interpolation between the two
     * samples whose `offset`s bracket `t`. Samples must be sorted by `offset`.
     */
    function sampleAtOffset(samples, t) {
        const len = samples.length;
        if (t <= samples[0].offset) {
            return samples[0].value;
        }
        if (t >= samples[len - 1].offset) {
            return samples[len - 1].value;
        }

        // Linear scan is fine: keyframe arrays are short (~60 entries) and
        // callers walk `t` monotonically. A binary search would add complexity
        // without measurable benefit.
        for (let i = 1; i < len; i++) {
            const next = samples[i];
            if (t <= next.offset) {
                const prev = samples[i - 1];
                const span = next.offset - prev.offset;
                if (span <= 0) {
                    return next.value;
                }
                const fraction = (t - prev.offset) / span;
                return prev.value + (next.value - prev.value) * fraction;
            }
        }

        return samples[len - 1].value;
    }

    /**
     * Compute transform state from resolved start/end values at a given progress.
     * Uses interpolateSubProperty so per-sub-property duration and easing are
     * respected (important for the complex multi-easing case).
     * @returns {{ x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY }}
     */
    function computeTransformFromResolved(resolved, globalProgress, maxDuration) {
        const t = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
        const s = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
        const r = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
        const k = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);
        const tr = resolved.translate || {};
        const pickUnit = u => (typeof u === 'string' && u.length > 0 ? u : 'px');
        return {
            x: t.x, y: t.y, z: t.z,
            scaleX: s.x, scaleY: s.y, scaleZ: s.z,
            rotateX: r.x, rotateY: r.y, rotateZ: r.z,
            skewX: k.x, skewY: k.y,
            translateUnitX: pickUnit(tr.unitX),
            translateUnitY: pickUnit(tr.unitY),
            translateUnitZ: pickUnit(tr.unitZ)
        };
    }

    /* eslint-env browser */
    /* global console */
    /**
     * Error reporting for ElmMotion.
     *
     * Default behavior: silent. Consumers opt in by registering one or more
     * subscribers via `onError`, or by enabling the built-in console adapter
     * with `useConsoleReporter`. This keeps production browsers free of
     * internal package warnings while letting developers see everything
     * during development and ship errors to a service of their choice in
     * production.
     *
     * See: https://phollyer.github.io/elm-motion/shared/error-reporting/
     *
     * @typedef {'error' | 'warning'} ErrorSeverity
     *
     * @typedef {('init' | 'motionCmd' | 'animation' | 'scrollDriven' | 'viewDriven' | 'polyfill' | string)} ErrorSource
     *
     * @typedef {Object} ErrorContext
     * @property {ErrorSource}              source                 Where the report originated.
     * @property {ErrorSeverity}            severity               'error' (default) or 'warning'.
     * @property {string}                   [code]                 Stable enum string, e.g. 'TARGET_NOT_FOUND'.
     * @property {string}                   [commandType]          The offending Elm command type, when relevant.
     * @property {string}                   [elementId]            The affected element id, when relevant.
     * @property {'WAAPI' | 'ScrollTimeline' | 'ViewTimeline'} [engine]
     * @property {Record<string, unknown>}  [details]              Additional structured information.
     *
     * @typedef {(error: Error, context: ErrorContext) => void} ErrorHandler
     * @typedef {() => void} Unsubscribe
     */

    const subscribers = new Set();

    /**
     * Register a subscriber to receive ElmMotion error reports.
     *
     * Subscribers are independent — register as many as you like. A subscriber
     * that throws is isolated; one bad handler will not block the others.
     * Non-function arguments are ignored and a no-op `unsubscribe` is returned.
     *
     * @param {ErrorHandler} handler
     * @returns {Unsubscribe} Call to remove the subscriber.
     *
     * @example
     * const off = ElmMotion.onError((error, context) => {
     *     console.log(context.code, error.message);
     * });
     * // later
     * off();
     */
    function onError(handler) {
        if (typeof handler !== 'function') {
            return function noop() { };
        }
        subscribers.add(handler);
        return function unsubscribe() {
            subscribers.delete(handler);
        };
    }

    function consoleMethodFor(context) {
        return context && context.severity === 'warning' ? 'warn' : 'error';
    }

    function consoleLabelFor(context) {
        const source = (context && context.source) || 'unknown';
        return '[ElmMotion:' + source + ']';
    }

    function compactSummary(context) {
        const ctx = context || {};
        return {
            code: ctx.code,
            commandType: ctx.commandType,
            elementId: ctx.elementId,
            engine: ctx.engine
        };
    }

    /**
     * @typedef {Object} ConsoleReporterOptions
     * @property {boolean} [verbose=false]  When true, logs the full error and full context.
     *                                      When false (default), logs a one-line summary.
     * @property {Console} [target=console] Any object with `.error()` and `.warn()` methods.
     */

    /**
     * Built-in subscriber that forwards reports to a console-like target.
     * Opt-in — call this explicitly to enable console output.
     *
     * Reports with `severity: 'warning'` are sent to `target.warn`; everything
     * else is sent to `target.error`.
     *
     * @param {ConsoleReporterOptions} [options]
     * @returns {Unsubscribe} Call to detach the console subscriber.
     *
     * @example
     * // Development: pipe everything to the browser console
     * if (process.env.NODE_ENV !== 'production') {
     *     ElmMotion.useConsoleReporter();
     * }
     *
     * @example
     * // Tests: capture into a custom transport
     * const captured = [];
     * ElmMotion.useConsoleReporter({
     *     target: {
     *         error: (...args) => captured.push({ level: 'error', args }),
     *         warn:  (...args) => captured.push({ level: 'warn',  args })
     *     }
     * });
     */
    function useConsoleReporter(options) {
        const opts = options || {};
        const verbose = opts.verbose === true;
        const target = opts.target || console;

        return onError(function consoleReporter(error, context) {
            const method = consoleMethodFor(context);
            const label = consoleLabelFor(context);
            if (verbose) {
                target[method](label, error, context);
            } else {
                target[method](label, error.message, compactSummary(context));
            }
        });
    }

    /**
     * Internal: dispatch a report to all subscribers.
     *
     * Wraps the input as an `Error` if necessary and guarantees a context
     * object with at least `severity` and `source` defaults. Short-circuits
     * when no subscribers are registered. Subscribers that throw are
     * isolated — one bad handler must never break the package, and the
     * dispatcher must not recurse to report its own subscribers' failures.
     *
     * Not exported from `index.js`; intended for internal use only.
     *
     * @param {unknown} err
     * @param {Partial<ErrorContext>} [context]
     * @returns {void}
     */
    function reportError(err, context) {
        if (subscribers.size === 0) {
            return;
        }
        const errorObj = err instanceof Error ? err : new Error(String(err));
        const ctx = Object.assign({ severity: 'error', source: 'unknown' }, context || {});

        subscribers.forEach(function (handler) {
            try {
                handler(errorObj, ctx);
            } catch (_handlerErr) {
                // Intentionally swallow: a misbehaving subscriber must never
                // break the package. We cannot use the dispatcher to report
                // its own failure without risking infinite recursion.
            }
        });
    }

    /* eslint-env browser */
    /* global window */

    /**
     * Reduced-motion policy for the compositor-driven engines (WAAPI,
     * ScrollTimeline, ViewTimeline).
     *
     * These engines drive the browser compositor directly from JS, so - unlike
     * the pure-Elm engines - they can honour the user's motion preference at the
     * point an animation is committed.
     *
     * Modes:
     *   'auto'   - follow the OS `prefers-reduced-motion: reduce` setting (default)
     *   'always' - always collapse animations to their end state
     *   'never'  - always animate, ignoring the OS setting
     *
     * When reduced motion is active, an animation is committed with a zero
     * duration (and, for scroll/view engines, with its timeline dropped) so the
     * element snaps straight to its end state. The lifecycle events Elm relies on
     * (`started`/`run` then `completed`) still fire, keeping Elm state consistent.
     */

    const VALID_MODES = ['auto', 'always', 'never'];

    let reducedMotionMode = 'auto';

    /**
     * Set how the compositor-driven engines respond to the user's motion
     * preference. Defaults to `'auto'` (follow the OS setting).
     *
     * @param {'auto'|'always'|'never'} mode
     */
    function setReducedMotion(mode) {
        if (!VALID_MODES.includes(mode)) {
            reportError('setReducedMotion requires one of: ' + VALID_MODES.join(', '), {
                source: 'setReducedMotion',
                severity: 'warning',
                code: 'REDUCED_MOTION_MODE_INVALID',
                details: { mode: mode }
            });
            return;
        }
        reducedMotionMode = mode;
    }

    function prefersReducedMotion() {
        if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
            return false;
        }
        try {
            return window.matchMedia('(prefers-reduced-motion: reduce)').matches === true;
        } catch (_) {
            // Hostile / partial environments (e.g. jsdom without matchMedia) —
            // treat as "no preference" rather than throwing into the animation path.
            return false;
        }
    }

    /**
     * Resolve whether motion should be reduced right now, combining the
     * configured mode with the live OS preference.
     *
     * @returns {boolean}
     */
    function isReducedMotionActive() {
        if (reducedMotionMode === 'always') {
            return true;
        }
        if (reducedMotionMode === 'never') {
            return false;
        }
        return prefersReducedMotion();
    }

    // Timeline-range keys that only make sense alongside a scroll/view timeline.
    // They are dropped for the instant path so the element becomes a static,
    // time-based snap to its end state instead of tracking scroll position.
    const INSTANT_DROP_KEYS = ['timeline', 'rangeStart', 'rangeEnd'];

    /**
     * Collapse a WAAPI timing object to an instant "snap to end" so the element
     * jumps straight to its committed end state. The end state is held via
     * `fill`, and the lifecycle events fire exactly as they would for a normal
     * finite animation.
     *
     * @param {object} timing - A WAAPI `KeyframeAnimationOptions` timing object.
     * @returns {object} A new timing object; the input is not mutated.
     */
    function toInstantTiming(timing) {
        const instant = Object.assign({}, timing);
        instant.duration = 0;
        instant.delay = 0;
        if ('endDelay' in instant) {
            instant.endDelay = 0;
        }
        // Infinite animations settle at the end of their first iteration.
        instant.iterations = 1;
        INSTANT_DROP_KEYS.forEach((key) => {
            delete instant[key];
        });
        instant.fill = instant.fill === 'both' ? 'both' : 'forwards';
        return instant;
    }

    /**
     * Return the timing to actually use for `element.animate`, applying the
     * instant "snap to end" transform when reduced motion is active.
     *
     * @param {object} timing - The animation's normal timing object.
     * @returns {object} The original timing, or its instant equivalent.
     */
    function applyReducedMotion(timing) {
        return isReducedMotionActive() ? toInstantTiming(timing) : timing;
    }

    /* eslint-env browser */
    /* global window */

    /**
     * Parse an `rgb(...)`, `rgba(...)`, or 6-digit `#hhhhhh` color string
     * into `{ r, g, b, a }` channel components.
     *
     * Returns opaque black (`{ r: 0, g: 0, b: 0, a: 1 }`) for any input the
     * parser does not recognise — named colors, 3-digit hex, `hsl(...)`, etc.
     * The fallback keeps animations visually safe but silently flattens
     * unsupported color formats; pre-resolve colors on the Elm side
     * (`Anim.Extra.Color`) to avoid surprises.
     */
    function parseColor(str) {
        const match = str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
        if (match) {
            return {
                r: parseInt(match[1], 10),
                g: parseInt(match[2], 10),
                b: parseInt(match[3], 10),
                a: match[4] !== undefined ? parseFloat(match[4]) : 1
            };
        }
        if (str.startsWith('#')) {
            const hex = str.substring(1);
            return {
                r: parseInt(hex.substring(0, 2), 16),
                g: parseInt(hex.substring(2, 4), 16),
                b: parseInt(hex.substring(4, 6), 16),
                a: 1
            };
        }
        return { r: 0, g: 0, b: 0, a: 1 };
    }

    /**
     * Interpolate between two color strings.
     */
    function interpolateColor(startColor, endColor, progress) {
        const start = parseColor(startColor);
        const end = parseColor(endColor);

        const r = Math.round(start.r + (end.r - start.r) * progress);
        const g = Math.round(start.g + (end.g - start.g) * progress);
        const b = Math.round(start.b + (end.b - start.b) * progress);
        const a = start.a + (end.a - start.a) * progress;

        return `rgba(${r}, ${g}, ${b}, ${a})`;
    }

    function parsePerspectiveOriginParts(computedStyle) {
        const computedOrigin = computedStyle.perspectiveOrigin || '50% 50%';
        const parts = computedOrigin.split(' ');
        const rawY = parts[1] ?? parts[0];
        return {
            x: parseFloat(parts[0]) || 50,
            y: parseFloat(rawY) || 50
        };
    }

    function getPerspectiveOriginFallback(animGroup, computedStyle, unitX, unitY) {
        const cached = lastKnownPerspectiveOrigins.get(animGroup);
        if (cached && cached.unitX === unitX && cached.unitY === unitY) {
            return { x: cached.x, y: cached.y };
        }
        return parsePerspectiveOriginParts(computedStyle);
    }

    function resolvePerspectiveOriginValues(animGroup, computedStyle, property) {
        const unitX = property.unitX || '%';
        const unitY = property.unitY || '%';
        const fallback = getPerspectiveOriginFallback(animGroup, computedStyle, unitX, unitY);
        const resolved = {
            type: 'perspectiveOrigin',
            startX: property.startX ?? fallback.x,
            startY: property.startY ?? fallback.y,
            endX: property.endX,
            endY: property.endY,
            unitX: unitX,
            unitY: unitY
        };

        lastKnownPerspectiveOrigins.set(animGroup, { x: property.endX, y: property.endY, unitX: unitX, unitY: unitY });
        return resolved;
    }

    const NON_TRANSFORM_RESOLVERS = {
        opacity(_animGroup, computedStyle, property) {
            const computedOpacity = parseFloat(computedStyle.opacity);
            return {
                type: 'opacity',
                startValue: property.startValue ?? property.defaultValue ?? computedOpacity,
                endValue: property.endValue
            };
        },
        size(_animGroup, computedStyle, property) {
            return {
                type: 'size',
                startWidth: property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width),
                startHeight: property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height),
                endWidth: property.endWidth,
                endHeight: property.endHeight,
                unitWidth: property.unitWidth || 'px',
                unitHeight: property.unitHeight || 'px'
            };
        },
        customProperty(_animGroup, computedStyle, property) {
            const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
            return {
                type: 'customProperty',
                cssProperty: property.cssProperty,
                unit: property.unit,
                startValue: property.startValue ?? computedValue,
                endValue: property.endValue
            };
        },
        customColorProperty(_animGroup, computedStyle, property) {
            const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
            return {
                type: 'customColorProperty',
                cssProperty: property.cssProperty,
                startColor: property.startColor ?? computedColor,
                endColor: property.endColor
            };
        },
        perspectiveOrigin(animGroup, computedStyle, property) {
            return resolvePerspectiveOriginValues(animGroup, computedStyle, property);
        }
    };

    function getCurrentTransformConfig(animGroup, element, property, axes) {
        const currentTransform = getTransformState(animGroup, element);
        const fromValues = axes.map(({ suffix, currentKey, useDefault = true }) => {
            const defaultValue = useDefault ? property[`default${suffix}`] : undefined;
            return property[`start${suffix}`] ?? defaultValue ?? currentTransform[currentKey];
        });
        const toValues = axes.map(({ suffix, currentKey }) => property[`end${suffix}`] ?? currentTransform[currentKey]);
        return {
            from: fromValues.join(','),
            to: toValues.join(',')
        };
    }

    const TRANSFORM_CONFIG_AXES = {
        translate: [
            { suffix: 'X', currentKey: 'x' },
            { suffix: 'Y', currentKey: 'y' },
            { suffix: 'Z', currentKey: 'z' }
        ],
        scale: [
            { suffix: 'X', currentKey: 'scaleX' },
            { suffix: 'Y', currentKey: 'scaleY' },
            { suffix: 'Z', currentKey: 'scaleZ' }
        ],
        rotate: [
            { suffix: 'X', currentKey: 'rotateX' },
            { suffix: 'Y', currentKey: 'rotateY' },
            { suffix: 'Z', currentKey: 'rotateZ' }
        ],
        skew: [
            { suffix: 'X', currentKey: 'skewX', useDefault: false },
            { suffix: 'Y', currentKey: 'skewY', useDefault: false }
        ]
    };

    function buildTransformPropertyConfig(animGroup, element, _computedStyle, property, config) {
        Object.assign(config, getCurrentTransformConfig(animGroup, element, property, TRANSFORM_CONFIG_AXES[property.type]));
    }

    const PROPERTY_CONFIG_BUILDERS = {
        translate: buildTransformPropertyConfig,
        scale: buildTransformPropertyConfig,
        rotate: buildTransformPropertyConfig,
        skew: buildTransformPropertyConfig,
        opacity(_animGroup, _element, computedStyle, property, config) {
            const computedOpacity = parseFloat(computedStyle.opacity);
            const fromVal = property.startValue ?? property.defaultValue ?? computedOpacity;
            config.from = `${fromVal}`;
            config.to = `${property.endValue}`;
        },
        size(_animGroup, _element, computedStyle, property, config) {
            const startWidth = property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width);
            const startHeight = property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height);
            config.from = `${startWidth},${startHeight}`;
            config.to = `${property.endWidth},${property.endHeight}`;
            config.unitWidth = property.unitWidth || 'px';
            config.unitHeight = property.unitHeight || 'px';
        },
        customProperty(_animGroup, _element, computedStyle, property, config) {
            const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
            const fromVal = property.startValue ?? computedValue;
            config.property = property.cssProperty;
            config.from = `${fromVal}${property.unit}`;
            config.to = `${property.endValue}${property.unit}`;
        },
        customColorProperty(_animGroup, _element, computedStyle, property, config) {
            const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
            config.property = property.cssProperty;
            config.from = property.startColor ?? computedColor;
            config.to = property.endColor;
        },
        perspectiveOrigin(_animGroup, _element, _computedStyle, property, config) {
            const uX = property.unitX || '%';
            const uY = property.unitY || '%';
            config.from = `${property.startX}${uX} ${property.startY}${uY}`;
            config.to = `${property.endX}${uX} ${property.endY}${uY}`;
        }
    };

    function assignResolvedAxes(start, end, property, currentTransform, axes) {
        axes.forEach(({ suffix, startKey, defaultKey, currentKey, endKey }) => {
            start[startKey] = defaultKey
                ? property[`start${suffix}`] ?? property[`default${suffix}`] ?? currentTransform[currentKey]
                : property[`start${suffix}`] ?? currentTransform[currentKey];
            end[endKey] = property[`end${suffix}`] ?? currentTransform[currentKey];
        });
    }

    const SCROLL_TRANSFORM_AXES = {
        translate: [
            { suffix: 'X', startKey: 'x', endKey: 'x', currentKey: 'x', defaultKey: 'defaultX' },
            { suffix: 'Y', startKey: 'y', endKey: 'y', currentKey: 'y', defaultKey: 'defaultY' },
            { suffix: 'Z', startKey: 'z', endKey: 'z', currentKey: 'z', defaultKey: 'defaultZ' }
        ],
        scale: [
            { suffix: 'X', startKey: 'scaleX', endKey: 'scaleX', currentKey: 'scaleX', defaultKey: 'defaultX' },
            { suffix: 'Y', startKey: 'scaleY', endKey: 'scaleY', currentKey: 'scaleY', defaultKey: 'defaultY' },
            { suffix: 'Z', startKey: 'scaleZ', endKey: 'scaleZ', currentKey: 'scaleZ', defaultKey: 'defaultZ' }
        ],
        rotate: [
            { suffix: 'X', startKey: 'rotateX', endKey: 'rotateX', currentKey: 'rotateX', defaultKey: 'defaultX' },
            { suffix: 'Y', startKey: 'rotateY', endKey: 'rotateY', currentKey: 'rotateY', defaultKey: 'defaultY' },
            { suffix: 'Z', startKey: 'rotateZ', endKey: 'rotateZ', currentKey: 'rotateZ', defaultKey: 'defaultZ' }
        ],
        skew: [
            { suffix: 'X', startKey: 'skewX', endKey: 'skewX', currentKey: 'skewX' },
            { suffix: 'Y', startKey: 'skewY', endKey: 'skewY', currentKey: 'skewY' }
        ]
    };

    function resolveScrollTransformProperty(property, start, end, currentTransform) {
        const axes = SCROLL_TRANSFORM_AXES[property.type];
        if (axes) {
            assignResolvedAxes(start, end, property, currentTransform, axes);
        }
    }

    const SIMPLE_KEYFRAME_BUILDERS = {
        opacity(resolved) {
            return [
                { opacity: String(resolved.startValue) },
                { opacity: String(resolved.endValue) }
            ];
        },
        size(resolved) {
            const uW = resolved.unitWidth || 'px';
            const uH = resolved.unitHeight || 'px';
            return [
                { width: resolved.startWidth + uW, height: resolved.startHeight + uH },
                { width: resolved.endWidth + uW, height: resolved.endHeight + uH }
            ];
        },
        customProperty(resolved) {
            return [
                { [camelCase(resolved.cssProperty)]: resolved.startValue + resolved.unit },
                { [camelCase(resolved.cssProperty)]: resolved.endValue + resolved.unit }
            ];
        },
        customColorProperty(resolved) {
            return [
                { [camelCase(resolved.cssProperty)]: resolved.startColor },
                { [camelCase(resolved.cssProperty)]: resolved.endColor }
            ];
        },
        perspectiveOrigin(resolved) {
            const uX = resolved.unitX || '%';
            const uY = resolved.unitY || '%';
            return [
                { perspectiveOrigin: resolved.startX + uX + ' ' + resolved.startY + uY },
                { perspectiveOrigin: resolved.endX + uX + ' ' + resolved.endY + uY }
            ];
        }
    };

    /**
     * Pre-baked easing samples arrive from Elm as `[{ offset, value }, ...]`
     * where `offset` is the sample's true time on `[0, 1]` and `value` is the
     * eased progress at that offset. The browser will place each keyframe at
     * its `offset` (rather than uniformly distributing them), so the rendered
     * curve faithfully follows the original easing — even when samples are
     * non-uniformly spaced in time (e.g. bounce critical-point samples).
     */
    const COMPLEX_KEYFRAME_BUILDERS = {
        opacity(resolved, easingKeyframes) {
            return easingKeyframes.map(({ offset, value }) => ({
                offset,
                opacity: String(resolved.startValue + (resolved.endValue - resolved.startValue) * value)
            }));
        },
        size(resolved, easingKeyframes) {
            const uW = resolved.unitWidth || 'px';
            const uH = resolved.unitHeight || 'px';
            return easingKeyframes.map(({ offset, value }) => ({
                offset,
                width: (resolved.startWidth + (resolved.endWidth - resolved.startWidth) * value) + uW,
                height: (resolved.startHeight + (resolved.endHeight - resolved.startHeight) * value) + uH
            }));
        },
        customProperty(resolved, easingKeyframes) {
            return easingKeyframes.map(({ offset, value }) => ({
                offset,
                [camelCase(resolved.cssProperty)]: (resolved.startValue + (resolved.endValue - resolved.startValue) * value) + resolved.unit
            }));
        },
        customColorProperty(resolved, easingKeyframes) {
            return easingKeyframes.map(({ offset, value }) => ({
                offset,
                [camelCase(resolved.cssProperty)]: interpolateColor(resolved.startColor, resolved.endColor, value)
            }));
        },
        perspectiveOrigin(resolved, easingKeyframes) {
            const uX = resolved.unitX || '%';
            const uY = resolved.unitY || '%';
            return easingKeyframes.map(({ offset, value }) => ({
                offset,
                perspectiveOrigin: (resolved.startX + (resolved.endX - resolved.startX) * value) + uX
                    + ' ' + (resolved.startY + (resolved.endY - resolved.startY) * value) + uY
            }));
        }
    };

    /**
     * Resolve start/end values for a non-transform property so they can be
     * used to compute interpolated values without reading the DOM later.
     */
    function resolveNonTransformValues(animGroup, element, property) {
        const computedStyle = window.getComputedStyle(element);
        const resolver = NON_TRANSFORM_RESOLVERS[property.type];
        return resolver ? resolver(animGroup, computedStyle, property) : null;
    }
    function buildSimplePropertyKeyframes(resolved) {
        const buildKeyframes = SIMPLE_KEYFRAME_BUILDERS[resolved.type];
        return buildKeyframes ? buildKeyframes(resolved) : null;
    }

    /**
     * Build a multi-keyframe array for a resolved non-transform property using
     * pre-computed easing progress values (for bounce/elastic easings).
     * Returns null for property types where this path is not supported (caller
     * should fall back to buildSimplePropertyKeyframes).
     */
    function buildComplexPropertyKeyframes(resolved, easingKeyframes) {
        const buildKeyframes = COMPLEX_KEYFRAME_BUILDERS[resolved.type];
        return buildKeyframes ? buildKeyframes(resolved, easingKeyframes) : null;
    }

    /**
     * Build keyframes and the animation easing value for a resolved non-transform property.
     * Returns { keyframes, animationEasing }.
     * When easingKeyframes is provided (complex easing), bakes it into the keyframes
     * and sets animationEasing to 'linear'. Otherwise returns 2 keyframes with the
     * CSS easing string as animationEasing.
     */
    function buildPropertyKeyframes(resolved, easingKeyframes, easing) {
        const cssEasing = easingFunctions[easing] || easing;

        if (easingKeyframes && Array.isArray(easingKeyframes)) {
            const keyframes = buildComplexPropertyKeyframes(resolved, easingKeyframes);
            if (keyframes) {
                return { keyframes, animationEasing: 'linear' };
            }
        }

        return { keyframes: buildSimplePropertyKeyframes(resolved), animationEasing: cssEasing };
    }

    /**
     * Create a WAAPI animation for a non-transform property using pre-resolved values.
     * Using pre-resolved values avoids a redundant DOM read (resolveNonTransformValues
     * is always called by the caller before this function).
     */
    function createPropertyAnimation(element, resolved, property, globalOptions = { iterations: 1, direction: 'normal' }) {
        if (!resolved) return null;
        const { keyframes, animationEasing } = buildPropertyKeyframes(resolved, property.easingKeyframes, property.easing);
        if (!keyframes) return null;
        const delayMs = property.delay || 0;
        return element.animate(keyframes, applyReducedMotion({
            duration: property.duration,
            delay: delayMs,
            easing: animationEasing,
            fill: delayMs > 0 ? 'both' : 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        }));
    }

    /**
     * Extract property configuration for lifecycle events.
     * Returns a normalized config object with from/to values as strings.
     */
    function extractPropertyConfig(animGroup, element, property) {
        const config = {
            property: property.type,
            duration: property.duration,
            easing: property.easing,
            from: '',
            to: ''
        };

        const computedStyle = window.getComputedStyle(element);

        const buildConfig = PROPERTY_CONFIG_BUILDERS[property.type];
        if (buildConfig) {
            buildConfig(animGroup, element, computedStyle, property, config);
        }

        return config;
    }

    /**
     * Resolve both the start and end transform component values for scroll-driven
     * animations in a single pass, eliminating the need for two separate iterators.
     * Returns { start, end } where each is a flat transform state object.
     */
    function resolveScrollDrivenTransformValues(transformProperties, currentTransform) {
        const base = {
            x: currentTransform.x, y: currentTransform.y, z: currentTransform.z,
            scaleX: currentTransform.scaleX, scaleY: currentTransform.scaleY, scaleZ: currentTransform.scaleZ,
            rotateX: currentTransform.rotateX, rotateY: currentTransform.rotateY, rotateZ: currentTransform.rotateZ,
            skewX: currentTransform.skewX, skewY: currentTransform.skewY,
            translateUnitX: currentTransform.translateUnitX || 'px',
            translateUnitY: currentTransform.translateUnitY || 'px',
            translateUnitZ: currentTransform.translateUnitZ || 'px'
        };
        const start = Object.assign({}, base);
        const end = Object.assign({}, base);

        transformProperties.forEach(function (property) {
            resolveScrollTransformProperty(property, start, end, currentTransform);
            if (property.type === 'translate') {
                if (typeof property.unitX === 'string' && property.unitX.length > 0) {
                    start.translateUnitX = property.unitX;
                    end.translateUnitX = property.unitX;
                }
                if (typeof property.unitY === 'string' && property.unitY.length > 0) {
                    start.translateUnitY = property.unitY;
                    end.translateUnitY = property.unitY;
                }
                if (typeof property.unitZ === 'string' && property.unitZ.length > 0) {
                    start.translateUnitZ = property.unitZ;
                    end.translateUnitZ = property.unitZ;
                }
            }
        });

        return { start, end };
    }

    /* eslint-env browser */

    // Whether we have already reported the missing-motionMsg-port warning.
    // Reset by index.js init() so a fresh app gets a fresh chance to warn.
    let portMissingWarned = false;

    function resetPortMissingWarning() {
        portMissingWarned = false;
    }

    /**
     * Send data to Elm via the motionMsg port.
     * All port communication funnels through this single function so the
     * port-presence check lives in exactly one place. If the port is missing,
     * we report once via reportError and then silently no-op for the rest of
     * the session (so per-frame senders don't spam the reporter).
     */
    function sendToElm(data) {
        const ports = portsRef.ports;
        if (ports && ports.motionMsg && typeof ports.motionMsg.send === 'function') {
            ports.motionMsg.send(data);
            return;
        }
        if (!portMissingWarned) {
            portMissingWarned = true;
            reportError('motionMsg port is not available; outbound events will be dropped', {
                source: 'ports',
                severity: 'warning',
                code: 'MOTION_MSG_PORT_MISSING'
            });
        }
    }

    function getGroupMaxDuration(animGroup) {
        const properties = animationGroups.get(animGroup)?.propertyConfigs || [];
        return properties.length > 0
            ? Math.max(...properties.map(property => property.duration))
            : 0;
    }

    function getRunningAnimationProgress(animGroup, maxDuration) {
        if (maxDuration <= 0) {
            return 0;
        }

        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims || elementAnims.size === 0) {
            return 0;
        }

        const firstAnim = elementAnims.values().next().value;
        if (!firstAnim || !firstAnim.animation) {
            return 0;
        }

        const currentTime = Number(firstAnim.animation.currentTime) || 0;
        const delay = Number(firstAnim.animation.effect?.getTiming?.()?.delay) || 0;
        const activeTime = Math.max(0, currentTime - delay);
        return Math.min(1.0, Math.max(0.0, activeTime / maxDuration));
    }

    function getLifecycleProgress(status, animGroup) {
        if (status === 'completed' || status === 'stopped') {
            return 1.0;
        }

        if (status === 'run' || status === 'started' || status === 'reset' || status === 'restarted') {
            return 0.0;
        }

        return getRunningAnimationProgress(animGroup, getGroupMaxDuration(animGroup));
    }

    /**
     * Send iteration event to Elm when an animation crosses an iteration boundary.
     * The iteration count is sent as the progress value so Elm can decode it
     * via: Iteration animGroupName (round progress)
     */
    function sendIterationEvent(animGroup, iterationNumber) {
        sendToElm({
            type: 'animationUpdate',
            payload: {
                elementId: animGroup,
                animGroup: animGroup,
                status: 'iteration',
                progress: iterationNumber
            }
        });
    }

    /**
     * Send lifecycle event to Elm (started, completed, cancelled, paused, resumed, etc.)
     * Includes current progress calculated from the active animation state.
     */
    function sendLifecycleEvent(status, animGroup) {
        sendToElm({
            type: 'animationUpdate',
            engine: 'waapi',
            payload: {
                elementId: animGroup,
                animGroup: animGroup,
                status: status,
                progress: getLifecycleProgress(status, animGroup)
            }
        });
    }

    /**
     * Send a lifecycle event for a scroll-driven animation group to Elm.
     * Payload matches the 'animationUpdate' shape used by the WAAPI engine, plus
     * an 'engine' field so Elm decoders can filter to their own events.
     */
    function sendScrollLifecycleEvent(status, animGroup, progress, engine) {
        sendToElm({
            type: 'animationUpdate',
            engine: engine,
            payload: {
                elementId: animGroup,
                animGroup: animGroup,
                status: status,
                progress: progress
            }
        });
    }

    /**
     * Send property update to Elm (during animation).
     * Uses 'propertyUpdate' type which Elm routes to PropertyUpdate handling.
     */
    function sendPropertyUpdate(propertyData) {
        sendToElm({ type: 'propertyUpdate', ...propertyData });
    }

    /**
     * Build the property-update payload sent to Elm during an animation.
     *
     * Phase 4: JS no longer sends absolute interpolated values. The Elm side
     * (`Anim.Internal.Engine.WAAPI.ProgressApply`) interpolates each property
     * from its anchored start to its end using the raw progress emitted here,
     * combined with the easing and config stored in the property's `PropertyState`.
     *
     * `propertyProgress` is a plain object keyed by Elm's property-type strings
     * (`'translate'`, `'rotate'`, `'skew'`, `'scale'`, `'opacity'`, `'size'`,
     * `'perspectiveOrigin'`, `'custom:<css>'`, `'customColor:<css>'`), with raw
     * 0..1 per-iteration progress values (no easing applied — Elm applies the
     * easing curve).
     */
    function buildAnimatedPropertyData(propertyProgress) {
        return { propertyProgress };
    }

    /**
     * Send settled (committed) transform values to Elm after animation completes.
     * This establishes the runtime baseline for the next animation on the same group,
     * ensuring Elm and JS use the same committed start values for frozen-axis anchoring.
     *
     * Payload includes per-axis values and units so Elm can reconstruct the exact
     * transform state that was committed to the DOM, preventing Elm baseline drift.
     */
    function sendSettledTransformValues(animGroup, settledTransform) {
        if (!settledTransform || typeof settledTransform !== 'object') {
            return;
        }
        sendToElm({
            type: 'settledValues',
            animGroup: animGroup,
            payload: {
                translate: settledTransform.translate || null,
                scale: settledTransform.scale || null,
                rotate: settledTransform.rotate || null,
                skew: settledTransform.skew || null,
                committedAt: performance.now()
            }
        });
    }

    /* eslint-env browser */
    /* global document, CSS */

    /**
     * Find the single DOM element with a matching data-anim-target attribute (or id).
     */
    function findAnimTarget(targetId) {
        return document.querySelector('[data-anim-target="' + CSS.escape(targetId) + '"]')
            || document.getElementById(targetId)
            || null;
    }

    /**
     * Find all DOM elements with a matching data-anim-target attribute (or id).
     */
    function findAllAnimTargets(targetId) {
        const byAttr = Array.from(document.querySelectorAll('[data-anim-target="' + CSS.escape(targetId) + '"]'));
        if (byAttr.length > 0) return byAttr;
        const byId = document.getElementById(targetId);
        return byId ? [byId] : [];
    }

    /* eslint-env browser */
    /* global requestAnimationFrame, cancelAnimationFrame, performance */

    // Sub-property keys covered by the merged transform animation. When the
    // 'transform' entry is active, raw per-iteration progress for each of these
    // is computed individually (sub-properties can have different durations and
    // each completes locally when its own duration elapses).
    const TRANSFORM_SUB_PROPS = ['translate', 'rotate', 'scale', 'skew'];

    // Minimum interval (ms) between per-frame propertyUpdate emissions during an
    // animation. Default 0 = no throttle: emit on every requestAnimationFrame
    // tick, matching the display refresh rate (60 Hz, 120 Hz, 144 Hz, etc.).
    // The visual animation runs on the browser compositor and is unaffected
    // by this value - this only governs how often we read the live transform
    // state and forward a propertyUpdate event to Elm.
    //
    // Set a positive value via `setPropertyUpdateThrottle(ms)` to cap the
    // emission rate, e.g. 16 for ~60 Hz, 33 for ~30 Hz. Useful when many
    // simultaneous animations on a high-refresh display would otherwise
    // generate excessive port traffic for Elm-side real-time queries.
    let propertyUpdateIntervalMs = 0;

    /**
     * Set the minimum interval (in milliseconds) between per-frame
     * `propertyUpdate` events emitted to Elm during an animation.
     *
     * Pass 0 (the default) to disable throttling - one event is emitted per
     * requestAnimationFrame tick, matching the display refresh rate.
     *
     * Pass a positive number to cap the emission rate. The visual animation
     * is never affected; only the rate at which Elm subscribers see live
     * mid-animation values changes.
     *
     * @param {number} intervalMs - Non-negative number. 0 disables throttling.
     */
    function setPropertyUpdateThrottle(intervalMs) {
        if (typeof intervalMs !== 'number' || !Number.isFinite(intervalMs) || intervalMs < 0) {
            reportError('setPropertyUpdateThrottle requires a non-negative finite number', {
                source: 'setPropertyUpdateThrottle',
                severity: 'warning',
                code: 'THROTTLE_INVALID',
                details: { intervalMs: intervalMs }
            });
            return;
        }
        propertyUpdateIntervalMs = intervalMs;
    }

    /**
     * Convert a camelCase JS property name (as used in Web Animations API
     * keyframe objects, e.g. `backgroundColor`) to its CSS hyphenated form
     * (e.g. `background-color`) for use with `CSSStyleDeclaration.setProperty`.
     */
    function camelToKebab(name) {
        return name.replace(/[A-Z]/g, m => '-' + m.toLowerCase());
    }

    /**
     * Best-effort equivalent of `Animation.commitStyles()` for browsers that
     * don't implement it (notably older iOS Safari). Reads the last keyframe
     * of the animation and writes each animatable property to the element's
     * inline style. Skips the `composite`, `easing`, `offset` pseudo-keys.
     *
     * Falls through to the native `commitStyles()` when available.
     */
    function commitAnimatedStyles(element, animation) {
        if (typeof animation.commitStyles === 'function') {
            animation.commitStyles();
            return;
        }
        const effect = animation.effect;
        if (!effect || typeof effect.getKeyframes !== 'function') {
            return;
        }
        const keyframes = effect.getKeyframes();
        if (!keyframes || keyframes.length === 0) {
            return;
        }
        const endFrame = keyframes[keyframes.length - 1];
        for (const key in endFrame) {
            if (!Object.prototype.hasOwnProperty.call(endFrame, key)) continue;
            if (key === 'composite' || key === 'easing' || key === 'offset' || key === 'computedOffset') continue;
            const value = endFrame[key];
            if (value == null) continue;
            if (key.startsWith('--')) {
                element.style.setProperty(key, String(value));
            } else {
                element.style.setProperty(camelToKebab(key), String(value));
            }
        }
    }

    function buildPropertyVersions(animGroup, propertyType, version) {
        const propertyVersions = {};

        const assignVersion = (propType, ver) => {
            propertyVersions[propType] = ver;
            if (propType === 'transform') {
                TRANSFORM_SUB_PROPS.forEach(subProp => {
                    propertyVersions[subProp] = ver;
                });
            }
        };

        const elementAnims = activeAnimations.get(animGroup);
        if (elementAnims) {
            elementAnims.forEach((animData, propType) => {
                assignVersion(propType, animData.version);
            });
        }
        if (propertyType && version != null) {
            assignVersion(propertyType, version);
        }
        return propertyVersions;
    }

    function removeTrackedAnimationVersion(animGroup, propertyType, version) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims) {
            return;
        }

        const current = elementAnims.get(propertyType);
        if (current && current.version === version) {
            elementAnims.delete(propertyType);
            if (elementAnims.size === 0) {
                activeAnimations.delete(animGroup);
            }
        }
    }

    /**
     * Cache the end values of a merged transform animation into
     * `lastKnownTransforms` so the resize machinery in `animations.js` has the
     * correct anchor after the animation finishes. Resize math reads this
     * cache to compute proportional rescaling; without it the post-animation
     * resize falls back to a DOM read of the inline style.
     */
    function buildAuthoredFinalState(resolvedTransformValues) {
        if (!resolvedTransformValues) {
            return null;
        }
        return {
            x: resolvedTransformValues.translate.endX,
            y: resolvedTransformValues.translate.endY,
            z: resolvedTransformValues.translate.endZ,
            scaleX: resolvedTransformValues.scale.endX,
            scaleY: resolvedTransformValues.scale.endY,
            scaleZ: resolvedTransformValues.scale.endZ,
            rotateX: resolvedTransformValues.rotate.endX,
            rotateY: resolvedTransformValues.rotate.endY,
            rotateZ: resolvedTransformValues.rotate.endZ,
            skewX: resolvedTransformValues.skew.endX,
            skewY: resolvedTransformValues.skew.endY,
            translateUnitX: (typeof resolvedTransformValues.translate.unitX === 'string') ? resolvedTransformValues.translate.unitX : 'px',
            translateUnitY: (typeof resolvedTransformValues.translate.unitY === 'string') ? resolvedTransformValues.translate.unitY : 'px',
            translateUnitZ: (typeof resolvedTransformValues.translate.unitZ === 'string') ? resolvedTransformValues.translate.unitZ : 'px'
        };
    }

    function cacheFinalTransformState(animGroup, resolvedTransformValues) {
        const finalState = buildAuthoredFinalState(resolvedTransformValues);
        if (!finalState) {
            return;
        }
        lastKnownTransforms.set(animGroup, finalState);
    }

    /**
     * Compute the per-sub-property local progress for the merged transform
     * animation at a given `globalProgress` (0..1 across the merged duration).
     *
     * Mirrors the duration-ratio scaling in `interpolateSubProperty` (transform.js)
     * so each sub-property's progress reaches 1.0 when its own duration elapses,
     * even when other sub-properties of the merged animation are still running.
     * Easing is intentionally NOT applied here — the Elm side
     * (`ProgressApply.applyPropertyProgress`) applies the property's easing.
     */
    function buildTransformSubPropertyProgress(globalProgress, resolvedTransformValues, maxDuration) {
        const out = {};
        for (const key of TRANSFORM_SUB_PROPS) {
            const subProp = resolvedTransformValues[key];
            if (!subProp) continue;
            const durationRatio = (subProp.duration > 0 && maxDuration > 0)
                ? (subProp.duration / maxDuration)
                : 1;
            out[key] = Math.min(1.0, durationRatio > 0 ? globalProgress / durationRatio : 1.0);
        }
        return out;
    }

    function sendTrackedPropertyUpdate(animGroup, propertyType, version, propertyProgress, isAnimating, progress) {
        const propertyVersions = buildPropertyVersions(animGroup, propertyType, version);
        const propertyData = {
            elementId: animGroup,
            animGroup: animGroup,
            ...buildAnimatedPropertyData(propertyProgress),
            isAnimating: isAnimating,
            propertyVersions: propertyVersions
        };

        if (progress != null) {
            propertyData.progress = progress;
        }

        sendPropertyUpdate(propertyData);
    }

    function updateGroupIterationState(animGroup, groupGeneration, propertyIndex, animation) {
        const groupInfo = animationGroups.get(animGroup);
        if (!groupInfo || groupInfo.generation !== groupGeneration) {
            return;
        }

        try {
            const currentIteration = animation.effect?.getComputedTiming()?.currentIteration;
            const nextGroupIteration = updateGroupIteration(
                groupInfo.propertyIterations,
                propertyIndex,
                currentIteration,
                groupInfo.lastIteration
            );
            if (nextGroupIteration != null) {
                groupInfo.lastIteration = nextGroupIteration;
                sendIterationEvent(animGroup, nextGroupIteration);
            }
        } catch (error) {
            reportError(error, {
                source: 'animationEvents',
                severity: 'warning',
                code: 'ITERATION_TIMING_READ_FAILED',
                details: { animGroup: animGroup, propertyIndex: propertyIndex }
            });
        }
    }

    function getAnimationProgress(animGroup, animation) {
        // Always read the LIVE per-iteration duration off the animation's own
        // effect. `resizeTransformAnimation` recreates the animation with a
        // new duration on every resize, but `groupInfo.propertyConfigs` is
        // populated only once at setup time and is never refreshed. Using the
        // cached config duration here returns
        //   (newCurrentTime % oldDuration) / oldDuration
        // after a resize — which wraps the just-seeked `currentTime` (e.g.
        // 1630 ms set against the new 2895 ms duration) back through the OLD
        // 1435 ms duration and reports 0.136 instead of 0.563. Elm then stores
        // that bogus progress and uses it on the NEXT resize, drifting the box
        // away from its true proportional position on every orientation switch.
        //
        // The animation is created with a single `duration` covering the max
        // of all sub-property durations (see `createMergedTransformAnimation`
        // and the `maxDuration` calc in `resizeTransformAnimation`), so the
        // live timing is the authoritative max-duration after any resize.
        const liveDuration = Number(animation.effect?.getTiming?.()?.duration) || 0;
        const groupInfo = animationGroups.get(animGroup);
        const fallbackDuration = groupInfo?.propertyConfigs?.length > 0
            ? Math.max(...groupInfo.propertyConfigs.map(property => property.duration))
            : 0;
        const maxDuration = liveDuration > 0 ? liveDuration : fallbackDuration;
        const currentTime = Number(animation.currentTime) || 0;
        const delay = Number(animation.effect?.getTiming?.()?.delay) || 0;
        const activeTime = Math.max(0, currentTime - delay);
        if (maxDuration <= 0) {
            return 0;
        }
        // Per-iteration raw progress. WAAPI's `currentTime` is total elapsed time
        // across all iterations and keeps growing forever on looping animations,
        // so a naive `currentTime / maxDuration` saturates at 1.0 after the first
        // iteration and gets clamped to 1 thereafter, telling Elm the animation
        // is permanently at end-of-leg. That poisons resize math in
        // `Anim.Internal.Engine.WAAPI.applyTranslateResize` (Proportional path),
        // which computes `(oldIter + progress) * newDuration` — with a stale
        // `progress=1` it lands the new `currentTime` exactly on the next
        // iteration boundary, snapping the box to the start of the next leg.
        return (activeTime % maxDuration) / maxDuration;
    }

    function getLiveTransformState(animGroup, animation, resolvedTransformValues, transformAnimDuration) {
        if (!resolvedTransformValues) {
            return lastKnownTransforms.get(animGroup) || getDefaultTransformState();
        }

        // While a freshly-created animation is in `pending` state (after
        // `element.animate(...)` but before its ready promise resolves on the
        // first compositor frame), `animation.currentTime` is null/0 even if
        // we explicitly set a target `currentTime` for resize continuity.
        // Returning the cached snapshot avoids emitting a one-frame
        // `t.x = 0` propertyUpdate that visually snaps the element to the
        // start of its keyframes before WAAPI applies the requested time.
        if (animation.playState === 'pending') {
            return lastKnownTransforms.get(animGroup) || getDefaultTransformState();
        }

        // Always read the live per-iteration duration from the effect rather
        // than relying on the duration captured at `setupAnimationEvents` time.
        // `resizeTransformAnimation` mutates the running animation in place via
        // `effect.updateTiming`, after which the captured value is stale and
        // would skew the modulo + reverse-leg math below — leaving the box at
        // the wrong position for the rest of the resized animation.
        const timing = animation.effect?.getTiming?.() || {};
        const liveDuration = Number(timing.duration) || transformAnimDuration || 0;
        const currentTime = Number(animation.currentTime) || 0;
        const delay = Number(timing.delay) || 0;
        const activeTime = Math.max(0, currentTime - delay);
        // Per-iteration progress: WAAPI's `currentTime` is the animation's total
        // elapsed time across all iterations, not the progress within the current
        // iteration. Without the modulo, multi-iteration animations (looping or
        // alternate) saturate `rawProgress` at 1.0 forever once `currentTime`
        // exceeds the per-iteration duration, which then poisons the snapshot
        // (especially after `flip` for alternate's reverse leg, where it would
        // collapse to 0).
        const rawProgress = liveDuration > 0
            ? ((activeTime % liveDuration) / liveDuration)
            : 0;

        // Flip progress on the reverse half of an `alternate`/`alternate-reverse`
        // iteration so the snapshot reflects the live visual position. WAAPI's
        // `currentTime` keeps marching forward each iteration, so for odd-indexed
        // alternate iterations the box is visually traveling end → start while
        // `currentTime / duration` keeps reading 0 → 1. Without this flip the
        // snapshot stays glued near `endX` for the whole reverse leg, which then
        // poisons resize math (proportional rescaling treats `oldEnd` as the
        // current position and snaps the box).
        const direction = timing.direction || 'normal';
        let animProgress = rawProgress;
        if (direction === 'alternate' || direction === 'alternate-reverse') {
            const computed = animation.effect?.getComputedTiming?.() || {};
            const iter = computed.currentIteration;
            if (Number.isFinite(iter)) {
                const startsReversed = direction === 'alternate-reverse';
                const isReverseLeg = (iter % 2 === 1) !== startsReversed;
                if (isReverseLeg) {
                    animProgress = 1 - rawProgress;
                }
            }
        } else if (direction === 'reverse') {
            animProgress = 1 - rawProgress;
        }

        const transformState = computeTransformFromResolved(resolvedTransformValues, animProgress, liveDuration);
        lastKnownTransforms.set(animGroup, transformState);

        return transformState;
    }

    function finalizeAnimationTracking(animGroup, groupGeneration, status) {
        const groupInfo = animationGroups.get(animGroup);
        if (!groupInfo || groupInfo.generation !== groupGeneration) {
            return false;
        }

        groupInfo.completedProperties++;
        const allComplete = groupInfo.completedProperties >= groupInfo.totalProperties;
        if (allComplete) {
            // Tear down JS-side bookkeeping BEFORE notifying Elm. `sendLifecycleEvent`
            // dispatches to an Elm port synchronously: Elm's `update` runs, returns
            // a Cmd that calls back into `processElementAnimation` to set up the
            // next animation — all before `sendLifecycleEvent` returns. If
            // `cleanupAnimGroup` ran after, it would wipe the freshly-set entry
            // and the next animation's `finish` event would find no entry,
            // silently skipping the next lifecycle emission and stalling the
            // example's state machine.
            cleanupAnimGroup(animGroup);
            sendLifecycleEvent(status, animGroup);
        }
        return allComplete;
    }

    function setupAnimationEvents(animGroup, propertyType, element, animation, version, resolvedTransformValues) {
        // Generation and propertyIndex are looked up per-event from the
        // `elementAnims` entry instead of being captured in this closure. This
        // lets `processElementAnimation` "carry forward" still-running animations
        // into a new generation (re-keying their entry's `generation` /
        // `propertyIndex` fields) without them mistakenly failing the generation
        // check at finish/cancel time.
        function getEntry() {
            return activeAnimations.get(animGroup)?.get(propertyType);
        }
        function isActiveEntry() {
            const entry = getEntry();
            return !!entry && entry.version === version;
        }
        const transformAnimDuration = resolvedTransformValues
            ? (animation.effect?.getTiming()?.duration || 0)
            : 0;

        let lastComputedTransformState = resolvedTransformValues
            ? computeTransformFromResolved(resolvedTransformValues, 0, transformAnimDuration)
            : null;
        let lastProgress = 0;
        let lastTime = 0;
        let rafId = null;

        function sendAnimationUpdate() {
            // The entry can be cleared out from under this RAF when a snap
            // (`WAAPI.retarget`) or restart deletes it from `activeAnimations`
            // before our queued frame runs. Sending a stale mid-flight
            // `propertyUpdate` after a snap would race the snap and regress
            // Elm's snapshot back toward the cancelled position. Bail out and
            // do not reschedule — `animation.playState` is no longer
            // `running` after the cancel, so the loop would have died on its
            // own next frame anyway.
            const currentEntry = getEntry();
            if (!currentEntry || currentEntry.version !== version) {
                rafId = null;
                return;
            }

            const now = performance.now();
            const playStateAtTick = animation.playState;
            const groupThrottleMs = animationGroups.get(animGroup)?.throttleIntervalMs;
            const effectiveThrottleMs = (typeof groupThrottleMs === 'number' && Number.isFinite(groupThrottleMs) && groupThrottleMs > 0)
                ? groupThrottleMs
                : propertyUpdateIntervalMs;

            if (effectiveThrottleMs <= 0 || now - lastTime >= effectiveThrottleMs) {
                const entry = getEntry();
                if (entry && entry.version === version) {
                    updateGroupIterationState(animGroup, entry.generation, entry.propertyIndex, animation);
                }

                // getLiveTransformState is invoked for its `lastKnownTransforms`
                // side-effect: the resize machinery in `animations.js` reads that
                // cache to anchor proportional rescaling on the next viewport
                // resize. The returned state is no longer sent to Elm — Elm
                // interpolates from its own anchored start using the per-property
                // progress emitted below.
                const transformState = getLiveTransformState(animGroup, animation, resolvedTransformValues, transformAnimDuration);
                lastComputedTransformState = transformState;

                const globalProgress = getAnimationProgress(animGroup, animation);
                lastProgress = globalProgress;

                const propertyProgress = resolvedTransformValues
                    ? buildTransformSubPropertyProgress(globalProgress, resolvedTransformValues, transformAnimDuration)
                    : { [propertyType]: globalProgress };

                const isAnimatingFlag = playStateAtTick === 'running';

                sendTrackedPropertyUpdate(
                    animGroup,
                    null,
                    null,
                    propertyProgress,
                    isAnimatingFlag,
                    globalProgress
                );
                lastTime = now;
            }

            if (animation.playState === 'running') {
                rafId = requestAnimationFrame(sendAnimationUpdate);
            } else {
                rafId = null;
            }
        }

        rafId = requestAnimationFrame(sendAnimationUpdate);
        let finishHandled = false;

        animation.addEventListener('finish', () => {
            finishHandled = true;

            let authoredFinalState = null;

            if (rafId !== null) {
                cancelAnimationFrame(rafId);
                rafId = null;
            }
            try {
                if (propertyType === 'transform') {
                    // We authored every keyframe, so the resting place is the
                    // resolved end values - exact numbers in the user's own
                    // units. Commit those authored values directly instead of
                    // reading the compositor's matrix back and decomposing it
                    // (matrix decomposition is lossy/ambiguous for combined
                    // transforms and is what produced interrupt snaps). Writing
                    // the authored end also pins iOS Safari past any stale
                    // last-keyframe tail commit.
                    authoredFinalState = buildAuthoredFinalState(resolvedTransformValues);

                    if (authoredFinalState) {
                        animation.cancel();

                        const order = getElementOrder(element);
                        element.style.transform = buildTransformString(
                            authoredFinalState.x, authoredFinalState.y, authoredFinalState.z,
                            authoredFinalState.scaleX, authoredFinalState.scaleY, authoredFinalState.scaleZ,
                            authoredFinalState.rotateX, authoredFinalState.rotateY, authoredFinalState.rotateZ,
                            authoredFinalState.skewX, authoredFinalState.skewY,
                            order,
                            null,
                            authoredFinalState.translateUnitX,
                            authoredFinalState.translateUnitY,
                            authoredFinalState.translateUnitZ
                        );
                    } else {
                        commitAnimatedStyles(element, animation);
                        animation.cancel();
                    }
                } else {
                    commitAnimatedStyles(element, animation);
                    animation.cancel();
                }
            } catch (commitError) {
                reportError(commitError, {
                    source: 'animationEvents',
                    severity: 'warning',
                    code: 'COMMIT_STYLES_FAILED',
                    details: { animGroup: animGroup, propertyType: propertyType }
                });
                try {
                    animation.cancel();
                } catch (cancelError) {
                    reportError(cancelError, {
                        source: 'animationEvents',
                        severity: 'warning',
                        code: 'ANIMATION_CANCEL_FAILED',
                        details: { animGroup: animGroup, propertyType: propertyType }
                    });
                }
            }

            const wasActive = isActiveEntry();
            const entryGeneration = getEntry()?.generation;
            removeTrackedAnimationVersion(animGroup, propertyType, version);

            if (wasActive && entryGeneration != null && animationGroups.get(animGroup)?.generation === entryGeneration) {
                const allComplete = finalizeAnimationTracking(animGroup, entryGeneration, 'completed');
                // Cache end-of-animation transform state for the next resize and
                // the next animation's start. Authored resolved-end values are
                // the single source of truth - never a decomposed DOM matrix.
                if (propertyType === 'transform' && authoredFinalState) {
                    lastKnownTransforms.set(animGroup, authoredFinalState);
                    // Emit settled transform values so Elm baseline matches JS committed state
                    sendSettledTransformValues(animGroup, {
                        translate: {
                            x: authoredFinalState.x,
                            y: authoredFinalState.y,
                            z: authoredFinalState.z,
                            unitX: authoredFinalState.translateUnitX,
                            unitY: authoredFinalState.translateUnitY,
                            unitZ: authoredFinalState.translateUnitZ
                        },
                        scale: {
                            x: authoredFinalState.scaleX,
                            y: authoredFinalState.scaleY,
                            z: authoredFinalState.scaleZ
                        },
                        rotate: {
                            x: authoredFinalState.rotateX,
                            y: authoredFinalState.rotateY,
                            z: authoredFinalState.rotateZ
                        },
                        skew: {
                            x: authoredFinalState.skewX,
                            y: authoredFinalState.skewY
                        }
                    });
                } else {
                    cacheFinalTransformState(animGroup, resolvedTransformValues);
                }
                const finalProgress = resolvedTransformValues
                    ? Object.fromEntries(TRANSFORM_SUB_PROPS.map(k => [k, 1]))
                    : { [propertyType]: 1 };
                sendTrackedPropertyUpdate(animGroup, propertyType, version, finalProgress, !allComplete);
            }
        });

        animation.addEventListener('cancel', () => {
            if (finishHandled) return;

            const wasActive = isActiveEntry();
            const entryGeneration = getEntry()?.generation;
            removeTrackedAnimationVersion(animGroup, propertyType, version);

            if (wasActive && entryGeneration != null && animationGroups.get(animGroup)?.generation === entryGeneration) {
                const allCancelled = finalizeAnimationTracking(animGroup, entryGeneration, 'cancelled');
                // Freeze the cached transform state at the last-known live values
                // so resize math after cancel doesn't read a stale baseline.
                if (resolvedTransformValues && lastComputedTransformState) {
                    lastKnownTransforms.set(animGroup, lastComputedTransformState);
                }
                const cancelProgress = resolvedTransformValues
                    ? buildTransformSubPropertyProgress(lastProgress, resolvedTransformValues, transformAnimDuration)
                    : { [propertyType]: lastProgress };
                sendTrackedPropertyUpdate(animGroup, propertyType, version, cancelProgress, !allCancelled);
            }
        });

        return sendAnimationUpdate;
    }

    /* eslint-env browser */

    function isFiniteNumber(value) {
        return typeof value === 'number' && Number.isFinite(value);
    }

    function computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation) {
        if (!isFiniteNumber(oldCurrentTime) || !isFiniteNumber(oldDuration) || oldDuration <= 0) {
            return null;
        }

        const oldRawProgress = (oldCurrentTime % oldDuration) / oldDuration;
        let oldLegProgress = oldRawProgress;
        if (oldDirection === 'alternate' || oldDirection === 'alternate-reverse') {
            const computed = animation?.effect?.getComputedTiming?.() || {};
            const iter = computed.currentIteration;
            if (Number.isFinite(iter)) {
                const startsReversed = oldDirection === 'alternate-reverse';
                const isReverseLeg = (iter % 2 === 1) !== startsReversed;
                if (isReverseLeg) {
                    oldLegProgress = 1 - oldRawProgress;
                }
            }
        } else if (oldDirection === 'reverse') {
            oldLegProgress = 1 - oldRawProgress;
        }

        return oldLegProgress;
    }

    function axisBoundsChanged(oldStart, oldEnd, newStart, newEnd, epsilon = 0.001) {
        return Math.abs(oldStart - newStart) > epsilon || Math.abs(oldEnd - newEnd) > epsilon;
    }

    function chooseEffectiveAxisValue(oldStart, oldEnd, newStart, newEnd, commandValue, liveValue) {
        if (!isFiniteNumber(liveValue)) {
            return commandValue;
        }

        return axisBoundsChanged(oldStart, oldEnd, newStart, newEnd)
            ? commandValue
            : liveValue;
    }

    function chooseDominantAxis(spans, epsilon = 0.0001) {
        let chosenAxis = null;
        let maxAbsSpan = epsilon;

        ['x', 'y', 'z'].forEach((axis) => {
            const span = Number(spans[axis]);
            const absSpan = Math.abs(span);
            if (isFiniteNumber(span) && absSpan > maxAbsSpan) {
                chosenAxis = axis;
                maxAbsSpan = absSpan;
            }
        });

        return chosenAxis;
    }

    function sanitizeResizeDuration(candidateDuration, oldDuration) {
        if (!isFiniteNumber(candidateDuration) || candidateDuration <= 0) {
            return oldDuration;
        }

        if (!isFiniteNumber(oldDuration) || oldDuration <= 0) {
            return candidateDuration;
        }

        const maxDuration = oldDuration * 8;

        // Keep lower durations untouched - end-of-leg resizes legitimately
        // shorten the remaining leg time. Clamp only implausible huge jumps.
        if (candidateDuration > maxDuration) {
            return oldDuration;
        }

        return candidateDuration;
    }

    const DEFAULT_TRANSFORM_KEYFRAME_COUNT = 30;

    function deriveTransformKeyframeCount(resolved) {
        const lengths = ['translate', 'scale', 'rotate', 'skew']
            .map((key) => resolved?.[key]?.easingKeyframes)
            .filter((keyframes) => Array.isArray(keyframes) && keyframes.length > 1)
            .map((keyframes) => keyframes.length);

        if (lengths.length === 0) {
            return DEFAULT_TRANSFORM_KEYFRAME_COUNT;
        }

        return Math.max(...lengths);
    }

    function getAnimationActiveTiming(animation) {
        const duration = Number(animation?.effect?.getTiming?.()?.duration) || 0;
        if (duration <= 0) {
            return null;
        }

        const currentTime = Number(animation?.currentTime);
        if (!Number.isFinite(currentTime)) {
            return null;
        }

        const delay = Number(animation?.effect?.getTiming?.()?.delay) || 0;
        const activeElapsed = Math.min(duration, Math.max(0, currentTime - delay));

        return {
            duration,
            activeElapsed,
            progress: activeElapsed / duration
        };
    }

    /**
     * Detect a resize cmd whose geometry exactly matches what the WAAPI
     * animation is already running. Used to short-circuit the cancel+recreate
     * path when Elm fires a resize purely because `currentTimeMs` advanced
     * (Progress event tick during a continuous drag) - if start/end/duration
     * for the resized slot are unchanged, recreating the animation would
     * needlessly seek the playhead and visually appear to speed the
     * animation up frame-by-frame during the drag.
     *
     * Comparison is strict (`===`) on the numbers Elm shipped: Elm's own
     * `noChange` guard already filters out near-equal geometry via its
     * epsilon, so any cmd that reaches JS with start/end/duration matching
     * the resolved slot byte-for-byte is the pure `currentTimeMs`-only case
     * we want to skip.
     */
    function isResizeGeometryUnchanged(commandData, slot, oldDuration) {
        if (!slot) {
            return false;
        }
        const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
        const hasBaseline = commandData.hasAnimationBaseline !== false;
        const newDuration = hasBaseline ? payloadDuration : oldDuration;
        return Number(commandData.startX) === Number(slot.startX)
            && Number(commandData.startY) === Number(slot.startY)
            && Number(commandData.startZ) === Number(slot.startZ)
            && Number(commandData.endX) === Number(slot.endX)
            && Number(commandData.endY) === Number(slot.endY)
            && Number(commandData.endZ) === Number(slot.endZ)
            && newDuration === Number(slot.duration);
    }

    /**
     * Perspective-origin counterpart of `isResizeGeometryUnchanged`. Same
     * short-circuit purpose, with two differences from the translate version:
     *
     * - Perspective-origin is 2D, so Z is omitted.
     * - The slot has a `unit` (`%` / `px`); a unit change must invalidate the
     *   skip even if the numeric start/end are unchanged.
     *
     * Duration is read from `oldDuration` (the live WAAPI timing) because
     * the resolved non-transform slot does not store a `duration` field —
     * the animation's own effect timing is the source of truth.
     */
    function isPerspectiveOriginGeometryUnchanged(commandData, slot, oldDuration) {
        if (!slot) {
            return false;
        }
        const incomingUnit = typeof commandData.unit === 'string' ? commandData.unit : '%';
        if (incomingUnit !== slot.unitX || incomingUnit !== slot.unitY) {
            return false;
        }
        const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
        const hasBaseline = commandData.hasAnimationBaseline !== false;
        const newDuration = hasBaseline ? payloadDuration : oldDuration;
        return Number(commandData.startX) === Number(slot.startX)
            && Number(commandData.startY) === Number(slot.startY)
            && Number(commandData.endX) === Number(slot.endX)
            && Number(commandData.endY) === Number(slot.endY)
            && newDuration === oldDuration;
    }

    function isSizeGeometryUnchanged(commandData, slot, oldDuration) {
        if (!slot) {
            return false;
        }
        const incomingUnit = typeof commandData.unit === 'string' ? commandData.unit : 'px';
        if (incomingUnit !== slot.unitWidth || incomingUnit !== slot.unitHeight) {
            return false;
        }
        const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
        const hasBaseline = commandData.hasAnimationBaseline !== false;
        const newDuration = hasBaseline ? payloadDuration : oldDuration;
        return Number(commandData.startX) === Number(slot.startWidth)
            && Number(commandData.startY) === Number(slot.startHeight)
            && Number(commandData.endX) === Number(slot.endWidth)
            && Number(commandData.endY) === Number(slot.endHeight)
            && newDuration === oldDuration;
    }

    const TRANSFORM_STATE_KEYS = {
        translate: { x: 'x', y: 'y', z: 'z' },
        scale: { x: 'scaleX', y: 'scaleY', z: 'scaleZ' },
        rotate: { x: 'rotateX', y: 'rotateY', z: 'rotateZ' },
        skew: { x: 'skewX', y: 'skewY' }
    };

    const START_FILL_AXES = {
        translate: [
            { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'x' },
            { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'y' },
            { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'z' }
        ],
        scale: [
            { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'scaleX' },
            { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'scaleY' },
            { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'scaleZ' }
        ],
        rotate: [
            { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'rotateX' },
            { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'rotateY' },
            { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'rotateZ' }
        ],
        skew: [
            { startKey: 'startX', stateKey: 'skewX' },
            { startKey: 'startY', stateKey: 'skewY' }
        ]
    };

    const RESOLVED_TRANSFORM_AXES = {
        translate: [
            { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'x', useDefault: true },
            { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'y', useDefault: true },
            { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'z', useDefault: true }
        ],
        scale: [
            { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'scaleX', useDefault: true },
            { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'scaleY', useDefault: true },
            { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'scaleZ', useDefault: true }
        ],
        rotate: [
            { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'rotateX', useDefault: true },
            { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'rotateY', useDefault: true },
            { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'rotateZ', useDefault: true }
        ],
        skew: [
            { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'skewX', useDefault: false },
            { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'skewY', useDefault: false }
        ]
    };

    function fillMissingTransformStarts(property, currentState) {
        const axes = START_FILL_AXES[property.type];
        if (!axes) {
            return;
        }

        axes.forEach(({ startKey, defaultKey, stateKey }) => {
            const defaultMissing = !defaultKey || property[defaultKey] == null;
            if (property[startKey] == null && defaultMissing) {
                property[startKey] = currentState[stateKey];
            }
        });
    }

    // For each axis Elm has declared frozen on this property, anchor both the
    // start and end values to where that axis currently rests.
    //
    // MID-FLIGHT: Elm's `runtimeBaseline` is updated asynchronously via the
    // `motionMsg` port and is therefore one or more frames behind the actual
    // rendered position; using its (stale) snapshot as both endpoints of a
    // "frozen" axis produces a visible backward jump when the user retargets a
    // sibling axis mid-flight. The live transform read from the in-flight
    // animation is the only source of truth in that case.
    //
    // SETTLED: once the prior animation has finished there is no race - the
    // axis is holding at the exact value Elm last commanded. The resolved end
    // value (`currentState`, sampled at progress 1.0) is that exact ledger
    // value, already expressed in the user's own unit. A live DOM read here
    // would round-trip through matrix decomposition and px-to-unit conversion,
    // both lossy, producing the few-pixel snap. So for settled axes we trust
    // the ledger and skip the DOM read entirely.
    const FROZEN_AXIS_LIVE_FIELDS = {
        translate: { x: 'x', y: 'y', z: 'z' },
        scale: { x: 'scaleX', y: 'scaleY', z: 'scaleZ' },
        rotate: { x: 'rotateX', y: 'rotateY', z: 'rotateZ' },
        skew: { x: 'skewX', y: 'skewY' }
    };

    function findContainerForQueryUnits(element) {
        if (!element) {
            return null;
        }

        let cursor = element.parentElement;
        while (cursor) {
            const cs = window.getComputedStyle(cursor);
            const containerType = cs.containerType || '';
            if (containerType !== 'normal') {
                return cursor;
            }
            cursor = cursor.parentElement;
        }

        return element.parentElement;
    }

    function pxToTranslateUnit(pxValue, unit, axis, element) {
        if (!Number.isFinite(pxValue)) {
            return null;
        }

        if (!unit || unit === 'px') {
            return pxValue;
        }

        const viewportW = window.innerWidth || 0;
        const viewportH = window.innerHeight || 0;
        const container = findContainerForQueryUnits(element);
        const containerRect = container ? container.getBoundingClientRect() : null;
        const containerW = containerRect ? containerRect.width : 0;
        const containerH = containerRect ? containerRect.height : 0;

        switch (unit) {
            case 'cqw':
            case 'cqi':
                return containerW > 0 ? (pxValue * 100) / containerW : null;

            case 'cqh':
            case 'cqb':
                return containerH > 0 ? (pxValue * 100) / containerH : null;

            case 'cqmin': {
                const basis = Math.min(containerW, containerH);
                return basis > 0 ? (pxValue * 100) / basis : null;
            }

            case 'cqmax': {
                const basis = Math.max(containerW, containerH);
                return basis > 0 ? (pxValue * 100) / basis : null;
            }

            case 'vw':
            case 'dvw':
            case 'svw':
            case 'lvw':
                return viewportW > 0 ? (pxValue * 100) / viewportW : null;

            case 'vh':
            case 'dvh':
            case 'svh':
            case 'lvh':
                return viewportH > 0 ? (pxValue * 100) / viewportH : null;

            default:
                if (axis === 'x') {
                    const basis = containerW || viewportW;
                    return basis > 0 ? (pxValue * 100) / basis : null;
                }

                if (axis === 'y') {
                    const basis = containerH || viewportH;
                    return basis > 0 ? (pxValue * 100) / basis : null;
                }

                return null;
        }
    }

    function applyFrozenAxesFromLive(property, currentState, domLiveState, element, isSettled) {
        const axes = property.frozenAxes;
        if (!Array.isArray(axes) || axes.length === 0) {
            return;
        }
        const fieldMap = FROZEN_AXIS_LIVE_FIELDS[property.type];
        if (!fieldMap) {
            return;
        }

        for (const axis of axes) {
            const stateKey = fieldMap[axis];
            if (!stateKey) continue;
            const suffix = axis.toUpperCase();
            const startKey = `start${suffix}`;
            const endKey = `end${suffix}`;

            // Keep command-provided starts as a last resort only. During
            // interruptions, Elm's runtime snapshot can trail the compositor on
            // iOS by a few frames; freezing to that stale value causes visible
            // snaps when the animation finishes.
            const commandStartValue = Number.isFinite(property[startKey]) ? property[startKey] : null;

            // Use the true compositor value from computed style when available.
            // iOS WebKit can report a slightly different in-flight value than our
            // resolved-time interpolation during interruptions.
            const domLivePx = Number.isFinite(domLiveState?.[stateKey])
                ? domLiveState[stateKey]
                : null;

            // `currentState[stateKey]` is the exact resolved value (the ledger).
            // When settled this is Elm's last-commanded target in the user's own
            // unit, so we keep it and skip the lossy DOM override below.
            let liveValue = currentState[stateKey];
            if (!isSettled && domLivePx != null) {
                if (property.type === 'translate') {
                    const unitKey = axis === 'x' ? 'unitX' : axis === 'y' ? 'unitY' : 'unitZ';
                    const converted = pxToTranslateUnit(domLivePx, property[unitKey] || 'px', axis, element);
                    if (Number.isFinite(converted)) {
                        liveValue = converted;
                    }
                } else {
                    liveValue = domLivePx;
                }
            }
            if (!Number.isFinite(liveValue)) {
                liveValue = commandStartValue;
            }
            if (!Number.isFinite(liveValue)) continue;
            property[startKey] = liveValue;
            property[endKey] = liveValue;
        }
    }

    function patchTransformStartsFromAnimation(element, existingTransform, mergedTransformProperties) {
        if (!existingTransform.resolvedValues || !existingTransform.animation) {
            return;
        }

        const activeTiming = getAnimationActiveTiming(existingTransform.animation);
        if (!activeTiming) {
            return;
        }

        const currentState = computeTransformFromResolved(existingTransform.resolvedValues, activeTiming.progress, activeTiming.duration);
        const domLiveState = getCurrentTransform(element);
        const hasActiveCompositorAnimation = !!(element.getAnimations && element.getAnimations().length > 0);
        // A finished animation holds at its exact commanded end (the ledger);
        // trust that value for frozen axes instead of a lossy live DOM read.
        const isSettled = existingTransform.animation.playState === 'finished'
            || activeTiming.activeElapsed >= activeTiming.duration;
        mergedTransformProperties.forEach(property => {
            // On interruption, always re-anchor starts to the live in-flight state.
            // Command-provided starts can be stale (e.g. delayed groups), which
            // otherwise produces visible snaps before the next delay window.
            const axes = RESOLVED_TRANSFORM_AXES[property.type];
            if (axes) {
                axes.forEach(({ startKey, currentKey }) => {
                    const currentValue = currentState[currentKey];
                    if (Number.isFinite(currentValue)) {
                        property[startKey] = currentValue;
                    }
                });
            }

            // For mid-flight interrupts, timeline-derived progress can lag the
            // compositor by a frame on some browsers. Prefer the live rendered
            // translate position when available so retarget starts exactly where
            // the element currently is on screen.
            if (!isSettled && hasActiveCompositorAnimation && property.type === 'translate') {
                [
                    { axis: 'x', startKey: 'startX', unitKey: 'unitX' },
                    { axis: 'y', startKey: 'startY', unitKey: 'unitY' },
                    { axis: 'z', startKey: 'startZ', unitKey: 'unitZ' }
                ].forEach(({ axis, startKey, unitKey }) => {
                    const domPx = domLiveState?.[axis];
                    const converted = pxToTranslateUnit(domPx, property[unitKey] || 'px', axis, element);
                    if (Number.isFinite(converted)) {
                        property[startKey] = converted;
                    }
                });
            }

            fillMissingTransformStarts(property, currentState);
            applyFrozenAxesFromLive(property, currentState, domLiveState, element, isSettled);
        });
    }

    // Re-anchor a fresh transform animation's start values to JS's authoritative
    // resting place after a previous animation has settled.
    //
    // When an animation completes, `cleanupAnimGroup` removes the live WAAPI
    // entry, so the next command takes the no-existing-entry path and its start
    // values come straight from Elm's `runtimeBaseline`. That baseline can
    // diverge from where the element is actually rendered - most visibly after a
    // frozen-axis animation, where JS froze an axis to the live compositor value
    // while Elm kept its own (stale) snapshot. Starting from the stale baseline
    // then produces a visible snap on the first frame.
    //
    // `lastKnownTransforms` is intentionally retained across `cleanupAnimGroup`
    // and holds the exact authored values JS last committed to the DOM, so it is
    // the single source of truth for the resting place. Pin every axis start to
    // it, and pin the end of any frozen axis too (a frozen axis must not move, so
    // its end has to match the rest rather than Elm's stale target).
    function anchorFreshStartsToCachedRest(animGroup, mergedTransformProperties) {
        const cached = lastKnownTransforms.get(animGroup);
        if (!cached) {
            return;
        }
        mergedTransformProperties.forEach(property => {
            const axes = RESOLVED_TRANSFORM_AXES[property.type];
            if (!axes) {
                return;
            }
            const frozen = Array.isArray(property.frozenAxes) ? property.frozenAxes : [];
            axes.forEach(({ suffix, startKey, endKey, currentKey }) => {
                const restValue = cached[currentKey];
                if (!Number.isFinite(restValue)) {
                    return;
                }
                // The cached rest stores translate values in their own unit; only
                // re-anchor when the new animation shares that unit, otherwise the
                // numeric value would be reinterpreted under the wrong unit.
                if (property.type === 'translate') {
                    const propUnit = property[`unit${suffix}`] || 'px';
                    const cachedUnit = cached[`translateUnit${suffix}`] || 'px';
                    if (propUnit !== cachedUnit) {
                        return;
                    }
                }
                property[startKey] = restValue;
                if (frozen.includes(suffix.toLowerCase())) {
                    property[endKey] = restValue;
                }
            });
        });
    }

    function scaleOpacityInterruptDuration(existingEntry, resolvedNonTransform, fallbackDuration) {
        const previous = existingEntry?.resolvedNonTransform;
        const previousAnimation = existingEntry?.animation;
        const previousTiming = previousAnimation?.effect?.getTiming?.() || {};
        const previousDuration = Number(previousTiming.duration);

        if (!previous || !Number.isFinite(previousDuration) || previousDuration <= 0) {
            return fallbackDuration;
        }

        const previousDistance = Math.abs(Number(previous.endValue) - Number(previous.startValue));
        const nextDistance = Math.abs(Number(resolvedNonTransform.endValue) - Number(resolvedNonTransform.startValue));

        if (!Number.isFinite(previousDistance) || previousDistance <= 0 || !Number.isFinite(nextDistance)) {
            return fallbackDuration;
        }

        return Math.max(0, nextDistance * (previousDuration / previousDistance));
    }

    function isActiveOpacityInterrupt(existingEntry) {
        const playState = existingEntry?.animation?.playState;
        return playState === 'running' || playState === 'paused' || playState === 'pending';
    }

    function buildRetainedTransformProperty(oldProp, currentTransform, elapsedMs) {
        const keys = TRANSFORM_STATE_KEYS[oldProp.type];
        const originalDuration = oldProp.duration || 0;
        const remainingDuration = Math.max(0, originalDuration - elapsedMs);
        return {
            type: oldProp.type,
            // Start from the live mid-flight value so the axis continues smoothly
            // from where it currently is on screen.
            startX: currentTransform[keys.x],
            startY: currentTransform[keys.y],
            startZ: keys.z ? currentTransform[keys.z] : undefined,
            // Continue toward the ORIGINAL target rather than freezing at the
            // current value. Combined with remainingDuration below, this lets
            // untouched in-flight axes carry on toward their goal while a sibling
            // axis is re-animated.
            endX: oldProp.endX,
            endY: oldProp.endY,
            endZ: keys.z ? oldProp.endZ : undefined,
            // Easing approximation: applying the same easing function over the
            // remainder of the curve is exact for `linear` and a perceptual
            // approximation for non-linear curves (the true tail of e.g. an
            // `ease-out` curve is a different bezier, but the visual difference
            // is typically imperceptible). Complex pre-baked easingKeyframes
            // (bounce / elastic / spring) are dropped here because the array
            // covers 0..1 of the FULL animation and replaying it across the
            // remainder would produce visible artifacts. A future improvement
            // could slice the keyframe tail and rescale.
            easing: oldProp.easing || 'linear',
            easingKeyframes: null,
            duration: remainingDuration,
            version: oldProp.version || 1
        };
    }

    /**
     * Determine which transform sub-property groups must be force-emitted in
     * every keyframe of a WAAPI animation. Returns a Set containing any of
     * `'translate' | 'scale' | 'rotate' | 'skew'`.
     *
     * WAAPI requires every keyframe in an animation to list the same set of
     * transform functions to interpolate per-function (e.g. animating
     * `rotateX` directly). If keyframes differ, the browser falls back to
     * matrix3d decomposition, which silently drops rotation when either
     * endpoint produces an identity rotation matrix (e.g. `rotateX(360deg)`
     * decomposes to identity). The fix is to force-emit a group on every
     * keyframe whenever any endpoint of the resolved animation is non-identity
     * for that group, so the function lists match across all keyframes.
     */
    function computeForceGroups(resolved) {
        const force = new Set();
        const isAxisActive = (group, identity, axes) => {
            const value = resolved[group];
            if (!value) return false;
            for (const axis of axes) {
                const start = value[`start${axis}`];
                const end = value[`end${axis}`];
                if (Number.isFinite(start) && start !== identity) return true;
                if (Number.isFinite(end) && end !== identity) return true;
            }
            return false;
        };
        if (isAxisActive('translate', 0, ['X', 'Y', 'Z'])) force.add('translate');
        if (isAxisActive('scale', 1, ['X', 'Y', 'Z'])) force.add('scale');
        if (isAxisActive('rotate', 0, ['X', 'Y', 'Z'])) force.add('rotate');
        if (isAxisActive('skew', 0, ['X', 'Y'])) force.add('skew');
        return force;
    }

    function buildDefaultResolvedTransform(currentTransform) {
        return {
            translate: {
                startX: currentTransform.x, startY: currentTransform.y, startZ: currentTransform.z,
                endX: currentTransform.x, endY: currentTransform.y, endZ: currentTransform.z,
                easing: null, easingKeyframes: null, duration: 0,
                unitX: currentTransform.translateUnitX || 'px',
                unitY: currentTransform.translateUnitY || 'px',
                unitZ: currentTransform.translateUnitZ || 'px'
            },
            scale: {
                startX: currentTransform.scaleX, startY: currentTransform.scaleY, startZ: currentTransform.scaleZ,
                endX: currentTransform.scaleX, endY: currentTransform.scaleY, endZ: currentTransform.scaleZ,
                easing: null, easingKeyframes: null, duration: 0
            },
            rotate: {
                startX: currentTransform.rotateX, startY: currentTransform.rotateY, startZ: currentTransform.rotateZ,
                endX: currentTransform.rotateX, endY: currentTransform.rotateY, endZ: currentTransform.rotateZ,
                easing: null, easingKeyframes: null, duration: 0
            },
            skew: {
                startX: currentTransform.skewX, startY: currentTransform.skewY,
                endX: currentTransform.skewX, endY: currentTransform.skewY,
                easing: null, easingKeyframes: null, duration: 0
            }
        };
    }

    function assignResolvedTransformProperty(target, property, currentTransform, axes) {
        axes.forEach(({ suffix, startKey, endKey, currentKey, useDefault }) => {
            const defaultValue = useDefault ? property[`default${suffix}`] : undefined;
            // Start values must anchor to the current live/cached transform state
            // when not explicitly provided, so sequential phases (e.g. 360 -> 0)
            // animate from the prior phase end instead of snapping to defaults.
            target[startKey] = property[`start${suffix}`] ?? currentTransform[currentKey] ?? defaultValue;
            target[endKey] = property[`end${suffix}`] ?? currentTransform[currentKey];
        });
        target.easing = property.easing;
        target.easingKeyframes = property.easingKeyframes;
        target.duration = property.duration;
        if (property.type === 'translate') {
            if (typeof property.unitX === 'string' && property.unitX.length > 0) {
                target.unitX = property.unitX;
            }
            if (typeof property.unitY === 'string' && property.unitY.length > 0) {
                target.unitY = property.unitY;
            }
            if (typeof property.unitZ === 'string' && property.unitZ.length > 0) {
                target.unitZ = property.unitZ;
            }
        }
    }

    function carryForwardMissingTransformProperties(animGroup, element, existingTransform, mergedTransformProperties) {
        if (!existingTransform.transformProperties) {
            return;
        }

        const newPropTypes = new Set(mergedTransformProperties.map(property => property.type));

        // Compute the live mid-flight transform from the running animation so
        // retained axes can continue from where they actually are on screen at
        // this exact moment. Falls back to the cached transform state if the
        // running animation has no resolved values yet.
        let liveTransform = null;
        const activeTiming = getAnimationActiveTiming(existingTransform.animation);
        if (existingTransform.resolvedValues && activeTiming) {
            liveTransform = computeTransformFromResolved(existingTransform.resolvedValues, activeTiming.progress, activeTiming.duration);
        }
        const currentTransform = liveTransform || getTransformState(animGroup, element);

        existingTransform.transformProperties.forEach(oldProp => {
            if (!newPropTypes.has(oldProp.type)) {
                mergedTransformProperties.push(buildRetainedTransformProperty(oldProp, currentTransform, activeTiming?.activeElapsed || 0));
            }
        });
    }

    function cancelLegacyTransformAnimations(elementAnims) {
        ['translate', 'scale', 'rotate', 'skew'].forEach(propType => {
            if (elementAnims.has(propType)) {
                const existing = elementAnims.get(propType);
                // Delete BEFORE cancel so the listener's `isActiveEntry()`
                // guard returns false and the listener exits silently.
                elementAnims.delete(propType);
                try {
                    existing.animation.cancel();
                } catch (_) {
                    // Already-cancelled / detached handles are safe to ignore.
                }
            }
        });
    }

    function markAnimationGroupStarted(animGroup) {
        const groupInfo = animationGroups.get(animGroup);
        if (groupInfo && !groupInfo.started) {
            groupInfo.started = true;
            sendLifecycleEvent('started', animGroup);
        }
    }

    function markAnimationGroupRun(animGroup) {
        const groupInfo = animationGroups.get(animGroup);
        if (groupInfo && !groupInfo.run) {
            groupInfo.run = true;
            sendLifecycleEvent('run', animGroup);
        }
    }

    /**
     * Convert the Elm-side `transformBaseline` payload (a snapshot of init/runtime
     * baseline values for translate, scale, rotate, skew) into the flat
     * transform-state shape used by `lastKnownTransforms`. Missing axes fall back
     * to identity defaults.
     */
    function baselineToTransformState(baseline) {
        const state = getDefaultTransformState();
        if (!baseline) {
            return state;
        }
        const num = (v, fallback) => Number.isFinite(v) ? v : fallback;
        if (baseline.translate) {
            state.x = num(baseline.translate.x, state.x);
            state.y = num(baseline.translate.y, state.y);
            state.z = num(baseline.translate.z, state.z);
        }
        if (baseline.scale) {
            state.scaleX = num(baseline.scale.x, state.scaleX);
            state.scaleY = num(baseline.scale.y, state.scaleY);
            state.scaleZ = num(baseline.scale.z, state.scaleZ);
        }
        if (baseline.rotate) {
            state.rotateX = num(baseline.rotate.x, state.rotateX);
            state.rotateY = num(baseline.rotate.y, state.rotateY);
            state.rotateZ = num(baseline.rotate.z, state.rotateZ);
        }
        if (baseline.skew) {
            state.skewX = num(baseline.skew.x, state.skewX);
            state.skewY = num(baseline.skew.y, state.skewY);
        }
        return state;
    }

    function processElementAnimation(animGroup, elementConfig, globalOptions = { iterations: 1, direction: 'normal' }, isRestart = false, resolvedElement = null) {
        const element = resolvedElement || findAnimTarget(animGroup);
        if (!element) {
            reportError(`Element with data-anim-target="${animGroup}" not found`, {
                source: 'animation',
                severity: 'warning',
                code: 'TARGET_NOT_FOUND',
                engine: 'WAAPI',
                elementId: animGroup
            });
            return;
        }

        const properties = elementConfig.properties || [];

        // Seed the GPU-hint optimisation before any keyframes are computed so
        // the compositor can promote the element to its own layer for the very
        // first frame. Cleared by `cleanupAnimGroup` once all animations on
        // this animGroup finish or cancel.
        if (elementConfig.willChange && typeof elementConfig.willChange === 'string') {
            try {
                element.style.willChange = elementConfig.willChange;
                appliedWillChange.set(animGroup, { element: element, value: elementConfig.willChange });
            } catch (_) {
                // Hostile environments (e.g. frozen styles) — non-fatal.
            }
        }

        const transformOrder = elementConfig.transformOrder;
        if (transformOrder && transformOrder.length > 0) {
            elementTransformOrders.set(animGroup, transformOrder);
        }

        // Seed `lastKnownTransforms` from the Elm-side snapshot baseline before
        // any keyframes are computed. This ensures init-only transform values
        // (e.g. `Translate.initZ animGroup 200`) survive the moment Elm hands
        // ownership of the inline `transform` style to JS — without this,
        // `getTransformState` would fall back to reading the (now-empty)
        // inline transform and silently default missing axes to identity.
        // We only seed when the cache is empty for this animGroup, so that
        // post-animation `commitStyles` results from prior generations remain
        // authoritative.
        if (elementConfig.transformBaseline && !lastKnownTransforms.has(animGroup)) {
            lastKnownTransforms.set(animGroup, baselineToTransformState(elementConfig.transformBaseline));
        }

        const transformProperties = properties.filter(property => isTransformProperty(property.type));
        const nonTransformProperties = properties.filter(property => !isTransformProperty(property.type));

        if (!activeAnimations.has(animGroup)) {
            activeAnimations.set(animGroup, new Map());
        }
        const elementAnims = activeAnimations.get(animGroup);

        const existingGroup = animationGroups.get(animGroup);
        const generation = isRestart ? (existingGroup?.generation || 0) : ((existingGroup?.generation || 0) + 1);

        // Reset the group bookkeeping for the new generation. `totalProperties`,
        // `propertyIterations` and `propertyConfigs` are filled in below as new
        // animations are created and as carryover (still-running, untouched)
        // animations are re-keyed to the new generation. Without carrying forward
        // those untouched entries, the new generation's `finalizeAnimationTracking`
        // would treat itself as complete as soon as the new (often very short)
        // animations finish - and `cleanupAnimGroup` would then wipe the still-
        // running animations' bookkeeping, freezing the per-frame propertyUpdate
        // values Elm uses for snapshot baselines.
        animationGroups.set(animGroup, {
            totalProperties: 0,
            completedProperties: 0,
            run: false,
            started: false,
            generation: generation,
            nextPropertyIndex: 0,
            lastIteration: 0,
            propertyIterations: [],
            propertyConfigs: [],
            throttleIntervalMs: (typeof elementConfig.throttleIntervalMs === 'number' && Number.isFinite(elementConfig.throttleIntervalMs) && elementConfig.throttleIntervalMs > 0)
                ? elementConfig.throttleIntervalMs
                : 0
        });

        markAnimationGroupRun(animGroup);

        if (transformProperties.length > 0) {
            const mergedTransformProperties = [...transformProperties];

            if (elementAnims.has('transform')) {
                const existingTransform = elementAnims.get('transform');

                // Restart must replay from the authored start values in the incoming
                // config. Do not patch starts from the live in-flight transform.
                // Also skip patching if the previous animation has already
                // completed, because that snapshot would collapse start=end.
                if (!isRestart && !isAnimationCompleted(existingTransform.animation)) {
                    patchTransformStartsFromAnimation(element, existingTransform, mergedTransformProperties);
                    carryForwardMissingTransformProperties(animGroup, element, existingTransform, mergedTransformProperties);
                }

                existingTransform.animation.cancel();
            } else {
                // Fresh animate calls should snap stale starts to the committed rest
                // snapshot, but restart must always replay from authored starts.
                if (!isRestart) {
                    anchorFreshStartsToCachedRest(animGroup, mergedTransformProperties);
                }
            }

            cancelLegacyTransformAnimations(elementAnims);

            const maxVersion = Math.max(...mergedTransformProperties.map(property => property.version || 1));
            const mergeResult = createMergedTransformAnimation(animGroup, element, mergedTransformProperties, globalOptions);

            if (mergeResult) {
                const { animation, resolved: resolvedTransformValues } = mergeResult;
                const entry = {
                    animation: animation,
                    version: maxVersion,
                    animGroup: animGroup,
                    easingKeyframes: null,
                    transformProperties: mergedTransformProperties,
                    resolvedValues: resolvedTransformValues,
                    generation: generation,
                    propertyIndex: allocatePropertyIndex(animGroup)
                };
                elementAnims.set('transform', entry);
                entry.updateFn = setupAnimationEvents(animGroup, 'transform', element, animation, maxVersion, resolvedTransformValues);

                const groupInfo = animationGroups.get(animGroup);
                if (groupInfo) {
                    transformProperties.forEach(property => {
                        groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
                    });
                }

                markAnimationGroupStarted(animGroup);
            }
        }

        nonTransformProperties.forEach(property => {
            const propType = (property.type === 'customProperty')
                ? `custom:${property.cssProperty}`
                : (property.type === 'customColorProperty')
                    ? `customColor:${property.cssProperty}`
                    : property.type;
            const newVersion = property.version || 1;

            const existingEntry =
                elementAnims.has(propType)
                    ? elementAnims.get(propType)
                    : null;

            const shouldAdjustOpacityInterrupt =
                propType === 'opacity' && existingEntry && isActiveOpacityInterrupt(existingEntry);

            if (existingEntry) {
                existingEntry.animation.cancel();
            }

            const resolvedNonTransform = resolveNonTransformValues(animGroup, element, property);
            const propertyForAnimation =
                shouldAdjustOpacityInterrupt
                    ? {
                        ...property,
                        duration: scaleOpacityInterruptDuration(existingEntry, resolvedNonTransform, property.duration)
                    }
                    : property;

            const animation = createPropertyAnimation(element, resolvedNonTransform, propertyForAnimation, globalOptions);

            if (animation) {
                const entry = {
                    animation: animation,
                    version: newVersion,
                    animGroup: animGroup,
                    easingKeyframes: property.easingKeyframes || null,
                    resolvedNonTransform: resolvedNonTransform,
                    generation: generation,
                    propertyIndex: allocatePropertyIndex(animGroup)
                };
                elementAnims.set(propType, entry);
                entry.updateFn = setupAnimationEvents(animGroup, propType, element, animation, newVersion, null);

                const groupInfo = animationGroups.get(animGroup);
                if (groupInfo) {
                    groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
                }

                markAnimationGroupStarted(animGroup);
            }
        });

        // Carry forward any entries that this call did not supersede so that the
        // new generation accounts for them. They were created in a previous
        // generation; without re-keying, their `finish`/`cancel` handlers would
        // skip `finalizeAnimationTracking` (generation mismatch) and the new
        // generation's totals would be wrong.
        elementAnims.forEach(entry => {
            if (entry.generation !== generation) {
                entry.generation = generation;
                entry.propertyIndex = allocatePropertyIndex(animGroup);
                const carryDuration = entry.animation?.effect?.getTiming()?.duration || 0;
                const groupInfo = animationGroups.get(animGroup);
                if (groupInfo) {
                    groupInfo.propertyConfigs.push({ duration: carryDuration });
                }
            }
        });

        const finalGroupInfo = animationGroups.get(animGroup);
        if (finalGroupInfo) {
            finalGroupInfo.totalProperties = elementAnims.size;
            finalGroupInfo.propertyIterations = new Array(elementAnims.size).fill(0);
        }

        if (elementAnims.size === 0) {
            cleanupAnimGroup(animGroup);
        }
    }

    function allocatePropertyIndex(animGroup) {
        const groupInfo = animationGroups.get(animGroup);
        if (!groupInfo) return 0;
        const index = groupInfo.nextPropertyIndex;
        groupInfo.nextPropertyIndex++;
        return index;
    }

    function createMergedTransformAnimation(animGroup, element, transformProperties, globalOptions = { iterations: 1, direction: 'normal' }) {
        const currentTransform = getTransformState(animGroup, element);
        const order = getElementOrder(element);
        const resolved = buildDefaultResolvedTransform(currentTransform);
        const maxDelay = Math.max(0, ...transformProperties.map(property => property.delay || 0));

        let maxDuration = 0;

        transformProperties.forEach(property => {
            const target = resolved[property.type];
            const axes = RESOLVED_TRANSFORM_AXES[property.type];
            if (target && axes) {
                assignResolvedTransformProperty(target, property, currentTransform, axes);
            }
            if (property.duration > maxDuration) {
                maxDuration = property.duration;
            }
        });

        const activeProps = transformProperties.map(property => resolved[property.type]);
        const allSameEasing = activeProps.every(item => !item.easingKeyframes && item.easing === activeProps[0].easing);
        const allSameDuration = activeProps.every(item => item.duration === activeProps[0].duration);

        const forceGroups = computeForceGroups(resolved);

        if (allSameEasing && allSameDuration) {
            const tUx = resolved.translate.unitX || 'px';
            const tUy = resolved.translate.unitY || 'px';
            const tUz = resolved.translate.unitZ || 'px';
            const startTransform = buildTransformString(
                resolved.translate.startX, resolved.translate.startY, resolved.translate.startZ,
                resolved.scale.startX, resolved.scale.startY, resolved.scale.startZ,
                resolved.rotate.startX, resolved.rotate.startY, resolved.rotate.startZ,
                resolved.skew.startX, resolved.skew.startY, order, forceGroups, tUx, tUy, tUz
            );
            const endTransform = buildTransformString(
                resolved.translate.endX, resolved.translate.endY, resolved.translate.endZ,
                resolved.scale.endX, resolved.scale.endY, resolved.scale.endZ,
                resolved.rotate.endX, resolved.rotate.endY, resolved.rotate.endZ,
                resolved.skew.endX, resolved.skew.endY, order, forceGroups, tUx, tUy, tUz
            );

            const easing = activeProps[0].easing;
            const animationEasing = easingFunctions[easing] || easing;
            const singleEasingTiming = {
                duration: maxDuration,
                delay: maxDelay,
                easing: animationEasing,
                fill: maxDelay > 0 ? 'both' : 'forwards',
                iterations: globalOptions.iterations,
                direction: globalOptions.direction
            };
            return {
                animation: element.animate([
                    { transform: startTransform },
                    { transform: endTransform }
                ], applyReducedMotion(singleEasingTiming)),
                resolved: resolved
            };
        }

        const KEYFRAME_COUNT = deriveTransformKeyframeCount(resolved);
        const keyframes = [];

        for (let index = 0; index < KEYFRAME_COUNT; index++) {
            const globalProgress = index / (KEYFRAME_COUNT - 1);
            const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
            const interpScale = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
            const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
            const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);

            keyframes.push({
                transform: buildTransformString(
                    interpTranslate.x, interpTranslate.y, interpTranslate.z,
                    interpScale.x, interpScale.y, interpScale.z,
                    interpRotate.x, interpRotate.y, interpRotate.z,
                    interpSkew.x, interpSkew.y, order, forceGroups,
                    resolved.translate.unitX || 'px',
                    resolved.translate.unitY || 'px',
                    resolved.translate.unitZ || 'px'
                )
            });
        }

        const perKeyframeTiming = {
            duration: maxDuration,
            delay: maxDelay,
            easing: 'linear',
            fill: maxDelay > 0 ? 'both' : 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        };
        return {
            animation: element.animate(keyframes, applyReducedMotion(perKeyframeTiming)),
            resolved: resolved
        };
    }

    function isAnimationCompleted(animation) {
        if (!animation) {
            return false;
        }

        if (animation.playState === 'finished') {
            return true;
        }

        const timing = animation.effect?.getComputedTiming?.();
        if (!timing) {
            return false;
        }

        return Number.isFinite(timing.progress) && timing.progress >= 1;
    }

    /**
     * Persist a resized translate or scale value into the `lastKnownTransforms`
     * cache and into the element's inline `style.transform`.
     *
     * Inline write rationale: once any transform sub-property is animated by
     * WAAPI, the transform slot is "JS-owned" and Elm's `WAAPI.attributes`
     * stops rendering inline `transform` to avoid fighting the running
     * animation. That means JS is now the sole writer for inline `transform`,
     * and resize must update it so the resized value is visible after the
     * animation finishes/cancels (and so the DOM truthfully reflects the
     * post-resize state in devtools). While an animation is running, WAAPI
     * fully shadows the inline value, so this write is invisible until the
     * animation releases the slot — exactly when we need it.
     */
    function persistResizedTransform(animGroup, element, propertyKey, currentResized) {
        const current = getTransformState(animGroup, element);
        const updated = { ...current };
        if (propertyKey === 'scale') {
            updated.scaleX = currentResized.x;
            updated.scaleY = currentResized.y;
            updated.scaleZ = currentResized.z;
        } else {
            updated.x = currentResized.x;
            updated.y = currentResized.y;
            updated.z = currentResized.z;
        }
        lastKnownTransforms.set(animGroup, updated);

        const order = getElementOrder(element);
        const transformString = buildTransformString(
            updated.x, updated.y, updated.z,
            updated.scaleX, updated.scaleY, updated.scaleZ,
            updated.rotateX, updated.rotateY, updated.rotateZ,
            updated.skewX, updated.skewY, order, undefined,
            updated.translateUnitX || 'px',
            updated.translateUnitY || 'px',
            updated.translateUnitZ || 'px'
        );
        element.style.transform = transformString;
    }

    /**
     * Update the in-flight transform animation for a group's translate sub-property
     * to match new bounds, without restarting. Replaces the underlying
     * `Animation` with one that has the new keyframes/timing, then sets
     * `currentTime` so the box continues moving smoothly from where it is.
     *
     * Triggered by Elm `Anim.Engine.WAAPI.onResize`. The Elm side has already
     * computed the new translate `start` / `end` / `current` values, the new
     * leg duration, the resize `strategy`, and the `currentTime` to set —
     * see `Anim.Internal.Engine.WAAPI.computeResizePayload` and
     * `Anim.Internal.Engine.WAAPI.scaleDurationForResize` for the math.
     *
     * Strategy branches when seeking `currentTime`:
     * - `proportional` preserves the temporal progress ratio
     *   (`currentTime / duration`) so the eased visual position lands at the
     *   same fractional spot along the new leg, exactly, for any easing.
     * - `clamp` (and any unknown / missing value, for back-compat) solves
     *   for the `currentTime` that places the box at the Elm-supplied
     *   `currentX/Y/Z` value via a linear inversion of the leg span.
     *
     * Non-translate transform sub-properties (rotate, scale, skew) are
     * preserved at their current resolved values.
     *
     * Resize commands arrive at native input cadence (often 30+ per displayed
     * frame during a drag-resize). We coalesce them via `requestAnimationFrame`
     * so each unique `(animGroup, property)` does at most one cancel+recreate
     * per displayed frame. Without coalescing, the dot's compositor layer
     * spends most of each frame snapped to its base transform during the brief
     * gap between `animation.cancel()` and the new `Animation` being committed,
     * which visually freezes the dot during the drag.
     *
     * Tests bypass coalescing by importing `_resizeTransformAnimationImmediate`
     * directly (see `js/tests/resize.test.js`).
     *
     * @param {object} commandData - Decoded `resize` port command payload.
     */
    function resizeTransformAnimation(commandData) {
        scheduleResize(commandData);
    }

    /**
     * Per-frame resize coalescing. Keyed by `${animGroup}:${property || 'translate'}`
     * so commands targeting different properties of the same element do not
     * stomp each other. Only the latest payload per key per frame is applied.
     */
    const pendingResizes = new Map();
    let pendingResizeFrame = null;

    function scheduleResize(commandData) {
        const animGroup = commandData.elementId || commandData.animGroup;
        if (!animGroup) {
            // Let the immediate path emit the missing-id error so behaviour
            // matches pre-coalescing tests and runtime diagnostics.
            _resizeTransformAnimationImmediate(commandData);
            return;
        }
        const key = `${animGroup}:${commandData.property || 'translate'}`;
        pendingResizes.set(key, commandData);
        armResizeFrame();
    }

    function armResizeFrame() {
        const raf = typeof globalThis !== 'undefined' && typeof globalThis.requestAnimationFrame === 'function'
            ? globalThis.requestAnimationFrame
            : null;
        if (raf === null) {
            // No rAF (non-browser host) — flush synchronously to preserve behaviour.
            flushPendingResizes();
            return;
        }
        if (pendingResizeFrame !== null) {
            return;
        }
        pendingResizeFrame = raf(() => {
            pendingResizeFrame = null;
            flushPendingResizes();
        });
    }

    /**
     * Drain the coalesced resize queue immediately. Exported so tests and
     * shutdown paths can force a flush without waiting for a rAF tick.
     */
    function flushPendingResizes() {
        if (pendingResizes.size === 0) {
            return;
        }
        const resizeBatch = Array.from(pendingResizes.values());
        pendingResizes.clear();
        for (const payload of resizeBatch) {
            try {
                _resizeTransformAnimationImmediate(payload);
            } catch (err) {
                reportError(`resize flush failed: ${err && err.message ? err.message : err}`, {
                    source: 'animation',
                    severity: 'error',
                    code: 'COMMAND_FAILED',
                    engine: 'WAAPI'
                });
            }
        }
    }

    /**
     * Synchronous resize worker. Direct callers (tests, `flushPendingResizes`)
     * use this to bypass the per-frame coalescing layer.
     *
     * @param {object} commandData - Decoded `resize` port command payload.
     */
    function _resizeTransformAnimationImmediate(commandData) {
        const animGroup = commandData.elementId || commandData.animGroup;
        if (!animGroup) {
            reportError('resize command missing elementId/animGroup', {
                source: 'animation',
                severity: 'warning',
                code: 'COMMAND_INVALID',
                engine: 'WAAPI'
            });
            return;
        }

        const element = findAnimTarget(animGroup);
        if (!element) {
            reportError(`Element with data-anim-target="${animGroup}" not found`, {
                source: 'animation',
                severity: 'warning',
                code: 'TARGET_NOT_FOUND',
                engine: 'WAAPI',
                elementId: animGroup
            });
            return;
        }

        if (commandData.property === 'perspectiveOrigin') {
            resizePerspectiveOriginAnimation(commandData, animGroup, element);
            return;
        }

        if (commandData.property === 'size') {
            resizeSizeAnimation(commandData, animGroup, element);
            return;
        }

        const propertyKey = commandData.property === 'scale' ? 'scale' : 'translate';

        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims || !elementAnims.has('transform')) {
            return;
        }

        const existing = elementAnims.get('transform');
        const resolved = existing.resolvedValues;
        if (!resolved || !resolved[propertyKey]) {
            return;
        }

        const animation = existing.animation;
        if (!animation || !animation.effect) {
            return;
        }

        // Fast path: when start/end/duration of the resized slot are identical
        // to what JS already has, the resize cmd is purely advisory (Elm fired
        // because `currentTimeMs` drifted as Progress events advanced — the
        // engine's geometry is unchanged). Skipping the cancel+recreate avoids
        // a per-rAF restart that the user perceives as the animation speeding
        // up during a continuous window drag, while leaving the running WAAPI
        // animation to keep ticking on its own undisturbed clock.
        if (isResizeGeometryUnchanged(commandData, resolved[propertyKey], Number(animation.effect.getTiming().duration) || 0)) {
            return;
        }

        // Read the live pre-resize state. WAAPI preserves `currentIteration`
        // and direction across `setKeyframes` / `updateTiming`, so all we need
        // to preserve manually is the box's target physical position. Elm
        // computes that target via `Resize.applyAxis` (honouring Proportional
        // vs Clamp) and ships it as `currentX/Y/Z` in the payload — JS must
        // solve for the `currentTime` that lands the box at that target,
        // otherwise the strategy choice is silently overridden.
        const oldTiming = animation.effect.getTiming() || {};
        const oldDuration = Number(oldTiming.duration) || 0;
        const oldCurrentTime = Number(animation.currentTime) || 0;
        const oldDirection = oldTiming.direction || 'normal';
        const oldLegProgress = computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation);

        // Strategy-aware target position from Elm. Falls back to the box's
        // current physical position derived from the running animation if the
        // payload omits it (older callers / safety).
        const hasCurrentFromCommand = commandData.currentX !== undefined
            && commandData.currentY !== undefined
            && commandData.currentZ !== undefined;
        const oldVisualPosition = oldLegProgress !== null
            ? interpolateSubProperty(resolved[propertyKey], oldLegProgress, oldDuration)
            : null;

        const hasElmCurrentTime = typeof commandData.currentTimeMs === 'number' && isFinite(commandData.currentTimeMs);

        let targetPosition = null;
        if (!hasElmCurrentTime && oldVisualPosition) {
            targetPosition = {
                x: chooseEffectiveAxisValue(
                    Number(resolved[propertyKey].startX),
                    Number(resolved[propertyKey].endX),
                    Number(commandData.startX),
                    Number(commandData.endX),
                    hasCurrentFromCommand ? Number(commandData.currentX) : oldVisualPosition.x,
                    oldVisualPosition.x
                ),
                y: chooseEffectiveAxisValue(
                    Number(resolved[propertyKey].startY),
                    Number(resolved[propertyKey].endY),
                    Number(commandData.startY),
                    Number(commandData.endY),
                    hasCurrentFromCommand ? Number(commandData.currentY) : oldVisualPosition.y,
                    oldVisualPosition.y
                ),
                z: chooseEffectiveAxisValue(
                    Number(resolved[propertyKey].startZ),
                    Number(resolved[propertyKey].endZ),
                    Number(commandData.startZ),
                    Number(commandData.endZ),
                    hasCurrentFromCommand ? Number(commandData.currentZ) : oldVisualPosition.z,
                    oldVisualPosition.z
                )
            };
        } else if (hasCurrentFromCommand) {
            targetPosition = {
                x: Number(commandData.currentX),
                y: Number(commandData.currentY),
                z: Number(commandData.currentZ)
            };
        } else if (oldVisualPosition) {
            targetPosition = oldVisualPosition;
        }

        const currentResized = targetPosition || {
            x: commandData.currentX !== undefined ? Number(commandData.currentX) : Number(commandData.endX),
            y: commandData.currentY !== undefined ? Number(commandData.currentY) : Number(commandData.endY),
            z: commandData.currentZ !== undefined ? Number(commandData.currentZ) : Number(commandData.endZ)
        };

        // Persist the resized values into lastKnownTransforms and inline style so
        // they survive across animation cleanup boundaries. The inline transform
        // is shadowed while a transform animation is running, but takes effect
        // the moment the animation is cancelled or finishes without `fill`,
        // ensuring the next `WAAPI.animate` cycle reads the resized values as its
        // start. Also handles the no-active-animation case directly.
        persistResizedTransform(animGroup, element, propertyKey, currentResized);

        // Patch the resized property slot with the Elm-supplied new bounds.
        // Other transform sub-properties keep their existing resolved values
        // so a resize on one property does not disturb the others.
        //
        // `hasAnimationBaseline === false` means Elm has no real animation for
        // this property (e.g. `Scale.init` paired with `Scale.onResize` while
        // a Rotate animation runs). The payload's `duration` is a synthetic
        // snapshot-bake value; using it would shrink the resized slot's
        // duration and (worse) starve the keyframe sampling for co-running
        // properties. Preserve the previous slot duration in that case.
        const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
        const hasBaseline = commandData.hasAnimationBaseline !== false;
        const newDuration = hasBaseline ? payloadDuration : oldDuration;
        const previousSlotDuration = resolved[propertyKey].duration;
        resolved[propertyKey] = {
            startX: Number(commandData.startX),
            startY: Number(commandData.startY),
            startZ: Number(commandData.startZ),
            endX: Number(commandData.endX),
            endY: Number(commandData.endY),
            endZ: Number(commandData.endZ),
            easing: resolved[propertyKey].easing,
            easingKeyframes: resolved[propertyKey].easingKeyframes,
            duration: hasBaseline ? payloadDuration : previousSlotDuration
        };

        const order = getElementOrder(element);

        // Build a 30-frame interpolated transform so non-linear timing on
        // co-running rotate/scale/skew is preserved. This mirrors the
        // multi-easing branch of createMergedTransformAnimation, which
        // samples every sub-property against the *maximum* duration across
        // all sub-properties — using a single sub-property's duration here
        // (e.g. the resized one) would scale the others' progress by
        // `subProp.duration / chosenDuration`, freezing co-running long
        // animations like an 8000 ms rotate when a 300 ms scale resizes.
        const maxDuration = Math.max(
            Number(resolved.translate?.duration) || 0,
            Number(resolved.scale?.duration) || 0,
            Number(resolved.rotate?.duration) || 0,
            Number(resolved.skew?.duration) || 0
        );
        const forceGroups = computeForceGroups(resolved);
        const KEYFRAME_COUNT = deriveTransformKeyframeCount(resolved);
        const keyframes = [];
        for (let index = 0; index < KEYFRAME_COUNT; index++) {
            const globalProgress = index / (KEYFRAME_COUNT - 1);
            const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
            const interpScale = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
            const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
            const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);

            keyframes.push({
                transform: buildTransformString(
                    interpTranslate.x, interpTranslate.y, interpTranslate.z,
                    interpScale.x, interpScale.y, interpScale.z,
                    interpRotate.x, interpRotate.y, interpRotate.z,
                    interpSkew.x, interpSkew.y, order, forceGroups,
                    resolved.translate.unitX || 'px',
                    resolved.translate.unitY || 'px',
                    resolved.translate.unitZ || 'px'
                )
            });
        }

        // When Elm has no animation baseline for the resized property (init-only
        // value, e.g. `Scale.init` alongside a Rotate animation), the resize is
        // a "snapshot bake": we only want to splice the new value into the
        // running transform animation's keyframes so it stays visually current.
        // Recreating the animation here would restart the unrelated property's
        // animation (rotate, etc.) because the synthesized baseline carries
        // `duration=0` / `currentTimeMs=0`. Apply keyframes in place and exit.
        if (commandData.hasAnimationBaseline === false) {
            try {
                animation.effect.setKeyframes(keyframes);
            } catch (err) {
                reportError(`setKeyframes failed during resize: ${err && err.message ? err.message : err}`, {
                    source: 'animation',
                    severity: 'warning',
                    code: 'RESIZE_SET_KEYFRAMES_FAILED',
                    engine: 'WAAPI',
                    elementId: animGroup
                });
            }
            return;
        }

        // Compute the target `currentTime` BEFORE we touch the running
        // animation, so we can apply it atomically on the freshly-created
        // replacement. Two paths:
        //
        // - Elm-supplied `currentTimeMs` (Proportional strategy): Elm has the
        //   authoritative answer (preserve full-iteration count + in-iteration
        //   progress for looping legs, restart from `0` for the collapsed
        //   one-shot leg). We just apply it.
        //
        // - Fallback (Clamp strategy / `currentTimeMs == null`): solve for
        //   the currentTime that places the box at the strategy-aware target
        //   position Elm computed via `Resize.applyAxis`. Reuse the box's
        //   pre-resize `oldIter` to preserve iteration count + leg parity.
        //   For a 1D translate (the common resize case) this is exact for
        //   Linear easing and approximate for non-linear, matching Clamp's
        //   "preserve current value" promise.
        //
        // Elm is the source of truth: when `currentTimeMs` is present, JS
        // must apply it as-is. Any second-guessing here masks Elm-side bugs.
        // `commandData.legRedefined === true` makes the intent explicit —
        // Elm has rebased `start` to the current visual position and the
        // authoritative seek is `0` on the redefined leg.
        let newCurrentTime = null;
        if (hasElmCurrentTime) {
            newCurrentTime = commandData.currentTimeMs;
        } else if (targetPosition !== null && newDuration > 0 && oldDuration > 0) {
            const newStartX = Number(commandData.startX);
            const newEndX = Number(commandData.endX);
            const newStartY = Number(commandData.startY);
            const newEndY = Number(commandData.endY);
            const newStartZ = Number(commandData.startZ);
            const newEndZ = Number(commandData.endZ);

            const spans = {
                x: newEndX - newStartX,
                y: newEndY - newStartY,
                z: newEndZ - newStartZ
            };

            const chosenAxis = chooseDominantAxis(spans);
            let pWanted = 0;
            if (chosenAxis === 'x') {
                pWanted = (targetPosition.x - newStartX) / spans.x;
            } else if (chosenAxis === 'y') {
                pWanted = (targetPosition.y - newStartY) / spans.y;
            } else if (chosenAxis === 'z') {
                pWanted = (targetPosition.z - newStartZ) / spans.z;
            }
            if (pWanted < 0) pWanted = 0;
            if (pWanted > 1) pWanted = 1;

            const oldIter = Math.floor(oldCurrentTime / oldDuration);
            let pWithinIter = pWanted;
            if (oldDirection === 'alternate' || oldDirection === 'alternate-reverse') {
                const startsReversed = oldDirection === 'alternate-reverse';
                const isReverseLeg = (oldIter % 2 === 1) !== startsReversed;
                if (isReverseLeg) {
                    pWithinIter = 1 - pWanted;
                }
            } else if (oldDirection === 'reverse') {
                pWithinIter = 1 - pWanted;
            }
            newCurrentTime = (oldIter + pWithinIter) * newDuration;
        }

        // Cancel + recreate (not in-place mutate). The in-place approach
        // (`setKeyframes` → `updateTiming` → `currentTime =`) suffers from a
        // one-composited-frame race: between `setKeyframes` and the
        // `currentTime` write, the compositor can sample the new keyframes
        // at the *old* `currentTime`, producing a visible flicker
        // `tx = newEnd × (oldCurrentTime / oldDuration)` for one frame before
        // snapping to the correct seeked position. Recreating the Animation
        // with the new keyframes/timing already set, then seeking before the
        // first composite, avoids the mismatched-state frame entirely.
        //
        // Iteration count and alternate-leg parity survive the recreate
        // because the seeked `currentTime` (= `(oldIter + pWithin) × newDuration`)
        // already encodes them — WAAPI derives `currentIteration` from
        // `currentTime / duration`, so iter=N forward/reverse leg is restored
        // automatically without an explicit `iterationStart`.
        const transformEntry = elementAnims.get('transform');
        const oldVersion = transformEntry.version;
        const newVersion = oldVersion + 1;
        const wasPaused = animation.playState === 'paused';
        const oldIterations = oldTiming.iterations;
        const animateOptions = {
            duration: newDuration > 0 ? newDuration : oldDuration,
            easing: 'linear',
            fill: 'forwards',
            iterations: Number.isFinite(oldIterations) || oldIterations === Infinity ? oldIterations : 1,
            direction: oldDirection
        };

        // Bump entry.version BEFORE cancelling so the old animation's `cancel`
        // event handler sees `entry.version !== capturedVersion` and exits
        // early without emitting a `cancelled` lifecycle event. The new
        // animation's `setupAnimationEvents` call below installs fresh
        // listeners keyed on the new version.
        transformEntry.version = newVersion;
        try {
            animation.cancel();
        } catch (err) {
            reportError(`cancel failed during resize: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'warning',
                code: 'RESIZE_CANCEL_FAILED',
                engine: 'WAAPI',
                elementId: animGroup
            });
        }

        let newAnimation = null;
        try {
            newAnimation = element.animate(keyframes, animateOptions);
        } catch (err) {
            reportError(`element.animate failed during resize: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'warning',
                code: 'RESIZE_RECREATE_FAILED',
                engine: 'WAAPI',
                elementId: animGroup
            });
            return;
        }

        if (newCurrentTime !== null) {
            try {
                newAnimation.currentTime = newCurrentTime;
            } catch (err) {
                reportError(`currentTime assignment failed during resize: ${err && err.message ? err.message : err}`, {
                    source: 'animation',
                    severity: 'warning',
                    code: 'RESIZE_CURRENT_TIME_FAILED',
                    engine: 'WAAPI',
                    elementId: animGroup
                });
            }
        }

        if (wasPaused) {
            try { newAnimation.pause(); } catch (_pauseErr) { /* non-fatal */ }
        }

        transformEntry.animation = newAnimation;
        transformEntry.updateFn = setupAnimationEvents(
            animGroup,
            'transform',
            element,
            newAnimation,
            newVersion,
            transformEntry.resolvedValues
        );
    }


    function resizePerspectiveOriginAnimation(commandData, animGroup, element) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims || !elementAnims.has('perspectiveOrigin')) {
            return;
        }

        const entry = elementAnims.get('perspectiveOrigin');
        const animation = entry.animation;
        if (!animation || !animation.effect) {
            return;
        }

        const oldTiming = animation.effect.getTiming() || {};
        const oldDuration = Number(oldTiming.duration) || 0;
        const oldCurrentTime = Number(animation.currentTime) || 0;
        const oldDirection = oldTiming.direction || 'normal';

        // Fast-path skip: when start/end/duration/unit of the perspective-origin
        // slot are identical to what JS already has, the resize cmd is purely
        // advisory (Elm fired because `currentTimeMs` advanced via Progress
        // ticks during a continuous drag). Mirrors the translate handler's
        // `isResizeGeometryUnchanged` early-return at the top of
        // `_resizeTransformAnimationImmediate` — without it, the perspective
        // animation gets cancel+recreate+seek-to-stale-`commandData.currentTimeMs`
        // every flush while its sibling translate just `setKeyframes` and
        // keeps ticking, so perspective falls 8-16 ms behind translate per
        // flush and the dot finishes the leg before the perspective container
        // catches up.
        const previousResolved = entry.resolvedNonTransform || null;
        if (isPerspectiveOriginGeometryUnchanged(commandData, previousResolved, oldDuration)) {
            return;
        }

        const oldLegProgress = computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation);

        const unit = typeof commandData.unit === 'string' ? commandData.unit : '%';
        const oldVisual =
            oldLegProgress !== null
                && previousResolved
                && isFiniteNumber(previousResolved.startX)
                && isFiniteNumber(previousResolved.endX)
                && isFiniteNumber(previousResolved.startY)
                && isFiniteNumber(previousResolved.endY)
                ? {
                    x: previousResolved.startX + (previousResolved.endX - previousResolved.startX) * oldLegProgress,
                    y: previousResolved.startY + (previousResolved.endY - previousResolved.startY) * oldLegProgress
                }
                : null;

        const hasElmCurrentTime = typeof commandData.currentTimeMs === 'number' && isFinite(commandData.currentTimeMs);
        const effectiveCurrentPosition = !hasElmCurrentTime && oldVisual
            ? {
                x: chooseEffectiveAxisValue(
                    Number(previousResolved?.startX),
                    Number(previousResolved?.endX),
                    Number(commandData.startX),
                    Number(commandData.endX),
                    Number(commandData.currentX),
                    oldVisual.x
                ),
                y: chooseEffectiveAxisValue(
                    Number(previousResolved?.startY),
                    Number(previousResolved?.endY),
                    Number(commandData.startY),
                    Number(commandData.endY),
                    Number(commandData.currentY),
                    oldVisual.y
                )
            }
            : {
                x: Number(commandData.currentX),
                y: Number(commandData.currentY)
            };

        const resolved = {
            type: 'perspectiveOrigin',
            startX: Number(commandData.startX),
            startY: Number(commandData.startY),
            endX: Number(commandData.endX),
            endY: Number(commandData.endY),
            unitX: unit,
            unitY: unit
        };

        const keyframeData = buildPropertyKeyframes(resolved, entry.easingKeyframes, 'linear');
        if (!keyframeData || !keyframeData.keyframes) {
            return;
        }

        const hasBaseline = commandData.hasAnimationBaseline !== false;
        const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
        const newDuration = hasBaseline ? payloadDuration : oldDuration;
        const wasPaused = animation.playState === 'paused';

        let newCurrentTime = null;
        if (hasElmCurrentTime) {
            // Elm is the source of truth for the seek target; apply unconditionally.
            newCurrentTime = commandData.currentTimeMs;
        } else if (oldDuration > 0 && newDuration > 0) {
            const oldIter = Math.floor(oldCurrentTime / oldDuration);
            const startsReversed = oldDirection === 'alternate-reverse';
            const isAlternate = oldDirection === 'alternate' || oldDirection === 'alternate-reverse';
            const isReverseLeg = isAlternate ? ((oldIter % 2 === 1) !== startsReversed) : oldDirection === 'reverse';

            const xStart = Number(commandData.startX);
            const xEnd = Number(commandData.endX);
            const yStart = Number(commandData.startY);
            const yEnd = Number(commandData.endY);

            const spans = {
                x: xEnd - xStart,
                y: yEnd - yStart,
                z: 0
            };

            const chosenAxis = chooseDominantAxis(spans);

            let pWanted = 0;
            if (chosenAxis === 'x') {
                pWanted = (effectiveCurrentPosition.x - xStart) / spans.x;
            } else if (chosenAxis === 'y') {
                pWanted = (effectiveCurrentPosition.y - yStart) / spans.y;
            }
            if (pWanted < 0) pWanted = 0;
            if (pWanted > 1) pWanted = 1;

            const pWithinIter = isReverseLeg ? 1 - pWanted : pWanted;
            newCurrentTime = (oldIter + pWithinIter) * newDuration;
        }

        const oldVersion = entry.version;
        const newVersion = oldVersion + 1;
        const oldIterations = oldTiming.iterations;
        const animateOptions = {
            duration: newDuration > 0 ? newDuration : oldDuration,
            easing: keyframeData.animationEasing || 'linear',
            fill: 'forwards',
            iterations: Number.isFinite(oldIterations) || oldIterations === Infinity ? oldIterations : 1,
            direction: oldDirection
        };

        entry.version = newVersion;
        try {
            animation.cancel();
        } catch (_err) {
            // Best-effort: keep going and recreate.
        }

        let newAnimation = null;
        try {
            newAnimation = element.animate(keyframeData.keyframes, animateOptions);
        } catch (_err) {
            return;
        }

        if (newCurrentTime !== null) {
            try {
                newAnimation.currentTime = newCurrentTime;
            } catch (_err) {
                // Non-fatal; animation still recreated with new bounds.
            }
        }

        if (wasPaused) {
            try { newAnimation.pause(); } catch (_pauseErr) { /* non-fatal */ }
        }

        element.style.perspectiveOrigin = `${effectiveCurrentPosition.x}${unit} ${effectiveCurrentPosition.y}${unit}`;

        entry.animation = newAnimation;
        entry.resolvedNonTransform = resolved;
        entry.updateFn = setupAnimationEvents(
            animGroup,
            'perspectiveOrigin',
            element,
            newAnimation,
            newVersion,
            null
        );
    }

    function resizeSizeAnimation(commandData, animGroup, element) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims || !elementAnims.has('size')) {
            return;
        }

        const entry = elementAnims.get('size');
        const animation = entry.animation;
        if (!animation || !animation.effect) {
            return;
        }

        const oldTiming = animation.effect.getTiming() || {};
        const oldDuration = Number(oldTiming.duration) || 0;
        const oldCurrentTime = Number(animation.currentTime) || 0;
        const oldDirection = oldTiming.direction || 'normal';

        // Fast-path skip mirroring the perspective-origin handler: a resize cmd
        // whose start/end/duration/unit match what JS already has is purely
        // advisory (Elm fired because `currentTimeMs` advanced via Progress
        // ticks during a continuous drag). Without this, every flush would
        // cancel+recreate and reset the animation's clock.
        const previousResolved = entry.resolvedNonTransform || null;
        if (isSizeGeometryUnchanged(commandData, previousResolved, oldDuration)) {
            return;
        }

        const oldLegProgress = computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation);

        const unit = typeof commandData.unit === 'string' ? commandData.unit : 'px';
        const oldVisual =
            oldLegProgress !== null
                && previousResolved
                && isFiniteNumber(previousResolved.startWidth)
                && isFiniteNumber(previousResolved.endWidth)
                && isFiniteNumber(previousResolved.startHeight)
                && isFiniteNumber(previousResolved.endHeight)
                ? {
                    x: previousResolved.startWidth + (previousResolved.endWidth - previousResolved.startWidth) * oldLegProgress,
                    y: previousResolved.startHeight + (previousResolved.endHeight - previousResolved.startHeight) * oldLegProgress
                }
                : null;

        const hasElmCurrentTime = typeof commandData.currentTimeMs === 'number' && isFinite(commandData.currentTimeMs);
        const effectiveCurrentPosition = !hasElmCurrentTime && oldVisual
            ? {
                x: chooseEffectiveAxisValue(
                    Number(previousResolved?.startWidth),
                    Number(previousResolved?.endWidth),
                    Number(commandData.startX),
                    Number(commandData.endX),
                    Number(commandData.currentX),
                    oldVisual.x
                ),
                y: chooseEffectiveAxisValue(
                    Number(previousResolved?.startHeight),
                    Number(previousResolved?.endHeight),
                    Number(commandData.startY),
                    Number(commandData.endY),
                    Number(commandData.currentY),
                    oldVisual.y
                )
            }
            : {
                x: Number(commandData.currentX),
                y: Number(commandData.currentY)
            };

        const resolved = {
            type: 'size',
            startWidth: Number(commandData.startX),
            startHeight: Number(commandData.startY),
            endWidth: Number(commandData.endX),
            endHeight: Number(commandData.endY),
            unitWidth: unit,
            unitHeight: unit
        };

        const keyframeData = buildPropertyKeyframes(resolved, entry.easingKeyframes, 'linear');
        if (!keyframeData || !keyframeData.keyframes) {
            return;
        }

        const hasBaseline = commandData.hasAnimationBaseline !== false;
        const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
        const newDuration = hasBaseline ? payloadDuration : oldDuration;
        const wasPaused = animation.playState === 'paused';

        let newCurrentTime = null;
        if (hasElmCurrentTime) {
            newCurrentTime = commandData.currentTimeMs;
        } else if (oldDuration > 0 && newDuration > 0) {
            const oldIter = Math.floor(oldCurrentTime / oldDuration);
            const startsReversed = oldDirection === 'alternate-reverse';
            const isAlternate = oldDirection === 'alternate' || oldDirection === 'alternate-reverse';
            const isReverseLeg = isAlternate ? ((oldIter % 2 === 1) !== startsReversed) : oldDirection === 'reverse';

            const xStart = Number(commandData.startX);
            const xEnd = Number(commandData.endX);
            const yStart = Number(commandData.startY);
            const yEnd = Number(commandData.endY);

            const spans = {
                x: xEnd - xStart,
                y: yEnd - yStart,
                z: 0
            };

            const chosenAxis = chooseDominantAxis(spans);

            let pWanted = 0;
            if (chosenAxis === 'x') {
                pWanted = (effectiveCurrentPosition.x - xStart) / spans.x;
            } else if (chosenAxis === 'y') {
                pWanted = (effectiveCurrentPosition.y - yStart) / spans.y;
            }
            if (pWanted < 0) pWanted = 0;
            if (pWanted > 1) pWanted = 1;

            const pWithinIter = isReverseLeg ? 1 - pWanted : pWanted;
            newCurrentTime = (oldIter + pWithinIter) * newDuration;
        }

        const oldVersion = entry.version;
        const newVersion = oldVersion + 1;
        const oldIterations = oldTiming.iterations;
        const animateOptions = {
            duration: newDuration > 0 ? newDuration : oldDuration,
            easing: keyframeData.animationEasing || 'linear',
            fill: 'forwards',
            iterations: Number.isFinite(oldIterations) || oldIterations === Infinity ? oldIterations : 1,
            direction: oldDirection
        };

        entry.version = newVersion;
        try {
            animation.cancel();
        } catch (_err) {
            // Best-effort: keep going and recreate.
        }

        let newAnimation = null;
        try {
            newAnimation = element.animate(keyframeData.keyframes, animateOptions);
        } catch (_err) {
            return;
        }

        if (newCurrentTime !== null) {
            try {
                newAnimation.currentTime = newCurrentTime;
            } catch (_err) {
                // Non-fatal; animation still recreated with new bounds.
            }
        }

        if (wasPaused) {
            try { newAnimation.pause(); } catch (_pauseErr) { /* non-fatal */ }
        }

        element.style.width = `${effectiveCurrentPosition.x}${unit}`;
        element.style.height = `${effectiveCurrentPosition.y}${unit}`;

        entry.animation = newAnimation;
        entry.resolvedNonTransform = resolved;
        entry.updateFn = setupAnimationEvents(
            animGroup,
            'size',
            element,
            newAnimation,
            newVersion,
            null
        );
    }

    function processAnimationData(animationData) {
        if (!animationData || !animationData.elements) {
            reportError('Invalid animation data format received', {
                source: 'animation',
                severity: 'warning',
                code: 'COMMAND_INVALID',
                engine: 'WAAPI'
            });
            return;
        }

        const globalOptions = {
            iterations: parseIterations(animationData.iterations),
            direction: animationData.direction || 'normal'
        };
        const isRestart = animationData.isRestart || false;

        Object.entries(animationData.elements).forEach(([animGroup, elementConfig]) => {
            const elementOptions = {
                iterations: parseIterations(elementConfig.iterations ?? globalOptions.iterations),
                direction: elementConfig.direction || globalOptions.direction
            };
            const targets = findAllAnimTargets(animGroup);
            if (targets.length <= 1) {
                processElementAnimation(animGroup, elementConfig, elementOptions, isRestart);
                return;
            }

            targets.forEach((element, index) => {
                const uniqueId = element.id || (animGroup + '__multi_' + index);
                processElementAnimation(uniqueId, elementConfig, elementOptions, isRestart, element);
            });
        });
    }

    /**
     * Snap touched properties to their new target values with no animation.
     *
     * For every property in `commandData.elements`, cancels any in-flight WAAPI
     * animation on that property and writes the target value as inline style.
     * Untouched properties on the same anim group are left alone (their
     * animations continue running).
     *
     * Builder timing (duration/delay/easing/spring) carried in the payload is
     * ignored — the snap writes the END state directly. A `cancelled`
     * lifecycle event is emitted via the in-flight animation's `cancel`
     * listener for any previously-playing animation that the snap kills.
     */
    function retargetAnimation(commandData) {
        if (!commandData || !commandData.elements) {
            reportError('Invalid retarget data format received', {
                source: 'animation',
                severity: 'warning',
                code: 'COMMAND_INVALID',
                engine: 'WAAPI'
            });
            return;
        }

        Object.entries(commandData.elements).forEach(([animGroup, elementConfig]) => {
            const targets = findAllAnimTargets(animGroup);
            if (targets.length <= 1) {
                retargetElement(animGroup, elementConfig);
                return;
            }

            targets.forEach((element, index) => {
                const uniqueId = element.id || (animGroup + '__multi_' + index);
                retargetElement(uniqueId, elementConfig, element);
            });
        });
    }

    function retargetElement(animGroup, elementConfig, resolvedElement = null) {
        const element = resolvedElement || findAnimTarget(animGroup);
        if (!element) {
            reportError(`Element with data-anim-target="${animGroup}" not found`, {
                source: 'animation',
                severity: 'warning',
                code: 'TARGET_NOT_FOUND',
                engine: 'WAAPI',
                elementId: animGroup
            });
            return;
        }

        const properties = elementConfig.properties || [];

        // Seed transformBaseline cache so a follow-up animate() reads the
        // correct start values when nothing has populated the cache yet.
        if (elementConfig.transformBaseline && !lastKnownTransforms.has(animGroup)) {
            lastKnownTransforms.set(animGroup, baselineToTransformState(elementConfig.transformBaseline));
        }

        if (elementConfig.transformOrder && elementConfig.transformOrder.length > 0) {
            elementTransformOrders.set(animGroup, elementConfig.transformOrder);
        }

        const transformProperties = properties.filter(property => isTransformProperty(property.type));
        const nonTransformProperties = properties.filter(property => !isTransformProperty(property.type));

        const elementAnims = activeAnimations.get(animGroup);

        if (transformProperties.length > 0) {
            const continuationApplied = retargetTransformWithContinuation(
                animGroup, element, transformProperties, elementAnims
            );
            if (!continuationApplied) {
                snapTransformProperties(animGroup, element, transformProperties, elementAnims);
            }
        }

        nonTransformProperties.forEach(property => {
            const continuationApplied = retargetNonTransformWithContinuation(
                animGroup, element, property, elementAnims
            );
            if (!continuationApplied) {
                snapNonTransformProperty(animGroup, element, property, elementAnims);
            }
        });
    }

    /**
     * Cancel the WAAPI Animation handle without letting its `cancel` event
     * listener fire its usual finalize path (which would emit a stale
     * mid-flight `propertyUpdate` and a `cancelled` lifecycle event).
     *
     * The listener guards every side-effect with `isActiveEntry()`, which
     * checks `activeAnimations.get(animGroup).get(propType).version`. By
     * deleting the entry before calling `.cancel()`, we make that lookup
     * fail and the listener exits silently. `retarget` is event-silent at
     * the engine level — no `cancelled` lifecycle event is emitted for the
     * snap.
     *
     * Returns `true` when an entry existed and was cancelled.
     */
    function cancelSilently(elementAnims, propType) {
        if (!elementAnims || !elementAnims.has(propType)) {
            return false;
        }
        const existing = elementAnims.get(propType);
        elementAnims.delete(propType);
        try {
            existing.animation.cancel();
        } catch (_) {
            // Already-cancelled / detached handles are safe to ignore.
        }
        return true;
    }

    /**
     * Compute the live mid-flight transform of an in-flight merged transform
     * animation. Falls back to the cached `lastKnownTransforms` state when
     * the animation has no resolved values or has not started ticking yet.
     */
    function readLiveTransform(animGroup, element, existing) {
        if (existing && existing.resolvedValues) {
            const activeTiming = getAnimationActiveTiming(existing.animation);
            if (activeTiming) {
                return computeTransformFromResolved(existing.resolvedValues, activeTiming.progress, activeTiming.duration);
            }
        }
        return getTransformState(animGroup, element);
    }

    /**
     * Build a continuation transform animation when the retarget command
     * touches only a subset of axes on one or more bundled transform
     * properties (translate / scale / rotate / skew) and an in-flight
     * transform animation is mid-flight. Touched axes snap to the new
     * target via flat keyframes; untouched axes preserve the in-flight
     * animation's original (start, end, easing) so they continue smoothly
     * toward their existing target. The new WAAPI animation uses the same
     * total duration as the old one and starts with `delay: -oldT`,
     * putting it at the same progress where the old one was cancelled —
     * for untouched axes this is indistinguishable from the original
     * animation continuing.
     *
     * Returns `true` when a continuation animation was built; `false` when
     * the caller should fall back to the full-snap path (no in-flight
     * animation, no touched-axis flags on any transform property in the
     * command, or every axis is touched).
     */
    function retargetTransformWithContinuation(animGroup, element, transformProperties, elementAnims) {
        if (!elementAnims) return false;
        const existing = elementAnims.get('transform');
        if (!existing || !existing.resolvedValues || !existing.animation) return false;

        const timing = existing.animation.effect?.getTiming();
        const oldDuration = timing?.duration || 0;
        if (!(oldDuration > 0)) return false;

        const oldT = existing.animation.currentTime;
        if (!Number.isFinite(oldT) || oldT < 0 || oldT >= oldDuration) return false;

        let hasAnyTouchedFlag = false;
        let hasAnyUntouched = false;
        for (const property of transformProperties) {
            const axes = RESOLVED_TRANSFORM_AXES[property.type];
            if (!axes) continue;
            for (const { suffix } of axes) {
                const flag = property[`touched${suffix}`];
                if (typeof flag === 'boolean') {
                    hasAnyTouchedFlag = true;
                    if (flag === false) hasAnyUntouched = true;
                }
            }
        }
        if (!hasAnyTouchedFlag || !hasAnyUntouched) return false;

        // Shallow clone preserves old per-axis start/end/easing/units;
        // mutations below only overwrite touched axes (snap) and any
        // transform property the retarget command does not address (left
        // entirely as-is from the in-flight resolved values).
        const oldResolved = existing.resolvedValues;
        const resolved = {
            translate: { ...oldResolved.translate },
            scale: { ...oldResolved.scale },
            rotate: { ...oldResolved.rotate },
            skew: { ...oldResolved.skew }
        };

        transformProperties.forEach(property => {
            const target = resolved[property.type];
            const axes = RESOLVED_TRANSFORM_AXES[property.type];
            if (!target || !axes) return;

            const hasTouchedFlags = axes.some(
                ({ suffix }) => typeof property[`touched${suffix}`] === 'boolean'
            );

            if (!hasTouchedFlags) {
                // No per-axis flags on this property: full-snap every axis.
                axes.forEach(({ suffix }) => {
                    const newEnd = property[`end${suffix}`];
                    if (!Number.isFinite(newEnd)) return;
                    target[`start${suffix}`] = newEnd;
                    target[`end${suffix}`] = newEnd;

                    // CRITICAL: For frozen (untouched) axes, anchor their start/end to the
                    // CURRENT LIVE position. Without this, frozen axes use stale in-flight
                    // start values, causing snaps when the next animate runs. E.g., if X moved
                    // 0→100 and settled at 100, a frozen-X retarget must have startX = 100
                    // (live), not 0 (old in-flight value).
                    const domLiveState = getCurrentTransform(element);
                    transformProperties.forEach(property => {
                        const target = resolved[property.type];
                        const axes = RESOLVED_TRANSFORM_AXES[property.type];
                        if (!target || !axes) return;

                        axes.forEach(({ suffix, currentKey }) => {
                            const touchedFlag = property[`touched${suffix}`];
                            // If touched !== true (either false or undefined), this axis is frozen
                            if (touchedFlag !== true) {
                                const liveValue = domLiveState[currentKey];
                                if (Number.isFinite(liveValue)) {
                                    target[`start${suffix}`] = liveValue;
                                    target[`end${suffix}`] = liveValue;
                                }
                            }
                        });
                    });
                });
            } else {
                // Per-axis flags present: only touched axes snap; untouched
                // axes keep the in-flight start/end/easing.
                axes.forEach(({ suffix }) => {
                    if (property[`touched${suffix}`] !== true) return;
                    const newEnd = property[`end${suffix}`];
                    if (!Number.isFinite(newEnd)) return;
                    target[`start${suffix}`] = newEnd;
                    target[`end${suffix}`] = newEnd;
                });
            }
        });

        // Carry forward any user-supplied units on the retarget command for
        // translate axes; absent values keep the in-flight units to avoid
        // unit-interpretation jumps. (Translate is the only bundled
        // transform property with per-axis CSS units.)
        const translateProp = transformProperties.find(property => property.type === 'translate');
        if (translateProp) {
            ['unitX', 'unitY', 'unitZ'].forEach(key => {
                const candidate = translateProp[key];
                if (typeof candidate === 'string' && candidate.length > 0) {
                    resolved.translate[key] = candidate;
                }
            });
        }

        cancelSilently(elementAnims, 'transform');
        cancelLegacyTransformAnimations(elementAnims);

        const order = getElementOrder(element);
        const forceGroups = computeForceGroups(resolved);
        const KEYFRAME_COUNT = deriveTransformKeyframeCount(resolved);
        const keyframes = [];
        for (let index = 0; index < KEYFRAME_COUNT; index++) {
            const globalProgress = index / (KEYFRAME_COUNT - 1);
            const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, oldDuration);
            const interpScale = interpolateSubProperty(resolved.scale, globalProgress, oldDuration);
            const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, oldDuration);
            const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, oldDuration);
            keyframes.push({
                transform: buildTransformString(
                    interpTranslate.x, interpTranslate.y, interpTranslate.z,
                    interpScale.x, interpScale.y, interpScale.z,
                    interpRotate.x, interpRotate.y, interpRotate.z,
                    interpSkew.x, interpSkew.y, order, forceGroups,
                    resolved.translate.unitX || 'px',
                    resolved.translate.unitY || 'px',
                    resolved.translate.unitZ || 'px'
                )
            });
        }

        // `delay: -oldT` advances the animation to oldT of progress at start,
        // so untouched axes resume on the same easing curve at the same point
        // the cancelled animation was sampling.
        const newAnimation = element.animate(keyframes, {
            duration: oldDuration,
            delay: -oldT,
            easing: 'linear',
            fill: 'forwards',
            iterations: 1,
            direction: 'normal'
        });

        const newVersion = (existing.version || 1) + 1;
        const entry = {
            animation: newAnimation,
            version: newVersion,
            animGroup: animGroup,
            easingKeyframes: null,
            transformProperties: transformProperties,
            resolvedValues: resolved,
            generation: existing.generation,
            propertyIndex: existing.propertyIndex
        };
        elementAnims.set('transform', entry);
        entry.updateFn = setupAnimationEvents(animGroup, 'transform', element, newAnimation, newVersion, resolved);

        return true;
    }

    const NON_TRANSFORM_RETARGET_AXES = {
        size: [
            { suffix: 'Width', startKey: 'startWidth', endKey: 'endWidth' },
            { suffix: 'Height', startKey: 'startHeight', endKey: 'endHeight' }
        ],
        perspectiveOrigin: [
            { suffix: 'X', startKey: 'startX', endKey: 'endX' },
            { suffix: 'Y', startKey: 'startY', endKey: 'endY' }
        ]
    };

    /**
     * Build a continuation animation for a non-transform multi-dimensional
     * property (`size`, `perspectiveOrigin`) when the retarget command
     * touches only a subset of its axes and an in-flight WAAPI animation
     * is mid-flight. Touched axes snap to the new target (start = end =
     * target so the per-axis curve is flat); untouched axes preserve the
     * in-flight animation's start / end so they continue along the
     * original easing curve. The new animation uses the same total
     * duration and starts with `delay: -oldT`, putting it at the same
     * progress where the old one was cancelled — for untouched axes this
     * is indistinguishable from the original animation continuing.
     *
     * Returns `true` when a continuation animation was built; `false` when
     * the caller should fall back to the full-snap path.
     */
    function retargetNonTransformWithContinuation(animGroup, element, property, elementAnims) {
        const axes = NON_TRANSFORM_RETARGET_AXES[property.type];
        if (!axes) return false;
        if (!elementAnims) return false;

        const existing = elementAnims.get(property.type);
        if (!existing || !existing.resolvedNonTransform || !existing.animation) return false;

        const timing = existing.animation.effect?.getTiming();
        const oldDuration = timing?.duration || 0;
        if (!(oldDuration > 0)) return false;

        const oldT = existing.animation.currentTime;
        if (!Number.isFinite(oldT) || oldT < 0 || oldT >= oldDuration) return false;

        const hasAnyTouchedFlag = axes.some(
            ({ suffix }) => typeof property[`touched${suffix}`] === 'boolean'
        );
        if (!hasAnyTouchedFlag) return false;

        const hasAnyUntouched = axes.some(
            ({ suffix }) => property[`touched${suffix}`] === false
        );
        if (!hasAnyUntouched) return false;

        // Shallow clone preserves the in-flight start/end/units; mutations
        // below only overwrite touched axes.
        const resolved = { ...existing.resolvedNonTransform };

        axes.forEach(({ suffix, startKey, endKey }) => {
            if (property[`touched${suffix}`] !== true) return;
            const target = property[`end${suffix}`];
            if (!Number.isFinite(target)) return;
            resolved[startKey] = target;
            resolved[endKey] = target;
        });

        cancelSilently(elementAnims, property.type);

        const { keyframes, animationEasing } = buildPropertyKeyframes(
            resolved,
            existing.easingKeyframes || property.easingKeyframes,
            property.easing
        );
        if (!keyframes) return false;

        const newAnimation = element.animate(keyframes, {
            duration: oldDuration,
            delay: -oldT,
            easing: animationEasing,
            fill: 'forwards',
            iterations: 1,
            direction: 'normal'
        });

        const newVersion = (existing.version || 1) + 1;
        const entry = {
            animation: newAnimation,
            version: newVersion,
            animGroup: animGroup,
            easingKeyframes: existing.easingKeyframes || property.easingKeyframes || null,
            resolvedNonTransform: resolved,
            generation: existing.generation,
            propertyIndex: existing.propertyIndex
        };
        elementAnims.set(property.type, entry);
        entry.updateFn = setupAnimationEvents(animGroup, property.type, element, newAnimation, newVersion, null);

        return true;
    }

    function snapTransformProperties(animGroup, element, transformProperties, elementAnims) {
        // Read the live mid-flight transform BEFORE cancelling so axes the
        // build does not mention end up frozen at their actual on-screen
        // position rather than at the stale cached baseline.
        const existing = elementAnims ? elementAnims.get('transform') : null;
        const currentTransform = readLiveTransform(animGroup, element, existing);

        const cancelled = cancelSilently(elementAnims, 'transform');
        if (elementAnims) {
            cancelLegacyTransformAnimations(elementAnims);
        }

        const order = getElementOrder(element);
        const resolved = buildDefaultResolvedTransform(currentTransform);

        transformProperties.forEach(property => {
            const target = resolved[property.type];
            const axes = RESOLVED_TRANSFORM_AXES[property.type];
            if (target && axes) {
                assignResolvedTransformProperty(target, property, currentTransform, axes);
            }
        });

        const forceGroups = computeForceGroups(resolved);
        const tUx = resolved.translate.unitX || 'px';
        const tUy = resolved.translate.unitY || 'px';
        const tUz = resolved.translate.unitZ || 'px';

        element.style.transform = buildTransformString(
            resolved.translate.endX, resolved.translate.endY, resolved.translate.endZ,
            resolved.scale.endX, resolved.scale.endY, resolved.scale.endZ,
            resolved.rotate.endX, resolved.rotate.endY, resolved.rotate.endZ,
            resolved.skew.endX, resolved.skew.endY, order, forceGroups, tUx, tUy, tUz
        );

        // Update the cache so subsequent reads (animate, getTransformState)
        // see the snapped end state rather than the pre-snap current value.
        lastKnownTransforms.set(animGroup, {
            x: resolved.translate.endX, y: resolved.translate.endY, z: resolved.translate.endZ,
            scaleX: resolved.scale.endX, scaleY: resolved.scale.endY, scaleZ: resolved.scale.endZ,
            rotateX: resolved.rotate.endX, rotateY: resolved.rotate.endY, rotateZ: resolved.rotate.endZ,
            skewX: resolved.skew.endX, skewY: resolved.skew.endY,
            translateUnitX: tUx, translateUnitY: tUy, translateUnitZ: tUz
        });

        return cancelled;
    }

    function snapNonTransformProperty(animGroup, element, property, elementAnims) {
        const propType = (property.type === 'customProperty')
            ? `custom:${property.cssProperty}`
            : (property.type === 'customColorProperty')
                ? `customColor:${property.cssProperty}`
                : property.type;

        const cancelled = cancelSilently(elementAnims, propType);

        const resolved = resolveNonTransformValues(animGroup, element, property);
        if (!resolved) return cancelled;

        const { keyframes } = buildPropertyKeyframes(resolved, property.easingKeyframes, property.easing);
        if (!keyframes || keyframes.length === 0) return cancelled;

        applyKeyframeToInlineStyle(element, keyframes[keyframes.length - 1]);
        return cancelled;
    }

    /**
     * Apply a WAAPI keyframe object as inline style on the element. Skips
     * the WAAPI-internal `offset` / `easing` keys. Routes CSS custom
     * properties (those starting with `--`) through `setProperty`.
     */
    function applyKeyframeToInlineStyle(element, keyframe) {
        Object.entries(keyframe).forEach(([key, value]) => {
            if (key === 'offset' || key === 'easing' || value === undefined || value === null) {
                return;
            }
            if (key.startsWith('--')) {
                element.style.setProperty(key, String(value));
            } else {
                element.style[key] = value;
            }
        });
    }

    /* eslint-env browser */

    const DIRECT_TRANSFORM_KEYS = [
        'x', 'y', 'z',
        'scaleX', 'scaleY', 'scaleZ',
        'rotateX', 'rotateY', 'rotateZ',
        'skewX', 'skewY'
    ];

    const DIRECT_STYLE_APPLIERS = {
        opacity(style, value) {
            style.opacity = String(value);
        }
    };

    function forEachAffectedAnimation(animGroup, properties, fn) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims) return { affected: 0, total: 0 };
        const filter = properties ? new Set(properties) : null;
        let affected = 0;
        elementAnims.forEach((animData, propertyType) => {
            if (!filter || filter.has(propertyType)) {
                fn(animData, propertyType);
                affected++;
            }
        });
        return { affected, total: elementAnims.size };
    }

    function hasDirectTransformUpdates(props) {
        return DIRECT_TRANSFORM_KEYS.some(key => props[key] !== undefined);
    }

    function clearTrackedAnimations(animGroup, element) {
        element.getAnimations().forEach(anim => {
            anim.cancel();
        });
        cleanupAnimGroup(animGroup);
    }

    function applyDirectTransformStyles(animGroup, element, props) {
        if (!hasDirectTransformUpdates(props)) {
            return;
        }

        const order = elementTransformOrders.get(animGroup) || DEFAULT_TRANSFORM_ORDER;
        const {
            x = 0,
            y = 0,
            z = 0,
            scaleX = 1,
            scaleY = 1,
            scaleZ = 1,
            rotateX = 0,
            rotateY = 0,
            rotateZ = 0,
            skewX = 0,
            skewY = 0,
            translateUnitX = 'px',
            translateUnitY = 'px',
            translateUnitZ = 'px'
        } = props;

        element.style.transform = buildTransformString(
            x,
            y,
            z,
            scaleX,
            scaleY,
            scaleZ,
            rotateX,
            rotateY,
            rotateZ,
            skewX,
            skewY,
            order,
            undefined,
            translateUnitX,
            translateUnitY,
            translateUnitZ
        );
    }

    function applyDirectStyleUpdates(style, props) {
        Object.entries(DIRECT_STYLE_APPLIERS).forEach(([key, applyStyle]) => {
            if (props[key] !== undefined) {
                applyStyle(style, props[key]);
            }
        });

        if (props.width !== undefined && props.height !== undefined) {
            const uW = props.unitWidth || 'px';
            const uH = props.unitHeight || 'px';
            style.width = `${props.width}${uW}`;
            style.height = `${props.height}${uH}`;
        }
    }

    function applyDirectPropertyUpdate(update) {
        const animGroup = update.elementId;
        const element = findAnimTarget(animGroup);
        if (!element) {
            reportError(`Element with data-anim-target="${animGroup}" not found`, {
                source: 'animation',
                severity: 'warning',
                code: 'TARGET_NOT_FOUND',
                engine: 'WAAPI',
                elementId: animGroup
            });
            return;
        }

        clearTrackedAnimations(animGroup, element);

        const props = update.properties;
        applyDirectTransformStyles(animGroup, element, props);
        applyDirectStyleUpdates(element.style, props);
    }

    function stopAnimation(animGroup, properties) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims) return;
        const { affected, total } = forEachAffectedAnimation(animGroup, properties, animData => animData.animation.finish());
        if (!properties || affected === total) {
            cleanupAnimGroup(animGroup);
        }
        sendLifecycleEvent('stopped', animGroup);
    }

    function resetAnimation(animGroup, properties) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims) {
            // If reset happens after completion, there may be no active entries but
            // a stale settled transform can still be cached. Drop it so the next
            // animate starts from Elm's reset snapshot instead of old rest values.
            lastKnownTransforms.delete(animGroup);
            sendLifecycleEvent('reset', animGroup);
            return;
        }

        // Snapshot targets BEFORE mutating the Map, then drop tracking entries
        // BEFORE calling `animation.cancel()`. The cancel listener in
        // animationEvents.js checks `isActiveEntry()` and short-circuits when the
        // entry is gone, so it will not emit a `propertyUpdate` carrying the
        // animation's last progress. Elm has already snapped the visible state
        // back to the start values - we must not let a trailing progress event
        // overwrite that snapshot.
        const filter = properties ? new Set(properties) : null;
        const targets = [];
        elementAnims.forEach((animData, propertyType) => {
            if (!filter || filter.has(propertyType)) {
                targets.push({ propertyType, animation: animData.animation });
            }
        });

        const affectedAll = !properties || targets.length === elementAnims.size;
        if (affectedAll) {
            cleanupAnimGroup(animGroup);
        } else {
            for (const { propertyType } of targets) {
                elementAnims.delete(propertyType);
            }
        }

        for (const { animation } of targets) {
            animation.cancel();
        }

        lastKnownTransforms.delete(animGroup);
        sendLifecycleEvent('reset', animGroup);
    }

    function restartAnimation(animGroup, properties) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims) return;
        forEachAffectedAnimation(animGroup, properties, animData => {
            animData.animation.cancel();
            animData.animation.play();
        });

        const groupTracking = animationGroups.get(animGroup);
        if (groupTracking) {
            groupTracking.completedProperties = 0;
            groupTracking.started = false;
        }
        sendLifecycleEvent('restarted', animGroup);
    }

    function pauseAnimation(animGroup, properties) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims) return;
        forEachAffectedAnimation(animGroup, properties, animData => animData.animation.pause());
        sendLifecycleEvent('paused', animGroup);
    }

    function resumeAnimation(animGroup, properties) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims) return;
        forEachAffectedAnimation(animGroup, properties, animData => {
            animData.animation.play();
            if (animData.updateFn) {
                animData.updateFn();
            }
        });
        sendLifecycleEvent('resumed', animGroup);
    }

    function setProperties(updates) {
        updates.forEach(applyDirectPropertyUpdate);
    }

    /* eslint-env browser */
    /* global window, document, CSS, ScrollTimeline, ViewTimeline */

    // Shared load guard so multiple timeline commands do not trigger duplicate loads.
    let timelinePolyfillLoadPromise = null;

    /**
     * Returns true if the named timeline API is available in the current window.
     */
    function hasTimelineApi(apiName) {
        return typeof window !== 'undefined' && typeof window[apiName] !== 'undefined';
    }

    /**
     * Resolve the scroll-timeline polyfill, guarding against duplicate work so
     * multiple timeline commands share one Promise.
     *
     * The polyfill is bundled into the elm-motion distribution at build time
     * (rollup `inlineDynamicImports: true`) - no third-party CDN fetch, no SRI,
     * no version drift between npm dependency and runtime fetch.
     *
     * The polyfill module is a side-effect script: evaluating it runs an IIFE that
     * feature-detects ScrollTimeline / ViewTimeline and installs them on `window`
     * only when native support is missing. In the shipped bundle that evaluation
     * happens once at module load (the inlined dynamic import is hoisted), so by
     * the time this runs the polyfill has usually already installed and the import
     * below resolves synchronously against the evaluated module. In the unbundled
     * source (dev/tests) the dynamic import triggers that evaluation on first call.
     */
    function loadTimelinePolyfill() {
        if (timelinePolyfillLoadPromise) {
            return timelinePolyfillLoadPromise;
        }

        timelinePolyfillLoadPromise = Promise.resolve().then(function () { return scrollTimeline; })
            .then(() => undefined);

        return timelinePolyfillLoadPromise;
    }

    /**
     * Ensure a timeline API is available, loading the polyfill if necessary.
     * Returns true if the API is available after this call, false otherwise.
     */
    async function ensureTimelineApi(apiName) {
        if (hasTimelineApi(apiName)) {
            return true;
        }

        try {
            await loadTimelinePolyfill();
        } catch (error) {
            reportError(error, {
                source: 'polyfill',
                severity: 'warning',
                code: 'POLYFILL_LOAD_FAILED',
                engine: apiName
            });
            return false;
        }

        if (!hasTimelineApi(apiName)) {
            reportError('Timeline polyfill loaded but ' + apiName + ' is still unavailable', {
                source: 'polyfill',
                severity: 'warning',
                code: 'POLYFILL_API_MISSING',
                engine: apiName
            });
            return false;
        }

        return true;
    }

    /**
     * Read the current progress (0.0–1.0) of a scroll-driven Animation object.
     * Unlike time-based animations, currentTime is a CSSUnitValue, not a number.
     * getComputedTiming().progress is always a plain number in [0, 1] or null.
     */
    function getScrollAnimationProgress(animation) {
        try {
            const timing = animation.effect && animation.effect.getComputedTiming();
            if (timing && timing.progress !== null && timing.progress !== undefined) {
                return Math.min(1.0, Math.max(0.0, timing.progress));
            }
        } catch (error) {
            reportError(error, {
                source: 'scroll',
                severity: 'warning',
                code: 'SCROLL_PROGRESS_READ_FAILED'
            });
        }
        return 0;
    }

    /**
     * Attach finish, cancel, and iteration listeners to a group of scroll-driven animations.
     * Emits port events to Elm matching the 'animationUpdate' format used by the WAAPI engine.
     */
    function attachScrollDrivenListeners(animGroup, animations, engine, element, discreteExit, emitProgress) {
        const total = animations.length;
        let cancelFired = false;

        // Per-pass tracking: a scroll-driven animation can cross its end point
        // many times as the user scrolls back and forth, and the spec re-fires
        // 'finish' on every forward crossing. We dedupe the group-level
        // 'completed' event per pass and re-arm whenever any member animation
        // leaves the 'finished' playState.
        const perAnimFinished = new Array(total).fill(false);
        let passEmitted = false;

        // Initialise group iteration counter (reset on each animate call).
        scrollDrivenIterationCounts.set(animGroup, 0);

        // Per-animation iteration counts used to deduplicate the group event:
        // a group with N properties fires N native 'iteration' events per loop.
        const perAnimIterations = new Array(total).fill(0);

        function maybeEmitCompleted() {
            if (passEmitted) return;
            for (let i = 0; i < total; i++) {
                if (!perAnimFinished[i]) return;
            }
            passEmitted = true;
            if (element && discreteExit) {
                Object.entries(discreteExit).forEach(function ([prop, values]) {
                    element.style[prop] = values.to;
                });
            }
            sendScrollLifecycleEvent('completed', animGroup, 1.0, engine);
        }

        // Synthetic 'started' watcher: scroll/view timelines have no native play
        // event, so we poll the representative animation's computed progress once
        // per frame. A 'started' event fires each time progress transitions from
        // null/0 (out of range) to > 0 (in range). The same tick also re-arms the
        // per-pass 'completed' flag when any animation leaves the 'finished'
        // state, so a subsequent forward crossing of the end emits another
        // 'completed'. When emitProgress is true, the loop also forwards every
        // in-range progress sample.
        //
        // The RAF handle is captured so 'cancel' (and an element-detached guard)
        // can stop the loop deterministically; otherwise the closure retains
        // `element`, `animations`, and `discreteExit` for the lifetime of the
        // page, even after the host element is unmounted from the DOM.
        let rafId = null;
        if (animations.length > 0 && typeof window !== 'undefined' && typeof window.requestAnimationFrame === 'function') {
            const representative = animations[0];
            let inRange = false;
            const tick = function () {
                if (cancelFired) {
                    rafId = null;
                    return;
                }
                // Element detached without an explicit cancel - stop polling and
                // release the closure so the GC can reclaim it.
                if (element && typeof element.isConnected === 'boolean' && !element.isConnected) {
                    cancelFired = true;
                    rafId = null;
                    cleanupAnimGroup(animGroup);
                    return;
                }
                for (let i = 0; i < total; i++) {
                    if (perAnimFinished[i] && animations[i].playState !== 'finished') {
                        perAnimFinished[i] = false;
                        passEmitted = false;
                    }
                }
                const progress = getScrollAnimationProgress(representative);
                if (!inRange && progress > 0) {
                    inRange = true;
                    sendScrollLifecycleEvent('started', animGroup, progress, engine);
                } else if (inRange && progress <= 0) {
                    inRange = false;
                }
                if (emitProgress && inRange) {
                    sendScrollLifecycleEvent('progress', animGroup, progress, engine);
                }
                rafId = window.requestAnimationFrame(tick);
            };
            rafId = window.requestAnimationFrame(tick);
        }

        animations.forEach(function (animation, i) {
            animation.addEventListener('finish', function () {
                perAnimFinished[i] = true;
                maybeEmitCompleted();
            });

            animation.addEventListener('cancel', function () {
                if (cancelFired) return;
                cancelFired = true;
                if (rafId !== null && typeof window !== 'undefined' && typeof window.cancelAnimationFrame === 'function') {
                    window.cancelAnimationFrame(rafId);
                    rafId = null;
                }
                const progress = getScrollAnimationProgress(animation);
                sendScrollLifecycleEvent('cancelled', animGroup, progress, engine);
                cleanupAnimGroup(animGroup);
            }, { once: true });

            animation.addEventListener('iteration', function () {
                perAnimIterations[i]++;
                const storedCount = scrollDrivenIterationCounts.get(animGroup) || 0;
                const nextGroupIteration = updateGroupIteration(perAnimIterations, i, perAnimIterations[i], storedCount);
                if (nextGroupIteration != null) {
                    scrollDrivenIterationCounts.set(animGroup, nextGroupIteration);
                    sendScrollLifecycleEvent('iteration', animGroup, nextGroupIteration, engine);
                }
            });
        });
    }

    /**
     * Apply a scroll/view-driven animation to a single element using the given timeline.
     * Builds start/end keyframes from each property config and calls element.animate().
     */
    function applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, engine, discreteEntry, discreteExit, emitProgress) {
        sendScrollLifecycleEvent('run', animGroup, 0, engine);

        const effectiveDiscreteEntry = Object.assign({}, discreteEntry || {}, elementConfig.discreteEntry || {});
        const effectiveDiscreteExit = Object.assign({}, discreteExit || {}, elementConfig.discreteExit || {});

        // Apply discrete entry styles immediately so the element is in the correct
        // state when the animation begins.
        if (effectiveDiscreteEntry) {
            Object.entries(effectiveDiscreteEntry).forEach(function ([prop, value]) {
                element.style[prop] = value;
            });
        }

        // Scroll-driven animations are continuous for the lifetime of the scroll
        // interaction, so the GPU hint is seeded once at start and intentionally
        // never cleared (no `cleanupAnimGroup` runs for these engines).
        if (elementConfig.willChange && typeof elementConfig.willChange === 'string') {
            try {
                element.style.willChange = elementConfig.willChange;
                appliedWillChange.set(animGroup, { element: element, value: elementConfig.willChange });
            } catch (_) {
                // Non-fatal.
            }
        }
        const baseTimingOptions = Object.assign(
            { timeline: timeline, fill: 'both' },
            rangeOptions || {},
            playbackOptions ? { iterations: playbackOptions.iterations, direction: playbackOptions.direction } : {}
        );
        const properties = elementConfig.properties || [];

        const transformProperties = properties.filter(p =>
            p.type === 'translate' || p.type === 'scale' || p.type === 'rotate' || p.type === 'skew'
        );
        const nonTransformProperties = properties.filter(p =>
            p.type !== 'translate' && p.type !== 'scale' && p.type !== 'rotate' && p.type !== 'skew'
        );

        const animations = [];

        nonTransformProperties.forEach(function (property) {
            const resolved = resolveNonTransformValues(animGroup, element, property);
            if (!resolved) return;

            const { keyframes, animationEasing } = buildPropertyKeyframes(resolved, property.easingKeyframes, property.easing);
            if (!keyframes) return;

            const propertyTimingOptions = Object.assign({}, baseTimingOptions, { easing: animationEasing });
            animations.push(element.animate(keyframes, applyReducedMotion(propertyTimingOptions)));
        });

        if (transformProperties.length > 0) {
            const currentTransform = getTransformState(animGroup, element);
            const order = (elementConfig.transformOrder && elementConfig.transformOrder.length > 0)
                ? elementConfig.transformOrder
                : (elementTransformOrders.get(animGroup) || DEFAULT_TRANSFORM_ORDER);

            const { start: sv, end: ev } = resolveScrollDrivenTransformValues(transformProperties, currentTransform);

            // Force every keyframe to list the same set of transform functions
            // so WAAPI uses per-function interpolation instead of decomposing
            // to matrix3d (which silently drops rotation when an endpoint
            // produces an identity rotation matrix). See animations.js
            // computeForceGroups for the same logic on time-driven animations.
            const forceGroups = new Set();
            if (sv.x !== 0 || sv.y !== 0 || sv.z !== 0 || ev.x !== 0 || ev.y !== 0 || ev.z !== 0) {
                forceGroups.add('translate');
            }
            if (sv.scaleX !== 1 || sv.scaleY !== 1 || sv.scaleZ !== 1 || ev.scaleX !== 1 || ev.scaleY !== 1 || ev.scaleZ !== 1) {
                forceGroups.add('scale');
            }
            if (sv.rotateX !== 0 || sv.rotateY !== 0 || sv.rotateZ !== 0 || ev.rotateX !== 0 || ev.rotateY !== 0 || ev.rotateZ !== 0) {
                forceGroups.add('rotate');
            }
            if (sv.skewX !== 0 || sv.skewY !== 0 || ev.skewX !== 0 || ev.skewY !== 0) {
                forceGroups.add('skew');
            }

            const transformTimingOptions = Object.assign({}, baseTimingOptions);
            const firstTransform = transformProperties[0];

            let transformKeyframes;
            if (firstTransform.easingKeyframes && Array.isArray(firstTransform.easingKeyframes)) {
                transformKeyframes = firstTransform.easingKeyframes.map(function (sample) {
                    const offset = sample.offset;
                    const p = sample.value;
                    return {
                        offset: offset,
                        transform: buildTransformString(
                            sv.x + (ev.x - sv.x) * p,
                            sv.y + (ev.y - sv.y) * p,
                            sv.z + (ev.z - sv.z) * p,
                            sv.scaleX + (ev.scaleX - sv.scaleX) * p,
                            sv.scaleY + (ev.scaleY - sv.scaleY) * p,
                            sv.scaleZ + (ev.scaleZ - sv.scaleZ) * p,
                            sv.rotateX + (ev.rotateX - sv.rotateX) * p,
                            sv.rotateY + (ev.rotateY - sv.rotateY) * p,
                            sv.rotateZ + (ev.rotateZ - sv.rotateZ) * p,
                            sv.skewX + (ev.skewX - sv.skewX) * p,
                            sv.skewY + (ev.skewY - sv.skewY) * p,
                            order, forceGroups,
                            ev.translateUnitX || sv.translateUnitX || 'px',
                            ev.translateUnitY || sv.translateUnitY || 'px',
                            ev.translateUnitZ || sv.translateUnitZ || 'px'
                        )
                    };
                });
                transformTimingOptions.easing = 'linear';
            } else {
                const startTransform = buildTransformString(
                    sv.x, sv.y, sv.z,
                    sv.scaleX, sv.scaleY, sv.scaleZ,
                    sv.rotateX, sv.rotateY, sv.rotateZ,
                    sv.skewX, sv.skewY, order, forceGroups,
                    sv.translateUnitX || 'px',
                    sv.translateUnitY || 'px',
                    sv.translateUnitZ || 'px'
                );
                const endTransform = buildTransformString(
                    ev.x, ev.y, ev.z,
                    ev.scaleX, ev.scaleY, ev.scaleZ,
                    ev.rotateX, ev.rotateY, ev.rotateZ,
                    ev.skewX, ev.skewY, order, forceGroups,
                    ev.translateUnitX || 'px',
                    ev.translateUnitY || 'px',
                    ev.translateUnitZ || 'px'
                );
                transformKeyframes = [{ transform: startTransform }, { transform: endTransform }];
                if (firstTransform.easing) {
                    transformTimingOptions.easing = easingFunctions[firstTransform.easing] || firstTransform.easing;
                }
            }

            animations.push(element.animate(transformKeyframes, applyReducedMotion(transformTimingOptions)));
        }

        if (animations.length > 0 && engine) {
            attachScrollDrivenListeners(animGroup, animations, engine, element, effectiveDiscreteExit || {}, !!emitProgress);
        }
    }

    /**
     * Build the {playbackOptions, discreteEntry, discreteExit} bundle shared by
     * both scroll-driven and view-driven processing.
     */
    function buildSharedTimelineOptions(commandData) {
        return {
            playbackOptions: {
                iterations: parseIterations(commandData.iterations),
                direction: commandData.direction || 'normal'
            },
            discreteEntry: commandData.discreteEntry || {},
            discreteExit: commandData.discreteExit || {},
            defaultEmitProgress: !!commandData.emitProgress
        };
    }

    /**
     * Build the rangeOptions object for a ViewTimeline from its config.
     * Per-element overrides win over the timeline defaults.
     */
    function buildViewRangeOptions(timelineConfig, elementConfig) {
        const rangeOptions = {};
        if (timelineConfig.rangeStart) rangeOptions.rangeStart = timelineConfig.rangeStart;
        if (timelineConfig.rangeEnd) rangeOptions.rangeEnd = timelineConfig.rangeEnd;
        if (elementConfig && elementConfig.rangeStart) rangeOptions.rangeStart = elementConfig.rangeStart;
        if (elementConfig && elementConfig.rangeEnd) rangeOptions.rangeEnd = elementConfig.rangeEnd;
        return rangeOptions;
    }

    /**
     * Validate that a timeline command has the expected shape and that the
     * required browser API is present. Reports the appropriate error and
     * returns false on failure.
     */
    function validateTimelineCommand(commandData, source, engine, apiPresent) {
        if (!commandData || !commandData.elements) {
            reportError('Invalid ' + source + ' data', {
                source: source,
                severity: 'warning',
                code: 'COMMAND_INVALID',
                engine: engine
            });
            return false;
        }
        if (!apiPresent) {
            reportError(engine + ' is not supported in this browser', {
                source: source,
                severity: 'warning',
                code: 'API_UNSUPPORTED',
                engine: engine
            });
            return false;
        }
        return true;
    }

    /**
     * Resolve the scroll-source element from a timelineConfig.source id.
     * Returns null and reports an error if not found.
     */
    function resolveScrollSource(sourceId) {
        if (sourceId === 'document') {
            return document.documentElement;
        }
        const element = document.querySelector('[data-anim-target="' + CSS.escape(sourceId) + '"]')
            || document.getElementById(sourceId);
        if (!element) {
            reportError('Scroll source element "' + sourceId + '" not found', {
                source: 'scrollDriven',
                severity: 'warning',
                code: 'SCROLL_SOURCE_NOT_FOUND',
                engine: 'ScrollTimeline',
                details: { sourceId: sourceId }
            });
        }
        return element;
    }

    /**
     * Resolve a per-element animation target. Returns null and reports an error
     * if the target cannot be found.
     */
    function resolveTimelineTarget(targetId, animGroup, source, engine) {
        const element = findAnimTarget(targetId);
        if (!element) {
            reportError('Element target "' + targetId + '" not found for ' + source + ' animation', {
                source: source,
                severity: 'warning',
                code: 'TARGET_NOT_FOUND',
                engine: engine,
                elementId: targetId,
                details: { animGroup: animGroup }
            });
        }
        return element;
    }

    /**
     * Process a scroll-driven animation using ScrollTimeline.
     */
    function processScrollDrivenData(commandData) {
        if (!validateTimelineCommand(commandData, 'scrollDriven', 'ScrollTimeline', typeof ScrollTimeline !== 'undefined')) {
            return;
        }

        const timelineConfig = commandData.timeline || {};
        const sourceId = timelineConfig.source || 'document';
        const axis = timelineConfig.axis || 'block';

        const sourceElement = resolveScrollSource(sourceId);
        if (!sourceElement) {
            return;
        }

        const timeline = new ScrollTimeline({ source: sourceElement, axis: axis });
        const { playbackOptions, discreteEntry, discreteExit, defaultEmitProgress } = buildSharedTimelineOptions(commandData);

        Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
            const targetId = elementConfig.target || animGroup;
            const element = resolveTimelineTarget(targetId, animGroup, 'scrollDriven', 'ScrollTimeline');
            if (!element) return;
            const emitProgress =
                typeof elementConfig.emitProgress === 'boolean'
                    ? elementConfig.emitProgress
                    : defaultEmitProgress;
            applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, null, playbackOptions, 'scrollTimeline', discreteEntry, discreteExit, emitProgress);
        });
    }

    /**
     * Apply a view-driven animation to a single element entry.
     */
    function applyViewDrivenForEntry(animGroup, elementConfig, axis, rangeOptions, playbackOptions, discreteEntry, discreteExit, emitProgress) {
        const targetId = elementConfig.target || animGroup;
        const element = resolveTimelineTarget(targetId, animGroup, 'viewDriven', 'ViewTimeline');
        if (!element) return;

        const timeline = new ViewTimeline({ subject: element, axis: axis });
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, 'viewTimeline', discreteEntry, discreteExit, emitProgress);
    }

    /**
     * Process a view-driven animation using ViewTimeline.
     */
    function processViewDrivenData(commandData) {
        if (!validateTimelineCommand(commandData, 'viewDriven', 'ViewTimeline', typeof ViewTimeline !== 'undefined')) {
            return;
        }

        const timelineConfig = commandData.timeline || {};
        const axis = timelineConfig.axis || 'block';
        const { playbackOptions, discreteEntry, discreteExit, defaultEmitProgress } = buildSharedTimelineOptions(commandData);

        Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
            const emitProgress =
                typeof elementConfig.emitProgress === 'boolean'
                    ? elementConfig.emitProgress
                    : defaultEmitProgress;
            const rangeOptions = buildViewRangeOptions(timelineConfig, elementConfig);
            applyViewDrivenForEntry(animGroup, elementConfig, axis, rangeOptions, playbackOptions, discreteEntry, discreteExit, emitProgress);
        });
    }

    /* eslint-env browser */
    /**
     * ElmMotion JavaScript Integration (ES Module source)
     * Canonical source for bundling ESM and IIFE distributions.
     *
     * This is the entry point only. All implementation lives in the sub-modules:
     *   state.js      – shared mutable state Maps (incl. portsRef)
     *   utils.js      – pure utility functions
     *   transform.js  – transform math and DOM helpers
     *   properties.js – property resolution and keyframe builders
     *   ports.js      – Elm port communication
     *   animations.js – WAAPI animation engine
     *   scroll.js     – scroll-driven and view-driven timeline engine
     *   errors.js     – opt-in error reporting (onError, useConsoleReporter)
     */

    /**
     * Validate an inbound port command. Returns true if it is well-formed.
     */
    function validateCommand(commandData) {
        if (!commandData) {
            reportError('No command data received', {
                source: 'motionCmd',
                severity: 'warning',
                code: 'COMMAND_EMPTY'
            });
            return false;
        }
        if (!commandData.type) {
            reportError('Command missing type field', {
                source: 'motionCmd',
                severity: 'warning',
                code: 'COMMAND_TYPE_MISSING',
                details: { commandData: commandData }
            });
            return false;
        }
        return true;
    }

    /**
     * Dispatch table mapping inbound command types to their handlers.
     * Each handler receives the raw commandData object.
     * Async handlers may return a Promise; the dispatcher awaits them.
     */
    const COMMAND_HANDLERS = {
        animate: function (commandData) {
            processAnimationData(commandData);
        },
        retarget: function (commandData) {
            retargetAnimation(commandData);
        },
        snap: function (commandData) {
            // Same wire shape as `retarget`, same effect: cancel any in-flight
            // WAAPI animation on each named property and apply the end value
            // as inline style. No touchedAxes => full snap.
            retargetAnimation(commandData);
        },
        resize: function (commandData) {
            resizeTransformAnimation(commandData);
        },
        scrollDriven: async function (commandData) {
            if (await ensureTimelineApi('ScrollTimeline')) {
                processScrollDrivenData(commandData);
            }
        },
        viewDriven: async function (commandData) {
            if (await ensureTimelineApi('ViewTimeline')) {
                processViewDrivenData(commandData);
            }
        },
        setProperties: function (commandData) {
            setProperties(commandData.updates);
        },
        stop: function (commandData) {
            stopAnimation(commandData.elementId, commandData.properties);
        },
        reset: function (commandData) {
            resetAnimation(commandData.elementId, commandData.properties);
        },
        restart: function (commandData) {
            restartAnimation(commandData.elementId, commandData.properties);
        },
        pause: function (commandData) {
            pauseAnimation(commandData.elementId, commandData.properties);
        },
        resume: function (commandData) {
            resumeAnimation(commandData.elementId, commandData.properties);
        }
    };

    /**
     * Look up and invoke the handler for a single command. Reports an error
     * if the command type is unknown or the handler throws/rejects.
     */
    async function dispatchCommand(commandData) {
        const handler = COMMAND_HANDLERS[commandData.type];
        if (!handler) {
            reportError('Unknown command type: ' + commandData.type, {
                source: 'motionCmd',
                severity: 'warning',
                code: 'COMMAND_TYPE_UNKNOWN',
                commandType: commandData.type
            });
            return;
        }
        await handler(commandData);
    }

    /**
     * Initialize the ElmMotion WAAPI system with Elm ports.
     *
     * If called again with a different ports object, `dispose()` is invoked
     * automatically to release per-group caches before re-attaching to the
     * new app — callers don't need to clean up manually for the common
     * reinitialization case. A warning is still reported via 
     * `PORTS_REINITIALIZED` so the swap is observable.
     *
     * @param {object} ports - The Elm app ports object (app.ports)
     */
    function init(ports) {
        if (!ports) {
            reportError('No ports provided to init()', { source: 'init', code: 'PORTS_MISSING' });
            return;
        }

        if (portsRef.ports && portsRef.ports !== ports) {
            reportError('init() called with a different ports object; previous app state has been disposed automatically', {
                source: 'init',
                severity: 'warning',
                code: 'PORTS_REINITIALIZED'
            });
            dispose();
        }

        portsRef.ports = ports;
        resetPortMissingWarning();

        if (!ports.motionCmd || !ports.motionCmd.subscribe) {
            reportError('motionCmd port not found or not subscribeable', {
                source: 'init',
                severity: 'warning',
                code: 'PORT_NOT_SUBSCRIBEABLE'
            });
            return;
        }

        ports.motionCmd.subscribe(async function (commandData) {
            try {
                if (!validateCommand(commandData)) return;
                await dispatchCommand(commandData);
            } catch (error) {
                reportError(error, {
                    source: 'motionCmd',
                    code: 'COMMAND_PROCESSING_FAILED',
                    commandType: commandData && commandData.type
                });
            }
        });
    }

    /**
     * Tear down the ElmMotion JS-side state. Call this when the host Elm app
     * is being unmounted to release any cached per-animation-group state and
     * stop attempting to send events to a stale ports object.
     *
     * After dispose(), call init() again with a fresh ports object to resume.
     */
    function dispose() {
        portsRef.ports = null;
        clearAllState();
        resetPortMissingWarning();
    }

    var index = { init: init, dispose: dispose, onError: onError, useConsoleReporter: useConsoleReporter, setPropertyUpdateThrottle: setPropertyUpdateThrottle, setReducedMotion: setReducedMotion };

    var __defProp=Object.defineProperty,__defNormalProp=(e,t,n)=>t in e?__defProp(e,t,{enumerable:true,configurable:true,writable:true,value:n}):e[t]=n,__publicField=(e,t,n)=>(__defNormalProp(e,"symbol"!=typeof t?t+"":t,n),n);!function(){class e{}class t extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class n extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class i extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class r extends e{constructor(e,t="unrestricted"){super(),__publicField(this,"type"),__publicField(this,"value"),this.value=e,this.type=t;}}class o extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class s extends e{}class a extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class l extends e{}class c extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class u extends e{constructor(e,t="integer"){super(),__publicField(this,"value"),__publicField(this,"type"),this.value=e,this.type=t;}}class m extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class f extends e{constructor(e,t,n){super(),__publicField(this,"value"),__publicField(this,"type"),__publicField(this,"unit"),this.value=e,this.type=t,this.unit=n;}}class h extends e{}class p extends e{}class d extends e{}class S extends e{}class g extends e{}class v extends e{}class T extends e{}class y extends e{}class w extends e{}class x extends e{}class b extends e{}class C extends e{}class E{constructor(e){__publicField(this,"input"),__publicField(this,"index",0),this.input=e;}consume(){const e=this.input.codePointAt(this.index);return void 0!==e&&(this.index+=String.fromCodePoint(e).length),e}reconsume(e){ void 0!==e&&(this.index-=String.fromCodePoint(e).length);}peek(){const e=[];let t=this.index;for(let n=0;n<3&&t<this.input.length;n++){const n=this.input.codePointAt(t);e.push(n),t+=String.fromCodePoint(n).length;}return e}}function k(e){return 10===e}function M(e){return k(e)||8192===e||32===e}function P(e){return e>=48&&e<=57}function I(e){return P(e)||e>=65&&e<=70||e>=97&&e<=102}function R(e){return function(e){return function(e){return e>=65&&e<=90}(e)||function(e){return e>=97&&e<=122}(e)}(e)||function(e){return e>=128}(e)||95===e}function N(e){return R(e)||P(e)||45===e}function A(e){return e>=0&&e<=8||11===e||e>=14&&e<=31||127===e}function V(e,t){return 92===e&&!k(t)}function _(e,t,n){return 45===e?R(t)||45===t||V(t,n):!!R(e)||92===e&&V(e,t)}function L(e,t,n){return 43===e||45===e?P(t)||46===t&&P(n):P(46===e?t:e)}function O(e){const t=e.consume();if(I(t)){let n=[t];for(;I(...e.peek())&&n.length<5;)n.push(e.consume());M(...e.peek())&&e.consume();const i=parseInt(String.fromCodePoint(...n),16);return 0===i||i>1114111?65533:i}return void 0===t?65533:t}function U(e,t){const n=new o("");for(;;){const i=e.consume();if(i===t)return n;if(void 0===i)return n;if(10===i)return e.reconsume(i),new s;if(92===i){const t=e.peek()[0];void 0===t||(k(t)?e.consume():n.value+=String.fromCodePoint(O(e)));}else n.value+=String.fromCodePoint(i);}}function j(e){let t="";for(;;){const n=e.consume();if(N(n))t+=String.fromCodePoint(n);else {if(!V(...e.peek()))return e.reconsume(n),t;t+=String.fromCodePoint(O(e));}}}function W(e){let t=function(e){let t="integer",n="";for([43,45].includes(e.peek()[0])&&(n+=String.fromCodePoint(e.consume()));P(...e.peek());)n+=String.fromCodePoint(e.consume());if(46===e.peek()[0]&&P(e.peek()[1]))for(n+=String.fromCodePoint(e.consume(),e.consume()),t="number";P(...e.peek());)n+=String.fromCodePoint(e.consume());return [69,101].includes(e.peek()[0])&&([45,43].includes(e.peek()[1])&&P(e.peek()[2])?(n+=String.fromCodePoint(e.consume(),e.consume(),e.consume()),t="number"):P(e.peek()[1])&&(n+=String.fromCodePoint(e.consume(),e.consume()),t="number")),{value:parseFloat(n),type:t}}(e);return _(...e.peek())?new f(t.value,t.type,j(e)):37===e.peek()[0]?(e.consume(),new m(t.value)):new u(t.value,t.type)}function F(e){for(;;){const t=e.consume();if(41===t||void 0===t)return;V(...e.peek())&&O(e);}}function D(e){const i=j(e);if(i.match(/url/i)&&40===e.peek()[0]){for(e.consume();M(e.peek()[0])&&M(e.peek()[1]);)e.consume();return [34,39].includes(e.peek()[0])||M(e.peek()[0])&&[34,39].includes(e.peek()[1])?new n(i):function(e){const t=new a("");for(;M(...e.peek());)e.consume();for(;;){const n=e.consume();if(41===n)return t;if(void 0===n)return t;if(M(n)){for(;M(...e.peek());)e.consume();return 41===e.peek()[0]||void 0===e.peek()[0]?(e.consume(),t):(F(e),new l)}if([34,39,40].includes(n)||A(n))return F(e),new l;if(92===n){if(!V(...e.peek()))return F(e),new l;t.value+=O(e);}else t.value+=String.fromCodePoint(n);}}(e)}return 40===e.peek()[0]?(e.consume(),new n(i)):new t(i)}function z(e){const t=e.consume(),n=e.peek();if(M(t)){for(;M(...e.peek());)e.consume();return new h}if(34===t)return U(e,t);if(35===t){if(N(n[0])||V(...n)){const t=new r;return _(...n)&&(t.type="id"),t.value=j(e),t}return new c(String.fromCodePoint(t))}return 39===t?U(e,t):40===t?new w:41===t?new x:43===t?L(...n)?(e.reconsume(t),W(e)):new c(String.fromCodePoint(t)):44===t?new v:45===t?L(...e.peek())?(e.reconsume(t),W(e)):45===e.peek()[0]&&62===e.peek()[1]?(e.consume(),e.consume(),new d):_(...e.peek())?(e.reconsume(t),D(e)):new c(String.fromCodePoint(t)):46===t?L(...e.peek())?(e.reconsume(t),W(e)):new c(String.fromCodePoint(t)):58===t?new S:59===t?new g:60===t?33===n[0]&&45===n[1]&&45===n[2]?(e.consume(),e.consume(),e.consume(),new p):new c(String.fromCodePoint(t)):64===t?_(...n)?new i(j(e)):new c(String.fromCodePoint(t)):91===t?new T:92===t?V(...n)?(e.reconsume(t),D(e)):new c(String.fromCodePoint(t)):93===t?new y:123===t?new b:125===t?new C:P(t)?(e.reconsume(t),W(e)):R(t)?(e.reconsume(t),D(e)):void 0===t?void 0:new c(String.fromCodePoint(t))}const H=new Set(["px","deg","s","hz","dppx","number","fr"]);function $(e){return H.has(e.toLowerCase())}function q(e,t){if(["x","y"].includes(e))return e;if(!t)throw new Error("To determine the normalized axis the computedStyle of the source is required.");const n="horizontal-tb"==t.writingMode;if("block"===e)e=n?"y":"x";else {if("inline"!==e)throw new TypeError(`Invalid axis “${e}”`);e=n?"x":"y";}return e}function B(e){const t=[];let n=0;function i(){let t=0;const i=n;for(;n<e.length;){const i=e.slice(n,n+1);if(/\s/.test(i)&&0===t)break;if("("===i)t+=1;else if(")"===i&&(t-=1,0===t)){n++;break}n++;}return e.slice(i,n)}function r(){for(;/\s/.test(e.slice(n,n+1));)n++;}for(;n<e.length;){const o=e.slice(n,n+1);/\s/.test(o)?r():t.push(i());}return t}function K(e,t){return e.reduce(((e,n)=>(e.has(n[t])?e.get(n[t]).push(n):e.set(n[t],[n]),e)),new Map)}function G(e,t){const n=[],i=[];for(const r of e)t(r)?n.push(r):i.push(r);return [n,i]}function Q(e,t={}){function n(e){return Array.from(e).map((e=>Q(e,t)))}if(e instanceof CSSUnitValue){if("percent"===e.unit&&t.percentageReference){const n=e.value/100*t.percentageReference.value,i=t.percentageReference.unit;return new CSSUnitValue(n,i)}const n=e.toSum();if(n&&1===n.values.length&&(e=n.values[0]),e instanceof CSSUnitValue&&"em"===e.unit&&t.fontSize&&(e=new CSSUnitValue(e.value*t.fontSize.value,t.fontSize.unit)),e instanceof CSSKeywordValue){if("e"===e.value)return new CSSUnitValue(Math.E,"number");if("pi"===e.value)return new CSSUnitValue(Math.PI,"number")}return e}if(!e.operator)return e;switch(e.operator){case "sum":e=new CSSMathSum(...n(e.values));break;case "product":e=new CSSMathProduct(...n(e.values));break;case "negate":e=new CSSMathNegate(Q(e.value,t));break;case "clamp":e=new CSSMathClamp(Q(e.lower,t),Q(e.value,t),Q(e.upper,t));break;case "invert":e=new CSSMathInvert(Q(e.value,t));break;case "min":e=new CSSMathMin(...n(e.values));break;case "max":e=new CSSMathMax(...n(e.values));}if(e instanceof CSSMathMin||e instanceof CSSMathMax){const t=Array.from(e.values);if(t.every((e=>e instanceof CSSUnitValue&&"percent"!==e.unit&&$(e.unit)&&e.unit===t[0].unit))){const n=Math[e.operator].apply(Math,t.map((({value:e})=>e)));return new CSSUnitValue(n,t[0].unit)}}if(e instanceof CSSMathMin||e instanceof CSSMathMax){const t=Array.from(e.values),[n,i]=G(t,(e=>e instanceof CSSUnitValue&&"percent"!==e.unit)),r=Array.from(K(n,"unit").values());if(r.some((e=>e.length>0))){const t=r.map((t=>{const n=Math[e.operator].apply(Math,t.map((({value:e})=>e)));return new CSSUnitValue(n,t[0].unit)}));e=e instanceof CSSMathMin?new CSSMathMin(...t,...i):new CSSMathMax(...t,...i);}return 1===t.length?t[0]:e}if(e instanceof CSSMathNegate)return e.value instanceof CSSUnitValue?new CSSUnitValue(0-e.value.value,e.value.unit):e.value instanceof CSSMathNegate?e.value.value:e;if(e instanceof CSSMathInvert)return e.value instanceof CSSMathInvert?e.value.value:e;if(e instanceof CSSMathSum){let t=function(e){const t=e.filter((e=>e instanceof CSSUnitValue));return [...e.filter((e=>!(e instanceof CSSUnitValue))),...Array.from(K(t,"unit").entries()).map((([e,t])=>{const n=t.reduce(((e,{value:t})=>e+t),0);return new CSSUnitValue(n,e)}))]},n=[];for(const i of e.values)i instanceof CSSMathSum?n.push(...i.values):n.push(i);return n=t(n),1===n.length?n[0]:new CSSMathSum(...n)}if(e instanceof CSSMathProduct){let t=[];for(const r of e.values)r instanceof CSSMathProduct?t.push(...r.values):t.push(r);const[n,i]=G(t,(e=>e instanceof CSSUnitValue&&"number"===e.unit));if(n.length>1){const e=n.reduce(((e,{value:t})=>e*t),1);t=[new CSSUnitValue(e,"number"),...i];}if(2===t.length){let e,n;for(const i of t)i instanceof CSSUnitValue&&"number"===i.unit?e=i:i instanceof CSSMathSum&&[...i.values].every((e=>e instanceof CSSUnitValue))&&(n=i);if(e&&n)return new CSSMathSum(...[...n.values].map((t=>new CSSUnitValue(t.value*e.value,t.unit))))}if(t.every((e=>e instanceof CSSUnitValue&&$(e.unit)||e instanceof CSSMathInvert&&e.value instanceof CSSUnitValue&&$(e.value.unit)))){const e=new CSSMathProduct(...t).toSum();if(e&&1===e.values.length)return e.values[0]}return new CSSMathProduct(...t)}return e}const X=null,Y=["percent","length","angle","time","frequency","resolution","flex"],J={fontRelativeLengths:{units:new Set(["em","rem","ex","rex","cap","rcap","ch","rch","ic","ric","lh","rlh"])},viewportRelativeLengths:{units:new Set(["vw","lvw","svw","dvw","vh","lvh","svh","dvh","vi","lvi","svi","dvi","vb","lvb","svb","dvb","vmin","lvmin","svmin","dvmin","vmax","lvmax","svmax","dvmax"])},absoluteLengths:{units:new Set(["cm","mm","Q","in","pt","pc","px"]),compatible:true,canonicalUnit:"px",ratios:{cm:96/2.54,mm:96/2.54/10,Q:96/2.54/40,in:96,pc:16,pt:96/72,px:1}},angle:{units:new Set(["deg","grad","rad","turn"]),compatible:true,canonicalUnit:"deg",ratios:{deg:1,grad:.9,rad:180/Math.PI,turn:360}},time:{units:new Set(["s","ms"]),compatible:true,canonicalUnit:"s",ratios:{s:1,ms:.001}},frequency:{units:new Set(["hz","khz"]),compatible:true,canonicalUnit:"hz",ratios:{hz:1,khz:1e3}},resolution:{units:new Set(["dpi","dpcm","dppx"]),compatible:true,canonicalUnit:"dppx",ratios:{dpi:1/96,dpcm:2.54/96,dppx:1}}},Z=new Map;for(const Vt of Object.values(J))if(Vt.compatible)for(const e of Vt.units)Z.set(e,Vt);function ee(e){return Z.get(e)}function te(e,t){const n={...e};for(const i of Object.keys(t))n[i]?n[i]+=t[i]:n[i]=t[i];return n}function ne(e){return "number"===e?{}:"percent"===e?{percent:1}:J.absoluteLengths.units.has(e)||J.fontRelativeLengths.units.has(e)||J.viewportRelativeLengths.units.has(e)?{length:1}:J.angle.units.has(e)?{angle:1}:J.time.units.has(e)?{time:1}:J.frequency.units.has(e)?{frequency:1}:J.resolution.units.has(e)?{resolution:1}:"fr"===e?{flex:1}:X}function ie(e){if(e instanceof CSSUnitValue){let{unit:t,value:n}=e;const i=ee(e.unit);return i&&t!==i.canonicalUnit&&(n*=i.ratios[t],t=i.canonicalUnit),"number"===t?[[n,{}]]:[[n,{[t]:1}]]}if(e instanceof CSSMathInvert){if(!(e.value instanceof CSSUnitValue))throw new Error("Not implemented");const t=ie(e.value);if(t===X)return X;if(t.length>1)return X;const n=t[0],i={};for(const[e,r]of Object.entries(n[1]))i[e]=-1*r;return t[0]=[1/n[0],i],t}if(e instanceof CSSMathProduct){let t=[[1,{}]];for(const n of e.values){const e=ie(n),i=[];if(e===X)return X;for(const n of t)for(const t of e)i.push([n[0]*t[0],te(n[1],t[1])]);t=i;}return t}throw new Error("Not implemented")}function re(e,t){if(ne(t)===X)throw new SyntaxError("The string did not match the expected pattern.");const n=ie(e);if(!n)throw new TypeError;if(n.length>1)throw new TypeError("Sum has more than one item");const i=function(e,t){const n=e.unit,i=e.value,r=ee(n),o=ee(t);if(!o||r!==o)return X;return new CSSUnitValue(i*o.ratios[n]/o.ratios[t],t)}(oe(n[0]),t);if(i===X)throw new TypeError;return i}function oe(e){const[t,n]=e,i=Object.entries(n);if(i.length>1)return X;if(0===i.length)return new CSSUnitValue(t,"number");const r=i[0];return 1!==r[1]?X:new CSSUnitValue(t,r[0])}function se(e,...t){if(t&&t.length)throw new Error("Not implemented");const n=ie(e).map((e=>oe(e)));if(n.some((e=>e===X)))throw new TypeError("Type error");return new CSSMathSum(...n)}function ae(e,t){if(e.percentHint&&t.percentHint&&e.percentHint!==t.percentHint)return X;const n={...e,percentHint:e.percentHint??t.percentHint};for(const i of Y)t[i]&&(n[i]??(n[i]=0),n[i]+=t[i]);return n}class CSSFunction{constructor(e,t){__publicField(this,"name"),__publicField(this,"values"),this.name=e,this.values=t;}}class CSSSimpleBlock{constructor(e,t){__publicField(this,"value"),__publicField(this,"associatedToken"),this.value=e,this.associatedToken=t;}}function le(e){if(Array.isArray(e))return e;if("string"==typeof e)return function(e){const t=new E(e),n=[];for(;;){const e=z(t);if(void 0===e)return n;n.push(e);}}(e);throw new TypeError("Invalid input type "+typeof e)}function ce(e){const t=e.shift();return t instanceof b||t instanceof T||t instanceof w?function(e,t){let n;if(t instanceof b)n=C;else if(t instanceof w)n=x;else {if(!(t instanceof T))return;n=y;}const i=new CSSSimpleBlock([],t);for(;;){const t=e.shift();if(t instanceof n)return i;if(void 0===t)return i;e.unshift(t),i.value.push(ce(e));}}(e,t):t instanceof n?function(e,t){const n=new CSSFunction(e.value,[]);for(;;){const e=t.shift();if(e instanceof x)return n;if(void 0===e)return n;t.unshift(e),n.values.push(ce(t));}}(t,e):t}function ue(e){if(e instanceof w||e instanceof x)return 6;if(e instanceof c){switch(e.value){case "*":case "/":return 4;case "+":case "-":return 2}}}function me(e){return e[e.length-1]}function fe(e,t,n){const i=["+","-"].includes(e.value)?"ADDITION":"MULTIPLICATION",r=t.type===i?t.values:[t],o=n.type===i?n.values:[n];return "-"===e.value?o[0]={type:"NEGATE",value:o[0]}:"/"===e.value&&(o[0]={type:"INVERT",value:o[0]}),{type:i,values:[...r,...o]}}function he(e){if("ADDITION"===e.type)return new CSSMathSum(...e.values.map((e=>he(e))));if("MULTIPLICATION"===e.type)return new CSSMathProduct(...e.values.map((e=>he(e))));if("NEGATE"===e.type)return new CSSMathNegate(he(e.value));if("INVERT"===e.type)return new CSSMathInvert(he(e.value));if(e instanceof CSSSimpleBlock)return pe(new CSSFunction("calc",e.value));if(e instanceof t){if("e"===e.value)return new CSSUnitValue(Math.E,"number");if("pi"===e.value)return new CSSUnitValue(Math.PI,"number");throw new SyntaxError("Invalid math expression")}return de(e)}function pe(e){if("min"===e.name||"max"===e.name){const t=e.values.filter((e=>!(e instanceof h||e instanceof v))).map((e=>Q(pe(new CSSFunction("calc",e)))));return "min"===e.name?new CSSMathMin(...t):new CSSMathMax(...t)}if("calc"!==e.name)return null;const n=he(function(e){const n=[],i=[];for(;e.length;){const r=e.shift();if(r instanceof u||r instanceof f||r instanceof m||r instanceof CSSFunction||r instanceof CSSSimpleBlock||r instanceof t)i.push(r);else if(r instanceof c&&["*","/","+","-"].includes(r.value)){for(;n.length&&!(me(n)instanceof w)&&ue(me(n))>ue(r);){const e=n.pop(),t=i.pop(),r=i.pop();i.push(fe(e,r,t));}n.push(r);}else if(r instanceof w)n.push(r);else if(r instanceof x){if(!n.length)return null;for(;!(me(n)instanceof w);){const e=n.pop(),t=i.pop(),r=i.pop();i.push(fe(e,r,t));}if(!(me(n)instanceof w))return null;n.pop();}else if(!(r instanceof h))return null}for(;n.length;){if(me(n)instanceof w)return null;const e=n.pop(),t=i.pop(),r=i.pop();i.push(fe(e,r,t));}return i[0]}([...e.values]));let i;try{i=Q(n);}catch(r){(new CSSStyleSheet).insertRule("error",0);}return i instanceof CSSUnitValue?new CSSMathSum(i):i}function de(e){return e instanceof CSSFunction&&["calc","min","max","clamp"].includes(e.name)?pe(e):e instanceof u&&0===e.value&&!e.unit?new CSSUnitValue(0,"px"):e instanceof u?new CSSUnitValue(e.value,"number"):e instanceof m?new CSSUnitValue(e.value,"percent"):e instanceof f?new CSSUnitValue(e.value,e.unit):void 0}function Se(e){const t=function(e){const t=le(e);for(;t[0]instanceof h;)t.shift();if(void 0===t[0])return null;const n=ce(t);for(;t[0]instanceof h;)t.shift();return void 0===t[0]?n:null}(e);if(null===t&&(new CSSStyleSheet).insertRule("error",0),t instanceof u||t instanceof m||t instanceof f||t instanceof CSSFunction||(new CSSStyleSheet).insertRule("error",0),t instanceof f){null===ne(t.unit)&&(new CSSStyleSheet).insertRule("error",0);}return de(t)}!function(){let e=new WeakMap;function t(e){const t=[];for(let i=0;i<e.length;i++)t[i]="number"==typeof(n=e[i])?new CSSUnitValue(n,"number"):n;var n;return t}class CSSNumericValue2{static parse(e){return e instanceof CSSNumericValue2?e:Q(Se(e),{})}}class CSSMathValue extends CSSNumericValue2{constructor(n,i,r,o){super(),e.set(this,{values:t(n),operator:i,name:r||i,delimiter:o||", "});}get operator(){return e.get(this).operator}get values(){return e.get(this).values}toString(){const t=e.get(this);return `${t.name}(${t.values.join(t.delimiter)})`}}const n={CSSNumericValue:CSSNumericValue2,CSSMathValue:CSSMathValue,CSSUnitValue:class extends CSSNumericValue2{constructor(t,n){super(),e.set(this,{value:t,unit:n});}get value(){return e.get(this).value}set value(t){e.get(this).value=t;}get unit(){return e.get(this).unit}to(e){return re(this,e)}toSum(...e){return se(this,...e)}type(){return ne(e.get(this).unit)}toString(){const t=e.get(this);return `${t.value}${function(e){switch(e){case "percent":return "%";case "number":return "";default:return e.toLowerCase()}}(t.unit)}`}},CSSKeywordValue:class{constructor(e){this.value=e;}toString(){return this.value.toString()}},CSSMathSum:class extends CSSMathValue{constructor(e){super(arguments,"sum","calc"," + ");}},CSSMathProduct:class extends CSSMathValue{constructor(e){super(arguments,"product","calc"," * ");}toSum(...e){return se(this,...e)}type(){return e.get(this).values.map((e=>e.type())).reduce(ae)}},CSSMathNegate:class extends CSSMathValue{constructor(e){super([arguments[0]],"negate","-");}get value(){return e.get(this).values[0]}type(){return this.value.type()}},CSSMathInvert:class extends CSSMathValue{constructor(e){super([1,arguments[0]],"invert","calc"," / ");}get value(){return e.get(this).values[1]}type(){return function(e){const t={};for(const n of Y)t[n]=-1*e[n];return t}(e.get(this).values[1].type())}},CSSMathMax:class extends CSSMathValue{constructor(){super(arguments,"max");}},CSSMathMin:class extends CSSMathValue{constructor(){super(arguments,"min");}}};if(!window.CSS&&!Reflect.defineProperty(window,"CSS",{value:{}}))throw Error("Error installing CSSOM support");window.CSSUnitValue||["number","percent","em","ex","px","cm","mm","in","pt","pc","Q","vw","vh","vmin","vmax","rems","ch","deg","rad","grad","turn","ms","s","Hz","kHz","dppx","dpi","dpcm","fr"].forEach((e=>{if(!Reflect.defineProperty(CSS,e,{value:t=>new CSSUnitValue(t,e)}))throw Error(`Error installing CSS.${e}`)}));for(let[i,r]of Object.entries(n))if(!(i in window)&&!Reflect.defineProperty(window,i,{value:r}))throw Error(`Error installing CSSOM support for ${i}`)}();const ge="block";let ve=new WeakMap,Te=new WeakMap;const ye=["entry","exit","cover","contain","entry-crossing","exit-crossing"];function we(e){return e===document.scrollingElement?document:e}function xe(e){Ee(e);let t=ve.get(e).animations;if(0===t.length)return;let n=e.currentTime;for(let i=0;i<t.length;i++)t[i].tickAnimation(n);}function be(e,t){if(!e)return null;const n=Te.get(e).sourceMeasurements,i=getComputedStyle(e);let r=n.scrollTop;return "x"===q(t,i)&&(r=Math.abs(n.scrollLeft)),r}function Ce(e,t){const n=Q(e,t);if(n instanceof CSSUnitValue){if("px"===n.unit)return n.value;throw TypeError("Unhandled unit type "+n.unit)}throw TypeError("Unsupported value type: "+typeof e)}function Ee(e){if(!(e instanceof $e))return void function(e){const t=ve.get(e);if(!t.anonymousSource)return;const n=_e(t.anonymousSource,t.anonymousTarget);Re(e,n);}(e);const t=e.subject;if(!t)return void Re(e,null);if("none"==getComputedStyle(t).display)return void Re(e,null);Re(e,We(t));}function ke(e){return ["block","inline","x","y"].includes(e)}function Me(e){const t=getComputedStyle(e);return {scrollLeft:e.scrollLeft,scrollTop:e.scrollTop,scrollWidth:e.scrollWidth,scrollHeight:e.scrollHeight,clientWidth:e.clientWidth,clientHeight:e.clientHeight,writingMode:t.writingMode,direction:t.direction,scrollPaddingTop:t.scrollPaddingTop,scrollPaddingBottom:t.scrollPaddingBottom,scrollPaddingLeft:t.scrollPaddingLeft,scrollPaddingRight:t.scrollPaddingRight}}function Pe(e,t){if(!e||!t)return;let n=0,i=0,r=t;const o=e.offsetParent;for(;r&&r!=o;)i+=r.offsetLeft,n+=r.offsetTop,r=r.offsetParent;i-=e.offsetLeft+e.clientLeft,n-=e.offsetTop+e.clientTop;const s=getComputedStyle(t);return {top:n,left:i,offsetWidth:t.offsetWidth,offsetHeight:t.offsetHeight,fontSize:s.fontSize}}function Ie(e){let t=Te.get(e);t.sourceMeasurements=Me(e);for(const n of t.timelineRefs){const t=n.deref();if(t instanceof $e){ve.get(t).subjectMeasurements=Pe(e,t.subject);}}t.updateScheduled||(setTimeout((()=>{for(const e of t.timelineRefs){const t=e.deref();t&&xe(t);}t.updateScheduled=false;})),t.updateScheduled=true);}function Re(e,t){const n=ve.get(e),i=n.source;if(i!=t){if(i){const t=Te.get(i);if(t){t.timelineRefs.delete(e);const n=Array.from(t.timelineRefs).filter((e=>void 0===e.deref()));for(const e of n)t.timelineRefs.delete(e);0===t.timelineRefs.size&&(t.disconnect(),Te.delete(i));}}if(n.source=t,t){let i=Te.get(t);if(!i){i={timelineRefs:new Set,sourceMeasurements:Me(t)},Te.set(t,i);const e=new ResizeObserver((e=>{for(const t of e)Ie(n.source);}));e.observe(t);for(const n of t.children)e.observe(n);const r=new MutationObserver((e=>{for(const t of e)Ie(t.target);}));r.observe(t,{attributes:true,attributeFilter:["style","class"]});const o=()=>{i.sourceMeasurements.scrollLeft=t.scrollLeft,i.sourceMeasurements.scrollTop=t.scrollTop;for(const e of i.timelineRefs){const t=e.deref();t&&xe(t);}};we(t).addEventListener("scroll",o),i.disconnect=()=>{e.disconnect(),r.disconnect(),we(t).removeEventListener("scroll",o);};}i.timelineRefs.add(new WeakRef(e));}}}function Ne(e,t){let n=ve.get(e).animations;for(let i=0;i<n.length;i++)n[i].animation==t&&n.splice(i,1);}function Ae(e,t,n){let i=ve.get(e).animations;for(let r=0;r<i.length;r++)if(i[r].animation==t)return;i.push({animation:t,tickAnimation:n}),queueMicrotask((()=>{xe(e);}));}class ScrollTimeline{constructor(e){ve.set(this,{source:null,axis:ge,anonymousSource:e?e.anonymousSource:null,anonymousTarget:e?e.anonymousTarget:null,subject:null,inset:null,animations:[],subjectMeasurements:null});if(Re(this,e&&void 0!==e.source?e.source:document.scrollingElement),e&&void 0!==e.axis&&e.axis!=ge){if(!ke(e.axis))throw TypeError("Invalid axis");ve.get(this).axis=e.axis;}xe(this);}set source(e){Re(this,e),xe(this);}get source(){return ve.get(this).source}set axis(e){if(!ke(e))throw TypeError("Invalid axis");ve.get(this).axis=e,xe(this);}get axis(){return ve.get(this).axis}get duration(){return CSS.percent(100)}get phase(){const e=this.source;if(!e)return "inactive";let t=getComputedStyle(e);return "none"==t.display?"inactive":e==document.scrollingElement||"visible"!=t.overflow&&"clip"!=t.overflow?"active":"inactive"}get currentTime(){const e=null,t=this.source;if(!t||!t.isConnected)return e;if("inactive"==this.phase)return e;const n=getComputedStyle(t);if("inline"===n.display||"none"===n.display)return e;const i=this.axis,r=be(t,i),o=function(e,t){const n=Te.get(e).sourceMeasurements,i="horizontal-tb"==getComputedStyle(e).writingMode;return "block"===t?t=i?"y":"x":"inline"===t&&(t=i?"x":"y"),"y"===t?n.scrollHeight-n.clientHeight:"x"===t?n.scrollWidth-n.clientWidth:void 0}(t,i);return o>0?CSS.percent(100*r/o):CSS.percent(100)}get __polyfill(){return  true}}function Ve(e,t){let n=e.parentElement;for(;null!=n;){if(t(n))return n;n=n.parentElement;}}function _e(e,t){switch(e){case "root":return document.scrollingElement;case "nearest":return We(t);case "self":return t;default:throw new TypeError("Invalid ScrollTimeline Source Type.")}}function Le(e){switch(getComputedStyle(e).display){case "block":case "inline-block":case "list-item":case "table":case "table-caption":case "flow-root":case "flex":case "grid":return  true}return  false}function Oe(e){const t=getComputedStyle(e);return "none"!=t.transform||"none"!=t.perspective||("transform"==t.willChange||"perspective"==t.willChange||("none"!=t.filter||"filter"==t.willChange||"none"!=t.backdropFilter))}function Ue(e){return "static"!=getComputedStyle(e).position||Oe(e)}function je(e){switch(getComputedStyle(e).position){case "static":case "relative":case "sticky":return Ve(e,Le);case "absolute":return Ve(e,Ue);case "fixed":return Ve(e,Oe)}}function We(e){if(e&&e.isConnected){for(;e=je(e);){switch(getComputedStyle(e)["overflow-x"]){case "auto":case "scroll":case "hidden":return e==document.body&&"visible"==getComputedStyle(document.scrollingElement).overflow?document.scrollingElement:e}}return document.scrollingElement}}function Fe(e,t){const n=ve.get(e),i=n.subjectMeasurements,r=Te.get(n.source).sourceMeasurements;return "inactive"===e.phase?null:e instanceof $e?De(t,r,i,n.axis,n.inset):null}function De(e,t,n,i,r){const o="rtl"==t.direction||"vertical-rl"==t.writingMode;let s,a,l={fontSize:n.fontSize};"x"===q(i,t)?(s=n.offsetWidth,a=n.left,l.scrollPadding=[t.scrollPaddingLeft,t.scrollPaddingRight],o&&(a+=t.scrollWidth-t.clientWidth,l.scrollPadding=[t.scrollPaddingRight,t.scrollPaddingLeft]),l.containerSize=t.clientWidth):(s=n.offsetHeight,a=n.top,l.scrollPadding=[t.scrollPaddingTop,t.scrollPaddingBottom],l.containerSize=t.clientHeight);const c=function(e,t){const n={start:0,end:0};if(!e)return n;const[i,r]=[e.start,e.end].map(((e,n)=>"auto"===e?"auto"===t.scrollPadding[n]?0:parseFloat(t.scrollPadding[n]):Ce(e,{percentageReference:CSS.px(t.containerSize),fontSize:CSS.px(parseFloat(t.fontSize))})));return {start:i,end:r}}(r,l),u=a-l.containerSize+c.end,m=a+s-c.start,f=u+s,h=m-s,p=Math.min(f,h),d=Math.max(f,h);let S,g;const v=s>l.containerSize-c.start-c.end;switch(e){case "cover":S=u,g=m;break;case "contain":S=p,g=d;break;case "entry":S=u,g=p;break;case "exit":S=d,g=m;break;case "entry-crossing":S=u,g=v?d:p;break;case "exit-crossing":S=v?p:d,g=m;}return {start:S,end:g}}function ze(e,t){if(e instanceof $e){const{rangeName:n,offset:i}=t;return He(Fe(e,n),i,Fe(e,"cover"),e.subject)}if(e instanceof ScrollTimeline){const{axis:n,source:i}=e,{sourceMeasurements:r}=Te.get(i);let o;o="x"===q(n,r)?r.scrollWidth-r.clientWidth:r.scrollHeight-r.clientHeight;return Ce(t,{percentageReference:CSS.px(o)})/o}unsupportedTimeline(e);}function He(e,t,n,i){if(!e||!n)return 0;let r=getComputedStyle(i);return (Ce(t,{percentageReference:CSS.px(e.end-e.start),fontSize:CSS.px(parseFloat(r.fontSize))})+e.start-n.start)/(n.end-n.start)}let $e=class ViewTimeline extends ScrollTimeline{constructor(e){super(e);const t=ve.get(this);if(t.subject=e&&e.subject?e.subject:void 0,e&&e.inset&&(t.inset=function(e){if(!e)return {start:0,end:0};let t;if(t="string"==typeof e?B(e).map((t=>{if("auto"===t)return "auto";try{return CSSNumericValue.parse(t)}catch(n){throw TypeError(`Could not parse inset "${e}"`)}})):Array.isArray(e)?e:[e],0===t.length||t.length>2)throw TypeError("Invalid inset");for(const n of t){if("auto"===n)continue;const e=n.type();if(1!==e.length&&1!==e.percent)throw TypeError("Invalid inset")}return {start:t[0],end:t[1]??t[0]}}(e.inset)),t.subject){new ResizeObserver((()=>{Ie(t.source);})).observe(t.subject);new MutationObserver((()=>{Ie(t.source);})).observe(t.subject,{attributes:true,attributeFilter:["class","style"]});}Ee(this),t.subjectMeasurements=Pe(t.source,t.subject),xe(this);}get source(){return Ee(this),ve.get(this).source}set source(e){throw new Error("Cannot set the source of a view timeline")}get subject(){return ve.get(this).subject}get axis(){return ve.get(this).axis}get currentTime(){const e=null,t=be(this.source,this.axis);if(t==e)return e;const n=Fe(this,"cover");if(!n)return e;const i=(t-n.start)/(n.end-n.start);return CSS.percent(100*i)}get startOffset(){return CSS.px(Fe(this,"cover").start)}get endOffset(){return CSS.px(Fe(this,"cover").end)}};const qe=document.getAnimations,Be=window.Element.prototype.getAnimations,Ke=window.Element.prototype.animate,Ge=window.Animation;class Qe{constructor(){this.state="pending",this.nativeResolve=this.nativeReject=null,this.promise=new Promise(((e,t)=>{this.nativeResolve=e,this.nativeReject=t;}));}resolve(e){this.state="resolved",this.nativeResolve(e);}reject(e){this.state="rejected",this.promise.catch((()=>{})),this.nativeReject(e);}}function Xe(e){e.readyPromise=new Qe,requestAnimationFrame((()=>{var t;null!==((null==(t=e.timeline)?void 0:t.currentTime)??null)&&(dt(e),"play"!==e.pendingTask||null===e.startTime&&null===e.holdTime?"pause"===e.pendingTask&&tt(e):et(e));}));}function Ye(){return new DOMException("The user aborted a request","AbortError")}function Je(e,t){if(null===t)return t;if("number"!=typeof t)throw new DOMException(`Unexpected value: ${t}.  Cannot convert to CssNumberish`,"InvalidStateError");const n=e.rangeDuration??100,i=at(e),r=i?n*t/i:0;return CSS.percent(r)}function Ze(e,t){if(e.timeline){if(null===t)return t;if("percent"===t.unit){const n=e.rangeDuration??100,i=at(e);return t.value*i/n}throw new DOMException("CSSNumericValue must be a percentage for progress based animations.","NotSupportedError")}{if(null==t||"number"==typeof t)return t;const e=t.to("ms");if(e)return e.value;throw new DOMException("CSSNumericValue must be either a number or a time value for time based animations.","InvalidStateError")}}function et(e){const t=Ze(e,e.timeline.currentTime);if(null!=e.holdTime)rt(e),0==e.animation.playbackRate?e.startTime=t:(e.startTime=t-e.holdTime/e.animation.playbackRate,e.holdTime=null);else if(null!==e.startTime&&null!==e.pendingPlaybackRate){const n=(t-e.startTime)*e.animation.playbackRate;rt(e);const i=e.animation.playbackRate;0==i?(e.holdTime=null,e.startTime=t):e.startTime=t-n/i;}e.readyPromise&&"pending"==e.readyPromise.state&&e.readyPromise.resolve(e.proxy),st(e,false,false),lt(e),e.pendingTask=null;}function tt(e){const t=Ze(e,e.timeline.currentTime);null!=e.startTime&&null==e.holdTime&&(e.holdTime=(t-e.startTime)*e.animation.playbackRate),rt(e),e.startTime=null,e.readyPromise.resolve(e.proxy),st(e,false,false),lt(e),e.pendingTask=null;}function nt(e){if(!e.finishedPromise||"pending"!=e.finishedPromise.state)return;if("finished"!=e.proxy.playState)return;e.finishedPromise.resolve(e.proxy),e.animation.pause();const t=new CustomEvent("finish",{detail:{currentTime:e.proxy.currentTime,timelineTime:e.proxy.timeline.currentTime}});Object.defineProperty(t,"currentTime",{get:function(){return this.detail.currentTime}}),Object.defineProperty(t,"timelineTime",{get:function(){return this.detail.timelineTime}}),requestAnimationFrame((()=>{queueMicrotask((()=>{e.animation.dispatchEvent(t);}));}));}function it(e){return null!==e.pendingPlaybackRate?e.pendingPlaybackRate:e.animation.playbackRate}function rt(e){null!==e.pendingPlaybackRate&&(e.animation.playbackRate=e.pendingPlaybackRate,e.pendingPlaybackRate=null);}function ot(e){if(!e.timeline)return null;const t=Ze(e,e.timeline.currentTime);if(null===t)return null;if(null===e.startTime)return null;let n=(t-e.startTime)*e.animation.playbackRate;return  -0==n&&(n=0),n}function st(e,t,n){if(!e.timeline)return;let i=t?Ze(e,e.proxy.currentTime):ot(e);if(i&&null!=e.startTime&&!e.proxy.pending){const n=it(e),r=at(e);let o=e.previousCurrentTime;n>0&&i>=r&&null!=e.previousCurrentTime?((null===o||o<r)&&(o=r),e.holdTime=t?i:o):n<0&&i<=0?((null==o||o>0)&&(o=0),e.holdTime=t?i:o):0!=n&&(t&&null!==e.holdTime&&(e.startTime=function(e,t){if(!e.timeline)return null;const n=Ze(e,e.timeline.currentTime);return null==n?null:n-t/e.animation.playbackRate}(e,e.holdTime)),e.holdTime=null);}lt(e),e.previousCurrentTime=Ze(e,e.proxy.currentTime);"finished"==e.proxy.playState?(e.finishedPromise||(e.finishedPromise=new Qe),"pending"==e.finishedPromise.state&&(n?nt(e):Promise.resolve().then((()=>{nt(e);})))):(e.finishedPromise&&"resolved"==e.finishedPromise.state&&(e.finishedPromise=new Qe),"paused"!=e.animation.playState&&e.animation.pause());}function at(e){const t=function(e){const t=e.proxy.effect.getTiming();return e.normalizedTiming||t}(e),n=t.delay+t.endDelay+t.iterations*t.duration;return Math.max(0,n)}function lt(e){if(e.timeline)if(null!==e.startTime){const t=e.timeline.currentTime;if(null==t)return;ct(e,(Ze(e,t)-e.startTime)*e.animation.playbackRate);}else null!==e.holdTime&&ct(e,e.holdTime);}function ct(e,t){const n=e.timeline,i=e.animation.playbackRate,r=n.currentTime&&n.currentTime.value==(i<0?0:100)?i<0?.001:-1e-3:0;e.animation.currentTime=t+r;}function ut(e,t){if(!e.timeline)return;const n="paused"==e.proxy.playState&&e.proxy.pending;let i=false,r=Ze(e,e.proxy.currentTime);0==it(e)&&null==r&&(e.holdTime=0),null==r&&(e.autoAlignStartTime=true),("finished"===e.proxy.playState||n)&&(e.holdTime=null,e.startTime=null,e.autoAlignStartTime=true),e.holdTime&&(e.startTime=null),e.pendingTask&&(e.pendingTask=null,i=true),(null!==e.holdTime||e.autoAlignStartTime||n||null!==e.pendingPlaybackRate)&&(e.readyPromise&&!i&&(e.readyPromise=null),lt(e),e.readyPromise||Xe(e),e.pendingTask="play",Ae(e.timeline,e.animation,mt.bind(e.proxy)),st(e,false,false));}function mt(e){const t=ht.get(this);if(!t)return;if(null==e)return void("paused"!==t.proxy.playState&&"idle"!=t.animation.playState&&t.animation.cancel());dt(t),t.pendingTask&&requestAnimationFrame((()=>{"play"!==t.pendingTask||null===t.startTime&&null===t.holdTime?"pause"===t.pendingTask&&tt(t):et(t);}));const n=this.playState;if("running"==n||"finished"==n){const n=Ze(t,e);ct(t,(n-Ze(t,this.startTime))*this.playbackRate),st(t,false,false);}}function ft(e){e.specifiedTiming=null;}let ht=new WeakMap;window.addEventListener("pagehide",(e=>{ht=new WeakMap;}),false);let pt=new WeakMap;function dt(e){if(!e.autoAlignStartTime)return;if(!e.timeline||!e.timeline.currentTime)return;if("idle"===e.proxy.playState||"paused"===e.proxy.playState&&null!==e.holdTime)return;const t=e.rangeDuration;let n,i;try{n=CSS.percent(100*function(e){if(!e.animationRange)return 0;const t="normal"===e.animationRange.start?gt(e.timeline):e.animationRange.start;return ze(e.timeline,t)}(e));}catch(o){n=CSS.percent(0),e.animationRange.start="normal",console.warn("Exception when calculating start offset",o);}try{i=CSS.percent(100*(1-function(e){if(!e.animationRange)return 0;const t="normal"===e.animationRange.end?vt(e.timeline):e.animationRange.end;return 1-ze(e.timeline,t)}(e)));}catch(o){i=CSS.percent(100),e.animationRange.end="normal",console.warn("Exception when calculating end offset",o);}e.rangeDuration=i.value-n.value;const r=it(e);e.startTime=Ze(e,r>=0?n:i),e.holdTime=null,e.rangeDuration!==t&&ft(e);}function St(e){throw new Error("Unsupported timeline class")}function gt(e){return e instanceof ViewTimeline?{rangeName:"cover",offset:CSS.percent(0)}:e instanceof ScrollTimeline?CSS.percent(0):void St()}function vt(e){return e instanceof ViewTimeline?{rangeName:"cover",offset:CSS.percent(100)}:e instanceof ScrollTimeline?CSS.percent(100):void St()}function Tt(e,t){if(!t)return {start:"normal",end:"normal"};const n={start:gt(e),end:vt(e)};if(e instanceof ViewTimeline){const e=B(t),i=[],r=[];if(e.forEach((e=>{if(ye.includes(e))i.push(e);else try{r.push(CSSNumericValue.parse(e));}catch(n){throw TypeError(`Could not parse range "${t}"`)}})),i.length>2||r.length>2||1==r.length)throw TypeError("Invalid time range or unsupported time range format.");return i.length&&(n.start.rangeName=i[0],n.end.rangeName=i.length>1?i[1]:i[0]),r.length>1&&(n.start.offset=r[0],n.end.offset=r[1]),n}if(e instanceof ScrollTimeline){const e=t.split(" ");if(2!=e.length)throw TypeError("Invalid time range or unsupported time range format.");return n.start=CSSNumericValue.parse(e[0]),n.end=CSSNumericValue.parse(e[1]),n}St();}function yt(e,t,n){if(!t||"normal"===t)return "normal";if(e instanceof ViewTimeline){let e="cover",i="start"===n?CSS.percent(0):CSS.percent(100);if(t instanceof Object) void 0!==t.rangeName&&(e=t.rangeName),void 0!==t.offset&&(i=t.offset);else {const n=B(t);1===n.length?ye.includes(n[0])?e=n[0]:i=Q(CSSNumericValue.parse(n[0]),{}):2===n.length&&(e=n[0],i=Q(CSSNumericValue.parse(n[1]),{}));}if(!ye.includes(e))throw TypeError("Invalid range name");return {rangeName:e,offset:i}}if(e instanceof ScrollTimeline)return CSSNumericValue.parse(t);St();}class wt{constructor(e,t,n={}){const i=t instanceof ScrollTimeline,r=e instanceof Ge?e:new Ge(e,i?void 0:t);pt.set(r,this),ht.set(this,{animation:r,timeline:i?t:void 0,playState:i?"idle":null,readyPromise:null,finishedPromise:null,startTime:null,holdTime:null,rangeDuration:null,previousCurrentTime:null,autoAlignStartTime:false,pendingPlaybackRate:null,pendingTask:null,specifiedTiming:null,normalizedTiming:null,effect:null,animationRange:i?Tt(t,n["animation-range"]):null,proxy:this});}get effect(){const e=ht.get(this);return e.timeline?(e.effect||(e.effect=function(e){const t=e.animation.effect,n=t.updateTiming,i={apply:function(n){t.getTiming();const i=n.apply(t);if(e.timeline){const t=e.duration??100;i.localTime=Je(e,i.localTime),i.endTime=Je(e,i.endTime),i.activeDuration=Je(e,i.activeDuration);const n=at(e),r=i.iterations?(n-i.delay-i.endDelay)/i.iterations:0;i.duration=n?CSS.percent(t*r/n):CSS.percent(0),void 0===e.timeline.currentTime&&(i.localTime=null);}return i}},r={apply:function(i,r){if(e.specifiedTiming)return e.specifiedTiming;e.specifiedTiming=i.apply(t);let o,s=Object.assign({},e.specifiedTiming);if(s.duration===1/0)throw TypeError("Effect duration cannot be Infinity when used with Scroll Timelines");return (null===s.duration||"auto"===s.duration||e.autoDurationEffect)&&e.timeline&&(e.autoDurationEffect=true,s.delay=0,s.endDelay=0,o=s.iterations?1e5:0,s.duration=s.iterations?(o-s.delay-s.endDelay)/s.iterations:0,s.duration<0&&(s.duration=0,s.endDelay=o-s.delay),n.apply(t,[s])),e.normalizedTiming=s,e.specifiedTiming}},o={apply:function(n,i,r){if(r&&r.length){if(e.timeline&&r[0]){const t=r[0],n=t.duration;if(n===1/0)throw TypeError("Effect duration cannot be Infinity when used with Scroll Timelines");if(t.iterations===1/0)throw TypeError("Effect iterations cannot be Infinity when used with Scroll Timelines");void 0!==n&&"auto"!==n&&(e.autoDurationEffect=null);}e.specifiedTiming&&n.apply(t,[e.specifiedTiming]),n.apply(t,r),ft(e);}}},s=new Proxy(t,{get:function(e,n){const i=e[n];return "function"==typeof i?i.bind(t):i},set:function(e,t,n){return e[t]=n,true}});return s.getComputedTiming=new Proxy(t.getComputedTiming,i),s.getTiming=new Proxy(t.getTiming,r),s.updateTiming=new Proxy(t.updateTiming,o),s}(e)),e.effect):e.animation.effect}set effect(e){const t=ht.get(this);t.animation.effect=e,t.effect=null,t.autoDurationEffect=null;}get timeline(){const e=ht.get(this);return e.timeline||e.animation.timeline}set timeline(e){const t=ht.get(this),n=this.timeline;if(n==e)return;const i=this.playState,r=this.currentTime;let o,s=at(t);o=null===r?null:0===s?0:Ze(t,r)/s;const a=n instanceof ScrollTimeline,l=e instanceof ScrollTimeline,c=this.pending;if(a&&Ne(t.timeline,t.animation),l)return t.timeline=e,rt(t),t.autoAlignStartTime=true,t.startTime=null,t.holdTime=null,"running"!==i&&"finished"!==i||(t.readyPromise&&"resolved"!==t.readyPromise.state||Xe(t),t.pendingTask="play",Ae(t.timeline,t.animation,mt.bind(this))),"paused"===i&&null!==o&&(t.holdTime=o*s),c&&(t.readyPromise&&"resolved"!=t.readyPromise.state||Xe(t),t.pendingTask="paused"==i?"pause":"play"),null!==t.startTime&&(t.holdTime=null),void st(t,false,false);if(t.animation.timeline!=e)throw TypeError("Unsupported timeline: "+e);if(Ne(t.timeline,t.animation),t.timeline=null,a)switch(null!==r&&(t.animation.currentTime=o*at(t)),i){case "paused":t.animation.pause();break;case "running":case "finished":t.animation.play();}}get startTime(){const e=ht.get(this);return e.timeline?Je(e,e.startTime):e.animation.startTime}set startTime(e){const t=ht.get(this);if(e=Ze(t,e),!t.timeline)return void(t.animation.startTime=e);t.autoAlignStartTime=false;null==Ze(t,t.timeline.currentTime)&&null!=t.startTime&&(t.holdTime=null,lt(t));const n=Ze(t,this.currentTime);rt(t),t.startTime=e,null!==t.startTime&&0!=t.animation.playbackRate?t.holdTime=null:t.holdTime=n,t.pendingTask&&(t.pendingTask=null,t.readyPromise.resolve(this)),st(t,true,false),lt(t);}get currentTime(){const e=ht.get(this);return e.timeline?null!=e.holdTime?Je(e,e.holdTime):Je(e,ot(e)):e.animation.currentTime}set currentTime(e){const t=ht.get(this);t.timeline?(!function(e,t){if(null==t&&null!==e.currentTime)throw new TypeError;t=Ze(e,t),e.autoAlignStartTime=false,null!==e.holdTime||null===e.startTime||"inactive"===e.timeline.phase||0===e.animation.playbackRate?e.holdTime=t:e.startTime=Ze(e,e.timeline.currentTime)-t/e.animation.playbackRate,"inactive"===e.timeline.phase&&(e.startTime=null),e.previousCurrentTime=null;}(t,e),"pause"==t.pendingTask&&(t.holdTime=Ze(t,e),rt(t),t.startTime=null,t.pendingTask=null,t.readyPromise.resolve(this)),st(t,true,false)):t.animation.currentTime=e;}get playbackRate(){return ht.get(this).animation.playbackRate}set playbackRate(e){const t=ht.get(this);if(!t.timeline)return void(t.animation.playbackRate=e);t.pendingPlaybackRate=null;const n=this.currentTime;t.animation.playbackRate=e,null!==n&&(this.currentTime=n);}get playState(){const e=ht.get(this);if(!e.timeline)return e.animation.playState;const t=Ze(e,this.currentTime);if(null===t&&null===e.startTime&&null==e.pendingTask)return "idle";if("pause"==e.pendingTask||null===e.startTime&&"play"!=e.pendingTask)return "paused";if(null!=t){if(e.animation.playbackRate>0&&t>=at(e))return "finished";if(e.animation.playbackRate<0&&t<=0)return "finished"}return "running"}get rangeStart(){var e;return (null==(e=ht.get(this).animationRange)?void 0:e.start)??"normal"}set rangeStart(e){const t=ht.get(this);if(!t.timeline)return t.animation.rangeStart=e;if(t.timeline instanceof ScrollTimeline){t.animationRange.start=yt(t.timeline,e,"start"),dt(t),lt(t);}}get rangeEnd(){var e;return (null==(e=ht.get(this).animationRange)?void 0:e.end)??"normal"}set rangeEnd(e){const t=ht.get(this);if(!t.timeline)return t.animation.rangeEnd=e;if(t.timeline instanceof ScrollTimeline){t.animationRange.end=yt(t.timeline,e,"end"),dt(t),lt(t);}}get replaceState(){return ht.get(this).animation.pending}get pending(){const e=ht.get(this);return e.timeline?!!e.readyPromise&&"pending"==e.readyPromise.state:e.animation.pending}finish(){const e=ht.get(this);if(!e.timeline)return void e.animation.finish();const t=it(e),n=at(e);if(0==t)throw new DOMException("Cannot finish Animation with a playbackRate of 0.","InvalidStateError");if(t>0&&n==1/0)throw new DOMException("Cannot finish Animation with an infinite target effect end.","InvalidStateError");rt(e);const i=t<0?0:n;this.currentTime=Je(e,i);const r=Ze(e,e.timeline.currentTime);null===e.startTime&&null!==r&&(e.startTime=r-i/e.animation.playbackRate),"pause"==e.pendingTask&&null!==e.startTime&&(e.holdTime=null,e.pendingTask=null,e.readyPromise.resolve(this)),"play"==e.pendingTask&&null!==e.startTime&&(e.pendingTask=null,e.readyPromise.resolve(this)),st(e,true,true);}play(){const e=ht.get(this);e.timeline?ut(e):e.animation.play();}pause(){const e=ht.get(this);e.timeline?"paused"!=this.playState&&(null===e.animation.currentTime&&(e.autoAlignStartTime=true),"play"==e.pendingTask?e.pendingTask=null:e.readyPromise=null,e.readyPromise||Xe(e),e.pendingTask="pause",Ae(e.timeline,e.animation,mt.bind(e.proxy))):e.animation.pause();}reverse(){const e=ht.get(this),t=it(e),n=Ze(e,this.currentTime),i=at(e)==1/0,r=0!=t&&(t<0||n>0||!i);if(!e.timeline||!r)return r&&(e.pendingPlaybackRate=-it(e)),void e.animation.reverse();if("inactive"==e.timeline.phase)throw new DOMException("Cannot reverse an animation with no active timeline","InvalidStateError");this.updatePlaybackRate(-t),ut(e);}updatePlaybackRate(e){const t=ht.get(this);if(t.pendingPlaybackRate=e,!t.timeline)return void t.animation.updatePlaybackRate(e);const n=this.playState;if(!t.readyPromise||"pending"!=t.readyPromise.state)switch(n){case "idle":case "paused":rt(t);break;case "finished":const n=Ze(t,t.timeline.currentTime),i=null!==n?(n-t.startTime)*t.animation.playbackRate:null;t.startTime=0==e?n:null!=n&&null!=i?(n-i)/e:null,rt(t),st(t,false,false),lt(t);break;default:ut(t);}}persist(){ht.get(this).animation.persist();}get id(){return ht.get(this).animation.id}set id(e){ht.get(this).animation.id=e;}cancel(){const e=ht.get(this);e.timeline?("idle"!=this.playState&&(!function(e){e.pendingTask&&(e.pendingTask=null,rt(e),e.readyPromise.reject(Ye()),Xe(e),e.readyPromise.resolve(e.proxy));}(e),e.finishedPromise&&"pending"==e.finishedPromise.state&&e.finishedPromise.reject(Ye()),e.finishedPromise=new Qe,e.animation.cancel()),e.startTime=null,e.holdTime=null,Ne(e.timeline,e.animation)):e.animation.cancel();}get onfinish(){return ht.get(this).animation.onfinish}set onfinish(e){ht.get(this).animation.onfinish=e;}get oncancel(){return ht.get(this).animation.oncancel}set oncancel(e){ht.get(this).animation.oncancel=e;}get onremove(){return ht.get(this).animation.onremove}set onremove(e){ht.get(this).animation.onremove=e;}get finished(){const e=ht.get(this);return e.timeline?(e.finishedPromise||(e.finishedPromise=new Qe),e.finishedPromise.promise):e.animation.finished}get ready(){const e=ht.get(this);return e.timeline?(e.readyPromise||(e.readyPromise=new Qe,e.readyPromise.resolve(this)),e.readyPromise.promise):e.animation.ready}addEventListener(e,t,n){ht.get(this).animation.addEventListener(e,t,n);}removeEventListener(e,t,n){ht.get(this).animation.removeEventListener(e,t,n);}dispatchEvent(e){ht.get(this).animation.dispatchEvent(e);}}function xt(e,t){const n=t.timeline;n instanceof ScrollTimeline&&delete t.timeline;const i=Ke.apply(this,[e,t]),r=new wt(i,n);if(n instanceof ScrollTimeline){i.pause();ht.get(r).animationRange={start:yt(n,t.rangeStart,"start"),end:yt(n,t.rangeEnd,"end")},r.play();}return r}function bt(e){for(let t=0;t<e.length;++t){let n=pt.get(e[t]);n&&(e[t]=n);}return e}function Ct(e){return bt(Be.apply(this,[e]))}function Et(e){return bt(qe.apply(this,[e]))}const kt={IDENTIFIER:/[\w\\\@_-]+/g,WHITE_SPACE:/\s*/g,TIME:/^[0-9]+(s|ms)/,SCROLL_TIMELINE:/scroll-timeline\s*:([^;}]+)/,SCROLL_TIMELINE_NAME:/scroll-timeline-name\s*:([^;}]+)/,SCROLL_TIMELINE_AXIS:/scroll-timeline-axis\s*:([^;}]+)/,VIEW_TIMELINE:/view-timeline\s*:([^;}]+)/,VIEW_TIMELINE_NAME:/view-timeline-name\s*:([^;}]+)/,VIEW_TIMELINE_AXIS:/view-timeline-axis\s*:([^;}]+)/,VIEW_TIMELINE_INSET:/view-timeline-inset\s*:([^;}]+)/,ANIMATION_TIMELINE:/animation-timeline\s*:([^;}]+)/,ANIMATION_TIME_RANGE:/animation-range\s*:([^;}]+)/,ANIMATION_NAME:/animation-name\s*:([^;}]+)/,ANIMATION:/animation\s*:([^;}]+)/,ANONYMOUS_SCROLL_TIMELINE:/scroll\(([^)]*)\)/,ANONYMOUS_VIEW_TIMELINE:/view\(([^)]*)\)/},Mt=["block","inline","x","y"],Pt=["nearest","root","self"];const It=new class{constructor(){this.cssRulesWithTimelineName=[],this.nextAnonymousTimelineNameIndex=0,this.anonymousScrollTimelineOptions=new Map,this.anonymousViewTimelineOptions=new Map,this.sourceSelectorToScrollTimeline=[],this.subjectSelectorToViewTimeline=[],this.keyframeNamesSelectors=new Map;}transpileStyleSheet(e,t,n){const i={sheetSrc:e,index:0,name:n};for(;i.index<i.sheetSrc.length&&(this.eatWhitespace(i),!(i.index>=i.sheetSrc.length));){if(this.lookAhead("/*",i)){for(;this.lookAhead("/*",i);)this.eatComment(i),this.eatWhitespace(i);continue}const e=this.parseQualifiedRule(i);e&&(t?this.parseKeyframesAndSaveNameMapping(e,i):this.handleScrollTimelineProps(e,i));}return i.sheetSrc}getAnimationTimelineOptions(e,t){for(let n=this.cssRulesWithTimelineName.length-1;n>=0;n--){const i=this.cssRulesWithTimelineName[n];try{if(t.matches(i.selector)&&(!i["animation-name"]||i["animation-name"]==e))return {"animation-timeline":i["animation-timeline"],"animation-range":i["animation-range"]}}catch{}}return null}getAnonymousScrollTimelineOptions(e,t){const n=this.anonymousScrollTimelineOptions.get(e);return n?{anonymousSource:n.source,anonymousTarget:t,source:_e(n.source??"nearest",t),axis:n.axis?n.axis:"block"}:null}getScrollTimelineOptions(e,t){const n=this.getAnonymousScrollTimelineOptions(e,t);if(n)return n;for(let i=this.sourceSelectorToScrollTimeline.length-1;i>=0;i--){const n=this.sourceSelectorToScrollTimeline[i];if(n.name==e){const e=this.findPreviousSiblingOrAncestorMatchingSelector(t,n.selector);if(e)return {source:e,...n.axis?{axis:n.axis}:{}}}}return null}findPreviousSiblingOrAncestorMatchingSelector(e,t){let n=e;for(;n;){if(n.matches(t))return n;n=n.previousElementSibling||n.parentElement;}return null}getAnonymousViewTimelineOptions(e,t){const n=this.anonymousViewTimelineOptions.get(e);return n?{subject:t,axis:n.axis?n.axis:"block",inset:n.inset?n.inset:"auto"}:null}getViewTimelineOptions(e,t){const n=this.getAnonymousViewTimelineOptions(e,t);if(n)return n;for(let i=this.subjectSelectorToViewTimeline.length-1;i>=0;i--){const n=this.subjectSelectorToViewTimeline[i];if(n.name==e){const e=this.findPreviousSiblingOrAncestorMatchingSelector(t,n.selector);if(e)return {subject:e,axis:n.axis,inset:n.inset}}}return null}handleScrollTimelineProps(e,t){if(e.selector.includes("@keyframes"))return;const n=e.block.contents.includes("animation-name:"),i=e.block.contents.includes("animation-timeline:"),r=e.block.contents.includes("animation:");if(this.saveSourceSelectorToScrollTimeline(e),this.saveSubjectSelectorToViewTimeline(e),!i&&!n&&!r)return;let o=[],s=[],a=false;i&&(o=this.extractScrollTimelineNames(e.block.contents)),n&&(s=this.extractMatches(e.block.contents,kt.ANIMATION_NAME)),i&&n||(r&&this.extractMatches(e.block.contents,kt.ANIMATION).forEach((t=>{const n=this.extractAnimationName(t);n&&i&&s.push(n),i&&(this.hasDuration(t)||(this.hasAutoDuration(t)&&(e.block.contents=e.block.contents.replace("auto","    ")),e.block.contents=e.block.contents.replace(t," 1s "+t),a=true));})),a&&this.replacePart(e.block.startIndex,e.block.endIndex,e.block.contents,t)),this.saveRelationInList(e,o,s);}saveSourceSelectorToScrollTimeline(e){const t=e.block.contents.includes("scroll-timeline:"),n=e.block.contents.includes("scroll-timeline-name:"),i=e.block.contents.includes("scroll-timeline-axis:");if(!t&&!n)return;let r=[];if(t){const t=this.extractMatches(e.block.contents,kt.SCROLL_TIMELINE);for(const n of t){const t=this.split(n);let i={selector:e.selector,name:""};1==t.length?i.name=t[0]:2==t.length&&(Mt.includes(t[0])?(i.axis=t[0],i.name=t[1]):(i.axis=t[1],i.name=t[0])),r.push(i);}}if(n){const t=this.extractMatches(e.block.contents,kt.SCROLL_TIMELINE_NAME);for(let n=0;n<t.length;n++)if(n<r.length)r[n].name=t[n];else {let i={selector:e.selector,name:t[n]};r.push(i);}}let o=[];if(i){const t=this.extractMatches(e.block.contents,kt.SCROLL_TIMELINE_AXIS);if(o=t.filter((e=>Mt.includes(e))),o.length!=t.length)throw new Error("Invalid axis")}for(let s=0;s<r.length;s++)o.length&&(r[s].axis=o[s%r.length]);this.sourceSelectorToScrollTimeline.push(...r);}saveSubjectSelectorToViewTimeline(e){const t=e.block.contents.includes("view-timeline:"),n=e.block.contents.includes("view-timeline-name:"),i=e.block.contents.includes("view-timeline-axis:"),r=e.block.contents.includes("view-timeline-inset:");if(!t&&!n)return;let o=[];if(t){const t=this.extractMatches(e.block.contents,kt.VIEW_TIMELINE);for(let n of t){const t=this.split(n);let i={selector:e.selector,name:"",inset:null};1==t.length?i.name=t[0]:2==t.length&&(Mt.includes(t[0])?(i.axis=t[0],i.name=t[1]):(i.axis=t[1],i.name=t[0])),o.push(i);}}if(n){const t=this.extractMatches(e.block.contents,kt.VIEW_TIMELINE_NAME);for(let n=0;n<t.length;n++)if(n<o.length)o[n].name=t[n];else {let i={selector:e.selector,name:t[n],inset:null};o.push(i);}}let s=[],a=[];if(r&&(s=this.extractMatches(e.block.contents,kt.VIEW_TIMELINE_INSET)),i){const t=this.extractMatches(e.block.contents,kt.VIEW_TIMELINE_AXIS);if(a=t.filter((e=>Mt.includes(e))),a.length!=t.length)throw new Error("Invalid axis")}for(let l=0;l<o.length;l++)s.length&&(o[l].inset=s[l%o.length]),a.length&&(o[l].axis=a[l%o.length]);this.subjectSelectorToViewTimeline.push(...o);}hasDuration(e){return e.split(" ").filter((e=>{return t=e,kt.TIME.exec(t);var t;})).length>=1}hasAutoDuration(e){return e.split(" ").filter((e=>"auto"===e)).length>=1}saveRelationInList(e,t,n){let i=[];e.block.contents.includes("animation-range:")&&(i=this.extractMatches(e.block.contents,kt.ANIMATION_TIME_RANGE));const r=Math.max(t.length,n.length,i.length);for(let o=0;o<r;o++)this.cssRulesWithTimelineName.push({selector:e.selector,"animation-timeline":t[o%t.length],...n.length?{"animation-name":n[o%n.length]}:{},...i.length?{"animation-range":i[o%i.length]}:{}});}extractScrollTimelineNames(e){const t=kt.ANIMATION_TIMELINE.exec(e)[1].trim(),n=[];return t.split(",").map((e=>e.trim())).forEach((e=>{if(function(e){return (e.startsWith("scroll")||e.startsWith("view"))&&e.includes("(")}(e)){const t=this.saveAnonymousTimelineName(e);n.push(t);}else n.push(e);})),n}saveAnonymousTimelineName(e){const t=":t"+this.nextAnonymousTimelineNameIndex++;return e.startsWith("scroll(")?this.anonymousScrollTimelineOptions.set(t,this.parseAnonymousScrollTimeline(e)):this.anonymousViewTimelineOptions.set(t,this.parseAnonymousViewTimeline(e)),t}parseAnonymousScrollTimeline(e){const t=kt.ANONYMOUS_SCROLL_TIMELINE.exec(e);if(!t)return null;const n=t[1],i={};return n.split(" ").forEach((e=>{Mt.includes(e)?i.axis=e:Pt.includes(e)&&(i.source=e);})),i}parseAnonymousViewTimeline(e){const t=kt.ANONYMOUS_VIEW_TIMELINE.exec(e);if(!t)return null;const n=t[1],i={};return n.split(" ").forEach((e=>{Mt.includes(e)?i.axis=e:i.inset=i.inset?`${i.inset} ${e}`:e;})),i}extractAnimationName(e){return this.findMatchingEntryInContainer(e,this.keyframeNamesSelectors)}findMatchingEntryInContainer(e,t){const n=e.split(" ").filter((e=>t.has(e)));return n?n[0]:null}parseIdentifier(e){kt.IDENTIFIER.lastIndex=e.index;const t=kt.IDENTIFIER.exec(e.sheetSrc);if(!t)throw this.parseError(e,"Expected an identifier");return e.index+=t[0].length,t[0]}parseKeyframesAndSaveNameMapping(e,t){if(e.selector.startsWith("@keyframes")){const n=this.replaceKeyframesAndGetMapping(e,t);e.selector.split(" ").forEach(((e,t)=>{t>0&&this.keyframeNamesSelectors.set(e,n);}));}}replaceKeyframesAndGetMapping(e,t){function n(e){return ye.some((t=>e.startsWith(t)))}const i=e.block.contents,r=function(e){let t=0,n=-1,i=-1;const r=[];for(let o=0;o<e.length;o++)"{"==e[o]?t++:"}"==e[o]&&t--,1==t&&"{"!=e[o]&&"}"!=e[o]&&-1==n&&(n=o),2==t&&"{"==e[o]&&(i=o,r.push({start:n,end:i}),n=i=-1);return r}(i);if(0==r.length)return new Map;const o=new Map;let s=false;const a=[];a.push(i.substring(0,r[0].start));for(let l=0;l<r.length;l++){const e=i.substring(r[l].start,r[l].end);let t=[];e.split(",").forEach((e=>{const i=e.split(" ").map((e=>e.trim())).filter((e=>""!=e)).join(" ");const r=o.size;o.set(r,i),t.push(`${r}%`),n(i)&&(s=true);})),a.push(t.join(",")),l==r.length-1?a.push(i.substring(r[l].end)):a.push(i.substring(r[l].end,r[l+1].start));}return s?(e.block.contents=a.join(""),this.replacePart(e.block.startIndex,e.block.endIndex,e.block.contents,t),o):new Map}parseQualifiedRule(e){const t=e.index,n=this.parseSelector(e).trim();if(!n)return;return {selector:n,block:this.eatBlock(e),startIndex:t,endIndex:e.index}}removeEnclosingDoubleQuotes(e){let t='"'==e[0]?1:0,n='"'==e[e.length-1]?e.length-1:e.length;return e.substring(t,n)}assertString(e,t){if(e.sheetSrc.substr(e.index,t.length)!=t)throw this.parseError(e,`Did not find expected sequence ${t}`);e.index+=t.length;}replacePart(e,t,n,i){if(i.sheetSrc=i.sheetSrc.slice(0,e)+n+i.sheetSrc.slice(t),i.index>=t){const r=i.index-t;i.index=e+n.length+r;}}eatComment(e){this.assertString(e,"/*"),this.eatUntil("*/",e,true),this.assertString(e,"*/");}eatBlock(e){const t=e.index;this.assertString(e,"{");let n=1;for(;0!=n;)this.lookAhead("/*",e)?this.eatComment(e):("{"===e.sheetSrc[e.index]?n++:"}"===e.sheetSrc[e.index]&&n--,this.advance(e));const i=e.index;return {startIndex:t,endIndex:i,contents:e.sheetSrc.slice(t,i)}}advance(e){if(e.index++,e.index>e.sheetSrc.length)throw this.parseError(e,"Advanced beyond the end")}parseError(e,t){return Error(`(${e.name?e.name:"<anonymous file>"}): ${t}`)}eatUntil(e,t,n=false){const i=t.index;for(;!this.lookAhead(e,t);)this.advance(t);return n&&(t.sheetSrc=t.sheetSrc.slice(0,i)+" ".repeat(t.index-i)+t.sheetSrc.slice(t.index)),t.sheetSrc.slice(i,t.index)}parseSelector(e){let t=e.index;if(this.eatUntil("{",e),t===e.index)throw Error("Empty selector");return e.sheetSrc.slice(t,e.index)}eatWhitespace(e){kt.WHITE_SPACE.lastIndex=e.index;const t=kt.WHITE_SPACE.exec(e.sheetSrc);t&&(e.index+=t[0].length);}lookAhead(e,t){return t.sheetSrc.substr(t.index,e.length)==e}peek(e){return e.sheetSrc[e.index]}extractMatches(e,t,n=","){return t.exec(e)[1].trim().split(n).map((e=>e.trim()))}split(e){return e.split(" ").map((e=>e.trim())).filter((e=>""!=e))}};function Rt(e,t,n,i,r,o){const s=Me(t),a=Pe(t,n);return He(De(e,s,a,i,r),o,De("cover",s,a,i,r),n)}function Nt(e,t,n){const i=It.getAnimationTimelineOptions(t,n);if(!i)return null;const r=i["animation-timeline"];if(!r)return null;let o=It.getScrollTimelineOptions(r,n)||It.getViewTimelineOptions(r,n);return o?(o.subject&&function(e,t){const n=We(t.subject),i=t.axis||t.axis;function r(e,r){let o=null;for(const[s,a]of e)if(s==100*r.offset){if("from"==a)o=0;else if("to"==a)o=100;else {const e=a.split(" ");o=1==e.length?parseFloat(e[0]):100*Rt(e[0],n,t.subject,i,t.inset,CSS.percent(parseFloat(e[1])));}break}return o}const o=It.keyframeNamesSelectors.get(e.animationName);if(o&&o.size){const t=[];e.effect.getKeyframes().forEach((e=>{const n=r(o,e);null!==n&&n>=0&&n<=100&&(e.offset=n/100,t.push(e));}));const n=t.sort(((e,t)=>e.offset<t.offset?-1:e.affset>t.offset?1:0));e.effect.setKeyframes(n);}}(e,o),{timeline:o.source?new ScrollTimeline(o):new $e(o),animOptions:i}):null}function At(){if(CSS.supports("animation-timeline: --works"))return  true;!function(){function e(e){if(0===e.innerHTML.trim().length||"aphrodite"in e.dataset)return;let t=It.transpileStyleSheet(e.innerHTML,true);t=It.transpileStyleSheet(t,false),e.innerHTML=t;}function t(e){"text/css"!=e.type&&"stylesheet"!=e.rel||!e.href||new URL(e.href,document.baseURI).origin==location.origin&&fetch(e.getAttribute("href")).then((async t=>{const n=await t.text();let i=It.transpileStyleSheet(n,true);if(i=It.transpileStyleSheet(n,false),i!=n){const t=new Blob([i],{type:"text/css"}),n=URL.createObjectURL(t);e.setAttribute("href",n);}}));}new MutationObserver((n=>{for(const i of n)for(const n of i.addedNodes)n instanceof HTMLStyleElement&&e(n),n instanceof HTMLLinkElement&&t(n);})).observe(document.documentElement,{childList:true,subtree:true}),document.querySelectorAll("style").forEach((t=>e(t))),document.querySelectorAll("link").forEach((e=>t(e)));}();const e=CSS.supports;CSS.supports=t=>(t=t.replaceAll(/(animation-timeline|scroll-timeline(-(name|axis))?|view-timeline(-(name|axis|inset))?|timeline-scope)\s*:/g,"--supported-property:"),e(t)),window.addEventListener("animationstart",(e=>{e.target.getAnimations().filter((t=>t.animationName===e.animationName)).forEach((t=>{const n=Nt(t,t.animationName,e.target);if(n)if(!n.timeline||t instanceof wt)t.timeline=n.timeline;else {const e=new wt(t,n.timeline,n.animOptions);t.pause(),e.play();}}));}));}!function(){if(!At()){if(!Reflect.defineProperty(window,"ScrollTimeline",{value:ScrollTimeline}))throw Error("Error installing ScrollTimeline polyfill: could not attach ScrollTimeline to window");if(!Reflect.defineProperty(window,"ViewTimeline",{value:$e}))throw Error("Error installing ViewTimeline polyfill: could not attach ViewTimeline to window");if(!Reflect.defineProperty(Element.prototype,"animate",{value:xt}))throw Error("Error installing ScrollTimeline polyfill: could not attach WAAPI's animate to DOM Element");if(!Reflect.defineProperty(window,"Animation",{value:wt}))throw Error("Error installing Animation constructor.");if(!Reflect.defineProperty(Element.prototype,"getAnimations",{value:Ct}))throw Error("Error installing ScrollTimeline polyfill: could not attach WAAPI's getAnimations to DOM Element");if(!Reflect.defineProperty(document,"getAnimations",{value:Et}))throw Error("Error installing ScrollTimeline polyfill: could not attach WAAPI's getAnimations to document")}}();}();

    var scrollTimeline = /*#__PURE__*/Object.freeze({
        __proto__: null
    });

    exports.default = index;
    exports.dispose = dispose;
    exports.init = init;
    exports.onError = onError;
    exports.setPropertyUpdateThrottle = setPropertyUpdateThrottle;
    exports.setReducedMotion = setReducedMotion;
    exports.useConsoleReporter = useConsoleReporter;

    Object.defineProperty(exports, '__esModule', { value: true });

    return exports;

})({});
//# sourceMappingURL=elm-motion.js.map
