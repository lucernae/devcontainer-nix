{ config, pkgs, ... }:
{
    programs.git = {
      enable = true;
      userName = "VSCode Devcontainer";
      userEmail = "my.email@domain.com";
      extraConfig = {
        safe.directory = [ "/workspace" "/workspaces" ];
      };
    };
}