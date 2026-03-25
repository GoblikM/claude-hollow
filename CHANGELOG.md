# Changelog

All notable changes to Claude Hollow are documented in this file.

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
