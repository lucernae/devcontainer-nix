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
ARG INITIAL_PACKAGES="nixpkgs.direnv nixpkgs.nix-direnv nixpkgs.stdenv.cc.cc.lib nixpkgs.nodejs nixpkgs.gawk nixpkgs.findutils nixpkgs.openssh nixpkgs.gnupg"
RUN nix-env -iA ${INITIAL_PACKAGES}

# default.nix pacakage to install
# useful to preload packages on docker build phase, rather than on runtime
# if you have custom packages to install, simply override the default.nix recipe in your own devcontainer
ADD default.nix ${USER_HOME_DIR}/default.nix
RUN nix-env -if ${USER_HOME_DIR}/default.nix

ADD entrypoint.sh ${USER_HOME_DIR}/entrypoint.sh

USER root
RUN chmod +x ${USER_HOME_DIR}/entrypoint.sh
USER ${USERNAME}