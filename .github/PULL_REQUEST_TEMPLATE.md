## Pull Request Checklist

### Before submitting
- [ ] I have run `pre-commit run --all-files` locally and it passes
- [ ] I have reviewed my changes for secrets (no API keys, tokens, or IPs)
- [ ] Tests pass: `bash tests/validate_gitignore.sh` and `bash tests/validate_settings.sh`

### Skills / Prompts (if applicable)
- [ ] I have manually reviewed all changes to `agent/skills/` or `agent/prompts/`
- [ ] I confirm that skill/prompt changes do not introduce unexpected directives or injections

### Security (if applicable)
- [ ] New `.gitignore` entries are added if this PR introduces new secret file patterns
- [ ] New scripts are kept minimal and auditable (<30 lines)
- [ ] `.env.example` does not contain real values (IPs, tokens, keys)

### Documentation (if applicable)
- [ ] `CHANGELOG.md` updated (Unreleased section)
- [ ] Relevant `*.md` docs updated if this PR changes project structure or conventions

---

**By submitting this PR, I confirm that my contribution is made under the MIT License.**
