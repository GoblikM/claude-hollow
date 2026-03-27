# Changelog

All notable changes to this project will be documented in this file.

## [unreleased]

### 🚀 Features

- Show version from git tag in main menu

### 🐛 Bug Fixes

- Fetch tags on update so version displays correctly
- Address critical architecture issues from system review

### 🚜 Refactor

- Merge brief.md into feature CLAUDE.md
- Improve subagent definitions with clear roles and rules
- Improve subagent definitions with clear roles and rules

## [0.1.2] - 2026-03-26

### 🚀 Features

- Add optional @explainer agent for learning mode

### 🚜 Refactor

- Split task creation between orchestrator and architect

### 📚 Documentation

- Add @explainer and learning mode to README
- Add CHANGELOG.md with v0.1.2 release notes

## [0.1.1] - 2026-03-25

### 🚀 Features

- Add clean code principles to agent definitions and CLAUDE.md
- Add project structure conventions to agent definitions
- Orchestrator must respect project structure when defining task scopes
- Remind orchestrator to check project structure before defining task Scope paths
- Add Clean Code principles to feature-claude.md orchestrator template

### 🐛 Bug Fixes

- Treat project conventions as starting point, not absolute truth

### 📚 Documentation

- Add CHANGELOG.md with v0.1.1 release notes

## [0.1.0] - 2026-03-25

### 🚀 Features

- *(main-menu-title)* Task add-ahoj-label done
- *(agents)* Code-reviewer a tester ukládají report do task složky
- Make test writing explicit in task pipeline
- Add office.sh interactive entry point with project registry
- Add new project questions to orchestrator requirements gathering
- Add tab completion for project path inputs in office.sh
- Scope features per project under features/<project>/<feature>/
- Redesign office.sh menu with project/feature screens and clear navigation
- Add install.sh to register office command globally via symlink
- Rename command from office to claude-office
- Rename command from claude-office to claude-hollow
- Replace typed menu with arrow-key picker
- Add navigation hints to arrow-key picker
- Add architect agent and flexible per-task pipeline
- Make tester always mandatory, tests always expected
- Add feature-done cleanup to hollow.sh menu
- Orchestrator offers auto-merge and cleanup at feature completion
- Orchestrator detects remote and offers MR creation at feature end
- Add push-only option when remote exists (no MR creation)
- Orchestrator proactively offers merge when all tasks are done
- Persist feature context across sessions via docs/brief.md
- Auto-push after git commit via PostToolUse hook
- Add /brief skill, replace empty settings.json
- Add cross-platform install support for Windows
- Add install.bat for one-click Windows install without bash
- Replace local install scripts with self-contained one-liner installers
- Customize agents for Godot/GDScript and GUT test framework
- Add Cestynak core principles, game conventions, fix godot executable
- Rename menu to Češťyňák Hollow, update README for cestynak-hollow branch
- Set cestynak-hollow branch in install scripts, update README with one-liner install commands
- Install script supports update, drop Windows installers
- Add frontend-design skill and integrate it into task-agent
- Update project CLAUDE.md at end of each feature
- Add init project flow for new projects
- Scaffold project and push during init session
- Improve init UX with terminal hint and conversational questions

### 🐛 Bug Fixes

- Use relative path for default project dir in feature.sh
- Correct template paths and cc.sh reference, init new projects with main branch
- Add execute permissions to all scripts
- Resolve symlink in SCRIPT_DIR so claude-office works from PATH
- Rewrite arrow-key picker to use ANSI cursor save/restore
- Write picker display to /dev/tty so it shows inside subshell
- Correct paths and gh CLI usage in feature template, add architect to README
- Prune stale worktree entries before deleting feature branch
- Hide features without workspace from menu
- Move auto-push hook to settings.local.json (personal, not shared)
- Add pipeline stop condition, inbox processing, docs/summary.md template
- Use cd /d to set working dir before running bash in .bat launcher
- Translate core principles to English, rename to Češťyňák
- Expand analytics convention with pattern and user_set vs _send_event guidance
- Remove cestynak-specific content from main branch
- Restore generic Claude Hollow menu title in hollow.sh
- Re-initialize archived feature instead of blocking with "already exists"
- Invoke frontend-design skill only when no design direction is defined in project context
- Create new project in subdirectory named after project slug
- Handle sentinel in is_initialized and remove stale setup block

### 🚜 Refactor

- Generalize office system to be project-agnostic
- Translate all content to English
- Rename Office to Claude Hollow throughout codebase
- Rename office.sh to hollow.sh
- Move install scripts to install/ folder with cleaner names
- Move install scripts to install/ folder, update README URLs

### 📚 Documentation

- Zobecnění cesty k repozitáři hry na relativní ../cestynak
- Update top-level CLAUDE.md for Claude Hollow
- Update README with one-liner install commands for all platforms
- Update structure diagram to reflect install/ folder
- Add Windows WSL install instructions
- Remove incorrect claim about automatic push hook

### ⚙️ Miscellaneous Tasks

- Smazání feature main-menu-title
- Gitignore features/ data and inbox/, keep only tool files tracked
- Translate .gitignore comments to English
- Ignore reviews/ directory
- Remove unnecessary reviews/ from gitignore

### ◀️ Revert

- Replace arrow-key picker with simple numbered/letter menu

### Icebox

- Paralelní běh agentů

<!-- generated by git-cliff -->
