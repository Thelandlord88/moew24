# Repo Zipper

This script creates a ZIP of your repo that **respects `.gitignore`** and also includes any **untracked but not ignored** files. It outputs to `dist/<repo>-YYYYMMDD-HHMMSS.zip`.

## How to use (GitHub Codespaces or any Linux/macOS shell)

1. Download this script to your repo (or copy it into your repo as `repo-zipper.sh`).
2. In a terminal at the repo root, run:
   ```bash
   bash repo-zipper.sh
   ```
3. In Codespaces (VS Code web), open the File Explorer, right‑click the new ZIP under `dist/` → **Download**.

### What is excluded?
Anything ignored by `.gitignore`, `.git/info/exclude`, and your global Git excludes (e.g. `node_modules/`, build outputs, `.env*`, caches, etc.).

### What is included?
- All **tracked files at HEAD** (via `git archive`)
- All **untracked but not ignored** files (via `git ls-files --others --exclude-standard`), appended into the same ZIP.

### Requirements
- `git` and `zip` must be installed in the environment.
