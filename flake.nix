{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
        flake-utils.url = "github:numtide/flake-utils";
    };
    outputs = {self, nixpkgs, flake-utils}:
        flake-utils.lib.eachDefaultSystem (system: 
        let
            pkgs = nixpkgs.legacyPackages.${system};
        in
        {
            packages = {
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