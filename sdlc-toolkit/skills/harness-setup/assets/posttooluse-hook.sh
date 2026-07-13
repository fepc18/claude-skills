#!/bin/bash
# PostToolUse Hook for Claude Code
# This hook runs AFTER a tool completes and verifies the project is still healthy.
# Specifically: tests pass, linting passes, build succeeds.
#
# This hook creates an autonomous feedback loop:
#   1. Agent writes code
#   2. PostToolUse hook runs tests
#   3. If tests fail, hook returns exit 1
#   4. Agent sees error message, understands what's wrong
#   5. Agent fixes the code automatically
#   6. Repeat until tests pass
#
# This prevents broken code from being committed.

set -euo pipefail

# Read input from stdin (tool result data)
read -r payload

# Extract tool name (for selective validation)
if command -v jq &> /dev/null; then
    tool_name=$(echo "$payload" | jq -r '.tool_name // empty')
else
    tool_name=$(echo "$payload" | grep -o '"tool_name":"[^"]*"' | cut -d'"' -f4 || true)
fi

# ============================================================================
# CONFIGURATION — Customize these for your project
# ============================================================================

# Test command — what to run to verify the codebase is healthy
# Examples:
#   Node.js: "npm test && npm run lint"
#   Go: "make test && make lint"
#   Python: "pytest && black --check ."
TEST_COMMAND="[TEST_COMMAND_PLACEHOLDER]"

# Skip validation for these tools (unlikely to break anything)
declare -a SKIP_VALIDATION_TOOLS=(
    "Read"
    "Glob"
    "Grep"
    "TaskCreate"
    "TaskUpdate"
)

# Files to check for syntax errors (language-specific)
declare -a JAVASCRIPT_FILES=(
    "*.js"
    "*.ts"
    "*.tsx"
    "*.jsx"
)

declare -a GO_FILES=(
    "*.go"
)

# ============================================================================
# Helper function: Check if tool should skip validation
# ============================================================================
should_skip_validation() {
    local tool="$1"
    for skip_tool in "${SKIP_VALIDATION_TOOLS[@]}"; do
        if [[ "$tool" == "$skip_tool" ]]; then
            return 0  # Skip
        fi
    done
    return 1  # Don't skip
}

# ============================================================================
# Helper function: Run tests and capture output
# ============================================================================
run_tests() {
    local test_cmd="$1"
    local output_file="/tmp/test_output_$$.log"

    echo "🧪 Running: $test_cmd"
    echo ""

    # Run test command and capture output
    if eval "$test_cmd" > "$output_file" 2>&1; then
        # Tests passed
        cat "$output_file"
        rm -f "$output_file"
        return 0
    else
        # Tests failed
        exit_code=$?
        cat "$output_file"
        rm -f "$output_file"
        return $exit_code
    fi
}

# ============================================================================
# Helper function: Check JavaScript/TypeScript syntax
# ============================================================================
check_javascript_syntax() {
    echo "✓ Checking JavaScript/TypeScript syntax..."

    # Try to run tsc type check if it exists
    if command -v tsc &> /dev/null; then
        if ! tsc --noEmit; then
            echo "❌ TypeScript compilation failed"
            return 1
        fi
    fi

    # Try eslint if available
    if command -v eslint &> /dev/null; then
        if ! eslint . --max-warnings 0; then
            echo "❌ ESLint found errors"
            return 1
        fi
    fi

    return 0
}

# ============================================================================
# Helper function: Check Go syntax
# ============================================================================
check_go_syntax() {
    echo "✓ Checking Go syntax..."

    # Format check
    if ! go fmt ./...; then
        echo "❌ Go formatting failed"
        return 1
    fi

    # Build check
    if ! go build ./...; then
        echo "❌ Go build failed"
        return 1
    fi

    return 0
}

# ============================================================================
# MAIN VALIDATION LOGIC
# ============================================================================

# Skip validation for certain tools (they can't break anything)
if should_skip_validation "$tool_name"; then
    echo "⏭️  Skipping validation for $tool_name"
    exit 0
fi

# Only validate after writes (most likely to break things)
if [[ "$tool_name" != "Write" ]] && [[ "$tool_name" != "Edit" ]] && [[ "$tool_name" != "Bash" ]]; then
    echo "⏭️  Skipping validation for $tool_name"
    exit 0
fi

echo "════════════════════════════════════════════════════════════════"
echo "🔍 POST-TOOL VALIDATION"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "⚠️  Not in a git repository. Skipping validation."
    exit 0
fi

# Get list of changed files
changed_files=$(git status --porcelain | awk '{print $2}')

if [[ -z "$changed_files" ]]; then
    echo "✓ No files changed. Skipping validation."
    exit 0
fi

echo "📝 Files changed:"
echo "$changed_files" | sed 's/^/   /'
echo ""

# ============================================================================
# Detect project type and run appropriate checks
# ============================================================================

is_node_project=0
is_go_project=0
is_python_project=0

if [[ -f "package.json" ]]; then
    is_node_project=1
    echo "📦 Node.js project detected (package.json found)"
fi

if [[ -f "go.mod" ]]; then
    is_go_project=1
    echo "📦 Go project detected (go.mod found)"
fi

if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
    is_python_project=1
    echo "📦 Python project detected"
fi

echo ""

# ============================================================================
# Run project-specific validations
# ============================================================================

validation_passed=true

# Node.js validation
if [[ $is_node_project -eq 1 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing Node.js project..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check for TypeScript
    if check_javascript_syntax; then
        echo "✓ JavaScript/TypeScript syntax OK"
    else
        validation_passed=false
        echo "❌ JavaScript/TypeScript syntax check failed"
    fi
    echo ""
fi

# Go validation
if [[ $is_go_project -eq 1 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing Go project..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if check_go_syntax; then
        echo "✓ Go syntax OK"
    else
        validation_passed=false
        echo "❌ Go syntax check failed"
    fi
    echo ""
fi

# ============================================================================
# Run general test suite
# ============================================================================

if [[ "$TEST_COMMAND" != "[TEST_COMMAND_PLACEHOLDER]" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running test suite..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if run_tests "$TEST_COMMAND"; then
        echo ""
        echo "✓ All tests passed ✨"
    else
        validation_passed=false
        echo ""
        echo "❌ Tests failed. Please review the output above."
    fi
    echo ""
else
    echo "ℹ️  No test command configured (TEST_COMMAND is placeholder)"
    echo "   Update .claude/hooks/posttooluse.sh to add: npm test, go test, pytest, etc."
fi

# ============================================================================
# Final result
# ============================================================================

echo "════════════════════════════════════════════════════════════════"

if $validation_passed; then
    echo "✅ VALIDATION PASSED"
    echo "════════════════════════════════════════════════════════════════"
    exit 0
else
    echo "❌ VALIDATION FAILED"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "What to do:"
    echo "  1. Review the errors above"
    echo "  2. Fix the issues in your code"
    echo "  3. Re-run tests locally: $TEST_COMMAND"
    echo "  4. Try your changes again"
    exit 1
fi
