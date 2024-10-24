# Make symlinks on a Windows machine, for the current user
# Currently only links `init.vim`
# You may need to activate "developer mode" (see [this](https://stackoverflow.com/a/34905638))

$REPO_DIR = (Get-Item $PSScriptRoot).parent

New-Item -Path "$env:USERPROFILE\AppData\Local\nvim\init.vim" -ItemType SymbolicLink -Value "$REPO_DIR\init.vim"