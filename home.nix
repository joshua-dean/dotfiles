{
  config,
  lib,
  pkgs,
  ...
}:
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

  # Same manifest scripts/link.py uses elsewhere; `linux` overrides `all`, both are ~/ paths
  home.file = lib.concatMapAttrs (
    name: entry:
    let
      targets = entry.linux or entry.all or [ ];
    in
    lib.listToAttrs (
      map (target: {
        name =
          if lib.hasPrefix "~/" target then
            lib.removePrefix "~/" target
          else
            throw "links.toml [${name}]: Linux targets must start with ~/ (got ${target})";
        value.source = link entry.source;
      }) (lib.toList targets)
    )
  ) (builtins.fromTOML (builtins.readFile ./links.toml));

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
