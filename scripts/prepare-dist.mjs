/* eslint-env node */
/**
 * Prepare dist/ for npm publishing.
 *
 * Builds a self-contained, publishable package directory at dist/:
 *   - dist/package.json            (paths flattened, dev-only fields stripped)
 *   - dist/LICENSE                 (copied from root)
 *   - dist/README.md              (copied from README.npm.md - the npm-facing README)
 *   - dist/THIRD-PARTY-LICENSES.md (attribution for code bundled into the artifact)
 *
 * Rollup output (elm-motion.js, elm-motion.mjs) and sync-types.mjs output
 * (elm-motion.d.ts) already live in dist/.
 *
 * Publish with:  npm run publish:dist
 */

import { copyFile, readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, '..');
const dist = resolve(root, 'dist');

await mkdir(dist, { recursive: true });

// Third-party code inlined into the published bundle (rollup
// `inlineDynamicImports: true`). Each entry's upstream LICENSE is embedded in
// dist/THIRD-PARTY-LICENSES.md so the artifact carries the required notices.
const BUNDLED_DEPENDENCIES = ['scroll-timeline-polyfill'];

// --- package.json -----------------------------------------------------------
const pkg = JSON.parse(await readFile(resolve(root, 'package.json'), 'utf8'));

const distPkg = {
    name: pkg.name,
    version: pkg.version,
    description: pkg.description,
    type: pkg.type,
    scripts: {
        prepublishOnly: "node -e \"if (process.env.ELM_MOTION_APPROVED_PUBLISH !== '1') { console.error('Use npm run publish:dist from the repository root. Direct npm publish dist/ is blocked.'); process.exit(1); }\""
    },
    publishConfig: {
        access: 'public'
    },
    main: 'elm-motion.mjs',
    module: 'elm-motion.mjs',
    types: 'elm-motion.d.ts',
    exports: {
        '.': {
            types: './elm-motion.d.ts',
            import: './elm-motion.mjs'
        }
    },
    keywords: pkg.keywords,
    author: pkg.author,
    license: pkg.license,
    engines: pkg.engines,
    repository: pkg.repository,
    homepage: pkg.homepage,
    bugs: pkg.bugs,
    dependencies: pkg.dependencies,
    peerDependencies: pkg.peerDependencies
};

// Drop empty/undefined fields
for (const [k, v] of Object.entries(distPkg)) {
    if (v === undefined) delete distPkg[k];
    else if (typeof v === 'object' && !Array.isArray(v) && Object.keys(v).length === 0) delete distPkg[k];
}

await writeFile(
    resolve(dist, 'package.json'),
    JSON.stringify(distPkg, null, 2) + '\n'
);

// --- LICENSE & README -------------------------------------------------------
await copyFile(resolve(root, 'LICENSE'), resolve(dist, 'LICENSE'));
await copyFile(resolve(root, 'README.npm.md'), resolve(dist, 'README.md'));

// --- THIRD-PARTY-LICENSES ---------------------------------------------------
// The published bundle inlines third-party code; their licenses (e.g.
// Apache-2.0) require the notice to travel with the redistributed artifact.
const nodeModules = resolve(root, 'node_modules');
const sections = [];

for (const dep of BUNDLED_DEPENDENCIES) {
    const depDir = resolve(nodeModules, dep);
    const depPkg = JSON.parse(await readFile(resolve(depDir, 'package.json'), 'utf8'));

    let licenseText;
    try {
        licenseText = await readFile(resolve(depDir, 'LICENSE'), 'utf8');
    } catch {
        throw new Error(
            `Bundled dependency "${dep}" has no LICENSE file at ${depDir}; ` +
            'cannot generate THIRD-PARTY-LICENSES.md. Aborting to avoid shipping ' +
            'unattributed third-party code.'
        );
    }

    const homepage = depPkg.homepage || (depPkg.repository && depPkg.repository.url) || '';
    sections.push(
        `## ${depPkg.name}@${depPkg.version}\n\n` +
        `- License: ${depPkg.license || 'see below'}\n` +
        (homepage ? `- Homepage: ${homepage}\n` : '') +
        '\nThis code is bundled into the published `elm-motion` artifact.\n\n' +
        '```\n' + licenseText.trimEnd() + '\n```'
    );
}

const thirdParty =
    '# Third-Party Licenses\n\n' +
    'The published `@phollyer/elm-motion` bundle includes code from the ' +
    'following third-party packages. Their licenses are reproduced below.\n\n' +
    sections.join('\n\n---\n\n') + '\n';

await writeFile(resolve(dist, 'THIRD-PARTY-LICENSES.md'), thirdParty);

globalThis.console.log(
    'Prepared dist/ for publishing (package.json, LICENSE, README.md, THIRD-PARTY-LICENSES.md)'
);
