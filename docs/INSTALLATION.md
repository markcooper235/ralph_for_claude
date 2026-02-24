# Ralph Loop Framework - Installation Guide

## Overview

The Ralph Loop Framework installation script (`install-ralph-loop.sh`) provides a complete setup system for adding Ralph Loop to new or existing projects.

## Features

✅ **Global Skills Installation** - Installs all Ralph skills to `~/.claude/skills/`
✅ **New Project Creation** - Creates project with Ralph Loop pre-configured
✅ **Existing Project Support** - Adds Ralph Loop to current project
✅ **Auto-Detection** - Detects project type and existing tools
✅ **Interactive Configuration** - Asks about preferences (package manager, test framework, etc.)
✅ **Safe Backups** - Backs up any files before replacing
✅ **Multi-Language Support** - TypeScript, Python, Go, Rust, Angular, React, Next.js, Express, Flask, Ruby

## Installation Methods

### Method 1: Global Skills Only

Install Ralph Loop skills globally without creating/modifying a project:

```bash
./install-ralph-loop.sh --install-global
```

**What it does:**
- Copies all 15 Ralph skills to `~/.claude/skills/`
- Backs up existing skills if present
- Makes skills available in all Claude Code sessions

**Use when:**
- You want Ralph Loop available everywhere
- You'll manually configure projects later
- You're installing on your development machine

---

### Method 2: Create New Project

Create a new project with Ralph Loop pre-configured:

```bash
# With specified project type
./install-ralph-loop.sh --install-global --new-project my-app --type typescript

# Auto-detect project type (will ask)
./install-ralph-loop.sh --install-global --new-project my-app
```

**What it does:**
1. Installs global skills (if `--install-global` specified)
2. Creates project directory with language-appropriate source, test, and config files
3. Asks configuration questions (package manager, test framework, etc.)
4. Sets up Ralph Loop structure (`ralph/.ralph/`, `ralph/specs/`, `ralph/archive/`, etc.)
5. Creates `CLAUDE.md` with project-specific guidance
6. Creates `.gitignore` for the language (node_modules, dist, venv, target, etc.)
7. Creates `README.md` with Ralph Loop workflow
8. **Installs dependencies** — runs `npm install`, `pip install`, `go mod tidy`, `cargo check`, or `bundle install` as appropriate
9. Initializes git repository
10. Makes initial commit

The project is ready to build, test, and lint immediately after creation — no manual setup required.

**Project types supported:**
- `typescript` - TypeScript/JavaScript with npm/yarn/pnpm/bun
- `python` - Python with pip/poetry/pipenv
- `go` - Go with standard tooling
- `rust` - Rust with Cargo
- `angular` - Angular with npm/yarn
- `react` - React with npm/yarn
- `nextjs` - Next.js with npm/yarn
- `express` - Express.js with npm/yarn
- `flask` - Flask with pip/poetry
- `ruby` - Ruby with bundler

**Use when:**
- Starting a new project from scratch
- Want Ralph Loop configured from the beginning
- Need project scaffolding

---

### Method 3: Initialize Existing Project

Add Ralph Loop to an existing project (current directory):

```bash
cd /path/to/existing/project
./install-ralph-loop.sh --install-global --init
```

**What it does:**
1. Installs global skills (if `--install-global` specified)
2. **Auto-detects** project type from existing files:
   - TypeScript: `package.json` with TypeScript
   - Python: `setup.py`, `pyproject.toml`, `requirements.txt`
   - Go: `go.mod`
   - Rust: `Cargo.toml`
   - C/C++: `CMakeLists.txt`, `Makefile`, `*.cpp`/`*.c`
3. **Auto-detects** existing tools:
   - Package managers (npm, yarn, pnpm, pip, poetry, etc.)
   - Test frameworks (jest, pytest, gtest, etc.)
   - Build systems (vite, webpack, cmake, etc.)
4. Asks configuration questions with detected defaults
5. **Backs up** existing files before modifying:
   - `CLAUDE.md` → `CLAUDE.md.ralph-backup-TIMESTAMP`
   - `.gitignore` → `.gitignore.ralph-backup-TIMESTAMP`
6. Creates Ralph Loop structure
7. Updates configuration files (preserves existing content)

**Use when:**
- Adding Ralph Loop to an existing codebase
- Preserving existing project structure
- Want auto-detection of tools and conventions

---

## Configuration Questions

The script asks tailored questions based on detected project type:

### TypeScript/JavaScript

```
Package manager? (npm/yarn/pnpm/bun) [npm]:
> yarn

Test framework? (jest/vitest/mocha) [jest]:
> vitest

Use build tool? (none/webpack/vite/esbuild) [vite]:
> vite

Include browser testing setup? (yes/no) [yes]:
> yes
```

### Python

```
Package manager? (pip/poetry/pipenv) [pip]:
> poetry

Test framework? (pytest/unittest) [pytest]:
> pytest

Use type checking? (mypy/pyright/none) [mypy]:
> mypy

Include browser testing setup? (yes/no) [yes]:
> no
```

### Go

```
Use additional test framework? (testify/ginkgo/none) [none]:
> testify

Include browser testing setup? (yes/no) [yes]:
> no
```

### Rust

```
Use workspace? (yes/no) [no]:
> no

Include browser testing setup? (yes/no) [yes]:
> no
```


**Defaults in brackets** - Detected from existing files or common choices

---

## What Gets Installed

### Directory Structure

```
project/
├── .claude/
│   ├── templates/
│   │   ├── prd-template.md
│   │   └── openspec-template.yaml
│   └── feedback-configs/             # Auto-generated configs
├── ralph/
│   ├── .ralph/                       # Runtime state (not tracked)
│   ├── specs/
│   │   ├── prds/                     # Your PRD files
│   │   └── openspecs/                # OpenSpec files
│   ├── archive/                      # Completed runs
│   ├── docs/
│   │   ├── QUICKSTART.md
│   │   ├── COMPLETE-WORKFLOW.md
│   │   ├── QUOTA-MANAGEMENT.md
│   │   ├── SPEC-MODIFICATIONS.md
│   │   └── ralph-loop-guide.md
│   ├── tests/
│   │   └── browser/                  # Browser tests
│   ├── feedback/                     # Test results
│   ├── .ralph-state-template.json    # State template
│   ├── .ralph-story-template.json    # Story template
│   └── .ralph-quota-config.json      # Quota config
├── CLAUDE.md                         # Claude guidance
└── README.md                         # Project readme
```

### Global Skills (~/.claude/skills/)

Skills are installed as subdirectories (e.g., `~/.claude/skills/ralph-loop/SKILL.md`).
Commands are installed as flat files (e.g., `~/.claude/commands/ralph-archive.md`).

**Skills** (invoke with `/skill-name`):
1. `ralph-loop/` - Main orchestrator with parallel subagents
2. `ralph-create-prd/` - Interactive PRD creation
3. `test-spec/` - Test against requirements
4. `browser-test/` - Playwright UI testing
5. `feedback-selector/` - Test strategy selection
6. `parse-prd/` - Parse PRD documents
7. `parse-openspec/` - Parse OpenSpec documents
8. `prove-requirements/` - Comprehensive validation

**Commands** (invoke with `/command-name`):
9. `ralph-archive` - Archive, validate, and merge
10. `ralph-status` - Progress monitoring
11. `ralph-resume` - Resume paused runs
12. `ralph-quota` - Quota management utilities
13. `ralph-modify-spec` - Full spec modification
14. `ralph-add-requirement` - Quick requirement addition
15. `ralph-loop-v2` - Alias for ralph-loop

---

## Auto-Detection Examples

### Example 1: TypeScript Project

**Existing files:**
```
my-app/
├── package.json          # Contains "typescript"
├── yarn.lock             # Yarn package manager
├── tsconfig.json
└── src/
```

**Auto-detects:**
- Project type: `typescript`
- Package manager: `yarn`
- Test framework: Checks package.json for jest/vitest/mocha

**Asks:**
```
Package manager? (npm/yarn/pnpm/bun) [yarn]:
> (press enter to accept yarn)

Test framework? (jest/vitest/mocha) [jest]:
> vitest
```

---

### Example 2: Python Project

**Existing files:**
```
my-app/
├── pyproject.toml        # Poetry project
├── poetry.lock
├── pytest.ini            # pytest configured
└── src/
```

**Auto-detects:**
- Project type: `python`
- Package manager: `poetry`
- Test framework: `pytest`

**Asks:**
```
Package manager? (pip/poetry/pipenv) [poetry]:
> (press enter)

Test framework? (pytest/unittest) [pytest]:
> (press enter)
```

---

### Example 3: Go Project

**Existing files:**
```
my-app/
├── go.mod
├── go.sum
└── internal/
```

**Auto-detects:**
- Project type: `go`
- Package manager: `go`
- Test framework: `testing` (standard)

**Asks:**
```
Use additional test framework? (testify/ginkgo/none) [none]:
> testify
```

---

## Backup System

The script **automatically backs up** any files it will modify:

### Backup Location

```
project/.ralph-backups/
├── CLAUDE.md.ralph-backup-20260223-153045
└── .gitignore.ralph-backup-20260223-153045
```

### Backup Naming

```
<filename>.ralph-backup-YYYYMMDD-HHMMSS
```

**Example:**
```
CLAUDE.md → CLAUDE.md.ralph-backup-20260223-153045
```

### When Backups Are Created

- **Global skills**: Existing skill file backed up before replacement
- **Project init**: `CLAUDE.md` and `.gitignore` backed up if they exist
- **Custom backup dir**: Use `--backup-dir <path>` to specify location

---

## Usage Examples

### Example 1: Install on Development Machine

```bash
# Install skills globally
./install-ralph-loop.sh --install-global

# Result:
# ✓ Installed 15 Ralph Loop skills to ~/.claude/skills/
# Skills available in all Claude Code sessions
```

---

### Example 2: Create TypeScript Project

```bash
# Create new TypeScript project
./install-ralph-loop.sh --install-global --new-project my-web-app --type typescript

# Answers:
# Package manager? (npm/yarn/pnpm/bun) [npm]: (enter)
# Test framework? (jest/vitest/mocha) [jest]: (enter)
# Include browser testing setup? (yes/no) [yes]: no

# Result:
# ✓ Created my-web-app/ with src/, tests/, jest.config.ts, .eslintrc.json
# ✓ npm install run — project ready to build/test/lint immediately
# ✓ .gitignore created (node_modules/, dist/, coverage/)
# ✓ Ralph Loop structure configured
# ✓ Initial git commit made

cd my-web-app
/ralph-create-prd
```

---

### Example 3: Add to Existing Python Project

```bash
cd /path/to/my-python-app

# Auto-detects Python with poetry and pytest
./install-ralph-loop.sh --install-global --init

# Detects:
# - Project type: python
# - Package manager: poetry (from poetry.lock)
# - Test framework: pytest (from pytest.ini)

# Asks:
# Package manager? (pip/poetry/pipenv) [poetry]: (enter)
# Test framework? (pytest/unittest) [pytest]: (enter)
# Use type checking? (mypy/pyright/none) [mypy]: (enter)
# Include browser testing setup? (yes/no) [yes]: no

# Result:
# ✓ Backed up CLAUDE.md.ralph-backup-20260223-153045
# ✓ Ralph Loop structure created
# ✓ CLAUDE.md updated with Python commands
# ✓ .gitignore updated with Ralph entries

/ralph-create-prd
```

---

### Example 4: Create Go Project

```bash
./install-ralph-loop.sh --install-global --new-project my-go-service --type go

# Asks:
# Use additional test framework? (testify/ginkgo/none) [none]: testify
# Include browser testing setup? (yes/no) [yes]: no

# Result:
# ✓ Created my-go-service/ with go.mod
# ✓ Ralph Loop configured
# ✓ Ready for PRD creation

cd my-go-service
/ralph-create-prd
```

---

## Troubleshooting

### Problem: Skills not found after installation

**Cause:** Claude Code may need to restart to detect new global skills.

**Solution:**
```bash
# Restart Claude Code
# Or verify skills directory
ls ~/.claude/skills/ | grep ralph
```

---

### Problem: Script fails with "Permission denied"

**Cause:** Script not executable.

**Solution:**
```bash
chmod +x install-ralph-loop.sh
./install-ralph-loop.sh --help
```

---

### Problem: Auto-detection incorrect

**Cause:** Ambiguous project files or unusual structure.

**Solution:** Specify type explicitly and answer configuration questions:
```bash
./install-ralph-loop.sh --install-global --init
# When asked, provide correct tool names
```

---

### Problem: Backup files accumulate

**Cause:** Multiple installations in same project.

**Solution:** Backups in `.ralph-backups/` can be safely deleted after verifying:
```bash
# Review backups
ls .ralph-backups/

# Delete old backups (after verification)
rm -rf .ralph-backups/
```

---

### Problem: Want to reinstall from scratch

**Cause:** Need clean installation.

**Solution:**
```bash
# Remove Ralph Loop files
rm -rf ralph/ .claude/

# Restore from backup if needed
cp .ralph-backups/CLAUDE.md.ralph-backup-* CLAUDE.md

# Reinstall
./install-ralph-loop.sh --install-global --init
```

---

## Verification

After installation, verify setup:

```bash
# Check global skills installed
ls ~/.claude/skills/ | grep ralph

# Check project structure
tree -L 2 -a

# Check CLAUDE.md created
cat CLAUDE.md

# Try a Ralph command
/ralph-create-prd --help
```

**Expected output:**
```
# Global skills (subdirectories in ~/.claude/skills/)
ralph-loop/
ralph-create-prd/
test-spec/
browser-test/
...

# Global commands (flat files in ~/.claude/commands/)
ralph-archive.md
ralph-status.md
ralph-resume.md
...

# Project structure
.
├── .claude/
├── ralph/
│   ├── archive/
│   ├── docs/
│   ├── specs/
│   └── .ralph-quota-config.json
├── CLAUDE.md
└── README.md
```

---

## Next Steps

After installation:

1. **Create PRD**:
   ```bash
   /ralph-create-prd
   ```

2. **Review Spec**:
   ```bash
   cat ralph/specs/prds/<spec-name>.prd.md
   ```

3. **Run Loop**:
   ```bash
   /ralph-loop
   ```

4. **Monitor Progress**:
   ```bash
   /ralph-status
   ```

5. **Archive Results**:
   ```bash
   /ralph-archive
   ```

---

## Uninstallation

To remove Ralph Loop:

### Remove Global Skills

```bash
# Skills are subdirectories
rm -rf ~/.claude/skills/ralph-loop/
rm -rf ~/.claude/skills/ralph-create-prd/
rm -rf ~/.claude/skills/test-spec/
rm -rf ~/.claude/skills/browser-test/
rm -rf ~/.claude/skills/feedback-selector/
rm -rf ~/.claude/skills/parse-prd/
rm -rf ~/.claude/skills/parse-openspec/
rm -rf ~/.claude/skills/prove-requirements/

# Commands are flat files
rm -f ~/.claude/commands/ralph-*.md
```

### Remove from Project

```bash
# Remove Ralph Loop files
rm -rf ralph/
rm -rf .claude/

# Restore original files from backup
cp .ralph-backups/CLAUDE.md.ralph-backup-* CLAUDE.md
cp .ralph-backups/.gitignore.ralph-backup-* .gitignore

# Remove backups
rm -rf .ralph-backups/
```

---

## Advanced Usage

### Custom Backup Directory

```bash
./install-ralph-loop.sh --install-global --init --backup-dir /path/to/backups
```

### Non-Interactive Installation

For CI/CD or scripted installations:

```bash
# Use environment variables for answers
export RALPH_PACKAGE_MANAGER=yarn
export RALPH_TEST_FRAMEWORK=vitest
export RALPH_BROWSER_TESTING=yes

./install-ralph-loop.sh --install-global --init
```

*(Note: Environment variable support would need to be added to script)*

---

## Support

For issues or questions:

1. Check `docs/QUICKSTART.md` for getting started
2. Review `docs/COMPLETE-WORKFLOW.md` for detailed examples
3. See `CLAUDE.md` for project-specific guidance
4. Check Ralph Loop Framework repository for updates

---

## Summary

The Ralph Loop installation script provides:

✅ **One-command installation** - Global skills + project setup
✅ **Auto-detection** - Detects project type and tools
✅ **Interactive configuration** - Tailored questions by project type
✅ **Safe backups** - Never lose existing work
✅ **Multi-language support** - TypeScript, Python, Go, Rust, Angular, React, Next.js, Express, Flask, Ruby
✅ **Flexible modes** - New projects or existing projects
✅ **Complete setup** - Documentation, templates, configs

**Quick reference:**

```bash
# Install globally
./install-ralph-loop.sh --install-global

# New project
./install-ralph-loop.sh --install-global --new-project <name> --type <lang>

# Existing project
cd /path/to/project
./install-ralph-loop.sh --install-global --init
```

Start building with Ralph Loop! 🚀
