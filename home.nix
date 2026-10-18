{ config, pkgs, ... }:
let
  # Link to the live checkout (not the Nix store) so edits apply without a rebuild
  repo = "${config.home.homeDirectory}/code/dotfiles";
  link = f: config.lib.file.mkOutOfStoreSymlink "${repo}/${f}";
  sourceIf =
    files: builtins.concatStringsSep "\n" (map (f: "[ -f ~/${f} ] && source ~/${f}") files) + "\n";
  sourceAliases = sourceIf [
    ".personal_bash_aliases"
    ".personal_bash_python_utils"
  ];
in
{
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    gh
    tmux
    neovim
    jq
    yq
    uv
    rustup
    gcc
  ];

  home.file =
    builtins.listToAttrs (
      map
        (f: {
          name = f;
          value.source = link f;
        })
        [
          ".editorconfig"
          ".gitconfig"
          ".gitignore_global"
          ".inputrc"
          ".shellcheckrc"
          ".tmux.conf"
          ".vimrc"
          ".personal_bash_aliases"
          ".personal_bash_history_config"
          ".personal_bash_python_utils"
        ]
    )
    // {
      ".claude/CLAUDE.md".source = link "claude/CLAUDE.md";
    };
  xdg.configFile."nvim/init.vim".source = link "init.vim";

  programs.bash = {
    enable = true;
    initExtra = sourceAliases + sourceIf [ ".personal_bash_history_config" ];
  };
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = sourceAliases;
  };
  programs.starship.enable = true; # git-aware prompt for both shells
}
