#!/usr/bin/env bash
# this script is used to reduce package priority from the setup process and base docker image
# this way, user can override these packages in their own setup
packages=('gcc' 'git-minimal' 'gnugrep' 'gnused' 'gnutar' 'gzip' 'iana-etc' 'iproute2' 'less' 'nss-cacert' 'procps' 'shadow' 'xz')
for p in "${packages[@]}"
do
    nix-env --set-flag priority 7 $p
done
