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

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/GoblikM/claude-hollow/main/install/unix.sh | bash
```

Run the same command again to update to the latest version.


On fresh install, run the command from the directory where you want the repo cloned. Restart your terminal after install.

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
claude-hollow feature my-feature --project /path/to/project

# Reopen existing feature
claude-hollow feature my-feature

# Delete a feature
claude-hollow feature -D my-feature
```

## Structure

```
claude-hollow/
├── CLAUDE.md                   # Orchestrator context
├── install/                    # One-liner install script (unix.sh)
├── bin/
│   └── hollow.js               # Entry point
├── src/                        # Node.js source modules
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
└── inbox/                      # Quick capture — local only, not tracked in git
```

## Agent pipeline

Each task goes through the following subagents in order:

| Agent | When | Role |
|-------|------|------|
| `@architect` | Complex tasks | Reads task + existing code, writes `plan.md` with approach, files, risks |
| `@task-agent` | Always | Implements changes, writes tests, commits to `task/<slug>` branch |
| `@code-reviewer` | Always | Reviews diff, verifies AC, conventions, and tests |
| `@tester` | Always | Runs tests, reports PASS / FAIL / SKIP |

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
