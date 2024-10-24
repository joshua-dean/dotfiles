# Setup for pathogen on windows
# Also pulls my fork of `vim-argwrap`

$NVIM_DIR = "$env:USERPROFILE\AppData\Local\nvim"
$BUNDLE_DIR = "$NVIM_DIR\bundle"
$AUTOLOAD_DIR = "$NVIM_DIR\autoload"

# Make `nvim` dir, "autoload", and  "bundle" subdirs if not present
New-Item -ErrorAction Ignore -ItemType directory -Path $NVIM_DIR
New-Item -ErrorAction Ignore -ItemType directory -Path $BUNDLE_DIR
New-Item -ErrorAction Ignore -ItemType directory -Path $AUTOLOAD_DIR

curl -LSso "$AUTOLOAD_DIR\pathogen.vim" https://tpo.pe/pathogen.vim

git clone git@github.com:joshua-dean/vim-argwrap.git "$BUNDLE_DIR\vim-argwrap"
