ARG IMAGE_TAG=latest
FROM ghcr.io/lucernae/devcontainer-nix:${IMAGE_TAG}

# In the case that users need non-root user
# See https://aka.ms/vscode-remote/containers/non-root-user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USER_HOME_DIR=/home/${USERNAME}

# Space separated list of default packages to install to be available on default profile
# This is needed for process that is executed before direnv can be hooked
# nodejs is needed to support vscode devcontainers

USER root
ARG MAIN_NIX_CHANNEL=https://nixos.org/channels/nixos-22.05
# We use nixpkgs as name because in devcontainers we are going to use it as package manager instead of the OS
ARG MAIN_NIX_CHANNEL_NAME=nixpkgs

RUN mkdir -p "/root" && touch "/root/.nix-channels" && \
    if [[ ! -f "/root/.nix-profile" ]]; then ln -sf /nix/var/nix/profiles/default "/root/.nix-profile"; fi && \
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
  nix-channel --add ${MAIN_NIX_CHANNEL} ${MAIN_NIX_CHANNEL_NAME} && \
  nix-channel --update

ARG INITIAL_PACKAGES="nixpkgs.direnv nixpkgs.nix-direnv nixpkgs.stdenv.cc.cc.lib nixpkgs.nodejs nixpkgs.gawk nixpkgs.findutils nixpkgs.openssh nixpkgs.gnupg"
RUN nix-env -iA ${INITIAL_PACKAGES}

# default.nix pacakage to install
# useful to preload packages on docker build phase, rather than on runtime
# if you have custom packages to install, simply override the default.nix recipe in your own devcontainer
ADD devcontainer-overrides ${USER_HOME_DIR}/devcontainer-overrides
RUN nix-env -if ${USER_HOME_DIR}/devcontainer-overrides

ADD entrypoint.sh ${USER_HOME_DIR}/entrypoint.sh
RUN chmod +x ${USER_HOME_DIR}/entrypoint.sh \
    && chmod u+s $(readlink -f $(command -v sudo)) \
    && echo "root ALL=(root) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "#includedir /etc/sudoers.d" >> /etc/sudoers \
    && mkdir -p /etc/sudoers.d \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && chown ${USERNAME}:${USERNAME} /nix/store

USER ${USERNAME}