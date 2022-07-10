{pkgs ? import <nixpkgs> {} }:
with pkgs;
stdenv.mkDerivation rec {
	pname = "devcontainer";
	version = "1.0";
	src = ./.;
	propagatedBuildInputs = [
		makeWrapper
		# needed for vscode-server
		nodejs
		gawk
		vim
		git
		stdenv.cc.cc.lib
	];
	dontBuild = true;
	dontInstall = true;
	meta = {
		description = "VS Code devcontainer with Nix";
		maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
	};
}
