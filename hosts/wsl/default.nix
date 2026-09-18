{ ... }:
{
  imports = [ ../../modules/base.nix ../../modules/containers.nix ../../modules/updates.nix ];
  wsl.enable = true;
  wsl.defaultUser = "oskarw";
  networking.hostName = "wsl";
  # Docker działa wewnątrz WSL; nie włączaj równolegle integracji Docker Desktop.
  # Aktualizacje wymagają rootowej kopii flake w /etc/nixos, jak na laptopie.
  system.stateVersion = "26.05";
}
