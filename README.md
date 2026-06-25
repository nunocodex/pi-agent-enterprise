# pi-agent-enterprise

[![CI](https://github.com/nunocodex/pi-agent-enterprise/actions/workflows/ci.yml/badge.svg)](https://github.com/nunocodex/pi-agent-enterprise/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Enterprise-grade [pi.dev](https://pi.dev) agent configuration — prompt templates, domain skills, and security hardening for production AI-assisted development.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/nunocodex/pi-agent-enterprise.git ~/.pi

# 2. Configure providers (pi.dev manages auth internally)
pi auth add deepseek --key <your-deepseek-api-key>

# 3. Configure RAG server (optional)
cp .env.example .env
# Edit .env with your RAG server IP and port

# 4. Install Python dependencies for RAG skill
bash setup.sh

# 5. Install npm extensions
cd agent/npm && npm ci

# 6. Start coding with enterprise standards
cd ~/your-project && pi
```

## What's Included

### Prompt Templates (9)
Command flow: `init` → `explore` → `plan` → `execute` → `review` → `test` → `commit`

| Command | Model | Purpose |
|---------|-------|---------|
| `/init` | Flash | Environment bootstrap |
| `/explore` | Flash | Codebase mapping (1h cache) |
| `/plan` | Pro (xhigh) | Architecture + risk assessment |
| `/execute` | Flash (medium) | TDD implementation |
| `/review` | Pro (high) | Security audit + code review |
| `/test` | Flash (low) | Test suite + coverage |
| `/commit` | Flash (minimal) | Conventional commit message |
| `/abort` | Flash (minimal) | Rollback + cleanup |

### Skills (6)
- **Security Hardening** — OWASP Top 10, input validation, encryption
- **Testing Standards** — TDD, 100% coverage, test quality
- **Architecture Principles** — DDD, CQRS, event-driven design
- **Laravel Best Practices** — PHP/Laravel conventions
- **FastAPI Best Practices** — Python/FastAPI conventions
- **RAG Query** — Local knowledge base retrieval

## Security

- **Zero secrets in repo**: `auth.json`, `.env`, session logs excluded via `.gitignore`
- **Defense in depth**: `.gitignore` → pre-commit hooks → CI secret scan → branch protection
- **GPG-signed commits** required on `main`
- **Supply chain hardening**: `npm ci` + `--require-hashes` for pip + Dependabot

Report vulnerabilities via `SECURITY.md`.

## Directory Structure

```
pi-agent-enterprise/
├── agent/
│   ├── AGENTS.md              # Enterprise agent standards
│   ├── settings.json          # User preferences (no secrets)
│   ├── prompts/               # 9 prompt templates
│   ├── skills/                # 6 domain skills
│   └── npm/                   # pi extension dependencies
├── .github/workflows/         # CI/CD pipeline
├── .gitignore                 # Secret exclusion
├── .pre-commit-config.yaml    # Local security hooks
├── ARCHITECTURE.md            # System architecture
├── GUIDE.md                   # Enterprise workflow guide
├── CONTRIBUTING.md            # How to contribute
├── SECURITY.md                # Vulnerability reporting
├── CHANGELOG.md               # Release history
├── CODE_OF_CONDUCT.md         # Contributor covenant
├── LICENSE                    # MIT
└── README.md                  # This file
```

## Requirements

- [pi.dev](https://pi.dev) >= 0.80
- Node.js for npm extensions
- Python 3.11+ (for RAG skill only)
- DeepSeek API key (or any OpenAI-compatible provider)

## License

MIT — see [LICENSE](LICENSE) for details.
