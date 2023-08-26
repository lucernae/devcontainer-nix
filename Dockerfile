ARG NIXOS_VERSION=nixos-22.05
FROM ghcr.io/lucernae/nix-community/nixpkgs/devcontainer:${NIXOS_VERSION}

# In the case that users need non-root user
# See https://aka.ms/vscode-remote/containers/non-root-user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USER_HOME_DIR=/home/${USERNAME}

# Root-user setup block

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME

ARG MAIN_NIX_CHANNEL=https://nixos.org/channels/nixos-22.05
# We use nixpkgs as name because in devcontainers we are going to use it as package manager instead of the OS
ARG MAIN_NIX_CHANNEL_NAME=nixpkgs

# Add bootstrap NIX_CONFIG if necessary
ARG NIX_CONFIG=
ADD nix.conf /etc/nix/nix.conf
RUN echo $'\n'"${NIX_CONFIG}" >> /etc/nix/nix.conf

RUN mkdir -p "/root" && touch "/root/.nix-channels" && \
    if [[ ! -f "/root/.nix-profile" ]]; then ln -sf /nix/var/nix/profiles/default "/root/.nix-profile"; fi && \
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
  nix-channel --add ${MAIN_NIX_CHANNEL} ${MAIN_NIX_CHANNEL_NAME} && \
  nix-channel --update

RUN chown $USER_UID:$USER_GID /nix \
  && chown $USER_UID:$USER_GID /nix/store \
  && chown -R $USER_UID:$USER_GID /nix/var

# Root setup for devcontainers

# /root/default.nix package to install
# useful to preload packages on docker build phase, rather than on runtime
# if you have custom packages to install, simply override the root/default.nix recipe in your own devcontainer
# root packages here are packages that requires root privileges to install. Like sudo.
ADD root/default.nix /root/default.nix
RUN nix-env -if /root/default.nix

# default entrypoint
ADD entrypoint.sh ${USER_HOME_DIR}/entrypoint.sh
RUN chmod +x ${USER_HOME_DIR}/entrypoint.sh \
    && chmod u+s $(readlink -f $(command -v sudo)) \
    && echo "root ALL=(root) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "#includedir /etc/sudoers.d" >> /etc/sudoers \
    && mkdir -p /etc/sudoers.d \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && chown ${USERNAME}:${USERNAME} /nix/store

# VS-Code patch so that devcontainer detects available shells
RUN echo "/nix/var/nix/profiles/default/bin/bash" >> /etc/shells \
    && echo "/nix/var/nix/profiles/default/bin/zsh" >> /etc/shells \
    && echo "/nix/var/nix/profiles/default/bin/nix-shell" >> /etc/shells

# Userspace block
USER ${USERNAME}

RUN mkdir -p "${USER_HOME_DIR}" && touch "${USER_HOME_DIR}/.nix-channels" && \
    if [[ ! -f "${USER_HOME_DIR}/.nix-profile" ]]; then ln -sf /nix/var/nix/profiles/default "${USER_HOME_DIR}/.nix-profile"; fi && \
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
  nix-channel --add ${MAIN_NIX_CHANNEL} ${MAIN_NIX_CHANNEL_NAME} && \
  nix-channel --update

WORKDIR "${USER_HOME_DIR}"

# List of default packages to install to be available on default profile
# This is needed for process that is executed before direnv can be hooked
ADD packages.nix ${USER_HOME_DIR}/packages.nix
RUN nix-env -if ${USER_HOME_DIR}/packages.nix

# Direnv bashrc hook
RUN echo ". ${USER_HOME_DIR}/.nix-profile/etc/profile.d/nix.sh" >> "${USER_HOME_DIR}/.bashrc" && \
    . "${USER_HOME_DIR}/.bashrc" && \
    echo 'eval "$(direnv hook bash)"' >> "${USER_HOME_DIR}/.bashrc" && \
    echo 'eval "$(direnv hook zsh)"' >> "${USER_HOME_DIR}/.zshrc"

# default.nix package to install
# useful to preload packages on docker build phase, rather than on runtime
# if you have custom packages to install, simply override the default.nix recipe in your own devcontainer
ADD default.nix ${USER_HOME_DIR}/default.nix
RUN nix-env -if ${USER_HOME_DIR}/default.nix

# Home manager support
ARG HOME_MANAGER_CHANNEL=https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz 
ARG HOME_MANAGER_CHANNEL_NAME=home-manager

ENV NIX_PATH=$USER_HOME_DIR/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH} \
    USER=${USERNAME} \
    HOME=${USER_HOME_DIR}

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix.sh \
    && nix-channel --add ${HOME_MANAGER_CHANNEL} ${HOME_MANAGER_CHANNEL_NAME} \
    && export NIX_PATH=$USER_HOME_DIR/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH} \
    && nix-channel --update \
    && mkdir -p ${USER_HOME_DIR}/.config/nixpkgs \
    && nix-shell '<home-manager>' -A install \
    && chown -R ${USERNAME}:${USERNAME} ${USER_HOME_DIR}/.config

# post build setup
ADD default-packages-priority.sh ${USER_HOME_DIR}/default-packages-priority.sh
RUN sudo chmod +x ${USER_HOME_DIR}/default-packages-priority.sh \
    && ${USER_HOME_DIR}/default-packages-priority.sh

# Entrypoint takes directory to activate direnv as first parameter. The rest of the parameters is the command executed by direnv
ENTRYPOINT [ "./entrypoint.sh", "." ]
CMD [ "bash", "-c", "while sleep 1000; do :; done" ]