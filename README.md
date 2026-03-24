# Claude Hollow

AI agent orchestration system for software development. Combines GTD task management with automated agent orchestration — no containers required.

## How it works

Start a feature with `claude-hollow`. Claude opens as an **orchestrator** and handles everything automatically:

1. Breaks down the request into concrete tasks
2. Creates `task.md` files in the GTD folder structure
3. Launches subagents (`@task-agent`, `@code-reviewer`, `@tester`) directly in the Claude session
4. Reviews the agent's diff after completion
5. Merges the task branch into the feature branch if accepted
6. Archives the completed task
7. Writes documentation to `docs/` summarizing what was implemented
8. Notifies you when the feature is ready for a merge request

The orchestrator **never writes code itself** — that is exclusively the role of the agents.

## Setup

```bash
git clone git@github.com:GoblikM/claude-hollow.git
cd claude-hollow
./install.sh
```

This creates a symlink in `~/.local/bin/claude-hollow` so you can type `claude-hollow` from anywhere.

> If `~/.local/bin` is not in your PATH, `install.sh` will tell you what to add to `.bashrc`/`.zshrc`.

## Usage

```bash
claude-hollow
```

Interactive menu to add/create projects and start features.

```
🏠  Claude Hollow
──────────────────────────────────────────

  Projects

  [1] my-app          ~/dev/my-app
  [2] my-api          ~/dev/my-api

  ──────────────────────────────────────────
  [a] Add existing project
  [n] Create new project
  [q] Quit
```

Select a project → see its features → start or resume one.

### Direct access (without menu)

```bash
# New feature
./scripts/feature.sh my-feature --project /path/to/project

# Reopen existing feature
./scripts/feature.sh my-feature

# Delete a feature
./scripts/feature.sh -D my-feature
```

## Structure

```
claude-hollow/
├── CLAUDE.md                   # Orchestrator context
├── install.sh                  # Installs the claude-hollow command
├── features/
│   ├── _templates/             # Templates: task, issue, inbox, feature docs
│   └── <project-name>/         # Local only — not tracked in git
│       └── <feature-name>/
│           ├── CLAUDE.md       # Feature orchestrator context (generated)
│           ├── workspace/      # Git worktree of the feature branch
│           ├── tasks/          # Ready-to-run tasks
│           │   └── done/       # Completed tasks (archive)
│           ├── blocked/        # Waiting on external dependencies
│           ├── icebox/         # Deliberately deferred
│           └── docs/           # Feature documentation
├── inbox/                      # Quick capture — local only, not tracked in git
└── scripts/
    ├── office.sh               # Main entry point (launched as claude-hollow)
    ├── feature.sh              # Initialize a feature workspace and git worktree
    ├── lib.sh                  # Shared utilities
    ├── task-done.sh            # Move a completed task to done/
    ├── cc.sh                   # (Advanced) Run a task agent in an isolated clone
    └── cleanup-clone.sh        # (Advanced) Remove a task clone after merge
```

## Agent pipeline

Each task goes through three subagents in order:

| Agent | Role |
|-------|------|
| `@task-agent` | Implements changes, writes tests, commits to `task/<slug>` branch |
| `@code-reviewer` | Reviews diff, verifies AC, conventions, and tests |
| `@tester` | Runs tests, reports PASS / FAIL / SKIP |

## GTD structure

| Folder | Meaning |
|--------|---------|
| `tasks/` | Actionable, ready to run |
| `tasks/done/` | Completed (archive) |
| `blocked/` | Waiting on something external |
| `icebox/` | Intentionally deferred |
| `inbox/` | Unprocessed — review and move ASAP |

## Local data

`features/` and `inbox/` are gitignored — task data stays on your machine. The repo only tracks the tool itself (scripts, templates, agent definitions), so Claude Hollow works for any project without mixing task data into version control.

## Requirements

- [Claude Code CLI](https://claude.ai/code) — `claude` in PATH
- Git
