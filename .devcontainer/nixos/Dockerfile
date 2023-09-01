ARG NIXOS_VERSION=nixos-23.05
# any docker image with nix will do. 
# we basically want to use the nix tools then throw it away
FROM ghcr.io/lucernae/nix-community/nixpkgs/devcontainer:${NIXOS_VERSION} AS build

USER root

ADD ./nix.conf /etc/nix/nix.conf

RUN mkdir -p /usr/share/nixos-build \
    && nix-channel --update

WORKDIR /usr/share/nixos-build

ADD . /usr/share/nixos-build/.
RUN nix-build container-tarball.nix
RUN mkdir -p ./extracted \
    && export NIX_ARCH=$(nix eval --impure --raw --expr 'builtins.currentSystem') \
    && tar -xf result/tarball/nixos-system-${NIX_ARCH}.tar -C extracted
    
# we have no way of passing link location to the next stage, so we pass 
# it as files
RUN echo "$(readlink ./extracted/rootfs)" > current-system-closure-path.txt

# copy library needed by vscode remote server from debian
FROM mcr.microsoft.com/devcontainers/base as linux-lib

# conditional check if the image used is aarch64, then create fake directory 
# /lib32 and /lib64 that is only presents in x86_64
RUN mkdir -p /lib /lib32 /lib64

# copy rootfs
# for some reason, scratch doesn't work for vscode devcontainer
FROM busybox AS final
USER root
COPY --from=build /usr/share/nixos-build/extracted/nix /nix
# pass the bootstrap configuration.nix in case someone needed it.
COPY --from=build /usr/share/nixos-build/etc/nixos/configuration.nix /etc/nixos/bootstrap-configuration.nix
COPY --from=build /usr/share/nixos-build/etc/nixos/devcontainer-patch.nix /etc/nixos/devcontainer-patch.nix
# needed the /bin binaries temporarily to get shell executable in scratch
COPY --from=build /usr/share/nixos-build/extracted/rootfs/sw/bin /bin
# retrieve the nix closure path for the init bootstrap
COPY --from=build /usr/share/nixos-build/current-system-closure-path.txt /path.txt

# retrieve standard linux library for compatibility with vscode remote-server
COPY --from=linux-lib /lib /lib
COPY --from=linux-lib /lib32 /lib32
COPY --from=linux-lib /lib64 /lib64

# creating symlink for systemd init at container boot
RUN $(cat /path.txt)/activate || true \
    && rm -rf /path.txt
# The last step is the clean up

# initial path
ENV PATH=/bin:/usr/sbin
CMD [ "/usr/sbin/init" ]