#!/usr/bin/env bash
# security.sh — secrets, dynamic code, mixed content, .env leakage
set -euo pipefail
IFS=$'\n\t'

. "hunters/trace.sh" || true

REPORT_DIR="__reports/hunt"
OUT="$REPORT_DIR/security.json"
mkdir -p "$REPORT_DIR"

scan() {
  local secrets=0 xss=0 unsafe=0 mixed=0 envleak=0

  # Secrets (heuristics)
  secrets=$(( $(grep -RIn --binary-files=without-match -E '(api[_-]?key|secret|token|password|AKIA[0-9A-Z]{16})' . 2>/dev/null | wc -l | tr -d ' ') ))

  # Dangerous code
  unsafe=$(( $(grep -RIn --binary-files=without-match -E '\beval\(|new[[:space:]]+Function\(' src 2>/dev/null | wc -l | tr -d ' ') ))

  # XSS sinks (basic patterns)
  xss=$(( $(grep -RIn --binary-files=without-match -E 'innerHTML\s*=|dangerouslySetInnerHTML' src 2>/dev/null | wc -l | tr -d ' ') ))

  # Mixed content (http:// in code)
  mixed=$(( $(grep -RIn --binary-files=without-match -E 'http://[^\"]+' src public 2>/dev/null | wc -l | tr -d ' ') ))

  # .env in repo
  envleak=$(( $(git ls-files 2>/dev/null | grep -E '(^|/)\.env(\..+)?$' | wc -l | tr -d ' ') ))

  local issues=$(( secrets + unsafe + xss + mixed + envleak ))
  local status="pass"; [[ $issues -gt 0 ]] && status="critical"

  cat > "$OUT" <<JSON
{
  "schemaVersion": 1,
  "module": "security",
  "status": "$status",
  "issues": $issues,
  "affected_files": $issues,
  "counts": {
    "secrets": $secrets,
    "unsafe_code": $unsafe,
    "xss_sinks": $xss,
    "mixed_content": $mixed,
    "env_files_in_repo": $envleak
  },
  "actions": [
    "Remove secrets from code; use environment or secret manager",
    "Replace eval/new Function; sanitize untrusted HTML; avoid innerHTML",
    "Enforce HTTPS and CSP; move .env files out of VCS"
  ],
  "policy_invariants": [
    "counts.secrets == 0",
    "counts.unsafe_code == 0",
    "counts.xss_sinks == 0",
    "counts.mixed_content == 0",
    "counts.env_files_in_repo == 0"
  ],
  "eta_minutes": 20,
  "unlocks": ["runtime_ssr","performance"]
}
JSON
}

scan "."
