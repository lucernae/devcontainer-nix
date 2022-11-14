ARG IMAGE_TAG=latest
# any docker image with nix will do. 
# we basically want to use the nix tools then throw it away
FROM ghcr.io/lucernae/devcontainer-nix:${IMAGE_TAG} AS build

USER root

RUN mkdir -p /usr/share/nixos-build

WORKDIR /usr/share/nixos-build

ADD configuration.nix configuration.nix
ADD systemd-docker.nix systemd-docker.nix
RUN nix-build systemd-docker.nix
RUN mkdir -p ./extracted \
    && tar -xf result/tarball/nixos-system-x86_64-linux.tar -C extracted
    
# we have no way of passing link location to the next stage, so we pass 
# it as files
RUN echo "$(readlink ./extracted/rootfs)" > current-system-closure-path.txt
# copy rootfs
FROM scratch AS final
COPY --from=build /usr/share/nixos-build/extracted/nix /nix
# pass the bootstrap configuration.nix in case someone needed it.
COPY --from=build /usr/share/nixos-build/extracted/etc/nixos/configuration.nix /etc/nixos/bootstrap-configuration.nix
# needed the /bin binaries temporarily to get shell executable in scratch
COPY --from=build /usr/share/nixos-build/extracted/rootfs/sw/bin /bin
# retrieve the nix closure path for the init bootstrap
COPY --from=build /usr/share/nixos-build/current-system-closure-path.txt /path.txt

# creating symlink for systemd init at container boot
RUN mkdir -p /usr/sbin \
    && ln -s "$(cat /path.txt)/init" /usr/sbin/init \
    && rm -rf /path.txt /bin
# The last step is the clean up


# initial path
ENV PATH=/bin:/usr/sbin
CMD [ "/usr/sbin/init" ]