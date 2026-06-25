# Contributing to pi-agent-enterprise

Thanks for contributing! This guide covers setup, conventions, and the PR process.

## Setup

```bash
git clone https://github.com/nunocodex/pi-agent-enterprise.git
cd pi-agent-enterprise

# Install pre-commit hooks
pip install pre-commit && pre-commit install

# Install npm deps for extension validation
cd agent/npm && npm ci && cd ../..
```

## GPG Commit Signing

All commits to `main` must be GPG-signed:

```bash
# Generate a key (if needed)
gpg --full-generate-key

# Configure git
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
```

## Conventions

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
<type>(<scope>): <subject>

<body>
```
Types: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`, `style`, `perf`

### Pull Requests
1. Fork the repo
2. Create a feature branch (`feat/my-feature`)
3. Write/update tests in `tests/`
4. Run `pre-commit run --all-files` locally
5. Ensure CI passes (GitHub Actions)
6. Fill out the PR template completely

### Skills & Prompts Changes
- Changes to `agent/skills/**` or `agent/prompts/**` require mandatory maintainer review
- Check the PR template checkbox: "I have manually reviewed all skill/prompt changes"
- CI will automatically flag skill/prompt diffs for attention

### Security
- Never commit secrets to `auth.json` or `.env`
- Run `pre-commit` before every commit
- Report vulnerabilities via `SECURITY.md` — do NOT open a public issue

## Testing

```bash
# Run validation tests
bash tests/validate_gitignore.sh
bash tests/validate_settings.sh
```

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
