#!/usr/bin/env bash
set -euo pipefail

echo "== Astro adapter fixer =="

# 0) Non-interactive package managers
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export CI=${CI:-1}

# 1) Sanity checks
if [[ ! -f package.json ]]; then
  echo "No package.json found. Run this in your Astro project root."
  exit 1
fi

if ! npx --yes astro --version >/dev/null 2>&1; then
  # Install Astro if missing (rare)
  echo "Astro CLI not found; adding it..."
  npm i -D astro >/dev/null 2>&1 || true
fi

# 2) Detect SSR signals (any of these => needs adapter)
has_ssr=0
grep -R --line-number --include='*.{astro,ts,js,tsx,mjs,cjs}' -E 'export\s+const\s+prerender\s*=\s*false' src 2>/dev/null && has_ssr=1 || true
[[ -f src/middleware.ts || -f src/middleware.js ]] && has_ssr=1
# Endpoints or actions-like folders people commonly use:
[[ -d src/pages/api || -d src/pages/_actions || -d src/actions ]] && has_ssr=1

# 3) Decide adapter
# You’re on Netlify in this repo history, so default to Netlify.
target_adapter="@astrojs/netlify"
adapter_import="import netlify from '@astrojs/netlify';"
adapter_use="adapter: netlify()"

# 4) Install adapter if missing
if ! jq -re '.devDependencies["@astrojs/netlify"] // .dependencies["@astrojs/netlify"]' package.json >/dev/null 2>&1; then
  echo "Installing ${target_adapter} ..."
  npm i -D ${target_adapter}
fi

# 5) Locate astro.config (ts or mjs). Create minimal if not present.
cfg=""
for f in astro.config.ts astro.config.mjs astro.config.js; do
  [[ -f "$f" ]] && cfg="$f" && break
done

if [[ -z "$cfg" ]]; then
  echo "No astro.config.* found. Creating astro.config.mjs..."
  cat > astro.config.mjs <<'CFG'
import { defineConfig } from 'astro/config';
import netlify from '@astrojs/netlify';

export default defineConfig({
  output: 'hybrid',
  adapter: netlify(),
});
CFG
  cfg="astro.config.mjs"
else
  echo "Patching ${cfg} ..."
  # Ensure import present
  if ! grep -q "@astrojs/netlify" "$cfg"; then
    # Insert import after first import block or at top
    # shellcheck disable=SC2016
    awk -v imp="$adapter_import" '
      NR==1{print imp}
      {print}
    ' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
  fi

  # Ensure export default defineConfig exists; if not, wrap minimal
  if ! grep -q "defineConfig" "$cfg"; then
    echo "No defineConfig() found; wrapping file."
    cp "$cfg" "$cfg.bak"
    cat > "$cfg" <<CFG
import { defineConfig } from 'astro/config';
${adapter_import}

export default defineConfig({
  output: 'hybrid',
  ${adapter_use},
});
CFG
  else
    # Ensure output and adapter are set (idempotent patch)
    #  - set output: 'hybrid' (safer for mixed prerender/SSR)
    #  - set adapter: netlify()
    node --input-type=module <<'PATCH'
import fs from 'node:fs';

const cfgCandidates = ["astro.config.ts","astro.config.mjs","astro.config.js"];
let path = cfgCandidates.find(f => fs.existsSync(f));
let s = fs.readFileSync(path, 'utf8');

function upsert(key, value) {
  const re = new RegExp(`${key}\\s*:\\s*[^,}]+`, 'm');
  if (re.test(s)) {
    s = s.replace(re, `${key}: ${value}`);
  } else {
    s = s.replace(/defineConfig\(\{/, match => `${match}\n  ${key}: ${value},`);
  }
}

upsert('output', `'hybrid'`);
upsert('adapter', 'netlify()');

fs.writeFileSync(path, s);
console.log("Patched", path);
PATCH
  fi
fi

# 6) If there’s absolutely no SSR signal, allow static builds to succeed too.
#    (We’ll leave 'hybrid' since it’s safe; but if you *want* static only, uncomment next lines)
# node --input-type=module <<'STATIC'
# import fs from 'node:fs';
# if (!fs.existsSync('src/middleware.ts') && !fs.existsSync('src/middleware.js')) {
#   const p = ['astro.config.ts','astro.config.mjs','astro.config.js'].find(f=>fs.existsSync(f));
#   if (p) {
#     let s = fs.readFileSync(p,'utf8');
#     s = s.replace(/output:\s*'hybrid'/, "output: 'static'");
#     fs.writeFileSync(p, s);
#     console.log("No SSR signals; set output: 'static' in", p);
#   }
# }
# STATIC

# 7) Rebuild to confirm
echo "Rebuilding…"
rm -rf node_modules .astro dist
npm ci
npm run build -- --verbose || {
  echo
  echo "Build still failing. Grep for adapter/SSR in logs:"
  grep -Ei 'adapter|SSR|prerender|middleware|astro' -n .debug-exit1/run-*/command.log 2>/dev/null || true
  exit 1
}

echo "✅ Done: adapter configured and build passed (or progressed past the adapter error)."
