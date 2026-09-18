{
  description = "Modułowa konfiguracja NixOS: loki i WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations = {
      loki = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/loki ];
      };
      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [ inputs.nixos-wsl.nixosModules.default ./hosts/wsl ];
      };
    };
    templates = {
      dotnet = { path = ./templates/dotnet; description = ".NET 10"; };
      rust = { path = ./templates/rust; description = "Rust przez rustup: stable/nightly"; };
      web = { path = ./templates/web; description = "Bun i Node.js LTS"; };
    };
  };
}
