# Task: [task name]

## Metadata
- **Feature:** [feature-name]
- **Component:** [e.g. frontend | backend | api | all]
- **Branch:** feature/[feature-name]
- **Estimated complexity:** S | M | L  <!-- S: 1–3 files, single concern | M: 4–8 files, one module | L: 8+ files — consider splitting -->
- **Pipeline:** task-agent → code-reviewer → tester | + architect

## Description
What the agent should do and why.

## Acceptance criteria
How we know the task is done:
- [ ] ...
- [ ] ...

<!-- ═══════════════════════════════════════════════════════
     Everything ABOVE is written by the orchestrator.
     Everything BELOW is filled by @architect (or by the
     orchestrator only for S-complexity tasks).
     ═══════════════════════════════════════════════════════ -->

## Scope
Files/directories the agent may change:
```
(filled by @architect)
```

## Technical notes
Context, constraints, implementation suggestions.

## Tests
<!-- Describe what to test and where. Tests are always expected.
     If genuinely untestable (pure config, generated file), tester will SKIP with reason. -->

**What to test:**
- ...

**Test file location:**
```
tests/...
```

## Pipeline state
- **Attempt:** 1/3
- **Last stage:** —
- **Status:** not started

## Notes
<!-- Runtime notes — review feedback, blocker descriptions, retry context.
     Added by orchestrator during pipeline execution. -->
