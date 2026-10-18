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
  # Bash/zsh port of PowerShell's posh-git prompt: `~/code/dotfiles [main ≡ +0 ~1 -0 | +1 ~0 -0 !]> `
  poshGitSh = pkgs.fetchFromGitHub {
    owner = "lyze";
    repo = "posh-git-sh";
    rev = "0de03f92f4d0a31333b7c3d6d103b6c09c0ee57e";
    hash = "sha256-1uPpnrUGMoG83onuxXxQo2/ShRoEMSLHmRKuJI2Hfm8=";
  };
  # Hand URLs and files to Windows' default app (wslu, the usual tool, was dropped from nixpkgs).
  # rundll32's handler avoids cmd/PowerShell quoting, which mangles URLs containing `&`.
  windowsOpen = pkgs.writeShellScriptBin "xdg-open" ''
    target=$1
    [ -e "$target" ] && target=$(wslpath -w "$target") # local paths need a Windows path
    exec /mnt/c/Windows/System32/rundll32.exe url.dll,FileProtocolHandler "$target"
  '';
in
{
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    gh
    tmux
    neovim
    vim # .gitconfig core.editor
    jq
    yq
    (callPackage ./pkgs/uv.nix { })
    rustup
    gcc
    nixfmt
    lazygit
    shellcheck # .shellcheckrc
    xclip # clipsh/clip aliases (via WSLg)
    xsel # cpl alias
    cloc # git cloc
    dnsutils # dig, for whoami-cloudflare
    orpie # rpn aliases
    windowsOpen
  ];
  home.sessionVariables.BROWSER = "xdg-open";

  # vim-plug for init.vim, which installs its plugins itself on first launch
  xdg.dataFile."nvim/site/autoload/plug.vim".source = "${pkgs.vimPlugins.vim-plug}/plug.vim";

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
    initExtra =
      sourceAliases
      + sourceIf [ ".personal_bash_history_config" ]
      + ''
        # `wsl` starts in the Windows folder it was run from; start fresh login shells in ~ instead
        if shopt -q login_shell && [[ $PWD == /mnt/* ]]; then cd ~; fi
        source ${poshGitSh}/git-prompt.sh
        # Args: prefix, suffix, then text around the git status (only shown inside a repo)
        PROMPT_COMMAND='__posh_git_ps1 "\w" "> " " " "";'"''${PROMPT_COMMAND:-}"
      '';
  };
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # KEYTIMEOUT is in 10ms units (default 40); keeps Esc into vi normal mode snappy
    initContent = sourceAliases + ''
      KEYTIMEOUT=1
      # `wsl` starts in the Windows folder it was run from; start fresh login shells in ~ instead
      if [[ -o login && $PWD == /mnt/* ]]; then cd ~; fi
      source ${poshGitSh}/git-prompt.sh
      precmd() { __posh_git_ps1 '%~' '> ' ' ' '''; }
    '';
  };
}
