{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  devcontainer-patch = import ./devcontainer-patch.nix {inherit pkgs;};
in {
  boot = {
    # settings to enable booting as OCI containers
    isContainer = true;
    tmp.useTmpfs = true;
  };
  # boot.tmpOnTmpfs = true;
  networking = {
    # machine hostname
    hostName = lib.mkForce "devcontainer";
    # networking settings for containers
    firewall.enable = false;
    # for some reason, dhcpcd doesn't work nicely
    useNetworkd = false;
    useHostResolvConf = false;
    dhcpcd.enable = lib.mkOverride 0 false;
    # fallback dns
    nameservers = ["1.1.1.1" "8.8.8.8"];
  };
  # networking.firewall.enable = false;
  # networking.useNetworkd = false;
  # networking.useHostResolvConf = true;
  # networking.dhcpcd.enable = true;
  # an example of defining systemd services
  # services.nginx.enable = true;
  # services.nginx.virtualHosts.localhost.root =
  #   "${pkgs.nix.doc}/share/doc/nix/manual";
  environment.systemPackages = with pkgs; [
    vim
    zsh
    git
    nodejs
    acl
    docker-client
    devcontainer-patch
  ];
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      extra-platforms = ["x86_64-linux" "aarch64-linux"];
    };
  };
  services = {
    nscd.enable = false;
    openssh.enable = true;
  };

  # systemd settings. you can enable/disable services.
  # systemd.services.nginx.serviceConfig.AmbientCapabilities =
  #   lib.mkForce [ "CAP_NET_BIND_SERVICE" ];
  systemd.services.nix-daemon.enable = true;
  systemd.services.networkd-wait-online.enable = false;

  # needed by vscode for non-root containers
  users.mutableUsers = true;
  users.groups = {
    vscode = {
      gid = 1000;
      name = "vscode";
    };
  };
  users.users.vscode = {
    uid = 1000;
    isNormalUser = true;
    name = "vscode";
    home = "/home/vscode";
    group = "vscode";
    extraGroups = ["wheel" "docker"];
  };
  security.sudo.extraRules = [
    {
      runAs = "root";
      groups = ["wheel"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  programs.nix-ld.enable = true;
  # environment.variables.NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
  #   pkgs.stdenv.cc.cc
  #   pkgs.glibc
  # ];
  # environment.variables.NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";

  system.activationScripts.installInitScript = ''
    mkdir -p /usr/sbin
    if [ ! -f /usr/sbin/init ]; then
      ln -fs $systemConfig/init /usr/sbin/init
    fi
  '';
  system.activationScripts.vscodePatch = ''
    mkdir -p /bin
    for f in $systemConfig/sw/bin/*; do
      ln -sf "$(readlink $f)" "/bin/$(basename $f)"
    done
    if [ ! -d /lib ]; then
      ln -fs $systemConfig/sw/lib /lib
    fi
    if [ ! -d /lib64 ]; then
      ln -fs /lib /lib64
    fi
    for f in libgcc_s.so.1 libdl.so.2; do
      ln -fs $systemConfig/sw/lib/$f /lib/$f
    done
  '';
  system.activationScripts.ghCodespacePatch = ''
    # GitHub codespace needs node in /usr/bin
    if [ ! -f /usr/bin/node ]; then
      ln -fs $systemConfig/sw/bin/node /usr/bin/node
    fi
    # allow nix to build using /tmp in codespace
    $systemConfig/sw/bin/setfacl -k /tmp
  '';

  system.nssModules = lib.mkForce [];
  system.stateVersion = "22.05";
}
