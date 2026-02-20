{
  description = "AI Agentic NixOS Devcontainer Demo - Practical home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgsUnstable, home-manager }:
    {
      # Home Manager configurations for the vscode user
      homeConfigurations = {
        # Configuration for x86_64 systems (Intel/AMD)
        vscode = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home.nix
            {
              # Ensure home directory and username match the container
              home.username = "vscode";
              home.homeDirectory = "/home/vscode";
            }
          ];
        };

        # Configuration for ARM64 systems (Apple Silicon, ARM servers)
        vscode-aarch64 = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          modules = [
            ./home.nix
            {
              home.username = "vscode";
              home.homeDirectory = "/home/vscode";
            }
          ];
        };
      };
    };
}
