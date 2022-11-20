{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "devcontainer-root-overrides";
  version = "1.0";
  src = ./.;
  propagatedBuildInputs = [ makeWrapper sudo su docker-client docker-compose cacert ];
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    ln -s "${sudo}/bin/sudo" $out/bin/sudo
    ln -s "${su}/bin/su" $out/bin/su
    runHook postInstall
  '';
  postInstall = ''
    makeWrapper $out/bin/sudo $out/bin/docker --add-flags ${docker-client}/bin/docker --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
    makeWrapper $out/bin/sudo $out/bin/docker-compose --add-flags ${docker-compose}/bin/docker-compose --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
  '';
  meta = {
    priority = "4";
    description = "VS Code devcontainer with Nix";
    maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
  };
}
