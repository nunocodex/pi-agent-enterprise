# pi-agent-enterprise

[![CI](https://github.com/nunocodex/pi-agent-enterprise/actions/workflows/ci.yml/badge.svg)](https://github.com/nunocodex/pi-agent-enterprise/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Enterprise-grade [pi.dev](https://pi.dev) agent configuration — 15 prompt templates, 20 integrated skills, and a complete CI pipeline for production AI-assisted development.

## Quick Start

```bash
git clone https://github.com/nunocodex/pi-agent-enterprise.git ~/.pi
pi auth add deepseek --key <your-deepseek-api-key>
cp .env.example .env        # Configure RAG server (optional)
bash setup.sh               # Python deps for RAG
cd agent/npm && npm ci      # npm extensions
cd ~/your-project && pi     # Start coding
```

## Workflow

```
brainstorm → plan → execute → test → commit
    ↑                           ↓
    │                      review → fix
    └─────────────── (pi.dev session) ─┘
```

All state flows through pi.dev's native session system. No temp files, no locks, no manual state management.

## Commands

### Core Pipeline (7)
| Command | Model | Thinking | Purpose |
|---------|-------|----------|---------|
| `/brainstorm` | Pro | xhigh | Creative analysis, design exploration |
| `/plan` | Pro | xhigh | Architecture, risk assessment, roadmap |
| `/execute` | Flash | medium | TDD implementation from plan |
| `/review` | Pro | high | Security audit, code review |
| `/test` | Flash | low | Full suite + coverage analysis |
| `/fix` | Flash | low | Autonomous fix loop (review → fix → verify) |
| `/commit` | Flash | minimal | Conventional commit + branch completion |

### Automation (2)
| Command | Model | Thinking | Purpose |
|---------|-------|----------|---------|
| `/workflow` | Pro | xhigh | Guided full pipeline (brainstorm → commit) |
| `/goal` | Pro | xhigh | Autonomous agent loop with review-fix |

### RAG (3)
| Command | Model | Purpose |
|---------|-------|---------|
| `/rag-query` | Default | Hybrid: local RAG + web collection search |
| `/rag-ingest` | Default | Upload local documentation to RAG |
| `/rag-url` | Default | Crawl + ingest web documentation |

### Utility (3)
| Command | Model | Thinking | Purpose |
|---------|-------|----------|---------|
| `/init` | Flash | minimal | Environment sanity check |
| `/explore` | Flash | low | Codebase mapping |
| `/abort` | Flash | minimal | Emergency rollback |

## Skills

**6 Custom Enterprise Skills:**
- **Security Hardening** — OWASP Top 10, input validation, encryption
- **Testing Standards** — TDD, coverage, test quality
- **Architecture Principles** — DDD, CQRS, event-driven design
- **Laravel Best Practices** — PHP/Laravel conventions
- **FastAPI Best Practices** — Python/FastAPI conventions
- **RAG Query** — Local knowledge base retrieval with hybrid search

**14 Superpowers Skills** (via git submodule):
brainstorming, writing-plans, executing-plans, subagent-driven-development, test-driven-development, dispatching-parallel-agents, systematic-debugging, receiving-code-review, requesting-code-review, verification-before-completion, finishing-a-development-branch, using-git-worktrees, using-superpowers, writing-skills

## Security

- **Zero secrets**: `auth.json`, `.env`, session logs excluded via `.gitignore`
- **Defense in depth**: `.gitignore` → pre-commit hooks → CI secret scan → branch protection
- **GPG-signed commits** on `main`
- **Supply chain**: `npm ci` + `--require-hashes` for pip + Dependabot
- **CI pipeline**: 11 stages (secret scan, .env validation, .gitignore integrity, GPG audit, markdown lint, YAML/JSON lint, npm audit)

## Directory Structure

```
pi-agent-enterprise/
├── agent/
│   ├── AGENTS.md              # Enterprise agent standards
│   ├── settings.json          # User preferences (no secrets)
│   ├── prompts/               # 15 prompt templates
│   ├── skills/                # 20 skills (6 custom + 14 symlinks)
│   ├── npm/                   # pi extension dependencies
│   ├── sessions/              # pi.dev managed conversation logs
│   └── git/                   # Superpowers submodule
├── .github/workflows/         # CI pipeline (11 stages)
├── tests/                     # 6 test suites (152+ assertions)
├── docs/specs/                # Design specifications
├── GUIDE.md                   # Enterprise guide (Italiano)
├── GUIDE.en.md                # Enterprise guide (English)
├── CONTRIBUTING.md            # How to contribute
├── SECURITY.md                # Vulnerability reporting
├── CHANGELOG.md               # Release history
└── README.md                  # This file
```

## Requirements

- [pi.dev](https://pi.dev) >= 0.80
- Node.js for npm extensions
- Python 3.11+ (for RAG skill only)
- DeepSeek API key (or OpenAI-compatible provider)
- [Obra Superpowers](https://github.com/obra/superpowers) submodule (auto-cloned)

## License

MIT — see [LICENSE](LICENSE) for details.
