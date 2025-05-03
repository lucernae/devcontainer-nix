{pkgs ? import <nixpkgs> {}}:
with pkgs;
  stdenv.mkDerivation rec {
    pname = "devcontainer";
    version = "1.0";
    src = ./.;
    propagatedBuildInputs = [stdenv.cc.cc.lib glibc nodejs];
    dontUnpack = true;
    dontBuild = true;
    installPhase =
      ''
        mkdir -p $out/lib $out/lib64 $out/bin
        mkdir -p lib lib64
        # libstdc++.so.6 is needed by vscode-server's nodejs
        ln -s "${stdenv.cc.cc.lib}/lib64/libstdc++.so.6" $out/lib
        ln -s "${glibc}/lib/libgcc_s.so.1 $out/lib
        ln -s "${glibc}/lib/libgcc_s.so.1 lib/libgcc_s.so.1
        ln -s "${glibc}/lib/libdl.so.2 $out/lib
        ln -s "${glibc}/lib/libdl.so.2 lib/libdl.so.2
      ''
      + (
        if stdenv.hostPlatform.isAarch64
        then ''
          # ld-linux-aarch64.so.1 is needed by vscode-server's in arm architecture
          mkdir -p lib
          ln -s "${glibc}/lib/ld-linux-aarch64.so.1" lib/ld-linux-aarch64.so.1
          ln -s "${glibc}/lib/ld-linux-aarch64.so.1" lib/ld-linux.so.1
          ln -sf "${stdenv.cc.cc.lib}/lib/libstdc++.so.6" lib/libstdc++.so.6
        ''
        else ""
      )
      + (
        if stdenv.hostPlatform.isx86_64
        then ''
          # allow ubuntu ELF binaries to run. VSCode copies it's own.
          mkdir -p lib64
          ln -s ${glibc}/lib64/ld-linux-x86-64.so.2 lib64/ld-linux-x86-64.so.2
          # ld-linux-x86-64.so.2 is needed by vscode-server's nodejs in case it install 32 bit nodejs
          ln -s "${glibc}/lib64/ld-linux-x86-64.so.2" lib64/ld-linux.so.2
          ln -sf "${stdenv.cc.cc.lib}/lib64/libstdc++.so.6" lib64/libstdc++.so.6
        ''
        else ""
      );
    meta = {
      description = "VS Code devcontainer with Nix";
      maintainers = ["Rizky Maulana Nugraha <lana.pcfre@gmail.com>"];
      priority = 6;
    };
  }
