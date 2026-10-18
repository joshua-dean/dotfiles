# Make symlinks on a Windows machine, for the current user
# Currently links `init.vim` and `claude/CLAUDE.md`
# You may need to activate "developer mode" (see [this](https://stackoverflow.com/a/34905638))
# Uses `mklink`, since Windows PowerShell 5.1's `New-Item` requires admin even in developer mode

$REPO_DIR = (Get-Item $PSScriptRoot).parent

cmd /c mklink "$env:USERPROFILE\AppData\Local\nvim\init.vim" "$REPO_DIR\init.vim"
cmd /c mklink "$env:USERPROFILE\.claude\CLAUDE.md" "$REPO_DIR\claude\CLAUDE.md"
