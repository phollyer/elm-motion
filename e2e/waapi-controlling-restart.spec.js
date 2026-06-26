import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { expect, test } from '@playwright/test';

const thisFile = fileURLToPath(import.meta.url);
const thisDir = path.dirname(thisFile);
const repoRoot = path.resolve(thisDir, '..');
const examplePath = path.join(
    repoRoot,
    'docs/examples/src/Animation/WAAPI/ControllingAnimations/index.html'
);
const exampleUrl = `file://${examplePath}`;

function translateYFromMatrix(transform) {
    if (!transform || transform === 'none') {
        return 0;
    }

    const values = transform
        .replace('matrix(', '')
        .replace(')', '')
        .split(',')
        .map(value => Number(value.trim()));

    // CSS 2D matrix(a, b, c, d, tx, ty)
    return values.length >= 6 ? values[5] : 0;
}

test('restart works on first click after completion', async ({ page }) => {
    await page.goto(exampleUrl);

    const animate = page.getByRole('button', { name: /animate/i });
    const restart = page.getByRole('button', { name: /restart/i });
    const target = page.locator('[data-anim-target="bouncingBall"]');

    const sampleY = async () => {
        const transform = await target.evaluate((element) => getComputedStyle(element).transform);
        return translateYFromMatrix(transform);
    };

    await animate.click();
    await page.waitForTimeout(1500);

    const settledY = await sampleY();
    expect(settledY).toBeGreaterThan(300);

    await restart.click();
    await page.waitForTimeout(140);

    const restartedY = await sampleY();

    // First restart after completion must move away from settled end position.
    expect(restartedY).toBeLessThan(settledY - 10);
});

test('reset works after completion', async ({ page }) => {
    await page.goto(exampleUrl);

    const animate = page.getByRole('button', { name: /animate/i });
    const reset = page.getByRole('button', { name: /reset/i });
    const target = page.locator('[data-anim-target="bouncingBall"]');

    const sampleY = async () => {
        const transform = await target.evaluate((element) => getComputedStyle(element).transform);
        return translateYFromMatrix(transform);
    };

    await animate.click();
    await page.waitForTimeout(1500);

    const settledY = await sampleY();
    expect(settledY).toBeGreaterThan(300);

    await reset.click();
    await page.waitForTimeout(140);

    const resetY = await sampleY();
    expect(resetY).toBeLessThan(10);
});
