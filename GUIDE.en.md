# Enterprise Guide for pi.dev with DeepSeek

This guide provides a comprehensive reference for using pi.dev with DeepSeek models (V4-Pro and V4-Flash) in an enterprise workflow, integrating skills and best practices.

---

## 1. Configuration

### 1.1 Model Setup

Add DeepSeek models via `pi auth` or configure `~/.pi/agent/models.json`:

```json
{
  "providers": {
    "deepseek": {
      "baseUrl": "https://api.deepseek.com",
      "api": "openai-completions",
      "apiKey": "$DEEPSEEK_API_KEY",
      "models": [
        {
          "id": "deepseek-v4-pro",
          "name": "DeepSeek V4 Pro",
          "contextWindow": 1000000,
          "maxTokens": 384000,
          "input": ["text"],
          "reasoning": true,
          "compat": {
            "requiresReasoningContentOnAssistantMessages": true,
            "thinkingFormat": "deepseek",
            "reasoningEffortMap": {
              "minimal": "high",
              "low": "high",
              "medium": "high",
              "high": "high",
              "xhigh": "max"
            }
          }
        },
        {
          "id": "deepseek-v4-flash",
          "name": "DeepSeek V4 Flash",
          "contextWindow": 1000000,
          "maxTokens": 384000,
          "input": ["text"],
          "reasoning": true,
          "compat": {
            "requiresReasoningContentOnAssistantMessages": true,
            "thinkingFormat": "deepseek",
            "reasoningEffortMap": {
              "minimal": "high",
              "low": "high",
              "medium": "high",
              "high": "high",
              "xhigh": "max"
            }
          }
        }
      ]
    }
  }
}
```

### 1.2 Environment Variable

Set the environment variable:

```bash
export DEEPSEEK_API_KEY="<your-deepseek-api-key>"
```

### 1.3 Frontmatter Extension

To enable `model`, `thinking`, and `skill` fields in prompt templates:

```bash
pi install npm:pi-prompt-template-model
```

Restart pi to load the extension.

---

## 2. Skill Configuration

### 2.1 Directory Structure

```bash
mkdir -p ~/.pi/agent/skills
```

### 2.2 Available Skills

| Skill | File | Description | Application |
|-------|------|-------------|-------------|
| **Security Hardening** | `security-hardening.md` | OWASP Top 10, input validation, encryption, authentication | Required for `/execute`, `/review`, `/plan` |
| **Testing Standards** | `testing-standards.md` | TDD, coverage, test quality, mocking | Required for `/execute`, `/test`, `/review` |
| **Architecture Principles** | `architecture-principles.md` | DDD, event-driven, CQRS, microservices | Required for `/plan`, `/review` |
| **Laravel Best Practices** | `laravel-best-practices.md` | PHP/Laravel specific (Eloquent, Services, Controllers) | Laravel projects in `/execute` |
| **FastAPI Best Practices** | `fastapi-best-practices.md` | Python/FastAPI specific (async, Pydantic, SQLAlchemy) | FastAPI projects in `/execute` |

### 2.3 Creating Skills

Copy each skill file to `~/.pi/agent/skills/`:

```
~/.pi/agent/skills/
├── security-hardening.md
├── testing-standards.md
├── architecture-principles.md
├── laravel-best-practices.md
└── fastapi-best-practices.md
```

---

## 3. Prompt Templates

### 3.1 Command Reference

| Command | Phase | Purpose |
|---------|-------|---------|
| `/init` | Bootstrap | Environment sanity check |
| `/explore` | Analysis | Codebase mapping with cache |
| `/brainstorm` | Design | Creative analysis, design exploration |
| `/plan` | Planning | Architecture design, risk assessment |
| `/execute` | Implementation | TDD: code + tests |
| `/review` | Quality | Code review, security audit |
| `/test` | Verification | Full test suite, coverage analysis |
| `/fix` | Correction | Fix loop: test → review → fix → verify |
| `/commit` | Delivery | Conventional commit |
| `/abort` | Recovery | Emergency rollback |
| `/rag-query` | Search | Hybrid RAG query (local + web) |
| `/rag-ingest` | Ingestion | Local documentation upload |
| `/rag-url` | Crawling | Web documentation crawl + ingest |
| `/workflow` | Pipeline | Full guided pipeline (7 phases) |

### 3.2 Workflow Pipeline

```
brainstorm → plan → execute → test → commit
    ↑                           ↓
    │                      review → fix
    └─────────────── (pi.dev session) ─┘
```

All state flows through the pi.dev session. No files are written.

### 3.3 Frontmatter Example

For `/execute`:

```yaml
---
description: Activate execution mode — implement code and tests simultaneously
argument-hint: "[target-component]"
model: deepseek/deepseek-v4-flash
thinking: medium
skill: rag-query
restore: true
---
```

---

## 4. Enterprise Workflow

### 4.1 Complete Development Cycle

1. **Initialize Session**
   ```
   /init
   ```
   Verifies environment (PHP, Node, Docker).

2. **Explore Codebase**
   ```
   /explore
   ```
   Maps directory structure, entry points, dependencies.

3. **Brainstorm**
   ```
   /brainstorm "Add Stripe payment processing"
   ```
   Creative analysis with clarifying questions and design exploration. Saves design spec to `docs/specs/`.

4. **Plan**
   ```
   /plan "Payment processing with Stripe"
   ```
   Reads brainstorm context from session. Creates structured plan in session.

5. **Execute Tasks**
   ```
   /execute PaymentService
   ```
   Reads plan from session. Implements using TDD (test first → fail → pass). Marks task completed in session.

6. **Code Review**
   ```
   /review src/PaymentService.php
   ```
   Read-only analysis. Output: issues with severity, file, line, suggested fix.

7. **Run Tests**
   ```
   /test
   ```
   Runs full suite with coverage analysis.

8. **Fix Loop** (if tests fail)
   ```
   /fix
   ```
   Root cause → fix → verify (max 5 cycles).

9. **Commit**
   ```
   /commit
   ```
   Analyzes diff, generates conventional commit. Verifies tests via `/test`.

10. **Rollback** (if needed)
    ```
    /abort
    ```
    Removes scratch files, reverts git. Session history preserved at `~/.pi/agent/sessions/`.

### 4.2 Context and Cost Management

| Model | Cost (input/output per 1M tokens) | Usage |
|-------|-----------------------------------|-------|
| DeepSeek V4 Pro | $1.74 / $3.48 | `/plan`, `/review`, `/brainstorm` |
| DeepSeek V4 Flash | $0.14 / $0.28 | `/execute`, `/test`, `/fix`, `/explore` |

**Recommendation**: Use Flash for most operations. Use Pro only for planning and review.

### 4.3 CI/CD Integration

- **Pre-commit gate**: `/test` must pass before `/commit` can proceed.
- **Pipeline**: `.github/workflows/ci.yml` — 11 stages including secret scan, linting, npm audit.
- **Local CI**: `bash tests/test_ci_locally.sh` — 10 stages, runs without GitHub.

---

## 5. Directory Structure

### 5.1 Global (`~/.pi/`)

```
~/.pi/
├── agent/
│   ├── AGENTS.md           # Enterprise agent standards
│   ├── auth.json            # Provider API keys (gitignored)
│   ├── models.json          # Custom provider config
│   ├── prompts/             # Prompt templates (14 commands)
│   ├── skills/              # Domain skills (6 custom + 14 superpowers)
│   ├── sessions/            # Conversation logs (pi.dev managed)
│   └── npm/                 # Extension dependencies
├── requirements.txt         # Python deps for RAG client
├── setup.sh                 # Python venv bootstrap
└── ...
```

### 5.2 Per Project (`.pi/`)

```
.pi/
├── tmp/                     # Scratch directory (cache only)
│   ├── cache/               # Explore cache (TTL: 1h)
│   └── coverage/            # Raw coverage data
├── .env                     # RAG server config (gitignored)
├── .gitignore               # Secrets and artifacts excluded
├── .github/workflows/       # CI pipeline
└── docs/specs/              # Design specs
```

All command state is managed by pi.dev sessions. No state files on disk.

---

## 6. Best Practices

### 6.1 Essential Commands

- `/init` — Start a session
- `/explore` — Map codebase
- `/brainstorm "feature"` — Explore design
- `/plan "feature"` — Create structured plan
- `/execute [task]` — Implement (default: next task)
- `/review [target]` — Code review (default: entire project)
- `/test` — Run test suite
- `/fix` — Fix loop
- `/commit` — Generate commit message
- `/abort` — Emergency rollback
- `/workflow "feature"` — Full guided pipeline

### 6.2 Feedback Cycle

- After `/execute`, review the DoD checklist.
- Use `/test` before every `/commit` (hard gate prevents broken commits).
- Use `/fix` to address test failures systematically (root cause → fix → verify).
- Use `/abort` if context degrades or session needs cleanup.

### 6.3 Extensibility

- **Add new skills**: Create `.md` or symlink to `agent/skills/` and reference in frontmatter `skill:` field.
- **Modify prompt templates**: Edit files in `agent/prompts/`.
- **Add custom providers**: Configure models via `pi auth` or `agent/models.json`.

---

## 7. Troubleshooting

### 7.1 Error: "No available model"

Verify the model is configured in `agent/models.json` or `pi auth`. Run `/model` to reload.

### 7.2 Error: "Test suite fails — halting"

Run `/fix` to enter the fix loop, or inspect individual failures:
```bash
bash tests/validate_settings.sh
bash tests/test_ci_locally.sh
```

### 7.3 Error: "RAG server unreachable"

Check the RAG server connection in `.env`:
```bash
curl http://192.168.1.2:8080/health
```

### 7.4 Error: "Skill not found"

Verify the skill exists in `agent/skills/`. Symlinks to superpowers skills are resolved automatically. Run `/init` to refresh.

---

## 8. References

- [pi.dev Documentation](https://pi.dev/docs/latest)
- [DeepSeek API Documentation](https://api-docs.deepseek.com)
- [pi-prompt-template-model Extension](https://www.npmjs.com/package/pi-prompt-template-model)
- [Obra Superpowers Skills](https://github.com/obra/superpowers)
- [GitHub Repository](https://github.com/nunocodex/pi-agent-enterprise)

---

*This guide is a living document. Update it as the workflow evolves.*
