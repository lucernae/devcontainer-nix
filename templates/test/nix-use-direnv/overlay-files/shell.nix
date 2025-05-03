{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = [(import ./default.nix {inherit pkgs;})];
  shellHook = ''
    export MY_HOOK="true"
  '';
}
