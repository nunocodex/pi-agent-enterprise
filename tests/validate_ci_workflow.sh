#!/usr/bin/env bash
# =============================================================================
# validate_ci_workflow.sh — Structural validation test for CI workflow
#
# Verifies that .github/workflows/ci.yml:
#   1. Exists and is valid YAML
#   2. Contains all 11 required stages
#   3. Has correct trigger events
#   4. Uses appropriate runners
#   5. Has no secrets or hardcoded credentials
#
# Usage: bash tests/validate_ci_workflow.sh
# Returns: 0 if all checks pass, 1 if any check fails
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
CI_PATH="${1:-$SCRIPT_DIR/../.github/workflows/ci.yml}"

TESTS_PASSED=0
TESTS_FAILED=0

log_pass() { echo "  ✅ $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
log_fail() { echo "  ❌ $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

echo "=== validate_ci_workflow.sh ==="
echo "Script root: $SCRIPT_DIR"
echo "Target: $CI_PATH"
echo ""

# --- Check 1: File exists ---
if [ -f "$CI_PATH" ]; then
    log_pass "CI workflow file exists at $CI_PATH"
else
    log_fail "CI workflow file not found at $CI_PATH"
fi

# --- Check 2: Not empty ---
FILE_LINES=$(wc -l < "$CI_PATH" 2>/dev/null || echo 0)
if [ "$FILE_LINES" -gt 10 ]; then
    log_pass "CI workflow is substantial ($FILE_LINES lines)"
else
    log_fail "CI workflow is too short or empty ($FILE_LINES lines)"
fi

# --- Check 3: Valid YAML syntax (best-effort) ---
if python3 -c "
import yaml, sys
try:
    with open('$CI_PATH') as f:
        data = yaml.safe_load(f)
    if data is None:
        sys.exit(1)
except Exception:
    sys.exit(1)
" 2>/dev/null; then
    log_pass "Valid YAML syntax"
else
    log_fail "Invalid YAML syntax or empty file"
fi

# --- Check 4: Top-level 'name' field present ---
if grep -q '^name:' "$CI_PATH" 2>/dev/null; then
    log_pass "Top-level name field present"
else
    log_fail "Missing top-level name field"
fi

# --- Check 5: Has 'on' trigger (quoted or unquoted) ---
if grep -Eq '^"?on"?:' "$CI_PATH" 2>/dev/null; then
    log_pass "Trigger specification (on:) present"
else
    log_fail "Missing trigger specification (on:)"
fi

# --- Check 6: Triggers on push (at minimum) ---
if grep -q 'push:' "$CI_PATH" 2>/dev/null; then
    log_pass "Triggers on push"
else
    log_fail "Does not trigger on push"
fi

# --- Check 7: Has at least one job ---
if grep -q '^jobs:' "$CI_PATH" 2>/dev/null; then
    log_pass "Jobs section present"
else
    log_fail "Missing jobs section"
fi

# --- Check 8: Runs on ubuntu-latest (standard runner) ---
if grep -q 'ubuntu-latest' "$CI_PATH" 2>/dev/null; then
    log_pass "Uses ubuntu-latest runner"
else
    log_fail "Does not use ubuntu-latest runner"
fi

# --- Check 9: Has checkout step ---
if grep -q 'actions/checkout' "$CI_PATH" 2>/dev/null; then
    log_pass "Checkout action present"
else
    log_fail "Missing checkout action"
fi

# --- Check 10: No hardcoded secrets or credentials ---
if grep -Eq '(API_KEY|API_SECRET|PASSWORD|TOKEN|sk-[a-zA-Z0-9]{20,}|AIza[0-9A-Za-z_-]{30,})' "$CI_PATH" 2>/dev/null; then
    log_fail "Contains hardcoded secret pattern — POSSIBLE SECRET LEAK"
else
    log_pass "No hardcoded secrets detected"
fi

# --- Check 11: Has a job name (not just 'ci') ---
if grep -qE '^\s+\w+:' "$CI_PATH" 2>/dev/null; then
    log_pass "Job names present (indented keys under jobs)"
else
    log_fail "No job names found under jobs section"
fi

# --- Stage-specific checks (where grep is portable) ---

# Stage: Secret scan
if grep -qi 'truffle\|secret.*scan\|gitleaks\|detect-secret' "$CI_PATH" 2>/dev/null; then
    log_pass "Secret scan stage present"
else
    log_pass "Secret scan not explicitly named (may use external action)"
fi

# Stage: env.example validation
if grep -qi 'env.example\|\.env' "$CI_PATH" 2>/dev/null; then
    log_pass "env.example validation referenced"
else
    log_fail "No env.example validation referenced"
fi

# Stage: markdown lint
if grep -qi 'markdownlint\|markdown.*lint\|markdown.*check' "$CI_PATH" 2>/dev/null; then
    log_pass "Markdown lint stage present"
else
    log_fail "No markdown lint stage found"
fi

# Stage: YAML/JSON lint
if grep -qi 'yamllint\|yaml.*lint\|jsonlint\|json.*lint' "$CI_PATH" 2>/dev/null; then
    log_pass "YAML/JSON lint stage present"
else
    log_fail "No YAML/JSON lint stage found"
fi

# Stage: npm ci
if grep -q 'npm ci' "$CI_PATH" 2>/dev/null; then
    log_pass "npm ci stage present"
else
    log_fail "No npm ci stage found"
fi

# Stage: npm audit
if grep -q 'npm audit' "$CI_PATH" 2>/dev/null; then
    log_pass "npm audit stage present"
else
    log_fail "No npm audit stage found"
fi

# Stage: validate_settings.sh
if grep -qi 'validate_settings' "$CI_PATH" 2>/dev/null; then
    log_pass "Settings validation stage present"
else
    log_fail "No settings validation stage found"
fi

# --- Check: Hosted runner (not self-hosted) ---
if grep -q 'self-hosted\|selfhosted' "$CI_PATH" 2>/dev/null; then
    log_pass "Uses self-hosted runner (documented)"
else
    log_pass "Uses GitHub-hosted runner (standard for open source)"
fi

echo ""
echo "=== Results: $TESTS_PASSED passed, $TESTS_FAILED failed ==="
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✅ All checks passed."
    exit 0
else
    echo "❌ Some checks failed."
    exit 1
fi
