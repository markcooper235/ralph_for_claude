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
    --type <language>           Project type (typescript, javascript, angular, react, nextjs, express, python, go, dotnet, rust, ruby, nx)
                                  Python sub-types:  python (prompts basic/flask/reflex/adk), or direct: flask, reflex, adk-python
                                  Go sub-types:      go (prompts basic/adk), or direct: adk-go
                                  TypeScript:        typescript (prompts basic/adk), or direct: adk-ts
                                  Ruby sub-types:    ruby (prompts basic/rails), or direct: rails
                                  Rust sub-types:    rust (prompts basic/actix/rocket), or direct: actix, rocket
                                  .NET sub-types:    dotnet (prompts webapi/mvc/blazorwasm/blazor)
                                  ADK agents:        adk-python (full LiteLLM bridge: gemini/anthropic/openai/other)
                                                     adk-go, adk-ts (Gemini-only; third-party adapters documented)
                                                     adk-java (gemini + anthropic native)
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
        if grep -q '"@google/adk"' "${project_dir}/package.json" 2>/dev/null; then
            echo "adk-ts"
        elif grep -q '"@angular/core"' "${project_dir}/package.json" 2>/dev/null; then
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

    # Python / Flask / ADK
    if [ -f "${project_dir}/setup.py" ] || [ -f "${project_dir}/pyproject.toml" ] || [ -f "${project_dir}/requirements.txt" ]; then
        if grep -qi "google-adk" "${project_dir}/requirements.txt" 2>/dev/null; then
            echo "adk-python"
        elif grep -qi "flask" "${project_dir}/requirements.txt" 2>/dev/null; then
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

    # Go (with optional ADK detection)
    if [ -f "${project_dir}/go.mod" ]; then
        if grep -q "google.golang.org/adk" "${project_dir}/go.mod" 2>/dev/null; then
            echo "adk-go"
        else
            echo "go"
        fi
        return
    fi

    # Rust
    if [ -f "${project_dir}/Cargo.toml" ]; then
        echo "rust"
        return
    fi

    # Java ADK (Maven pom.xml with google-adk dependency)
    if [ -f "${project_dir}/pom.xml" ]; then
        if grep -q "com.google.adk" "${project_dir}/pom.xml" 2>/dev/null; then
            echo "adk-java"
            return
        fi
    fi

    echo "unknown"
}

detect_tools() {
    local project_type="$1"
    local project_dir="$2"

    case "${project_type}" in
        typescript|javascript|angular|react|nextjs|express|adk-ts)
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

        python|flask|adk-python)
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

        go|adk-go)
            echo "test_framework=testing"
            echo "package_manager=go"
            ;;

        adk-java)
            echo "test_framework=junit5"
            echo "package_manager=maven"
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
            # For TypeScript only: offer the ADK sub-framework choice up front
            if [ "${project_type}" = "typescript" ]; then
                echo "TypeScript framework? (basic/adk) [basic]:"
                echo "  basic: standard TypeScript project (Jest/Vitest, ESLint)"
                echo "  adk:   Google Agent Development Kit agent (Gemini, requires Node 18+)"
                read -r ts_fw_choice || true
                PROJECT_CONFIG[ts_framework]="${ts_fw_choice:-basic}"
            else
                PROJECT_CONFIG[ts_framework]="basic"
            fi

            if [ "${PROJECT_CONFIG[ts_framework]}" = "adk" ]; then
                # adk-ts is Gemini-only — no provider menu, just model ID
                PROJECT_CONFIG[package_manager]="npm"
                PROJECT_CONFIG[test_framework]="vitest"
                echo "Gemini model ID? [gemini-flash-latest]:"
                read -r model_choice || true
                PROJECT_CONFIG[adk_provider]="gemini"
                PROJECT_CONFIG[adk_model]="${model_choice:-gemini-flash-latest}"
                PROJECT_CONFIG[adk_env_var]="GEMINI_API_KEY"
            else
                # Package manager
                local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
                if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                    default_pm="npm"
                fi

                echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
                read -r pm_choice || true
                PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

                # Test framework
                local default_test=$(echo "${detected_tools}" | grep "test_framework=" | cut -d= -f2)
                if [ -z "${default_test}" ] || [ "${default_test}" = "unknown" ]; then
                    default_test="jest"
                fi

                echo "Test framework? (jest/vitest/mocha) [${default_test}]:"
                read -r test_choice || true
                PROJECT_CONFIG[test_framework]="${test_choice:-$default_test}"

                # Build tool
                echo "Use build tool? (none/webpack/vite/esbuild) [vite]:"
                read -r build_choice || true
                PROJECT_CONFIG[build_tool]="${build_choice:-vite}"
            fi
            ;;

        adk-ts)
            # Direct shortcut — equivalent to --type typescript with framework=adk
            PROJECT_CONFIG[ts_framework]="adk"
            PROJECT_CONFIG[package_manager]="npm"
            PROJECT_CONFIG[test_framework]="vitest"
            PROJECT_CONFIG[adk_provider]="gemini"
            PROJECT_CONFIG[adk_model]="gemini-flash-latest"
            PROJECT_CONFIG[adk_env_var]="GEMINI_API_KEY"
            ;;

        adk-java)
            # adk-java natively supports Gemini + Anthropic Claude (no LiteLLM bridge)
            PROJECT_CONFIG[package_manager]="maven"
            PROJECT_CONFIG[test_framework]="junit5"
            echo "ADK model provider? (gemini/anthropic) [gemini]:"
            echo "  gemini:    Google Gemini (string model arg, GOOGLE_API_KEY)"
            echo "  anthropic: Claude via native com.google.adk.models.Claude (ANTHROPIC_API_KEY)"
            read -r prov_choice || true
            PROJECT_CONFIG[adk_provider]="${prov_choice:-gemini}"
            case "${PROJECT_CONFIG[adk_provider]}" in
                gemini)
                    echo "Gemini model ID? [gemini-flash-latest]:"
                    read -r model_choice || true
                    PROJECT_CONFIG[adk_model]="${model_choice:-gemini-flash-latest}"
                    PROJECT_CONFIG[adk_env_var]="GOOGLE_API_KEY"
                    ;;
                anthropic)
                    echo "Claude model ID? [claude-sonnet-4-5]:"
                    read -r model_choice || true
                    PROJECT_CONFIG[adk_model]="${model_choice:-claude-sonnet-4-5}"
                    PROJECT_CONFIG[adk_env_var]="ANTHROPIC_API_KEY"
                    ;;
                *)
                    print_warning "Unknown provider '${PROJECT_CONFIG[adk_provider]}' — defaulting to gemini"
                    PROJECT_CONFIG[adk_provider]="gemini"
                    PROJECT_CONFIG[adk_model]="gemini-flash-latest"
                    PROJECT_CONFIG[adk_env_var]="GOOGLE_API_KEY"
                    ;;
            esac
            ;;

        angular)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm) [${default_pm}]:"
            read -r pm_choice || true
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (karma/jest) [karma]:"
            read -r test_choice || true
            PROJECT_CONFIG[test_framework]="${test_choice:-karma}"
            ;;

        react)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice || true
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (jest/vitest) [vitest]:"
            read -r test_choice || true
            PROJECT_CONFIG[test_framework]="${test_choice:-vitest}"

            echo "Build tool? (vite/create-react-app) [vite]:"
            read -r build_choice || true
            PROJECT_CONFIG[build_tool]="${build_choice:-vite}"
            ;;

        nextjs)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice || true
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (jest/vitest) [jest]:"
            read -r test_choice || true
            PROJECT_CONFIG[test_framework]="${test_choice:-jest}"

            echo "Use App Router? (yes/no) [yes]:"
            read -r router_choice || true
            PROJECT_CONFIG[app_router]="${router_choice:-yes}"

            echo "Use React Compiler? (auto-memoization, stable since 2025) (yes/no) [no]:"
            read -r rc_choice || true
            PROJECT_CONFIG[react_compiler]="${rc_choice:-no}"
            ;;

        express)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi

            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice || true
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (jest/mocha/supertest) [jest]:"
            read -r test_choice || true
            PROJECT_CONFIG[test_framework]="${test_choice:-jest}"

            echo "Use TypeScript? (yes/no) [yes]:"
            read -r ts_choice || true
            PROJECT_CONFIG[typescript]="${ts_choice:-yes}"
            ;;

        python)
            # Sub-framework selection
            echo "Python framework? (basic/flask/reflex/adk) [basic]:"
            read -r py_fw_choice || true
            PROJECT_CONFIG[python_framework]="${py_fw_choice:-basic}"

            # Package manager
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="pip"
            fi

            echo "Package manager? (pip/poetry/uv) [${default_pm}]:"
            read -r pm_choice || true
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            case "${PROJECT_CONFIG[python_framework]}" in
                flask)
                    echo "Test framework? (pytest/unittest) [pytest]:"
                    read -r test_choice || true
                    PROJECT_CONFIG[test_framework]="${test_choice:-pytest}"

                    echo "Use SQLAlchemy? (yes/no) [no]:"
                    read -r db_choice || true
                    PROJECT_CONFIG[sqlalchemy]="${db_choice:-no}"
                    ;;
                reflex)
                    echo "Use type checking? (mypy/pyright/none) [none]:"
                    read -r type_choice || true
                    PROJECT_CONFIG[type_checker]="${type_choice:-none}"
                    ;;
                adk)
                    PROJECT_CONFIG[test_framework]="pytest"
                    echo "ADK model provider? (gemini/anthropic/openai/other) [gemini]:"
                    echo "  gemini:    Google Gemini (direct, no extra deps)"
                    echo "  anthropic: Claude via LiteLLM (adds google-adk[extensions])"
                    echo "  openai:    GPT via LiteLLM (adds google-adk[extensions])"
                    echo "  other:     any LiteLLM-supported model (you specify model + env var)"
                    read -r prov_choice || true
                    PROJECT_CONFIG[adk_provider]="${prov_choice:-gemini}"
                    case "${PROJECT_CONFIG[adk_provider]}" in
                        gemini)
                            echo "Model ID? [gemini-flash-latest]:"
                            read -r model_choice || true
                            PROJECT_CONFIG[adk_model]="${model_choice:-gemini-flash-latest}"
                            PROJECT_CONFIG[adk_env_var]="GOOGLE_API_KEY"
                            PROJECT_CONFIG[adk_uses_litellm]="false"
                            ;;
                        anthropic)
                            echo "Model ID? [anthropic/claude-3-5-sonnet-latest]:"
                            read -r model_choice || true
                            PROJECT_CONFIG[adk_model]="${model_choice:-anthropic/claude-3-5-sonnet-latest}"
                            PROJECT_CONFIG[adk_env_var]="ANTHROPIC_API_KEY"
                            PROJECT_CONFIG[adk_uses_litellm]="true"
                            ;;
                        openai)
                            echo "Model ID? [openai/gpt-4o]:"
                            read -r model_choice || true
                            PROJECT_CONFIG[adk_model]="${model_choice:-openai/gpt-4o}"
                            PROJECT_CONFIG[adk_env_var]="OPENAI_API_KEY"
                            PROJECT_CONFIG[adk_uses_litellm]="true"
                            ;;
                        other)
                            echo "LiteLLM model string? (e.g. groq/llama-3.1-70b-versatile):"
                            read -r model_choice || true
                            PROJECT_CONFIG[adk_model]="${model_choice:-groq/llama-3.1-70b-versatile}"
                            echo "API key env var name? (e.g. GROQ_API_KEY):"
                            read -r env_choice || true
                            PROJECT_CONFIG[adk_env_var]="${env_choice:-PROVIDER_API_KEY}"
                            PROJECT_CONFIG[adk_uses_litellm]="true"
                            ;;
                        *)
                            print_warning "Unknown provider '${PROJECT_CONFIG[adk_provider]}' — defaulting to gemini"
                            PROJECT_CONFIG[adk_provider]="gemini"
                            PROJECT_CONFIG[adk_model]="gemini-flash-latest"
                            PROJECT_CONFIG[adk_env_var]="GOOGLE_API_KEY"
                            PROJECT_CONFIG[adk_uses_litellm]="false"
                            ;;
                    esac
                    ;;
                *)  # basic
                    local default_test=$(echo "${detected_tools}" | grep "test_framework=" | cut -d= -f2)
                    if [ -z "${default_test}" ] || [ "${default_test}" = "unknown" ]; then
                        default_test="pytest"
                    fi
                    echo "Test framework? (pytest/unittest) [${default_test}]:"
                    read -r test_choice || true
                    PROJECT_CONFIG[test_framework]="${test_choice:-$default_test}"

                    echo "Use type checking? (mypy/pyright/none) [mypy]:"
                    read -r type_choice || true
                    PROJECT_CONFIG[type_checker]="${type_choice:-mypy}"
                    ;;
            esac
            ;;

        flask)
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="pip"
            fi

            echo "Package manager? (pip/poetry/pipenv) [${default_pm}]:"
            read -r pm_choice || true
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            echo "Test framework? (pytest/unittest) [pytest]:"
            read -r test_choice || true
            PROJECT_CONFIG[test_framework]="${test_choice:-pytest}"

            echo "Use SQLAlchemy? (yes/no) [no]:"
            read -r db_choice || true
            PROJECT_CONFIG[sqlalchemy]="${db_choice:-no}"
            ;;

        ruby)
            # Sub-framework selection
            echo "Ruby framework? (basic/rails) [basic]:"
            read -r rb_fw_choice || true
            PROJECT_CONFIG[ruby_framework]="${rb_fw_choice:-basic}"

            case "${PROJECT_CONFIG[ruby_framework]}" in
                rails)
                    echo "Test framework? (minitest/rspec) [minitest]:"
                    read -r test_choice || true
                    PROJECT_CONFIG[test_framework]="${test_choice:-minitest}"

                    echo "API only? (yes/no) [no]:"
                    read -r api_choice || true
                    PROJECT_CONFIG[rails_api]="${api_choice:-no}"
                    ;;
                *)  # basic
                    echo "Test framework? (rspec/minitest) [rspec]:"
                    read -r test_choice || true
                    PROJECT_CONFIG[test_framework]="${test_choice:-rspec}"

                    echo "Use Bundler? (yes/no) [yes]:"
                    read -r bundler_choice || true
                    PROJECT_CONFIG[package_manager]="bundler"
                    ;;
            esac
            ;;

        rails)
            # Direct shortcut — equivalent to --type ruby with framework=rails
            PROJECT_CONFIG[ruby_framework]="rails"
            echo "Test framework? (minitest/rspec) [minitest]:"
            read -r test_choice || true
            PROJECT_CONFIG[test_framework]="${test_choice:-minitest}"

            echo "API only? (yes/no) [no]:"
            read -r api_choice || true
            PROJECT_CONFIG[rails_api]="${api_choice:-no}"
            ;;

        go)
            PROJECT_CONFIG[package_manager]="go"
            PROJECT_CONFIG[test_framework]="testing"

            # Sub-framework selection (basic Go project vs. ADK agent)
            echo "Go framework? (basic/adk) [basic]:"
            echo "  basic: standard Go project (testing package)"
            echo "  adk:   Google Agent Development Kit agent (Gemini, requires go 1.24+)"
            read -r go_fw_choice || true
            PROJECT_CONFIG[go_framework]="${go_fw_choice:-basic}"

            case "${PROJECT_CONFIG[go_framework]}" in
                adk)
                    # adk-go is Gemini-only — no provider menu needed, just model ID
                    echo "Gemini model ID? [gemini-flash-latest]:"
                    read -r model_choice || true
                    PROJECT_CONFIG[adk_provider]="gemini"
                    PROJECT_CONFIG[adk_model]="${model_choice:-gemini-flash-latest}"
                    PROJECT_CONFIG[adk_env_var]="GOOGLE_API_KEY"
                    ;;
                *)  # basic
                    echo "Use additional test framework? (testify/ginkgo/none) [none]:"
                    read -r test_choice || true
                    PROJECT_CONFIG[additional_test]="${test_choice:-none}"
                    ;;
            esac
            ;;

        adk-go)
            # Direct shortcut — equivalent to --type go with framework=adk
            PROJECT_CONFIG[go_framework]="adk"
            PROJECT_CONFIG[package_manager]="go"
            PROJECT_CONFIG[test_framework]="testing"
            PROJECT_CONFIG[adk_provider]="gemini"
            PROJECT_CONFIG[adk_model]="gemini-flash-latest"
            PROJECT_CONFIG[adk_env_var]="GOOGLE_API_KEY"
            ;;

        rust)
            # Sub-framework selection
            echo "Rust framework? (basic/actix/rocket) [basic]:"
            read -r rs_fw_choice || true
            PROJECT_CONFIG[rust_framework]="${rs_fw_choice:-basic}"

            PROJECT_CONFIG[package_manager]="cargo"
            PROJECT_CONFIG[test_framework]="cargo-test"

            case "${PROJECT_CONFIG[rust_framework]}" in
                basic)
                    echo "Use workspace? (yes/no) [no]:"
                    read -r workspace_choice || true
                    PROJECT_CONFIG[workspace]="${workspace_choice:-no}"
                    ;;
                actix|rocket)
                    # Web frameworks — no extra questions needed
                    ;;
            esac
            ;;

        actix)
            # Direct shortcut — equivalent to --type rust with framework=actix
            PROJECT_CONFIG[rust_framework]="actix"
            PROJECT_CONFIG[package_manager]="cargo"
            PROJECT_CONFIG[test_framework]="cargo-test"
            ;;

        rocket)
            # Direct shortcut — equivalent to --type rust with framework=rocket
            PROJECT_CONFIG[rust_framework]="rocket"
            PROJECT_CONFIG[package_manager]="cargo"
            PROJECT_CONFIG[test_framework]="cargo-test"
            ;;

        nx)
            # Workspace type
            echo "Workspace type? (integrated/package-based) [integrated]:"
            read -r ws_type || true
            PROJECT_CONFIG[nx_workspace_type]="${ws_type:-integrated}"

            # Package manager
            local default_pm=$(echo "${detected_tools}" | grep "package_manager=" | cut -d= -f2)
            if [ -z "${default_pm}" ] || [ "${default_pm}" = "unknown" ]; then
                default_pm="npm"
            fi
            echo "Package manager? (npm/yarn/pnpm/bun) [${default_pm}]:"
            read -r pm_choice || true
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"

            # Frontend apps
            echo
            print_info "Frontend applications to scaffold (space-separated, or 'none'):"
            echo "  Options: react angular nextjs vue"
            echo "  Example: react nextjs"
            echo "  [none]:"
            read -r frontend_choice || true
            PROJECT_CONFIG[nx_frontends]="${frontend_choice:-none}"

            # Backend apps
            echo
            print_info "Backend applications to scaffold (space-separated, or 'none'):"
            echo "  Options: nest express node"
            echo "  Example: nest express"
            echo "  [none]:"
            read -r backend_choice || true
            PROJECT_CONFIG[nx_backends]="${backend_choice:-none}"

            # E2E framework
            echo
            echo "E2E test framework? (playwright/none) [playwright]:"
            read -r e2e_choice || true
            # Normalize: cypress → playwright (Cypress removed; Playwright covers all E2E needs)
            if [[ "${e2e_choice}" == "cypress" ]]; then
                print_warning "Cypress is not supported — using Playwright instead"
                e2e_choice="playwright"
            fi
            PROJECT_CONFIG[nx_e2e]="${e2e_choice:-playwright}"

            # Unit test runner (default; each app can override)
            echo "Default unit test runner? (jest/vitest) [jest]:"
            read -r unit_choice || true
            PROJECT_CONFIG[nx_unit_test]="${unit_choice:-jest}"

            # Nx Cloud
            echo "Connect to Nx Cloud for remote caching? (yes/no) [no]:"
            read -r cloud_choice || true
            PROJECT_CONFIG[nx_cloud]="${cloud_choice:-no}"

            # Community language plugins
            echo
            print_info "Community language plugins (space-separated, or 'none'):"
            echo "  Options: python go terraform"
            echo "  [none]:"
            read -r community_choice || true
            PROJECT_CONFIG[nx_community]="${community_choice:-none}"
            ;;

        dotnet)
            echo "Template? (webapi/mvc/blazorwasm/blazor) [webapi]:"
            echo "  webapi     — ASP.NET Core REST API"
            echo "  mvc        — ASP.NET MVC with Razor views"
            echo "  blazorwasm — Blazor WebAssembly (SPA in C#)"
            echo "  blazor     — Blazor (server-side / SSR, .NET 8+)"
            read -r template_choice || true
            PROJECT_CONFIG[dotnet_template]="${template_choice:-webapi}"
            ;;

        reflex)
            # Direct shortcut — equivalent to --type python with framework=reflex
            PROJECT_CONFIG[python_framework]="reflex"
            local default_pm="pip"
            echo "Package manager? (pip/uv) [${default_pm}]:"
            read -r pm_choice || true
            PROJECT_CONFIG[package_manager]="${pm_choice:-$default_pm}"
            echo "Use type checking? (mypy/pyright/none) [none]:"
            read -r type_choice || true
            PROJECT_CONFIG[type_checker]="${type_choice:-none}"
            ;;

        adk-python)
            # Direct shortcut — equivalent to --type python with framework=adk
            # Defaults to Gemini; use `--type python` then `adk` for the interactive
            # provider menu (anthropic / openai / other).
            PROJECT_CONFIG[python_framework]="adk"
            PROJECT_CONFIG[package_manager]="pip"
            PROJECT_CONFIG[test_framework]="pytest"
            PROJECT_CONFIG[adk_provider]="gemini"
            PROJECT_CONFIG[adk_model]="gemini-flash-latest"
            PROJECT_CONFIG[adk_env_var]="GOOGLE_API_KEY"
            PROJECT_CONFIG[adk_uses_litellm]="false"
            ;;

        *)
            print_warning "Unknown project type '${project_type}' — skipping type-specific configuration"
            print_info "You can manually configure build tools and test frameworks after project creation"
            ;;
    esac

    # Determine browser testing default (UI frameworks: yes; API/CLI: no)
    local browser_default="no"
    case "${project_type}" in
        angular|react|nextjs) browser_default="yes" ;;
        reflex) browser_default="yes" ;;
        rails) browser_default="yes" ;;
        dotnet)
            case "${PROJECT_CONFIG[dotnet_template]:-webapi}" in
                mvc|blazorwasm|blazor) browser_default="yes" ;;
            esac
            ;;
        ruby)
            [ "${PROJECT_CONFIG[ruby_framework]:-basic}" = "rails" ] && browser_default="yes"
            ;;
        python)
            [ "${PROJECT_CONFIG[python_framework]:-basic}" = "reflex" ] && browser_default="yes"
            ;;
    esac

    # Common questions for all types (skip for nx — it manages its own browser testing)
    if [ "${project_type}" != "nx" ]; then
        echo
        echo "Include browser testing setup? (yes/no) [${browser_default}]:"
        read -r browser_choice || true
        PROJECT_CONFIG[browser_testing]="${browser_choice:-${browser_default}}"
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

## Ralph Loop

This project uses the Ralph Loop Framework for specification-driven development.

```bash
/ralph-create-prd          # Create a new PRD specification (start here)
/ralph-loop <spec-file>    # Run the development loop
/ralph-status              # Check current progress
/ralph-resume              # Resume a paused run
/ralph-archive             # Archive and merge completed run
/ralph-modify-spec         # Modify spec during a run
/ralph-add-requirement     # Quick add single requirement
```

Full documentation: `ralph/docs/QUICKSTART.md`

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

        javascript)
            cat >> "${claude_md}" << 'EOF'

## JavaScript Specific

### Dev Commands
```bash
npm run dev           # Run with node
npm test              # Run all tests (jest)
npm run test:coverage # Coverage report
```

### Lint Commands
```bash
npm run lint          # ESLint check
```

EOF
            ;;

        python)
            cat >> "${claude_md}" << 'EOF'

## Python Specific

### Setup (First Time)
```bash
# venv is created automatically by the install script
source venv/bin/activate      # Activate (Linux/Mac)
# venv/Scripts/activate       # Activate (Windows)
```

### Test Commands
```bash
venv/bin/pytest tests/        # Run tests (no activation needed)
venv/bin/pytest -v tests/     # Verbose output
venv/bin/pytest --cov tests/  # Coverage report
```

### Dev Commands
```bash
venv/bin/python src/main.py   # Run script
```

### Lint Commands
```bash
venv/bin/flake8 .             # Style checking
venv/bin/mypy .               # Type checking
venv/bin/black .              # Code formatting
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

### Coverage Commands
```bash
cargo tarpaulin                   # Coverage report (install: cargo install cargo-tarpaulin)
cargo tarpaulin --out Html        # HTML report → tarpaulin-report.html
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

### Setup (First Time)
```bash
# venv is created automatically by the install script
source venv/bin/activate      # Activate (Linux/Mac)
# venv/Scripts/activate       # Activate (Windows)
```

### Development Commands
```bash
venv/bin/flask run            # Dev server (localhost:5000)
venv/bin/flask run --debug    # Debug mode with reload
venv/bin/python run.py        # Alternative: run via run.py
```

### Test Commands
```bash
venv/bin/pytest tests/        # Run tests (no activation needed)
venv/bin/pytest -v tests/     # Verbose output
venv/bin/pytest --cov tests/  # Coverage report
```

### Lint Commands
```bash
venv/bin/flake8 .             # Style checking
venv/bin/black .              # Code formatting
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

        rocket)
            cat >> "${claude_md}" << 'EOF'

## Rocket Specific

### Build Commands
```bash
cargo build           # Debug build
cargo build --release # Release build
cargo run             # Build and run (localhost:8000)
```

### Test Commands
```bash
cargo test            # Run all tests (uses Rocket's blocking test client)
cargo test -- --nocapture  # Show println output
cargo test <name>     # Run specific test
```

### Lint Commands
```bash
cargo fmt             # Format code
cargo clippy          # Lint
cargo check           # Fast type/borrow check
```

### Key Notes
- Server runs on `http://localhost:8000` by default (Rocket default port)
- Rocket 0.5 is stable — no nightly toolchain required
- Tests use `rocket::local::blocking::Client` — no running server needed
- Add `rocket_db_pools` for database connection pooling

EOF
            ;;

        actix)
            cat >> "${claude_md}" << 'EOF'

## Actix Web Specific

### Build Commands
```bash
cargo build           # Debug build
cargo build --release # Release build
cargo run             # Build and run (localhost:8080)
```

### Test Commands
```bash
cargo test            # Run all tests (includes integration tests)
cargo test -- --nocapture  # Show println output
cargo test <name>     # Run specific test
```

### Lint Commands
```bash
cargo fmt             # Format code
cargo clippy          # Lint (treat warnings as errors in CI)
cargo check           # Fast type/borrow check without linking
```

### Key Notes
- Server runs on `http://localhost:8080` by default
- Tests use `actix_web::test` helpers — no running server needed
- Add `tracing` + `tracing-actix-web` crates for structured logging

EOF
            ;;

        dotnet)
            cat >> "${claude_md}" << 'EOF'

## .NET Specific

### Build Commands
```bash
dotnet build              # Build the project
dotnet build -c Release   # Release build
dotnet publish -c Release # Publish for deployment
```

### Development Commands
```bash
dotnet run                # Build and run
dotnet watch run          # Hot-reload dev server
dotnet run --project <name>.csproj  # Explicit project
```

### Test Commands
```bash
dotnet test               # Run all tests (from solution or test project)
dotnet test --logger "console;verbosity=detailed"
dotnet test --collect:"XPlat Code Coverage"  # Run with coverage (Cobertura XML → TestResults/)
```

### Coverage Commands
```bash
# Step 1 — run tests and collect coverage data
dotnet test --collect:"XPlat Code Coverage"

# Step 2 — generate HTML report from the Cobertura XML
dotnet tool run reportgenerator -- \
  -reports:"**/TestResults/**/coverage.cobertura.xml" \
  -targetdir:"coverage-report" \
  -reporttypes:Html

# Open report: coverage-report/index.html
# Note: coverlet.collector is pre-installed in the xUnit test project template
```

### Package Management
```bash
dotnet add package <name>         # Add NuGet package
dotnet remove package <name>      # Remove package
dotnet restore                    # Restore all packages
dotnet list package               # List installed packages
```

### Lint / Format Commands
```bash
dotnet format             # Format code (editorconfig rules)
dotnet format --verify-no-changes  # Check formatting only
```

### Key Notes
- Test project lives in `../<ProjectName>.Tests/` (sibling directory)
- Run `dotnet new sln` + `dotnet sln add` to manage multi-project solutions

EOF
            ;;

        rails)
            cat >> "${claude_md}" << 'EOF'

## Rails Specific

### Setup
```bash
bundle install            # Install gems
bundle exec rails db:create db:migrate  # Create and migrate database
```

### Development Commands
```bash
bundle exec rails server  # Dev server (localhost:3000)
bundle exec rails console # Rails REPL
bundle exec rails routes  # Show all routes
```

### Test Commands
```bash
bundle exec rails test    # Run all tests (Minitest)
bundle exec rspec         # Run all tests (RSpec, if configured)
bundle exec rails test test/models/     # Test specific directory
```

### Generate Commands
```bash
bundle exec rails generate model User name:string email:string
bundle exec rails generate controller Pages index
bundle exec rails generate scaffold Post title:string body:text
bundle exec rails db:migrate
```

### Lint Commands
```bash
bundle exec rubocop       # Style and lint check
bundle exec rubocop -a    # Auto-fix safe offenses
```

EOF
            ;;

        reflex)
            cat >> "${claude_md}" << 'EOF'

## Reflex Specific

### Setup (First Time)
```bash
# venv is created automatically by the install script
source venv/bin/activate      # Activate (Linux/Mac)
# venv/Scripts/activate       # Activate (Windows)
```

### Development Commands
```bash
venv/bin/reflex run           # Dev server (localhost:3000)
venv/bin/reflex run --env prod # Production mode
```

### Build Commands
```bash
venv/bin/reflex export        # Export static site
venv/bin/reflex build         # Build for deployment
```

### Test Commands
```bash
venv/bin/pytest tests/        # Unit tests for state logic (no activation needed)
venv/bin/pytest -v tests/
venv/bin/pytest --cov tests/
```

### Lint Commands
```bash
venv/bin/ruff check .         # Fast linting (pip install ruff)
venv/bin/black .              # Code formatting
venv/bin/mypy .               # Type checking (if configured)
```

EOF
            ;;

        adk-python)
            cat >> "${claude_md}" << 'EOF'

## ADK Python Agent Specific

This project is a Google Agent Development Kit (ADK) agent. Layout:

```
project-root/
├── agents/                        ← the agent Python package
│   ├── __init__.py                # `from . import agent` (required for discovery)
│   ├── agent.py                   # defines `root_agent`
│   └── .env                       # API key (loaded by ADK at runtime)
├── tests/                         # pytest — outside agents/
├── requirements.txt
├── pytest.ini
└── venv/
```

The `agents/` directory IS the agent Python package. `root_agent` is
defined in `agents/agent.py` and re-exported via `agents/__init__.py`.

### Setup (First Time)
```bash
# venv is created automatically by the install script and google-adk is installed
source venv/bin/activate           # Activate (Linux/Mac)
# venv/Scripts/activate            # Activate (Windows)

# REQUIRED before running the agent:
#   Edit agents/.env and replace REPLACE_WITH_YOUR_<PROVIDER>_API_KEY
#   Get a Gemini key from https://aistudio.google.com/app/apikey
```

### Run the Agent
```bash
# CLI mode — interactive conversation in the terminal:
venv/bin/adk run agents/

# Web UI:
venv/bin/adk web . --port 8000             # http://localhost:8000
```

### Test Commands
```bash
venv/bin/pytest tests/             # Unit tests for tool functions + agent config
venv/bin/pytest -v tests/
venv/bin/pytest --cov tests/
```

Tests are hermetic: they exercise the tool functions and verify agent
configuration without calling Gemini, so they run without an API key.

### Lint Commands
```bash
venv/bin/black .                   # Code formatting
venv/bin/flake8 .                  # Linting
```

### Editing the Agent
- Tools: add functions in `agents/agent.py` and list them in `tools=[...]`.
  Each tool function needs type hints on parameters and a docstring (becomes
  the LLM schema). Return a dict with a `status` key.
- Instructions: edit the `instruction=` parameter on `root_agent`.
- Sub-agents: pass `sub_agents=[child_agent]` on the parent `Agent` — compose
  in Python.
- Workflow agents: `SequentialAgent`, `ParallelAgent`, `LoopAgent` (deterministic
  pipelines) — see https://adk.dev/agents/workflow-agents/.
- Callbacks: `before_model_callback`, `after_model_callback`, `before_tool_callback`,
  etc. — all optional kwargs on `Agent`. See https://adk.dev/callbacks/.
- Model: see "Switching Models" below.
- Adding more agents: convert this single-agent layout into a multi-agent one
  by moving `agents/agent.py` + `agents/__init__.py` into `agents/<name>/` and
  adding more `agents/<other>/` sibling dirs. Then `adk web agents/` shows all
  of them in the picker.

### Switching Models

ADK speaks Gemini natively and routes other providers through LiteLLM.
Four things change together when you swap models:

1. `agents/agent.py` — the `model=` argument on `root_agent`
2. `agents/.env` — the API key env var name
3. `requirements.txt` — `google-adk[extensions]` is needed for LiteLLM-routed models
4. `tests/test_agent.py` — the assertion `_model_id(agent.root_agent) == "..."`

**Gemini** (current default — no LiteLLM needed):
```python
# agent.py
root_agent = Agent(model="gemini-flash-latest", ...)
# .env: GOOGLE_API_KEY="..."
```

**Anthropic Claude** (via LiteLLM):
```python
# agent.py
from google.adk.models.lite_llm import LiteLlm
root_agent = Agent(model=LiteLlm("anthropic/claude-3-5-sonnet-latest"), ...)
# .env: ANTHROPIC_API_KEY="..."
# requirements.txt: replace `google-adk` with `google-adk[extensions]`
```

**OpenAI GPT** (via LiteLLM):
```python
# agent.py
from google.adk.models.lite_llm import LiteLlm
root_agent = Agent(model=LiteLlm("openai/gpt-4o"), ...)
# .env: OPENAI_API_KEY="..."
# requirements.txt: replace `google-adk` with `google-adk[extensions]`
```

**Any LiteLLM-supported provider** (Groq, Together, Cohere, Bedrock, Ollama, etc.):
Use the `provider/model-name` string format. See
https://docs.litellm.ai/docs/providers for the full list and required env vars.

EOF
            ;;

        adk-go)
            cat >> "${claude_md}" << 'EOF'

## ADK Go Agent Specific

This project is a Google Agent Development Kit (ADK) agent written in Go.
The agent factory lives in `agent.go` (`NewAgent`). The launcher (`adk run`
CLI / `adk web` UI) is invoked from `main()`.

### Setup (First Time)
```bash
# go.mod + go.sum were created and `go mod tidy` was run during install.
# REQUIRED before running the agent:
#   Edit .env and replace REPLACE_WITH_YOUR_GEMINI_API_KEY with a real key.
#   Get one from https://aistudio.google.com/app/apikey
source .env                     # exports GOOGLE_API_KEY into the shell
```

### Run the Agent
```bash
# CLI mode — interactive conversation in the terminal:
go run .

# Web UI — same binary, different subcommand:
go run . web api webui          # http://localhost:8080
```

### Test Commands
```bash
go test ./...                   # Hermetic unit tests (do NOT call Gemini)
go test -v ./...                # Verbose
go test -cover ./...            # With coverage
```

Tests are hermetic: they construct the agent with a fake API key and
inspect its configuration without making any network calls. They pass
without a real `GOOGLE_API_KEY`.

### Lint Commands
```bash
go vet ./...                    # Standard Go vet
go fmt ./...                    # Format code (gofmt)
```

### Editing the Agent
- Tools: add to the `Tools:` slice in `agent.go`. Built-in `geminitool.*`
  helpers ship with the SDK; for custom function tools see the ADK docs.
- Instructions: edit the `Instruction:` field in `NewAgent`.
- Model: edit the literal passed to `NewAgent(...)` in `main()`, or change
  the constant in `agent_test.go` if you also want the test assertion to
  follow.

### Other Model Providers (third-party)

**adk-go ships Gemini-only first-party.** The `google.golang.org/adk`
module includes `model/gemini` and `model/apigee` but no Anthropic / OpenAI
adapters. Two community options exist:

- **Anthropic Claude:** `github.com/Alcova-AI/adk-anthropic-go` implements
  the `model.LLM` interface for Claude. Add it to `go.mod`, replace the
  `gemini.NewModel(...)` call in `NewAgent` with `adkanthropic.NewModel(...)`,
  and switch the env var to `ANTHROPIC_API_KEY`.
- **Other providers:** implement the `model.LLM` interface yourself, or
  watch the ADK Go releases for first-party additions.

If you need broad multi-provider support today, the Python ADK
(`--type adk-python`) has a first-party LiteLLM bridge that covers
Anthropic, OpenAI, Groq, Together, Cohere, Bedrock, Ollama, and more.

EOF
            ;;

        adk-ts)
            cat >> "${claude_md}" << 'EOF'

## ADK TypeScript Agent Specific

This project is a Google Agent Development Kit (ADK) agent written in
TypeScript. Layout:

```
project-root/
├── agents/                              ← what `adk web agents/` scans
│   └── <agent_file>.ts                  # exports `rootAgent`; filename = app name
├── tests/
│   └── agent.test.ts                    # vitest — OUTSIDE agents/ so adk web ignores
├── package.json
├── tsconfig.json
├── .env                                 # GEMINI_API_KEY at project root
└── node_modules/                        # OUTSIDE agents/ so adk web ignores
```

**Important:** anything that isn't an agent file must live OUTSIDE
`agents/`. `adk web agents/` lists every `.ts` file there as an agent
(filename becomes the app name). Test files in `agents/` crash the
picker (vitest internal-state errors). Keep `agents/` clean.

### Setup (First Time)
```bash
# node_modules/ was populated and `npm install` was run during install.
# REQUIRED before running the agent:
#   Edit .env at project root and replace REPLACE_WITH_YOUR_GEMINI_API_KEY.
#   Get a key from https://aistudio.google.com/app/apikey
```

### Run the Agent
```bash
npm start                       # CLI mode — interactive conversation
npm run web                     # Web UI on http://localhost:8000
# Or directly:
npx adk run agents/<agent_file>.ts
npx adk web agents/
```

### Test Commands
```bash
npm test                        # Run all tests (vitest)
npm run test:watch              # Watch mode
```

Tests are hermetic: the `LlmAgent` constructor does not call the model
at construction time, so `rootAgent` can be imported and inspected
without a `GEMINI_API_KEY`.

### Lint / Format / Typecheck
```bash
npm run typecheck               # tsc --noEmit
npm run format                  # prettier --write .
npm run format:check            # prettier --check .
```

### Editing the Agent
- Tools: define new `FunctionTool({...})` instances and add them to the
  `tools:` array on `rootAgent`.
- Instructions: edit the `instruction:` field on `rootAgent`.
- Model: change the `model:` string in `agent.ts` (e.g.
  `gemini-flash-latest`, `gemini-2.5-pro`).

### Other Model Providers (third-party)

**adk-ts ships Gemini-only first-party.** The `@google/adk` package
exports `Gemini`, `ApigeeLlm`, and `BaseLlm` — no `LiteLlm`, no
`AnthropicLlm`, no `OpenAiLlm`. The official Anthropic example page on
adk.dev shows Python and Java only.

Two options if you need non-Gemini in TypeScript:

1. **Third-party bridge:** `adk-llm-bridge`
   (https://github.com/pailat/adk-llm-bridge) routes through Vercel AI
   Gateway / OpenRouter. Add to `package.json`, replace the `model:`
   string in `agent.ts` with `Anthropic("claude-sonnet-4-5")` (or
   equivalent), switch the env var.
2. **Custom BaseLlm subclass:** extend `BaseLlm` from `@google/adk` and
   implement the abstract methods against the SDK of your chosen
   provider.

For broad multi-provider support today, the Python ADK
(`--type adk-python`) has a first-party LiteLLM bridge that covers
Anthropic, OpenAI, Groq, Together, Cohere, Bedrock, Ollama, and more.

EOF
            ;;

        adk-java)
            cat >> "${claude_md}" << 'EOF'

## ADK Java Agent Specific

This project is a Google Agent Development Kit (ADK) agent written in
Java (Maven, JUnit 5). The agent factory lives in
`src/main/java/com/example/agent/HelloTimeAgent.java` (`buildAgent()`).
`AgentCliRunner` wires the agent into an `InMemoryRunner` with a
Scanner loop for CLI mode.

### Setup (First Time)
```bash
# Maven dependencies were resolved during install (mvn compile).
# REQUIRED before running the agent: edit .env and replace the
# placeholder API key. The exact env var depends on the model provider:
#   - Gemini:    GOOGLE_API_KEY    → https://aistudio.google.com/app/apikey
#   - Anthropic: ANTHROPIC_API_KEY → https://console.anthropic.com/settings/keys
source .env                     # exports the API key into the shell
```

### Run the Agent
```bash
# CLI mode — interactive conversation in the terminal:
mvn compile exec:java -Dexec.mainClass=com.example.agent.AgentCliRunner

# Web UI (ADK ships its own server):
mvn compile exec:java \
  -Dexec.mainClass=com.google.adk.web.AdkWebServer \
  -Dexec.args="--adk.agents.source-dir=target --server.port=8000"
```

### Test Commands
```bash
mvn test                        # JUnit 5 tests (hermetic — no API call)
mvn -Dtest=HelloTimeAgentTest test   # Single test class
mvn surefire-report:report      # HTML report at target/site/surefire-report.html
```

Tests are hermetic: `buildAgent()` is called with a fake API key (for
Anthropic) or just uses a model-name string (for Gemini); neither path
contacts the model provider, so tests run without `GOOGLE_API_KEY` or
`ANTHROPIC_API_KEY` set.

### Editing the Agent
- Tools: add `@Schema`-annotated static methods to `HelloTimeAgent` and
  register them with `FunctionTool.create(HelloTimeAgent.class, "methodName")`
  in `buildAgent()`.
- Instructions: edit the `.instruction(...)` argument in `buildAgent()`.
- Model: change `MODEL_ID`, then update the test assertion if needed.

### Switching Model Providers

ADK Java natively supports two providers (no LiteLLM bridge in Java):

**Gemini** (default — string model arg):
```java
return LlmAgent.builder()
    .model("gemini-flash-latest")    // or "gemini-2.5-pro" etc.
    ...
```
- `.env`: `GOOGLE_API_KEY="..."`
- pom.xml: no changes (Gemini support ships in `google-adk`)

**Anthropic Claude** (native `com.google.adk.models.Claude`):
```java
AnthropicClient client = AnthropicOkHttpClient.builder()
    .apiKey(System.getenv("ANTHROPIC_API_KEY"))
    .build();
return LlmAgent.builder()
    .model(new Claude("claude-sonnet-4-5", client))
    ...
```
- `.env`: `ANTHROPIC_API_KEY="..."`
- pom.xml: no extra dep needed (anthropic-java comes transitively with
  `google-adk` 1.2.0)

**Other providers (OpenAI, Groq, etc.):** no first-party Java support.
You would need to implement a `BaseLlm` subclass against the SDK of your
chosen provider. There is no LiteLLM bridge in Java.

For the broadest multi-provider support, use Python ADK
(`--type adk-python`) — it has a first-party LiteLLM bridge.

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
- Check `ralph/nx-workspace.json` for workspace metadata used by Ralph

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

# Ralph templates are tracked (checked-in defaults)
!ralph/.ralph-state-template.json
!ralph/.ralph-story-template.json

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
- \`/ralph-status\` - Check progress
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
            echo "Project type? (typescript/javascript/angular/react/nextjs/express/python/flask/reflex/adk-python/go/dotnet/rust/ruby/rails/actix/rocket/nx) [typescript]:"
            read -r type_choice
            project_type="${type_choice:-typescript}"
            case "${project_type}" in
                typescript|javascript|angular|react|nextjs|express|python|flask|reflex|adk-python|go|adk-go|adk-ts|adk-java|dotnet|rust|ruby|rails|actix|rocket|nx) break ;;
                *)
                    print_error "Unknown project type: '${project_type}'"
                    print_info "Valid types: typescript, javascript, angular, react, nextjs, express, python, flask, reflex, adk-python, go, adk-go, adk-ts, adk-java, dotnet, rust, ruby, rails, actix, rocket, nx"
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
            echo "Project type? (typescript/javascript/angular/react/nextjs/express/python/go/dotnet/rust/ruby/nx) [typescript]:"
            echo "  Python sub-types: python (asks basic/flask/reflex/adk), or direct: flask, reflex, adk-python"
            echo "  Ruby sub-types:   ruby (asks basic/rails), or direct: rails"
            echo "  Rust sub-types:   rust (asks basic/actix/rocket), or direct: actix, rocket"
            read -r type_choice
            project_type="${type_choice:-typescript}"
            case "${project_type}" in
                typescript|javascript|angular|react|nextjs|express|python|flask|reflex|adk-python|go|adk-go|adk-ts|adk-java|dotnet|rust|ruby|rails|actix|rocket|nx) break ;;
                *)
                    print_error "Unknown project type: '${project_type}'"
                    print_info "Valid types: typescript, javascript, angular, react, nextjs, express, python, flask, reflex, adk-python, go, adk-go, adk-ts, adk-java, dotnet, rust, ruby, rails, actix, rocket, nx"
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
        typescript)
            case "${PROJECT_CONFIG[ts_framework]:-basic}" in
                adk) create_typescript_adk_project "." "${project_name}"; project_type="adk-ts" ;;
                *)   create_typescript_project "." ;;
            esac
            ;;
        adk-ts)
            create_typescript_adk_project "." "${project_name}"
            ;;
        adk-java)
            create_java_adk_project "." "${project_name}"
            ;;
        javascript)
            create_javascript_project "."
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
            case "${PROJECT_CONFIG[python_framework]:-basic}" in
                flask)  create_flask_project "." "${project_name}"; project_type="flask" ;;
                reflex) create_reflex_project ".";                  project_type="reflex" ;;
                adk)    create_python_adk_project "." "${project_name}"; project_type="adk-python" ;;
                *)      create_python_project "." ;;
            esac
            ;;
        flask)
            create_flask_project "." "${project_name}"
            ;;
        reflex)
            create_reflex_project "."
            ;;
        adk-python)
            create_python_adk_project "." "${project_name}"
            ;;
        ruby)
            case "${PROJECT_CONFIG[ruby_framework]:-basic}" in
                rails) create_rails_project "." "${project_name}"; project_type="rails" ;;
                *)     create_ruby_project "." "${project_name}" ;;
            esac
            ;;
        rails)
            create_rails_project "." "${project_name}"
            ;;
        go)
            case "${PROJECT_CONFIG[go_framework]:-basic}" in
                adk) create_go_adk_project "." "${project_name}"; project_type="adk-go" ;;
                *)   create_go_project "." "${project_name}" ;;
            esac
            ;;
        adk-go)
            create_go_adk_project "." "${project_name}"
            ;;
        dotnet)
            create_dotnet_project "$(pwd)" "${project_name}"
            ;;
        rust)
            case "${PROJECT_CONFIG[rust_framework]:-basic}" in
                actix)  create_actix_project "." "${project_name}"; project_type="actix" ;;
                rocket) create_rocket_project "." "${project_name}"; project_type="rocket" ;;
                *)      create_rust_project "." "${project_name}" ;;
            esac
            ;;
        actix)
            create_actix_project "." "${project_name}"
            ;;
        rocket)
            create_rocket_project "." "${project_name}"
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

create_javascript_project() {
    local project_dir="$1"

    # Create basic JavaScript structure
    mkdir -p "${project_dir}/src"
    mkdir -p "${project_dir}/tests"

    # package.json — scripts only; npm install below resolves compatible latest versions
    cat > "${project_dir}/package.json" << 'EOF'
{
  "name": "project",
  "version": "1.0.0",
  "scripts": {
    "dev": "node src/index.js",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src tests"
  }
}
EOF

    # jest.config.js — plain JS, no TypeScript
    cat > "${project_dir}/jest.config.js" << 'EOF'
/** @type {import('jest').Config} */
const config = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: ['src/**/*.js'],
};

module.exports = config;
EOF

    # ESLint 9 flat config — JS only (no typescript-eslint)
    cat > "${project_dir}/eslint.config.cjs" << 'EOF'
// eslint.config.cjs — ESLint 9 flat config
const js = require('@eslint/js');

module.exports = [
  { ignores: ['coverage/', 'node_modules/'] },
  js.configs.recommended,
  {
    rules: {
      'no-unused-vars': 'warn',
      'no-console': 'off',
    },
  },
];
EOF

    # src/index.js
    cat > "${project_dir}/src/index.js" << 'EOF'
// Ralph Loop Framework - JavaScript Project

/**
 * Returns a greeting for the given name.
 * @param {string} name
 * @returns {string}
 */
function greet(name) {
  return `Hello, ${name}!`;
}

module.exports = { greet };

if (require.main === module) {
  console.log(greet('Ralph Loop'));
}
EOF

    # tests/index.test.js
    cat > "${project_dir}/tests/index.test.js" << 'EOF'
const { greet } = require('../src/index');

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
.env
.env.local
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
EOF

    print_info "Installing JavaScript dependencies (npm selects compatible latest versions)..."
    (cd "${project_dir}" && npm install --save-dev \
        jest \
        eslint @eslint/js \
        --silent \
    ) && print_success "npm install complete" \
      || print_warning "npm install failed — run manually: cd ${project_dir} && npm install --save-dev jest eslint @eslint/js"

    print_success "Created JavaScript project structure"
}

create_typescript_project() {
    local project_dir="$1"

    # Create basic TypeScript structure
    mkdir -p "${project_dir}/src"
    mkdir -p "${project_dir}/tests"

    # package.json — scripts only; npm install below resolves compatible latest versions
    cat > "${project_dir}/package.json" << 'EOF'
{
  "name": "project",
  "version": "1.0.0",
  "scripts": {
    "dev": "ts-node src/index.ts",
    "build": "tsc",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src tests"
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

    # ESLint 9 flat config using typescript-eslint unified package
    # Compatible with whatever version npm installs (ESLint 9+ required)
    cat > "${project_dir}/eslint.config.cjs" << 'EOF'
// eslint.config.cjs — ESLint 9 flat config with typescript-eslint
const tseslint = require('typescript-eslint');

module.exports = tseslint.config(
  { ignores: ['dist/', 'coverage/', 'node_modules/', 'eslint.config.cjs'] },
  ...tseslint.configs.recommended,
);
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
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
EOF

    print_info "Installing TypeScript dependencies (npm selects compatible latest versions)..."
    (cd "${project_dir}" && npm install --save-dev \
        typescript ts-node @types/node \
        jest ts-jest @types/jest \
        eslint typescript-eslint \
        --silent \
    ) && print_success "npm install complete" \
      || print_warning "npm install failed — run manually: cd ${project_dir} && npm install --save-dev typescript ts-node @types/node jest ts-jest @types/jest eslint typescript-eslint"

    print_success "Created TypeScript project structure"
}

create_python_project() {
    local project_dir="$1"

    # Create basic Python structure
    mkdir -p "${project_dir}/src"
    mkdir -p "${project_dir}/tests"

    # requirements.txt — no version pins; pip selects latest compatible versions
    cat > "${project_dir}/requirements.txt" << 'EOF'
pytest
pytest-cov
black
flake8
mypy
httpx
pytest-asyncio
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
logs/
*.log
EOF

    print_info "Creating Python virtual environment..."
    (cd "${project_dir}" && python3 -m venv venv) \
        && print_success "venv created at venv/" \
        || print_warning "venv creation failed — run manually: cd ${project_dir} && python3 -m venv venv"

    print_info "Installing Python dependencies into venv..."
    (cd "${project_dir}" && venv/bin/pip install -r requirements.txt -q) \
        && print_success "pip install complete" \
        || print_warning "pip install failed — run manually: cd ${project_dir} && source venv/bin/activate && pip install -r requirements.txt"

    print_info "Running tests..."
    (cd "${project_dir}" && venv/bin/pytest tests/ -q 2>&1) \
        && print_success "Tests passed" \
        || print_warning "Tests failed — run manually: cd ${project_dir} && venv/bin/pytest tests/"

    print_success "Created Python project structure"
}

create_go_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/internal"

    # Detect installed Go version (major.minor only)
    local go_version
    go_version=$(go version 2>/dev/null | grep -oP 'go\K[0-9]+\.[0-9]+' | head -1)
    go_version="${go_version:-1.22}"

    # go.mod
    cat > "${project_dir}/go.mod" << EOF
module ${project_name}

go ${go_version}
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
logs/
*.log
EOF

    print_info "Running go mod tidy..."
    (cd "${project_dir}" && go mod tidy) && print_success "go mod tidy complete" || print_warning "go mod tidy failed — run manually: cd ${project_dir} && go mod tidy"

    print_success "Created Go project structure"
}

create_go_adk_project() {
    local project_dir="$1"
    local project_name="$2"

    # Model config (set by ask_project_questions or shortcut defaults)
    local model_id="${PROJECT_CONFIG[adk_model]:-gemini-flash-latest}"
    local env_var="${PROJECT_CONFIG[adk_env_var]:-GOOGLE_API_KEY}"

    # Detect installed Go major.minor (adk-go needs 1.24+)
    local go_version
    go_version=$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+' | head -1 | sed 's/go//')
    go_version="${go_version:-1.24}"

    # go.mod — module + go directive; go mod tidy below pulls all adk-go deps
    cat > "${project_dir}/go.mod" << EOF
module ${project_name}

go ${go_version}
EOF

    # agent.go — adk-go agent factory + main() launcher.
    # NewAgent is extracted so tests can build the agent with a fake API key
    # (gemini.NewModel does not validate the key at construction time, so the
    # agent struct can be inspected without ever calling Gemini).
    cat > "${project_dir}/agent.go" << EOF
// Package main is the entry point for the ADK agent.
//
// Edit NewAgent() to change the agent's name, instruction, model, or tools.
package main

import (
	"context"
	"log"
	"os"

	"google.golang.org/adk/agent"
	"google.golang.org/adk/agent/llmagent"
	"google.golang.org/adk/cmd/launcher"
	"google.golang.org/adk/cmd/launcher/full"
	"google.golang.org/adk/model/gemini"
	"google.golang.org/adk/tool"
	"google.golang.org/adk/tool/geminitool"
	"google.golang.org/genai"
)

// NewAgent builds the root agent. Extracted so tests can construct the agent
// with a fake API key — gemini.NewModel does not make network calls at
// construction time, so the agent struct can be inspected hermetically.
func NewAgent(ctx context.Context, apiKey, modelID string) (agent.Agent, error) {
	model, err := gemini.NewModel(ctx, modelID, &genai.ClientConfig{
		APIKey: apiKey,
	})
	if err != nil {
		return nil, err
	}
	return llmagent.New(llmagent.Config{
		Name:        "hello_time_agent",
		Model:       model,
		Description: "Tells the current time in a specified city.",
		Instruction: "You are a helpful assistant that tells the current time " +
			"in a specified city. Use the available tools.",
		Tools: []tool.Tool{geminitool.GoogleSearch{}},
	})
}

func main() {
	ctx := context.Background()

	rootAgent, err := NewAgent(ctx, os.Getenv("${env_var}"), "${model_id}")
	if err != nil {
		log.Fatalf("Failed to create agent: %v", err)
	}

	l := full.NewLauncher()
	l.Execute(ctx, &launcher.Config{
		AgentLoader: agent.NewSingleLoader(rootAgent),
	}, os.Args[1:])
}
EOF

    # agent_test.go — hermetic test that does NOT call Gemini
    cat > "${project_dir}/agent_test.go" << EOF
package main

import (
	"context"
	"testing"
)

const expectedModel = "${model_id}"

func TestNewAgent_BuildsWithoutAPICall(t *testing.T) {
	ctx := context.Background()
	a, err := NewAgent(ctx, "fake-test-key-do-not-call", expectedModel)
	if err != nil {
		t.Fatalf("NewAgent failed: %v", err)
	}
	if a == nil {
		t.Fatal("agent is nil")
	}
}

func TestAgent_Name(t *testing.T) {
	ctx := context.Background()
	a, _ := NewAgent(ctx, "fake-test-key", expectedModel)
	if a.Name() != "hello_time_agent" {
		t.Errorf("agent name = %q, want hello_time_agent", a.Name())
	}
}

func TestAgent_Description(t *testing.T) {
	ctx := context.Background()
	a, _ := NewAgent(ctx, "fake-test-key", expectedModel)
	want := "Tells the current time in a specified city."
	if a.Description() != want {
		t.Errorf("agent description = %q, want %q", a.Description(), want)
	}
}
EOF

    # .env — placeholder API key; user must replace before running the agent
    cat > "${project_dir}/.env" << EOF
# Get a Gemini API key from https://aistudio.google.com/app/apikey
${env_var}="REPLACE_WITH_YOUR_GEMINI_API_KEY"
EOF

    # .gitignore — keep .env out of git (API key safety)
    cat > "${project_dir}/.gitignore" << 'EOF'
# Compiled binaries
*.exe
*.out
/dist/
/build/

# Environment (contains API key)
.env

# Test/coverage
/tmp/
coverage.out
coverage.html
logs/
*.log
EOF

    print_info "Running go mod tidy (downloads adk-go + transitive deps, may take a minute)..."
    (cd "${project_dir}" && go mod tidy 2>&1 | tail -5) \
        && print_success "go mod tidy complete" \
        || print_warning "go mod tidy failed — run manually: cd ${project_dir} && go mod tidy"

    print_info "Running go vet..."
    (cd "${project_dir}" && go vet ./... 2>&1) \
        && print_success "go vet passed" \
        || print_warning "go vet found issues — see output above"

    print_info "Running tests (hermetic — does not call Gemini)..."
    (cd "${project_dir}" && go test ./... 2>&1 | tail -5) \
        && print_success "Tests passed" \
        || print_warning "Tests failed — run manually: cd ${project_dir} && go test ./..."

    print_success "Created Go ADK project structure (provider: gemini, model: ${model_id})"
    echo
    print_warning "REQUIRED: Edit ${project_dir}/.env and replace REPLACE_WITH_YOUR_GEMINI_API_KEY"
    print_warning "Get a key from https://aistudio.google.com/app/apikey (the agent will not run without it)"
}

create_typescript_adk_project() {
    local project_dir="$1"
    local project_name="$2"

    # Model config (set by ask_project_questions or shortcut defaults)
    local model_id="${PROJECT_CONFIG[adk_model]:-gemini-flash-latest}"
    local env_var="${PROJECT_CONFIG[adk_env_var]:-GEMINI_API_KEY}"

    # Agent file name (becomes the app name in `adk web` picker).
    # Derived from project name: lowercase, hyphens/dots/spaces -> underscores.
    local agent_file
    agent_file="$(echo "${project_name}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]/_/g')"
    [ -z "${agent_file}" ] && agent_file="agent"

    # Canonical ADK TypeScript layout (mirrors the Python pattern):
    #   project_dir/
    #     agents/<agent_file>.ts        ← what `adk web agents/` scans
    #     agent.test.ts                 ← outside agents/ so adk web ignores it
    #     package.json
    #     tsconfig.json
    #     .env
    #     node_modules/                 ← outside agents/ so adk web ignores it
    # The TS `adk web` lists every .ts file in its target dir as one agent
    # (filename = app name). Test files inside `agents/` break the picker
    # (vitest internal state errors), so keep them OUTSIDE.
    mkdir -p "${project_dir}/agents"
    mkdir -p "${project_dir}/tests"

    # package.json — ESM + tsx for running .ts directly + vitest for tests
    cat > "${project_dir}/package.json" << EOF
{
  "name": "${project_name}",
  "version": "1.0.0",
  "type": "module",
  "main": "agents/${agent_file}.ts",
  "scripts": {
    "start": "npx adk run agents/${agent_file}.ts",
    "web": "npx adk web agents/",
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  },
  "dependencies": {
    "@google/adk": "*",
    "zod": "*"
  },
  "devDependencies": {
    "@google/adk-devtools": "*",
    "typescript": "*",
    "tsx": "*",
    "vitest": "*",
    "prettier": "*"
  }
}
EOF

    # tsconfig.json — modern ESM target, suitable for tsx + vitest
    cat > "${project_dir}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": false
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
EOF

    # agents/<agent_file>.ts — exports `rootAgent`. The filename (without .ts)
    # becomes the app name in the `adk web` picker. LlmAgent constructor is
    # hermetic (no API call at construction time), so tests can import
    # rootAgent directly.
    cat > "${project_dir}/agents/${agent_file}.ts" << EOF
import { FunctionTool, LlmAgent } from "@google/adk";
import { z } from "zod";

const getCurrentTime = new FunctionTool({
  name: "get_current_time",
  description: "Returns the current time in a specified city.",
  parameters: z.object({
    city: z
      .string()
      .describe("The name of the city for which to retrieve the current time."),
  }),
  execute: ({ city }) => {
    return {
      status: "success",
      report: \`The current time in \${city} is 10:30 AM\`,
    };
  },
});

export const rootAgent = new LlmAgent({
  name: "hello_time_agent",
  model: "${model_id}",
  description: "Tells the current time in a specified city.",
  instruction: \`You are a helpful assistant that tells the current time in a city.
                Use the 'getCurrentTime' tool for this purpose.\`,
  tools: [getCurrentTime],
});
EOF

    # tests/agent.test.ts — vitest. Hermetic: LlmAgent does not call the model
    # at construction time, so the tests run without GEMINI_API_KEY.
    # Tests live OUTSIDE agents/ so `adk web` does not try to load them.
    cat > "${project_dir}/tests/agent.test.ts" << EOF
import { describe, it, expect } from "vitest";
import { rootAgent } from "../agents/${agent_file}.js";

describe("rootAgent (ADK Gemini agent)", () => {
  it("is constructed without an API key", () => {
    expect(rootAgent).toBeDefined();
  });

  it("has the expected name", () => {
    expect(rootAgent.name).toBe("hello_time_agent");
  });

  it("uses the configured model", () => {
    expect(rootAgent.model).toBe("${model_id}");
  });

  it("has the get_current_time tool registered", () => {
    const toolNames = rootAgent.tools.map((t: any) => t.name);
    expect(toolNames).toContain("get_current_time");
  });
});
EOF

    # .env — placeholder API key; user must replace before running the agent.
    # TypeScript ADK uses GEMINI_API_KEY (NOT GOOGLE_API_KEY like Python).
    cat > "${project_dir}/.env" << EOF
# Get a Gemini API key from https://aistudio.google.com/app/apikey
${env_var}="REPLACE_WITH_YOUR_GEMINI_API_KEY"
EOF

    # .prettierrc — match Python's black-equivalent: opinionated, no config
    cat > "${project_dir}/.prettierrc.json" << 'EOF'
{
  "semi": true,
  "singleQuote": false,
  "trailingComma": "all",
  "printWidth": 80
}
EOF

    # .prettierignore — skip node_modules and lockfiles
    cat > "${project_dir}/.prettierignore" << 'EOF'
node_modules/
package-lock.json
yarn.lock
pnpm-lock.yaml
dist/
.vitest/
EOF

    # .gitignore — keep node_modules and .env out of git
    cat > "${project_dir}/.gitignore" << 'EOF'
node_modules/
dist/
build/

# Environment (contains API key)
.env
.env.local

# Test/coverage
coverage/
.vitest/

# Logs
logs/
*.log
npm-debug.log*
EOF

    print_info "Installing @google/adk + test dependencies (this may take a minute)..."
    (cd "${project_dir}" && npm install --silent 2>&1 | tail -5) \
        && print_success "npm install complete" \
        || print_warning "npm install failed — run manually: cd ${project_dir} && npm install"

    print_info "Running typecheck..."
    (cd "${project_dir}" && npx tsc --noEmit 2>&1 | tail -5) \
        && print_success "tsc clean" \
        || print_warning "tsc found type errors — run manually: cd ${project_dir} && npx tsc --noEmit"

    print_info "Running prettier --check..."
    (cd "${project_dir}" && npx prettier --check . 2>&1 | tail -3) \
        && print_success "prettier clean" \
        || print_warning "prettier check failed — run: cd ${project_dir} && npx prettier --write ."

    print_info "Running tests (hermetic — does not call Gemini)..."
    (cd "${project_dir}" && npx vitest run 2>&1 | tail -10) \
        && print_success "Tests passed" \
        || print_warning "Tests failed — run manually: cd ${project_dir} && npx vitest run"

    print_success "Created TypeScript ADK project structure (provider: gemini, model: ${model_id})"
    echo
    print_warning "REQUIRED: Edit ${project_dir}/.env and replace REPLACE_WITH_YOUR_GEMINI_API_KEY"
    print_warning "Get a key from https://aistudio.google.com/app/apikey (the agent will not run without it)"
    echo
    print_info "To run the agent:"
    print_info "  cd ${project_dir}"
    print_info "  npx adk run agents/${agent_file}.ts       # interactive CLI"
    print_info "  npx adk web agents/                       # web UI at http://localhost:8000"
}

create_java_adk_project() {
    local project_dir="$1"
    local project_name="$2"

    # Model config (set by ask_project_questions or shortcut defaults)
    local provider="${PROJECT_CONFIG[adk_provider]:-gemini}"
    local model_id="${PROJECT_CONFIG[adk_model]:-gemini-flash-latest}"
    local env_var="${PROJECT_CONFIG[adk_env_var]:-GOOGLE_API_KEY}"

    # Friendly description for the .env comment and final warning
    local provider_display="${provider}"
    local article="a"
    local key_url=""
    case "${provider}" in
        gemini)    provider_display="Gemini";    key_url="https://aistudio.google.com/app/apikey" ;;
        anthropic) provider_display="Anthropic"; article="an"; key_url="https://console.anthropic.com/settings/keys" ;;
        *)         provider_display="${provider}"; key_url="your model provider's API key dashboard" ;;
    esac

    # Maven artifactId: lowercased, allows dashes (java-adk1234 valid).
    # Force lowercase; replace any non-[a-z0-9-] with dash.
    local artifact_id
    artifact_id="$(echo "${project_name}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"
    [ -z "${artifact_id}" ] && artifact_id="adk-agent"

    # Java package — fixed at com.example.agent (matches the ADK quickstart);
    # users rename if they want their own namespace.
    local pkg_path="src/main/java/com/example/agent"
    local test_pkg_path="src/test/java/com/example/agent"
    mkdir -p "${project_dir}/${pkg_path}"
    mkdir -p "${project_dir}/${test_pkg_path}"

    # pom.xml — google-adk + google-adk-dev (for adk web), JUnit 5 for tests,
    # surefire 3.x picks up *Test.java automatically.
    cat > "${project_dir}/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>${artifact_id}</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <adk.version>1.2.0</adk.version>
        <junit.version>5.10.0</junit.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>com.google.adk</groupId>
            <artifactId>google-adk</artifactId>
            <version>\${adk.version}</version>
        </dependency>
        <dependency>
            <groupId>com.google.adk</groupId>
            <artifactId>google-adk-dev</artifactId>
            <version>\${adk.version}</version>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>\${junit.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.2.5</version>
            </plugin>
        </plugins>
    </build>
</project>
EOF

    # HelloTimeAgent.java — provider-specific model construction. The agent
    # is exposed via a static ROOT_AGENT field so InMemoryRunner can find it,
    # AND a builder method buildAgent() so tests can construct it explicitly
    # with a fake API key. Both Gemini (string model) and Anthropic Claude
    # (Claude object via Anthropic SDK) are hermetic at construction time.
    if [ "${provider}" = "anthropic" ]; then
        cat > "${project_dir}/${pkg_path}/HelloTimeAgent.java" << EOF
package com.example.agent;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.models.Claude;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;
import java.util.Map;

/** Root ADK agent. Edit buildAgent() to change the agent's behavior. */
public class HelloTimeAgent {

    public static final String MODEL_ID = "${model_id}";

    public static final BaseAgent ROOT_AGENT = buildAgent(System.getenv("${env_var}"));

    /** Build the agent. Extracted so tests can pass a fake API key. */
    public static BaseAgent buildAgent(String apiKey) {
        AnthropicClient client = AnthropicOkHttpClient.builder()
            .apiKey(apiKey == null ? "" : apiKey)
            .build();
        Claude model = new Claude(MODEL_ID, client);
        return LlmAgent.builder()
            .name("hello_time_agent")
            .description("Tells the current time in a specified city.")
            .instruction(
                "You are a helpful assistant that tells the current time in a city. "
                    + "Use the 'getCurrentTime' tool for this purpose.")
            .model(model)
            .tools(FunctionTool.create(HelloTimeAgent.class, "getCurrentTime"))
            .build();
    }

    @Schema(description = "Get the current time for a given city.")
    public static Map<String, String> getCurrentTime(
        @Schema(name = "city", description = "Name of the city.") String city) {
        return Map.of("status", "success", "city", city, "time", "10:30 AM");
    }
}
EOF
    else
        cat > "${project_dir}/${pkg_path}/HelloTimeAgent.java" << EOF
package com.example.agent;

import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;
import java.util.Map;

/** Root ADK agent. Edit buildAgent() to change the agent's behavior. */
public class HelloTimeAgent {

    public static final String MODEL_ID = "${model_id}";

    public static final BaseAgent ROOT_AGENT = buildAgent();

    /** Build the agent. The Gemini model is referenced by string, so the
     *  constructor does not call the model and tests are hermetic. */
    public static BaseAgent buildAgent() {
        return LlmAgent.builder()
            .name("hello_time_agent")
            .description("Tells the current time in a specified city.")
            .instruction(
                "You are a helpful assistant that tells the current time in a city. "
                    + "Use the 'getCurrentTime' tool for this purpose.")
            .model(MODEL_ID)
            .tools(FunctionTool.create(HelloTimeAgent.class, "getCurrentTime"))
            .build();
    }

    @Schema(description = "Get the current time for a given city.")
    public static Map<String, String> getCurrentTime(
        @Schema(name = "city", description = "Name of the city.") String city) {
        return Map.of("status", "success", "city", city, "time", "10:30 AM");
    }
}
EOF
    fi

    # AgentCliRunner.java — InMemoryRunner + Scanner loop (the production
    # CLI runner from the ADK quickstart). Loads ROOT_AGENT and pipes
    # stdin lines through the agent.
    cat > "${project_dir}/${pkg_path}/AgentCliRunner.java" << 'EOF'
package com.example.agent;

import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import java.util.Map;
import java.util.Scanner;
import java.util.UUID;

/** Run the agent interactively in the terminal. */
public class AgentCliRunner {
    public static void main(String[] args) throws Exception {
        InMemoryRunner runner = new InMemoryRunner(HelloTimeAgent.ROOT_AGENT);
        String userId = "user-" + UUID.randomUUID();
        Session session = runner
            .sessionService()
            .createSession(runner.appName(), userId, /*state=*/ Map.of(), /*sessionId=*/ null)
            .blockingGet();

        try (Scanner in = new Scanner(System.in)) {
            System.out.println("Type a message (Ctrl+D to exit):");
            while (in.hasNextLine()) {
                String userText = in.nextLine();
                Content message = Content.fromParts(Part.fromText(userText));
                Flowable<Event> events =
                    runner.runAsync(userId, session.id(), message);
                events.blockingForEach(e -> {
                    if (e.finalResponse()) {
                        String text = e.stringifyContent();
                        if (text != null && !text.isEmpty()) {
                            System.out.println(text);
                        }
                    }
                });
            }
        }
    }
}
EOF

    # HelloTimeAgentTest.java — hermetic JUnit 5 tests.
    if [ "${provider}" = "anthropic" ]; then
        cat > "${project_dir}/${test_pkg_path}/HelloTimeAgentTest.java" << EOF
package com.example.agent;

import static org.junit.jupiter.api.Assertions.*;

import com.google.adk.agents.BaseAgent;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Hermetic tests for HelloTimeAgent. Does NOT call the model API. */
class HelloTimeAgentTest {

    @Test
    void buildAgent_doesNotCallApi() {
        // Anthropic builder is lazy: fake key does not trigger a network call.
        BaseAgent agent = HelloTimeAgent.buildAgent("sk-ant-fake-test-key");
        assertNotNull(agent);
    }

    @Test
    void agent_hasExpectedName() {
        BaseAgent agent = HelloTimeAgent.buildAgent("fake-key");
        assertEquals("hello_time_agent", agent.name());
    }

    @Test
    void agent_hasExpectedDescription() {
        BaseAgent agent = HelloTimeAgent.buildAgent("fake-key");
        assertEquals("Tells the current time in a specified city.", agent.description());
    }

    @Test
    void getCurrentTime_returnsSuccessMap() {
        Map<String, String> result = HelloTimeAgent.getCurrentTime("Paris");
        assertEquals("success", result.get("status"));
        assertEquals("Paris", result.get("city"));
    }

    @Test
    void modelId_matchesConfig() {
        assertEquals("${model_id}", HelloTimeAgent.MODEL_ID);
    }
}
EOF
    else
        cat > "${project_dir}/${test_pkg_path}/HelloTimeAgentTest.java" << EOF
package com.example.agent;

import static org.junit.jupiter.api.Assertions.*;

import com.google.adk.agents.BaseAgent;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Hermetic tests for HelloTimeAgent. Does NOT call the model API. */
class HelloTimeAgentTest {

    @Test
    void buildAgent_doesNotCallApi() {
        // Gemini model is a string; no API call happens at build time.
        BaseAgent agent = HelloTimeAgent.buildAgent();
        assertNotNull(agent);
    }

    @Test
    void agent_hasExpectedName() {
        BaseAgent agent = HelloTimeAgent.buildAgent();
        assertEquals("hello_time_agent", agent.name());
    }

    @Test
    void agent_hasExpectedDescription() {
        BaseAgent agent = HelloTimeAgent.buildAgent();
        assertEquals("Tells the current time in a specified city.", agent.description());
    }

    @Test
    void getCurrentTime_returnsSuccessMap() {
        Map<String, String> result = HelloTimeAgent.getCurrentTime("Paris");
        assertEquals("success", result.get("status"));
        assertEquals("Paris", result.get("city"));
    }

    @Test
    void modelId_matchesConfig() {
        assertEquals("${model_id}", HelloTimeAgent.MODEL_ID);
    }
}
EOF
    fi

    # .env — placeholder API key; user must replace before running the agent
    cat > "${project_dir}/.env" << EOF
# Get ${article} ${provider_display} API key from ${key_url}
${env_var}="REPLACE_WITH_YOUR_${provider_display^^}_API_KEY"
EOF

    # .gitignore — keep .env and Maven outputs out of git
    cat > "${project_dir}/.gitignore" << 'EOF'
# Maven outputs
target/
*.class
*.jar

# IDE
.idea/
*.iml
.vscode/
.project
.classpath
.settings/

# Environment (contains API key)
.env

# Logs
logs/
*.log
EOF

    print_info "Running mvn compile (downloads google-adk + transitive deps, may take a minute)..."
    # set -o pipefail so the subshell exit reflects mvn's exit, not tail's
    (cd "${project_dir}" && set -o pipefail; mvn -q compile 2>&1 | tail -10) \
        && print_success "mvn compile passed" \
        || print_warning "mvn compile failed — run manually: cd ${project_dir} && mvn compile"

    print_info "Running mvn test (hermetic — does not call the model)..."
    (cd "${project_dir}" && set -o pipefail; mvn -q test 2>&1 | tail -15) \
        && print_success "Tests passed" \
        || print_warning "Tests failed — run manually: cd ${project_dir} && mvn test"

    print_success "Created Java ADK project structure (provider: ${provider}, model: ${model_id})"
    echo
    print_warning "REQUIRED: Edit ${project_dir}/.env and replace REPLACE_WITH_YOUR_${provider_display^^}_API_KEY"
    print_warning "Get a key from ${key_url} (the agent will not run without it)"
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
logs/
*.log
tarpaulin-report.html
cobertura.xml
lcov.info
EOF

    print_info "Running cargo check..."
    (cd "${project_dir}" && cargo check --quiet) && print_success "cargo check complete" || print_warning "cargo check failed — run manually: cd ${project_dir} && cargo check"

    print_success "Created Rust project structure"
}

create_actix_project() {
    local project_dir="$1"
    local project_name="$2"

    if ! command -v cargo > /dev/null 2>&1; then
        print_warning "cargo not found — creating placeholder Actix structure"
        mkdir -p "${project_dir}/src" "${project_dir}/tests"
        cat > "${project_dir}/Cargo.toml" << EOF
[package]
name = "${project_name}"
version = "0.1.0"
edition = "2021"

[dependencies]
actix-web = "4"
tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
EOF
        print_info "Install Rust from https://rustup.rs/ then run: cd ${project_dir} && cargo build"
        return
    fi

    # Initialize cargo project
    (cd "${project_dir}" && cargo init --name "${project_name}" 2>/dev/null) || true

    # Write Cargo.toml with actix-web dependencies
    cat > "${project_dir}/Cargo.toml" << EOF
[package]
name = "${project_name}"
version = "0.1.0"
edition = "2021"

[dependencies]
actix-web = "4"
tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[dev-dependencies]
actix-rt = "2"
EOF

    # main.rs — basic Actix-web server with health endpoint
    cat > "${project_dir}/src/main.rs" << 'EOF'
use actix_web::{get, App, HttpResponse, HttpServer, Responder};
use serde::Serialize;

#[derive(Serialize)]
struct HealthResponse {
    status: String,
}

#[derive(Serialize)]
struct GreetResponse {
    message: String,
}

#[get("/")]
async fn index() -> impl Responder {
    HttpResponse::Ok().json(GreetResponse {
        message: "Hello from Ralph Loop!".to_string(),
    })
}

#[get("/health")]
async fn health() -> impl Responder {
    HttpResponse::Ok().json(HealthResponse {
        status: "ok".to_string(),
    })
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("Starting server at http://localhost:8080");
    HttpServer::new(|| {
        App::new()
            .service(index)
            .service(health)
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, App};

    #[actix_web::test]
    async fn test_index_ok() {
        let app = test::init_service(App::new().service(index)).await;
        let req = test::TestRequest::get().uri("/").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_health_ok() {
        let app = test::init_service(App::new().service(health)).await;
        let req = test::TestRequest::get().uri("/health").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }
}
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
/target/
Cargo.lock
logs/
*.log
tarpaulin-report.html
cobertura.xml
lcov.info
EOF

    print_info "Building Actix project (downloads dependencies — may take a moment)..."
    (cd "${project_dir}" && cargo build --quiet) \
        && print_success "cargo build complete" \
        || print_warning "cargo build failed — run manually: cd ${project_dir} && cargo build"

    print_success "Created Actix Web project structure"
}

create_rocket_project() {
    local project_dir="$1"
    local project_name="$2"

    if ! command -v cargo > /dev/null 2>&1; then
        print_warning "cargo not found — creating placeholder Rocket structure"
        mkdir -p "${project_dir}/src" "${project_dir}/tests"
        cat > "${project_dir}/Cargo.toml" << EOF
[package]
name = "${project_name}"
version = "0.1.0"
edition = "2021"

[dependencies]
rocket = { version = "0.5", features = ["json"] }
serde = { version = "1", features = ["derive"] }
EOF
        print_info "Install Rust from https://rustup.rs/ then run: cd ${project_dir} && cargo build"
        return
    fi

    # Initialize cargo project
    (cd "${project_dir}" && cargo init --name "${project_name}" 2>/dev/null) || true

    # Cargo.toml with Rocket 0.5 (stable, no nightly required)
    cat > "${project_dir}/Cargo.toml" << EOF
[package]
name = "${project_name}"
version = "0.1.0"
edition = "2021"

[dependencies]
rocket = { version = "0.5", features = ["json"] }
serde = { version = "1", features = ["derive"] }
EOF

    # main.rs — basic Rocket server with health endpoint
    cat > "${project_dir}/src/main.rs" << 'EOF'
#[macro_use]
extern crate rocket;

use rocket::serde::{json::Json, Serialize};

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
struct GreetResponse {
    message: String,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
struct HealthResponse {
    status: String,
}

#[get("/")]
fn index() -> Json<GreetResponse> {
    Json(GreetResponse {
        message: "Hello from Ralph Loop!".to_string(),
    })
}

#[get("/health")]
fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok".to_string(),
    })
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/", routes![index, health])
}

#[cfg(test)]
mod tests {
    use super::*;
    use rocket::local::blocking::Client;
    use rocket::http::Status;

    fn test_client() -> Client {
        Client::tracked(rocket()).expect("valid rocket instance")
    }

    #[test]
    fn test_index_ok() {
        let client = test_client();
        let response = client.get("/").dispatch();
        assert_eq!(response.status(), Status::Ok);
    }

    #[test]
    fn test_health_ok() {
        let client = test_client();
        let response = client.get("/health").dispatch();
        assert_eq!(response.status(), Status::Ok);
    }
}
EOF

    # .gitignore
    cat > "${project_dir}/.gitignore" << 'EOF'
/target/
Cargo.lock
logs/
*.log
tarpaulin-report.html
cobertura.xml
lcov.info
EOF

    print_info "Building Rocket project (downloads dependencies — may take a moment)..."
    (cd "${project_dir}" && cargo build --quiet) \
        && print_success "cargo build complete" \
        || print_warning "cargo build failed — run manually: cd ${project_dir} && cargo build"

    print_success "Created Rocket project structure"
}

create_angular_project() {
    local project_dir="$1"
    local project_name="$2"
    local current_dir
    current_dir="$(pwd)"
    local parent_dir
    parent_dir="$(dirname "${current_dir}")"

    print_info "Scaffolding Angular project via @angular/cli@latest..."
    print_info "(Installs Angular + all compatible dependencies — may take 2-3 minutes)"

    # ng new creates its own directory, so we run it from the parent.
    # The pre-created empty project dir is removed first to avoid conflicts.
    # ng new also runs npm install automatically.
    # IMPORTANT: the subshell below removes the pre-created empty project dir
    # (so ng new can create it cleanly), then ng new recreates it with a new inode.
    # After the subshell exits, the main shell's CWD still points to the OLD
    # (now-orphaned) inode. We must re-cd by absolute path to get the new inode.
    if (
        cd "${parent_dir}" || exit 1
        rm -rf "${project_name}" 2>/dev/null || true
        npx --yes @angular/cli@latest new "${project_name}" \
            --skip-git \
            --routing=false \
            --style=css \
            --standalone \
            --defaults \
            --package-manager=npm
    ); then
        # Re-enter project dir by absolute path to pick up the new inode
        cd "${current_dir}" || { print_warning "Could not cd into ${current_dir}"; return 1; }
        print_success "Angular project scaffolded with latest compatible packages"
        print_info "(All dependencies installed by ng new)"

        # Add test:coverage script to package.json
        if [ -f "${current_dir}/package.json" ]; then
            node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = pkg.scripts || {};
if (!pkg.scripts['test:coverage']) {
    pkg.scripts['test:coverage'] = 'ng test --no-watch --code-coverage';
}
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
" 2>/dev/null && print_success "Added test:coverage script" || true
        fi

        # Add coverage/ to .gitignore
        if [ -f "${current_dir}/.gitignore" ] && ! grep -q '^coverage/' "${current_dir}/.gitignore"; then
            echo "coverage/" >> "${current_dir}/.gitignore"
        fi

        return 0
    fi

    # Restore directory so subsequent script steps don't fail
    mkdir -p "${current_dir}"
    cd "${current_dir}" 2>/dev/null || true
    print_warning "Angular scaffolding failed."
    print_warning "To scaffold manually run:"
    print_warning "  cd ${parent_dir} && npx @angular/cli@latest new ${project_name} --skip-git --standalone --defaults"

    # Fallback: note instructions in a README and exit
    print_warning "Project directory created but Angular is not configured."
    print_warning "Run the scaffold command above to complete setup."
}

create_react_project() {
    local project_dir="$1"
    local project_name="$2"
    local current_dir
    current_dir="$(pwd)"
    local parent_dir
    parent_dir="$(dirname "${current_dir}")"

    print_info "Scaffolding React (Vite) project via create-vite@latest..."

    # create-vite creates its own directory; run from parent after removing pre-created empty dir.
    # Note: create-vite does NOT run npm install automatically.
    # IMPORTANT: rm -rf inside the subshell orphans our CWD inode.
    # We must re-cd by absolute path after the subshell to get the new inode.
    if ! (
        cd "${parent_dir}" || exit 1
        rm -rf "${project_name}" 2>/dev/null || true
        npm create vite@latest "${project_name}" -- --template react-ts
    ); then
        mkdir -p "${current_dir}"
        cd "${current_dir}" 2>/dev/null || true
        print_warning "React/Vite scaffolding failed."
        print_warning "To scaffold manually: cd ${parent_dir} && npm create vite@latest ${project_name} -- --template react-ts"
        return 0
    fi

    # Re-enter project dir by absolute path to pick up the new inode
    cd "${current_dir}" || { print_warning "Could not cd into ${current_dir}"; return 1; }

    # Install base deps (create-vite does not run npm install)
    print_info "Installing base React dependencies..."
    (cd "${current_dir}" && npm install --silent)

    # Add testing packages — npm resolves compatible latest versions
    print_info "Installing testing packages (npm selects compatible latest versions)..."
    (cd "${current_dir}" && npm install --save-dev \
        vitest \
        @vitest/coverage-v8 \
        @testing-library/react \
        @testing-library/jest-dom \
        @testing-library/user-event \
        jsdom \
        --silent)

    # Update package.json scripts to add test commands
    (cd "${current_dir}" && \
        npm pkg set scripts.test="vitest run" && \
        npm pkg set scripts.test:watch="vitest" && \
        npm pkg set scripts.test:coverage="vitest run --coverage")

    # Overwrite vite.config.ts to add vitest config
    cat > "${project_dir}/vite.config.ts" << 'EOF'
/// <reference types="vitest" />
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

    # Testing setup file
    cat > "${project_dir}/src/setupTests.ts" << 'EOF'
import '@testing-library/jest-dom';
EOF

    # Overwrite App.tsx with Ralph greeting example
    cat > "${project_dir}/src/App.tsx" << 'EOF'
interface AppProps {
  name?: string;
}

function App({ name = 'Ralph Loop' }: AppProps) {
  return (
    <div>
      <h1>Hello from {name}!</h1>
    </div>
  );
}

export default App;
EOF

    # Example test
    cat > "${project_dir}/src/App.test.tsx" << 'EOF'
import { render, screen } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('renders default greeting', () => {
    render(<App />);
    expect(screen.getByText('Hello from Ralph Loop!')).toBeInTheDocument();
  });

  it('renders custom name', () => {
    render(<App name="World" />);
    expect(screen.getByText('Hello from World!')).toBeInTheDocument();
  });
});
EOF

    print_success "React project scaffolded with latest compatible packages"
}

create_nextjs_project() {
    local project_dir="$1"
    local project_name="$2"
    local current_dir
    current_dir="$(pwd)"
    local parent_dir
    parent_dir="$(dirname "${current_dir}")"

    print_info "Scaffolding Next.js project via create-next-app@latest..."
    print_info "(Installs Next.js + all compatible dependencies — may take 1-2 minutes)"

    # React Compiler flag — user choice from ask_project_questions (default: no)
    local rc_flag="--no-react-compiler"
    if [ "${PROJECT_CONFIG[react_compiler]:-no}" = "yes" ]; then
        rc_flag="--react-compiler"
        print_info "React Compiler enabled (auto-memoization)"
    fi

    # create-next-app creates its own directory; run from parent after removing pre-created empty dir.
    # create-next-app@latest runs npm install automatically.
    # IMPORTANT: rm -rf inside the subshell orphans our CWD inode.
    # We must re-cd by absolute path after the subshell to get the new inode.
    if ! (
        cd "${parent_dir}" || exit 1
        rm -rf "${project_name}" 2>/dev/null || true
        npx create-next-app@latest "${project_name}" \
            --typescript \
            --eslint \
            --no-tailwind \
            --src-dir \
            --app \
            --no-import-alias \
            --use-npm \
            "${rc_flag}"
    ); then
        mkdir -p "${current_dir}"
        cd "${current_dir}" 2>/dev/null || true
        print_warning "Next.js scaffolding failed."
        print_warning "To scaffold manually: npx create-next-app@latest ${project_name} --typescript --eslint --src-dir --app --use-npm ${rc_flag}"
        return 0
    fi

    # Re-enter project dir by absolute path to pick up the new inode
    cd "${current_dir}" || { print_warning "Could not cd into ${current_dir}"; return 1; }

    # Install jest testing packages — npm resolves compatible latest versions
    print_info "Installing jest testing packages (npm selects compatible latest versions)..."
    (cd "${current_dir}" && npm install --save-dev \
        jest \
        jest-environment-jsdom \
        @testing-library/react \
        @testing-library/jest-dom \
        @testing-library/user-event \
        @types/jest \
        ts-jest \
        ts-node \
        supertest \
        @types/supertest \
        --silent)

    # Add test scripts
    (cd "${current_dir}" && \
        npm pkg set scripts.test="jest" && \
        npm pkg set scripts.test:coverage="jest --coverage")

    # jest.config.ts using Next.js jest preset
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

    # jest setup file
    cat > "${project_dir}/jest.setup.ts" << 'EOF'
import '@testing-library/jest-dom';
EOF

    # Update home page with Ralph greeting
    cat > "${project_dir}/src/app/page.tsx" << 'EOF'
export default function Home() {
  return (
    <main>
      <h1>Hello from Ralph Loop!</h1>
    </main>
  );
}
EOF

    # Add example test
    mkdir -p "${project_dir}/src/__tests__"
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

    print_success "Next.js project scaffolded with latest compatible packages"
}

create_express_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/src/routes"
    mkdir -p "${project_dir}/src/middleware"
    mkdir -p "${project_dir}/tests"

    # package.json — scripts only; npm install below resolves compatible latest versions
    cat > "${project_dir}/package.json" << 'EOF'
{
  "name": "project",
  "version": "1.0.0",
  "scripts": {
    "dev": "nodemon src/index.ts",
    "start": "node dist/index.js",
    "build": "tsc",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src tests"
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

    # ESLint 9 flat config using typescript-eslint unified package
    cat > "${project_dir}/eslint.config.cjs" << 'EOF'
// eslint.config.cjs — ESLint 9 flat config with typescript-eslint
const tseslint = require('typescript-eslint');

module.exports = tseslint.config(
  { ignores: ['dist/', 'coverage/', 'node_modules/', 'eslint.config.cjs'] },
  ...tseslint.configs.recommended,
);
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
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
EOF

    print_info "Installing Express dependencies (npm selects compatible latest versions)..."
    (cd "${project_dir}" && npm install express --silent && \
        npm install --save-dev \
            typescript ts-node @types/node @types/express \
            nodemon \
            jest ts-jest @types/jest \
            supertest @types/supertest \
            eslint typescript-eslint \
            --silent \
    ) && print_success "npm install complete" \
      || print_warning "npm install failed — run manually: cd ${project_dir} && npm install express && npm install --save-dev typescript ts-node @types/node @types/express nodemon jest ts-jest @types/jest supertest @types/supertest eslint typescript-eslint"

    print_success "Created Express project structure"
}

create_flask_project() {
    local project_dir="$1"
    local project_name="$2"

    mkdir -p "${project_dir}/app"
    mkdir -p "${project_dir}/tests"

    # requirements.txt — no version pins; pip selects latest compatible versions
    cat > "${project_dir}/requirements.txt" << 'EOF'
flask
pytest
pytest-cov
black
flake8
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
logs/
*.log
EOF

    print_info "Creating Python virtual environment..."
    (cd "${project_dir}" && python3 -m venv venv) \
        && print_success "venv created at venv/" \
        || print_warning "venv creation failed — run manually: cd ${project_dir} && python3 -m venv venv"

    print_info "Installing Python dependencies into venv..."
    (cd "${project_dir}" && venv/bin/pip install -r requirements.txt -q) \
        && print_success "pip install complete" \
        || print_warning "pip install failed — run manually: cd ${project_dir} && source venv/bin/activate && pip install -r requirements.txt"

    print_info "Running tests..."
    (cd "${project_dir}" && venv/bin/pytest tests/ -q 2>&1) \
        && print_success "Tests passed" \
        || print_warning "Tests failed — run manually: cd ${project_dir} && venv/bin/pytest tests/"

    print_success "Created Flask project structure"
}

create_reflex_project() {
    local project_dir="$1"

    print_info "Creating Python virtual environment..."
    (cd "${project_dir}" && python3 -m venv venv) \
        && print_success "venv created at venv/" \
        || print_warning "venv creation failed — run manually: cd ${project_dir} && python3 -m venv venv"

    print_info "Installing Reflex and test dependencies..."
    (cd "${project_dir}" && venv/bin/pip install reflex pytest pytest-cov httpx pytest-asyncio -q) \
        && print_success "Reflex installed" \
        || print_warning "pip install failed — run: source venv/bin/activate && pip install reflex pytest pytest-cov httpx pytest-asyncio"

    # Derive module name: lowercase, hyphens/dots → underscores
    local module_name
    module_name=$(basename "${project_dir}" | tr '-.' '_' | tr '[:upper:]' '[:lower:]')

    print_info "Initializing Reflex project..."
    if (cd "${project_dir}" && venv/bin/reflex init --template blank --name "${module_name}" 2>/dev/null); then
        print_success "Reflex project initialized"
    else
        print_warning "reflex init failed — creating minimal placeholder structure"
        mkdir -p "${project_dir}/${module_name}"
        touch "${project_dir}/${module_name}/__init__.py"
        cat > "${project_dir}/${module_name}/${module_name}.py" << EOF
"""${module_name} — main Reflex application."""
import reflex as rx


class State(rx.State):
    """Application state."""
    count: int = 0

    def increment(self):
        self.count += 1


def index() -> rx.Component:
    return rx.center(
        rx.vstack(
            rx.heading("Reflex App", size="8"),
            rx.text(f"Count: {State.count}"),
            rx.button("Increment", on_click=State.increment),
            spacing="5",
        )
    )


app = rx.App()
app.add_page(index)
EOF
        cat > "${project_dir}/rxconfig.py" << EOF
import reflex as rx

config = rx.Config(
    app_name="${module_name}",
)
EOF
    fi

    # Tests directory — pytest unit tests for State logic
    mkdir -p "${project_dir}/tests"
    touch "${project_dir}/tests/__init__.py"
    cat > "${project_dir}/tests/test_state.py" << 'EOF'
"""Tests for Reflex application state.

Import your State class and test methods directly — no browser needed.
For UI testing use Playwright (if browser testing was enabled).

Example:
    from <module>.<module> import State
    state = State()
    state.increment()
    assert state.count == 1
"""


def test_placeholder():
    """Replace with actual state unit tests."""
    assert True
EOF

    # requirements.txt (may already exist from reflex init)
    if [ ! -f "${project_dir}/requirements.txt" ]; then
        cat > "${project_dir}/requirements.txt" << 'EOF'
reflex
pytest
pytest-cov
EOF
    else
        grep -q "^pytest" "${project_dir}/requirements.txt" \
            || printf "\npytest\npytest-cov\n" >> "${project_dir}/requirements.txt"
    fi

    # .gitignore (append Reflex-specific entries)
    cat >> "${project_dir}/.gitignore" << 'EOF'
# Reflex runtime
.web/
.states/
*.db
venv/
__pycache__/
*.pyc
.pytest_cache/
.coverage
logs/
*.log
EOF

    print_info "Running tests..."
    (cd "${project_dir}" && venv/bin/pytest tests/ -q 2>&1) \
        && print_success "Tests passed" \
        || print_warning "Tests failed — run manually: cd ${project_dir} && venv/bin/pytest tests/"

    print_success "Created Reflex project structure"
}

create_python_adk_project() {
    local project_dir="$1"
    local project_name="$2"

    # Python module name: hyphens → underscores (project_name may be "my-agent",
    # but `adk run` and `adk web` need a valid Python package directory)
    local agent_module="${project_name//-/_}"
    # Strip any non-identifier leading chars and any remaining invalid chars
    agent_module="$(echo "${agent_module}" | sed 's/[^a-zA-Z0-9_]/_/g')"
    # Fallback if name was empty/all-invalid
    [ -z "${agent_module}" ] && agent_module="my_agent"

    # Model / provider config (set by ask_project_questions or shortcut defaults)
    local provider="${PROJECT_CONFIG[adk_provider]:-gemini}"
    local model_id="${PROJECT_CONFIG[adk_model]:-gemini-flash-latest}"
    local env_var="${PROJECT_CONFIG[adk_env_var]:-GOOGLE_API_KEY}"
    local uses_litellm="${PROJECT_CONFIG[adk_uses_litellm]:-false}"

    # Friendly description for the .env comment and final warning.
    # provider_display: proper-cased name for human-facing strings.
    # article: grammatically correct "a"/"an".
    local provider_display="${provider}"
    local article="a"
    local key_url=""
    case "${provider}" in
        gemini)    provider_display="Gemini";    key_url="https://aistudio.google.com/app/apikey" ;;
        anthropic) provider_display="Anthropic"; article="an"; key_url="https://console.anthropic.com/settings/keys" ;;
        openai)    provider_display="OpenAI";    article="an"; key_url="https://platform.openai.com/api-keys" ;;
        *)         provider_display="${provider}"; key_url="your model provider's API key dashboard" ;;
    esac

    # Single-agent layout — agent files live directly under agents/:
    #   project_dir/
    #     agents/
    #       __init__.py
    #       agent.py
    #       .env                        ← per-agent env (ADK walks UP from here)
    #     tests/                        ← outside agents/ to keep the package clean
    #     pytest.ini
    #     requirements.txt
    #     venv/                         ← outside agents/
    # The agents/ directory is itself the agent Python package; root_agent is
    # defined in agents/agent.py. Add more agents later by promoting this
    # layout back into agents/<sub>/agent.py per-agent subdirs if needed.
    local agents_dir="${project_dir}/agents"
    mkdir -p "${agents_dir}"
    mkdir -p "${project_dir}/tests"

    # requirements.txt — google-adk[extensions] for LiteLLM-routed providers
    local adk_dep="google-adk"
    [ "${uses_litellm}" = "true" ] && adk_dep="google-adk[extensions]"
    cat > "${project_dir}/requirements.txt" << EOF
${adk_dep}
pytest
pytest-cov
pytest-asyncio
black
flake8
EOF

    # Agent package __init__.py — required for `adk run`/`adk web` discovery
    cat > "${agents_dir}/__init__.py" << 'EOF'
from . import agent  # noqa: F401  -- required for ADK agent discovery
EOF

    # agent.py — formatted black-clean. Two code shapes:
    #   - Gemini:        Agent(model="gemini-flash-latest", ...)
    #   - Other (via LiteLLM): Agent(model=LiteLlm("provider/model"), ...)
    if [ "${uses_litellm}" = "true" ]; then
        cat > "${agents_dir}/agent.py" << EOF
"""Root ADK agent. Edit this file to change the agent's behavior."""

from google.adk.agents.llm_agent import Agent
from google.adk.models.lite_llm import LiteLlm


def get_current_time(city: str) -> dict:
    """Returns the current time in a specified city."""
    return {"status": "success", "city": city, "time": "10:30 AM"}


root_agent = Agent(
    model=LiteLlm("${model_id}"),
    name="root_agent",
    description="Tells the current time in a specified city.",
    instruction=(
        "You are a helpful assistant that tells the current time in cities. "
        "Use the 'get_current_time' tool for this purpose."
    ),
    tools=[get_current_time],
)
EOF
    else
        cat > "${agents_dir}/agent.py" << EOF
"""Root ADK agent. Edit this file to change the agent's behavior."""

from google.adk.agents.llm_agent import Agent


def get_current_time(city: str) -> dict:
    """Returns the current time in a specified city."""
    return {"status": "success", "city": city, "time": "10:30 AM"}


root_agent = Agent(
    model="${model_id}",
    name="root_agent",
    description="Tells the current time in a specified city.",
    instruction=(
        "You are a helpful assistant that tells the current time in cities. "
        "Use the 'get_current_time' tool for this purpose."
    ),
    tools=[get_current_time],
)
EOF
    fi

    # .env — INSIDE the agent dir (canonical, what `adk create` writes).
    # ADK walks UP from this file to filesystem root looking for env vars.
    # GOOGLE_GENAI_USE_VERTEXAI=FALSE selects the public Gemini API path
    # (vs. Vertex AI, which would require GOOGLE_CLOUD_PROJECT instead).
    if [ "${provider}" = "gemini" ]; then
        cat > "${agents_dir}/.env" << EOF
# Get ${article} ${provider_display} API key from ${key_url}
GOOGLE_GENAI_USE_VERTEXAI=FALSE
${env_var}="REPLACE_WITH_YOUR_${provider_display^^}_API_KEY"
EOF
    else
        cat > "${agents_dir}/.env" << EOF
# Get ${article} ${provider_display} API key from ${key_url}
${env_var}="REPLACE_WITH_YOUR_${provider_display^^}_API_KEY"
EOF
    fi

    # tests/__init__.py
    touch "${project_dir}/tests/__init__.py"

    # tests/test_agent.py — hermetic: exercises the tool function and agent config,
    # does NOT call the model (no API key needed to run tests). The model
    # comparison uses _model_id() so it works for both plain-string and
    # LiteLlm-wrapped models (LiteLlm stores the model string at .model.model).
    # sys.path is extended with the project root so `from agents import agent`
    # resolves (agents/ is the agent Python package).
    cat > "${project_dir}/tests/test_agent.py" << EOF
"""Hermetic tests for the ADK agent. Does not call the model."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from agents import agent  # noqa: E402  -- import after sys.path setup


def _model_id(a):
    """Return the model string for both plain (Gemini) and LiteLlm-wrapped agents."""
    return getattr(a.model, "model", a.model)


def test_get_current_time_returns_success():
    result = agent.get_current_time("Tokyo")
    assert result["status"] == "success"
    assert result["city"] == "Tokyo"


def test_root_agent_is_configured():
    assert agent.root_agent is not None
    assert agent.root_agent.name == "root_agent"
    assert _model_id(agent.root_agent) == "${model_id}"


def test_root_agent_has_tool():
    tool_names = [
        getattr(t, "__name__", getattr(t, "name", "")) for t in agent.root_agent.tools
    ]
    assert "get_current_time" in tool_names
EOF

    cat > "${project_dir}/pytest.ini" << EOF
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = --cov=agents --cov-report=term-missing
EOF

    cat > "${project_dir}/.flake8" << 'EOF'
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = .venv,venv,__pycache__,.git
EOF

    # .gitignore — venv/ and .env are NOT committed (API key safety)
    cat > "${project_dir}/.gitignore" << 'EOF'
__pycache__/
*.pyc
*.pyo
.venv/
venv/
env/
.env
*.egg-info/
dist/
build/
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/
logs/
*.log
EOF

    print_info "Creating Python virtual environment..."
    (cd "${project_dir}" && python3 -m venv venv) \
        && print_success "venv created at venv/" \
        || print_warning "venv creation failed — run manually: cd ${project_dir} && python3 -m venv venv"

    print_info "Installing ${adk_dep} + test dependencies into venv (this may take a minute)..."
    (cd "${project_dir}" && venv/bin/pip install -r requirements.txt -q) \
        && print_success "pip install complete" \
        || print_warning "pip install failed — run manually: cd ${project_dir} && source venv/bin/activate && pip install -r requirements.txt"

    # Verify the `adk` CLI landed on PATH inside the venv
    if [ -x "${project_dir}/venv/bin/adk" ]; then
        print_success "adk CLI installed at venv/bin/adk"
    else
        print_warning "adk CLI not found at venv/bin/adk — google-adk may have failed to install"
    fi

    print_info "Running tests..."
    (cd "${project_dir}" && venv/bin/pytest tests/ -q 2>&1) \
        && print_success "Tests passed" \
        || print_warning "Tests failed — run manually: cd ${project_dir} && venv/bin/pytest tests/"

    print_success "Created Python ADK project structure (provider: ${provider}, model: ${model_id})"
    echo
    print_warning "REQUIRED: Edit ${project_dir}/agents/.env and replace REPLACE_WITH_YOUR_${provider_display^^}_API_KEY"
    print_warning "Get a key from ${key_url} (the agent will not run without it)"
    echo
    print_info "To run the agent:"
    print_info "  cd ${project_dir}"
    print_info "  venv/bin/adk run agents/                     # interactive CLI"
    print_info "  venv/bin/adk web .                            # web UI at http://localhost:8000"
}

create_ruby_project() {
    local project_dir="$1"
    local project_name="$2"
    # Convert hyphenated/underscored names to CamelCase for Ruby module names
    # e.g. "test-ruby" → "TestRuby", "my_app" → "MyApp"
    local ruby_module_name
    ruby_module_name="$(echo "${project_name}" | sed 's/[-_]\([a-zA-Z0-9]\)/\U\1/g; s/^\([a-zA-Z0-9]\)/\U\1/')"

    mkdir -p "${project_dir}/lib"
    mkdir -p "${project_dir}/spec"

    cat > "${project_dir}/Gemfile" << EOF
source 'https://rubygems.org'

gem 'rspec', '~> 3.13'
gem 'rubocop', '~> 1.65', require: false
gem 'simplecov', require: false
gem 'rack-test', group: :test
EOF

    cat > "${project_dir}/lib/${project_name}.rb" << EOF
# Ralph Loop Framework - Ruby Project
module ${ruby_module_name}
  def self.hello
    "Hello from Ralph Loop!"
  end
end
EOF

    cat > "${project_dir}/run.rb" << EOF
require_relative 'lib/${project_name}'

puts ${ruby_module_name}.hello
EOF

    cat > "${project_dir}/spec/spec_helper.rb" << 'EOF'
require 'simplecov'
SimpleCov.start

require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
EOF

    cat > "${project_dir}/spec/${project_name}_spec.rb" << EOF
require_relative '../lib/${project_name}'

RSpec.describe ${ruby_module_name} do
  it 'returns a greeting' do
    expect(${ruby_module_name}.hello).to eq('Hello from Ralph Loop!')
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
logs/
*.log
EOF

    print_info "Installing Ruby gems..."
    (cd "${project_dir}" && bundle install --quiet) && print_success "bundle install complete" || print_warning "bundle install failed — run manually: cd ${project_dir} && bundle install"

    print_success "Created Ruby project structure"
}

create_rails_project() {
    local project_dir="$1"
    local project_name="$2"
    local current_dir
    current_dir="$(pwd)"
    local parent_dir
    parent_dir="$(dirname "${current_dir}")"

    # Check runtime availability
    if ! command -v ruby > /dev/null 2>&1; then
        print_warning "ruby not found — creating placeholder Rails structure"
        mkdir -p "${project_dir}/app/controllers" "${project_dir}/app/models" \
                 "${project_dir}/app/views" "${project_dir}/config"
        cat > "${project_dir}/Gemfile" << 'EOF'
source 'https://rubygems.org'

gem 'rails'
gem 'sqlite3'
EOF
        print_info "Install Ruby then run: cd ${project_dir} && gem install rails && rails new . --force --database=sqlite3"
        return
    fi

    # Ensure Rails 7+ is available — Rails 6.x is incompatible with Ruby 3.2+
    local rails_bin
    rails_bin=$(command -v rails 2>/dev/null || true)
    local rails_major=0
    [[ -n "${rails_bin}" ]] && rails_major=$(rails --version 2>/dev/null | grep -oE '[0-9]+' | head -1)

    if [[ "${rails_major:-0}" -lt 7 ]]; then
        if [[ "${rails_major:-0}" -gt 0 ]]; then
            print_info "System Rails v${rails_major} is incompatible with Ruby 3.2+ (need Rails 7+), installing latest..."
        else
            print_info "Rails not found — installing latest..."
        fi
        if gem install rails --user-install --no-document -q 2>/dev/null; then
            local user_rails
            user_rails="$(ruby -e 'puts File.join(Gem.user_dir, "bin", "rails")' 2>/dev/null)"
            [[ -x "${user_rails}" ]] && rails_bin="${user_rails}" || rails_bin="rails"
            print_success "Rails installed: $(${rails_bin} --version 2>/dev/null)"
        else
            print_warning "gem install rails failed — install manually: gem install rails --user-install"
            return
        fi
    fi

    local test_fw="${PROJECT_CONFIG[test_framework]:-minitest}"
    local api_only="${PROJECT_CONFIG[rails_api]:-no}"

    local rails_flags="--database=sqlite3 --skip-bundle --skip-git"
    [ "${api_only}" = "yes" ] && rails_flags="${rails_flags} --api"
    [ "${test_fw}" = "rspec" ] && rails_flags="${rails_flags} --skip-test"

    print_info "Scaffolding Rails project (this may take a moment)..."
    # rails new creates its own dir — remove the pre-created empty dir first, then scaffold from parent
    if (
        cd "${parent_dir}" || exit 1
        rm -rf "${project_name}" 2>/dev/null || true
        # shellcheck disable=SC2086
        "${rails_bin}" new "${project_name}" ${rails_flags}
    ); then
        # Re-enter project dir by absolute path (new inode after rm + recreate)
        cd "${current_dir}" || { print_warning "Could not cd into ${current_dir}"; return 1; }
        print_success "Rails project scaffolded"
    else
        mkdir -p "${current_dir}"
        cd "${current_dir}" 2>/dev/null || true
        print_warning "rails new failed — run manually: cd ${parent_dir} && rails new ${project_name} --database=sqlite3 --skip-git"
        return
    fi

    # Configure Bundler to install gems locally to avoid needing system-level write perms
    (cd "${current_dir}" && bundle config set --local path 'vendor/bundle' 2>/dev/null) || true

    # Ensure libyaml-dev is available — required to compile the psych gem (YAML parser)
    # Rails 8 requires psych 5.x which must be compiled against libyaml headers.
    if command -v dpkg >/dev/null 2>&1 && ! dpkg -l libyaml-dev 2>/dev/null | grep -q '^ii'; then
        print_info "Installing libyaml-dev (required to compile Rails psych gem)..."
        if sudo apt-get install -y libyaml-dev -qq 2>/dev/null; then
            print_success "libyaml-dev installed"
        else
            print_warning "libyaml-dev is not installed and could not be auto-installed."
            print_warning "bundle install may fail. Fix with: sudo apt-get install libyaml-dev"
            print_warning "Then re-run: cd ${current_dir} && bundle install"
        fi
    fi

    print_info "Installing gems (to vendor/bundle)..."
    (cd "${current_dir}" && bundle install --quiet) \
        && print_success "Gems installed" \
        || print_warning "bundle install failed — run manually: cd ${project_dir} && bundle install"

    # Ensure vendor/bundle is gitignored
    if ! grep -q 'vendor/bundle' "${current_dir}/.gitignore" 2>/dev/null; then
        echo "vendor/bundle/" >> "${current_dir}/.gitignore"
    fi

    # Add simplecov to Gemfile (works with both minitest and rspec)
    cat >> "${current_dir}/Gemfile" << 'EOF'

group :test do
  gem 'simplecov', require: false
end
EOF

    # Add RSpec if chosen
    if [ "${test_fw}" = "rspec" ]; then
        # Append rspec-rails to Gemfile development/test group
        cat >> "${current_dir}/Gemfile" << 'EOF'

group :development, :test do
  gem 'rspec-rails'
end
EOF
        (cd "${current_dir}" && bundle install --quiet \
            && bundle exec rails generate rspec:install) \
            && print_success "RSpec configured" \
            || print_warning "RSpec setup failed — run: bundle install && rails generate rspec:install"

        # Prepend simplecov config to spec/spec_helper.rb
        if [ -f "${current_dir}/spec/spec_helper.rb" ]; then
            python3 -c "
content = open('spec/spec_helper.rb').read()
prepend = \"require 'simplecov'\nSimpleCov.start 'rails'\n\n\"
if 'simplecov' not in content:
    open('spec/spec_helper.rb', 'w').write(prepend + content)
" 2>/dev/null && print_success "SimpleCov added to spec_helper.rb" || true
        fi
    else
        # minitest: prepend simplecov to test/test_helper.rb
        (cd "${current_dir}" && bundle install --quiet) && true || true
        if [ -f "${current_dir}/test/test_helper.rb" ]; then
            python3 -c "
content = open('test/test_helper.rb').read()
prepend = \"require 'simplecov'\nSimpleCov.start 'rails'\n\n\"
if 'simplecov' not in content:
    open('test/test_helper.rb', 'w').write(prepend + content)
" 2>/dev/null && print_success "SimpleCov added to test_helper.rb" || true
        fi
    fi

    # Add coverage/ to Rails .gitignore
    if ! grep -q '^coverage/' "${current_dir}/.gitignore" 2>/dev/null; then
        echo "coverage/" >> "${current_dir}/.gitignore"
    fi

    print_success "Created Rails project structure"
}

create_dotnet_project() {
    local project_dir="$1"
    local project_name="$2"
    local template="${PROJECT_CONFIG[dotnet_template]:-webapi}"

    # Check runtime availability
    if ! command -v dotnet > /dev/null 2>&1; then
        print_warning "dotnet CLI not found — creating placeholder structure"
        mkdir -p "${project_dir}/src"
        cat > "${project_dir}/${project_name}.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
  </PropertyGroup>
</Project>
EOF
        print_info "Install .NET SDK: https://dotnet.microsoft.com/download"
        print_info "Then run: cd ${project_dir} && dotnet new ${template} --force"
        return
    fi

    print_info "Scaffolding .NET ${template} project..."
    # dotnet new creates files IN the current directory (no subdirectory)
    (cd "${project_dir}" && dotnet new "${template}" \
        --name "${project_name}" \
        --output . \
        --force \
        --no-restore) \
        && print_success ".NET project scaffolded" \
        || { print_warning "dotnet new failed — run: cd ${project_dir} && dotnet new ${template} --name ${project_name} --output ."; return; }

    # Add .gitignore via dotnet template
    (cd "${project_dir}" && dotnet new gitignore --force 2>/dev/null) || true

    # Create sibling xUnit test project
    print_info "Creating xUnit test project..."
    local sibling_test_name="${project_name}.Tests"
    (cd "$(dirname "${project_dir}")" && dotnet new xunit \
        --name "${sibling_test_name}" \
        --output "${sibling_test_name}" \
        --no-restore 2>/dev/null) \
        && print_success "Test project: ../${sibling_test_name}" \
        || print_warning "xUnit test project creation failed — run: dotnet new xunit --name ${sibling_test_name}"

    # Add Microsoft.AspNetCore.Mvc.Testing for integration tests (webapi / mvc / blazor server only)
    local test_proj_dir
    test_proj_dir="$(dirname "${project_dir}")/${project_name}.Tests"
    if [[ "${template}" != "blazorwasm" ]] && [ -d "${test_proj_dir}" ]; then
        print_info "Adding Microsoft.AspNetCore.Mvc.Testing for integration tests..."
        (cd "${test_proj_dir}" && dotnet add package Microsoft.AspNetCore.Mvc.Testing --verbosity quiet 2>/dev/null) \
            && print_success "Microsoft.AspNetCore.Mvc.Testing added" \
            || print_warning "Could not add Mvc.Testing — run: cd ${test_proj_dir} && dotnet add package Microsoft.AspNetCore.Mvc.Testing"
    fi

    # Restore packages
    print_info "Restoring NuGet packages..."
    (cd "${project_dir}" && dotnet restore --verbosity quiet) \
        && print_success "NuGet packages restored" \
        || print_warning "dotnet restore failed — run: cd ${project_dir} && dotnet restore"

    # Install ReportGenerator as a local dotnet tool for HTML coverage reports
    print_info "Installing ReportGenerator (coverage HTML reports)..."
    (cd "${project_dir}" && dotnet new tool-manifest --force 2>/dev/null) || true
    (cd "${project_dir}" && dotnet tool install dotnet-reportgenerator-globaltool --verbosity quiet 2>/dev/null) \
        && print_success "ReportGenerator installed (local tool)" \
        || print_warning "ReportGenerator install failed — run: cd ${project_dir} && dotnet tool install dotnet-reportgenerator-globaltool"

    # Ensure coverage output dirs are gitignored (dotnet new gitignore covers TestResults/ but not coverage-report/)
    if ! grep -q '^coverage-report/' "${project_dir}/.gitignore" 2>/dev/null; then
        echo "coverage-report/" >> "${project_dir}/.gitignore"
    fi
    if ! grep -q 'TestResults/' "${project_dir}/.gitignore" 2>/dev/null; then
        echo "TestResults/" >> "${project_dir}/.gitignore"
    fi

    print_success "Created .NET ${template} project structure"
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

    # Track generated project names for ralph-loop metadata
    local generated_projects_json=""
    local project_sep=""

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
                generated_projects_json+="${project_sep}{\"name\":\"${fw}-app\",\"type\":\"frontend\",\"framework\":\"${fw}\"}"
                project_sep=","
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
                generated_projects_json+="${project_sep}{\"name\":\"${fw}-api\",\"type\":\"backend\",\"framework\":\"${fw}\"}"
                project_sep=","
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
                    print_info "Generating python-app..."
                    npx nx generate @nxlv/python:poetry-project python-app --no-interactive 2>&1 | tail -5 || true
                    print_success "Generated python-app"
                    generated_projects_json+="${project_sep}{\"name\":\"python-app\",\"type\":\"community\",\"framework\":\"python\"}"
                    project_sep=","
                    ;;
                go)
                    print_info "Adding community plugin: @nx-go/nx-go"
                    npx nx add @nx-go/nx-go --no-interactive 2>&1 | tail -3 || true
                    print_info "Generating go-app..."
                    npx nx generate @nx-go/nx-go:app go-app --no-interactive 2>&1 | tail -5 || true
                    print_success "Generated go-app"
                    generated_projects_json+="${project_sep}{\"name\":\"go-app\",\"type\":\"community\",\"framework\":\"go\"}"
                    project_sep=","
                    ;;
                terraform)
                    if ! command -v terraform > /dev/null 2>&1; then
                        print_warning "terraform CLI not found — install from https://developer.hashicorp.com/terraform/install"
                        print_warning "Continuing with plugin install; run 'terraform init' manually once CLI is available"
                    fi
                    print_info "Adding community plugin: @nx-extend/terraform"
                    npx nx add @nx-extend/terraform --no-interactive 2>&1 | tail -3 || true
                    print_info "Generating terraform-infra project..."
                    npx nx generate @nx-extend/terraform:init terraform-infra --no-interactive 2>&1 | tail -5 || true
                    print_success "Generated terraform-infra"
                    generated_projects_json+="${project_sep}{\"name\":\"terraform-infra\",\"type\":\"community\",\"framework\":\"terraform\"}"
                    project_sep=","
                    ;;
                *)
                    print_warning "Unknown community plugin: ${plugin}, skipping"
                    ;;
            esac
        done
    fi

    # Write Ralph workspace metadata so Ralph skills know this is an NX workspace
    # Stored in ralph/ (git-tracked) so it survives archive/cleanup of ralph/.ralph/
    # Note: create_ralph_structure() hasn't run yet for NX, so create ralph/ first
    mkdir -p "ralph"
    cat > "ralph/nx-workspace.json" << EOF
{
  "nx_workspace": true,
  "workspace_type": "${ws_type}",
  "package_manager": "${pm}",
  "unit_test": "${unit_test}",
  "e2e": "${e2e}",
  "frontends": "${frontends}",
  "backends": "${backends}",
  "community_plugins": "${community}",
  "projects": [${generated_projects_json}]
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
                    typescript|javascript|angular|react|nextjs|express|python|flask|reflex|adk-python|go|adk-go|adk-ts|adk-java|dotnet|rust|ruby|rails|actix|rocket|nx) ;;
                    *)
                        print_error "Unknown project type: '${project_type}'"
                        print_info "Valid types: typescript, javascript, angular, react, nextjs, express, python, flask, reflex, adk-python, go, adk-go, adk-ts, adk-java, dotnet, rust, ruby, rails, actix, rocket, nx"
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
