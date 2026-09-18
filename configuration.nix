# Punkt wejścia dla narzędzi oczekujących configuration.nix.
# Wdrażaj przez flake: sudo nixos-rebuild switch --flake .#loki
{ ... }:
{
  imports = [ ./hosts/loki ];
}
