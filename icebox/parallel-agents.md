# Parallel agent execution

## Idea

Allow launching multiple task agents simultaneously, so multiple tasks execute in parallel.

## What would be needed

1. `cc.sh --background` — flag for background execution, returns PID or log name
2. Convention in `task.md` for marking parallelizable tasks (no shared files, no dependencies)
3. Orchestrator decides which tasks to run in parallel and which sequentially

## Notes

- Isolation is already in place — each agent has its own clone
- Risk: merge conflicts when modifying the same files
- Only worthwhile for independent tasks (different files, no dependencies)
