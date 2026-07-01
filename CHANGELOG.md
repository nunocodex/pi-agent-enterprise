# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-07-01

### Added

- `/brainstorm` command — creative analysis with clarifying questions and design spec output
- `/fix` command — autonomous fix loop (review → root cause → fix → verify)
- `/workflow` command — guided full pipeline (brainstorm → plan → execute → test → review → fix → commit)
- `/goal` command — autonomous agent loop with review-fix for achieving objectives
- `/rag-ingest` command — local documentation upload to RAG server
- `/rag-url` command — web documentation crawl + ingest + refresh
- 14 superpowers skills integrated via symlinks and git submodule
- `rag_client.py` extended: ingest_url, crawl_and_ingest, upload_file, ingest_directory, refresh_index, document_status
- `.github/workflows/ci.yml` — 11-stage CI pipeline (secret scan, env validation, markdown lint, npm audit, etc.)
- `tests/test_ci_locally.sh` — local CI simulation (10 stages)
- `tests/validate_ci_workflow.sh` — CI workflow structural validation (19 assertions)
- `tests/validate_prompts.sh` — prompt template validation (105 assertions)
- `tests/validate_guide_en.sh` — English guide validation (7 assertions)
- `GUIDE.en.md` — full English translation of enterprise guide
- `.markdownlint.json` and `.markdownlintignore` — markdown lint configuration
- `docs/specs/` — design specification directory
- Ollama provider support via `models.json`
- Hybrid RAG query (local + web collection)

### Changed

- Session system: migrated from custom ephemeral workspace to pi.dev native sessions
- Removed `.pi/state/` directory — all state flows through pi.dev session
- Removed `SESSION_ID`, `current_session`, lock files, TTL policies
- Updated all 9 original prompts to session-driven design (no file writes)
- Updated `/plan`: plan lives in session, not on disk
- Updated `/execute`: reads plan from session, not PLAN.md
- Updated `/review` and `/test`: output in session, no `.pi/tmp/*.json` files
- Updated `/commit`: added finishing-a-development-branch + verification-before-completion skills
- Updated `/rag-query`: hybrid search combining local RAG + web collection
- `GUIDE.md` (Italian) kept as reference; GUIDE.en.md is canonical English version
- `README.md` updated with 15 commands, workflow diagram, 20 skills
- All prompts: removed stale `.pi/state/`, `PLAN.md`, `SESSION_ID` references

### Fixed

- `settings.json` defaultThinkingLevel changed from "high" to "xhigh"
- `rag-query.md` missing argument-hint field
- Markdown lint issues in prompt templates
- npm-shrinkwrap.json out of sync with package.json
- CI workflow: replaced unreachable trufflehog@v3 with grep-based scan
- CI workflow: switched markdownlint-cli2 to cli-action@v1 for config compatibility

### Security

- All 16 commits GPG-signed with key `0D9BB5D5EB5FFE7D`
- git author unified to `NunoCodex <nunocodex@gmail.com>`
- Git global config: commit.gpgsign=true, user.signingkey set
- `.env.example` updated with RAG_DOCS_PATH and RAG_DOCS_MAX_FILES
- Python cache files excluded via .gitignore

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

[1.1.0]: https://github.com/nunocodex/pi-agent-enterprise/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nunocodex/pi-agent-enterprise/releases/tag/v1.0.0
