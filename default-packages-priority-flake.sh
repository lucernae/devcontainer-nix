#!/usr/bin/env bash
# this script is used to reduce package priority from the setup process and base docker image
# this way, user can override these packages in their own setup
set -e
echo "package list"
echo "nix version: $(nix --version)"
nix profile list
packages=('coreutils' 'procps' 'gcc' 'git-minimal' 'gnugrep' 'gnused' 'gnutar' 'gzip' 'iana-etc' 'iproute2' 'less' 'shadow' 'xz')
for p in "${packages[@]}"
do
    # uninstall the package and use flake version to control priority
    nix-env -e $p
done

# reinstalling nix so that nix profile can set priority
nix-env -iA nixpkgs.nix nixpkgs.cacert

echo "uninstalling done"
nix profile list

packages=('coreutils' 'gcc' 'gitMinimal' 'gnugrep' 'gnused' 'gnutar' 'gzip' 'iana-etc' 'iproute2' 'less' 'shadow' 'xz')

# test nix flake version, if priority flag available
if nix profile install --priority 8 nixpkgs#coreutils; then
    priorityFlag=true
else
    priorityFlag=""
fi

for p in "${packages[@]}"
do
    if [[ -n "$priorityFlag" ]]; then
        nix profile install --priority 7 "nixpkgs#$p"
    else
        nix profile install "nixpkgs#$p"
    fi
done