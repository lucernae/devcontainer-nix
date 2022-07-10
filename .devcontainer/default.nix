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
		docker-compose
	];
	dontBuild = true;
	installPhase = ''
		mkdir -p $out/lib
		# libstdc++.so.6 is needed by vscode-server's nodejs
		cp "${stdenv.cc.cc.lib}/lib64/libstdc++.so.6" $out/lib
	'';
	meta = {
		description = "VS Code devcontainer with Nix";
		maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
	};
}
