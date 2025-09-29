#!/usr/bin/env bash
set -euo pipefail
REPORT_DIR="${REPORT_DIR:-__reports/hunt}"; mkdir -p "$REPORT_DIR"
OUT="$REPORT_DIR/adapter_presence.json"

PKG_JSON="package.json"
if [[ ! -f $PKG_JSON ]]; then
  echo '{"module":"adapter_presence","status":"pass","findings":{},"note":"no package.json"}' > "$OUT"; exit 0
fi

ADAPTERS=$(jq -r '[.dependencies,.devDependencies]|add|keys[]?|select(test("^@astrojs/(netlify|vercel|cloudflare|deno|node|aws|lambda)"))' $PKG_JSON 2>/dev/null || true)
CONFIG_COUNT=$(grep -Eo "adapter\s*\(" astro.config.mjs 2>/dev/null | wc -l | tr -d ' ' || echo 0)

UNCONFIGURED=0
UNCONFIGURED_LIST=()
if [[ -n "$ADAPTERS" ]]; then
  while IFS= read -r a; do
    [[ -z "$a" ]] && continue
    if (( CONFIG_COUNT == 0 )); then
      UNCONFIGURED=$((UNCONFIGURED+1))
      UNCONFIGURED_LIST+=("$a")
    fi
  done <<< "$ADAPTERS"
fi

STATUS=pass
(( UNCONFIGURED>0 )) && STATUS=critical

{
  echo '{'
  echo '  "module":"adapter_presence",'
  echo '  "timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
  echo '  "status":"'$STATUS'",'
  echo '  "findings": {'
  echo '    "installed_adapters": ['
  if [[ -n "$ADAPTERS" ]]; then
    echo "$ADAPTERS" | awk 'NR>1{printf ","}{printf "\""$0"\""}'
  fi
  echo '    ],'
  echo '    "configured_adapter_calls": '$CONFIG_COUNT','
  echo '    "unconfigured_adapters": '$UNCONFIGURED','
  echo -n '    "unconfigured_list": ['
  if (( UNCONFIGURED>0 )); then
    for i in "${!UNCONFIGURED_LIST[@]}"; do
      [[ $i -gt 0 ]] && printf ","
      printf '"%s"' "${UNCONFIGURED_LIST[$i]}"
    done
  fi
  echo ']'
  echo '  },'
  echo '  "policy_invariants":["findings.unconfigured_adapters==0"],'
  echo '  "recommendations":["Remove unused adapter packages or configure an adapter explicitly"]'
  echo '}'
} > "$OUT"

echo "adapter_presence: $STATUS"
[[ $STATUS == critical ]] && exit 2 || exit 0
