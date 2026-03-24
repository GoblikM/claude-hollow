Write or update `docs/brief.md` for the current feature.

## Steps

1. Read `CLAUDE.md` in the current directory — get FEATURE_NAME and any existing context
2. Read `docs/brief.md` if it exists — you will update it, not overwrite blindly
3. Review the current conversation — extract:
   - What is this feature trying to accomplish (goal)
   - Key decisions made (tech choices, scope boundaries, UX intent)
   - What is explicitly out of scope
4. Write `docs/brief.md`:

```markdown
# Feature brief: <feature-name>

## Goal
<One paragraph — what this feature does and why. Written for a developer who has no prior context.>

## Key decisions
- <Decision and brief reason>

## Out of scope
- <What will NOT be done in this feature>
```

## Rules

- Be specific — "add JWT auth" is better than "improve security"
- Key decisions must include the *why*, not just the *what*
- If `docs/brief.md` already exists, merge new information — don't lose existing content
- After writing, confirm with the file path and a one-line summary of what was captured
