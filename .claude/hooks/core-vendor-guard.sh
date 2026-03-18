#!/usr/bin/env bash
#
# Hook: core-vendor-guard.sh
#
# PreToolUse hook for Write and Edit tools.
# Blocks modifications to Magento core/vendor files and instructs Claude Code
# to use plugins, observers, preferences, or theme overrides instead.
#
# Outputs nothing (exits 0 silently) for files outside vendor/ and app/code/Magento/.

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
")

[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
    */vendor/magento/* | */vendor/Magento/* | */app/code/Magento/*)
        cat <<'GUARD'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Modifying Magento core/vendor files is not allowed. Use a plugin (di.xml), observer (events.xml), preference, or theme override instead. Run /plugin or /create-theme-override for scaffolding help."
  }
}
GUARD
        ;;
    */vendor/*)
        cat <<'GUARD'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Modifying third-party vendor files is not allowed. Vendor files are managed by Composer and will be overwritten on update. Use a plugin, preference, or module override instead."
  }
}
GUARD
        ;;
    *)
        exit 0
        ;;
esac
