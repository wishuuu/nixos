{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "pl_PL.UTF-8";
  console.keyMap = "pl2";
  networking.firewall.enable = true;

  programs.fish.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  programs.nano.enable = false;
  programs.git = {
    enable = true;
    config = {
      user = { name = "Oskar Wiszowaty"; email = "ppwiszu@gmail.com"; };
      init.defaultBranch = "main";
      pull.ff = "only";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      # Podpisywanie włącz lokalnie po wygenerowaniu własnego klucza SSH.
      gpg.format = "ssh";
    };
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  users.users.oskarw = {
    isNormalUser = true;
    description = "Oskar Wiszowaty";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };
  # Własne skrypty użytkownika, dowiązywane przez instalator dotfiles.
  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    pi-coding-agent curl wget fd ripgrep jq tree unzip zip htop
    openssh rsync file which gcc gnumake pkg-config
    gh zellij fzf bat delta lazygit
    bash coreutils findutils util-linux
    # Pierwsze uruchomienie z repo; kolejne odnajdują repo przez rootowy znacznik.
    (pkgs.writeShellScriptBin "setup" (builtins.readFile ../setup))
  ];
}
