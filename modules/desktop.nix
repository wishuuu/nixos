{ pkgs, inputs, ... }:
{
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  programs.thunar.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
      user = "greeter";
    };
  };
  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  fonts.packages = with pkgs; [ noto-fonts noto-fonts-color-emoji nerd-fonts.jetbrains-mono ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    discord nordpass spotify libreoffice-stable vlc
    ghostty waybar fuzzel mako hypridle
    grim slurp wl-clipboard brightnessctl playerctl pavucontrol
    networkmanagerapplet polkit_gnome
  ];
}
