{
  description = "home-manager flake";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Flake utils
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {self, nixpkgs, home-manager, flake-utils, ...}:
    let
        inherit (flake-utils.lib) system eachSystem;
    in
    eachSystem [
        system.x86_64-linux
        system.aarch64-linux
    ] (
        system: 
            let
                pkgs = import nixpkgs {
                    inherit system;
                    config.allowUnfree = true;
                };
            in
            rec {
                formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
            packages.homeConfigurations.vscode = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;

                # Specify your home configuration modules here, for example,
                # the path to your home.nix.
                modules = [
                ./vscode.nix
                ];
            };
        }
    );
}
