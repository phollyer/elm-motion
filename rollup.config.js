import resolve from '@rollup/plugin-node-resolve';

export default {
    input: 'js/src/index.js',
    plugins: [resolve()],
    // Inline the dynamically-imported scroll-timeline polyfill into the bundle
    // rather than emitting a separate chunk. This keeps the published artifact
    // self-contained (no runtime CDN fetch, no extra files to host) and works
    // for both ESM and IIFE outputs. Note: because the dynamic import is
    // inlined, the polyfill's self-executing IIFE runs once at module
    // evaluation (bundle load) - it feature-detects ScrollTimeline /
    // ViewTimeline and installs them on `window` only when native support is
    // missing. So WAAPI-only consumers pay a one-time feature-detect at load;
    // nothing is installed when the browser already supports the timeline APIs.
    output: [
        {
            file: 'dist/elm-motion.mjs',
            format: 'es',
            exports: 'named',
            inlineDynamicImports: true,
            sourcemap: true
        },
        {
            file: 'dist/elm-motion.js',
            format: 'iife',
            name: 'ElmMotion',
            exports: 'named',
            inlineDynamicImports: true,
            sourcemap: true
        }
    ]
};
