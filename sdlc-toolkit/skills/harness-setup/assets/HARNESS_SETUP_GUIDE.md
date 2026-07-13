# Harness Setup — Installation & Activation Guide

This guide walks you through setting up the Claude Code harness in your project. The harness consists of:

1. **CLAUDE.md** — Work contract that defines project rules
2. **Hook Scripts** — Pre/post validation that enforces rules
3. **Settings Configuration** — Activates hooks in Claude Code

---

## Step 1: Copy CLAUDE.md to Your Project Root

The CLAUDE.md file is your project's contract with Claude Code. It defines:
- Tech stack and exact versions
- Folder structure where code goes
- Protected paths (never modify without asking)
- Development conventions
- Testing requirements
- When to stop and ask for approval

**To install:**

```bash
# Copy the template to your project root
cp claude-md-template.md /path/to/your/project/CLAUDE.md

# Edit it to match your actual project
# Replace placeholders like [ProjectName], [test command], etc.
# Make sure ALL conventions match your actual codebase
```

**What to customize:**

- [ ] Project name, purpose, stack versions
- [ ] Folder structure (make it match your repo)
- [ ] Protected paths (add anything critical: migrations, infra, secrets)
- [ ] Test commands (npm test, go test, pytest, etc.)
- [ ] Code conventions (how imports are ordered, naming, etc.)
- [ ] Examples (show 3-5 real examples from your codebase)
- [ ] When to ask (database changes? public API changes? file deletes?)

**Verify it reads well:**
Open CLAUDE.md and scan through it. Does it match your project? Would a new developer understand the rules?

---

## Step 2: Create .claude/hooks/ Directory

The hooks are shell scripts that validate Claude Code's actions.

```bash
# Create the hooks directory
mkdir -p .claude/hooks

# Copy the hook scripts
cp pretooluse-hook.sh .claude/hooks/pretooluse.sh
cp posttooluse-hook.sh .claude/hooks/posttooluse.sh

# Make them executable
chmod +x .claude/hooks/pretooluse.sh
chmod +x .claude/hooks/posttooluse.sh
```

---

## Step 3: Customize Hook Scripts

The hook scripts have placeholders that need customization:

### PreToolUse Hook (pretooluse.sh)

Edit `.claude/hooks/pretooluse.sh`:

1. **Find the PROTECTED_PATHS array** (around line 50)
   ```bash
   declare -a PROTECTED_PATHS=(
       "/migrations/"           # Database migrations
       "/infra/"                # Infrastructure code
       ...
   )
   ```
   Add or remove paths specific to your project.

2. **Verify DEPRECATED_PATTERNS** (around line 60)
   ```bash
   declare -a DEPRECATED_PATTERNS=(
       "io/ioutil"              # Deprecated in Go 1.16+
       ...
   )
   ```
   Add patterns you want to warn about.

3. **Verify DESTRUCTIVE_COMMANDS** (around line 70)
   ```bash
   declare -a DESTRUCTIVE_COMMANDS=(
       "rm -rf"
       ...
   )
   ```
   These are already good defaults. Leave unless you have extras.

### PostToolUse Hook (posttooluse.sh)

Edit `.claude/hooks/posttooluse.sh`:

1. **Find the TEST_COMMAND** (around line 30)
   ```bash
   TEST_COMMAND="[TEST_COMMAND_PLACEHOLDER]"
   ```
   Replace with your actual test command:
   - **Node.js:** `npm test && npm run lint`
   - **Go:** `make test && make lint` or `go test -v ./... && go fmt ./...`
   - **Python:** `pytest && black --check .`
   - **Combination:** `npm test && npm run lint && npm run type-check`

   Example:
   ```bash
   TEST_COMMAND="npm test && npm run lint"
   ```

---

## Step 4: Merge Settings into .claude/settings.json

Claude Code reads `.claude/settings.json` to load hooks. You need to merge the hook configuration into this file.

**If .claude/settings.json already exists:**

1. Open `.claude/settings.json`
2. Open `settings-json-snippet.json`
3. Merge the `"hooks"` section into your existing settings

Example before:
```json
{
  "model": "claude-opus"
}
```

Example after:
```json
{
  "model": "claude-opus",
  "hooks": {
    "preToolUse": {
      "command": "bash .claude/hooks/pretooluse.sh",
      "description": "Validates tool usage against project rules..."
    },
    "postToolUse": {
      "command": "bash .claude/hooks/posttooluse.sh",
      "description": "Runs after each tool completes..."
    }
  }
}
```

**If .claude/settings.json doesn't exist:**

```bash
# Create it
mkdir -p .claude
cp settings-json-snippet.json .claude/settings.json
```

Then verify it's valid JSON:
```bash
cat .claude/settings.json | jq .
```

---

## Step 5: Test the Harness

Before committing to your project, test the hooks to make sure they work:

### Test PreToolUse Hook

```bash
# Create a test payload
cat > /tmp/test_payload.json << 'EOF'
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/migrations/test.sql",
    "content": "CREATE TABLE test (id UUID);"
  }
}
EOF

# Run the hook
cat /tmp/test_payload.json | bash .claude/hooks/pretooluse.sh
# Should output: ❌ BLOCKED: /migrations/ is a protected path.
# Exit code should be 1 (blocked)
```

### Test PostToolUse Hook

```bash
# Test hook exists and is executable
bash .claude/hooks/posttooluse.sh < /dev/null
# Should run tests and report status
```

### Verify Settings

```bash
# Check that settings.json is valid
cat .claude/settings.json | jq .hooks

# Should output something like:
# {
#   "preToolUse": {
#     "command": "bash .claude/hooks/pretooluse.sh",
#     ...
#   },
#   ...
# }
```

---

## Step 6: Commit Everything

Once tested, commit the harness to your repository:

```bash
# Stage all new harness files
git add CLAUDE.md .claude/hooks/ .claude/settings.json

# Commit
git commit -m "Add Claude Code harness: CLAUDE.md + hooks for safe agent delegation"

# Push
git push origin main
```

---

## Step 7: Tell Claude Code About the Harness

When you invoke Claude Code on your project, it will automatically:
1. Read CLAUDE.md
2. Load hooks from .claude/settings.json
3. Enforce all rules

**You don't need to do anything else.** The harness is now active.

---

## Testing the Harness in Action

Once activated, test with Claude Code:

```bash
# Start Claude Code
claude code

# Try a protected operation
# For example: "Edit /migrations/test.sql"
# Expected: Hook blocks it with message
```

Claude Code should respond with the block message from the hook. This confirms the harness is working.

---

## Troubleshooting

### "Hook script not found"
- Verify `.claude/settings.json` has correct path: `bash .claude/hooks/pretooluse.sh`
- Verify hooks are executable: `ls -la .claude/hooks/`
- If not: `chmod +x .claude/hooks/*.sh`

### "Invalid JSON in .claude/settings.json"
- Verify the file is valid: `cat .claude/settings.json | jq .`
- Check for trailing commas or missing quotes
- Merge the snippet carefully

### "Tests running but always passing"
- Verify TEST_COMMAND in posttooluse.sh matches reality
- Manually run the command: `npm test` or `go test ./...`
- Make sure your project actually has tests

### "Too many false positives (blocking legitimate edits)"
- Review PROTECTED_PATHS in pretooluse.sh
- Maybe you're too strict? Adjust patterns to be more specific
- Example: Instead of `"/test/"`, use `"/migrations/"` only

### "Hook scripts don't seem to run"
- Verify hooks are in `.claude/settings.json`
- Restart Claude Code session
- Check hook output: `bash .claude/hooks/pretooluse.sh < /tmp/test.json`

---

## Ongoing Maintenance

The harness is not set-and-forget. Keep it updated:

### When your tech stack changes
- Update CLAUDE.md stack section
- Update hook scripts if needed (new protected paths, new test commands)

### When conventions evolve
- Update the "Development Conventions" section in CLAUDE.md
- Add new examples if you discover better patterns

### When something keeps causing issues
- Review hook error messages
- Adjust protected paths or add warnings
- Re-test with examples

---

## What's Next?

Your project now has a harness! Claude Code will:

1. **Read CLAUDE.md** before every task → understand your rules
2. **Run PreToolUse hook** before each action → detect risky operations
3. **Run PostToolUse hook** after changes → verify tests still pass
4. **Create commits** with clear messages → maintain history
5. **Stop and ask** when uncertain → escalate to human

This creates a safe, predictable development loop where Claude Code can work autonomously on legitimate tasks while protecting critical parts of your codebase.

Happy delegation! 🚀
