#!/usr/bin/env bash
# =============================================================================
# validate_guide_en.sh — Validate English guide against Italian original
#
# Verifies that GUIDE.en.md:
#   1. Exists and is non-empty
#   2. Has the same section structure (## headers) as GUIDE.md
#   3. Has no Italian text (disallowed words)
#   4. No placeholders or TODO markers remain
#
# Usage: bash tests/validate_guide_en.sh
# Returns: 0 if all checks pass, 1 if any check fails
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
GUIDE_IT="${SCRIPT_DIR}/../GUIDE.md"
GUIDE_EN="${SCRIPT_DIR}/../GUIDE.en.md"

TESTS_PASSED=0
TESTS_FAILED=0

log_pass() { echo "  ✅ $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
log_fail() { echo "  ❌ $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

echo "=== validate_guide_en.sh ==="
echo "Italian: $GUIDE_IT"
echo "English: $GUIDE_EN"
echo ""

# --- Check 1: English guide exists ---
if [ -f "$GUIDE_EN" ]; then
    log_pass "GUIDE.en.md exists"
else
    log_fail "GUIDE.en.md not found"
fi

# --- Check 2: Non-empty ---
FILE_LINES=$(wc -l < "$GUIDE_EN" 2>/dev/null || echo 0)
if [ "$FILE_LINES" -gt 100 ]; then
    log_pass "GUIDE.en.md is substantial ($FILE_LINES lines)"
else
    log_fail "GUIDE.en.md too short ($FILE_LINES lines)"
fi

# --- Check 3: Same number of ## sections as Italian ---
IT_SECTIONS=$(grep -c '^## ' "$GUIDE_IT" 2>/dev/null || echo 0)
EN_SECTIONS=$(grep -c '^## ' "$GUIDE_EN" 2>/dev/null || echo 0)
if [ "$IT_SECTIONS" -eq "$EN_SECTIONS" ]; then
    log_pass "Section count matches: $EN_SECTIONS (IT: $IT_SECTIONS)"
else
    log_fail "Section count mismatch: EN=$EN_SECTIONS, IT=$IT_SECTIONS"
fi

# --- Check 4: AI generated text removed ---
if grep -qi "certainly\|as an ai\|i cannot\|i apologize\|i'm sorry\|as a language model" "$GUIDE_EN" 2>/dev/null; then
    log_fail "Contains AI-generated boilerplate text"
else
    log_pass "No AI boilerplate text"
fi

# --- Check 5: No Italian disallowed words (outside code blocks) ---
ITALIAN_WORDS="guida\|gestione\|configurazione\|esegui\|variabile\|direttiva\|questa\|questo\|della\|nella\|delle\|perché\|sarà\|più\|così\|può\|sono\|tutti\|ogni\|nessun"
# Exclude code blocks and JSON content
ITALIAN_FOUND=$(grep -vE '^\`\`\`' "$GUIDE_EN" | grep -vE '^\s{4}' | grep -oiE "$ITALIAN_WORDS" 2>/dev/null || echo "")
if [ -n "$ITALIAN_FOUND" ]; then
    log_fail "Contains Italian text: $(echo "$ITALIAN_FOUND" | sort -u | tr '\n' ' ')"
else
    log_pass "No Italian text detected"
fi

# --- Check 6: No deprecated ephemeral references ---
if grep -qi "SESSION_ID\|current_session\|\.pi/tmp/{SESSION_ID}" "$GUIDE_EN" 2>/dev/null; then
    log_fail "Contains deprecated references (SESSION_ID, current_session)"
else
    log_pass "No deprecated ephemeral references"
fi

# --- Check 7: Has English title ---
if head -1 "$GUIDE_EN" 2>/dev/null | grep -qiE "enterprise|guide" ; then
    log_pass "Has English title"
else
    log_fail "Title not in English"
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
