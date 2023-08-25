{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
        flake-utils.url = "github:numtide/flake-utils";
        # customized from github:nix-community/docker-nixpkgs to support flake
        docker-nixpkgs.url = "github:lucernae/docker-nixpkgs/flake-devcontainer";
    };
    outputs = {self, nixpkgs, docker-nixpkgs, flake-utils}:
        flake-utils.lib.eachDefaultSystem (system: 
        let
            pkgs = nixpkgs.legacyPackages.${system};
        in
        {
            packages = {
                base-devcontainer = {
                    "nixos-23.05" = docker-nixpkgs.docker-nixpkgs.${system}."nixos-23.05".devcontainer;
                    "nixos-unstable" = docker-nixpkgs.docker-nixpkgs.${system}."nixos-unstable".devcontainer;
                    default = docker-nixpkgs.docker-nixpkgs.${system}."nixos-23.05".devcontainer;
                };
                devcontainer-root = (import ./root/default.nix) {
                    inherit pkgs;
                };
                devcontainer-packages = (import ./packages.nix) {
                    inherit pkgs;
                };
                devcontainer = (import ./default.nix) {
                    inherit pkgs;
                };
            };
            devShell = (import ./shell.nix) {
                inherit pkgs;
            };
        });
}