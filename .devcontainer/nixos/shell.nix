{pkgs ? import <nixpkgs> {}}: let
  local-shell =
    if builtins.pathExists ./local-shell.nix
    then (import ./local-shell.nix {inherit pkgs;})
    else null;
in
  with pkgs;
    mkShell {
      inputsFrom = [] ++ lib.optionals (!isNull local-shell) [local-shell];
      buildInputs = [zsh nixfmt yq skopeo python3 gzip file];
      shellHook = ''
        echo ""
        echo "---------------------------------------------------------------"
        echo "You are using default Nix-shell in this project."
        echo "Use: \"direnv status\" to check if you are using correct direnv"
        echo "Use: \"printenv\" to print current environment variable"
        echo "---------------------------------------------------------------"
        echo ""
      '';
    }
