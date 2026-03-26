# Parallel agent execution

## Idea

Allow launching multiple task agents simultaneously, so multiple tasks execute in parallel.

## What would be needed

1. Execution script for background agents (isolated clone or worktree per agent)
2. Convention in `task.md` for marking parallelizable tasks (no shared files, no dependencies)
3. Orchestrator decides which tasks to run in parallel and which sequentially

## Notes

- Risk: merge conflicts when modifying the same files
- Only worthwhile for independent tasks (different files, no dependencies)
- Previous `cc.sh` (isolated clone runner) was removed — would need to be rebuilt if this is pursued
