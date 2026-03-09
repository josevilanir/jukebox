# CLAUDE.MD

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Minimal code impact.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Only touch what's necessary. Avoid introducing side-effects.

## Workflow

### Plan Before Acting

- Enter plan mode for any non-trivial task (3+ steps or architectural decisions).
- Write plan to `tasks/todo.md` with checkable items, then check in before starting implementation.
- If something goes sideways, stop and re-plan immediately — don't keep pushing.

### Subagent Strategy

- Offload research, exploration, and parallel analysis to subagents to keep the main context window clean.
- One focused task per subagent.

### Self-Improvement Loop

- After any correction from the user, update `tasks/lessons.md` with the pattern.
- Write rules that prevent the same mistake from recurring. Review lessons at session start.

### Verification Before Done

- Never mark a task complete without proving it works: run tests, check logs, demonstrate correctness.
- Mark items complete in `tasks/todo.md` as you go, and add a result summary when finished.
- Ask: "Would a staff engineer approve this?"

### Elegance Check

- For non-trivial changes, pause and ask: "Is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution."
- Skip for simple, obvious fixes.

### Autonomous Bug Fixing

- When given a bug report, just fix it. Point at logs/errors/failing tests, then resolve them.
- Go fix failing tests without being told how.
