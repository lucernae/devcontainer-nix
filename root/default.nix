{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "devcontainer-root";
  version = "1.0";
  src = ./.;
  propagatedBuildInputs = [
    makeWrapper
    # needed for vscode-server
    zsh
    nodejs
    gawk
    vim
    git
    sudo
    su
    which
    stdenv.cc.cc.lib
  ];
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/lib $out/bin
    # libstdc++.so.6 is needed by vscode-server's nodejs
    cp "${stdenv.cc.cc.lib}/lib64/libstdc++.so.6" $out/lib
    cp "${sudo}/bin/sudo" $out/bin/sudo
    cp "${su}/bin/su" $out/bin/su
    cp "${which}/bin/which" $out/bin/which
  '';
  meta = {
    priority = "7";
    description = "VS Code devcontainer with Nix";
    maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
  };
}
