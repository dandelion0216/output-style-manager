#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${HOME}/.claude/output-style-active"
BUNDLED_STYLES_DIR="${CLAUDE_PLUGIN_ROOT}/styles"
CUSTOM_STYLES_DIR="${HOME}/.claude/custom-output-styles"

# Helper: output empty additionalContext
empty_output() {
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
  exit 0
}

# Read active style name
[ ! -f "$CONFIG_FILE" ] && empty_output

STYLE_NAME=$(tr -d '[:space:]' < "$CONFIG_FILE")
[ -z "$STYLE_NAME" ] && empty_output

# Look for style file: custom directory first, then bundled
STYLE_FILE=""
if [ -f "${CUSTOM_STYLES_DIR}/${STYLE_NAME}.md" ]; then
  STYLE_FILE="${CUSTOM_STYLES_DIR}/${STYLE_NAME}.md"
elif [ -f "${BUNDLED_STYLES_DIR}/${STYLE_NAME}.md" ]; then
  STYLE_FILE="${BUNDLED_STYLES_DIR}/${STYLE_NAME}.md"
fi

[ -z "$STYLE_FILE" ] && empty_output

# Strip YAML frontmatter and JSON-escape the body
CONTENT=$(awk 'BEGIN{skip=0} /^---[[:space:]]*$/{skip++; next} skip>=2{print}' "$STYLE_FILE")
ESCAPED=$(printf '%s' "$CONTENT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read())[1:-1])')

cat <<JSONEOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"${ESCAPED}"}}
JSONEOF

exit 0
