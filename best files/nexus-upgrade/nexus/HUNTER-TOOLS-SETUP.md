# Hunter System Tools & Extensions Guide

A comprehensive setup guide for tools and extensions needed to effectively work with the Hunter code analysis system.

## Prerequisites

Before setting up the Hunter-specific tools, ensure you have these basic requirements:

- **Node.js** (v16+) and **npm**
- **Git**
- **Bash shell** (Linux/macOS/WSL)
- **VS Code** or similar editor

## Essential CLI Tools

### Core Dependencies (Required)

#### JSON Processing
```bash
# jq - Essential for JSON manipulation in hunters
sudo apt install jq                    # Ubuntu/Debian
brew install jq                        # macOS
winget install jqlang.jq              # Windows

# Test installation
jq --version
```

#### Fast Search Tools
```bash
# ripgrep - Critical for pattern-based analysis
sudo apt install ripgrep              # Ubuntu/Debian
brew install ripgrep                   # macOS
winget install BurntSushi.ripgrep.MSVC # Windows

# fd - Enhanced find (pairs well with rg)
sudo apt install fd-find              # Ubuntu/Debian (note: binary is 'fdfind')
brew install fd                        # macOS
winget install sharkdp.fd             # Windows

# Test installation
rg --version
fd --version  # or 'fdfind --version' on Ubuntu
```

#### Standard Unix Tools
Most systems have these, but verify:
```bash
which grep awk sed wc stat find tail head
```

### Recommended Enhancements

#### Interactive Tools
```bash
# fzf - Fuzzy finder for interactive hunter selection
sudo apt install fzf                  # Ubuntu/Debian
brew install fzf                       # macOS
winget install junegunn.fzf           # Windows

# bat - Enhanced cat with syntax highlighting
sudo apt install bat                  # Ubuntu/Debian
brew install bat                       # macOS
winget install sharkdp.bat            # Windows

# Test installation
fzf --version
bat --version
```

#### JSON & Data Tools
```bash
# jless - Interactive JSON viewer
cargo install jless                   # Via Rust
# OR download from: https://github.com/PaulJuliusMartinez/jless

# yq - YAML processor (like jq for YAML)
sudo apt install yq                   # Ubuntu/Debian
brew install yq                        # macOS
winget install MikeFarah.yq           # Windows
```

#### Performance & Analysis
```bash
# hyperfine - Benchmarking tool
sudo apt install hyperfine            # Ubuntu/Debian
brew install hyperfine                 # macOS
winget install sharkdp.hyperfine      # Windows

# tokei - Code statistics
sudo apt install tokei                # Ubuntu/Debian
brew install tokei                     # macOS
cargo install tokei                   # Via Rust

# dust - Disk usage analyzer  
sudo apt install du-dust              # Ubuntu/Debian
brew install dust                      # macOS
cargo install du-dust                 # Via Rust
```

#### File Watching
```bash
# entr - File watcher for auto-running hunters
sudo apt install entr                 # Ubuntu/Debian
brew install entr                      # macOS
# Windows: Use watchexec instead
winget install watchexec.watchexec
```

## VS Code Extensions

### Essential Extensions

Copy this into VS Code's Quick Open (Ctrl+P) and run each line:

```
ext install astro-build.astro-vscode
ext install ms-vscode.vscode-typescript-next
ext install bradlc.vscode-tailwindcss
ext install esbenp.prettier-vscode
ext install ms-vscode.vscode-json
```

#### Core Development
- **Astro** (`astro-build.astro-vscode`) - Official Astro language support
- **TypeScript** (`ms-vscode.vscode-typescript-next`) - Enhanced TS support
- **Tailwind CSS IntelliSense** (`bradlc.vscode-tailwindcss`) - CSS architecture support
- **Prettier** (`esbenp.prettier-vscode`) - Code formatting
- **JSON Tools** (`ms-vscode.vscode-json`) - JSON editing and validation

### Code Quality & Security Extensions

```
ext install usernamehw.errorlens
ext install eamodio.gitlens  
ext install ms-vscode.vscode-eslint
ext install snyk-security.snyk-vulnerability-scanner
ext install wayou.vscode-todo-highlight
```

- **Error Lens** (`usernamehw.errorlens`) - Inline error display
- **GitLens** (`eamodio.gitlens`) - Git insights and history
- **ESLint** (`ms-vscode.vscode-eslint`) - JavaScript/TypeScript linting
- **Snyk Security** (`snyk-security.snyk-vulnerability-scanner`) - Vulnerability scanning
- **TODO Highlight** (`wayou.vscode-todo-highlight`) - Highlight TODO/FIXME comments

### Accessibility & Performance Extensions

```
ext install deque-systems.vscode-axe-linter
ext install wix.vscode-import-cost
ext install humao.rest-client
ext install yzhang.markdown-all-in-one
```

- **axe Accessibility Linter** (`deque-systems.vscode-axe-linter`) - A11Y compliance
- **Import Cost** (`wix.vscode-import-cost`) - Bundle size analysis
- **REST Client** (`humao.rest-client`) - API testing
- **Markdown All in One** (`yzhang.markdown-all-in-one`) - Documentation support

### Optional Enhancements

```
ext install ms-vscode.theme-github-light
ext install pkief.material-icon-theme
ext install gruntfuggly.todo-tree
ext install streetsidesoftware.code-spell-checker
```

## Shell Enhancements

### Oh My Zsh (macOS/Linux)
```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Recommended plugins for ~/.zshrc:
plugins=(git node npm docker kubectl fzf)
```

### Starship Prompt (Cross-platform)
```bash
# Install Starship
curl -sS https://starship.rs/install.sh | sh

# Add to shell config
echo 'eval "$(starship init bash)"' >> ~/.bashrc     # Bash
echo 'eval "$(starship init zsh)"' >> ~/.zshrc       # Zsh
```

## Hunter-Specific Workflow Setup

### 1. Hunter Development Aliases

Add to your shell config (`~/.bashrc` or `~/.zshrc`):

```bash
# Hunter System Aliases
alias hunt='./hunters/hunt.sh'
alias hunt-critical='./hunters/hunt.sh --modules "environment_security build_ssg_guard accessibility runtime_ssr"'
alias hunt-security='./hunters/hunt.sh --modules "security environment_security"'
alias hunt-performance='./hunters/hunt.sh --modules "performance asset_weight image_optimization"'
alias hunt-reports='find __reports/hunt -name "*.json" | head -10'
alias hunt-logs='find __reports/hunt -name "*.log" | head -10'
alias hunt-health='cat __reports/hunt/health_index.json | jq .findings.score'

# Report viewing with jq/jless
alias hunt-summary='jq -s "map({module, status, critical_issues, warning_issues})" __reports/hunt/*.json'
alias hunt-interactive='find __reports/hunt -name "*.json" | fzf --preview "jq . {}"'

# Quick file searches for hunter development  
alias hunt-grep='rg --type sh -A 3 -B 3'
alias hunt-find='fd -e sh . hunters/'
```

### 2. File Watching Setup

Create `watch-hunters.sh`:
```bash
#!/bin/bash
# Watch for changes and auto-run relevant hunters

echo "Watching for file changes..."
find src/ -name "*.astro" -o -name "*.ts" -o -name "*.js" | entr -c ./hunters/hunt.sh --modules "type_safety security performance"
```

### 3. Git Hooks Integration

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Run critical hunters before commit

echo "Running critical hunters..."
./hunters/hunt.sh --modules "environment_security build_ssg_guard accessibility"

if [ $? -ne 0 ]; then
    echo "❌ Critical hunters failed. Commit blocked."
    exit 1
fi

echo "✅ Critical hunters passed."
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Quick Setup Script

Create `setup-hunter-tools.sh`:

```bash
#!/bin/bash
# Quick setup script for Hunter tools

echo "🔧 Setting up Hunter system tools..."

# Check for required tools
REQUIRED_TOOLS="jq rg node npm git"
MISSING_TOOLS=""

for tool in $REQUIRED_TOOLS; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS $tool"
    fi
done

if [ ! -z "$MISSING_TOOLS" ]; then
    echo "❌ Missing required tools:$MISSING_TOOLS"
    echo "Please install them first."
    exit 1
fi

# Install optional tools based on OS
if command -v apt &> /dev/null; then
    # Ubuntu/Debian
    sudo apt update && sudo apt install -y fzf bat hyperfine entr fd-find
elif command -v brew &> /dev/null; then
    # macOS
    brew install fzf bat hyperfine entr fd
elif command -v winget &> /dev/null; then
    # Windows
    winget install junegunn.fzf sharkdp.bat sharkdp.hyperfine sharkdp.fd
fi

# Create reports directory
mkdir -p __reports/hunt

# Test installation
echo "✅ Testing hunter system..."
./hunters/hunt.sh --help

echo "🎉 Hunter tools setup complete!"
echo "Run './hunters/hunt.sh' to start analyzing your code."
```

## Troubleshooting

### Common Issues

1. **`jq: command not found`**
   - Install jq: `sudo apt install jq` or `brew install jq`

2. **`rg: command not found`** 
   - Install ripgrep: `sudo apt install ripgrep` or `brew install ripgrep`

3. **Permission denied on hunter scripts**
   - Make executable: `chmod +x hunters/*.sh`

4. **Reports directory missing**
   - Create it: `mkdir -p __reports/hunt`

5. **Slow performance**
   - Ensure ripgrep and fd are installed for fast file operations
   - Check that you're not running hunters on `node_modules/`

### Performance Optimization

- Use `.gitignore` patterns to exclude large directories
- Run hunters in parallel when possible
- Use `--max-results` flag to limit output
- Consider running only critical hunters in CI/CD

## Next Steps

1. **Test the setup**: Run `./hunters/hunt.sh --help`
2. **Run a sample analysis**: `./hunters/hunt.sh --modules "security"`
3. **Explore reports**: `ls -la __reports/hunt/`
4. **Customize workflow**: Modify aliases and scripts to fit your needs
5. **Set up automation**: Configure file watching and git hooks

## Getting Help

- **Hunter logs**: Check `__reports/hunt/*.log` files
- **Verbose output**: Add `-x` to hunter scripts for debugging
- **Report issues**: Document problems in hunter output JSON
- **Community**: Share hunter configurations and custom modules
