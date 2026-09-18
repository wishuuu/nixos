{
  description = "Środowisko .NET 10";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = [ pkgs.dotnet-sdk_10 pkgs.pkg-config ];
            DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet";
            DOTNET_CLI_TELEMETRY_OPTOUT = "1";
          };
        });
    };
}
