{ ... }:
{
  imports = [
    ../../hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/containers.nix
    ../../modules/desktop.nix
    ../../modules/updates.nix
  ];
  networking.hostName = "loki";
  networking.networkmanager.enable = true;
  users.users.oskarw.extraGroups = [ "networkmanager" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };
  zramSwap.enable = true;
  system.stateVersion = "26.05";
}
