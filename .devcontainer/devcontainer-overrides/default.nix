{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "devcontainer-overrides";
  version = "1.0";
  src = ./.;
  propagatedBuildInputs = [
    makeWrapper
    sudo
    su
    docker
    docker-compose
  ];
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    cp "${sudo}/bin/sudo" $out/bin/sudo
    cp "${su}/bin/su" $out/bin/su
    runHook postInstall
  '';
  postInstall = ''
    makeWrapper $out/bin/sudo $out/bin/docker --add-flags ${docker-client}/bin/docker
    makeWrapper $out/bin/sudo $out/bin/docker-compose --add-flags ${docker-compose}/bin/docker-compose
  '';
  meta = {
    description = "VS Code devcontainer with Nix";
    maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
  };
}
