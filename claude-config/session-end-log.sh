#!/bin/bash
# SessionEnd hook — appends timestamped entry to session_log.md
# File location after setup: kasiro-brain/.claude/hooks/session-end-log.sh
# async: true — fires after session ends, does not block

LOG_FILE="${CLAUDE_PROJECT_DIR}/session_log.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

if [ ! -f "$LOG_FILE" ]; then
  echo "# Kasiro Brain Session Log" > "$LOG_FILE"
  echo "" >> "$LOG_FILE"
fi

echo "## ${TIMESTAMP}" >> "$LOG_FILE"
echo "Session: ${SESSION_ID}" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit 0
