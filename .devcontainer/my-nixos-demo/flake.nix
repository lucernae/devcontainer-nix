{
  description = "AI Agentic NixOS Devcontainer Demo - Practical home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgsUnstable, flake-utils, home-manager }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Shared Home Manager configuration module
        mkHomeModule = username: homeDirectory: { pkgs, ... }: {
          imports = [ ./home.nix ];
          home.username = username;
          home.homeDirectory = homeDirectory;
        };
      in
      {
        # Home configurations for both vscode and root users
        packages.homeConfigurations = {
          vscode = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.${system};
            modules = [ (mkHomeModule "vscode" "/home/vscode") ];
          };

          root = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.${system};
            modules = [ (mkHomeModule "root" "/root") ];
          };
        };

        # Development shell for working with the flake
        devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            home-manager.packages.${system}.home-manager
          ];
        };
      }
    );
}
