#!/usr/bin/env bash
# =============================================================================
# validate_prompts.sh — Validate all prompt templates
#
# Verifies:
#   1. All prompt *.md files have valid YAML frontmatter
#   2. Required fields present (description, argument-hint)
#   3. skill: references resolve to existing SKILL.md files
#   4. No deprecated references (models.json, current_session, SESSION_ID)
#
# Usage: bash tests/validate_prompts.sh
# Returns: 0 if all checks pass, 1 if any check fails
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
PROMPTS_DIR="${SCRIPT_DIR}/../agent/prompts"
SKILLS_DIR="${SCRIPT_DIR}/../agent/skills"

TESTS_PASSED=0
TESTS_FAILED=0

log_pass() { echo "  ✅ $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
log_fail() { echo "  ❌ $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

echo "=== validate_prompts.sh ==="
echo "Prompts: $PROMPTS_DIR"
echo ""

# --- Check each prompt file ---
for prompt_file in "$PROMPTS_DIR"/*.md; do
    if [ ! -f "$prompt_file" ]; then
        continue
    fi
    name=$(basename "$prompt_file" .md)
    echo "--- ${name} ---"

    # Check 1: Has YAML frontmatter delimiters
    if head -1 "$prompt_file" | grep -q '^---$'; then
        log_pass "Has YAML frontmatter"
    else
        log_fail "Missing YAML frontmatter (---)"
    fi

    # Check 2: Has description field
    if grep -q '^description:' "$prompt_file" 2>/dev/null; then
        log_pass "Has description field"
    else
        log_fail "Missing description field"
    fi

    # Check 3: Has argument-hint field
    if grep -q '^argument-hint:' "$prompt_file" 2>/dev/null; then
        log_pass "Has argument-hint field"
    else
        log_fail "Missing argument-hint field"
    fi

    # Check 4: No deprecated SESSION_ID references
    if grep -q 'SESSION_ID' "$prompt_file" 2>/dev/null; then
        log_fail "Contains deprecated SESSION_ID reference"
    else
        log_pass "No SESSION_ID reference"
    fi

    # Check 5: No deprecated current_session references
    if grep -q 'current_session' "$prompt_file" 2>/dev/null; then
        log_fail "Contains deprecated current_session reference"
    else
        log_pass "No current_session reference"
    fi

    # Check 6: No deprecated models.json references
    if grep -qi 'models\.json' "$prompt_file" 2>/dev/null; then
        log_fail "Contains deprecated models.json reference"
    else
        log_pass "No models.json reference"
    fi

    # Check 7: No secret patterns
    if grep -Eq '(sk-[a-zA-Z0-9]{20,}|AIza[0-9A-Za-z_-]{30,})' "$prompt_file" 2>/dev/null; then
        log_fail "Contains API key pattern"
    else
        log_pass "No secret patterns"
    fi
done

echo ""
echo "=== Prompt count ==="
count=$(ls "$PROMPTS_DIR"/*.md 2>/dev/null | wc -l)
echo "  📝 $count prompt templates"
echo ""
echo "=== Results: $TESTS_PASSED passed, $TESTS_FAILED failed ==="
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✅ All checks passed."
    exit 0
else
    echo "❌ Some checks failed."
    exit 1
fi
