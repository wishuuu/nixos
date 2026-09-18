{ ... }:
{
  virtualisation.docker.enable = true;
  users.users.oskarw.extraGroups = [ "docker" ];
}
