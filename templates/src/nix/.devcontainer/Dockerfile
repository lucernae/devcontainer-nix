FROM ghcr.io/lucernae/devcontainer-nix:${templateOption:imageVariant}

ENV USE_DIRENV="${templateOption:useDirenv}"
ENV USE_FLAKE="${templateOption:useFlake}"
ENV INSTALL_ROOT_PACKAGES="${templateOption:installRootPackages}"
ENV PREBUILD_DEFAULT_PACKAGE="${templateOption:prebuildDefaultPackage}"
ENV PREBUILD_NIX_SHELL="${templateOption:prebuildNixShell}"
ENV PREBUILD_FLAKE="${templateOption:prebuildFlake}"
ENV PREBUILD_FLAKE_RUN="${templateOption:prebuildFlakeRun}"
ENV PREBUILD_FLAKE_DEVELOP="${templateOption:prebuildFlakeDevelop}"
ENV ADDITIONAL_NIX_CHANNEL="${templateOption:additionalNixChannel}"
ENV ADDITIONAL_NIX_FLAKE_REGISTRY="${templateOption:additionalNixFlakeRegistry}"
ENV PREBUILD_HOME_MANAGER="${templateOption:prebuildHomeManager}"
ENV PREBUILD_HOME_MANAGER_FLAKE="${templateOption:prebuildHomeManagerFlake}"

COPY library-scripts /library-scripts

RUN bash /library-scripts/build/all.sh