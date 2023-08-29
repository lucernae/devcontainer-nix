{ pkgs ? import <nixpkgs> { } }:
with pkgs;
buildEnv {
  name = "devcontainer-packages";
  paths = [
    zsh
    vim
    git
    direnv # needed for direnv hook
    nix-direnv # needed for nix-direnv hook
    ncurses
    nodejs # to support vscode devcontainers process/hooks
    gawk
    findutils
    openssh
    gnupg
    getent
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    acl # needed to change /tmp default ACL for nix build process
  ];
  meta = {
    description = "VS Code devcontainer packages Nix";
    maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
    priority = 6;
  };
}
