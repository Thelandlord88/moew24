#!/usr/bin/env bash
# NEXUS Phase 5 Bootstrap — Cognitive Differentiation System (portable, hardened)
# Deploys/initializes the NEXUS Phase 5 runtime with personality-specific response generation scaffolding.
# Works on macOS/Linux/WSL. Requires Node >= 20.10.0.

set -Eeuo pipefail
IFS=$'\n\t'

# =============================
# Defaults / Config
# =============================
NEXUS_VERSION="${NEXUS_VERSION:-5.0.0-cognitive-differentiation}"
TARGET_DIR="${PWD}"
NEXUS_PORT="${NEXUS_PORT:-8080}"
PKG="auto"            # auto | npm | pnpm | yarn
DRY_RUN=0
SKIP_TOOLS=0
NO_VSCODE=0
QUIET=0
GIT_INIT=0
LOCKFILE=""
CREATE_TEMPLATES=1    # set 0 to skip writing minimal runtime files if you already vend them

# =============================
# Helpers
# =============================
log()   { (( QUIET )) || printf "%s\n" "$*"; }
warn()  { (( QUIET )) || printf "⚠️  %s\n" "$*" >&2; }
err()   { printf "❌ %s\n" "$*" >&2; exit 1; }
has()   { command -v "$1" >/dev/null 2>&1; }
run()   { if (( DRY_RUN )); then log "[dry-run] $*"; else eval "$*"; fi; }

usage() {
  cat <<'USAGE'
NEXUS Phase 5 Bootstrap

Usage:
  nexus-phase5-bootstrap.sh [options]

Options:
  --target DIR               Target directory to initialize (default: current dir)
  --port PORT                Port for the NEXUS runtime (default: 8080 or $NEXUS_PORT)
  --package-manager NAME     npm|pnpm|yarn|auto (default: auto)
  --skip-tools               Skip installing jq, curl, wget, tree, shellcheck
  --dry-run                  Print steps without executing
  --no-vscode                Don't create/update .vscode/settings.json
  --git-init                 Initialize a git repo if none exists
  --quiet                    Minimal logging
  -h, --help                 Show help

Examples:
  ./nexus-phase5-bootstrap.sh --target . --port 8080
  ./nexus-phase5-bootstrap.sh --target ./app --package-manager pnpm --git-init
USAGE
}

cleanup() { [[ -n "${LOCKFILE}" && -f "${LOCKFILE}" ]] && rm -f "${LOCKFILE}" || true; }
on_error() {
  local ec=$?
  warn "Bootstrap failed (exit $ec). See messages above."
  warn "Tip: try --skip-tools on CI/WSL, check Node version, or re-run with --dry-run."
  exit "$ec"
}
trap cleanup EXIT
trap on_error ERR

# =============================
# Arg parsing
# =============================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)           TARGET_DIR="$2"; shift 2 ;;
    --port)             NEXUS_PORT="$2"; shift 2 ;;
    --package-manager)  PKG="$2"; shift 2 ;;
    --skip-tools)       SKIP_TOOLS=1; shift ;;
    --dry-run)          DRY_RUN=1; shift ;;
    --no-vscode)        NO_VSCODE=1; shift ;;
    --git-init)         GIT_INIT=1; shift ;;
    --quiet)            QUIET=1; shift ;;
    -h|--help)          usage; exit 0 ;;
    *)                  TARGET_DIR="$1"; shift ;;
  esac
done

# normalize target path
TARGET_DIR="${TARGET_DIR%/}"
[[ -z "$TARGET_DIR" ]] && TARGET_DIR="${PWD}"

# =============================
# Lock to avoid overlapping runs
# =============================
LOCKFILE="$TARGET_DIR/.nexus-phase5-bootstrap.lock"
run "mkdir -p \"$TARGET_DIR\""
if [[ -f "$LOCKFILE" ]]; then
  err "Another bootstrap may be in progress (lock exists: $LOCKFILE). Remove it if safe and re-run."
fi
run "printf '%s' $$ > \"$LOCKFILE\""

# =============================
# Node version check (>= 20.10.0)
# =============================
if ! has node; then
  err "Node.js not found. Please install Node >= 20.10.0."
fi
nv_raw="$(node --version | sed 's/^v//')"
IFS='.' read -r nMajor nMinor nPatch <<<"${nv_raw}"
if (( nMajor < 20 )) || { (( nMajor == 20 )) && (( nMinor < 10 )); }; then
  err "Need Node >= 20.10.0, found v${nv_raw}."
fi
log "✅ Node v${nv_raw} OK"

# =============================
# System tools (optional)
# =============================
log "2️⃣ Ensuring system tools (jq, curl, wget, tree, shellcheck)…"
if (( SKIP_TOOLS )); then
  log "↪︎ Skipping tool install by request."
else
  if has apt-get; then
    run "sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq"
    run "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y jq curl wget tree shellcheck >/dev/null"
  elif has dnf; then
    run "sudo dnf install -y jq curl wget tree ShellCheck >/dev/null"
  elif has yum; then
    run "sudo yum install -y jq curl wget tree ShellCheck >/dev/null"
  elif has pacman; then
    run "sudo pacman -Sy --noconfirm jq curl wget tree shellcheck"
  elif has brew; then
    run "brew list --versions jq >/dev/null || brew install jq"
    run "brew list --versions wget >/dev/null || brew install wget"
    run "brew list --versions tree >/dev/null || brew install tree"
    run "brew list --versions shellcheck >/dev/null || brew install shellcheck"
  else
    warn "No supported package manager found; continuing without tool installation."
  fi
fi

# =============================
# PM detection
# =============================
if [[ "$PKG" == "auto" ]]; then
  if has pnpm; then PKG="pnpm"
  elif has yarn; then PKG="yarn"
  else PKG="npm"
  fi
fi
if ! has "$PKG"; then
  warn "'$PKG' not found; falling back to npm."
  PKG="npm"
fi
log "↪︎ Using package manager: $PKG"

# =============================
# Directory structure
# =============================
log "3️⃣ Creating directories under: $TARGET_DIR"
run "mkdir -p \"$TARGET_DIR/nexus/consciousness\" \"$TARGET_DIR/nexus/generators\" \"$TARGET_DIR/nexus/traits\""
run "mkdir -p \"$TARGET_DIR/profiles\" \"$TARGET_DIR/scripts\" \"$TARGET_DIR/.vscode\""

# =============================
# Minimal runtime templates (Phase 5 scaffolding)
# =============================
RUNTIME_PATH="$TARGET_DIR/nexus/nexus-runtime.mjs"
BRIDGE_PATH="$TARGET_DIR/nexus/nexus-bridge.mjs"
TRAIT_PATH="$TARGET_DIR/nexus/nexus-trait-bridge.mjs"
FACTORY_PATH="$TARGET_DIR/nexus/generators/ResponseGeneratorFactory.js"
GEN_GENERIC="$TARGET_DIR/nexus/generators/GenericResponseGenerator.js"

if (( CREATE_TEMPLATES )); then
  if [[ ! -f "$RUNTIME_PATH" ]]; then
    log "⚙️  Writing minimal runtime → $RUNTIME_PATH"
    run "cat > \"$RUNTIME_PATH\" <<'RJS'
import http from 'node:http';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { ResponseGeneratorFactory } from './generators/ResponseGeneratorFactory.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const port = Number(process.env.NEXUS_PORT || 8080);

const factory = new ResponseGeneratorFactory();

// Policy middleware example (tone & required sections)
factory.use({
  post: (res, req, persona, principles) => {
    const sections = principles?.requiredSections ?? [];
    if (sections.length) {
      for (const s of sections) {
        if (!res.content.toLowerCase().includes(('### ' + s).toLowerCase())) {
          res.content += `\\n\\n### ${s}\\n- (added by policy)`;
        }
      }
    }
    if (persona?.tone === 'decisive') {
      res.content = res.content.replaceAll('consider', 'do').replaceAll('might', 'will');
      res.confidenceScore = Math.min(1, res.confidenceScore + 0.1);
    }
    return res;
  }
});

const server = http.createServer(async (req, res) => {
  if (req.url?.startsWith('/status')) {
    res.setHeader('content-type','application/json');
    res.end(JSON.stringify({ initialized: true, port, version: '${NEXUS_VERSION}' }));
    return;
  }
  if (req.url?.startsWith('/respond')) {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const { request, personality, principles, context } = JSON.parse(body || '{}');
        const persona = personality ?? { identity: { name: 'generic' }, traits: [] };
        const result = await factory.generate(
          request || 'Hello NEXUS',
          persona,
          principles ?? { requiredSections: ['Summary','Evidence','Risks','Next Steps'] },
          context ?? { requestId: 'dev-local' }
        );
        res.setHeader('content-type','application/json');
        res.end(JSON.stringify(result));
      } catch (e) {
        res.statusCode = 400;
        res.end(String(e));
      }
    });
    return;
  }
  res.statusCode = 404;
  res.end('Not found');
});

server.listen(port, '127.0.0.1', () => console.log(\`NEXUS Phase 5 listening on \${port}\"));
RJS"
  fi

  if [[ ! -f "$BRIDGE_PATH" ]]; then
    log "⚙️  Writing bridge → $BRIDGE_PATH"
    run "cat > \"$BRIDGE_PATH\" <<'BJS'
export const nexusBridge = {
  enhancePersonality: (p) => p
};
BJS"
  fi

  if [[ ! -f "$TRAIT_PATH" ]]; then
    log "⚙️  Writing trait bridge → $TRAIT_PATH"
    run "cat > \"$TRAIT_PATH\" <<'TJS'
export const nexusTraitBridge = {
  selectOptimalPersonality: async () => 'guardian'
};
TJS"
  fi

  if [[ ! -f "$GEN_GENERIC" ]]; then
    log "⚙️  Writing GenericResponseGenerator → $GEN_GENERIC"
    run "cat > \"$GEN_GENERIC\" <<'GJS'
export class GenericResponseGenerator {
  async generateResponse(request, personality, principles, context) {
    const name = personality?.identity?.name ?? 'NEXUS Agent';
    const traits = personality?.traits ?? [];
    const sections = principles?.requiredSections ?? ['Summary','Evidence','Risks','Next Steps'];
    const content = [
      \`### 🧠 \${name} Response\`,
      '',
      \`**Request**: \${request}\`,
      '',
      '### Cognitive Profile',
      \`- Traits: \${traits.length ? traits.join(', ') : 'none'}\`,
      \`- Tone: \${personality?.tone ?? 'neutral'}\`,
      \`- Domain: \${(personality?.domain ?? []).join(', ') || 'general'}\`,
      '',
      ...sections.map(s => \`### \${s}\\n- (generic; add specialized generator to enrich)\`)
    ].join('\\n');
    return {
      content,
      personalityUsed: name,
      nexusEnhanced: true,
      traitApplications: traits.map(t => ({ trait: t, application: 'generic-modulation', strength: 0.5 })),
      specialtyInsights: [],
      confidenceScore: Math.min(0.9, 0.4 + traits.length * 0.1),
      analysisDepth: request && request.length > 600 ? 'deep' : (request && request.length > 250 ? 'medium' : 'surface')
    };
  }
}
GJS"
  fi

  if [[ ! -f "$FACTORY_PATH" ]]; then
    log "⚙️  Writing ResponseGeneratorFactory → $FACTORY_PATH"
    run "cat > \"$FACTORY_PATH\" <<'FJS'
import { GenericResponseGenerator } from './GenericResponseGenerator.js';

const CANONICAL = ['bob','hunter','stellar','flash','aria','touch','daedalus','guardian'];
const ALIASES = { robert: 'bob', dae: 'daedalus' };

function normalize(name) {
  const k = String(name || '').toLowerCase().trim();
  return ALIASES[k] || (CANONICAL.includes(k) ? k : null);
}

export class ResponseGeneratorFactory {
  constructor() {
    this.generators = new Map();
    this.generic = new GenericResponseGenerator();
    this.middlewares = [];
    // place to wire specialized generators you ship by default:
    // this.generators.set('daedalus', new DaedalusResponseGenerator());
    // this.generators.set('hunter', new HunterResponseGenerator());
  }

  use(mw) { this.middlewares.push(mw); }

  hasSpecializedGenerator(name) {
    const n = normalize(name);
    return !!(n && this.generators.has(n));
  }

  getAvailableSpecializations() {
    return Array.from(this.generators.keys());
  }

  getGeneratorStatus() {
    const specialized = this.generators.size;
    const total = CANONICAL.length;
    const missing = CANONICAL.filter(p => !this.generators.has(p));
    return { specialized, total, coverage: \`\${specialized}/\${total}\`, missing };
  }

  getGenerator(name) {
    const n = normalize(name);
    if (n && this.generators.has(n)) {
      console.log(\`🎯 Using specialized \${n} response generator\`);
      return this.generators.get(n);
    }
    console.log(\`🔧 Using generic response generator for \${name}\`);
    return this.generic;
  }

  async generate(request, personality, principles, context) {
    for (const mw of this.middlewares) if (mw.pre) await mw.pre(request, personality, principles, context);
    const gen = this.getGenerator(personality?.identity?.name ?? 'generic');
    let res = await gen.generateResponse(request, personality, principles, context);
    for (const mw of this.middlewares) if (mw.post) res = await mw.post(res, request, personality, principles, context);
    return res;
  }
}
FJS"
  fi
else
  log "↪︎ Skipping template creation (CREATE_TEMPLATES=0)."
fi

# =============================
# Dependencies (optional)
# =============================
if [[ -f "$TARGET_DIR/package.json" ]]; then
  log "4️⃣ Installing project dependencies in $TARGET_DIR …"
  if (( DRY_RUN )); then
    log "[dry-run] (cd \"$TARGET_DIR\" && $PKG install)"
  else
    ( cd "$TARGET_DIR" && "$PKG" install )
  fi
else
  warn "No package.json found in $TARGET_DIR — skipping dependency install."
fi

# =============================
# VS Code settings (non-destructive merge if jq is available)
# =============================
if (( NO_VSCODE )); then
  log "↪︎ Skipping VS Code settings by request."
else
  SETTINGS="$TARGET_DIR/.vscode/settings.json"
  if [[ ! -f "$SETTINGS" ]]; then
    log "5️⃣ Creating .vscode/settings.json"
    run "cat > \"$SETTINGS\" <<'JSON'
{
  \"shellcheck.exclude\": [\"SC2034\", \"SC2086\"],
  \"files.associations\": { \"*.mjs\": \"javascript\", \"*.mts\": \"typescript\" },
  \"typescript.preferences.includePackageJsonAutoImports\": \"auto\"
}
JSON"
  else
    if has jq; then
      log "🔧 Merging VS Code settings …"
      TMP_JSON="$(mktemp)"
      run "jq -s '.[0] * .[1]' \"$SETTINGS\" <(cat <<'JSON'
{
  \"shellcheck.exclude\": [\"SC2034\", \"SC2086\"],
  \"files.associations\": { \"*.mjs\": \"javascript\", \"*.mts\": \"typescript\" },
  \"typescript.preferences.includePackageJsonAutoImports\": \"auto\"
}
JSON
) > \"$TMP_JSON\" && mv \"$TMP_JSON\" \"$SETTINGS\""
    else
      warn "jq not available; leaving existing VS Code settings untouched."
    fi
  fi
fi

# =============================
# Helpers
# =============================
START_SH="$TARGET_DIR/nexus-start.sh"
STATUS_SH="$TARGET_DIR/nexus-status.sh"
TEST_SH="$TARGET_DIR/nexus-test.sh"

run "cat > \"$START_SH\" << EOF
#!/usr/bin/env bash
set -euo pipefail
export NEXUS_PORT=\${NEXUS_PORT:-$NEXUS_PORT}
echo \"🧠 Starting NEXUS Phase 5…\"
echo \"Port: \${NEXUS_PORT}\"
echo \"Version: ${NEXUS_VERSION}\"
node nexus/nexus-runtime.mjs
EOF"
run "chmod +x \"$START_SH\""

run "cat > \"$STATUS_SH\" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
PORT="${NEXUS_PORT}"
URL="http://127.0.0.1:${NEXUS_PORT}/status"
if command -v curl >/dev/null 2>&1; then
  curl -fsS "${URL}" | sed 's/^/↪︎ /'
else
  echo "curl not found; open ${URL} in your browser"
fi
EOF"
run "chmod +x \"$STATUS_SH\""

run "cat > \"$TEST_SH\" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
URL="http://127.0.0.1:${NEXUS_PORT}/status"
echo "🔍 Probing ${URL} …"
if command -v curl >/dev/null 2>&1; then
  if curl -fsS "${URL}" >/dev/null; then
    echo "✅ Status endpoint reachable."
    exit 0
  else
    echo "❌ Status endpoint not reachable. Is nexus-start.sh running?"
    exit 1
  fi
else
  echo "curl not found; open ${URL} in your browser."
  exit 0
fi
EOF"
run "chmod +x \"$TEST_SH\""

# =============================
# Git init (optional)
# =============================
if (( GIT_INIT )); then
  if has git; then
    if [[ ! -d "$TARGET_DIR/.git" ]]; then
      log "6️⃣ Initializing git repository …"
      (cd "$TARGET_DIR" && run "git init -q" && run "git add -A" && run "git commit -qm 'chore(nexus): bootstrap phase 5 runtime'")
    else
      log "↪︎ Git repository already present."
    fi
  else
    warn "git not found; skipping --git-init."
  fi
fi

# =============================
# Summary
# =============================
log ""
log "🎉 NEXUS Phase 5 Bootstrap complete."
log "   • Target:     $TARGET_DIR"
log "   • Port:       $NEXUS_PORT"
log "   • Node:       v${nv_raw}"
log "   • Package PM: $PKG"
log "   • Version:    $NEXUS_VERSION"
log ""
log "Next steps:"
log "  1) Start:  (cd \"$TARGET_DIR\" && ./nexus-start.sh)"
log "  2) Status: ./nexus-status.sh"
log "  3) Test:   ./nexus-test.sh"
