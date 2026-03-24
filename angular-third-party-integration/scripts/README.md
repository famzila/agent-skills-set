# Helper Scripts for Interactive CLI Handling

These scripts are optional helpers to make interactive third-party CLIs work reliably when the environment has no true TTY.

## Recommended Approach: Inline Expect

For most reliable results, use inline `expect` directly in the shell command rather than the shell script wrapper. This avoids extra shell layers and quoting issues:

```bash
cd /path/to/project && expect -c '
set timeout 180
spawn pnpm exec ng g @spartan-ng/cli:ui button --directory libs/ui
expect {
    -re {\?.*›} { send "\r"; exp_continue }
    -re {\?.*\(y/N\)} { send "y\r"; exp_continue }
    -re {\?.*\(Y/n\)} { send "y\r"; exp_continue }
    -re {>\s*$} { send "\r"; exp_continue }
    eof
}
catch wait result
exit [lindex $result 3]
' 2>&1
```

## Pattern Reference

| Pattern | Matches | Action |
|---------|---------|--------|
| `{\?.*›}` | Any prompt with `?` and `›` (default value indicator) | Accept default (Enter) |
| `{\?.*\(y/N\)}` | Yes/No confirmation (default No) | Answer `y` |
| `{\?.*\(Y/n\)}` | Yes/No confirmation (default Yes) | Answer `y` |
| `{>\s*$}` | Fallback for any trailing `>` prompt | Accept default (Enter) |

## `run_with_expect.sh` (macOS/Linux)

An alternative wrapper script that runs a command inside an `expect` session and auto-accepts safe defaults:

- Select prompts: press Enter
- Text prompts: press Enter
- Yes/No prompts: answer `y` + Enter

Example:

```bash
./scripts/run_with_expect.sh -- pnpm exec ng g @spartan-ng/cli:init
```

If the CLI requires a non-default choice (not deterministic), do **human-in-terminal handoff**:
- run the command normally
- let the user answer the prompt in their terminal
