#!/usr/bin/env bash
# =============================================================================
# validate_gitignore.sh — Structural validation test for .gitignore
#
# Verifies that the project .gitignore contains all critical entries
# required by the security risk register (S1, S2, S9).
#
# Features:
#   - Path resolution: auto-detects project root relative to script location
#   - Comment-aware: ignores comment lines and blank lines when checking entries
#   - Exact header matching: matches # === SECTION_NAME === pattern
#
# Usage: bash validate_gitignore.sh [path-to-.gitignore]
#   Default path: resolved relative to this script's location (portable)
# Returns: 0 if all checks pass, 1 if any check fails
# =============================================================================

# --- Resolve .gitignore path relative to script location (review fix M1) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
GITIGNORE_PATH="${1:-$SCRIPT_DIR/../.gitignore}"

# Normalize path (remove /./ and /../)
if command -v readlink >/dev/null 2>&1; then
    GITIGNORE_PATH="$(readlink -f "$GITIGNORE_PATH" 2>/dev/null || echo "$GITIGNORE_PATH")"
fi

TESTS_PASSED=0
TESTS_FAILED=0

log_pass() { echo "  ✅ $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
log_fail() { echo "  ❌ $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

echo "=== validate_gitignore.sh ==="
echo "Script root: $SCRIPT_DIR"
echo "Target: $GITIGNORE_PATH"
echo ""

# --- Check 1: File exists ---
if [ -f "$GITIGNORE_PATH" ]; then
    log_pass "File exists at $GITIGNORE_PATH"
else
    log_fail "File exists at $GITIGNORE_PATH"
fi

# --- Check 2: Not empty ---
FILE_LINES=$(wc -l < "$GITIGNORE_PATH" 2>/dev/null || echo 0)
if [ "$FILE_LINES" -gt 0 ]; then
    log_pass "File is non-empty ($FILE_LINES lines)"
else
    log_fail "File is empty"
fi

# --- Helper: check a critical entry in non-comment lines (review fix L2) ---
# Filters out blank lines and lines starting with # (comments), then greps.
check_active_entry() {
    local pattern="$1"
    local active_lines
    active_lines=$(grep -vE '^\s*(#|$)' "$GITIGNORE_PATH" 2>/dev/null || true)
    if echo "$active_lines" | grep -Eq "$pattern" 2>/dev/null; then
        log_pass "Active entry: $pattern"
    else
        log_fail "Missing or commented-out entry: $pattern"
    fi
}

# --- Check 3-9: Critical entries from security risk register ---
check_active_entry '^\.env$'
check_active_entry '^agent/auth\.json$'
check_active_entry '^agent/sessions/'
check_active_entry '^venv/'
check_active_entry '^agent/npm/node_modules/'
check_active_entry '^agent/bin/'
check_active_entry '^tmp/'
check_active_entry '^state/'

# --- Check 10: *.jsonl defense-in-depth (S3, T1.1b) ---
check_active_entry '^\*\.jsonl$'
if grep -Eq '\s+$' "$GITIGNORE_PATH" 2>/dev/null; then
    log_fail "Found trailing whitespace on some lines"
else
    log_pass "No trailing whitespace"
fi

# --- Check 11: File ends with newline ---
if [ "$(tail -c 1 "$GITIGNORE_PATH" 2>/dev/null | wc -l)" -eq 1 ]; then
    log_pass "File ends with newline"
else
    log_fail "File does not end with newline"
fi

# --- Check 12-18: Section headers (# === SECTION_NAME pattern, review fix L1) ---
for section in "SECRETS" "SESSIONS" "BINARIES" "DEPENDENCIES" "IDE" "OS" "EPHEMERAL"; do
    if grep -q "^# === $section" "$GITIGNORE_PATH" 2>/dev/null; then
        log_pass "Section header: # === $section"
    else
        log_fail "Missing section header: # === $section"
    fi
done

echo ""
echo "=== Results: $TESTS_PASSED passed, $TESTS_FAILED failed ==="
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✅ All checks passed."
    exit 0
else
    echo "❌ Some checks failed."
    exit 1
fi
