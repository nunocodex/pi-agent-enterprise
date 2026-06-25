# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-25

### Added
- 9 prompt templates (`init`, `explore`, `plan`, `execute`, `review`, `test`, `commit`, `abort`, `rag-query`)
- 6 domain skills (security-hardening, testing-standards, architecture-principles, laravel-best-practices, fastapi-best-practices, rag-query)
- `.gitignore` with critical secret exclusion entries (S1, S2, S3)
- `.gitattributes` for export-ignore and script diff highlighting
- `.pre-commit-config.yaml` with detect-secrets, gitleaks, and formatting hooks
- `.env.example` at project root with contamination-scan header
- `ARCHITECTURE.md` — generalized system architecture documentation
- `GUIDE.md` — enterprise workflow guide for pi.dev with DeepSeek
- `AGENTS.md` — enterprise-grade agentic engineering standards
- `README.md` — project overview with quick start
- `CONTRIBUTING.md` — contribution guide with GPG signing setup
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1
- `SECURITY.md` — vulnerability reporting policy and disclosure process
- `CODEOWNERS` — maintainer enforcement for skills, prompts, and .gitignore
- `.github/PULL_REQUEST_TEMPLATE.md` — mandatory skill/prompt review checkbox
- `tests/validate_gitignore.sh` — 19 structural validation tests for .gitignore
- `tests/validate_settings.sh` — settings.json consistency validation
- `setup.sh` and `rag_client.py` with GPG detached signatures
- `npm-shrinkwrap.json` for transitive dependency locking
- `LICENSE` — MIT

### Security
- Layered defense: `.gitignore` → pre-commit → CI trufflehog → branch protection
- Zero secrets in repo: `auth.json`, `.env`, `agent/sessions/` excluded
- GPG-signed commits required for `main` branch
- Supply chain hardening: `npm ci`, `pip --require-hashes`, Dependabot
- `.env.example` contamination scan in CI
- `.gitignore` integrity validation in CI

[1.0.0]: https://github.com/nunocodex/pi-agent-enterprise/releases/tag/v1.0.0
