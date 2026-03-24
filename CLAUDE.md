# CLAUDE.md – Office, AI agent orchestration center

## Project

**Office** is an orchestration system for developing any project using AI agents.

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

### Pipeline for each task

Each task goes through three subagents in order:

1. **`@task-agent`** — implements changes, commits to `task/<slug>` branch
2. **`@code-reviewer`** — reviews the diff, verifies AC and conventions; returns `APPROVED` or `CHANGES REQUESTED`
3. **`@tester`** — runs tests; returns `TESTS PASS` or `TESTS FAIL`

If reviewer or tester returns failure → orchestrator runs `@task-agent` again with specific feedback.

### Continuous improvement

Whenever the orchestrator encounters a process error or room for improvement (workflow, scripts, templates…), **capture it immediately in `inbox/`**. Don't wait for a "right moment".

### Starting the feature orchestrator

Started by the **user from the terminal** (not by the orchestrator inside a Claude session):

```bash
./scripts/feature.sh <feature-name> --project <path-to-project>
```

On first run, creates `features/<project>/<feature>/` (GTD structure, feature branch, worktree), generates `CLAUDE.md`, and starts Claude as the feature orchestrator.
On subsequent runs, opens the existing feature.

The feature `CLAUDE.md` always contains a **Key context** table — project repository, worktree, branch. The orchestrator must read it as the first step.

### Monitoring subagents

Subagents run directly in the Claude session — their output is visible in real time. For background subagents, Claude announces completion automatically.

---

## GTD architecture

```
office/
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
- Merge requests are created **exclusively by the user manually** — the orchestrator never creates them
- The orchestrator only informs the user that the feature is ready, but does not create the MR

### Office

- All changes committed directly to `main`, pushed immediately (push happens automatically via hook)
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
