---
description: "Activate emergency rollback & context purge — discard uncommitted changes, clear scratch directory, revert to PLAN.md"
argument-hint: ""
---

[Mode: Emergency Rollback & Context Purge activated]

You are a Senior DevOps Engineer. Your task is to perform an emergency rollback to a known good state, clearing scratch artifacts and restoring the project baseline.

**Ephemeral Scratch Cleanup:**

1. **Clean `.pi/tmp/` scratch directory (all contents):**
   - Execute: `rm -rf .pi/tmp/*`

2. **Clean stale explore caches (older than 24 hours):**
   - Execute: `find .pi/tmp -type f -mtime +1 -delete 2>/dev/null || true`

**Source Code Rollback:**

1. **Discard Uncommitted Application Changes:**
   - Run `git checkout -- .` to discard all uncommitted changes in the working directory.
   - Run `git clean -fd` to remove untracked files and directories.
   - **Verify:** Ensure `git status` shows a clean working tree.

2. **Revert PLAN.md to Last Committed State:**
   - Run `git checkout -- .pi/state/PLAN.md` to discard any uncommitted changes to the plan.
   - If `PLAN.md` is untracked, skip this step and output a warning.

3. **Final Verification:**
   - Confirm that no uncommitted changes remain (`git status`).
   - Output a rollback summary.

**Important:**
- pi.dev sessions are managed natively at `~/.pi/agent/sessions/`. This command does not delete pi.dev session files — that is done interactively via `/resume` (Ctrl+D) or directly via the filesystem.
- This rollback only clears the scratch `.pi/tmp/` directory and reverts git changes.
- pi.dev handles its own session lifecycle automatically.

**Output Format:**

    [Abort] Cleaning scratch directory...
    [Abort] Cleaning stale caches...
    [Abort] Discarding uncommitted changes...
    [Abort] Restoring PLAN.md to last committed state...
    [Abort] Verification: git status → clean
    [Abort] Rollback complete.

**Critical Rules:**
- This is a destructive operation — use with extreme caution.
- Do not delete or modify committed files.
- Do not push changes to remote — this is a local rollback only.
- If `PLAN.md` does not exist in git, output a warning and proceed.
- Always confirm the final state with `git status`.

**Example Output:**

    [Abort] Cleaning scratch directory... done (2 files removed)
    [Abort] Cleaning stale caches... 3 files removed.
    [Abort] Discarding uncommitted changes... done.
    [Abort] Restoring PLAN.md to last committed state... done.
    [Abort] Verification:
    On branch main
    nothing to commit, working tree clean
    [Abort] Rollback complete.
