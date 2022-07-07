ARG NIXOS_VERSION=nixos-22.05
FROM nixpkgs/devcontainer:${NIXOS_VERSION}

# In the case that users need non-root user
# See https://aka.ms/vscode-remote/containers/non-root-user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME

RUN chown -R $USER_UID:$USER_GID /nix
ARG MAIN_NIX_CHANNEL=https://nixos.org/channels/nixos-22.05
# We use nixpkgs as name because in devcontainers we are going to use it as package manager instead of the OS
ARG MAIN_NIX_CHANNEL_NAME=nixpkgs

ARG USER_HOME_DIR=/home/${USERNAME}

# default entrypoint
ADD entrypoint.sh ${USER_HOME_DIR}/entrypoint.sh
RUN chmod +x ${USER_HOME_DIR}/entrypoint.sh && \
  ln -sf /bin/bash /bin/sh

USER ${USERNAME}

RUN mkdir -p "${USER_HOME_DIR}" && touch "${USER_HOME_DIR}/.nix-channels" && \
    if [[ ! -f "${USER_HOME_DIR}/.nix-profile" ]]; then ln -sf /nix/var/nix/profiles/default "${USER_HOME_DIR}/.nix-profile"; fi && \
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
  nix-channel --add ${MAIN_NIX_CHANNEL} ${MAIN_NIX_CHANNEL_NAME} && \
  nix-channel --update

WORKDIR "${USER_HOME_DIR}"

# Space separated list of default packages to install
ARG INITIAL_PACKAGES="nixpkgs.direnv nixpkgs.nix-direnv"
RUN nix-env -iA ${INITIAL_PACKAGES}

# Direnv bashrc hook
RUN echo ". ${USER_HOME_DIR}/.nix-profile/etc/profile.d/nix.sh" >> "${USER_HOME_DIR}/.bashrc" && \
    . "${USER_HOME_DIR}/.bashrc" && \
    echo 'eval "$(direnv hook bash)"' >> "${USER_HOME_DIR}/.bashrc"

# default.nix pacakage to install
ADD default.nix ${USER_HOME_DIR}/default.nix
RUN nix-env -if ${USER_HOME_DIR}/default.nix

ENTRYPOINT [ "${USER_HOME_DIR}/entrypoint.sh", "${USER_HOME_DIR}" ]
CMD [ "bash", "-c", "tail -f /dev/null" ]