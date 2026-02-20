{ config, pkgs, ... }:

{
  # Specify the home-manager release version
  home.stateVersion = "25.11";

  # Allow unfree packages in home-manager
  # Required for VS Code (vscode is unfree)
  nixpkgs.config.allowUnfree = true;

  # User packages - AI Agentic Tools and Development Utilities
  home.packages = with pkgs; [
    # AI Development Tools
    opencode
    claude-code

    # Development utilities
    ripgrep       # Fast search tool (rg)
    fd            # Fast find alternative
    bat           # Cat with syntax highlighting
    eza           # Modern ls replacement
    fzf           # Fuzzy finder
    starship      # Shell prompt

    # Git and version control
    gh            # GitHub CLI
    git-crypt     # Git encryption

    # Modern shell tools
    zoxide        # Smart cd command
    direnv        # Directory-based environment management
    nix-direnv    # Better direnv support for Nix

    # System tools
    htop          # Process viewer
    ncdu          # Disk usage analyzer
    tree          # Directory tree viewer

    # Network tools
    httpie        # HTTP client
    jq            # JSON processor
    yq            # YAML processor
  ];

  # Git configuration for AI-assisted development
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "AI Developer";
        email = "dev@example.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "code --wait";
      # Enable delta for better git diffs
      core.pager = "${pkgs.delta}/bin/delta";
      interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };
  };

  # Delta (git diff viewer) - separate from git config
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # Zsh configuration optimized for AI development
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # Modern replacements
      ls = "eza --icons";
      ll = "eza -la --icons --git";
      cat = "bat";

      # Git shortcuts
      gs = "git status";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate";

      # Claude Code shortcuts
      cc = "claude-code";
      ccc = "claude-code chat";

      # Nix shortcuts
      nix-search = "nix search nixpkgs";
      nix-shell-unfree = "NIXPKGS_ALLOW_UNFREE=1 nix-shell";

      # NixOS rebuild shortcuts:
      # nrs  - Traditional rebuild (uses /etc/nixos/configuration.nix)
      # nrsf - Flake-based rebuild (uses /etc/nixos/flake.nix#devcontainer)

      # Traditional NixOS rebuild with unfree packages
      nrs = "sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --impure -I nixos-config=/etc/nixos/configuration.nix";

      # Flake-based NixOS rebuild (recommended)
      # Flake automatically detects system architecture
      nrsf = "sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --flake /etc/nixos#devcontainer --impure";
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
        "npm"
        "node"
        "direnv"
        "history"
        "command-not-found"
      ];
    };

    initExtra = ''
      # Initialize starship prompt
      eval "$(${pkgs.starship}/bin/starship init zsh)"

      # Initialize zoxide (smart cd)
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

      # Install claude-code globally if not already installed
      if ! command -v claude-code &> /dev/null; then
        echo "Installing @anthropics/claude-code..."
        npm install -g @anthropics/claude-code
      fi

      # Set up environment for AI development
      export EDITOR="code --wait"
      export VISUAL="code"

      # Enable unfree packages for nix-shell
      export NIXPKGS_ALLOW_UNFREE=1

      # Claude Code API key (set this in your actual environment)
      # Note that you should not commit any API Key into public repository.
      # Ensure the sourcing script for the secrets were .gitignore'd
      # export ANTHROPIC_API_KEY="your-api-key-here"

      # Welcome message
      echo "🤖 AI Development Environment Ready!"
      echo "   • Node.js: $(node --version)"
      echo "   • Claude Code: Run 'claude-code --version' after npm install completes"
      echo ""
      echo "💡 Quick tips:"
      echo "   • Use 'cc' to run claude-code"
      echo "   • Use 'ccc' for claude-code chat"
      echo "   • Set ANTHROPIC_API_KEY environment variable for Claude Code"
    '';
  };

  # Starship prompt configuration
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$all";

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      # Show Nix shell indicator
      nix_shell = {
        format = "via [$symbol$state]($style) ";
        symbol = "❄️ ";
        impure_msg = "impure";
        pure_msg = "pure";
      };

      # Git status
      git_status = {
        conflicted = "🏳";
        ahead = "🏎💨";
        behind = "😰";
        diverged = "😵";
        untracked = "🤷";
        stashed = "📦";
        modified = "📝";
        staged = "[++($count)](green)";
        renamed = "👅";
        deleted = "🗑";
      };

      # Show command duration
      cmd_duration = {
        min_time = 500;
        format = "took [$duration](bold yellow)";
      };
    };
  };

  # Direnv integration for automatic environment activation
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # Bat (cat replacement) configuration
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };

  # FZF (fuzzy finder) configuration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--border"
      "--inline-info"
      "--preview '${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 {}'"
    ];
  };

  # Environment variables for AI development
  home.sessionVariables = {
    # Allow unfree packages in nix-shell
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  # Shell initialization for ensuring claude-code is available
  home.file.".config/claude-code/.keep".text = ''
    # This directory stores claude-code configuration
    # API key should be set via environment variable: ANTHROPIC_API_KEY
  '';
}
