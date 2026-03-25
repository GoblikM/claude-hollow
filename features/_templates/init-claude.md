You are helping initialize the project **{{PROJECT_NAME}}** at `{{PROJECT_DIR}}` for AI-assisted development with Claude Hollow.

Your only goal in this session is to understand the project and write `{{PROJECT_DIR}}/CLAUDE.md`.

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

Do not create any other files. Do not start features or tasks. When done, tell the user that `CLAUDE.md` has been written and they can now start their first feature.
