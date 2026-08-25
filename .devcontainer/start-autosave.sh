#!/bin/bash
# This wrapper properly daemonizes the autosave loop.
# Using a double-fork + disown to create a true background daemon
# that survives the parent shell exiting.

WORKSPACE="/workspaces/dexwin-devops-assessment"
LOG="$WORKSPACE/.devcontainer/autosave.log"
SCRIPT="$WORKSPACE/.devcontainer/autosave.sh"

# Double-fork daemonization:
# The outer &    → forks child from postStartCommand shell
# The inner nohup → detaches from terminal/SIGHUP
# disown          → removes from job table so shell exit won't kill it
(
  nohup bash "$SCRIPT" >> "$LOG" 2>&1 &
  disown $!
) </dev/null >/dev/null 2>&1
