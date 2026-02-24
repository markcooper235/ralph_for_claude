# Ralph Add Requirement - Quick Add Single Requirement

Quickly add a single requirement to running Ralph loop (simplified version of ralph-modify-spec).

## Usage

```
/ralph-add-requirement <description> [--priority=high|medium|low] [--depends-on=REQ-XXX,REQ-YYY]
```

## Purpose

Fast way to add a discovered gap without full spec modification flow.

## Instructions

### Quick Add Flow

```
[Add Req] Quick Add Requirement
[Add Req] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Add Req] Current run: user-authentication-20260223152030
[Add Req] Next REQ-ID: REQ-009

[Add Req] Requirement description:
> Email verification before account activation

[Add Req] Priority (high/medium/low, default: medium):
> high

[Add Req] Dependencies (REQ-IDs, comma-separated, or 'none'):
> REQ-001, REQ-002

[Add Req] Acceptance criteria (enter one per line, 'done' when finished):
> User receives verification email
> Email contains unique verification link
> Link expires after 24 hours
> Account activated on successful verification
> done

[Add Req] Analyzing...
[Add Req] - Will modify: auth/verify.ts (new file)
[Add Req] - No conflicts with existing stories
[Add Req] - Dependencies satisfied: REQ-001 ✓, REQ-002 ✓
[Add Req] - Can start: immediately (next available phase)

[Add Req] Add this requirement? (y/n)
> y

[Add Req] ✓ REQ-009 added: Email Verification
[Add Req] ✓ Spec updated (v2)
[Add Req] ✓ Story created
[Add Req] ✓ Task created
[Add Req] ✓ Execution plan updated

[Add Req] Story will execute in: Phase 3 (next available)
[Add Req] Estimated cost: 16,000 tokens

[Add Req] Continue with /ralph-loop or /ralph-resume
```

### What It Does

1. Pauses current work
2. Assigns next sequential REQ-ID
3. Adds requirement to spec
4. Creates story in stories.json
5. Creates Claude Task
6. Analyzes dependencies and conflicts
7. Updates execution plan
8. Archives modification
9. Ready to resume

### Integration

Calls `/ralph-modify-spec` internally but with streamlined UX for single requirement.

## Examples

### Example 1: Discovered Gap
```bash
/ralph-add-requirement "Add email verification" --priority=high --depends-on=REQ-001
```

### Example 2: Missing Security Requirement
```bash
/ralph-add-requirement "Rate limiting on login attempts" --priority=high
```

### Example 3: Integration Requirement
```bash
/ralph-add-requirement "Webhook notifications on user events" --priority=low
```

## Notes

- For multiple requirements or complex changes, use `/ralph-modify-spec`
- For quick single additions, this is faster
- Maintains all safety features of full modification
- Spec versioning still tracked
- All changes archived
