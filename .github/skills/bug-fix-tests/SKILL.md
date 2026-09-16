---
name: bug-fix-tests
description: "Use when the user asks to change a feature, fix bugs, tests first, stop for review, or staged implementation (for example: 'tests first then stop', 'let me review before fixes'). Enforces a strict red-green workflow with an explicit pause after test creation for bug fixes."
argument-hint: "Describe target area, expected behavior, and whether to run focused or full tests"
user-invocable: true
---

# Bug Fix Tests

Use this skill for change requests that must be done in phases.

## Trigger Phrases

- tests first
- stop after tests
- let me review before implementation
- staged rollout
- one engine at a time

## Contract

When this skill is used, follow these rules in order:

1. Resolve engine targeting rules first.
2. Clarify test scope only.
3. Add or update tests before any production code edits.
4. Run the smallest relevant test command.
5. Report test outcomes and what they prove.
6. Stop and wait for explicit user approval before implementation.

Do not implement fixes before approval.

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

If the user does not explicitly specify an engine to target, ask for confirmation before any edits.

Use one concise question that confirms:

1. Bug category (animation or scroll).
2. The default engine order above.
3. The first engine to start with.

Do not proceed until the user confirms.

## Procedure

1. Scope capture:
   - Confirm engine target or default engine order when missing.
   - Identify exact module or engine under test.
   - Identify expected behavior and edge cases.

2. Tests-only phase:
   - Edit test files only.
   - Prefer black-box tests for public behavior.
   - Add internal tests only when needed for precise coverage.

3. Validation:
   - Run focused tests first.
   - If requested, run broader suite.
   - If test file has syntax errors, fix test syntax only.

4. Handoff report:
   - List test files changed.
   - Summarize pass/fail and key assertions.
   - State explicitly that implementation has not started.
   - Ask for approval to continue to implementation.

## Guardrails

- Never modify non-test source files during tests-only phase.
- Keep edits minimal and tied to requested behavior.
- Preserve existing behavior unless tests intentionally codify a behavior change.
- If instructions conflict, follow explicit user instruction first.

## Elm-Motion Defaults

- Prefer focused runs before full suite.
- Use project test commands appropriate to the touched area.
- If any source file is later edited after approval, run required post-edit analysis steps.
