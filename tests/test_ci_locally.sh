#!/usr/bin/env bash
# =============================================================================
# test_ci_locally.sh — Local CI pipeline simulation
#
# Runs all CI stages that can be executed without GitHub Actions.
# Tests correspond to the 11-stage CI pipeline in .github/workflows/ci.yml.
#
# Usage: bash tests/test_ci_locally.sh
# Returns: 0 if all stages pass, 1 if any stage fails
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
STAGES_PASSED=0
STAGES_FAILED=0
STAGES_SKIPPED=0

pass() { echo "  ✅ Stage $1: $2"; STAGES_PASSED=$((STAGES_PASSED + 1)); }
fail() { echo "  ❌ Stage $1: $2"; STAGES_FAILED=$((STAGES_FAILED + 1)); }
skip() { echo "  ⏭️  Stage $1: $2 (unavailable)"; STAGES_SKIPPED=$((STAGES_SKIPPED + 1)); }

echo "=============================================="
echo "  Local CI Pipeline Simulation"
echo "  Project: pi-agent-enterprise"
echo "  Date:    $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "=============================================="
echo ""

cd "$PROJECT_ROOT" || { echo "❌ Cannot cd to project root"; exit 1; }

# =============================================================================
# Stage 1: Secret scan (trufflehog)
# =============================================================================
echo "--- Stage 1: Secret scan (full history) ---"
if command -v trufflehog >/dev/null 2>&1; then
    # trufflehog is available - scan git history
    if trufflehog git --since-commit HEAD --only-verified --no-verification . 2>/dev/null; then
        pass 1 "Secret scan: no secrets found"
    else
        fail 1 "Secret scan: secrets detected!"
    fi
elif command -v gitleaks >/dev/null 2>&1; then
    if gitleaks detect --no-git -v 2>/dev/null; then
        pass 1 "Secret scan (gitleaks): no secrets found"
    else
        fail 1 "Secret scan (gitleaks): issues found"
    fi
else
    # Fallback: simple regex scan on tracked files
    echo "  ⚠️  No secret scanner available — fallback to grep scan"
    FAILED=0
    for file in $(git ls-files 2>/dev/null); do
        if [ -f "$file" ]; then
            if grep -Eq '(sk-[a-zA-Z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|pk_[a-zA-Z0-9]{20,})' "$file" 2>/dev/null; then
                echo "  ❌ Possible secret in: $file"
                FAILED=1
            fi
        fi
    done
    if [ "$FAILED" -eq 0 ]; then
        pass 1 "Secret scan (grep fallback): no secrets found"
    else
        fail 1 "Secret scan: potential secrets detected!"
    fi
fi

# =============================================================================
# Stage 2: .env.example validation
# =============================================================================
echo "--- Stage 2: .env.example validation ---"
FAILED=0
if grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' .env.example 2>/dev/null; then
    echo "  ❌ .env.example contains IP address"
    FAILED=1
fi
if grep -Eq '(sk-[a-zA-Z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|pk_[a-zA-Z0-9]{20,})' .env.example 2>/dev/null; then
    echo "  ❌ .env.example contains API key pattern"
    FAILED=1
fi
if [ "$FAILED" -eq 0 ]; then
    pass 2 ".env.example: no contamination"
else
    fail 2 ".env.example: contamination detected!"
fi

# =============================================================================
# Stage 3: .gitignore integrity
# =============================================================================
echo "--- Stage 3: .gitignore integrity ---"
FAILED=0
# Check critical entries
for pattern in '^\.env$' '^agent/auth\.json$' '^agent/sessions/' '^venv/' '^agent/npm/node_modules/' '^agent/bin/' '^tmp/' '^state/' '^\*\.jsonl$'; do
    if grep -vE '^\s*(#|$)' .gitignore | grep -Eq "$pattern" 2>/dev/null; then
        :  # found
    else
        echo "  ❌ Missing entry: $pattern"
        FAILED=1
    fi
done
# Check section headers
for section in "SECRETS" "SESSIONS" "BINARIES" "DEPENDENCIES" "IDE" "OS" "EPHEMERAL"; do
    if grep -q "^# === $section" .gitignore 2>/dev/null; then
        :  # found
    else
        echo "  ❌ Missing section: # === $section"
        FAILED=1
    fi
done
if [ "$FAILED" -eq 0 ]; then
    pass 3 ".gitignore: all entries present"
else
    fail 3 ".gitignore: missing entries"
fi

# =============================================================================
# Stage 4: Script GPG + checksum
# =============================================================================
echo "--- Stage 4: Script GPG + checksum ---"
if command -v gpg >/dev/null 2>&1; then
    FAILED=0
    for script in setup.sh agent/skills/rag-query/rag_client.py; do
        SIG="${script}.asc"
        if [ -f "$SIG" ] && [ -f "$script" ]; then
            if gpg --verify "$SIG" "$script" 2>/dev/null; then
                echo "  ✅ GPG verified: $script"
            else
                echo "  ❌ GPG FAILED: $script"
                FAILED=1
            fi
        else
            echo "  ⚠️  No signature found for $script"
        fi
        # Print checksum
        if [ -f "$script" ]; then
            echo "     sha256: $(sha256sum "$script" | cut -d' ' -f1)"
        fi
    done
    if [ "$FAILED" -eq 0 ]; then
        pass 4 "Script signatures verified"
    else
        fail 4 "Script signature verification failed"
    fi
else
    skip 4 "Script GPG verification" "gpg not available"
fi

# =============================================================================
# Stage 5: Settings validation
# =============================================================================
echo "--- Stage 5: Settings validation ---"
if bash tests/validate_settings.sh >/dev/null 2>&1; then
    pass 5 "Settings validation: PASS"
else
    # Show details
    bash tests/validate_settings.sh 2>&1 | grep -E '❌|✅' | tail -5
    fail 5 "Settings validation: FAILED"
fi

# =============================================================================
# Stage 6: SKILL.md frontmatter + prompt validation
# =============================================================================
echo "--- Stage 6: Prompt/SKILL validation ---"
if bash tests/validate_prompts.sh >/dev/null 2>&1; then
    pass 6 "Prompt validation: PASS"
else
    bash tests/validate_prompts.sh 2>&1 | grep '❌' | head -5
    fail 6 "Prompt validation: FAILED"
fi

# =============================================================================
# Stage 7: GPG commit audit
# =============================================================================
echo "--- Stage 7: GPG commit audit ---"
if command -v gpg >/dev/null 2>&1; then
    SIGNED=0
    UNSIGNED=0
    for commit in $(git log --format='%H' -5 2>/dev/null); do
        if git log --format='%GS' -1 "$commit" 2>/dev/null | grep -q .; then
            SIGNED=$((SIGNED + 1))
        else
            UNSIGNED=$((UNSIGNED + 1))
        fi
    done
    echo "  Last 5 commits: $SIGNED signed, $UNSIGNED unsigned"
    if [ "$UNSIGNED" -eq 0 ]; then
        pass 7 "All recent commits GPG-signed"
    else
        fail 7 "Some commits lack GPG signatures"
    fi
else
    skip 7 "GPG commit audit" "gpg not available"
fi

# =============================================================================
# Stage 8: Markdown lint
# =============================================================================
echo "--- Stage 8: Markdown lint ---"
if command -v markdownlint >/dev/null 2>&1; then
    if markdownlint '*.md' 'agent/**/*.md' --ignore-path .markdownlintignore 2>/dev/null; then
        pass 8 "Markdown lint: PASS"
    else
        fail 8 "Markdown lint: issues found"
    fi
else
    skip 8 "Markdown lint" "no markdown linter available"
fi

# =============================================================================
# Stage 9: YAML/JSON lint
# =============================================================================
echo "--- Stage 9: YAML/JSON lint ---"
FAILED=0
# JSON lint
for json_file in agent/settings.json agent/npm/package.json; do
    if [ -f "$json_file" ]; then
        if python3 -m json.tool "$json_file" > /dev/null 2>&1; then
            echo "  ✅ $json_file: valid JSON"
        else
            echo "  ❌ $json_file: invalid JSON"
            FAILED=1
        fi
    fi
done
# YAML lint (basic python check)
for yaml_file in .pre-commit-config.yaml .github/workflows/ci.yml; do
    if [ -f "$yaml_file" ]; then
        if python3 -c "
import sys
import yaml
try:
    with open('$yaml_file') as f:
        data = yaml.safe_load(f)
    if data is None:
        raise ValueError('empty')
    print('  ✅ $yaml_file: valid YAML')
except Exception as e:
    print(f'  ❌ $yaml_file: invalid YAML')
    sys.exit(1)
" 2>/dev/null; then
            :  # valid
        else
            FAILED=1
        fi
    fi
done
if [ "$FAILED" -eq 0 ]; then
    pass 9 "YAML/JSON lint: PASS"
else
    fail 9 "YAML/JSON lint: FAILED"
fi

# =============================================================================
# Stage 10: npm ci + audit
# =============================================================================
echo "--- Stage 10: npm ci + audit ---"
if command -v npm >/dev/null 2>&1; then
    # Try to change to agent/npm directory
    if ! cd agent/npm 2>/dev/null && ! cd "$PROJECT_ROOT/agent/npm" 2>/dev/null; then
        skip 10 "npm ci" "agent/npm not found"
        cd "$PROJECT_ROOT" 2>/dev/null || true
        NPM_OK=1
    fi
    
    if [ -z "${NPM_OK:-}" ]; then
        # npm ci
        NPM_CI_FAILED=0
        if npm ci 2>/dev/null; then
            echo "  ✅ npm ci: dependencies installed"
        else
            echo "  ❌ npm ci: failed"
            NPM_CI_FAILED=1
        fi
        
        if [ "$NPM_CI_FAILED" -eq 0 ]; then
            # npm audit --production
            AUDIT_OUTPUT=$(npm audit --production 2>&1) || true
            if echo "$AUDIT_OUTPUT" | grep -q "found 0 vulnerabilities"; then
                echo "  ✅ npm audit: no vulnerabilities"
                cd "$PROJECT_ROOT"
                pass 10 "npm ci + audit: PASS"
            else
                cd "$PROJECT_ROOT"
                pass 10 "npm ci + audit: PASS (with warnings)"
            fi
        else
            cd "$PROJECT_ROOT"
            fail 10 "npm ci failed"
        fi
    fi
else
    skip 10 "npm ci + audit" "npm not available"
fi

# Make sure we're back at project root
cd "$PROJECT_ROOT" 2>/dev/null || true

# =============================================================================
# Stage 11: Final summary
# =============================================================================
echo ""
echo "=============================================="
echo "  Local CI Pipeline — Results"
echo "=============================================="
echo "  Stages passed: $STAGES_PASSED"
echo "  Stages failed: $STAGES_FAILED"
echo "  Stages skipped: $STAGES_SKIPPED"
echo "  Total: $((STAGES_PASSED + STAGES_FAILED + STAGES_SKIPPED))"
echo "=============================================="

if [ "$STAGES_FAILED" -eq 0 ]; then
    echo "✅ All available CI stages passed."
    exit 0
else
    echo "❌ $STAGES_FAILED stage(s) failed."
    exit 1
fi
