{
  description = "AI Agentic NixOS Devcontainer System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgsUnstable, flake-utils }:
    let
      # Create overlay to make unstable packages available
      mkOverlay = system: [
        (final: prev: {
          unstable = import nixpkgsUnstable {
            inherit system;
            config.allowUnfree = true;
          };
        })
      ];

      # Create NixOS configuration for a specific system
      mkNixosConfig = system: nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          # Import the existing configuration.nix
          ./configuration.nix

          # Apply overlays to make unstable packages available
          { nixpkgs.overlays = mkOverlay system; }

          # Additional flake-specific configuration
          {
            # Set the hostname to match the flake configuration name
            networking.hostName = nixpkgs.lib.mkForce "devcontainer";

            # Ensure experimental features are enabled
            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            # Allow unfree packages system-wide
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };

      # Generate nixosConfigurations for all systems using flake-utils
      allNixosConfigurations = builtins.listToAttrs (
        map (system: {
          name = "devcontainer-${system}";
          value = mkNixosConfig system;
        }) flake-utils.lib.defaultSystems
      );
    in
    {
      # NixOS configurations for all systems
      nixosConfigurations = allNixosConfigurations // {
        # Default alias for x86_64-linux
        devcontainer = allNixosConfigurations."devcontainer-x86_64-linux";
      };
    };
}
