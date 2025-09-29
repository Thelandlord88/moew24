#!/usr/bin/env bash
# workspace_health.sh — Repository size & hygiene hunter
# Focus: large files, dependency footprint, env hygiene, generated noise

set -Eeuo pipefail
set +H

REPORT_DIR="__reports/hunt"
REPORT_FILE="$REPORT_DIR/workspace_health.json"
TIMESTAMP=${TIMESTAMP:-$(date -u +%Y%m%d-%H%M%S)}

mkdir -p "$REPORT_DIR"
REPORT_COMPLETED=0

ISSUES=0
CRITICAL=0

set +e

# 1. Detect large non-media files (>500KB) excluding common binary/media formats we intentionally track
mapfile -t LARGE_FILES < <(find . -type f \
  -not -path './node_modules/*' \
  -not -path './.git/*' \
  -not -path './dist/*' \
  -not -path './.astro/*' \
  -size +500k -print 2>/dev/null | head -100)
LARGE_FILE_COUNT=${#LARGE_FILES[@]}
if (( LARGE_FILE_COUNT > 0 )); then ((ISSUES++)); fi

# 2. Oversized source files (>1500 lines) in src/ (signal for refactor)
mapfile -t OVERSIZE_SRC < <(grep -rIl '' src 2>/dev/null | while read -r f; do wc -l "$f" | awk '$1>1500{print $2":"$1}'; done | head -100)
OVERSIZE_SRC_COUNT=${#OVERSIZE_SRC[@]}
if (( OVERSIZE_SRC_COUNT > 0 )); then ((ISSUES++)); fi

# 3. Count unique runtime deps (package.json dependencies + prod transitive approx via node_modules depth 1)
PROD_DEPS=$(node -e 'try{const p=require("./package.json");const d=Object.keys(p.dependencies||{});process.stdout.write(String(d.length));}catch{process.stdout.write("0")}' 2>/dev/null)
NODEMODULES_TOP=$(find node_modules -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | awk '{print $1}')

# 4. Environment file hygiene (.env should not be committed with secrets) — simple heuristic: if .env exists, ensure it only contains comments or placeholder assignments
ENV_PRESENT=0
ENV_FLAGGED=0
if [[ -f .env ]]; then
  ENV_PRESENT=1
  if grep -Eiq 'netlify|secret|token|key' .env; then
    ENV_FLAGGED=1; ((ISSUES++));
  fi
fi

# 5. Generated reports churn: count JSON files under __reports (signal if > 250 suggesting cleanup)
REPORT_JSON_COUNT=$(find __reports -type f -name '*.json' 2>/dev/null | wc -l | awk '{print $1}')
if (( REPORT_JSON_COUNT > 250 )); then ((ISSUES++)); fi

# 6. Disk usage snapshot (top-level) — not an issue metric but included
DISK_USAGE=$(du -sh . 2>/dev/null | awk '{print $1}')
SRC_USAGE=$(du -sh src 2>/dev/null | awk '{print $1}')
NODE_USAGE=$(du -sh node_modules 2>/dev/null | awk '{print $1}')
REPORT_USAGE=$(du -sh __reports 2>/dev/null | awk '{print $1}')

# Criteria for CRITICAL: any env leak or >25 oversize source files
if (( ENV_FLAGGED == 1 )); then ((CRITICAL++)); fi
if (( OVERSIZE_SRC_COUNT > 25 )); then ((CRITICAL++)); fi

STATUS="pass"
if (( CRITICAL > 0 )); then STATUS="critical"; elif (( ISSUES > 0 )); then STATUS="warn"; fi

set -e
cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "module": "workspace_health",
  "status": "$STATUS",
  "issues": $ISSUES,
  "critical": $CRITICAL,
  "findings": {
    "large_files": $LARGE_FILE_COUNT,
    "oversize_source_files": $OVERSIZE_SRC_COUNT,
    "prod_dependencies": $PROD_DEPS,
    "top_level_node_modules_count": $NODEMODULES_TOP,
    "env_present": $ENV_PRESENT,
    "env_flagged": $ENV_FLAGGED,
    "report_json_files": $REPORT_JSON_COUNT,
    "disk_usage_root": "$DISK_USAGE",
    "disk_usage_src": "$SRC_USAGE",
    "disk_usage_node_modules": "$NODE_USAGE",
    "disk_usage_reports": "$REPORT_USAGE"
  },
  "counts": {
    "oversize": $OVERSIZE_SRC_COUNT
  },
  "policy_invariants": [
    "counts.oversize < 26",
    "findings.env_flagged == 0"
  ],
  "recommendations": [
    "Refactor oversize source files (>1500 lines)",
    "Remove or archive stale large files not needed at runtime",
    "Keep .env restricted to placeholders only",
    "Reduce churn by pruning obsolete __reports JSON artifacts",
    "Consider code-splitting large generated contexts"
  ]
}
EOF
REPORT_COMPLETED=1
sync || true

# Exit codes align with orchestrator expectations
if (( CRITICAL > 0 )); then exit 2; elif (( ISSUES > 0 )); then exit 1; else exit 0; fi
