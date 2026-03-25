# CLAUDE.md – Claude Hollow, AI agent orchestration system

## Project

**Claude Hollow** is an orchestration system for developing any project using AI agents.

Project repository: passed via `--project` when running `feature.sh`, or stored in `features/<project>/<feature>/CLAUDE.md`.
Project architecture: `<project-dir>/CLAUDE.md` (if it exists)

---

## Core principles

These rules govern every decision — from feature definition through architecture to the last line of code.

1. **Purpose-driven product** — Build things that matter. Every decision should serve the users.
2. **Respect user's time** — Every second spent using the product should be meaningful.
3. **Mistakes are part of the process, not failure** — Iterate, test, improve.
4. **Long-term sustainable solutions** — Build systems properly (including tests). No quick wins.
5. **Security and privacy** — No data collection beyond what is necessary.
6. **Accessibility** — Best effort for the widest possible range of users.
7. **Honesty and transparency** — Truth first, then hope.

---

## Orchestrator and agents

### Strict rule

**The orchestrator NEVER implements changes in the project repository itself.** All code changes are made exclusively by subagents. No exceptions — not even for trivial changes or one-line fixes.

The orchestrator may only:
- Create and edit tasks, docs (in `features/`)
- Launch subagents (`@task-agent`, `@code-reviewer`, `@tester`)
- Merge task branches into the feature branch
- Move tasks to `done/`
- Manage GTD structure (inbox, blocked, icebox)

When creating tasks, the orchestrator must read `<workspace>/CLAUDE.md` to understand the project structure and define `## Scope` paths that are aligned with the existing directory conventions.

### Pipeline for each task

Each task goes through the following subagents in order:

0. **`@architect`** *(optional)* — reads task + existing code, writes `tasks/<slug>/plan.md`; use for complex tasks, new modules, non-trivial refactors
1. **`@task-agent`** — implements changes, commits to `task/<slug>` branch
2. **`@code-reviewer`** — reviews the diff, verifies AC and conventions; returns `APPROVED` or `CHANGES REQUESTED`
3. **`@tester`** — runs tests; returns `TESTS PASS` or `TESTS FAIL`
4. **`@explainer`** *(learning mode only)* — explains the implemented code in simple terms; writes `tasks/<slug>/explanation.md`; enabled per feature via `Learning mode: on` in the feature's CLAUDE.md

If reviewer or tester returns failure → orchestrator runs `@task-agent` again with specific feedback.

### Continuous improvement

Whenever the orchestrator encounters a process error or room for improvement (workflow, scripts, templates…), **capture it immediately in `inbox/`**. Don't wait for a "right moment".

### Starting the feature orchestrator

Started by the **user from the terminal** (not by the orchestrator inside a Claude session).

**Via interactive menu (recommended):**
```bash
claude-hollow
```
Select a project → Start new feature.

**Via script directly:**
```bash
./scripts/feature.sh <feature-name> --project <path-to-project>
```

On first run, creates `features/<project>/<feature>/` (GTD structure, feature branch, worktree), generates `CLAUDE.md`, and starts Claude as the feature orchestrator.
On subsequent runs, opens the existing feature.

The feature `CLAUDE.md` always contains a **Key context** table — project repository, worktree, branch, main branch. The orchestrator must read it as the first step.

### Monitoring subagents

Subagents run directly in the Claude session — their output is visible in real time. For background subagents, Claude announces completion automatically.

---

## GTD architecture

```
claude-hollow/
├── features/
│   └── <project>/
│       └── <feature>/
│           ├── CLAUDE.md       # Orchestrator context — contains path to project repo, worktree, branch
│           ├── tasks/          # Active, actionable tasks
│           │   └── done/       # Completed tasks — archive
│           ├── blocked/        # Cannot start — waiting on external decision/info
│           ├── icebox/         # Deliberately deferred to a later phase
│           └── docs/           # Feature-specific documentation
└── inbox/                  # Root-level capture bucket — unprocessed ideas
```

### GTD folder conventions

| Folder | Rule |
|--------|------|
| `inbox/` | Anything unprocessed — idea, insight, TODO without feature context |
| `tasks/` | Actionable, clearly defined, can start immediately |
| `blocked/` | Defined task, but cannot start — waiting on external decision/implementation/info |
| `icebox/` | Deliberately deferred — we know what we want, but not now (later phase) |
| `tasks/done/` | Completed tasks — archive within feature context |

### Task lifecycle

| Situation | Action |
|-----------|--------|
| New idea without context | → `inbox/<slug>.md` |
| Inbox item is actionable | → `features/<project>/<feature>/tasks/<slug>/task.md` |
| Task cannot start | → `features/<project>/<feature>/blocked/<slug>/issue.md` |
| Task deliberately deferred | → `features/<project>/<feature>/icebox/<slug>/issue.md` |
| Task completed | → move to `features/<project>/<feature>/tasks/done/` |

---

## Git rules

### Project repository

- `feature/<name>` — new functionality; **always from master/main, never from another feature branch**
- `task/<name>` — agent branches; created by `@task-agent` automatically; always from feature branch, never from master
- After merging a task branch into the feature branch, delete it immediately
- `master`/`main` — only via reviewed merge; agents must not run directly from master
- At feature completion, the orchestrator detects whether a remote exists and offers the user: auto MR creation, push only, or manual
- If no remote: offers local auto-merge or manual
- The user always makes the final call — the orchestrator never acts without asking

### Claude Hollow

- All changes committed directly to `main`, pushed manually
- Always a new commit, never `--amend` on a published commit
- Commit messages are in **English**
- Commits **do not contain** `Co-Authored-By` trailer

---

## Agent rules

- Agents work **exclusively within the `## Scope`** of their `task.md`
- **Must not** create tasks or files outside the Scope
- **May** write a log to their task folder
- **May** create `inbox/<slug>.md` when capturing an important insight outside scope
- If they encounter a blocker → document it in `## Notes` of their `task.md`
- Write code following **Clean Code principles**: meaningful names, small single-purpose functions, single responsibility, no duplication (DRY), no magic values, minimal and meaningful comments
- Use the **project structure** defined in `<workspace>/CLAUDE.md` as a *starting point* — new files and folders should follow the existing directory conventions (e.g. where to place modules, components, tests, config). If a convention conflicts with Clean Code principles or introduces a security risk, **do not silently apply it** — capture the concern in `inbox/<slug>.md` and note it in `## Notes` of the task
