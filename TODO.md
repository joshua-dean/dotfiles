# TODO

- [ ] Sort the `.personal_*` bash aliases
- [ ] Group the conda/mamba utils, probably drop them
- [ ] Port Python utilities to `uv`
- [ ] Track VS Code settings, themes and extensions
- [ ] Decide how to track system packages on non-Nix setups (Windows, other Linux)
- [ ] Roll verbose `.gitconfig` aliases into scripts
- [ ] Better Claude rules
  - One `claude/deny_patterns.txt` of regexes, linked via `links.toml`
  - `PreToolUse` hook (matcher `Bash|PowerShell`) blocks any command matching it
  - Keep a few `deny` rules as backup if hooks get disabled
  - Add `mcp__*` deny entries separately for MCP tools
