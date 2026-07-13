#!/bin/bash
# PreToolUse Hook for Claude Code
# This hook intercepts tool calls BEFORE execution and validates them against
# project rules. Return exit code 0 to allow, 1 to block.
#
# Receives via stdin: JSON payload with tool_name and tool_input
# Example:
# {
#   "tool_name": "Write",
#   "tool_input": {
#     "file_path": "/migrations/001_add_users.sql",
#     "content": "CREATE TABLE ..."
#   }
# }

set -euo pipefail

# Read input from stdin
read -r payload

# Extract tool name and file path using jq (if available) or grep/sed fallback
if command -v jq &> /dev/null; then
    tool_name=$(echo "$payload" | jq -r '.tool_name // empty')
    file_path=$(echo "$payload" | jq -r '.tool_input.file_path // empty')
    command_args=$(echo "$payload" | jq -r '.tool_input.command // empty')
else
    # Fallback for systems without jq
    tool_name=$(echo "$payload" | grep -o '"tool_name":"[^"]*"' | cut -d'"' -f4)
    file_path=$(echo "$payload" | grep -o '"file_path":"[^"]*"' | cut -d'"' -f4)
fi

# ============================================================================
# PROTECTED PATHS — These paths require explicit human approval to modify
# ============================================================================
# Customize these patterns for your project
declare -a PROTECTED_PATHS=(
    "/migrations/"           # Database migrations
    "/infra/"                # Infrastructure code
    "/terraform/"            # Terraform configs
    ".env"                   # Environment files
    "docker-compose.yml"     # Docker compose
    "Dockerfile"             # Docker container definition
    ".github/workflows/"     # GitHub Actions
    "azure-pipelines.yml"    # Azure DevOps pipelines
    "Makefile"               # Build commands
    "package-lock.json"      # Lock files (npm)
    "go.sum"                 # Lock files (Go)
    ".git/"                  # Git internals
)

# ============================================================================
# DEPRECATED PATTERNS — Block usage of deprecated libraries/patterns
# ============================================================================
declare -a DEPRECATED_PATTERNS=(
    "io/ioutil"              # Deprecated in Go 1.16+
    "encoding/json"          # Prefer json-iterator for performance
    "CommonJS"               # Use ES modules
    "var "                   # Use let/const in JavaScript
)

# ============================================================================
# DESTRUCTIVE COMMANDS — Require explicit confirmation
# ============================================================================
declare -a DESTRUCTIVE_COMMANDS=(
    "rm -rf"
    "rm -r"
    "git reset --hard"
    "git clean -f"
)

# ============================================================================
# Helper function: Check if path matches protected patterns
# ============================================================================
is_protected_path() {
    local path="$1"
    for pattern in "${PROTECTED_PATHS[@]}"; do
        if [[ "$path" =~ $pattern ]]; then
            return 0  # Protected
        fi
    done
    return 1  # Not protected
}

# ============================================================================
# Helper function: Check if content contains deprecated patterns
# ============================================================================
contains_deprecated_pattern() {
    local content="$1"
    for pattern in "${DEPRECATED_PATTERNS[@]}"; do
        if echo "$content" | grep -q "$pattern"; then
            return 0  # Found deprecated pattern
        fi
    done
    return 1  # No deprecated patterns
}

# ============================================================================
# Helper function: Check if command is destructive
# ============================================================================
is_destructive_command() {
    local command="$1"
    for pattern in "${DESTRUCTIVE_COMMANDS[@]}"; do
        if [[ "$command" == *"$pattern"* ]]; then
            return 0  # Is destructive
        fi
    done
    return 1  # Not destructive
}

# ============================================================================
# MAIN VALIDATION LOGIC
# ============================================================================

# Rule 1: Block writes to protected paths
if [[ "$tool_name" == "Write" ]] || [[ "$tool_name" == "Edit" ]]; then
    if [[ -n "$file_path" ]] && is_protected_path "$file_path"; then
        echo "❌ BLOCKED: $file_path is a protected path."
        echo ""
        echo "Protected paths require human approval because they are critical to:"
        echo "  - Database schema (migrations/)"
        echo "  - Infrastructure configuration (infra/, terraform/)"
        echo "  - Deployment automation (.github/workflows/, CI/CD)"
        echo "  - Secrets management (.env files)"
        echo ""
        echo "What to do:"
        echo "  1. Explain why you need to modify this file in a comment"
        echo "  2. Wait for human approval"
        echo "  3. Once approved, you can proceed"
        exit 1
    fi
fi

# Rule 2: Block destructive bash commands
if [[ "$tool_name" == "Bash" ]]; then
    if is_destructive_command "$command_args"; then
        echo "❌ BLOCKED: Destructive command detected: $command_args"
        echo ""
        echo "High-risk commands (rm -rf, git reset --hard, etc.) require confirmation."
        echo ""
        echo "What to do:"
        echo "  1. Explain why you need to run this command"
        echo "  2. If it's really necessary, wait for human approval"
        echo "  3. If it's not necessary, use a safer alternative (git revert, etc.)"
        exit 1
    fi
fi

# Rule 3: Warn about deprecated patterns (but don't block)
if [[ "$tool_name" == "Write" ]] || [[ "$tool_name" == "Edit" ]]; then
    content=$(echo "$payload" | grep -o '"content":"[^"]*' | cut -d'"' -f4 || true)
    if [[ -n "$content" ]] && contains_deprecated_pattern "$content"; then
        echo "⚠️  WARNING: Your code contains deprecated patterns:"
        echo ""
        echo "Deprecated patterns found in $file_path:"
        for pattern in "${DEPRECATED_PATTERNS[@]}"; do
            if echo "$content" | grep -q "$pattern"; then
                echo "  - $pattern"
            fi
        done
        echo ""
        echo "These are discouraged but not blocking. Consider using modern alternatives."
        # Don't exit(1) here — just warn
    fi
fi

# Rule 4: Verify file extensions match content type (basic sanity check)
if [[ "$tool_name" == "Write" ]]; then
    if [[ "$file_path" =~ \.sql$ ]]; then
        if ! [[ "$(echo "$payload" | grep -o '"content":"[^"]*' | head -c 50)" =~ (CREATE|ALTER|INSERT|UPDATE|DELETE|SELECT) ]]; then
            echo "⚠️  WARNING: File $file_path has .sql extension but doesn't look like SQL"
            # Don't block — might be valid
        fi
    fi
fi

# ============================================================================
# If we got here, the action is allowed
# ============================================================================
exit 0
