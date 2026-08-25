#!/bin/bash

# ==========================================
# AUTO-SAVE CONFIGURATION
# ==========================================
# Normal slow polling interval for most of the assessment
NORMAL_INTERVAL=60
# Aggressive polling interval for the final minute
AGGRESSIVE_INTERVAL=10
# ==========================================

# Detect workspace root dynamically — works for any repo name
# The script is in .devcontainer/, so its parent directory IS the workspace root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

echo "[autosave] Script located at: $SCRIPT_DIR"
echo "[autosave] Workspace root detected as: $WORKSPACE_ROOT"

cd "$WORKSPACE_ROOT" || { echo "[autosave] FATAL: Could not cd to workspace root. Exiting."; exit 1; }

echo "[autosave] Starting autosave loop. Default interval: ${NORMAL_INTERVAL}s."

while true; do
  # Determine current interval dynamically based on remaining time
  CURRENT_INTERVAL=$NORMAL_INTERVAL

  if [ -f .session_end_time ]; then
    END_TIME=$(cat .session_end_time)
    CURRENT_TIME=$(date +%s)
    REMAINING=$((END_TIME - CURRENT_TIME))

    if [ "$REMAINING" -le 60 ] && [ "$REMAINING" -gt 0 ]; then
      CURRENT_INTERVAL=$AGGRESSIVE_INTERVAL
      echo "[autosave] $(date): WARNING - Final 60 seconds! Accelerating to every ${CURRENT_INTERVAL}s."
    fi
  else
    echo "[autosave] $(date): .session_end_time not found, using normal interval."
  fi

  sleep $CURRENT_INTERVAL

  echo "[autosave] $(date): Checking for changes..."

  # Check if there are any changes (tracked or untracked)
  GIT_STATUS=$(git status -s)
  if [[ -n "$GIT_STATUS" ]]; then
    echo "[autosave] $(date): Changes detected:"
    echo "$GIT_STATUS"
    git add .

    # Check if the last commit was an auto-save
    if git log -1 --pretty=%B 2>/dev/null | grep -q "^Auto-save backup"; then
      # Amend the existing auto-save commit to prevent a messy commit history
      GIT_AUTHOR_NAME="Auto-Save Bot" GIT_AUTHOR_EMAIL="autosave@cloudbintech.local" \
      GIT_COMMITTER_NAME="Auto-Save Bot" GIT_COMMITTER_EMAIL="autosave@cloudbintech.local" \
      git commit --amend --no-edit && \
      git push origin HEAD --force-with-lease && \
      echo "[autosave] $(date): Amended and pushed successfully." || \
      echo "[autosave] $(date): ERROR - push failed!"
    else
      # Create a new auto-save commit (preserves candidate's manual commits)
      GIT_AUTHOR_NAME="Auto-Save Bot" GIT_AUTHOR_EMAIL="autosave@cloudbintech.local" \
      GIT_COMMITTER_NAME="Auto-Save Bot" GIT_COMMITTER_EMAIL="autosave@cloudbintech.local" \
      git commit -m "Auto-save backup" && \
      git push origin HEAD && \
      echo "[autosave] $(date): New auto-save commit pushed successfully." || \
      echo "[autosave] $(date): ERROR - push failed!"
    fi
  else
    echo "[autosave] $(date): No changes to save."
  fi
done
