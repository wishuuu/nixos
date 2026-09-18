{ config, ... }:
{
  # /etc/nixos to osobna, należąca do roota kopia konfiguracji (patrz README).
  system.autoUpgrade = {
    enable = true;
    flake = "path:/etc/nixos#${config.networking.hostName}";
    dates = "Sun *-*-* 04:00:00";
    randomizedDelaySec = "45min";
    persistent = true;
    allowReboot = false;
    flags = [ "--refresh" "--update-input" "nixpkgs" "--no-write-lock-file" ];
  };
}
