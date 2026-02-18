#!/usr/bin/env bash
set -euo pipefail

# Resolve the path to style.md relative to this plugin's root
STYLE_FILE="${CLAUDE_PLUGIN_ROOT}/style.md"

# If style.md does not exist, output empty additionalContext and exit gracefully
if [ ! -f "$STYLE_FILE" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
  exit 0
fi

# Read style.md, strip YAML frontmatter (content between first two '---' lines),
# and keep only the body content
CONTENT=$(awk 'BEGIN{skip=0} /^---[[:space:]]*$/{skip++; next} skip>=2{print}' "$STYLE_FILE")

# JSON-escape the content using python3 (pre-installed on macOS)
# This handles newlines, double quotes, backslashes, tabs, and unicode correctly
ESCAPED=$(printf '%s' "$CONTENT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read())[1:-1])')

# Output the hookSpecificOutput JSON
cat <<JSONEOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"${ESCAPED}"}}
JSONEOF

exit 0
