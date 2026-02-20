{
  system ? builtins.currentSystem,
  pkgs ? import <nixpkgs> { inherit system; },
}:
let
  container = (import ./container-definition.nix { inherit system pkgs; }).container;

  # Pull the Microsoft devcontainers base image to extract Debian libraries
  # This replicates lines 26-30 of the Dockerfile
  # Multi-arch support: uses different hash per architecture
  microsoftBaseImage = pkgs.dockerTools.pullImage {
    imageName = "mcr.microsoft.com/devcontainers/base";
    imageDigest = "sha256:3dcb059253b2ebb44de3936620e1cff3dadcd2c1c982d579081ca8128c1eb319";
    sha256 =
      if system == "x86_64-linux" then "sha256-DOqliRFy6+ivfxDYNDOM/srowHL751OJwx2OXhlJozE="
      else if system == "aarch64-linux" then "sha256-EavwpObLdBjgGpxY7as6Qtlt4WvEvzl96BtozRXJ8G4="
      else throw "Unsupported system: ${system}";
    finalImageTag = "ubuntu";
  };

  # Extract Debian libraries from Microsoft's base image for VS Code compatibility
  # This replicates lines 46-50 of the Dockerfile
  # VS Code remote server needs actual Debian libraries at FHS paths, not Nix equivalents
  debianLibsForVSCode = pkgs.runCommand "debian-libs-vscode"
    {
      buildInputs = [ pkgs.gnutar ];
    } ''
    mkdir -p $out/lib $out/lib32 $out/lib64 $out/usr/lib $out/usr/bin

    # Extract the Microsoft image
    tar -xf ${microsoftBaseImage}

    # Find and extract all layers
    for layer in */layer.tar; do
      if [ -f "$layer" ]; then
        tar -xf "$layer" 2>/dev/null || true
      fi
    done

    # Copy the extracted directories to output
    if [ -d lib ]; then
      cp -r lib/* $out/lib/ 2>/dev/null || true
    fi
    if [ -d usr/bin/wget ]; then
      cp usr/bin/wget $out/usr/bin/ 2>/dev/null || true
    fi
    if [ -d usr/lib/x86_64-linux-gnu ]; then
      mkdir -p $out/usr/lib/x86_64-linux-gnu
      cp -r usr/lib/x86_64-linux-gnu/* $out/usr/lib/x86_64-linux-gnu/ 2>/dev/null || true
    fi

    ${pkgs.lib.optionalString (system == "x86_64-linux") ''
      if [ -d lib32 ]; then
        cp -r lib32/* $out/lib32/ 2>/dev/null || true
      fi
      if [ -d lib64 ]; then
        cp -r lib64/* $out/lib64/ 2>/dev/null || true
      fi
      # Create empty directories if they don't exist
      mkdir -p $out/lib32 $out/lib64
    ''}
  '';

  configFiles = pkgs.runCommand "config-files" {} ''
      mkdir -p $out/etc/nixos
      cp ${./etc/nixos/configuration.nix} $out/etc/nixos/bootstrap-configuration.nix
      cp ${./etc/nixos/devcontainer-patch.nix} $out/etc/nixos/devcontainer-patch.nix
    '';

  # Post-create script for devcontainer
  postCreateScript = pkgs.runCommand "post-create-script" {} ''
    mkdir -p $out/opt/devcontainer/scripts
    cp ${./opt/devcontainer/scripts/post-create.sh} $out/opt/devcontainer/scripts/post-create.sh
    chmod +x $out/opt/devcontainer/scripts/post-create.sh
  '';

  # First: create a layered base image for better caching (packages in separate layers)
  baseLayeredImage = pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/lucernae/devcontainer-nix-base";
    tag = "rootfs-build";
    contents = [
      debianLibsForVSCode
    ];
  };
in
{
  # this is the output if you want to create a docker image and load it using:
  # cat ./result | docker load

  # Base layered image (cached packages)
  baseImage = baseLayeredImage;

  # Second: use buildImage on top with runAsRoot for activation
  # This adds only ONE extra layer for the activation results
  layeredImage = pkgs.dockerTools.buildImage {
    name = "ghcr.io/lucernae/devcontainer-nix";
    tag = "nixos-dockertools";

    # Build on top of the layered base image
    fromImage = baseLayeredImage;

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [
        configFiles
        postCreateScript
      ];
      pathsToLink = [ "/" ];
    };

    # Run NixOS activation script at build time with root privileges
    runAsRoot = ''
      #!${pkgs.runtimeShell}
      echo "=== Running NixOS activation ===" >&2
      mkdir -p /etc
      ${container}/activate 2>&1 || true
      echo "=== Activation complete ===" >&2
    '';

    config = {
      Cmd = [ "${container}/init" ];
      Env = [
        "PATH=/run/wrappers/bin:/bin:/usr/bin:/usr/sbin:/run/current-system/sw/bin"
      ];
    };
  };
}
