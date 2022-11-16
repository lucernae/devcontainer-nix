{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "devcontainer";
  version = "1.0";
  src = ./.;
  propagatedBuildInputs = [ stdenv.cc.cc.lib glibc nodejs ];
  dontUnpack = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/lib $out/lib64 $out/bin
    # libstdc++.so.6 is needed by vscode-server's nodejs
    ln -s "${stdenv.cc.cc.lib}/lib64/libstdc++.so.6" $out/lib
    # ld-linux-x86-64.so.2 is needed by vscode-server's nodejs in case it install 32 bit nodejs
    ln -s "${glibc}/lib64/ld-linux-x86-64.so.2" $out/lib64
    ln -s "${glibc}/lib64/ld-linux-x86-64.so.2" $out/lib64/ld-linux.so.2
  '';
  meta = {
    description = "VS Code devcontainer with Nix";
    maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
    priority = 6;
  };
}
