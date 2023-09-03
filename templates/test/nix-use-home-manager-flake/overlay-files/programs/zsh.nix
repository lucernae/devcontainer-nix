{ config, pkgs, ... }:
{
    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "kubectl"
          "docker"
          "docker-compose"
        ];
        theme = "bira";
      };
      prezto = {
        enable = false;
        pmodules = [
          "autosuggestions"
          "completion"
          "directory"
          "editor"
          "git"
          "kubectl"
          "docker"
          "docker-compose"
          "terminal"
        ];
      };
    };
}
