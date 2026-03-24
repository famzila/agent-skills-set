#!/usr/bin/env bash
set -euo pipefail

# Generic pseudo‑TTY prompt runner for macOS/Linux using `expect`.
#
# Usage:
#   ./scripts/run_with_expect.sh -- pnpm exec ng g @spartan-ng/cli:init
#
# Behavior (deterministic defaults):
# - Select prompts: presses Enter to accept default choice
# - Text prompts: presses Enter to accept default
# - Confirm prompts: answers "y" + Enter
#
# If a prompt needs a non-default selection, stop and use human-in-terminal handoff.

if ! command -v expect >/dev/null 2>&1; then
  echo "expect not found. Use human-in-terminal handoff."
  exit 2
fi

if [[ "${1:-}" != "--" ]]; then
  echo "Usage: $0 -- <command...>"
  exit 2
fi
shift

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 -- <command...>"
  exit 2
fi

expect -c "
  set timeout 3600
  log_user 1
  spawn -noecho {*}$*
  expect {
    -re {\\? (Choose|Select|Pick).*} { send \"\\r\"; exp_continue }
    -re {(Use arrow keys|No matching choices)} { send \"\\r\"; exp_continue }
    -re {(overwrite|Overwrite|confirm|Confirm|Proceed|proceed).*(\\(y/N\\)|\\(Y/n\\)|\\[y/N\\]|\\[Y/n\\]).*} { send \"y\\r\"; exp_continue }
    -re {â€º[ ]*$} { send \"\\r\"; exp_continue }
    eof
  }
  catch wait result
  exit [lindex \$result 3]
"

