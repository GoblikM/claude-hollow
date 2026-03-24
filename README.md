# Češťyňák — Claude Hollow

AI agent orchestration for the Češťyňák game project. Based on [Claude Hollow](https://github.com/GoblikM/claude-hollow) (`main` branch) — this branch adds Godot/GDScript conventions, GUT test runner, and Češťyňák-specific context (core principles, game name, analytics, environment detection).

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
curl -fsSL https://raw.githubusercontent.com/GoblikM/claude-hollow/cestynak-hollow/install/unix.sh | bash
```

**Windows CMD:**
```cmd
curl -fsSL https://raw.githubusercontent.com/GoblikM/claude-hollow/cestynak-hollow/install/windows.cmd -o install.cmd && install.cmd && del install.cmd
```

**Windows PowerShell:**
```powershell
irm https://raw.githubusercontent.com/GoblikM/claude-hollow/cestynak-hollow/install/windows.ps1 | iex
```

Run the command from the directory where you want the repo cloned. Restart your terminal after install.

## Usage

```bash
claude-hollow
```

```
🎮  Češťyňák Hollow
──────────────────────────────────────────

  Projects

  [1] cestynak          ~/dev/cestynak

  ──────────────────────────────────────────
  [a] Add existing project
  [q] Quit
```

Select a project → see its features → start or resume one.

### Direct access (without menu)

```bash
# New feature
./scripts/feature.sh my-feature --project /path/to/cestynak

# Reopen existing feature
./scripts/feature.sh my-feature

# Delete a feature
./scripts/feature.sh -D my-feature
```

## What's different from main

| | `main` | `cestynak-hollow` |
|---|---|---|
| Menu title | Claude Hollow | Češťyňák Hollow |
| Core principles | Generic | Češťyňák-specific (7 principles) |
| Game conventions | — | Name, environment detection, settings, analytics |
| Test runner | Generic discovery | GUT (headless, `t_` prefix) |
| Code review | Generic | + GDScript conventions |
| Task agent | Generic | + Godot file rules (.godot/, .import) |

## Structure

```
cestynak-hollow/
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
    ├── hollow.sh               # Main entry point (launched as claude-hollow)
    ├── feature.sh              # Initialize a feature workspace and git worktree
    ├── lib.sh                  # Shared utilities
    ├── task-done.sh            # Move a completed task to done/
    └── feature-done.sh         # Cleanup after feature merge
```

## Agent pipeline

Each task goes through the following subagents in order:

| Agent | When | Role |
|-------|------|------|
| `@architect` | Complex tasks | Reads task + existing code, writes `plan.md` with approach, files, risks |
| `@task-agent` | Always | Implements changes, writes tests, commits to `task/<slug>` branch |
| `@code-reviewer` | Always | Reviews diff, verifies AC, GDScript conventions, and tests |
| `@tester` | Always | Runs GUT tests headlessly, reports PASS / FAIL / SKIP |

## Requirements

- [Claude Code CLI](https://claude.ai/code) — `claude` in PATH
- Git
- Godot 4.6.1 — `godot` in PATH (for running tests)
