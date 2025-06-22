FROM ghcr.io/lucernae/devcontainer-nix:flake

ENV USE_DIRENV="true" \
    USE_FLAKE="true" \
    INSTALL_ROOT_PACKAGES="" \
    PREBUILD_DEFAULT_PACKAGE="default.nix" \
    PREBUILD_NIX_SHELL="shell.nix" \
    PREBUILD_FLAKE="" \
    PREBUILD_FLAKE_RUN="" \
    PREBUILD_FLAKE_DEVELOP="" \
    ADDITIONAL_NIX_CHANNEL="" \
    ADDITIONAL_NIX_FLAKE_REGISTRY="" \
    PREBUILD_HOME_MANAGER="" \
    PREBUILD_HOME_MANAGER_FLAKE=""

# Switch to root user to execute commands requiring root permissions
USER root

# Create script directories and prepare environment in a single layer
RUN set -ex \
    && mkdir -p /root/.nix-profile /root/.nix-defexpr /tmp/library-scripts/runtime/ /usr/local/lib/library-scripts/runtime/ \
    && [ ! -e /root/.nix-channels ] || rm -rf /root/.nix-channels \
    && [ -L /root/.nix-profile ] || ln -s /nix/var/nix/profiles/per-user/root/profile /root/.nix-profile \
    && [ -L /root/.nix-defexpr/channels ] || ln -s /nix/var/nix/profiles/per-user/root/channels /root/.nix-defexpr \
    && [ -L /root/.nix-channels ] || ln -s /nix/var/nix/profiles/per-user/root/channels /root/.nix-channels \
    && if [ -e /nix/var/nix/profiles/per-user/root/channels ] && [ ! -d /nix/var/nix/profiles/per-user/root/channels ]; then \
          rm -rf /nix/var/nix/profiles/per-user/root/channels; \
       fi \
    && mkdir -p /nix/var/nix/profiles/per-user/root/channels \
    && if [ ! -f /etc/os-release ]; then \
          echo "NAME=NixOS" > /etc/os-release && \
          echo "VERSION=23.05" >> /etc/os-release && \
          echo "ID=nixos" >> /etc/os-release; \
       fi \
    && chown -R vscode:vscode /tmp/library-scripts /usr/local/lib/library-scripts

# Add fallback for os-release file content verification
RUN cat /etc/os-release || echo "os-release file is missing"

# Copy configuration and scripts in a single layer
COPY ./nix.conf /etc/nix/nix.conf
COPY ./library-scripts /tmp/library-scripts/
COPY ./library-scripts /usr/local/lib/library-scripts/

# Prepare scripts and run build
RUN set -ex \
    && chmod +x /tmp/library-scripts/runtime/*.sh \
    && chmod +x /usr/local/lib/library-scripts/runtime/*.sh \
    && ln -sf /usr/local/lib/library-scripts/runtime/postCreateCommand.sh /tmp/library-scripts/runtime/postCreateCommand.sh \
    && ls -l /tmp/library-scripts/runtime/ \
    && ls -l /usr/local/lib/library-scripts/runtime/ \
    # Switch to vscode user temporarily for the build script
    && su vscode -c 'bash /usr/local/lib/library-scripts/build/all.sh' \
    # Clean up unnecessary files to reduce image size
    && rm -rf /tmp/* \
    && nix-store --gc \
    && nix-collect-garbage -d

# Switch back to vscode user for container usage
USER vscode
