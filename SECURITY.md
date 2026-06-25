# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅ Active |
| < 1.0   | ❌ Pre-release |

## Reporting a Vulnerability

**Do not open a public issue.** Instead, report vulnerabilities privately:

1. **Email**: [maintainer email — configure before release]
2. **PGP Key**: [maintainer PGP key — configure before release]

### What to Include
- Description of the vulnerability
- Steps to reproduce
- Affected versions
- Potential impact

### Response Timeline
- Acknowledge receipt within **48 hours**
- Triage and severity assessment within **5 business days**
- Fix timeline communicated within **10 business days**

## Scope

Security-relevant components:
- `agent/prompts/` — Prompt template injection vectors
- `agent/skills/` — Skill instruction integrity
- `agent/skills/rag-query/rag_client.py` — Network client
- `setup.sh` — Bootstrap script execution
- `.gitignore` / `.pre-commit-config.yaml` — Secret protection

## Disclosure Policy

We follow [coordinated disclosure](https://en.wikipedia.org/wiki/Coordinated_vulnerability_disclosure):
1. Reporter submits vulnerability privately
2. Maintainer acknowledges and triages
3. Fix is developed and tested
4. Release is prepared with security advisory
5. CVE requested if applicable
6. Public disclosure after patch is available

## Acknowledgments

We maintain a [SECURITY-ACKNOWLEDGMENTS.md](SECURITY-ACKNOWLEDGMENTS.md) to thank researchers who responsibly disclose vulnerabilities.
