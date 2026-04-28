# Agent Notes

This project may be edited with multiple coding assistants. Keep this file as
the handoff point when work is paused, interrupted, or continued by another
assistant.

## Workflow

- Use git before starting meaningful edits.
- Prefer one branch per task, for example `codex/fix-targeting` or
  `claude/add-new-towers`.
- Do not edit the same files in parallel unless the handoff below says why.
- Before switching assistants, record what changed, what remains, and how to
  verify it.

## Current Handoff

- Repository initialized by Codex on 2026-04-28.
- `flutter analyze` was run before initialization and reported no issues.
- Review notes found two likely gameplay bugs to revisit:
  - `Frost King` is described as chain freeze, but is registered as
    `TowerType.slow`.
  - `TargetingMode.first` currently compares enemy `y` position rather than
    true path progress.
