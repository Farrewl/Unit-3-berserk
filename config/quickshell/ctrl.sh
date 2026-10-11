#!/usr/bin/env bash
# ── Unit-3 ControlCenter toggle ──
# Usage:
#   ctrl.sh         → toggle the ControlCenter (open if closed, close if open)
#   ctrl.sh open    → force open
#   ctrl.sh close   → force close
#
# The ControlCenter must already be loaded by the main Quickshell instance.
# This script sends an IPC command — it does NOT spawn a new qs process.

case "${1:-toggle}" in
  open)  exec qs ipc call ctrl forceOpen ;;
  close) exec qs ipc call ctrl hide ;;
  *)     exec qs ipc call ctrl toggle ;;
esac
