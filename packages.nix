{ pkgs ? import <nixpkgs> { } }:
with pkgs;
buildEnv {
  name = "devcontainer-packages";
  paths = [
    vim
    git
    direnv # needed for direnv hook
    nix-direnv # needed for nix-direnv hook
    acl # needed to change /tmp default ACL for nix build process
    ncurses
    nodejs # to support vscode devcontainers process/hooks
    gawk
    findutils
    openssh
    gnupg
  ];
  meta = {
    description = "VS Code devcontainer packages Nix";
    maintainers = [ "Rizky Maulana Nugrah       a <lana.pcfre@gmail.com>" ];
    priority = 6;
  };
}
