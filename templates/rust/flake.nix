{
  description = "Rust stable/nightly zarządzany przez rustup";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }:
    let systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ rustup pkg-config openssl ];
            # rustup z nixpkgs zapewnia narzędzia działające na NixOS.
            # Wersję przypnij w rust-toolchain.toml; rustup pobiera ją z sieci.
          };
        });
    };
}
