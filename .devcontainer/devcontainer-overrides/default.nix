{pkgs ? import <nixpkgs> {} }:
with pkgs;
stdenv.mkDerivation rec {
	pname = "devcontainer-overrides";
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
		sudo
		su
		which
	];
	dontBuild = true;
	installPhase = ''
		mkdir -p $out/lib $out/bin
		# libstdc++.so.6 is needed by vscode-server's nodejs
		cp "${stdenv.cc.cc.lib}/lib64/libstdc++.so.6" $out/lib
		cp "${sudo}/bin/sudo" $out/bin/sudo
		cp "${su}/bin/su" $out/bin/su
		cp "${which}/bin/which" $out/bin/which

		runHook postInstall
	'';
	postInstall = ''
		makeWrapper $out/bin/sudo $out/bin/docker --add-flags ${docker-client}/bin/docker
		makeWrapper $out/bin/sudo $out/bin/docker-compose --add-flags ${docker-client}/bin/docker-compose
	'';
	meta = {
		description = "VS Code devcontainer with Nix";
		maintainers = [ "Rizky Maulana Nugraha <lana.pcfre@gmail.com>" ];
	};
}
