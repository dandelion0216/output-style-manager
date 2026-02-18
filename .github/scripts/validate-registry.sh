#!/usr/bin/env bash
set -euo pipefail

REGISTRY="$1"
BASE_REGISTRY="$2"
RESULT_FILE="/tmp/validation-result.md"
ERRORS=()
WARNINGS=()
PASSED=()

# ============================================================
# Helper: write result and exit
# ============================================================
write_result() {
  {
    echo "## Registry Validation"
    echo ""

    if [ ${#ERRORS[@]} -eq 0 ]; then
      echo ":white_check_mark: **All checks passed**"
    else
      echo ":x: **Validation failed** (${#ERRORS[@]} error(s))"
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
      echo ":warning: ${#WARNINGS[@]} warning(s) require attention"
    fi

    echo ""
    echo "---"
    echo ""

    if [ ${#ERRORS[@]} -gt 0 ]; then
      echo "### :x: Errors"
      echo ""
      for err in "${ERRORS[@]}"; do
        echo "- $err"
      done
      echo ""
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
      echo "### :warning: Warnings"
      echo ""
      for warn in "${WARNINGS[@]}"; do
        echo "- $warn"
      done
      echo ""
    fi

    if [ ${#PASSED[@]} -gt 0 ]; then
      echo "<details>"
      echo "<summary>:white_check_mark: Passed checks (${#PASSED[@]})</summary>"
      echo ""
      for pass in "${PASSED[@]}"; do
        echo "- $pass"
      done
      echo ""
      echo "</details>"
    fi

    echo ""
    echo "---"
    echo "*Automated validation by registry-pr-validator*"

  } > "$RESULT_FILE"
}

# ============================================================
# STEP 1: JSON Structure Validation
# ============================================================
if ! jq empty "$REGISTRY" 2>/dev/null; then
  ERRORS+=("registry.json is not valid JSON")
  write_result
  exit 1
fi

if ! jq -e '.styles | type == "array"' "$REGISTRY" > /dev/null 2>&1; then
  ERRORS+=("registry.json must contain a top-level \"styles\" array")
  write_result
  exit 1
fi

PASSED+=("JSON structure is valid")

# ============================================================
# STEP 2: Identify New / Changed Entries
# ============================================================
BASE_NAMES=$(jq -r '.styles[].name' "$BASE_REGISTRY" 2>/dev/null | sort || true)
CURRENT_NAMES=$(jq -r '.styles[].name' "$REGISTRY" | sort)
NEW_NAMES=$(comm -13 <(echo "$BASE_NAMES") <(echo "$CURRENT_NAMES") || true)

# Detect gist_id changes on existing entries (only entries present in both base and current)
EXISTING_NAMES=$(comm -12 <(echo "$BASE_NAMES") <(echo "$CURRENT_NAMES") || true)
CHANGED_NAMES=""
while IFS= read -r name; do
  [ -z "$name" ] && continue
  BASE_GID=$(jq -r ".styles[] | select(.name == \"$name\") | .gist_id" "$BASE_REGISTRY" 2>/dev/null || true)
  CURR_GID=$(jq -r ".styles[] | select(.name == \"$name\") | .gist_id" "$REGISTRY")
  if [[ "$BASE_GID" != "$CURR_GID" ]]; then
    CHANGED_NAMES="${CHANGED_NAMES}${name}"$'\n'
  fi
done <<< "$EXISTING_NAMES"

# Combine new + changed for Gist validation
VALIDATE_NAMES=$(printf '%s\n%s' "$NEW_NAMES" "$CHANGED_NAMES" | sort -u)

if [ -n "$NEW_NAMES" ]; then
  PASSED+=("New entries detected: $(echo "$NEW_NAMES" | tr '\n' ', ')")
fi
if [ -n "$CHANGED_NAMES" ]; then
  WARNINGS+=("gist_id changed for existing entries: $(echo "$CHANGED_NAMES" | tr '\n' ', ')")
fi

# ============================================================
# STEP 3: Required Fields Check
# ============================================================
ENTRY_COUNT=$(jq '.styles | length' "$REGISTRY")
REQUIRED_FIELDS=("name" "description" "gist_id" "author" "bundled")
SEEN_NAMES=()

for i in $(seq 0 $((ENTRY_COUNT - 1))); do
  ENTRY_NAME=$(jq -r ".styles[$i].name // empty" "$REGISTRY")

  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! jq -e ".styles[$i] | has(\"$field\")" "$REGISTRY" > /dev/null 2>&1; then
      ERRORS+=("Entry \"$ENTRY_NAME\" (index $i): missing required field \"$field\"")
    fi
  done

  # Type checks
  BUNDLED=$(jq -r ".styles[$i].bundled" "$REGISTRY")
  GIST_ID=$(jq -r ".styles[$i].gist_id" "$REGISTRY")

  if [[ "$BUNDLED" != "true" && "$BUNDLED" != "false" ]]; then
    ERRORS+=("Entry \"$ENTRY_NAME\": \"bundled\" must be true or false")
  fi

  if [[ "$BUNDLED" == "false" && ("$GIST_ID" == "null" || -z "$GIST_ID") ]]; then
    ERRORS+=("Entry \"$ENTRY_NAME\": community style (bundled: false) must have a non-null gist_id")
  fi

  # bundled styles should also have gist_id for reference
  if [[ "$BUNDLED" == "true" && "$GIST_ID" == "null" ]]; then
    WARNINGS+=("Entry \"$ENTRY_NAME\": bundled style has no gist_id (recommended to set one)")
  fi

  if [ -z "$ENTRY_NAME" ]; then
    ERRORS+=("Entry at index $i: \"name\" is empty")
  fi

  if [[ -n "$ENTRY_NAME" ]] && ! echo "$ENTRY_NAME" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
    WARNINGS+=("Entry \"$ENTRY_NAME\": name should be kebab-case (lowercase, hyphens only)")
  fi

  # Duplicate check
  for seen in "${SEEN_NAMES[@]+"${SEEN_NAMES[@]}"}"; do
    if [[ "$seen" == "$ENTRY_NAME" ]]; then
      ERRORS+=("Duplicate style name: \"$ENTRY_NAME\"")
      break
    fi
  done
  SEEN_NAMES+=("$ENTRY_NAME")
done

PASSED+=("Required fields check completed ($ENTRY_COUNT entries)")

# ============================================================
# STEP 4-6: Gist Validation & Security Scan (new/changed only)
# ============================================================
while IFS= read -r target_name; do
  [ -z "$target_name" ] && continue

  GIST_ID=$(jq -r "[.styles[] | select(.name == \"$target_name\") | .gist_id] | first" "$REGISTRY")
  BUNDLED=$(jq -r "[.styles[] | select(.name == \"$target_name\") | .bundled] | first" "$REGISTRY")

  # Skip bundled styles
  [[ "$BUNDLED" == "true" ]] && continue
  [[ "$GIST_ID" == "null" || -z "$GIST_ID" ]] && continue

  # ---- STEP 4: Gist Accessibility ----
  if ! GIST_CONTENT=$(gh gist view "$GIST_ID" --raw 2>&1); then
    ERRORS+=("Entry \"$target_name\": Gist $GIST_ID is not accessible ($GIST_CONTENT)")
    continue
  fi

  PASSED+=("Entry \"$target_name\": Gist $GIST_ID is accessible")

  # ---- STEP 5: YAML Frontmatter Validation ----
  FIRST_LINE=$(echo "$GIST_CONTENT" | head -1)
  if [[ "$FIRST_LINE" != "---" ]]; then
    ERRORS+=("Entry \"$target_name\": Gist content does not start with YAML frontmatter (---)")
    continue
  fi

  FRONTMATTER=$(echo "$GIST_CONTENT" | awk 'BEGIN{c=0} /^---[[:space:]]*$/{c++; if(c==2) exit; next} c==1{print}')

  if [ -z "$FRONTMATTER" ]; then
    ERRORS+=("Entry \"$target_name\": YAML frontmatter is empty or malformed")
    continue
  fi

  if ! echo "$FRONTMATTER" | grep -qE '^name:'; then
    ERRORS+=("Entry \"$target_name\": YAML frontmatter missing \"name\" field")
    continue
  fi

  BODY=$(echo "$GIST_CONTENT" | awk 'BEGIN{c=0} /^---[[:space:]]*$/{c++; next} c>=2{print}')
  BODY_TRIMMED=$(echo "$BODY" | tr -d '[:space:]')

  if [ -z "$BODY_TRIMMED" ]; then
    ERRORS+=("Entry \"$target_name\": Gist has no style content after frontmatter")
    continue
  fi

  PASSED+=("Entry \"$target_name\": Gist content has valid frontmatter and body")

  # ---- STEP 6: Security Scan ----
  SECURITY_FLAGS=()

  # 6a. System prompt override attempts
  SYSTEM_OVERRIDE_PATTERNS=(
    'ignore (all |any )?(previous|prior|above) (instructions|prompts|rules)'
    'disregard (all |any )?(previous|prior|above) (instructions|prompts|rules)'
    'forget (all |any )?(previous|prior|above) (instructions|prompts|rules)'
    'override (system|safety|security)'
    'new instructions:'
    'from now on,? (ignore|forget|disregard)'
    'system prompt'
    'jailbreak'
  )

  # 6b. File system / command execution attempts
  EXECUTION_PATTERNS=(
    'rm -rf'
    'curl .* \| (bash|sh)'
    'wget .* \| (bash|sh)'
    'eval\('
    'os\.system'
    'subprocess'
    'exec\('
    'import os'
    'require\(.*(fs|child_process|exec)'
  )

  # 6c. Data exfiltration attempts
  EXFIL_PATTERNS=(
    'send (all |any |the )?(files?|data|content|code|secrets?|keys?|tokens?|credentials?) to'
    'upload .* to'
    'exfiltrate'
    'base64 encode .* (and |then )?(send|post|upload)'
  )

  # 6d. Credential / secret access attempts
  SECRET_PATTERNS=(
    '\.env'
    'API.?KEY'
    'SECRET.?KEY'
    'ACCESS.?TOKEN'
    'ssh.?key'
    'private.?key'
  )

  # 6e. Role manipulation
  ROLE_PATTERNS=(
    'you are (a |an )?(hacker|attacker|malicious)'
    'pretend (to be|you are)'
    'act as (if|though)'
    'do anything now'
  )

  check_patterns() {
    local category="$1"
    shift
    local patterns=("$@")
    for pattern in "${patterns[@]}"; do
      MATCHES=$(echo "$GIST_CONTENT" | grep -icE "$pattern" 2>/dev/null || true)
      if [ "$MATCHES" -gt 0 ]; then
        MATCHED_LINE=$(echo "$GIST_CONTENT" | grep -iE "$pattern" | head -1 | cut -c1-100)
        SECURITY_FLAGS+=("[$category] Pattern matched: \`$MATCHED_LINE\`")
      fi
    done
  }

  check_patterns "SYSTEM_OVERRIDE" "${SYSTEM_OVERRIDE_PATTERNS[@]}"
  check_patterns "COMMAND_EXEC" "${EXECUTION_PATTERNS[@]}"
  check_patterns "DATA_EXFIL" "${EXFIL_PATTERNS[@]}"
  check_patterns "SECRET_ACCESS" "${SECRET_PATTERNS[@]}"
  check_patterns "ROLE_MANIPULATION" "${ROLE_PATTERNS[@]}"

  # 6f. Suspicious URL check
  URLS=$(echo "$GIST_CONTENT" | grep -oE 'https?://[^ )"'"'"'`>]+' || true)
  if [ -n "$URLS" ]; then
    SECURITY_FLAGS+=("[SUSPICIOUS_URL] URLs found in style content (unusual for output style definitions)")

    ALLOWED_DOMAINS="github\.com|gist\.github\.com|docs\.anthropic\.com|docs\.claude\.com"
    SHORTENER_DOMAINS="bit\.ly|t\.co|tinyurl\.com|is\.gd|goo\.gl|ow\.ly|buff\.ly|rb\.gy|short\.io"

    while IFS= read -r url; do
      [ -z "$url" ] && continue
      DOMAIN=$(echo "$url" | sed -E 's|https?://([^/]+).*|\1|')

      # IP address direct access
      if echo "$DOMAIN" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
        ERRORS+=("Entry \"$target_name\": [SUSPICIOUS_URL] IP address URL detected: \`$url\`")
      # URL shorteners
      elif echo "$DOMAIN" | grep -qiE "^($SHORTENER_DOMAINS)$"; then
        ERRORS+=("Entry \"$target_name\": [SUSPICIOUS_URL] URL shortener detected: \`$url\`")
      # Non-allowed domains
      elif ! echo "$DOMAIN" | grep -qiE "($ALLOWED_DOMAINS)$"; then
        SECURITY_FLAGS+=("[SUSPICIOUS_URL] Non-allowed domain: \`$url\`")
      fi
    done <<< "$URLS"
  fi

  # data: URI scheme
  if echo "$GIST_CONTENT" | grep -qiE 'data:[a-z]+/[a-z]'; then
    ERRORS+=("Entry \"$target_name\": [SUSPICIOUS_URL] data: URI scheme detected")
  fi

  if [ ${#SECURITY_FLAGS[@]} -gt 0 ]; then
    for flag in "${SECURITY_FLAGS[@]}"; do
      WARNINGS+=("Entry \"$target_name\": $flag")
    done
    WARNINGS+=("Entry \"$target_name\": ${#SECURITY_FLAGS[@]} security pattern(s) flagged -- manual review recommended")
  else
    PASSED+=("Entry \"$target_name\": No security issues detected")
  fi

  # ---- STEP 7: Content Size Check ----
  CHAR_COUNT=${#GIST_CONTENT}
  if [ "$CHAR_COUNT" -gt 5000 ]; then
    WARNINGS+=("Entry \"$target_name\": Gist content is $CHAR_COUNT characters (>5000). Large styles increase token consumption.")
  else
    PASSED+=("Entry \"$target_name\": Content size OK ($CHAR_COUNT chars)")
  fi

done <<< "$VALIDATE_NAMES"

# ============================================================
# Write result and exit
# ============================================================
write_result

if [ ${#ERRORS[@]} -gt 0 ]; then
  exit 1
fi

exit 0
