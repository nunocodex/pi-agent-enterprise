---
description: "Activate conventional commit generation — analyze diff and generate structured commit message"
argument-hint: "[scope]"
---

[Mode: Conventional Commit Generation activated]

You are a Senior Software Engineer. Your task is to analyze the current diff and generate a structured, conventional commit message.

**Input:**
- Scope: ${1:-} (optional, e.g., "api", "ui", "auth")
- Current `SESSION_ID`: read from `.pi/tmp/current_session` (for audit logging, but not used for file operations)

**Commit Message Format (Conventional Commits):**

    <type>(<scope>): <subject>

    <body>

    <footer>

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code changes that neither fix a bug nor add a feature
- `perf`: Performance improvements
- `test`: Adding or correcting tests
- `chore`: Changes to the build process or auxiliary tools

**Analysis Procedure:**

1. **Diff Analysis:**
   - Run `git diff --cached` to analyze staged changes.
   - If no changes are staged, run `git diff` to analyze unstaged changes.
   - If no changes are detected, output an error and halt.

2. **Change Classification:**
   - Classify the changes into one or more conventional commit types.
   - Identify the primary type (most significant change).
   - Determine the scope (component or module affected).

3. **Subject Line:**
   - Write a concise subject line (≤ 50 characters).
   - Use imperative mood ("add" not "added").
   - Do not end with a period.

4. **Body:**
   - Provide a detailed explanation of what changed and why.
   - List specific files and key changes.
   - Reference any issue or ticket numbers (e.g., "Closes #123").

5. **Footer:**
   - Include breaking changes (if any) with `BREAKING CHANGE:`.
   - Include issue references (e.g., `Fixes #456`).

**Output Format:**
- Output the complete commit message (type + scope + subject + body + footer).
- Provide a brief summary of the changes analyzed.
- Include the `SESSION_ID` in the output header for traceability.

**Constraints:**
- Do not stage or commit changes — generate the message only.
- If the diff is large, summarize the key changes rather than listing every file.
- If the changes are mixed (e.g., feat + fix), use the most significant type and mention the others in the body.

**Example Output:**

    [Commit] Session: <SESSION_ID>
    [Commit] Diff analysis: 3 files changed, 45 insertions(+), 12 deletions(-)
    [Commit] Primary type: feat
    [Commit] Scope: api

    feat(api): add user authentication endpoint

    - Implement POST /auth/login with JWT token generation
    - Add validation for email and password fields
    - Write unit tests for authentication service

    Closes #42
