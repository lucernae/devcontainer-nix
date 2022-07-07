{pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation rec {
	pname = "devcontainer";
	version = "1.0";
	src = ./.;
	propagatedBuildInputs = [
		pkgs.makeWrapper
		pkgs.kubectl
		pkgs.kubernetes-helm
	];
	dontInstall = true;
	meta = {
		description = "VS Code devcontainer with Nix";
		maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
	};
}
