---
name: harness-setup
description: Genera CLAUDE.md y hooks de seguridad pre-configurados para que equipos deleguen trabajo a Claude Code de forma controlada y auditable. Protege carpetas críticas, enforza convenciones del proyecto, verifica tests antes de commits, y define cuándo el agente debe parar a preguntar.
model_invoked: true
triggers:
  - harness setup
  - harness engineering
  - claude guardrails
  - seguridad de agente
  - agent safety
  - claude governance
  - controlar claude code
  - how to safely use claude code
  - cómo usar claude code de forma segura
  - proteger repositorio
  - reglas para claude
  - claude rules
---

# Harness Setup Skill

## Purpose

Generate a complete harness (CLAUDE.md + hooks) that wraps Claude Code with safety guards, enabling teams to delegate work to the agent confidently. This skill produces:

- **CLAUDE.md** — Work contract defining stack, conventions, protected files, test requirements, and decision points
- **PreToolUse Hook** — Detects and blocks dangerous operations (deletes, writes to critical folders, deprecated libraries)
- **PostToolUse Hook** — Verifies tests/linting pass after every change
- **Setup Guide** — Step-by-step instructions to activate hooks in `.claude/settings.json`
- **Decision Guide** — When the agent should stop and ask before acting

This bridges the gap between architectural guidelines (sdlc-toolkit) and safe execution (Claude Code with guardrails).

## Critical: Reference Standards

**Before generating harness, ALWAYS review:**
1. `../../references/security-rules.md` — File protection patterns, decision points
2. `../../references/clean-architecture.md` — Folder structure, protected layers
3. Project's EXISTING conventions (README, .gitignore, test setup, CI/CD)

Harness must align with team's actual practices, not impose fictional ones.

## Workflow

### 1. Project Context

Ask the user:
- **Project Name:** (e.g., "UserManagement", "OrderProcessing")
- **Repository Path:** Where is the codebase? (needed to scan structure)
- **Tech Stack:** What languages/frameworks? (Node.js + Express? Golang + Chi? React + Vite?)
- **Team Size:** Solo developer? Team of 5? (affects decision tolerance)

### 2. Critical Protections

Ask:
- **"Which folders/files should Claude Code NEVER modify without asking?"**
  - Typical answers: `/migrations`, `/infra`, `.env*`, `/terraform`, Dockerfiles, CI/CD pipelines
  - These become protected paths in PreToolUse hook

- **"Which files/patterns are 'always audit required'?"**
  - Examples: database schema changes, security-related code, payment logic

- **"Are there deprecated libraries or patterns to block?"**
  - Example: "Don't use CommonJS; we're ES modules only"

### 3. Team Conventions & Decision Points

Ask:
- **"What are your project conventions?"** (import order, folder structure, naming)
  - Tool will scan repo to auto-detect, but confirm with user

- **"When should Claude Code stop and ask rather than decide alone?"**
  - Before deleting files?
  - Before changing function signatures?
  - Before modifying public APIs?
  - Before changing database schema?
  - Default recommendation: ALWAYS ask before delete/schema changes

- **"What tests must pass before a commit?"** (npm test? go test? cargo test?)

### 4. Generate Harness

Create:
1. **CLAUDE.md** — Personalized with project's stack, folder structure, tests, conventions
2. **pretooluse-hook.sh** — Scans Write/Bash commands against protected paths + patterns
3. **posttooluse-hook.sh** — After any file write, verify tests still pass
4. **.claude/settings.json snippet** — Hook configuration ready to merge

All templates customized to the project.

### 5. Setup & Validation

Show user:
- Generated CLAUDE.md
- Hook script previews
- Setup instructions (copy-paste ready)
- Test the hooks with example scenarios

Ask: "Ready to activate? Once enabled, Claude Code will follow these guardrails automatically."

## Template Structure

### `assets/claude-md-template.md`

Sections (customized per project):
1. **Overview** — Project name, purpose, stack versions
2. **Folder Structure** — Directory tree showing where code goes
3. **Tech Stack** — Exact versions (Node 20.11, PostgreSQL 15, etc.)
4. **Protected Paths** — Folders/files that require special permission
5. **Development Conventions** — Import order, naming, comment style
6. **Testing Requirements** — Which tests must pass before commit
7. **CI/CD Integration** — Commands to run locally before push
8. **Decision Protocol** — When to stop and ask for approval
9. **Common Patterns** — 3-5 example implementations showing correct style
10. **Troubleshooting** — "If you hit error X, do Y"

### `assets/pretooluse-hook.sh`

Bash script that:
1. Receives tool name + arguments via stdin (JSON)
2. Checks if it's a **Write** or **Bash** command
3. Validates against protected paths (regex patterns)
4. Checks for deprecated patterns (libraries, syntax)
5. Returns exit code 0 (allow) or 1 (block with message)

Examples of blocks:
- Writing to `/migrations/` without explicit flag
- Writing to `/terraform/`, `/infra/`, `.env*`
- Running `rm -rf` on critical paths
- Importing deprecated packages

### `assets/posttooluse-hook.sh`

Bash script that:
1. After Write/Bash completes, checks repo state
2. Runs test command (npm test, go test, etc.)
3. Runs linter (eslint, go fmt, etc.)
4. If tests fail, returns exit 1 + error message
5. Agent re-reads error and fixes automatically

### `assets/settings-json-snippet.json`

Ready-to-merge snippet for `.claude/settings.json`:
```json
{
  "hooks": {
    "preToolUse": {
      "command": "bash .claude/hooks/pretooluse.sh"
    },
    "postToolUse": {
      "command": "bash .claude/hooks/posttooluse.sh"
    }
  }
}
```

## Reference Standards Integration

### Security Rules Applied
- ✅ Protected paths: `/migrations`, `/infra`, CI/CD configs, `.env*`
- ✅ Decision points: before delete, before schema change, before public API change
- ✅ Deprecated pattern detection: warns before using old libraries
- ✅ Test requirement: tests must pass before each commit

### Clean Architecture Applied
- ✅ Folder structure enforced (no writes outside expected directories)
- ✅ Layer separation respected (no direct DB writes from handlers)
- ✅ Test colocation (tests live next to code they test)
- ✅ Dependency rules (imports from layers above only)

### Governance Goals
- ✅ Every action is auditable (git commits with clear messages)
- ✅ Nothing lands without passing tests/lint
- ✅ High-risk changes require human review (schema, API, infrastructure)
- ✅ Agent can work autonomously on features, catches its own errors

## Quality Checklist

Before returning harness to user:

**CLAUDE.md:**
- ✅ Stack versions are EXACT (Node 20.11.0, not "Node 20")
- ✅ All protected paths listed with rationale
- ✅ Test commands are copy-paste ready (npm test, go test -v, etc.)
- ✅ 3+ example implementations showing correct style
- ✅ Decision protocol is explicit (when to ask, not vague)
- ✅ No fictional conventions (only real project patterns)

**Hooks:**
- ✅ PreToolUse handles Write, Bash, Edit tools
- ✅ Protected paths are regex patterns (allow for flexibility)
- ✅ Exit code logic is clear (0 = allow, 1 = block)
- ✅ Error messages are actionable (tell agent what to do instead)
- ✅ PostToolUse runs actual test commands (not stubs)

**Settings:**
- ✅ JSON is valid (can copy-paste directly)
- ✅ Paths are correct (.claude/hooks/*)
- ✅ Instructions include where to place hook files

**Integration:**
- ✅ CLAUDE.md + hooks are compatible
- ✅ Test no false positives (legitimate files not blocked)
- ✅ Test no false negatives (risky operations not missed)

## Interaction Examples

### Example 1: Node.js/Express API

**User:** "Generate harness for my Express API. I want to protect /migrations and make sure tests pass before commits."

**User Input:**
- Stack: Node 20, Express 4, PostgreSQL, Jest
- Protected: `/migrations/`, `/infra/`, `.env*`, `docker-compose.yml`
- Tests: `npm test && npm run lint`
- Decide alone: feature implementation, bug fixes
- Ask before: schema changes, public API changes, deleting files

**Generated:**
- CLAUDE.md with Express patterns (routes in src/routes/, logic in src/services/)
- PreToolUse blocks writes to /migrations/ unless approved
- PostToolUse runs `npm test && npm run lint` after every file change
- Example implementations showing correct Express handler style
- Decision guide: "Stop before modifying src/types/", "Proceed with src/routes/"

### Example 2: Golang Microservice

**User:** "Harness for my Golang microservice. Need to protect migrations, block deprecated io/ioutil."

**User Input:**
- Stack: Go 1.21, Chi router, PostgreSQL, testing package
- Protected: `/migrations/`, `/terraform/`, `Makefile`, all .env files
- Tests: `make test` (which runs go test -v ./...)
- Block patterns: `io/ioutil` (deprecated), `encoding/json` (use modern libs)
- Decision points: before schema changes, before package exports change

**Generated:**
- CLAUDE.md with Go patterns (cmd/server/main.go, internal/{domain,application,infrastructure})
- PreToolUse blocks io/ioutil imports, writes to /migrations/, destructive file ops
- PostToolUse runs `make test` + `go fmt ./...`
- Examples showing proper Go handler and repository patterns
- Decision guide: stop before modifying public interfaces

### Example 3: React SPA

**User:** "Harness for React frontend. What should I protect?"

**User Input:**
- Stack: React 18, Vite, Vitest, TypeScript
- Protected: `/public/`, `vite.config.ts`, `.env*`
- Tests: `npm run test` + `npm run lint`
- Conventions: Atomic design (src/components/{atoms,molecules,organisms})
- Stop points: before changing tsconfig.json, before modifying CSS frameworks

**Generated:**
- CLAUDE.md showing React folder structure and patterns
- PreToolUse blocks writes to Vite config, public folder
- PostToolUse runs tests + type check
- Examples of correct hook usage, component props interfaces
- Decision guide: implement components freely, ask before deps changes

## Refinement Workflow

If user asks for adjustments:
- "Which protection do you want to adjust?" (add protected path, change test command, etc.)
- Regenerate affected sections (CLAUDE.md, hook scripts)
- Re-test with examples
- Ask: "Better? Ready to activate?"

## Dependencies & Context

**Used by:** Teams implementing sdlc-toolkit recommendations with Claude Code
**Feeds into:** `.claude/settings.json`, CLAUDE.md in project root, hook scripts in .claude/hooks/
**References:**
- `../../references/security-rules.md` (decision points, file protection)
- `../../references/clean-architecture.md` (folder structure, layer enforcement)
- Project's own README, .gitignore, CI/CD config

**Output location:** `/sessions/[session-id]/mnt/outputs/[project-name]-harness-setup/`

Outputs include:
- `CLAUDE.md` (copy to project root)
- `.claude/hooks/pretooluse.sh` (copy to .claude/hooks/)
- `.claude/hooks/posttooluse.sh` (copy to .claude/hooks/)
- `settings-json-snippet.json` (merge into .claude/settings.json)
- `HARNESS_SETUP_GUIDE.md` (step-by-step activation instructions)

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) + Bash scripts (.sh) + JSON config
