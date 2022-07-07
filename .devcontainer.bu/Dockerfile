ARG IMAGE_TAG=latest
FROM ghcr.io/lucernae/devcontainer-nix:${IMAGE_TAG}

# In the case that users need non-root user
# See https://aka.ms/vscode-remote/containers/non-root-user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USER_HOME_DIR=/home/${USERNAME}

# default.nix pacakage to install
# useful to preload packages on docker build phase, rather than on runtime
# if you have custom packages to install, simply override the default.nix recipe in your own devcontainer
ADD default.nix ${USER_HOME_DIR}/default.nix
RUN nix-env -if ${USER_HOME_DIR}/default.nix
RUN nix-env -iA nixpkgs.gawk