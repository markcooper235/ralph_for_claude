#!/usr/bin/env bash

# Ralph Loop Framework - Installation Script
# Installs Ralph Loop Framework skills globally and sets up projects

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global Claude directories
CLAUDE_GLOBAL_SKILLS="${HOME}/.claude/skills"
CLAUDE_GLOBAL_COMMANDS="${HOME}/.claude/commands"

# Configuration
BACKUP_SUFFIX=".ralph-backup-$(date +%Y%m%d-%H%M%S)"

#==============================================================================
# Helper Functions
#==============================================================================

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Ralph Loop Framework - Installation${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    --install-global            Install skills to ~/.claude/skills/ and commands to ~/.claude/commands/
    --new-project <name>        Create new project with Ralph framework
    --type <language>           Project type (typescript, javascript, angular, react, nextjs, express, python, flask, go, rust, ruby, nx)
    --parent-dir <path>         Directory where project will be created (default: current directory)
    --init                      Add Ralph framework to existing project (current directory)
    --backup-dir <path>         Custom backup directory (default: .ralph-backups/)
    --help                      Show this help message

INSTALL SCOPE:
    Skills and commands are installed in exactly ONE place:
    - --install-global           → ~/.claude/ only  (available in ALL projects)
    - --new-project / --init     → project .claude/ only  (this project only)
    - --install-global + project → ~/.claude/ only  (project-level skipped to avoid duplicates)

EXAMPLES:
    # Install skills globally (available in every project, no per-project install needed)
    $0 --install-global

    # Create new TypeScript project — skills installed at project level only
    $0 --new-project my-app --type typescript

    # Create project in specific directory — skills installed at project level only
    $0 --new-project my-app --type python --parent-dir ~/projects

    # Initialize existing project — skills installed at project level only
    cd /path/to/project
    $0 --init

    # Install globally AND create project — skills go to ~/.claude/ only (no duplication)
    $0 --install-global --new-project my-app --type typescript

EOF
}

#==============================================================================
# Installation Functions
#==============================================================================

install_global_skills() {
    print_info "Installing Ralph Loop skills and commands globally..."

    # Create global directories if they don't exist
    mkdir -p "${CLAUDE_GLOBAL_SKILLS}"
    mkdir -p "${CLAUDE_GLOBAL_COMMANDS}"

    local installed_skills=0
    local updated_skills=0
    local skipped_skills=0
    local installed_cmds=0
    local updated_cmds=0
    local skipped_cmds=0

    # -------------------------------------------------------------------------
    # Install SKILLS: .claude/skills/<name>/SKILL.md → ~/.claude/skills/<name>/SKILL.md
    # Skills are identified by being a subdirectory containing SKILL.md
    # -------------------------------------------------------------------------
    local skills_source="${SCRIPT_DIR}/.claude/skills"
    if [ -d "${skills_source}" ]; then
        for skill_dir in "${skills_source}"/*/; do
            if [ -d "${skill_dir}" ] && [ -f "${skill_dir}/SKILL.md" ]; then
                local skill_name=$(basename "${skill_dir}")
                local target_dir="${CLAUDE_GLOBAL_SKILLS}/${skill_name}"
                local source_file="${skill_dir}/SKILL.md"
                local target_file="${target_dir}/SKILL.md"

                mkdir -p "${target_dir}"

                if [ -f "${target_file}" ]; then
                    if [ "${source_file}" -nt "${target_file}" ]; then
                        cp "${source_file}" "${target_file}"
                        print_success "Updated skill: ${skill_name}"
                        updated_skills=$((updated_skills + 1))
                    else
                        skipped_skills=$((skipped_skills + 1))
                    fi
                else
                    cp "${source_file}" "${target_file}"
                    print_success "Installed skill: ${skill_name}"
                    installed_skills=$((installed_skills + 1))
                fi
            fi
        done
    else
        print_warning "Skills source directory not found: ${skills_source}"
    fi

    # -------------------------------------------------------------------------
    # Install COMMANDS: .claude/commands/<name>.md → ~/.claude/commands/<name>.md
    # Commands are flat .md files (legacy format, still supported)
    # -------------------------------------------------------------------------
    local commands_source="${SCRIPT_DIR}/.claude/commands"
    if [ -d "${commands_source}" ]; then
        for cmd_file in "${commands_source}"/*.md; do
            if [ -f "${cmd_file}" ]; then
                local cmd_name=$(basename "${cmd_file}")
                local target="${CLAUDE_GLOBAL_COMMANDS}/${cmd_name}"

                if [ -f "${target}" ]; then
                    if [ "${cmd_file}" -nt "${target}" ]; then
                        cp "${cmd_file}" "${target}"
                        print_success "Updated command: ${cmd_name}"
                        updated_cmds=$((updated_cmds + 1))
                    else
                        skipped_cmds=$((skipped_cmds + 1))
                    fi
                else
                    cp "${cmd_file}" "${target}"
                    print_success "Installed command: ${cmd_name}"
                    installed_cmds=$((installed_cmds + 1))
                fi
            fi
        done
    else
        print_warning "Commands source directory not found: ${commands_source}"
    fi

    # Print summary
    local total_skills=$((installed_skills + updated_skills + skipped_skills))
    local total_cmds=$((installed_cmds + updated_cmds + skipped_cmds))

    echo
    print_success "Skills  → ${CLAUDE_GLOBAL_SKILLS}"
    print_info "  Installed: ${installed_skills}  Updated: ${updated_skills}  Up-to-date: ${skipped_skills}  Total: ${total_skills}"
    print_success "Commands → ${CLAUDE_GLOBAL_COMMANDS}"
    print_info "  Installed: ${installed_cmds}  Updated: ${updated_cmds}  Up-to-date: ${skipped_cmds}  Total: ${total_cmds}"
    echo
}

install_project_skills() {
    local project_dir="$1"

    print_info "Installing Ralph Loop skills and commands into project..."

    local installed_skills=0
    local updated_skills=0
    local skipped_skills=0
    local installed_cmds=0
    local updated_cmds=0
    local skipped_cmds=0

    # -------------------------------------------------------------------------
    # Install SKILLS: .claude/skills/<name>/SKILL.md → <project>/.claude/skills/<name>/SKILL.md
    # -------------------------------------------------------------------------
    local skills_source="${SCRIPT_DIR}/.claude/skills"
    if [ -d "${skills_source}" ]; then
        for skill_dir in "${skills_source}"/*/; do
            if [ -d "${skill_dir}" ] && [ -f "${skill_dir}/SKILL.md" ]; then
                local skill_name=$(basename "${skill_dir}")
                local target_dir="${project_dir}/.claude/skills/${skill_name}"
                local source_file="${skill_dir}/SKILL.md"
                local target_file="${target_dir}/SKILL.md"

                mkdir -p "${target_dir}"

                if [ -f "${target_file}" ]; then
                    if [ "${source_file}" -nt "${target_file}" ]; then
                        cp "${source_file}" "${target_file}"
                        print_success "Updated skill: ${skill_name}"
                        updated_skills=$((updated_skills + 1))
                    else
                        skipped_skills=$((skipped_skills + 1))
                    fi
                else
                    cp "${source_file}" "${target_file}"
                    print_success "Installed skill: ${skill_name}"
                    installed_skills=$((installed_skills + 1))
                fi
            fi
        done
    else
        print_warning "Skills source not found: ${skills_source}"
    fi

    # -------------------------------------------------------------------------
    # Install COMMANDS: .claude/commands/<name>.md → <project>/.claude/commands/<name>.md
    # -------------------------------------------------------------------------
    mkdir -p "${project_dir}/.claude/commands"
    local commands_source="${SCRIPT_DIR}/.claude/commands"
    if [ -d "${commands_source}" ]; then
        for cmd_file in "${commands_source}"/*.md; do
            if [ -f "${cmd_file}" ]; then
                local cmd_name=$(basename "${cmd_file}")
                local target="${project_dir}/.claude/commands/${cmd_name}"

                if [ -f "${target}" ]; then
                    if [ "${cmd_file}" -nt "${target}" ]; then
                        cp "${cmd_file}" "${target}"
                        print_success "Updated command: ${cmd_name}"
                        updated_cmds=$((updated_cmds + 1))
                    else
                        skipped_cmds=$((skipped_cmds + 1))
                    fi
                else
                    cp "${cmd_file}" "${target}"
                    print_success "Installed command: ${cmd_name}"
                    installed_cmds=$((installed_cmds + 1))
                fi
            fi
        done
    else
        print_warning "Commands source not found: ${commands_source}"
    fi

    local total_skills=$((installed_skills + updated_skills + skipped_skills))
    local total_cmds=$((installed_cmds + updated_cmds + skipped_cmds))

    echo
    print_success "Skills  → ${project_dir}/.claude/skills/"
    print_info "  Installed: ${installed_skills}  Updated: ${updated_skills}  Up-to-date: ${skipped_skills}  Total: ${total_skills}"
    print_success "Commands → ${project_dir}/.claude/commands/"
    print_info "  Installed: ${installed_cmds}  Updated: ${updated_cmds}  Up-to-date: ${skipped_cmds}  Total: ${total_cmds}"
    echo
}

#==============================================================================
# Project Type Detection
#==============================================================================

detect_project_type() {
    local project_dir="$1"

    # Framework-specific detection (check before generic JS/TS)
    if [ -f "${project_dir}/package.json" ]; then
        if grep -q '"@angular/core"' "${project_dir}/package.json" 2>/dev/null; then
            echo "angular"
        elif grep -q '"next"' "${project_dir}/package.json" 2>/dev/null; then
            echo "nextjs"
        elif grep -q '"react"' "${project_dir}/package.json" 2>/dev/null; then
            echo "react"
        elif grep -q '"express"' "${project_dir}/package.json" 2>/dev/null; then
            echo "express"
        elif grep -q '"typescript"' "${project_dir}/package.json" 2>/dev/null; then
            echo "typescript"
        else
            echo "javascript"
        fi
        return
    fi

    # Python / Flask
    if [ -f "${project_dir}/setup.py" ] || [ -f "${project_dir}/pyproject.toml" ] || [ -f "${project_dir}/requirements.txt" ]; then
        if grep -qi "flask" "${project_dir}/requirements.txt" 2>/dev/null; then
            echo "flask"
        else
            echo "python"
        fi
        return
    fi

    # NX monorepo
    if [ -f "${project_dir}/nx.json" ]; then
        echo "nx"
        return
    fi

    # Ruby
    if [ -f "${project_dir}/Gemfile" ]; then
        echo "ruby"
        return
    fi

    # Go
    if [ -f "${project_dir}/go.mod" ]; then
        echo "go"
        return
    fi

    # Rust
    if [ -f "${project_dir}/Cargo.toml" ]; then
        echo "rust"
        return
    fi

    echo "unknown"
}

detect_tools() {
    local project_type="$1"
    local project_dir="$2"

    case "${project_type}" in
        typescript|javascript|angular|react|nextjs|express)
            # Package manager
            if [ -f "${project_dir}/yarn.lock" ]; then
                echo "package_manager=yarn"
            elif [ -f "${project_dir}/pnpm-lock.yaml" ]; then
                echo "package_manager=pnpm"
            elif [ -f "${project_dir}/bun.lockb" ]; then
                echo "package_manager=bun"
            else
                echo "package_manager=npm"
            fi

            # Test framework
            if grep -q '"jest"' "${project_dir}/package.json" 2>/dev/null; then
                echo "test_framework=jest"
            elif grep -q '"vitest"' "${project_dir}/package.json" 2>/dev/null; then
                echo "test_framework=vitest"
            elif grep -q '"mocha"' "${project_dir}/package.json" 2>/dev/null; then
                echo "test_framework=mocha"
            else
                echo "test_framework=unknown"
            fi
            ;;

        python|flask)
            # Test framework
            if [ -f "${project_dir}/pytest.ini" ] || grep -q "pytest" "${project_dir}/requirements.txt" 2>/dev/null; then
                echo "test_framework=pytest"
            else
                echo "test_framework=unittest"
            fi

            # Package manager
            if [ -f "${project_dir}/poetry.lock" ]; then
                echo "package_manager=poetry"
            elif [ -f "${project_dir}/Pipfile" ]; then
                echo "package_manager=pipenv"
            else
                echo "package_manager=pip"
            fi
            ;;

        ruby)
            echo "package_manager=bundler"
            if [ -f "${project_dir}/Gemfile" ] && grep -q "rspec" "${project_dir}/Gemfile" 2>/dev/null; then
                echo "test_framework=rspec"
            else
                echo "test_framework=minitest"
            fi
            ;;

        go)
            echo "test_framework=testing"
            echo "package_manager=go"
            ;;

        rust)
            echo "test_framework=cargo-test"
            echo "package_manager=cargo"
            ;;

        nx)
            # Package manager detected from lockfiles
            if [ -f "${project_dir}/yarn.lock" ]; then
                echo "package_manager=yarn"
            elif [ -f "${project_dir}/pnpm-lock.yaml" ]; then
                echo "package_manager=pnpm"
            elif [ -f "${project_dir}/bun.lockb" ]; then
                echo "package_manager=bun"
            else
                echo "package_manager=npm"
            fi
            # Nx Cloud detection
            if grep -q '"nxCloudId"\|"nxCloudAccessToken"' "${project_dir}/nx.json" 2>/dev/null; then
                echo "nx_cloud=true"
            else
                echo "nx_cloud=false"
            fi
            ;;
    esac
}

#==============================================================================
# Interactive Questions
#==============================================================================

ask_project_questions() {
    local project_type="$1"
    local detected_tools="$2"

    echo
    print_info "Project Configuration"
    echo

    case "${project_type}" in
        typescript|javascript)
            # Package manager
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            # Test framework
            local default_test=$(echo "${detected_tools}" | grep "test_framework=" | cut -d= -f2)
            if [ -z "${default_test}" ] || [ "${default_test}" = "unknown" ]; then
                default_test="jest"
            fi

            echo "Test framework? (jest/vitest/mocha) [${default_test}]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-$default_test}"

            # Build tool
            echo "Use build tool? (none/webpack/vite/esbuild) [vite]:"
            read -r build_choice
            PROJECT_CONFIG[build_tool]="${build_choice:-vite}"
            ;;

        angular)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm) [${default_pm}]:"
            read -r pm_choice
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (karma/jest) [karma]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-karma}"
            ;;

        react)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (jest/vitest) [vitest]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-vitest}"

            echo "Build tool? (vite/create-react-app) [vite]:"
            read -r build_choice
            PROJECT_CONFIG[build_tool]="${build_choice:-vite}"
            ;;

        nextjs)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (jest/vitest) [jest]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-jest}"

            echo "Use App Router? (yes/no) [yes]:"
            read -r router_choice
            PROJECT_CONFIG[app_router]="${router_choice:-yes}"
            ;;

        express)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (jest/mocha/supertest) [jest]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-jest}"

            echo "Use TypeScript? (yes/no) [yes]:"
            read -r ts_choice
            PROJECT_CONFIG[typescript]="${ts_choice:-yes}"
            ;;

        python)
            # Package manager
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="pip"
            fi

            echo "Package manager? (pip/poetry/pipenv) [${default_pm}]:"
            read -r pm_choice
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            # Test framework
            local default_test=$(echo "${detected_tools}" | grep "test_framework=" | cut -d= -f2)
            if [ -z "${default_test}" ] || [ "${default_test}" = "unknown" ]; then
                default_test="pytest"
            fi

            echo "Test framework? (pytest/unittest) [${default_test}]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-$default_test}"

            # Type checking
            echo "Use type checking? (mypy/pyright/none) [mypy]:"
            read -r type_choice
            PROJECT_CONFIG[type_checker]="${type_choice:-mypy}"
            ;;

        flask)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="pip"
            fi

            echo "Package manager? (pip/poetry/pipenv) [${default_pm}]:"
            read -r pm_choice
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (pytest/unittest) [pytest]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-pytest}"

            echo "Use SQLAlchemy? (yes/no) [no]:"
            read -r db_choice
            PROJECT_CONFIG[sqlalchemy]="${db_choice:-no}"
            ;;

        ruby)
            echo "Test framework? (rspec/minitest) [rspec]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-rspec}"

            echo "Use Bundler? (yes/no) [yes]:"
            read -r bundler_choice
            PROJECT_CONFIG[package_manager]="bundler"
            ;;

        go)
            PROJECT_CONFIG[package_manager]="go"
            PROJECT_CONFIG[test_framework]="testing"

            echo "Use additional test framework? (testify/ginkgo/none) [none]:"
            read -r test_choice
            PROJECT_CONFIG[additional_test]="${test_choice:-none}"
            ;;

        rust)
            PROJECT_CONFIG[package_manager]="cargo"
            PROJECT_CONFIG[test_framework]="cargo-test"

            echo "Use workspace? (yes/no) [no]:"
            read -r workspace_choice
            PROJECT_CONFIG[workspace]="${workspace_choice:-no}"
            ;;

        nx)
            # Workspace type
            echo "Workspace type? (integrated/package-based) [integrated]:"
            read -r ws_type
            PROJECT_CONFIG[nx_workspace_type]="${ws_type:-integrated}"

            # Package manager
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi
            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            # Frontend apps
            echo
            print_info "Frontend applications to scaffold (space-separated, or 'none'):"
            echo "  Options: react angular nextjs vue"
            echo "  Example: react nextjs"
            echo "  [none]:"
            read -r frontend_choice
            PROJECT_CONFIG[nx_frontends]="${frontend_choice:-none}"

            # Backend apps
            echo
            print_info "Backend applications to scaffold (space-separated, or 'none'):"
            echo "  Options: nest express node"
            echo "  Example: nest express"
            echo "  [none]:"
            read -r backend_choice
            PROJECT_CONFIG[nx_backends]="${backend_choice:-none}"

            # E2E framework
            echo
            echo "E2E test framework? (playwright/cypress/none) [playwright]:"
            read -r e2e_choice
            PROJECT_CONFIG[nx_e2e]="${e2e_choice:-playwright}"

            # Unit test runner (default; each app can override)
            echo "Default unit test runner? (jest/vitest) [jest]:"
            read -r unit_choice
            PROJECT_CONFIG[nx_unit_test]="${unit_choice:-jest}"

            # Nx Cloud
            echo "Connect to Nx Cloud for remote caching? (yes/no) [no]:"
            read -r cloud_choice
            PROJECT_CONFIG[nx_cloud]="${cloud_choice:-no}"

            # Community language plugins
            echo
            print_info "Community language plugins (space-separated, or 'none'):"
            echo "  Options: python go"
            echo "  [none]:"
            read -r community_choice
            PROJECT_CONFIG[nx_community]="${community_choice:-none}"
            ;;

        *)
            print_warning "Unknown project type '${project_type}' — skipping type-specific configuration"
            print_info "You can manually configure build tools and test frameworks after project creation"
            ;;
    esac

    # Common questions for all types (skip for nx — it manages its own browser testing)
    if [ "${project_type}" != "nx" ]; then
        echo
        echo "Include browser testing setup? (yes/no) [yes]:"
        read -r browser_choice
        PROJECT_CONFIG[browser_testing]="${browser_choice:-yes}"
    fi

    echo
}

#==============================================================================
# Project Initialization
#==============================================================================

backup_file() {
    local file="$1"
    local backup_dir="$2"

    if [ -f "${file}" ]; then
        mkdir -p "${backup_dir}"
        cp "${file}" "${backup_dir}/$(basename "${file}")${BACKUP_SUFFIX}"
        print_warning "Backed up: $(basename "${file}")"
    fi
}

create_ralph_structure() {
    local project_dir="$1"
    local backup_dir="${project_dir}/.ralph-backups"

    print_info "Creating Ralph Loop directory structure..."

    # Backup existing files
    backup_file "${project_dir}/CLAUDE.md" "${backup_dir}"
    backup_file "${project_dir}/.gitignore" "${backup_dir}"

    # Create directories — all Ralph content lives under ralph/ except .claude/ (root)
    mkdir -p "${project_dir}/.claude/templates"
    mkdir -p "${project_dir}/.claude/feedback-configs"
    mkdir -p "${project_dir}/ralph/specs/prds"
    mkdir -p "${project_dir}/ralph/specs/openspecs"
    mkdir -p "${project_dir}/ralph/archive"
    mkdir -p "${project_dir}/ralph/docs"
    mkdir -p "${project_dir}/ralph/tests/browser"
    mkdir -p "${project_dir}/ralph/feedback"

    # Copy template/config files into ralph/
    cp "${SCRIPT_DIR}/.ralph-state-template.json" "${project_dir}/ralph/"
    cp "${SCRIPT_DIR}/.ralph-story-template.json" "${project_dir}/ralph/"
    cp "${SCRIPT_DIR}/.ralph-quota-config.json" "${project_dir}/ralph/"

    # Copy Claude templates (stay in .claude/ at root)
    cp "${SCRIPT_DIR}/.claude/templates/prd-template.md" "${project_dir}/.claude/templates/"
    cp "${SCRIPT_DIR}/.claude/templates/openspec-template.yaml" "${project_dir}/.claude/templates/"

    # Copy documentation into ralph/docs/
    for doc in "${SCRIPT_DIR}"/docs/*.md; do
        if [ -f "${doc}" ]; then
            cp "${doc}" "${project_dir}/ralph/docs/"
        fi
    done

    print_success "Created Ralph Loop structure"
}

create_claude_md() {
    local project_dir="$1"
    local project_type="$2"

    local claude_md="${project_dir}/CLAUDE.md"

    cat > "${claude_md}" << 'EOF'
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project uses the **Ralph Loop Framework** for specification-driven development with:
- PRD/OpenSpec-style requirements
- Parallel implementation with Claude Tasks
- Automated testing and validation
- Comprehensive archival

## Ralph Loop Commands

### Create Specification
```bash
/ralph-create-prd          # Interactive PRD creation
/parse-prd <file>          # Parse existing PRD
/parse-openspec <file>     # Parse OpenSpec file
```

### Run Development Loop
```bash
/ralph-loop                # Start full RALPH cycle
/ralph-status              # Check current progress
/ralph-resume              # Resume paused run
/ralph-archive             # Archive and merge results
```

### Modify Specifications
```bash
/ralph-modify-spec         # Full modification interface
/ralph-add-requirement     # Quick add single requirement
```

### Testing & Validation
```bash
/test-spec                 # Test against requirements
/prove-requirements        # Comprehensive validation
/browser-test              # UI testing with Playwright
/feedback-selector         # Determine test strategy
```

## Workflow

1. **Create PRD**: `/ralph-create-prd` - Interactive requirement gathering
2. **Review Spec**: Check `ralph/specs/prds/` for generated specification
3. **Run Loop**: `/ralph-loop` - Automated implementation
4. **Monitor**: `/ralph-status` - Track progress and quota
5. **Resume if needed**: `/ralph-resume` - Continue after pause
6. **Archive**: `/ralph-archive` - Validate, merge, and archive

## Ralph Loop Features

### Parallel Execution
- Max 3 concurrent Claude Task subagents
- Dependency-aware scheduling
- Code conflict detection

### Quota Management
- Automatic token tracking
- Pause at 85% threshold (configurable)
- Resume capability with state preservation
- Cost estimation before tasks

### Git Integration
- Branch: `ralph/<spec-name>-<timestamp>`
- One commit per requirement (REQ-XXX)
- Merge during archive (after validation)
- Ralph branch preserved by default

### Testing Strategy
- Lint checks before implementation
- Unit tests per story
- Integration tests per phase
- Browser tests for UI (if applicable)
- Code quality validation

### Spec Modifications
- Add requirements during run
- Modify existing requirements
- Change priorities dynamically
- Full version tracking with backups
- No progress lost

## State Management

Ralph Loop maintains state in `ralph/.ralph/` directory:
- `state.json` - Current run state and quota
- `stories.json` - All stories with dependencies
- `tasks.json` - Claude Task mappings
- `phases.json` - Execution phases

**Never manually edit state files** - use Ralph commands.

## Archive Structure

After completion, find archives in `ralph/archive/<run-id>/`:
- `summary.md` - Run overview and results
- `spec/` - All spec versions
- `code/` - Final implementation
- `tests/` - All test results
- `git/` - Commits and diffs
- `artifacts/` - Task outputs and logs
- `metrics/` - Quota usage and timing

## Configuration

### Quota Limits
Edit `ralph/.ralph-quota-config.json`:
```json
{
  "limits": {
    "contextWindow": 200000,
    "safetyThreshold": 0.85,
    "warningThreshold": 0.75
  }
}
```

### Max Iterations
```json
{
  "maxIterations": {
    "enabled": true,
    "logic": 5,
    "formatting": 3
  }
}
```

## Best Practices

1. **Start with clear requirements** - Use `/ralph-create-prd` for guidance
2. **Review generated spec** - Verify requirements before running loop
3. **Monitor quota** - Use `/ralph-status` during long runs
4. **Modify specs when needed** - Don't hesitate to add missing requirements
5. **Review archives** - Learn from completed runs
6. **Keep Ralph branches** - Useful for audit trail

## Troubleshooting

- **Quota exhausted**: `/ralph-resume` after context replenishes
- **Test failures**: Ralph pauses automatically, fix and resume
- **Spec gaps**: `/ralph-add-requirement` to add missing requirements
- **Circular dependencies**: Modify spec with `/ralph-modify-spec`
- **Merge conflicts**: Manually resolve, Ralph detects git state

## Additional Resources

- `ralph/docs/QUICKSTART.md` - Getting started guide
- `ralph/docs/COMPLETE-WORKFLOW.md` - Detailed workflow with examples
- `ralph/docs/QUOTA-MANAGEMENT.md` - Quota strategies
- `ralph/docs/SPEC-MODIFICATIONS.md` - Modifying specs during runs

EOF

    # Add project-specific sections
    case "${project_type}" in
        typescript)
            cat >> "${claude_md}" << 'EOF'

## TypeScript Specific

### Build Commands
```bash
npm run build          # Production build
npm run dev            # Development server
npm run type-check     # TypeScript checking
```

### Test Commands
```bash
npm test              # Run all tests
npm run test:watch    # Watch mode
npm run test:coverage # Coverage report
```

### Lint Commands
```bash
npm run lint          # ESLint check
npm run lint:fix      # Auto-fix issues
```

EOF
            ;;

        python)
            cat >> "${claude_md}" << 'EOF'

## Python Specific

### Setup Commands
```bash
python -m venv venv            # Create virtual environment
source venv/bin/activate       # Activate (Linux/Mac)
pip install -r requirements.txt # Install dependencies
```

### Test Commands
```bash
pytest                # Run all tests
pytest -v             # Verbose output
pytest --cov          # Coverage report
```

### Lint Commands
```bash
flake8 .              # Style checking
mypy .                # Type checking
black .               # Code formatting
```

EOF
            ;;

        go)
            cat >> "${claude_md}" << 'EOF'

## Go Specific

### Build Commands
```bash
go build ./...        # Build all packages
go run main.go        # Run main
go install            # Install binary
```

### Test Commands
```bash
go test ./...         # Run all tests
go test -v ./...      # Verbose output
go test -cover ./...  # Coverage report
```

### Lint Commands
```bash
go fmt ./...          # Format code
go vet ./...          # Vet code
golangci-lint run     # Full linting
```

EOF
            ;;

        rust)
            cat >> "${claude_md}" << 'EOF'

## Rust Specific

### Build Commands
```bash
cargo build           # Debug build
cargo build --release # Release build
cargo run             # Build and run
```

### Test Commands
```bash
cargo test            # Run all tests
cargo test -- --nocapture  # Show output
cargo bench           # Run benchmarks
```

### Lint Commands
```bash
cargo fmt             # Format code
cargo clippy          # Lint code
cargo check           # Quick check
```

EOF
            ;;

        angular)
            cat >> "${claude_md}" << 'EOF'

## Angular Specific

### Development Commands
```bash
ng serve              # Dev server (localhost:4200)
ng build              # Production build
ng build --watch      # Watch mode
```

### Test Commands
```bash
ng test               # Run unit tests (Karma)
ng e2e                # Run end-to-end tests
ng test --code-coverage # Coverage report
```

### Lint Commands
```bash
ng lint               # ESLint check
```

### Generate Commands
```bash
ng generate component <name>   # New component
ng generate service <name>     # New service
ng generate module <name>      # New module
```

EOF
            ;;

        react)
            cat >> "${claude_md}" << 'EOF'

## React Specific

### Development Commands
```bash
npm run dev           # Dev server (Vite)
npm run build         # Production build
npm run preview       # Preview production build
```

### Test Commands
```bash
npm test              # Run tests
npm run test:coverage # Coverage report
```

### Lint Commands
```bash
npm run lint          # ESLint check
npm run lint:fix      # Auto-fix issues
```

EOF
            ;;

        nextjs)
            cat >> "${claude_md}" << 'EOF'

## Next.js Specific

### Development Commands
```bash
npm run dev           # Dev server (localhost:3000)
npm run build         # Production build
npm start             # Start production server
```

### Test Commands
```bash
npm test              # Run tests
npm run test:coverage # Coverage report
```

### Lint Commands
```bash
npm run lint          # Next.js ESLint check
```

### Key Conventions
- App Router: `src/app/` directory
- API Routes: `src/app/api/` directory
- Server Components by default; add `'use client'` for client components

EOF
            ;;

        express)
            cat >> "${claude_md}" << 'EOF'

## Express Specific

### Development Commands
```bash
npm run dev           # Dev server with hot reload (nodemon)
npm start             # Production start
npm run build         # TypeScript compile (if applicable)
```

### Test Commands
```bash
npm test              # Run tests
npm run test:coverage # Coverage report
```

### Lint Commands
```bash
npm run lint          # ESLint check
npm run lint:fix      # Auto-fix issues
```

EOF
            ;;

        flask)
            cat >> "${claude_md}" << 'EOF'

## Flask Specific

### Setup Commands
```bash
python -m venv venv            # Create virtual environment
source venv/bin/activate       # Activate (Linux/Mac)
pip install -r requirements.txt # Install dependencies
```

### Development Commands
```bash
flask run             # Dev server (localhost:5000)
flask run --debug     # Debug mode with reload
```

### Test Commands
```bash
pytest                # Run all tests
pytest -v             # Verbose output
pytest --cov          # Coverage report
```

### Lint Commands
```bash
flake8 .              # Style checking
black .               # Code formatting
mypy .                # Type checking (if configured)
```

EOF
            ;;

        ruby)
            cat >> "${claude_md}" << 'EOF'

## Ruby Specific

### Setup Commands
```bash
bundle install        # Install dependencies
```

### Development Commands
```bash
ruby run.rb           # Run the application
ruby -e "require './lib/app'"  # Quick REPL test
```

### Test Commands
```bash
rspec                 # Run all tests (RSpec)
rspec --format documentation  # Verbose output
bundle exec rake test # Run Minitest suite
```

### Lint Commands
```bash
rubocop               # Style and lint check
rubocop -a            # Auto-fix safe offenses
```

EOF
            ;;

        nx)
            cat >> "${claude_md}" << 'EOF'

## NX Monorepo Specific

### Core NX Commands
```bash
nx graph                          # Visualize project dependency graph
nx show projects                  # List all projects in the workspace
nx show project <name>            # Show project targets and config
nx reset                          # Clear local cache
nx connect                        # Connect to Nx Cloud (remote cache)
```

### Running Tasks
```bash
nx run <project>:<target>         # Run a target for a specific project
nx run <project>:build            # Build a project
nx run <project>:test             # Test a project
nx run <project>:lint             # Lint a project
nx run <project>:serve            # Serve/start a project
nx run-many -t build              # Build all projects
nx run-many -t test               # Test all projects
nx run-many -t build,test,lint    # Multiple targets at once
```

### Affected Commands (CI/CD — only run what changed)
```bash
nx affected -t build              # Build only affected projects
nx affected -t test               # Test only affected projects
nx affected -t lint               # Lint only affected projects
nx affected -t build,test,lint    # All affected tasks at once
```

### Generating Code
```bash
nx generate @nx/react:application <name>    # Add a React app
nx generate @nx/angular:application <name>  # Add an Angular app
nx generate @nx/next:application <name>     # Add a Next.js app
nx generate @nx/vue:application <name>      # Add a Vue app
nx generate @nx/nest:application <name>     # Add a NestJS API
nx generate @nx/express:application <name>  # Add an Express API
nx generate @nx/node:application <name>     # Add a Node app
nx generate @nx/js:library <name>           # Add a shared TypeScript library
```

### Adding Plugins
```bash
nx add @nx/react
nx add @nx/nest
nx add @nxlv/python
nx add @nx-go/nx-go
```

### Migrations & Maintenance
```bash
nx migrate latest                 # Update Nx and plugins
nx migrate --run-migrations       # Apply pending migrations
nx format:write                   # Format all files with Prettier
nx format:check                   # Check formatting
```

## NX + Ralph Loop Notes

- Ralph tasks run per-project: `nx run <project>:test` not bare `npm test`
- Use `nx affected` in CI to skip unaffected projects
- Store `.nx/cache` in CI cache for faster runs
- Project tags (`scope:`, `type:`) enforce architectural boundaries
- Check `ralph/.ralph/nx-workspace.json` for workspace metadata used by Ralph

EOF
            ;;
    esac

    print_success "Created CLAUDE.md"
}

create_gitignore() {
    local project_dir="$1"
    local gitignore="${project_dir}/.gitignore"

    # Read existing .gitignore if it exists
    local existing_content=""
    if [ -f "${gitignore}" ]; then
        existing_content=$(cat "${gitignore}")
    fi

    # Check if Ralph Loop entries already exist
    if echo "${existing_content}" | grep -q "# Ralph Loop Framework"; then
        print_info ".gitignore already has Ralph Loop entries"
        return
    fi

    # Append Ralph Loop entries
    cat >> "${gitignore}" << 'EOF'

# Ralph Loop Framework - Runtime State (never tracked)
ralph/.ralph/

# Ralph templates/configs are tracked (checked-in defaults)
!ralph/.ralph-state-template.json
!ralph/.ralph-story-template.json
!ralph/.ralph-quota-config.json

# Checkpoints (can be regenerated)
.claude/checkpoints/

# Feedback results (can be regenerated)
ralph/feedback/
!ralph/feedback/.gitkeep

# Auto-generated feedback configs
.claude/feedback-configs/*.json

# Ralph backups (from installation)
.ralph-backups/
EOF

    print_success "Updated .gitignore with Ralph Loop entries"
}

create_readme() {
    local project_dir="$1"
    local project_name="$2"
    local project_type="$3"

    local readme="${project_dir}/README.md"

    # Don't overwrite existing README, just create if missing
    if [ -f "${readme}" ]; then
        print_info "README.md already exists, skipping"
        return
    fi

    cat > "${readme}" << EOF
# ${project_name}

A ${project_type} project built with the Ralph Loop Framework.

## Getting Started

### Prerequisites

- Claude Code CLI
- Ralph Loop Framework (installed)

### Development Workflow

1. **Create Specification**:
   \`\`\`bash
   /ralph-create-prd
   \`\`\`

2. **Run Development Loop**:
   \`\`\`bash
   /ralph-loop
   \`\`\`

3. **Monitor Progress**:
   \`\`\`bash
   /ralph-status
   \`\`\`

4. **Archive Results**:
   \`\`\`bash
   /ralph-archive
   \`\`\`

## Ralph Loop Commands

- \`/ralph-create-prd\` - Interactive PRD creation
- \`/ralph-loop\` - Run full development cycle
- \`/ralph-status\` - Check progress and quota
- \`/ralph-resume\` - Resume paused run
- \`/ralph-archive\` - Archive and merge
- \`/ralph-modify-spec\` - Modify specifications during run

## Documentation

- \`CLAUDE.md\` - Claude Code guidance
- \`ralph/docs/QUICKSTART.md\` - Quick start guide
- \`ralph/docs/COMPLETE-WORKFLOW.md\` - Complete workflow examples
- \`ralph/docs/QUOTA-MANAGEMENT.md\` - Quota management strategies

## Project Structure

\`\`\`
${project_name}/
├── .claude/             # Claude Code configuration (root — required)
├── ralph/
│   ├── specs/prds/      # Product requirement documents
│   ├── archive/         # Completed runs
│   ├── .ralph/          # Runtime state (not tracked)
│   ├── docs/            # Ralph Loop documentation
│   └── tests/           # Test files
\`\`\`

## License

[Your License Here]
EOF

    print_success "Created README.md"
}

create_project_settings() {
    local project_dir="$1"
    local settings_file="${project_dir}/.claude/settings.json"
    local backup_dir="${project_dir}/.ralph-backups"

    mkdir -p "${project_dir}/.claude"

    # The full set of permissions Ralph Loop needs
    # Passed as a JSON array via environment variable to avoid glob expansion issues
    local RALPH_PERMS='["Bash(*)","Read(**)","Write(**)","Edit(**)","Read(/tmp/**)","Write(/tmp/**)","Edit(/tmp/**)","Read(~/.claude/**)","Write(~/.claude/skills/**)","Edit(~/.claude/skills/**)","Write(~/.claude/commands/**)","Edit(~/.claude/commands/**)"]'

    if [ ! -f "${settings_file}" ]; then
        # Fresh install — write the file directly
        cat > "${settings_file}" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(**)",
      "Write(**)",
      "Edit(**)",
      "Read(/tmp/**)",
      "Write(/tmp/**)",
      "Edit(/tmp/**)",
      "Read(~/.claude/**)",
      "Write(~/.claude/skills/**)",
      "Edit(~/.claude/skills/**)",
      "Write(~/.claude/commands/**)",
      "Edit(~/.claude/commands/**)"
    ]
  }
}
EOF
        print_success "Created .claude/settings.json with Ralph Loop permissions"
        return
    fi

    # Existing file — merge missing permissions in
    print_info "Merging Ralph Loop permissions into existing .claude/settings.json..."
    backup_file "${settings_file}" "${backup_dir}"

    local merged=false

    if command -v python3 &>/dev/null; then
        local result
        result=$(SETTINGS_FILE="${settings_file}" RALPH_PERMS="${RALPH_PERMS}" python3 -c "
import json, os, sys

sf = os.environ['SETTINGS_FILE']
required = json.loads(os.environ['RALPH_PERMS'])

with open(sf) as f:
    s = json.load(f)

if 'permissions' not in s:
    s['permissions'] = {}
if 'allow' not in s['permissions']:
    s['permissions']['allow'] = []

existing = s['permissions']['allow']
added = [p for p in required if p not in existing]
existing.extend(added)

with open(sf, 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')

if added:
    print('Added ' + str(len(added)) + ' permission(s): ' + ', '.join(added))
else:
    print('All Ralph permissions already present')
" 2>&1) && merged=true
        print_success "${result}"
    fi

    if [ "${merged}" = false ] && command -v node &>/dev/null; then
        local result
        result=$(SETTINGS_FILE="${settings_file}" RALPH_PERMS="${RALPH_PERMS}" node -e "
const fs = require('fs');
const sf = process.env.SETTINGS_FILE;
const required = JSON.parse(process.env.RALPH_PERMS);
const s = JSON.parse(fs.readFileSync(sf, 'utf8'));

if (!s.permissions) s.permissions = {};
if (!s.permissions.allow) s.permissions.allow = [];

const added = required.filter(p => !s.permissions.allow.includes(p));
s.permissions.allow.push(...added);
fs.writeFileSync(sf, JSON.stringify(s, null, 2) + '\n');

console.log(added.length
    ? 'Added ' + added.length + ' permission(s): ' + added.join(', ')
    : 'All Ralph permissions already present');
" 2>&1) && merged=true
        print_success "${result}"
    fi

    if [ "${merged}" = false ]; then
        print_warning "python3 and node unavailable — overwriting .claude/settings.json (original backed up to ${backup_dir})"
        cat > "${settings_file}" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(**)",
      "Write(**)",
      "Edit(**)",
      "Read(/tmp/**)",
      "Write(/tmp/**)",
      "Edit(/tmp/**)",
      "Read(~/.claude/**)",
      "Write(~/.claude/skills/**)",
      "Edit(~/.claude/skills/**)",
      "Write(~/.claude/commands/**)",
      "Edit(~/.claude/commands/**)"
    ]
  }
}
EOF
        print_success "Wrote .claude/settings.json with Ralph Loop permissions"
    fi
}

initialize_existing_project() {
    local project_dir="$1"

    print_info "Initializing Ralph Loop in existing project..."
    echo

    # Detect project type
    local project_type=$(detect_project_type "${project_dir}")
    if [ "${project_type}" = "unknown" ]; then
        print_warning "Could not auto-detect project type from existing files"
        while true; do
            echo "Project type? (typescript/javascript/angular/react/nextjs/express/python/flask/go/rust/ruby) [typescript]:"
            read -r type_choice
            project_type="${type_choice:-typescript}"
            case "${project_type}" in
                typescript|javascript|angular|react|nextjs|express|python|flask|go|rust|ruby|nx) break ;;
                *)
                    print_error "Unknown project type: '${project_type}'"
                    print_info "Valid types: typescript, javascript, angular, react, nextjs, express, python, flask, go, rust, ruby, nx"
                    ;;
            esac
        done
    fi
    print_info "Project type: ${project_type}"

    # Detect existing tools
    local detected_tools=$(detect_tools "${project_type}" "${project_dir}")
    if [ -n "${detected_tools}" ]; then
        print_info "Detected tools:"
        echo "${detected_tools}" | while read -r line; do
            echo "  - ${line}"
        done
    fi

    # Ask configuration questions
    declare -A PROJECT_CONFIG
    ask_project_questions "${project_type}" "${detected_tools}"

    # Create Ralph structure
    create_ralph_structure "${project_dir}"

    # Create/update configuration files
    create_claude_md "${project_dir}" "${project_type}"
    create_gitignore "${project_dir}"
    create_project_settings "${project_dir}"

    echo
    print_success "Ralph Loop Framework initialized successfully!"
    print_info "Project configured with:"
    for key in "${!PROJECT_CONFIG[@]}"; do
        echo "  - ${key}: ${PROJECT_CONFIG[$key]}"
    done
    echo
}

create_new_project() {
    local project_name="$1"
    local project_type="$2"
    local parent_dir="${3:-.}"

    local project_dir="${parent_dir}/${project_name}"

    print_info "Creating new project: ${project_name}"
    echo

    # Detect project type if not specified (needed before dir creation for nx path)
    if [ -z "${project_type}" ] || [ "${project_type}" = "unknown" ]; then
        while true; do
            echo "Project type? (typescript/javascript/angular/react/nextjs/express/python/flask/go/rust/ruby/nx) [typescript]:"
            read -r type_choice
            project_type="${type_choice:-typescript}"
            case "${project_type}" in
                typescript|javascript|angular|react|nextjs|express|python|flask|go|rust|ruby|nx) break ;;
                *)
                    print_error "Unknown project type: '${project_type}'"
                    print_info "Valid types: typescript, javascript, angular, react, nextjs, express, python, flask, go, rust, ruby, nx"
                    ;;
            esac
        done
    fi

    print_info "Project type: ${project_type}"

    # NX takes a completely different path: create-nx-workspace handles directory
    # creation itself, so we must NOT pre-create the dir. Ask questions, then run
    # from parent_dir and cd into the workspace afterward.
    if [ "${project_type}" = "nx" ]; then
        if [ -d "${project_dir}" ]; then
            print_error "Directory already exists: ${project_dir}"
            exit 1
        fi
        mkdir -p "${parent_dir}"
        cd "${parent_dir}"
        declare -A PROJECT_CONFIG
        ask_project_questions "nx" ""
        create_nx_project "${parent_dir}" "${project_name}"
        cd "${project_dir}"
        create_ralph_structure "."
        create_claude_md "." "nx"
        create_gitignore "."
        create_project_settings "."
        # Git commit is deferred to main() so skills are included
        echo
        print_success "Project created successfully: ${project_dir}"
        print_info "Project configured with:"
        for key in "${!PROJECT_CONFIG[@]}"; do
            echo "  - ${key}: ${PROJECT_CONFIG[$key]}"
        done
        echo
        print_info "Next steps:"
        echo "  1. cd ${project_name}"
        echo "  2. /ralph-create-prd"
        echo "  3. /ralph-loop"
        echo
        return
    fi

    # Non-NX path: pre-create directory and git init as before
    # Check if directory already exists
    if [ -d "${project_dir}" ]; then
        print_error "Directory already exists: ${project_dir}"
        echo "Use --init to add Ralph Loop to existing project"
        exit 1
    fi

    # Create project directory
    mkdir -p "${project_dir}"
    cd "${project_dir}"

    # Initialize git if not already in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        git init
        print_success "Initialized git repository in project"
    fi

    # Ask configuration questions
    declare -A PROJECT_CONFIG
    ask_project_questions "${project_type}" ""

    # Create basic project structure based on type
    case "${project_type}" in
        typescript|javascript)
            create_typescript_project "."
            ;;
        angular)
            create_angular_project "." "${project_name}"
            ;;
        react)
            create_react_project "." "${project_name}"
            ;;
        nextjs)
            create_nextjs_project "." "${project_name}"
            ;;
        express)
            create_express_project "." "${project_name}"
            ;;
        python)
            create_python_project "."
            ;;
        flask)
            create_flask_project "." "${project_name}"
            ;;
        ruby)
            create_ruby_project "." "${project_name}"
            ;;
        go)
            create_go_project "." "${project_name}"
            ;;
        rust)
            create_rust_project "." "${project_name}"
            ;;
        *)
            print_warning "No scaffold available for project type '${project_type}'"
            print_info "Ralph structure will be created — add your language files manually"
            ;;
    esac

    # Create Ralph structure
    create_ralph_structure "."

    # Create configuration files
    create_claude_md "." "${project_type}"
    create_gitignore "."
    create_readme "." "${project_name}" "${project_type}"
    create_project_settings "."
    # Git commit is deferred to main() so skills are included

    echo
    print_success "Project created successfully: ${project_dir}"
    print_info "Project configured with:"
    for key in "${!PROJECT_CONFIG[@]}"; do
        echo "  - ${key}: ${PROJECT_CONFIG[$key]}"
    done
    echo
    print_info "Next steps:"
    echo "  1. cd ${project_name}"
    echo "  2. /ralph-create-prd"
    echo "  3. /ralph-loop"
    echo
}

#==============================================================================
# Project Type Creators
#==============================================================================

create_typescript_project() {
    local project_dir="$1"

    # Create basic TypeScript structure
    mkdir -p "${project_dir}/src"
    mkdir -p "${project_dir}/tests"

    # package.json — Node.js TypeScript with jest + ts-jest + eslint
    cat > "${project_dir}/package.json" << 'EOF'
{
  "name": "project",
  "version": "1.0.0",
  "scripts": {
    "dev": "ts-node src/index.ts",
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src tests --ext .ts"
  },
  "devDependencies": {
    "@types/jest": "^29.5.14",
    "@types/node": "^22.0.0",
    "@typescript-eslint/eslint-plugin": "^7.18.0",
    "@typescript-eslint/parser": "^7.18.0",
    "eslint": "^8.57.1",
    "jest": "^29.7.0",
    "ts-jest": "^29.2.5",
    "ts-node": "^10.9.2",
    "typescript": "^5.6.3"
  }
}
EOF

    # tsconfig.json — CommonJS for jest compatibility
    cat > "${project_dir}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
EOF

    # jest.config.ts
    cat > "${project_dir}/jest.config.ts" << 'EOF'
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.ts'],
  collectCoverageFrom: ['src/**/*.ts'],
};

export default config;
EOF

    # .eslintrc.json
    cat > "${project_dir}/.eslintrc.json" << 'EOF'
{
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  "env": { "node": true, "jest": true }
}
EOF

    # src/index.ts
    cat > "${project_dir}/src/index.ts" << 'EOF'
// Ralph Loop Framework - TypeScript Project

export function greet(name: string): string {
  return `Hello, ${name}!`;
}

if (require.main === module) {
  console.log(greet('Ralph Loop'));
}
EOF

    # tests/index.test.ts
    cat > "${project_dir}/tests/index.test.ts" << 'EOF'
import { greet } from '../src/index';

describe('greet', () => {
  it('returns a greeting with the given name', () => {
    expect(greet('World')).toBe('Hello, World!');
  });

  it('returns a greeting for Ralph Loop', () => {
    expect(greet('Ralph Loop')).toBe('Hello, Ralph Loop!');
  });
});
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
node_modules/
dist/
coverage/
.nyc_output/
*.js.map
.env
.env.local
EOF

    print_info "Installing npm dependencies..."
    (cd "${project_dir}" && npm install --silent) && print_success "npm install complete" || print_warning "npm install failed — run manually: cd ${project_dir} && npm install"

    print_success "Created TypeScript project structure"
}

create_python_project() {
    local project_dir="$1"

    # Create basic Python structure
    mkdir -p "${project_dir}/src"
    mkdir -p "${project_dir}/tests"

    # requirements.txt
    cat > "${project_dir}/requirements.txt" << 'EOF'
pytest>=8.3.0
pytest-cov>=5.0.0
black>=24.10.0
flake8>=7.1.0
mypy>=1.11.0
EOF

    # setup.py
    cat > "${project_dir}/setup.py" << 'EOF'
from setuptools import setup, find_packages

setup(
    name="project",
    version="1.0.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.8",
)
EOF

    # src/__init__.py
    touch "${project_dir}/src/__init__.py"

    # src/main.py
    cat > "${project_dir}/src/main.py" << 'EOF'
"""Ralph Loop Framework - Python Project"""


def greet(name: str) -> str:
    """Return a greeting for the given name."""
    return f"Hello, {name}!"


def main():
    print(greet("Ralph Loop"))


if __name__ == "__main__":
    main()
EOF

    # tests/__init__.py
    touch "${project_dir}/tests/__init__.py"

    # tests/test_main.py
    cat > "${project_dir}/tests/test_main.py" << 'EOF'
"""Tests for src/main.py"""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from main import greet


def test_greet_returns_greeting():
    assert greet("World") == "Hello, World!"


def test_greet_ralph_loop():
    assert greet("Ralph Loop") == "Hello, Ralph Loop!"
EOF

    # pytest.ini
    cat > "${project_dir}/pytest.ini" << 'EOF'
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = --cov=src --cov-report=term-missing
EOF

    # .flake8
    cat > "${project_dir}/.flake8" << 'EOF'
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = .venv,venv,__pycache__,.git
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
__pycache__/
*.pyc
*.pyo
*.pyd
.venv/
venv/
env/
*.egg-info/
dist/
build/
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/
EOF

    print_info "Installing Python dependencies..."
    (cd "${project_dir}" && python3 -m pip install -r requirements.txt -q) && print_success "pip install complete" || print_warning "pip install failed — run manually: cd ${project_dir} && pip install -r requirements.txt"

    print_success "Created Python project structure"
}

create_go_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/internal"

    # go.mod
    cat > "${project_dir}/go.mod" << EOF
module ${project_name}

go 1.23
EOF

    # main.go
    cat > "${project_dir}/main.go" << 'EOF'
package main

import "fmt"

func main() {
	fmt.Println(Greet("Ralph Loop"))
}

// Greet returns a greeting for the given name.
func Greet(name string) string {
	return fmt.Sprintf("Hello, %s!", name)
}
EOF

    # main_test.go
    cat > "${project_dir}/main_test.go" << 'EOF'
package main

import "testing"

func TestGreet(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"basic greeting", "World", "Hello, World!"},
		{"ralph loop greeting", "Ralph Loop", "Hello, Ralph Loop!"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := Greet(tt.input)
			if result != tt.expected {
				t.Errorf("Greet(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
# Compiled binaries
*.exe
*.out
/dist/
/build/

# Test cache
/tmp/
coverage.out
coverage.html
EOF

    print_info "Running go mod tidy..."
    (cd "${project_dir}" && go mod tidy) && print_success "go mod tidy complete" || print_warning "go mod tidy failed — run manually: cd ${project_dir} && go mod tidy"

    print_success "Created Go project structure"
}

create_rust_project() {
    local project_dir="$1"
    local project_name="$2"

    # Cargo.toml
    cat > "${project_dir}/Cargo.toml" << EOF
[package]
name = "${project_name}"
version = "1.0.0"
edition = "2021"

[dependencies]
EOF

    # Create src directory
    mkdir -p "${project_dir}/src"

    # src/main.rs — includes inline tests
    cat > "${project_dir}/src/main.rs" << 'EOF'
fn main() {
    println!("{}", greet("Ralph Loop"));
}

/// Returns a greeting for the given name.
pub fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greet_basic() {
        assert_eq!(greet("World"), "Hello, World!");
    }

    #[test]
    fn test_greet_ralph_loop() {
        assert_eq!(greet("Ralph Loop"), "Hello, Ralph Loop!");
    }
}
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
/target/
EOF

    print_info "Running cargo check..."
    (cd "${project_dir}" && cargo check --quiet) && print_success "cargo check complete" || print_warning "cargo check failed — run manually: cd ${project_dir} && cargo check"

    print_success "Created Rust project structure"
}

create_angular_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/src/app"
    mkdir -p "${project_dir}/src/assets"

    cat > "${project_dir}/package.json" << EOF
{
  "name": "${project_name}",
  "version": "1.0.0",
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build",
    "test": "ng test --watch=false --browsers=ChromeHeadless",
    "lint": "ng lint"
  },
  "dependencies": {
    "@angular/animations": "^18.2.0",
    "@angular/common": "^18.2.0",
    "@angular/compiler": "^18.2.0",
    "@angular/core": "^18.2.0",
    "@angular/forms": "^18.2.0",
    "@angular/platform-browser": "^18.2.0",
    "@angular/router": "^18.2.0",
    "rxjs": "^7.8.1",
    "tslib": "^2.7.0",
    "zone.js": "^0.14.10"
  },
  "devDependencies": {
    "@angular-devkit/build-angular": "^18.2.0",
    "@angular/cli": "^18.2.0",
    "@angular/compiler-cli": "^18.2.0",
    "@types/jasmine": "^5.1.4",
    "jasmine-core": "^5.3.0",
    "karma": "^6.4.4",
    "karma-chrome-launcher": "^3.2.0",
    "karma-coverage": "^2.2.1",
    "karma-jasmine": "^5.1.0",
    "karma-jasmine-html-reporter": "^2.1.0",
    "typescript": "~5.5.0"
  }
}
EOF

    cat > "${project_dir}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022", "dom"],
    "strict": true,
    "esModuleInterop": true,
    "moduleResolution": "bundler",
    "experimentalDecorators": true,
    "useDefineForClassFields": false,
    "forceConsistentCasingInFileNames": true
  },
  "angularCompilerOptions": {
    "enableI18nLegacyMessageIdFormat": false,
    "strictInjectionParameters": true,
    "strictInputAccessModifiers": true,
    "strictTemplates": true
  }
}
EOF

    # tsconfig.spec.json for tests
    cat > "${project_dir}/tsconfig.spec.json" << 'EOF'
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./out-tsc/spec",
    "types": ["jasmine"]
  },
  "include": ["src/**/*.spec.ts", "src/**/*.d.ts"]
}
EOF

    # angular.json — required for all ng commands
    cat > "${project_dir}/angular.json" << EOF
{
  "\$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "newProjectRoot": "projects",
  "projects": {
    "${project_name}": {
      "projectType": "application",
      "schematics": {
        "@schematics/angular:component": { "standalone": true },
        "@schematics/angular:directive": { "standalone": true },
        "@schematics/angular:pipe": { "standalone": true }
      },
      "root": "",
      "sourceRoot": "src",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular-devkit/build-angular:application",
          "options": {
            "outputPath": "dist/${project_name}",
            "index": "src/index.html",
            "browser": "src/main.ts",
            "polyfills": ["zone.js"],
            "tsConfig": "tsconfig.json",
            "assets": ["src/assets"],
            "styles": [],
            "scripts": []
          },
          "configurations": {
            "production": {
              "budgets": [
                { "type": "initial", "maximumWarning": "500kb", "maximumError": "1mb" },
                { "type": "anyComponentStyle", "maximumWarning": "2kb", "maximumError": "4kb" }
              ],
              "outputHashing": "all"
            },
            "development": {
              "optimization": false,
              "extractLicenses": false,
              "sourceMap": true
            }
          },
          "defaultConfiguration": "production"
        },
        "serve": {
          "builder": "@angular-devkit/build-angular:dev-server",
          "configurations": {
            "production": { "buildTarget": "${project_name}:build:production" },
            "development": { "buildTarget": "${project_name}:build:development" }
          },
          "defaultConfiguration": "development"
        },
        "test": {
          "builder": "@angular-devkit/build-angular:karma",
          "options": {
            "polyfills": ["zone.js", "zone.js/testing"],
            "tsConfig": "tsconfig.spec.json",
            "assets": ["src/assets"],
            "styles": [],
            "scripts": [],
            "codeCoverage": true
          }
        }
      }
    }
  }
}
EOF

    # karma.conf.js
    cat > "${project_dir}/karma.conf.js" << 'EOF'
module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage'),
      require('@angular-devkit/build-angular/plugins/karma'),
    ],
    client: { jasmine: {}, clearContext: false },
    coverageReporter: { dir: require('path').join(__dirname, './coverage/${project_name}'), subdir: '.', reporters: [{ type: 'html' }, { type: 'text-summary' }] },
    reporters: ['progress', 'kjhtml'],
    browsers: ['ChromeHeadless'],
    singleRun: true,
  });
};
EOF

    # src/index.html
    cat > "${project_dir}/src/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>${project_name^}</title>
  <base href="/" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body>
  <app-root></app-root>
</body>
</html>
EOF

    # src/app/app.component.ts
    cat > "${project_dir}/src/app/app.component.ts" << 'EOF'
import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  template: '<h1>Hello from Ralph Loop!</h1>',
  standalone: true,
})
export class AppComponent {
  title = 'app';

  greet(name: string): string {
    return `Hello, ${name}!`;
  }
}
EOF

    # src/app/app.component.spec.ts
    cat > "${project_dir}/src/app/app.component.spec.ts" << 'EOF'
import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';

describe('AppComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AppComponent],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should greet by name', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app.greet('World')).toBe('Hello, World!');
  });
});
EOF

    # src/main.ts
    cat > "${project_dir}/src/main.ts" << 'EOF'
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent).catch((err) => console.error(err));
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
node_modules/
dist/
out-tsc/
coverage/
.angular/
.env
.env.local
EOF

    print_info "Installing npm dependencies (Angular — this may take a minute)..."
    (cd "${project_dir}" && npm install --silent) && print_success "npm install complete" || print_warning "npm install failed — run manually: cd ${project_dir} && npm install"

    print_success "Created Angular project structure"
}

create_react_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/src"
    mkdir -p "${project_dir}/public"

    cat > "${project_dir}/package.json" << EOF
{
  "name": "${project_name}",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "lint": "eslint src --ext ts,tsx"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.6.3",
    "@testing-library/react": "^16.0.0",
    "@testing-library/user-event": "^14.5.2",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "@typescript-eslint/eslint-plugin": "^7.18.0",
    "@typescript-eslint/parser": "^7.18.0",
    "@vitejs/plugin-react": "^4.3.2",
    "@vitest/coverage-v8": "^2.1.8",
    "eslint": "^8.57.1",
    "eslint-plugin-react": "^7.37.2",
    "eslint-plugin-react-hooks": "^4.6.2",
    "jsdom": "^25.0.1",
    "typescript": "^5.6.3",
    "vite": "^5.4.10",
    "vitest": "^2.1.8"
  }
}
EOF

    cat > "${project_dir}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src"]
}
EOF

    # vite.config.ts — includes vitest config
    cat > "${project_dir}/vite.config.ts" << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/setupTests.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
    },
  },
});
EOF

    # .eslintrc.json
    cat > "${project_dir}/.eslintrc.json" << 'EOF'
{
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint", "react", "react-hooks"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended"
  ],
  "settings": { "react": { "version": "detect" } },
  "rules": { "react/react-in-jsx-scope": "off" }
}
EOF

    # src/setupTests.ts
    cat > "${project_dir}/src/setupTests.ts" << 'EOF'
import '@testing-library/jest-dom';
EOF

    # src/App.tsx
    cat > "${project_dir}/src/App.tsx" << 'EOF'
interface AppProps {
  name?: string;
}

function App({ name = 'Ralph Loop' }: AppProps) {
  return <h1>Hello from {name}!</h1>;
}

export default App;
EOF

    # src/App.test.tsx
    cat > "${project_dir}/src/App.test.tsx" << 'EOF'
import { render, screen } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('renders default greeting', () => {
    render(<App />);
    expect(screen.getByText('Hello from Ralph Loop!')).toBeInTheDocument();
  });

  it('renders custom name greeting', () => {
    render(<App name="World" />);
    expect(screen.getByText('Hello from World!')).toBeInTheDocument();
  });
});
EOF

    # src/main.tsx
    cat > "${project_dir}/src/main.tsx" << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

    # public/index.html
    cat > "${project_dir}/public/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8" /><title>Ralph Loop App</title></head>
<body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
node_modules/
dist/
coverage/
.nyc_output/
.env
.env.local
EOF

    print_info "Installing npm dependencies..."
    (cd "${project_dir}" && npm install --silent) && print_success "npm install complete" || print_warning "npm install failed — run manually: cd ${project_dir} && npm install"

    print_success "Created React project structure"
}

create_nextjs_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/src/app"
    mkdir -p "${project_dir}/src/app/api"
    mkdir -p "${project_dir}/src/__tests__"
    mkdir -p "${project_dir}/public"

    cat > "${project_dir}/package.json" << EOF
{
  "name": "${project_name}",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "jest",
    "test:coverage": "jest --coverage"
  },
  "dependencies": {
    "next": "^15.0.3",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.6.3",
    "@testing-library/react": "^16.0.0",
    "@testing-library/user-event": "^14.5.2",
    "@types/jest": "^29.5.14",
    "@types/node": "^22.0.0",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "jest": "^29.7.0",
    "jest-environment-jsdom": "^29.7.0",
    "ts-jest": "^29.2.5",
    "typescript": "^5.6.3"
  }
}
EOF

    # next.config.js
    cat > "${project_dir}/next.config.js" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {};
module.exports = nextConfig;
EOF

    # jest.config.ts — uses Next.js jest preset
    cat > "${project_dir}/jest.config.ts" << 'EOF'
import type { Config } from 'jest';
import nextJest from 'next/jest.js';

const createJestConfig = nextJest({ dir: './' });

const config: Config = {
  coverageProvider: 'v8',
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
};

export default createJestConfig(config);
EOF

    # jest.setup.ts
    cat > "${project_dir}/jest.setup.ts" << 'EOF'
import '@testing-library/jest-dom';
EOF

    # tsconfig.json
    cat > "${project_dir}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "jsx": "preserve",
    "module": "esnext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "incremental": true,
    "plugins": [{ "name": "next" }]
  },
  "include": ["src", "next.config.js", "jest.config.ts", "jest.setup.ts"],
  "exclude": ["node_modules"]
}
EOF

    # src/app/layout.tsx
    cat > "${project_dir}/src/app/layout.tsx" << 'EOF'
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
EOF

    # src/app/page.tsx
    cat > "${project_dir}/src/app/page.tsx" << 'EOF'
export default function Home() {
  return (
    <main>
      <h1>Hello from Ralph Loop!</h1>
    </main>
  );
}
EOF

    # src/__tests__/page.test.tsx
    cat > "${project_dir}/src/__tests__/page.test.tsx" << 'EOF'
import { render, screen } from '@testing-library/react';
import Home from '../app/page';

describe('Home page', () => {
  it('renders heading', () => {
    render(<Home />);
    expect(screen.getByRole('heading', { name: /Hello from Ralph Loop!/i })).toBeInTheDocument();
  });
});
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
node_modules/
.next/
out/
dist/
coverage/
.env
.env.local
.env.*.local
EOF

    print_info "Installing npm dependencies..."
    (cd "${project_dir}" && npm install --silent) && print_success "npm install complete" || print_warning "npm install failed — run manually: cd ${project_dir} && npm install"

    print_success "Created Next.js project structure"
}

create_express_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/src/routes"
    mkdir -p "${project_dir}/src/middleware"
    mkdir -p "${project_dir}/tests"

    cat > "${project_dir}/package.json" << EOF
{
  "name": "${project_name}",
  "version": "1.0.0",
  "scripts": {
    "dev": "nodemon src/index.ts",
    "start": "node dist/index.js",
    "build": "tsc",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src tests --ext .ts"
  },
  "dependencies": {
    "express": "^4.21.1"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/jest": "^29.5.14",
    "@types/node": "^22.0.0",
    "@types/supertest": "^6.0.2",
    "@typescript-eslint/eslint-plugin": "^7.18.0",
    "@typescript-eslint/parser": "^7.18.0",
    "eslint": "^8.57.1",
    "jest": "^29.7.0",
    "nodemon": "^3.1.7",
    "supertest": "^7.0.0",
    "ts-jest": "^29.2.5",
    "ts-node": "^10.9.2",
    "typescript": "^5.6.3"
  }
}
EOF

    # tsconfig.json
    cat > "${project_dir}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
EOF

    # jest.config.ts
    cat > "${project_dir}/jest.config.ts" << 'EOF'
import type { Config } from 'jest';

const config: Config = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.ts'],
  collectCoverageFrom: ['src/**/*.ts'],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', { tsconfig: { module: 'commonjs' } }],
  },
};

export default config;
EOF

    # .eslintrc.json
    cat > "${project_dir}/.eslintrc.json" << 'EOF'
{
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"],
  "env": { "node": true, "jest": true }
}
EOF

    # src/index.ts
    cat > "${project_dir}/src/index.ts" << 'EOF'
import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (_req, res) => {
  res.json({ message: 'Hello from Ralph Loop!' });
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

export default app;
EOF

    # src/routes/index.ts
    cat > "${project_dir}/src/routes/index.ts" << 'EOF'
import { Router } from 'express';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

export default router;
EOF

    # tests/index.test.ts
    cat > "${project_dir}/tests/index.test.ts" << 'EOF'
import request from 'supertest';
import app from '../src/index';

describe('GET /', () => {
  it('returns hello message', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.body.message).toBe('Hello from Ralph Loop!');
  });
});

describe('GET /health', () => {
  it('returns status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
node_modules/
dist/
coverage/
.env
.env.local
EOF

    print_info "Installing npm dependencies..."
    (cd "${project_dir}" && npm install --silent) && print_success "npm install complete" || print_warning "npm install failed — run manually: cd ${project_dir} && npm install"

    print_success "Created Express project structure"
}

create_flask_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/app"
    mkdir -p "${project_dir}/tests"

    cat > "${project_dir}/requirements.txt" << 'EOF'
flask>=3.1.0
pytest>=8.3.0
pytest-cov>=5.0.0
black>=24.10.0
flake8>=7.1.0
EOF

    cat > "${project_dir}/app/__init__.py" << 'EOF'
from flask import Flask

def create_app():
    app = Flask(__name__)

    from .routes import main
    app.register_blueprint(main)

    return app
EOF

    cat > "${project_dir}/app/routes.py" << 'EOF'
from flask import Blueprint, jsonify

main = Blueprint('main', __name__)

@main.route('/')
def index():
    return jsonify({"message": "Hello from Ralph Loop!"})

@main.route('/health')
def health():
    return jsonify({"status": "ok"})
EOF

    cat > "${project_dir}/run.py" << 'EOF'
from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True)
EOF

    cat > "${project_dir}/pytest.ini" << 'EOF'
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = --cov=app --cov-report=term-missing
EOF

    cat > "${project_dir}/.flake8" << 'EOF'
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = .venv,venv,__pycache__,.git
EOF

    cat > "${project_dir}/tests/__init__.py" << 'EOF'
EOF

    cat > "${project_dir}/tests/test_app.py" << 'EOF'
import pytest
from app import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_index_returns_200(client):
    response = client.get('/')
    assert response.status_code == 200


def test_index_returns_message(client):
    response = client.get('/')
    data = response.get_json()
    assert data['message'] == 'Hello from Ralph Loop!'


def test_health_returns_ok(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.get_json()['status'] == 'ok'
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
__pycache__/
*.pyc
*.pyo
.venv/
venv/
env/
*.egg-info/
dist/
build/
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/
instance/
EOF

    print_info "Installing Python dependencies..."
    (cd "${project_dir}" && python3 -m pip install -r requirements.txt -q) && print_success "pip install complete" || print_warning "pip install failed — run manually: cd ${project_dir} && pip install -r requirements.txt"

    print_success "Created Flask project structure"
}

create_ruby_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/lib"
    mkdir -p "${project_dir}/spec"

    cat > "${project_dir}/Gemfile" << EOF
source 'https://rubygems.org'

gem 'rspec', '~> 3.13'
gem 'rubocop', '~> 1.65', require: false
EOF

    cat > "${project_dir}/lib/${project_name}.rb" << EOF
# Ralph Loop Framework - Ruby Project
module ${project_name^}
  def self.hello
    "Hello from Ralph Loop!"
  end
end
EOF

    cat > "${project_dir}/run.rb" << EOF
require_relative 'lib/${project_name}'

puts ${project_name^}.hello
EOF

    cat > "${project_dir}/spec/spec_helper.rb" << 'EOF'
require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
EOF

    cat > "${project_dir}/spec/${project_name}_spec.rb" << EOF
require_relative '../lib/${project_name}'

RSpec.describe ${project_name^} do
  it 'returns a greeting' do
    expect(${project_name^}.hello).to eq('Hello from Ralph Loop!')
  end
end
EOF

    cat > "${project_dir}/.rubocop.yml" << 'EOF'
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3

Style/Documentation:
  Enabled: false
EOF

    # .rspec
    cat > "${project_dir}/.rspec" << 'EOF'
--require spec_helper
--format documentation
--color
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
.bundle/
vendor/bundle/
*.gem
.byebug_history
coverage/
.yardoc/
doc/
EOF

    print_info "Installing Ruby gems..."
    (cd "${project_dir}" && bundle install --quiet) && print_success "bundle install complete" || print_warning "bundle install failed — run manually: cd ${project_dir} && bundle install"

    print_success "Created Ruby project structure"
}

create_nx_project() {
    local parent_dir="$1"
    local project_name="$2"

    # Read config set by ask_project_questions
    local ws_type="${PROJECT_CONFIG[nx_workspace_type]:-integrated}"
    local pm="${PROJECT_CONFIG[package_manager]:-npm}"
    local frontends="${PROJECT_CONFIG[nx_frontends]:-none}"
    local backends="${PROJECT_CONFIG[nx_backends]:-none}"
    local e2e="${PROJECT_CONFIG[nx_e2e]:-playwright}"
    local unit_test="${PROJECT_CONFIG[nx_unit_test]:-jest}"
    local nx_cloud="${PROJECT_CONFIG[nx_cloud]:-no}"
    local community="${PROJECT_CONFIG[nx_community]:-none}"

    print_info "Creating NX workspace: ${project_name}"
    print_info "  Workspace type : ${ws_type}"
    print_info "  Package manager: ${pm}"
    print_info "  Frontends      : ${frontends}"
    print_info "  Backends       : ${backends}"
    print_info "  E2E framework  : ${e2e}"
    print_info "  Unit test      : ${unit_test}"
    print_info "  Nx Cloud       : ${nx_cloud}"
    print_info "  Community      : ${community}"
    echo

    # Determine preset — use 'apps' (empty integrated) or 'npm' (package-based)
    # then add plugins and generate each app manually for full control.
    local preset="apps"
    if [ "${ws_type}" = "package-based" ]; then
        preset="npm"
    fi

    # Run create-nx-workspace in the PARENT directory so it creates <project_name>/
    # We're already CD'd into project_dir (which is "."), so we need to go up.
    # Map yes/no cloud choice to the values create-nx-workspace expects
    if [ "${nx_cloud}" = "yes" ]; then
        cloud_flag="yes"
    else
        cloud_flag="skip"
    fi

    # create-nx-workspace must run from parent_dir to create the project subdir
    print_info "Running: npx create-nx-workspace@latest ..."
    (
        cd "${parent_dir}"
        npx create-nx-workspace@latest "${project_name}" \
            --preset="${preset}" \
            --workspaceType="${ws_type}" \
            --pm="${pm}" \
            --nxCloud="${cloud_flag}" \
            --skipGit=false \
            --interactive=false 2>&1 | grep -v "^$" || true
    )

    # cd into newly-created workspace for all subsequent nx commands
    cd "${parent_dir}/${project_name}"

    # After workspace creation, we're in the project dir — install plugins and generate apps
    print_info "Installing Nx plugins..."

    # Map of frontend framework -> @nx plugin
    local -A FRONTEND_PLUGINS=(
        ["react"]="@nx/react"
        ["angular"]="@nx/angular"
        ["nextjs"]="@nx/next"
        ["vue"]="@nx/vue"
    )

    # Map of backend framework -> @nx plugin
    local -A BACKEND_PLUGINS=(
        ["nest"]="@nx/nest"
        ["express"]="@nx/express"
        ["node"]="@nx/node"
    )

    # Install and generate frontend apps
    if [ "${frontends}" != "none" ]; then
        for fw in ${frontends}; do
            local plugin="${FRONTEND_PLUGINS[$fw]}"
            if [ -n "${plugin}" ]; then
                print_info "Adding plugin: ${plugin}"
                npx nx add "${plugin}" --no-interactive 2>&1 | tail -3 || true

                print_info "Generating ${fw} application..."
                case "${fw}" in
                    react)
                        npx nx generate "${plugin}:application" "${fw}-app" \
                            --bundler=vite \
                            --unitTestRunner="${unit_test}" \
                            --e2eTestRunner="${e2e}" \
                            --style=css \
                            --no-interactive 2>&1 | tail -5 || true
                        ;;
                    angular)
                        npx nx generate "${plugin}:application" "${fw}-app" \
                            --bundler=esbuild \
                            --unitTestRunner="${unit_test}" \
                            --e2eTestRunner="${e2e}" \
                            --style=css \
                            --standaloneApi=true \
                            --no-interactive 2>&1 | tail -5 || true
                        ;;
                    nextjs)
                        npx nx generate "${plugin}:application" "${fw}-app" \
                            --unitTestRunner="${unit_test}" \
                            --e2eTestRunner="${e2e}" \
                            --nextAppDir=true \
                            --no-interactive 2>&1 | tail -5 || true
                        ;;
                    vue)
                        npx nx generate "${plugin}:application" "${fw}-app" \
                            --unitTestRunner="${unit_test}" \
                            --e2eTestRunner="${e2e}" \
                            --no-interactive 2>&1 | tail -5 || true
                        ;;
                esac
                print_success "Generated ${fw}-app"
            else
                print_warning "Unknown frontend framework: ${fw}, skipping"
            fi
        done
    fi

    # Install and generate backend apps
    if [ "${backends}" != "none" ]; then
        for fw in ${backends}; do
            local plugin="${BACKEND_PLUGINS[$fw]}"
            if [ -n "${plugin}" ]; then
                print_info "Adding plugin: ${plugin}"
                npx nx add "${plugin}" --no-interactive 2>&1 | tail -3 || true

                print_info "Generating ${fw} application..."
                case "${fw}" in
                    nest)
                        npx nx generate "${plugin}:application" "${fw}-api" \
                            --unitTestRunner="${unit_test}" \
                            --no-interactive 2>&1 | tail -5 || true
                        ;;
                    express)
                        npx nx generate "${plugin}:application" "${fw}-api" \
                            --unitTestRunner="${unit_test}" \
                            --no-interactive 2>&1 | tail -5 || true
                        ;;
                    node)
                        npx nx generate "${plugin}:application" "${fw}-api" \
                            --framework=none \
                            --unitTestRunner="${unit_test}" \
                            --bundler=esbuild \
                            --no-interactive 2>&1 | tail -5 || true
                        ;;
                esac
                print_success "Generated ${fw}-api"
            else
                print_warning "Unknown backend framework: ${fw}, skipping"
            fi
        done
    fi

    # Community plugins
    if [ "${community}" != "none" ]; then
        for plugin in ${community}; do
            case "${plugin}" in
                python)
                    print_info "Adding community plugin: @nxlv/python"
                    npx nx add @nxlv/python --no-interactive 2>&1 | tail -3 || true
                    print_success "Added @nxlv/python (use: nx generate @nxlv/python:poetry-project <name>)"
                    ;;
                go)
                    print_info "Adding community plugin: @nx-go/nx-go"
                    npx nx add @nx-go/nx-go --no-interactive 2>&1 | tail -3 || true
                    print_success "Added @nx-go/nx-go (use: nx generate @nx-go/nx-go:app <name>)"
                    ;;
                *)
                    print_warning "Unknown community plugin: ${plugin}, skipping"
                    ;;
            esac
        done
    fi

    # Write Ralph workspace metadata so Ralph skills know this is an NX workspace
    mkdir -p "ralph/.ralph"
    cat > "ralph/.ralph/nx-workspace.json" << EOF
{
  "nx_workspace": true,
  "workspace_type": "${ws_type}",
  "package_manager": "${pm}",
  "unit_test": "${unit_test}",
  "e2e": "${e2e}",
  "frontends": "${frontends}",
  "backends": "${backends}",
  "community_plugins": "${community}"
}
EOF

    print_success "NX workspace created: ${project_name}"
    echo
    print_info "Installed apps (run with: nx run <app>:serve):"
    for fw in ${frontends}; do [ "${fw}" != "none" ] && echo "  - ${fw}-app"; done
    for fw in ${backends}; do [ "${fw}" != "none" ] && echo "  - ${fw}-api"; done
    echo
}

#==============================================================================
# Main Script
#==============================================================================

main() {
    local install_global=false
    local new_project=""
    local project_type="unknown"
    local parent_dir="."
    local init_existing=false
    local backup_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-global)
                install_global=true
                shift
                ;;
            --new-project)
                new_project="$2"
                shift 2
                ;;
            --type)
                project_type="$2"
                case "${project_type}" in
                    typescript|javascript|angular|react|nextjs|express|python|flask|go|rust|ruby|nx) ;;
                    *)
                        print_error "Unknown project type: '${project_type}'"
                        print_info "Valid types: typescript, javascript, angular, react, nextjs, express, python, flask, go, rust, ruby, nx"
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --parent-dir)
                parent_dir="$2"
                shift 2
                ;;
            --init)
                init_existing=true
                shift
                ;;
            --backup-dir)
                backup_dir="$2"
                shift 2
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    # Show header
    print_header

    # Install global skills/commands if requested (global only - never touches projects)
    if [ "${install_global}" = true ]; then
        install_global_skills
    fi

    # Helper: decide where to install skills for a project.
    # Rules (evaluated in order):
    #   1. --install-global was passed → globals already handled above, skip project-level
    #   2. Ralph skills are already installed globally → update globals instead of project-level
    #   3. No globals at all → install at project level
    install_skills_for_project() {
        local project_abs_dir="$1"
        if [ "${install_global}" = true ]; then
            print_info "Skipping project-level skills (already installed globally — no duplicates)"
        elif [ -d "${CLAUDE_GLOBAL_SKILLS}/ralph-loop" ] || [ -f "${CLAUDE_GLOBAL_COMMANDS}/ralph-archive.md" ]; then
            print_info "Global Ralph skills detected — updating globals rather than installing project-level"
            install_global_skills
        else
            install_project_skills "${project_abs_dir}"
        fi
    }

    # Create new project if requested
    if [ -n "${new_project}" ]; then
        # Create parent directory if it doesn't exist, then resolve to absolute path.
        # Resolving BEFORE create_new_project is critical: that function does an internal
        # `cd` into the new project, which would make relative paths like "./myapp" resolve
        # to "<project>/myapp" instead of the intended parent directory.
        if [ ! -d "${parent_dir}" ]; then
            mkdir -p "${parent_dir}"
            print_success "Created parent directory: ${parent_dir}"
        fi
        parent_dir="$(cd "${parent_dir}" && pwd)"

        create_new_project "${new_project}" "${project_type}" "${parent_dir}"
        install_skills_for_project "${parent_dir}/${new_project}"

        # Single git commit after everything is in place (structure + skills + commands).
        # cd into the project first so all git commands run in the correct context.
        local project_abs="${parent_dir}/${new_project}"
        cd "${project_abs}"
        if git rev-parse --git-dir >/dev/null 2>&1; then
            git add .
            if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                # Use "Add Ralph Loop Framework" if there's already a commit (e.g. NX workspace),
                # otherwise this is the very first commit.
                if git rev-parse HEAD >/dev/null 2>&1; then
                    git commit -m "Add Ralph Loop Framework to project"
                else
                    git commit -m "Initial commit: Ralph Loop Framework"
                fi
                print_success "Git commit created — all setup files included"
            fi
        fi
    fi

    # Initialize existing project if requested
    if [ "${init_existing}" = true ]; then
        if [ -n "${new_project}" ]; then
            print_error "Cannot use --new-project and --init together"
            exit 1
        fi
        local init_dir
        init_dir="$(pwd)"
        initialize_existing_project "${init_dir}"
        install_skills_for_project "${init_dir}"
    fi

    # If no action specified, show usage
    if [ "${install_global}" = false ] && [ -z "${new_project}" ] && [ "${init_existing}" = false ]; then
        print_error "No action specified"
        echo
        print_usage
        exit 1
    fi

    print_success "Installation complete!"
    echo
}

# Run main function
main "$@"
