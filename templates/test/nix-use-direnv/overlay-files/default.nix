{pkgs ? import <nixpkgs> {}}:
pkgs.buildEnv {
    name="my-package";
    paths = [
        pkgs.hello
    ];
}