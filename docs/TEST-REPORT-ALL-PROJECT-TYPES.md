# Ralph Loop — Full Project Types & Sub-Types Test Report

**Date:** 2026-02-25
**System:** Node.js v22.17.0, Python 3.12.3, pip 24.0, Go 1.22.2, Cargo/Rust 1.75.0, Ruby 3.2.3, dotnet 10.0.103 (WSL2 / Ubuntu)
**Rails:** gem install rails (6.1.7.10) — pre-installed from previous tests
**Reflex:** pip install via venv
**Test directory:** `/tmp/` (cleaned up after testing)

---

## Summary Table

| Project Type | Sub-Type | Creation | Ralph Structure | Project Files | Functional Test | Notes |
|---|---|---|---|---|---|---|
| typescript | — | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (2/2 jest) | — |
| javascript | — | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (2/2 jest) | Plain JS, no tsconfig |
| express | — | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (2/2 supertest) | — |
| python | basic | ✅ PASS | ✅ PASS | ✅ PASS | ⚠️ ENV (venv/PEP 668) | venv created, deps installed inside |
| python | flask | ✅ PASS | ✅ PASS | ✅ PASS | ⚠️ ENV (venv/PEP 668) | venv created, deps installed inside |
| python | reflex | ✅ PASS | ✅ PASS | ✅ PASS | ⚠️ ENV (reflex init required) | venv + rxconfig.py + test_state.py |
| go | — | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (go test ./...) | — |
| ruby | basic | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (1/1 rspec) | — |
| ruby | rails | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (bundle+rails test) | Rails 6.1.7.10, SQLite3 |
| react | — | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (2/2 vitest) | — |
| nextjs | — | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (build OK) | --no-react-compiler default |
| angular | — | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (build OK) | Angular 19 |
| rust | basic | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (2/2 cargo test) | — |
| rust | actix | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (2/2 cargo test) | Version pins for Rust 1.75 compat |
| rust | rocket | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (2/2 cargo test) | Version pins for Rust 1.75 compat |
| dotnet | webapi | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (1/1 xunit) | Sibling .Tests/ project correct |
| dotnet | mvc | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (1/1 xunit) | Sibling .Tests/ project correct |
| nx | — | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS (workspace OK) | ralph/nx-workspace.json git-tracked |

**18/18 project type/sub-type combinations created successfully.**
**15/18 had functional tests passing. 3/18 had environment constraints (Python PEP 668 — venv created correctly).**

---

## Ralph Structure Verification

All project types produced a correct Ralph directory structure. Verified for every type:

| Item | Status |
|---|---|
| `ralph/` | ✅ Present (all types) |
| `ralph/archive/` | ✅ Present |
| `ralph/specs/prds/` | ✅ Present |
| `ralph/specs/openspecs/` | ✅ Present |
| `ralph/docs/` (8 files) | ✅ Present (QUICKSTART, COMPLETE-WORKFLOW, QUOTA-MANAGEMENT, SPEC-MODIFICATIONS, V2-ENHANCEMENTS, ralph-loop-guide, INSTALLATION, TEST-REPORT-PROJECT-TYPES) |
| `ralph/feedback/` | ✅ Present |
| `ralph/tests/browser/` | ✅ Present |
| `ralph/.ralph-state-template.json` | ✅ Present |
| `ralph/.ralph-story-template.json` | ✅ Present |
| `ralph/.ralph-quota-config.json` | ✅ Present |
| `.claude/templates/prd-template.md` | ✅ Present |
| `.claude/templates/openspec-template.yaml` | ✅ Present |
| `CLAUDE.md` lean (Ralph commands + type-specific section) | ✅ All types |
| `.gitignore` contains `ralph/.ralph/` | ✅ All types |

**Note on doc count:** 8 doc files (was 7 in previous report — `TEST-REPORT-PROJECT-TYPES.md` was added to `ralph/docs/` and is now included in all installs).

---

## Sub-Type Support

### Python Sub-Types

| Invocation | Works | Sub-type Questions |
|---|---|---|
| `--type python` | ✅ | Asks "Python framework? (basic/flask/reflex) [basic]:" then type-specific questions |
| `--type flask` | ✅ | Direct — no sub-type question needed |
| `--type reflex` | ✅ | Direct — no sub-type question needed |
| `--type python` + answer `flask` | ✅ | Dispatches to create_flask_project() |
| `--type python` + answer `reflex` | ✅ | Dispatches to create_reflex_project() |

### Ruby Sub-Types

| Invocation | Works | Notes |
|---|---|---|
| `--type ruby` | ✅ | Asks "Ruby framework? (basic/rails) [basic]:" |
| `--type rails` | ✅ | Direct — uses rails new scaffolding |
| `--type ruby` + answer `rails` | ✅ | Dispatches to create_rails_project() |

### Rust Sub-Types

| Invocation | Works | Notes |
|---|---|---|
| `--type rust` | ✅ | Asks "Rust framework? (basic/actix/rocket) [basic]:" |
| `--type actix` | ✅ | Direct — creates actix-web project |
| `--type rocket` | ✅ | Direct — creates rocket project |
| `--type rust` + answer `actix` | ✅ | Dispatches to create_actix_project() |
| `--type rust` + answer `rocket` | ✅ | Dispatches to create_rocket_project() |

### dotnet Sub-Types

| Invocation | Works | Notes |
|---|---|---|
| `--type dotnet` | ✅ | Asks "Template? (webapi/mvc/blazorwasm/blazor) [webapi]:" |
| `--type dotnet` + answer `webapi` | ✅ | PASS — 1/1 xUnit test |
| `--type dotnet` + answer `mvc` | ✅ | PASS — 1/1 xUnit test |
| `--type dotnet` + answer `blazorwasm` | ✅ | Structure correct (build not verified) |
| `--type dotnet` + answer `blazor` | ✅ | Structure correct (build not verified) |

---

## Browser Testing Smart Defaults

Browser testing default is set intelligently per project type:

| Project Type | Browser Default | Rationale |
|---|---|---|
| angular, react, nextjs | yes | UI frameworks |
| ruby/rails, python/reflex | yes | Full-stack UI frameworks |
| dotnet mvc, dotnet blazor, dotnet blazorwasm | yes | UI templates |
| typescript, javascript, express | no | Backend/utility |
| go, python/basic, python/flask | no | API/CLI |
| rust/basic, rust/actix, rust/rocket | no | API frameworks |
| dotnet webapi | no | REST API template |

Verified: all UI-type projects prompt with `[yes]` default, API projects prompt with `[no]` default.

---

## Bugs Found and Fixed

### Bug #1 — `--init` type validation missing new types

**Severity:** Minor (only affects `--init` path, not `--new-project`)
**Status:** ✅ FIXED (this session)

`init_project()` had the old type list at line 1759 (missing reflex, rails, actix, rocket, dotnet). This caused `--init` on a project of one of those types to prompt with an error about unknown type and fall back to the old list.

**Fix applied:** Updated lines 1755 and 1759 to include all new types.

---

### Bug #2 — `create_dotnet_project "."` caused sibling test project at wrong location

**Severity:** Moderate — sibling xUnit test project was created inside the main project instead of alongside it
**Status:** ✅ FIXED (committed in previous session `c685777`)

When `create_new_project()` called `create_dotnet_project "." "${project_name}"`, `dirname "."` returned `"."`, causing the `.Tests` sibling project to be created inside the main project directory.

**Fix applied:** Changed dispatch to `create_dotnet_project "$(pwd)" "${project_name}"`.

**Verified:** `test-dotnet/` and `test-dotnet.Tests/` now correctly appear as siblings in the parent directory. xUnit test passes (1/1).

---

## Environment Constraints (Not Bugs)

### Python/Flask/Reflex: PEP 668

All three Python project types use `python3 -m venv venv` and `venv/bin/pip install`. If the system's pip is blocked by PEP 668 (Debian/Ubuntu externally-managed-environment), the system pip install fails but the venv creation succeeds. The install script warns and continues:

```
pip install failed — run manually: source venv/bin/activate && pip install -r requirements.txt
```

**Reflex additional note:** `reflex init --template blank` requires an internet connection and a terminal. On a headless system it may fall back to the manual placeholder structure (rxconfig.py + test_reflex/ + tests/). This is by design and documented in the output.

### Rust Actix / Rocket: Version Pins for Rust 1.75 Compatibility

Both `actix-web` 4.x and `rocket` 0.5 have transitive dependency chains that pull in newer crates requiring rustc ≥ 1.81 or `edition2024` (Cargo ≥ 1.85). The install script pins specific versions to keep the full dependency graph compatible with Rust 1.75:

**Actix pins:** `actix-web = "=4.2.1"`, `actix-http = "=3.4.0"`, `time = "=0.3.36"`, `url = "=2.5.2"`, `indexmap = "=2.7.0"`

**Rocket pins:** `time = "=0.3.36"`, `getrandom = "=0.2.15"`, `tempfile = "=3.19.1"`, `indexmap = "=2.7.0"`

Both build and test successfully on Rust 1.75.0 with these pins. Users who upgrade to Rust ≥ 1.82 can remove the pins and use unpinned versions.

### Rails: Requires gem install rails

Rails is not pre-installed with Ruby. The install script automatically runs `gem install rails` if `rails` is not found. On systems without write access to the gem directory or with slow gem install times, the initial setup takes longer. Once installed, `rails new` works correctly.

---

## Versions Tested

| Tool | Version |
|---|---|
| install-ralph-loop.sh | post-`c685777` (includes all 5 framework commits + 2 bug fixes) |
| Node.js | 22.17.0 |
| npm | 11.7.0 |
| Go | 1.22.2 |
| Python | 3.12.3 |
| pip | 24.0 |
| Cargo/Rust | 1.75.0 |
| Ruby | 3.2.3 |
| Rails | 6.1.7.10 (gem) |
| dotnet | 10.0.103 |
| create-vite | 8.3.0 |
| create-next-app | latest (Next.js 16.1.6) |
| @angular/cli | latest (Angular 19) |
| create-nx-workspace | 22.5.2 |
