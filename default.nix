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
  installPhase = if stdenv.hostPlatform.isLinux then ''
    mkdir -p $out/lib $out/bin
    # libstdc++.so.6 is needed by vscode-server's nodejs
    # ln -sf "${stdenv.cc.cc.lib}/lib64/libstdc++.so.6" $out/lib
    # # ld-linux-x86-64.so.2 is needed by vscode-server's nodejs in case it install 32 bit nodejs
    # ln -s "${glibc}/lib64/ld-linux-x86-64.so.2" $out/lib64
    # ln -s "${glibc}/lib64/ld-linux-x86-64.so.2" $out/lib64/ld-linux.so.2
    # # ld-linux-aarch64.so.1 is needed by vscode-server's in arm architecture
    # ln -s "${glibc}/lib/ld-linux-aarch64.so.1" $out/lib
    # ln -s "${glibc}/lib/ld-linux-aarch64.so.1" $out/lib/ld-linux.so.1
  '' else "";
  meta = {
    description = "VS Code devcontainer with Nix";
    maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
    priority = 6;
  };
}
