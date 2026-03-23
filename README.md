# Office – AI Agent Orchestration for Čestyňák

A system for managing Claude Code AI agents during development of the [Čestyňák](https://gitlab.com/martinsenkerik/cestynak) game. Combines GTD task management with automated agent orchestration — no containers required.

## How it works

You open Claude Code in this directory and describe what you want to implement. Claude acts as an **orchestrator** and handles everything automatically:

1. Breaks down the request into a feature and concrete tasks
2. Creates the GTD folder structure and `task.md` files
3. Launches task agents via `scripts/cc.sh` — each agent runs in an **isolated git clone** on a dedicated `task/<slug>` branch
4. Reviews the agent's diff after completion
5. Merges the task branch into the feature branch if accepted
6. Archives the completed task and cleans up the clone
7. Writes documentation to `docs/` summarizing what was implemented
8. Notifies you when the feature is ready for a merge request

```bash
cd office/
claude
# "Add sound effects when the player answers correctly"
```

The orchestrator **never writes code itself** — that is exclusively the role of the agents.

## Structure

```
office/
├── CLAUDE.md                   # Orchestrator context (read by Claude on startup)
├── features/
│   ├── _templates/             # Templates: task, issue, inbox, feature docs
│   └── <feature-name>/
│       ├── CLAUDE.md           # Feature-specific orchestrator context
│       ├── tasks/              # Ready-to-run tasks
│       │   └── done/           # Completed tasks (archive)
│       ├── blocked/            # Tasks waiting on external dependencies
│       ├── icebox/             # Deliberately deferred items
│       └── docs/               # Feature documentation written after completion
├── inbox/                      # Quick capture for unprocessed ideas
└── scripts/
    ├── cc.sh                   # Launch a task agent in an isolated git clone
    ├── feature.sh              # Initialize a feature workspace and git worktree
    ├── lib.sh                  # Shared utilities (branch detection, slugify, etc.)
    ├── task-done.sh            # Move a completed task to done/
    └── cleanup-clone.sh        # Remove a task clone after merge
```

## Agent isolation

Each task runs in a separate git clone located at `../.clones/task-<slug>/`. The agent works on a `task/<slug>` branch inside the clone. After the agent finishes, commits are fetched back to the main project repo for review before merging. This prevents agents from accidentally affecting the working tree or other tasks.

## GTD rules

| Folder | Meaning |
|--------|---------|
| `tasks/` | Actionable, ready to run |
| `tasks/done/` | Completed (archive) |
| `blocked/` | Waiting on something external |
| `icebox/` | Intentionally deferred |
| `inbox/` | Unprocessed — review and move ASAP |

## Requirements

- [Claude Code CLI](https://claude.ai/code) — `claude` available in PATH
- Git
- Čestyňák repository cloned locally at `~/dev/cestynak`
