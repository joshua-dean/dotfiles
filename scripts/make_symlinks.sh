#!/bin/bash
# Make symlinks from repo dotfiles to relevant locations
# You must specify either '--hard/-h' or '--symbolic/-s' flag to determine the link type
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Usage string (based on https://stackoverflow.com/a/51911626)
__usage="
Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --hard      Make hard links
    -s, --symbolic  Make symbolic links
    -f, --force     Overwrite existing files
"

# If there are no args, print usage
if [[ $# -eq 0 ]]; then
    echo "$__usage"
    exit 1
fi

# Argument structure based on https://stackoverflow.com/a/7069755
hard_flag=''
symbolic_flag=''
force_flag=''
while [[ $# -gt 0 ]]; do
    case "$1" in
    --help)
        echo "$__usage"
        exit 0
        ;;
    -h | --hard)
        hard_flag='true'
        shift
        ;;
    -s | --symbolic)
        symbolic_flag='true'
        shift
        ;;
    -f | --force)
        force_flag='true'
        shift
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
done

# If both flags are set, complain
if [[ -n "$hard_flag" && -n "$symbolic_flag" ]]; then
    echo "You must specify either '--hard/-h' or '--symbolic/-s' flag, not both"
    exit 1
fi

# If neither flag is set, complain
if [[ -z "$hard_flag" && -z "$symbolic_flag" ]]; then
    echo "You must specify either '--hard/-h' or '--symbolic/-s' flag"
    exit 1
fi

ln_flags=''
# Add flags based on user input
if [[ -n "$symbolic_flag" ]]; then
    ln_flags="${ln_flags}--symbolic "
fi
if [[ -n "$force_flag" ]]; then
    ln_flags="${ln_flags}--force "
fi

# If any flags are specified, drop the trailing space
if [[ -n "$ln_flags" ]]; then
    ln_flags="${ln_flags% }"
fi

# Make symlinks
# These are listed in lexicographical order,
# files starting with a '.' first,
# as they would appear from `LC_COLLATE=C ls -1a`
ln "$ln_flags" "$REPO_DIR"/.gitconfig ~
ln "$ln_flags" "$REPO_DIR"/.gitignore_global ~
ln "$ln_flags" "$REPO_DIR"/.inputrc ~
ln "$ln_flags" "$REPO_DIR"/.shellcheckrc ~
ln "$ln_flags" "$REPO_DIR"/.tmux.conf ~
ln "$ln_flags" "$REPO_DIR"/.vimrc ~
ln "$ln_flags" "$REPO_DIR"/init.vim ~/.config/nvim
