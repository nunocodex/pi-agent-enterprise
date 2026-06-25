#!/usr/bin/env bash
# =============================================================================
# validate_settings.sh — Structural validation test for agent/settings.json
#
# Verifies:
#   1. settings.json exists and is valid JSON
#   2. Contains no secrets (API keys, tokens, IPs)
#   3. defaultThinkingLevel matches GUIDE.md documented value ("xhigh")
#   4. Required fields are present
#
# Usage: bash validate_settings.sh
# Returns: 0 if all checks pass, 1 if any check fails
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
SETTINGS_PATH="${1:-$SCRIPT_DIR/../agent/settings.json}"
GUIDE_PATH="$SCRIPT_DIR/../GUIDE.md"

TESTS_PASSED=0
TESTS_FAILED=0

log_pass() { echo "  ✅ $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
log_fail() { echo "  ❌ $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

echo "=== validate_settings.sh ==="
echo "Settings: $SETTINGS_PATH"
echo "Guide:    $GUIDE_PATH"
echo ""

# --- Check 1: File exists ---
if [ -f "$SETTINGS_PATH" ]; then
    log_pass "settings.json exists"
else
    log_fail "settings.json not found"
fi

# --- Check 2: Valid JSON ---
if python3 -m json.tool "$SETTINGS_PATH" >/dev/null 2>&1 || \
   node -e "JSON.parse(require('fs').readFileSync('$SETTINGS_PATH','utf8'))" 2>/dev/null; then
    log_pass "Valid JSON syntax"
else
    log_fail "Invalid JSON syntax"
fi

# --- Check 3: No secrets (API key patterns) ---
if grep -Eq '(sk-[a-zA-Z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|pk_[a-zA-Z0-9]{20,}|Bearer [a-zA-Z0-9_-]{20,})' "$SETTINGS_PATH" 2>/dev/null; then
    log_fail "Contains API key pattern — POSSIBLE SECRET LEAK"
else
    log_pass "No API key patterns detected"
fi

# --- Check 4: No IP addresses ---
if grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$SETTINGS_PATH" 2>/dev/null; then
    log_fail "Contains IP address pattern — possible network data leak"
else
    log_pass "No IP address patterns detected"
fi

# --- Check 5: defaultThinkingLevel matches GUIDE.md ---
ACTUAL_LEVEL=$(grep -oP '"defaultThinkingLevel"\s*:\s*"\K[^"]+' "$SETTINGS_PATH" 2>/dev/null || echo "NOT_FOUND")

# GUIDE.md documents "xhigh" as the thinking level for plan + review
if grep -q 'xhigh' "$GUIDE_PATH" 2>/dev/null && [ "$ACTUAL_LEVEL" = "xhigh" ]; then
    log_pass "defaultThinkingLevel: $ACTUAL_LEVEL (matches GUIDE.md: xhigh)"
elif [ "$ACTUAL_LEVEL" = "NOT_FOUND" ]; then
    log_fail "defaultThinkingLevel field not found in settings.json"
else
    log_fail "defaultThinkingLevel: settings.json=$ACTUAL_LEVEL, expected=xhigh (per GUIDE.md)"
fi

# --- Check 6: Required fields present ---
for field in '"defaultProvider"' '"defaultModel"' '"theme"' '"packages"'; do
    if grep -q "$field" "$SETTINGS_PATH" 2>/dev/null; then
        log_pass "Required field: $field"
    else
        log_fail "Missing required field: $field"
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
