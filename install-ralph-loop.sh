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

# Global Claude skills directory
CLAUDE_GLOBAL_SKILLS="${HOME}/.claude/skills"

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
    --install-global            Install skills globally to ~/.claude/skills/
    --new-project <name>        Create new project with Ralph framework
    --type <language>           Project type (typescript, python, go, rust, c, cpp)
    --init                      Add Ralph framework to existing project (current directory)
    --backup-dir <path>         Custom backup directory (default: .ralph-backups/)
    --help                      Show this help message

EXAMPLES:
    # Install skills globally only
    $0 --install-global

    # Create new TypeScript project
    $0 --install-global --new-project my-app --type typescript

    # Initialize existing project
    cd /path/to/project
    $0 --install-global --init

    # Create project and auto-detect type
    $0 --install-global --new-project my-app

EOF
}

#==============================================================================
# Installation Functions
#==============================================================================

install_global_skills() {
    print_info "Installing Ralph Loop skills globally..."

    # Create global skills directory if it doesn't exist
    if [ ! -d "${CLAUDE_GLOBAL_SKILLS}" ]; then
        mkdir -p "${CLAUDE_GLOBAL_SKILLS}"
        print_success "Created global skills directory: ${CLAUDE_GLOBAL_SKILLS}"
    fi

    # Copy all Ralph skills
    local skills_source="${SCRIPT_DIR}/.claude/skills"
    if [ ! -d "${skills_source}" ]; then
        print_error "Skills directory not found: ${skills_source}"
        exit 1
    fi

    local installed_count=0
    local updated_count=0
    local skipped_count=0

    for skill_file in "${skills_source}"/*.md; do
        if [ -f "${skill_file}" ]; then
            local skill_name=$(basename "${skill_file}")
            local target="${CLAUDE_GLOBAL_SKILLS}/${skill_name}"

            # Check if target exists and compare modification times
            if [ -f "${target}" ]; then
                # Only update if source is newer
                if [ "${skill_file}" -nt "${target}" ]; then
                    cp "${skill_file}" "${target}"
                    print_success "Updated: ${skill_name}"
                    updated_count=$((updated_count + 1))
                else
                    # Target is up to date, skip
                    skipped_count=$((skipped_count + 1))
                fi
            else
                # Target doesn't exist, install new
                cp "${skill_file}" "${target}"
                print_success "Installed: ${skill_name}"
                installed_count=$((installed_count + 1))
            fi
        fi
    done

    # Print summary
    local total=$((installed_count + updated_count + skipped_count))
    if [ ${installed_count} -gt 0 ]; then
        print_success "Installed ${installed_count} new skill(s)"
    fi
    if [ ${updated_count} -gt 0 ]; then
        print_success "Updated ${updated_count} skill(s)"
    fi
    if [ ${skipped_count} -gt 0 ]; then
        print_info "${skipped_count} skill(s) already up to date"
    fi
    print_success "Total: ${total} Ralph Loop skills in ${CLAUDE_GLOBAL_SKILLS}"
    echo
}

#==============================================================================
# Project Type Detection
#==============================================================================

detect_project_type() {
    local project_dir="$1"

    # TypeScript/JavaScript
    if [ -f "${project_dir}/package.json" ]; then
        if grep -q '"typescript"' "${project_dir}/package.json" 2>/dev/null; then
            echo "typescript"
        else
            echo "javascript"
        fi
        return
    fi

    # Python
    if [ -f "${project_dir}/setup.py" ] || [ -f "${project_dir}/pyproject.toml" ] || [ -f "${project_dir}/requirements.txt" ]; then
        echo "python"
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

    # C/C++
    if [ -f "${project_dir}/CMakeLists.txt" ] || [ -f "${project_dir}/Makefile" ]; then
        if ls "${project_dir}"/*.cpp "${project_dir}"/*.hpp 2>/dev/null | grep -q .; then
            echo "cpp"
        else
            echo "c"
        fi
        return
    fi

    echo "unknown"
}

detect_tools() {
    local project_type="$1"
    local project_dir="$2"

    case "${project_type}" in
        typescript|javascript)
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

        python)
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

        go)
            echo "test_framework=testing"
            echo "package_manager=go"
            ;;

        rust)
            echo "test_framework=cargo-test"
            echo "package_manager=cargo"
            ;;

        c|cpp)
            if [ -f "${project_dir}/CMakeLists.txt" ]; then
                echo "build_system=cmake"
            else
                echo "build_system=make"
            fi

            # Test framework
            if grep -q "gtest" "${project_dir}/CMakeLists.txt" 2>/dev/null; then
                echo "test_framework=gtest"
            elif grep -q "catch2" "${project_dir}/CMakeLists.txt" 2>/dev/null; then
                echo "test_framework=catch2"
            else
                echo "test_framework=unknown"
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
        typescript)
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

        c|cpp)
            # Build system
            local default_build=$(echo "${detected_tools}" | grep "build_system=" | cut -d= -f2)
            if [ -z "${default_build}" ] || [ "${default_build}" = "unknown" ]; then
                default_build="cmake"
            fi

            echo "Build system? (cmake/make/meson) [${default_build}]:"
            read -r build_choice
            PROJECT_CONFIG[build_system]="${build_choice:-$default_build}"

            # Test framework
            local default_test=$(echo "${detected_tools}" | grep "test_framework=" | cut -d= -f2)
            if [ -z "${default_test}" ] || [ "${default_test}" = "unknown" ]; then
                default_test="gtest"
            fi

            echo "Test framework? (gtest/catch2/doctest) [${default_test}]:"
            read -r test_choice
            PROJECT_CONFIG[test_framework]="${test_choice:-$default_test}"
            ;;
    esac

    # Common questions for all types
    echo
    echo "Include browser testing setup? (yes/no) [yes]:"
    read -r browser_choice
    PROJECT_CONFIG[browser_testing]="${browser_choice:-yes}"

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

    # Create directories
    mkdir -p "${project_dir}/.claude/templates"
    mkdir -p "${project_dir}/.claude/feedback-configs"
    mkdir -p "${project_dir}/specs/prds"
    mkdir -p "${project_dir}/archive"
    mkdir -p "${project_dir}/docs"
    mkdir -p "${project_dir}/tests/browser"
    mkdir -p "${project_dir}/feedback"

    # Copy template files
    cp "${SCRIPT_DIR}/.ralph-state-template.json" "${project_dir}/"
    cp "${SCRIPT_DIR}/.ralph-story-template.json" "${project_dir}/"
    cp "${SCRIPT_DIR}/.ralph-quota-config.json" "${project_dir}/"

    # Copy templates
    cp "${SCRIPT_DIR}/.claude/templates/prd-template.md" "${project_dir}/.claude/templates/"
    cp "${SCRIPT_DIR}/.claude/templates/openspec-template.yaml" "${project_dir}/.claude/templates/"

    # Copy documentation
    for doc in "${SCRIPT_DIR}"/docs/*.md; do
        if [ -f "${doc}" ]; then
            cp "${doc}" "${project_dir}/docs/"
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
2. **Review Spec**: Check `specs/prds/` for generated specification
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

Ralph Loop maintains state in `.ralph/` directory:
- `state.json` - Current run state and quota
- `stories.json` - All stories with dependencies
- `tasks.json` - Claude Task mappings
- `phases.json` - Execution phases

**Never manually edit state files** - use Ralph commands.

## Archive Structure

After completion, find archives in `archive/<run-id>/`:
- `summary.md` - Run overview and results
- `spec/` - All spec versions
- `code/` - Final implementation
- `tests/` - All test results
- `git/` - Commits and diffs
- `artifacts/` - Task outputs and logs
- `metrics/` - Quota usage and timing

## Configuration

### Quota Limits
Edit `.ralph-quota-config.json`:
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

- `docs/QUICKSTART.md` - Getting started guide
- `docs/COMPLETE-WORKFLOW.md` - Detailed workflow with examples
- `docs/QUOTA-MANAGEMENT.md` - Quota strategies
- `docs/SPEC-MODIFICATIONS.md` - Modifying specs during runs

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
.ralph/

# Ralph templates are tracked (they're templates, not runtime state)
!.ralph-state-template.json
!.ralph-story-template.json
!.ralph-quota-config.json

# Checkpoints (can be regenerated)
.claude/checkpoints/

# Feedback results (can be regenerated)
feedback/
!feedback/.gitkeep

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
- \`docs/QUICKSTART.md\` - Quick start guide
- \`docs/COMPLETE-WORKFLOW.md\` - Complete workflow examples
- \`docs/QUOTA-MANAGEMENT.md\` - Quota management strategies

## Project Structure

\`\`\`
${project_name}/
├── specs/prds/          # Product requirement documents
├── archive/             # Completed runs
├── .ralph/              # Runtime state (not tracked)
├── .claude/             # Claude Code configuration
├── docs/                # Ralph Loop documentation
└── tests/               # Test files
\`\`\`

## License

[Your License Here]
EOF

    print_success "Created README.md"
}

initialize_existing_project() {
    local project_dir="$1"

    print_info "Initializing Ralph Loop in existing project..."
    echo

    # Detect project type
    local project_type=$(detect_project_type "${project_dir}")
    print_info "Detected project type: ${project_type}"

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

    # Check if directory already exists
    if [ -d "${project_dir}" ]; then
        print_error "Directory already exists: ${project_dir}"
        echo "Use --init to add Ralph Loop to existing project"
        exit 1
    fi

    # Create project directory
    mkdir -p "${project_dir}"
    cd "${project_dir}"

    # Initialize git if not already a repo
    if [ ! -d ".git" ]; then
        git init
        print_success "Initialized git repository"
    fi

    # Detect project type if not specified
    if [ -z "${project_type}" ] || [ "${project_type}" = "unknown" ]; then
        echo "Project type? (typescript/python/go/rust/c/cpp):"
        read -r type_choice
        project_type="${type_choice:-typescript}"
    fi

    print_info "Project type: ${project_type}"

    # Ask configuration questions
    declare -A PROJECT_CONFIG
    ask_project_questions "${project_type}" ""

    # Create basic project structure based on type
    case "${project_type}" in
        typescript)
            create_typescript_project "."
            ;;
        python)
            create_python_project "."
            ;;
        go)
            create_go_project "." "${project_name}"
            ;;
        rust)
            create_rust_project "." "${project_name}"
            ;;
        c|cpp)
            create_c_project "." "${project_type}"
            ;;
    esac

    # Create Ralph structure
    create_ralph_structure "."

    # Create configuration files
    create_claude_md "." "${project_type}"
    create_gitignore "."
    create_readme "." "${project_name}" "${project_type}"

    # Initial git commit
    git add .
    git commit -m "Initial commit with Ralph Loop Framework"

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

    # package.json
    cat > "${project_dir}/package.json" << 'EOF'
{
  "name": "project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "jest",
    "lint": "eslint src --ext ts,tsx"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "vite": "^5.0.0"
  }
}
EOF

    # tsconfig.json
    cat > "${project_dir}/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM"],
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"],
  "exclude": ["node_modules"]
}
EOF

    # src/index.ts
    cat > "${project_dir}/src/index.ts" << 'EOF'
// Ralph Loop Framework - TypeScript Project
console.log('Hello from Ralph Loop!');
EOF

    print_success "Created TypeScript project structure"
}

create_python_project() {
    local project_dir="$1"

    # Create basic Python structure
    mkdir -p "${project_dir}/src"
    mkdir -p "${project_dir}/tests"

    # requirements.txt
    cat > "${project_dir}/requirements.txt" << 'EOF'
# Ralph Loop Framework - Python Project
pytest>=7.0.0
pytest-cov>=4.0.0
black>=23.0.0
flake8>=6.0.0
mypy>=1.0.0
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

def main():
    print("Hello from Ralph Loop!")

if __name__ == "__main__":
    main()
EOF

    # pytest.ini
    cat > "${project_dir}/pytest.ini" << 'EOF'
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
EOF

    print_success "Created Python project structure"
}

create_go_project() {
    local project_dir="$1"
    local project_name="$2"

    # go.mod
    cat > "${project_dir}/go.mod" << EOF
module ${project_name}

go 1.21
EOF

    # main.go
    cat > "${project_dir}/main.go" << 'EOF'
package main

import "fmt"

func main() {
	fmt.Println("Hello from Ralph Loop!")
}
EOF

    # Create test directory
    mkdir -p "${project_dir}/internal"

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

    # src/main.rs
    cat > "${project_dir}/src/main.rs" << 'EOF'
fn main() {
    println!("Hello from Ralph Loop!");
}
EOF

    print_success "Created Rust project structure"
}

create_c_project() {
    local project_dir="$1"
    local project_type="$2"

    # Create directories
    mkdir -p "${project_dir}/src"
    mkdir -p "${project_dir}/include"
    mkdir -p "${project_dir}/tests"

    # CMakeLists.txt
    cat > "${project_dir}/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.15)
project(RalphLoopProject)

set(CMAKE_CXX_STANDARD 17)

add_subdirectory(src)
add_subdirectory(tests)
EOF

    # src/CMakeLists.txt
    mkdir -p "${project_dir}/src"
    cat > "${project_dir}/src/CMakeLists.txt" << 'EOF'
add_executable(main main.cpp)
target_include_directories(main PRIVATE ${CMAKE_SOURCE_DIR}/include)
EOF

    # src/main.cpp or main.c
    if [ "${project_type}" = "cpp" ]; then
        cat > "${project_dir}/src/main.cpp" << 'EOF'
#include <iostream>

int main() {
    std::cout << "Hello from Ralph Loop!" << std::endl;
    return 0;
}
EOF
    else
        cat > "${project_dir}/src/main.c" << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from Ralph Loop!\n");
    return 0;
}
EOF
    fi

    print_success "Created C/C++ project structure"
}

#==============================================================================
# Main Script
#==============================================================================

main() {
    local install_global=false
    local new_project=""
    local project_type="unknown"
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

    # Install global skills if requested
    if [ "${install_global}" = true ]; then
        install_global_skills
    fi

    # Create new project if requested
    if [ -n "${new_project}" ]; then
        create_new_project "${new_project}" "${project_type}"
    fi

    # Initialize existing project if requested
    if [ "${init_existing}" = true ]; then
        if [ -n "${new_project}" ]; then
            print_error "Cannot use --new-project and --init together"
            exit 1
        fi
        initialize_existing_project "$(pwd)"
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
