{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "devcontainer";
  version = "1.0";
  src = ./.;
  propagatedBuildInputs = [
    makeWrapper
    stdenv.cc.cc.lib
  ];
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/lib $out/bin
    # libstdc++.so.6 is needed by vscode-server's nodejs
    cp "${stdenv.cc.cc.lib}/lib64/libstdc++.so.6" $out/lib
  '';
  meta = {
    description = "VS Code devcontainer with Nix";
    maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
    priority = 6;
  };
}
