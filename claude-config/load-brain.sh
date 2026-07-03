#!/bin/bash
# SessionStart hook — auto-loads KASIRO_BRAIN.md into Claude Code CLI context
# File location after setup: kasiro-brain/.claude/hooks/load-brain.sh
#
# For SessionStart events, plain text written to stdout goes directly to Claude as context.
# Claude Code will auto-load the brain at the start of every CLI session in this directory.

BRAIN_FILE="${CLAUDE_PROJECT_DIR}/KASIRO_BRAIN.md"

if [ ! -f "$BRAIN_FILE" ]; then
  echo "[kasiro-brain] WARNING: KASIRO_BRAIN.md not found at $BRAIN_FILE"
  exit 0
fi

echo "=== KASIRO BRAIN AUTO-LOADED ==="
echo ""
cat "$BRAIN_FILE"
echo ""
echo "=== END KASIRO BRAIN ==="
echo ""
echo "Domain files (domains/*.md) and agent specs (agents/*/SPEC.md) are available."
echo "To run an agent: read the relevant SKILL.md and follow the session setup instructions."

exit 0
