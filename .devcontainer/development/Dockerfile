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

# default.nix package to install
# useful to preload packages on docker build phase, rather than on runtime
# if you have custom packages to install, simply override the default.nix recipe in your own devcontainer
ADD devcontainer-overrides/root /root/devcontainer-overrides
RUN nix-env -if /root/devcontainer-overrides

ADD entrypoint-overrides.sh ${USER_HOME_DIR}/entrypoint-overrides.sh
RUN chmod +x ${USER_HOME_DIR}/entrypoint.sh \
    && chmod u+s $(readlink -f $(command -v sudo)) \
    && chown ${USERNAME}:${USERNAME} /nix/store

# VS-Code patch so that devcontainer detects available shells
RUN echo "/nix/var/nix/profiles/default/bin/bash" >> /etc/shells \
    && echo "/nix/var/nix/profiles/default/bin/zsh" >> /etc/shells \
    && echo "/nix/var/nix/profiles/default/bin/nix-shell" >> /etc/shells