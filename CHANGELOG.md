# Changelog

All notable changes to Claude Hollow are documented in this file.

## [v0.1.2] — 2026-03-26

### Changed

- **Task creation split between orchestrator and architect** — orchestrator writes intent (Description, AC, complexity), `@architect` fills technical details (Scope, Technical notes, Test paths) based on actual code exploration
- **@architect is now mandatory for M/L complexity tasks** — optional only for S (simple bug fix, config change)
- **Incremental task planning** — orchestrator creates independent tasks upfront, defers dependent tasks until predecessors are complete
- **Task complexity definitions (S/M/L)** with concrete criteria and splitting rules — prevents oversized tasks
- **plan.md no longer duplicates Scope** — task.md covers "what and where", plan.md covers "how" (approach, interfaces, risks)

### Added

- **Persistent retry feedback** — review/test failure feedback is written to `## Notes` in task.md before retry, survives session loss
- **Plan compliance check** in `@code-reviewer` — verifies implementation follows `plan.md` approach when it exists
- **Task splitting rules** — tasks must be split when they have multiple independent concerns, span architectural layers, or have 5+ AC items
- **`## Notes` section** in task.md template for runtime context (feedback, blockers)
- **Visual separator** in task.md template marking orchestrator vs architect sections

### Fixed

- Orchestrator no longer guesses file paths for Scope — architect fills them from actual code
- README architect role description now matches expanded responsibilities

## [v0.1.1] — 2026-03-25

### Improved

- **Clean Code principles** added to agent instructions (`@task-agent`, `@code-reviewer`) — agents now explicitly follow naming, DRY, single responsibility, no magic values, and minimal comments rules
- **Project structure awareness** — agents and orchestrator now read `<workspace>/CLAUDE.md` before defining Scope or placing new files; conventions are treated as a starting point, not an absolute truth
- **feature-claude.md template** updated with a *Code quality* section reminding orchestrators to include Clean Code guidance in task definitions
- **CLAUDE.md** updated with Clean Code and project structure rules for agents

### Fixed

- Agent instructions no longer treat project conventions as absolute — if a convention conflicts with Clean Code principles or introduces a security risk, agents are instructed to capture the concern in `inbox/` rather than silently propagate it

## [v0.1.0] — 2026-03-25

Initial release. See [GitHub release](https://github.com/GoblikM/claude-hollow/releases/tag/v0.1.0) for details.
