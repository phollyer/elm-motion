---
name: bug-fix
description: "Use when the user asks to fix a bug end-to-end with a gated workflow: tests first, stop for review, then implement after explicit approval. Works well for staged fixes and one-engine-at-a-time rollouts."
argument-hint: "Describe the bug, target area, expected behavior, and test scope"
user-invocable: true
---

# Bug Fix

Use this skill for engine-by-engine bug fixes with an explicit review checkpoint between failing-test creation and implementation for each engine.

## Trigger Phrases

- fix this bug
- bug fix with tests first
- tests first then implement
- stop after tests and let me review
- staged bug fix

## Contract

When this skill is used, follow this exact sequence:

1. Resolve engine targeting rules first.
2. For the current engine, write failing tests first.
3. Stop and wait for explicit user approval.
4. For the same engine, implement the fix and verify tests.
5. Stop and ask whether to continue to the next engine.
6. Repeat steps 2-5 for each next engine in the confirmed order.

Never start implementation for any engine without approval on that engine's failing tests.

## Engine Targeting Rules

Apply these defaults when the user does not explicitly name an engine.

### Animation Bug Order

1. Transition Engine
2. Keyframe Engine
3. Sub Engine
4. WAAPI Engine
5. ScrollTimeline Engine
6. ViewTimeline Engine

### Scroll Bug Order

1. Cmd Engine
2. Task Engine
3. Sub Engine

### Required Confirmation

If the user does not explicitly specify an engine to target, ask for confirmation before writing tests, the fix phase should follow the confirmed engine order.

Use one concise question that confirms:

1. Bug category (animation or scroll).
2. The default engine order above.
3. The first engine to start with.

Do not proceed until the user confirms.

## Phase A - Tests First

This phase follows the same protocol as bug-fix-tests.

1. Confirm engine target or default engine order when missing.
2. Confirm the current engine being processed.
3. Clarify test scope only.
4. Add or update tests before any production code edits.
5. Run the smallest relevant test command.
6. Report test outcomes and what they prove for the current engine.
7. Stop and ask for approval to continue with implementation for the current engine.

### Phase A Guardrails

- Edit test files only.
- If tests fail due to test syntax mistakes, fix test syntax only.
- Do not change production source files.
- Tests must fail for the intended bug behavior on the current engine before moving to Phase B.

## Approval Gate

Proceed only if the user explicitly confirms the tests are appropriate for the current engine.

Accepted confirmations include phrases like:

- looks good, proceed
- approved, implement
- continue to fix

If approval is ambiguous, ask one concise clarification question and wait.

## Phase B - Implement Fix

1. Confirm the current engine being implemented.
2. Implement the smallest production code change needed to satisfy approved tests for that engine.
3. Re-run focused tests for that engine.
4. Run broader tests when requested or when risk is high.
5. Report exactly what changed and why.
6. Ask for confirmation before moving to the next engine in order.

### Phase B Guardrails

- Preserve existing behavior outside the bug scope.
- Keep API and formatting changes minimal unless required by the fix.
- If unexpected unrelated changes are detected, pause and ask the user how to proceed.
- Do not skip ahead to the next engine without user confirmation.

## Engine Loop Summary

For each engine, the required loop is:

1. Write failing tests (specified engine).
2. Wait for confirmation.
3. Fix failing tests (same specified engine).
4. Repeat for the next engine.

Do not collapse multiple engines into one combined test phase or one combined implementation phase unless the user explicitly requests that workflow.

## Completion Checklist

1. Each engine in scope has completed the full loop in order.
2. Approved tests from each engine phase are green after implementation.
3. No new relevant regressions in touched areas.
4. User receives a concise summary of:
   - files changed
   - behavior fixed
   - test evidence by engine

## Elm-Motion Defaults

- Prefer focused runs before full suite.
- For cross-engine work, complete one engine at a time in the confirmed order.
- After each engine implementation phase, ask for confirmation before starting the next engine.
- After production edits, run required post-edit analysis steps.
