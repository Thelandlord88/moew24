#!/usr/bin/env bash
# seo_geo_crawl_hunter.sh
# Purpose: Ensure every location page is crawlable, worth indexing, and compliant with your SEO/geo rules.
# Safe for slugs with spaces/dashes (no bash key-subscripts); relies on grep/rg/jq/node over bash arrays.

set -euo pipefail
IFS=$'\n\t'

# ---- Config (change as needed) ------------------------------------------------
DIST_DIR="${1:-dist}"
SITEMAP="${2:-sitemap.xml}"   # accepts absolute or relative
REPORT_DIR="__reports/hunt"
REPORT_JSON="$REPORT_DIR/seo_geo_crawl.json"
HTML_BUDGET_GZ_MAX=$((120*1024))   # ~120KB gz
JACCARD_MAX="0.30"

mkdir -p "$REPORT_DIR"

# ---- Utilities ----------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }
fail() { echo "❌ $*"; exit 1; }
note() { echo "• $*"; }
ok()   { echo "✅ $*"; }

require_tools() {
  local need=(rg jq node gzip awk sed)
  for t in "${need[@]}"; do have "$t" || fail "Missing tool: $t"
  done
}

gz_size () { gzip -c "$1" | wc -c | awk '{print $1}'; }

extract_jsonld() {
  # Extract first JSON-LD script from an HTML file (minimally robust; avoids heavy deps).
  awk 'BEGIN{p=0} /<script[^>]*type="application\/ld\+json"[^>]*>/{p=1;next} /<\/script>/{if(p){p=0;print "";exit}} p{printf "%s",$0}' "$1"
}

title_text() {
  awk 'BEGIN{IGNORECASE=1}/<title>/{gsub(/.*<title>/,"");gsub(/<\/title>.*/,"");print;exit}' "$1"
}

meta_desc() {
  awk 'BEGIN{IGNORECASE=1}/<meta[^>]*name=["]description["]/{match($0,/content=["][^"]*["]/); if(RLENGTH>0){s=substr($0,RSTART,RLENGTH); gsub(/content=|"/,"",s); print s}}' "$1"
}

has_self_canonical() {
  local f="$1" slug="$2"
  # basic check: canonical present and points to own URL (contains slug)
  awk 'BEGIN{IGNORECASE=1}/<link[^>]*rel=["]canonical["]/{print}' "$f" | grep -qi "$slug"
}

suburb_from_path() {
  # dist/{slug}/index.html -> slug
  local f="$1"
  # Normalize to slug dir name
  dirname "$f" | awk -F/ '{print $NF}'
}

slugify() {
  # very mild slugify for ALT checks
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g;s/^-+|-+$//g'
}

word_count_inside_local_proof() {
  # count words inside Local Proof section by id or heading heuristic
  awk '
    BEGIN{m=0;c=0}
    /id="local-proof"|>Recent work in /{m=1}
    /<\/section>/{if(m==1){m=0}}
    m==1{gsub(/<[^>]+>/,""); gsub(/&[^;]+;/," "); for(i=1;i<=NF;i++){ if($i!="") c++ }}
    END{print c}
  ' "$1"
}

has_faq_count_ge2() {
  # look for at least two <h3> in local-faq section (or schema.org FAQPage block)
  local f="$1"
  local n
  n=$(awk '
    BEGIN{m=0;c=0}
    /id="local-faq"/{m=1}
    /<\/section>/{if(m==1){m=0}}
    m==1 && /<h3[^>]*>/{c++}
    END{print c}
  ' "$f")
  if [ "${n:-0}" -ge 2 ]; then echo "yes"; else echo "no"; fi
}

check_neighbor_links() {
  local f="$1" slug="$2" needed="${3:-2}"
  # Accept links to other suburb slugs (anything under /{something}/ with letters/dashes)
  local count
  count=$(grep -Eo 'href="[^"]+/"' "$f" | sed -E 's/^href="\/?([^"]+)\/".*/\1/' \
          | grep -v -E "^$slug$" | grep -E '^[a-z0-9-]+$' | sort -u | wc -l | awk '{print $1}')
  if [ "$count" -ge "$needed" ]; then echo "yes"; else echo "no"; fi
}

has_image_alt_with_suburb() {
  local f="$1" suburb="$2"
  grep -Eio '<img[^>]+alt="[^"]+"' "$f" | grep -qi "$suburb" && echo "yes" || echo "no"
}

has_hero_preload_and_dims() {
  local f="$1"
  local p l
  p=$(grep -Eio '<link[^>]+rel="preload"[^>]+as="image"[^>]*/?>' "$f" | wc -l | awk '{print $1}')
  l=$(grep -Eio '<img[^>]+(width|height)=' "$f" | wc -l | awk '{print $1}')
  if [ "$p" -ge 1 ] && [ "$l" -ge 1 ]; then echo "yes"; else echo "no"; fi
}

json_has_keys() {
  # check JSON-LD contains key markers (string contains is fine)
  local json="$1"
  echo "$json" | grep -q '"@type"'               || return 1
  echo "$json" | grep -q 'LocalBusiness'         || return 1
  echo "$json" | grep -q '"areaServed"'          || return 1
  echo "$json" | grep -q '"geo"'                 || return 1
  echo "$json" | grep -q '"hasMap"'              || return 1
  return 0
}

check_sitemap_includes() {
  local slug="$1" site="${2:-$SITEMAP}"
  if [ ! -f "$site" ]; then 
    echo "no"
    return 0
  fi
  if grep -q "/$slug/" "$site"; then echo "yes"; else echo "no"; fi
}

jaccard_js='
const fs = require("node:fs");
function sentences(html){return html.replace(/<[^>]+>/g," ").split(/[.!?]\s+/).map(s=>s.trim()).filter(Boolean)}
function shingles3(ss){const s=new Set(); for(let i=0;i<ss.length-2;i++) s.add((ss[i]+"|"+ss[i+1]+"|"+ss[i+2]).toLowerCase()); return s}
function jaccard(a,b){const I=[...a].filter(x=>b.has(x)).length; const U=new Set([...a,...b]).size; return I/U}
function scoreOne(me, others){
  const htmlMe = fs.readFileSync(me,"utf8"); const a = shingles3(sentences(htmlMe));
  let worst=0, worstFile=null;
  for (const f of others){
    const b = shingles3(sentences(fs.readFileSync(f,"utf8")));
    const s = jaccard(a,b);
    if (s>worst){ worst=s; worstFile=f; }
  }
  return {worst, worstFile};
}
const [_,__,meFile,...rest]=process.argv; 
const N = Math.min(rest.length, 12); // sample up to 12
const sample = rest.sort(()=>Math.random()-0.5).slice(0,N);
const out = scoreOne(meFile, sample);
console.log(JSON.stringify(out));
'

# ---- Thinker preflight (Upstream-Curious) -------------------------------------
cat > "$REPORT_DIR/seo_geo_prelude.json" <<'JSON'
{
  "box": "Pages might be thin/duplicative or not fully crawlable",
  "closet": "build output + templates + sitemaps",
  "ablation": "If we drop local-proof/faq/schema/internal-links, coverage & ranking decay",
  "upstream_candidates": [
    "Make local-proof + faq mandatory at build",
    "Validate JSON-LD areaServed/geo/hasMap",
    "Enforce adjacency links & image ALT locality",
    "Fail on high shingle similarity"
  ],
  "chosen_change": {
    "description": "Automated hunter that validates crawlability + locality signals and blocks deploy on failure",
    "deletions": [],
    "single_source_of_truth": "__reports/hunt/seo_geo_crawl.json"
  },
  "policy_invariant": "Build fails if local-proof<120 words, faq<2, schema missing, sitemap/canonical missing, or shingle>0.30",
  "sibling_sweep": { "pattern": "random|Math\\.random|layout.*shuffle", "hits": [], "actions": [] },
  "evidence_window": "last_30_days",
  "rollback_plan": "Disable this hunter, fall back to manual QA"
}
JSON

# ---- Main scan ----------------------------------------------------------------
require_tools

htmls=()
while IFS= read -r -d '' f; do htmls+=("$f"); done < <(find "$DIST_DIR" -type f -name "index.html" -print0 | sort -z)

[ ${#htmls[@]} -gt 0 ] || fail "No built pages found in $DIST_DIR"

pass=1
results='[]'

for f in "${htmls[@]}"; do
  slug="$(suburb_from_path "$f")"
  suburb="$(echo "$slug" | tr '-' ' ' | sed 's/\b./\u&/g')" # Titlecase-ish for ALT check
  t="$(title_text "$f")"
  d="$(meta_desc "$f")"
  gz=$(gz_size "$f")
  sz_ok=$([ "$gz" -le "$HTML_BUDGET_GZ_MAX" ] && echo "yes" || echo "no")
  can_ok=$(has_self_canonical "$f" "$slug")
  pre_ok=$(has_hero_preload_and_dims "$f")
  lp_words=$(word_count_inside_local_proof "$f")
  faq_ok=$(has_faq_count_ge2 "$f")
  alt_ok=$(has_image_alt_with_suburb "$f" "$suburb")
  nlk_ok=$(check_neighbor_links "$f" "$slug" 2)
  jl="$(extract_jsonld "$f")"
  schema_ok="no"; [ -n "$jl" ] && json_has_keys "$jl" && schema_ok="yes"
  sm_ok=$(check_sitemap_includes "$slug" "$SITEMAP")

  # Shingle similarity vs sample
  if [ ${#htmls[@]} -gt 1 ]; then
    # Only run similarity check if we have multiple files
    other_files=()
    for other_f in "${htmls[@]}"; do
      if [ "$other_f" != "$f" ]; then
        other_files+=("$other_f")
      fi
    done
    
    if [ ${#other_files[@]} -gt 0 ]; then
      worst_json=$(node -e "$jaccard_js" "$f" "${other_files[@]}")
      worst_score=$(echo "$worst_json" | jq -r '.worst')
      worst_file=$(echo "$worst_json" | jq -r '.worstFile // ""')
    else
      worst_score="0.0"
      worst_file=""
    fi
  else
    worst_score="0.0" 
    worst_file=""
  fi
  
  shingle_ok=$(awk -v s="$worst_score" -v m="$JACCARD_MAX" 'BEGIN{print (s<=m)?"yes":"no"}')

  # Mandatory gates
  gate_localproof=$(awk -v n="${lp_words:-0}" 'BEGIN{print (n>=120)?"yes":"no"}')
  gate_faq="$faq_ok"
  gate_schema="$schema_ok"
  gate_canonical=$([ -n "$can_ok" ] && echo "yes" || echo "no")
  gate_sitemap=$([ -n "$sm_ok" ] && echo "$sm_ok" || echo "no")
  gate_htmlbudget="$sz_ok"
  gate_shingle="$shingle_ok"

  # overall
  if [ "$gate_localproof" != "yes" ] || [ "$gate_faq" != "yes" ] || [ "$gate_schema" != "yes" ] \
     || [ "$gate_canonical" != "yes" ] || [ "$gate_sitemap" != "yes" ] || [ "$gate_htmlbudget" != "yes" ] \
     || [ "$gate_shingle" != "yes" ]; then
    pass=0
  fi

  # Assemble row
  row=$(jq -n \
    --arg slug "$slug" \
    --arg title "$t" \
    --arg desc "$d" \
    --arg gz "$gz" \
    --arg lp_words "$lp_words" \
    --arg faq_ok "$faq_ok" \
    --arg schema_ok "$schema_ok" \
    --arg canonical_ok "$gate_canonical" \
    --arg sitemap_ok "$gate_sitemap" \
    --arg preload_ok "$pre_ok" \
    --arg alt_ok "$alt_ok" \
    --arg neighbors_ok "$nlk_ok" \
    --arg shingle_ok "$shingle_ok" \
    --arg worst_score "$worst_score" \
    --arg worst_file "$worst_file" \
    '{
      slug: $slug,
      html_gz: ($gz|tonumber),
      title: $title,
      metaDescription: $desc,
      checks: {
        localProof_ge120: (($lp_words|tonumber) >= 120),
        faq_ge2: ($faq_ok=="yes"),
        schema_localBusiness: ($schema_ok=="yes"),
        self_canonical: ($canonical_ok=="yes"),
        in_sitemap: ($sitemap_ok=="yes"),
        hero_preload_and_dims: ($preload_ok=="yes"),
        alt_contains_suburb: ($alt_ok=="yes"),
        neighbor_links_ge2: ($neighbors_ok=="yes"),
        html_gz_le_120k: (($gz|tonumber) <= 122880),
        shingle_jaccard_le_0_30: ($shingle_ok=="yes")
      },
      shingle: { worst: ($worst_score|tonumber), versus: $worst_file }
    }')
  results=$(jq -c --argjson row "$row" '. + [$row]' <<<"$results")
done

echo "$results" | jq '.' > "$REPORT_JSON"

if [ "$pass" -eq 1 ]; then
  ok "SEO/Geo Crawlability: PASS → $REPORT_JSON"
  exit 0
else
  echo "✗ SEO/Geo Crawlability: FAIL → $REPORT_JSON"
  echo "   (blockers: local-proof<120, faq<2, schema/canonical/sitemap missing, HTML gz >120KB, or shingle>0.30)"
  exit 2
fi