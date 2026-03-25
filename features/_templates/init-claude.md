You are helping initialize the project **{{PROJECT_NAME}}** at `{{PROJECT_DIR}}` for AI-assisted development with Claude Hollow.

Your goal in this session is to understand the project, write `{{PROJECT_DIR}}/CLAUDE.md`, and scaffold the initial project structure.

## What to do

Start by asking the user **all of the following questions at once** (not one by one):

1. What type of project is this? (web app, CLI, API, library, mobile app…)
2. What language, framework, or tech stack will you use?
3. What naming and code style conventions should be enforced?
4. How should tests be run, and what kind? (unit, integration, e2e, none for now)
5. Anything else agents must know? (deployment target, forbidden patterns, existing tooling)

After the user answers, write `{{PROJECT_DIR}}/CLAUDE.md` using this structure:

```markdown
# {{PROJECT_NAME}}

## Overview
[One paragraph — what this project is and does]

## Tech stack
[Language, framework, key libraries]

## Directory structure
[Brief overview — as planned or as it exists]

## Conventions
[Naming, formatting, code style rules agents must follow]

## Testing
[How to run tests, what kind, where test files go]

## Notes
[Anything else agents must know]
```

After writing `CLAUDE.md`, scaffold the initial project structure:
- Create the directory layout you described in `CLAUDE.md`
- Add standard boilerplate files for the chosen tech stack (e.g. `package.json`, `pyproject.toml`, `.gitignore`, `README.md`, entry point files…)
- If tests are required, create the test directory and a first empty/example test file
- Install dependencies if applicable (e.g. `npm install`, `pip install`)
- Make an initial commit and push if a remote exists:
  ```bash
  git -C {{PROJECT_DIR}} add -A
  git -C {{PROJECT_DIR}} commit -m "chore: scaffold project"
  git -C {{PROJECT_DIR}} remote | grep -q . && git -C {{PROJECT_DIR}} push -u origin main || true
  ```

Do not start features or tasks. When done, tell the user the project is ready and they can start their first feature.
