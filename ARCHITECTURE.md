# ARCHITECTURE.md — pi-agent-enterprise

## 1. Overview

`pi-agent-enterprise` is a reusable, enterprise-grade configuration for [pi.dev](https://pi.dev), an AI-powered coding agent. It bundles prompt templates, domain-specific skills, and documentation to provide a production-ready agentic workflow out of the box.

## 2. Architecture

The project is structured around four bounded contexts:

```
┌──────────────────────────────────────────────────────────┐
│                   pi-agent-enterprise                     │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐         │
│  │  Templates │  │   Skills   │  │    Docs    │         │
│  │            │  │            │  │            │         │
│  │ init.md    │  │ security-  │  │ README.md  │         │
│  │ explore.md │  │ hardening  │  │ GUIDE.md   │         │
│  │ plan.md    │  │ testing-   │  │ AGENTS.md  │         │
│  │ execute.md │  │ standards  │  │ ARCHITECT- │         │
│  │ review.md  │  │ architect-  │  │ URE.md     │         │
│  │ test.md    │  │ ure-princ-  │  │ CONTRIB-   │         │
│  │ abort.md   │  │ iples       │  │ UTING.md   │         │
│  │ commit.md  │  │ laravel     │  │ CHANGELOG  │         │
│  │ rag-query  │  │ fastapi     │  │ CODE_OF_   │         │
│  └────────────┘  │ rag-query   │  │ CONDUCT.md │         │
│                  └────────────┘  └────────────┘         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐         │
│  │   Config   │  │  Security  │  │   CI/CD    │         │
│  │            │  │            │  │            │         │
│  │ settings.  │  │ .gitignore │  │ .github/   │         │
│  │ json       │  │ .gitattrib-│  │ workflows/ │         │
│  │ .env.exam- │  │ utes       │  │ .pre-comm- │         │
│  │ ple        │  │ CODEOWNERS │  │ it-config   │         │
│  └────────────┘  └────────────┘  └────────────┘         │
└──────────────────────────────────────────────────────────┘
```

## 3. Component Details

### 3.1 Prompt Templates (`agent/prompts/`)

Nine templates implement the full agentic workflow:

| Template | Model | Thinking | Skills | Purpose |
|----------|-------|----------|--------|---------|
| `init.md` | Flash | minimal | — | Environment bootstrap |
| `explore.md` | Flash | low | — | Codebase mapping |
| `plan.md` | Pro | xhigh | architecture, security, testing | Architecture design |
| `execute.md` | Flash | medium | security, testing, architecture | Implementation + TDD |
| `review.md` | Pro | high | security, testing, architecture | Code review + audit |
| `test.md` | Flash | low | testing, security | Test suite + coverage |
| `abort.md` | Flash | minimal | — | Rollback + cleanup |
| `commit.md` | Flash | minimal | — | Conventional commit |
| `rag-query.md` | Flash | low | rag-query | RAG documentation query |

All templates use `model:` frontmatter via `pi-prompt-template-model` extension.

### 3.2 Skills (`agent/skills/`)

Six domain-specific skills inject expertise into prompt templates:

| Skill | Domain | Type |
|-------|--------|------|
| `security-hardening` | OWASP, encryption, input validation | Mandatory for execute/review/plan |
| `testing-standards` | TDD, coverage, test quality | Mandatory for execute/test/review |
| `architecture-principles` | DDD, CQRS, event-driven | Mandatory for plan/review |
| `laravel-best-practices` | PHP/Laravel | Optional (Laravel projects) |
| `fastapi-best-practices` | Python/FastAPI | Optional (FastAPI projects) |
| `rag-query` | RAG server queries | Optional (RAG-enabled projects) |

### 3.3 Security Architecture

Layered defense for secret protection:

```
Layer 1: .gitignore         → Prevents accidental git add
Layer 2: .pre-commit        → detect-secrets + gitleaks
Layer 3: GitHub Actions CI  → trufflehog full-history scan
Layer 4: Branch protection  → Signed commits, PR review required
```

### 3.4 CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/ci.yml`):
- Secret scanning (trufflehog)
- `.env.example` contamination validation
- `.gitignore` integrity check
- Script GPG signature verification
- Settings validation
- SKILL.md schema validation
- GPG commit audit
- Markdown/YAML/JSON linting
- Dependency audit (`npm audit`, `pip check`)

## 4. RAG Integration (Optional)

The project includes a `rag-query` skill that connects to a local RAG (Retrieval-Augmented Generation) server for documentation context retrieval:

- **Server**: Docker-based, running on a separate node in the local network
- **Client**: `rag_client.py` — minimal Python script using `requests` + stdlib
- **Config**: `.env.example` provides connection parameters (`RAG_API_IP`, `RAG_API_PORT`)
- **Network**: All traffic stays within the local network — zero data leakage

The RAG server stack (not included in this repo — deployment is separate):
- FastAPI-based `rag-api` container
- Ollama container for local LLM/embedding models
- ChromaDB container for vector storage

## 5. Design Decisions

| Decision | Rationale |
|----------|-----------|
| MIT License | Permissive, compatible with all npm/pip dependencies |
| `auth.json` excluded | pi.dev internal file; users configure via `pi auth` |
| `.env` excluded | Contains user-specific network config |
| `*.jsonl` in `.gitignore` | Prevents accidental session log exposure |
| No `models.json` | Model config moved to prompt frontmatter (`model:` field) |
| GPG-signed commits | Required by branch protection (Phase 3) |
| npm shrinkwrap | Locks transitive dependencies for supply chain integrity |

## 6. Constraints

- **No cloud dependencies**: All components run locally (agent) or within the local network (RAG server)
- **Zero data leakage**: No API calls leave the user's environment
- **DeepSeek V4**: Current LLM provider; swappable via `settings.json`
- **pi.dev >=0.80**: Required for prompt-template-model extension support

---
*This document reflects the current architecture. Major changes require a PLAN.md update.*
