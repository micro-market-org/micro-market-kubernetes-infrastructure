# Security guardrails

## Never commit credentials

All cloud credentials come from environment variables (locally) or GitHub Actions secrets/variables
+ OIDC federation (pipelines). The `*_apply.sh`/`*_destroy.sh` scripts fail fast when
credentials are unset. `.gitignore` blocks state files, plan artifacts (`tfplan`,
`plan.json`), and key material (`*service-account*.json`, `*-key.json`, `*.pem`, ...).
CI runs gitleaks (part of the shared `security-scan-gate.yml` reusable workflow) on every pipeline.

## Pre-commit secret scanning (recommended)

Install [gitleaks](https://github.com/gitleaks/gitleaks) and enable it as a pre-commit hook:

```shell
# one-time, in this repo
git config core.hooksPath .githooks
```

`.githooks/pre-commit` runs `gitleaks protect --staged` and rejects commits containing
secret-like content. To scan the whole tree manually:

```shell
gitleaks detect --source .
```

## Incident note (2026-07-03)

A GCP service-account key file was previously staged in this repo. It was removed and
**must be treated as compromised and rotated**; git history was intentionally kept
(rotation-only policy). Do not reuse any credential found in history.
