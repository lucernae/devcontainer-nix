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
RUN chmod +x ${USER_HOME_DIR}/entrypoint.sh

USER ${USERNAME}

RUN mkdir -p "${USER_HOME_DIR}" && touch "${USER_HOME_DIR}/.nix-channels" && \
    if [[ ! -f "${USER_HOME_DIR}/.nix-profile" ]]; then ln -sf /nix/var/nix/profiles/default "${USER_HOME_DIR}/.nix-profile"; fi && \
  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
  nix-channel --add ${MAIN_NIX_CHANNEL} ${MAIN_NIX_CHANNEL_NAME} && \
  nix-channel --update

WORKDIR "${USER_HOME_DIR}"

# Space separated list of default packages to install to be available on default profile
# This is needed for process that is executed before direnv can be hooked
# nodejs is needed to support vscode devcontainers
ARG INITIAL_PACKAGES="nixpkgs.direnv nixpkgs.nix-direnv nixpkgs.stdenv.cc.cc.lib nixpkgs.nodejs nixpkgs.gawk nixpkgs.findutils nixpkgs.openssh nixpkgs.gnupg"
RUN nix-env -iA ${INITIAL_PACKAGES}

# Direnv bashrc hook
RUN echo ". ${USER_HOME_DIR}/.nix-profile/etc/profile.d/nix.sh" >> "${USER_HOME_DIR}/.bashrc" && \
    . "${USER_HOME_DIR}/.bashrc" && \
    echo 'eval "$(direnv hook bash)"' >> "${USER_HOME_DIR}/.bashrc"

# default.nix pacakage to install
# useful to preload packages on docker build phase, rather than on runtime
# if you have custom packages to install, simply override the default.nix recipe in your own devcontainer
ADD default.nix ${USER_HOME_DIR}/default.nix
RUN nix-env -if ${USER_HOME_DIR}/default.nix

# Entrypoint takes directory to activate direnv too as first parameter. The rest of the parameters is the command executed by direnv
ENTRYPOINT [ "${USER_HOME_DIR}/entrypoint.sh", "${USER_HOME_DIR}" ]
CMD [ "bash", "-c", "while sleep 1000; do :; done" ]