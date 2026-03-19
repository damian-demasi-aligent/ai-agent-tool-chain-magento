---
name: implement-feature
description: Orchestrate feature implementation and code review. Spawns the feature-implementer agent in a worktree, then runs the reviewer agent on the result. Use when you have a plan file ready and want to execute it.
argument-hint: [Path to plan file (e.g., docs/plans/ABC-123-my-awesome-feature.md)]
disable-model-invocation: true
---

# Implement Feature

Orchestrate the implementation workflow for "$ARGUMENTS".

You coordinate four phases — validation, implementation (in a worktree), code review, and reporting. Complete all phases in order.

## Phase 0: Gather context

Run these commands in parallel to establish context:

- `git branch --show-current` — extract the ticket identifier from the branch name
- `ls docs/plans/` — check available plan files

## Phase 1: Validate the plan

1. **Locate the plan file.** If $ARGUMENTS is a file path (e.g. `docs/plans/ABC-123-my-awesome-feature.md`), read it. If it's a ticket number, look for a matching file in `docs/plans/`. If no plan exists, stop and tell the user to run `/plan-feature` first.

2. **Check for open questions.** Scan the plan for unresolved items — look for:

   - Sections titled "Open Questions", "Questions", or "Assumptions"
   - Inline markers: `TODO`, `TBD`, `?`, "confirm", "verify"
   - Unchecked items in the implementation checklist that have question marks

3. **If open questions exist**, list them and ask the user to resolve them before proceeding. Do not continue to Phase 2 until confirmed.

4. **If the plan is clean**, summarise the scope in 2-3 sentences and confirm with the user before spawning the implementer. Example:

   ```
   Plan: docs/plans/ABC-123-my-awesome-feature.md
   Scope: New Trial module with GraphQL mutation, dual emails, React multi-step form widget, and admin config.
   Checklist: 12 items

   Ready to start implementation in a worktree. Proceed?
   ```

   Wait for user confirmation before continuing.

## Phase 2: Implement in a worktree

After the user confirms, use the **Agent tool** to spawn the `feature-implementer` agent in an isolated worktree.

```
Agent tool call:
  description: "Implement [feature name]"
  subagent_type: "feature-implementer"
  isolation: "worktree"
  prompt: "Implement the feature described in the following plan file: [plan file path]

Read the plan file first, then follow its implementation checklist in order. The plan contains all the context you need — file paths, pattern sources, and implementation details.

IMPORTANT — Read vendor integration points before writing code:
Before writing any plugin, observer, or code that hooks into Magento core, read the relevant vendor source code to understand the exact flow. This prevents integration bugs that cannot be caught from project code alone. For example:
- If hooking into a controller: read the controller's execute() method
- If writing a plugin on a repository save: read the save() method for side effects
- If dispatching or observing events: read where the event is dispatched and what state exists at that point
Your agent instructions have the full list of what to read — follow step 5 carefully.

After implementation, run verification checks and produce the change summary as described in your instructions."
```

The feature-implementer agent will:

- Read the plan and CLAUDE.md
- Read vendor source code for integration points (controllers, repositories, event dispatchers)
- Implement each checklist item in order
- Run type-check, lint, and build verification
- Produce a structured change summary

Wait for the agent to complete. This may take a while for large features.

## Phase 3: Code review

After the feature-implementer agent returns, determine where the changes live before spawning the reviewer.

**Detect where the changes live:** Run two commands in parallel:

1. `git worktree list` — check if the implementer's worktree still exists
2. `ls -d [worktree path]` — verify the directory actually exists on disk (git may list stale/prunable entries for directories that were already deleted)

Then determine the location:

- **Worktree exists on disk** (listed in `git worktree list` WITHOUT `prunable` AND the directory exists) → the changes are there. Tell the reviewer to `cd` into the worktree path.
- **Worktree is stale** (marked `prunable`, or directory doesn't exist on disk) → the directory was already removed. Run `git worktree prune` to clean up the stale reference. The changes are in the **main working directory**. Tell the reviewer to work there.
- **Worktree not listed at all** → same as stale: changes are in the main working directory.

Spawn the **reviewer** agent accordingly:

```
Agent tool call:
  description: "Review [feature name] implementation"
  subagent_type: "reviewer"
  prompt: "Review the uncommitted changes implementing [feature name].

The changes are in [worktree path OR main working directory]. Run these commands to see them:

  cd [path]
  git diff
  git diff --cached
  git status

The plan that guided the implementation is at [plan file path].

Follow your standard review process: run git diff to see the full diff, then review for correctness, patterns compliance, cross-boundary consistency, and accessibility."
```

Wait for the reviewer to complete, then proceed to Phase 4.

## Phase 4: Report results

After both agents have completed, present the combined output to the user. The output should contain:

1. **Change summary** — files created/modified, grouped by layer (from the implementer)
2. **Verification results** — type-check, lint, build pass/fail (from the implementer)
3. **Checklist progress** — how many items were completed vs blocked (from the implementer)
4. **Code review** — the reviewer agent's findings, presented as-is without filtering or softening
5. **Key files to understand** — the 3-5 most important files for understanding the feature (from the implementer)

Present all of this to the user, then provide next steps:

```
## Next Steps

1. **Review the changes** — The changes are in: [worktree path or main working directory]
   - `cd [path]` to inspect files
   - `git diff` to see all changes

2. **Fix review issues** (if any) — Address findings from the code review before committing

3. **Commit the changes** — When satisfied, use `@committer` to create structured commits following the project's grouping conventions

4. **Generate documentation** — For multi-layer features, use `@documenter [ticket]` to create a feature architecture document in docs/features/

5. **Clean up the worktree** (if applicable) — If changes are in a worktree, merge them back to the main branch and remove the worktree after pushing
```

If the implementer reported blocked items or failures, highlight those prominently so the user knows what needs manual attention.
