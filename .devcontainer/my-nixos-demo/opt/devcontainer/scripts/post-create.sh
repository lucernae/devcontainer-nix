#!/usr/bin/env bash
set -e

echo "[devcontainer-nix] Starting AI Agentic NixOS Demo post-create setup..."

# Wait for systemd to finish booting
echo "[devcontainer-nix] Waiting for systemd to reach running or degraded state..."
timeout=60
elapsed=0
while true; do
  state=$(systemctl is-system-running 2>/dev/null || echo "starting")
  if [[ "$state" == "running" ]] || [[ "$state" == "degraded" ]]; then
    echo "[devcontainer-nix] Systemd is $state"
    break
  fi
  if [ $elapsed -ge $timeout ]; then
    echo "[devcontainer-nix] WARNING: Timeout waiting for systemd (state: $state)"
    break
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done

# Start D-Bus (required for nixos-rebuild and other system tools)
echo "[devcontainer-nix] Starting D-Bus..."
systemctl start dbus || true

# Flake-based approach: Update flake inputs if needed
if [ -f /workspace/.devcontainer/my-nixos-demo/flake.nix ]; then
  echo "[devcontainer-nix] Using flake-based configuration..."
  echo "[devcontainer-nix] Flake inputs are locked in flake.lock for reproducibility"

  # Optional: Uncomment to update flake inputs on every rebuild
  # cd /workspace/.devcontainer/my-nixos-demo && nix flake update
else
  # Fallback to channel-based approach if flake not available
  echo "[devcontainer-nix] Flake not found, falling back to channel-based approach..."

  # Update Nix channels for root
  echo "[devcontainer-nix] Updating Nix channels for root..."
  nix-channel --update || echo "[devcontainer-nix] WARNING: Failed to update root channels"

  # Switch to vscode user and update channels
  echo "[devcontainer-nix] Updating Nix channels for vscode user..."
  su - vscode -c "nix-channel --update" || echo "[devcontainer-nix] WARNING: Failed to update vscode channels"

  # Add home-manager channel for vscode user if not present
  echo "[devcontainer-nix] Ensuring home-manager channel is available..."
  su - vscode -c "
    if ! nix-channel --list | grep -q home-manager; then
      nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
      nix-channel --update
    fi
  "
fi

# Apply latest NixOS system configuration on rebuild/prebuild
echo "[devcontainer-nix] Applying NixOS system configuration..."

# Set NIXPKGS_ALLOW_UNFREE for system rebuild (required for unfree packages)
export NIXPKGS_ALLOW_UNFREE=1

if [ -f /etc/nixos/configuration.nix ]; then
  echo "[devcontainer-nix] Using traditional NixOS configuration.nix..."

  # Run nixos-rebuild switch to apply the latest configuration
  # This will rebuild the system with any changes made to /etc/nixos/configuration.nix
  # Using --impure to allow NIXPKGS_ALLOW_UNFREE environment variable
  nixos-rebuild switch --impure 2>&1 | tee /tmp/nixos-rebuild.log || {
    echo "[devcontainer-nix] WARNING: nixos-rebuild switch failed"
    echo "[devcontainer-nix] Check /tmp/nixos-rebuild.log for details"
    echo "[devcontainer-nix] You can try manually with:"
    echo "[devcontainer-nix]   NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --impure"
    echo "[devcontainer-nix] Or use the alias: nrsf"
  }

  echo "[devcontainer-nix] System configuration applied successfully"
else
  echo "[devcontainer-nix] WARNING: /etc/nixos/configuration.nix not found, skipping nixos-rebuild"
fi

# Activate home-manager configuration with AI tools
if [ -f /workspace/.devcontainer/my-nixos-demo/home.nix ]; then
  echo "[devcontainer-nix] Activating home-manager configuration with AI tools..."
  echo "[devcontainer-nix] This will install VS Code, claude-code, and other AI development tools..."

  # Detect architecture
  ARCH=$(uname -m)
  if [ "$ARCH" = "aarch64" ]; then
    FLAKE_CONFIG="vscode-aarch64"
  else
    FLAKE_CONFIG="vscode"
  fi

  # Set NIXPKGS_ALLOW_UNFREE to allow VS Code and other unfree packages
  # Use flake-based home-manager activation
  su - vscode -c "
    export NIXPKGS_ALLOW_UNFREE=1
    cd /workspace/.devcontainer/my-nixos-demo
    home-manager switch --flake .#${FLAKE_CONFIG}
  " || {
    echo "[devcontainer-nix] WARNING: Flake-based home-manager activation failed"
    echo "[devcontainer-nix] Falling back to file-based activation..."

    # Fallback to file-based activation
    su - vscode -c "
      export NIXPKGS_ALLOW_UNFREE=1
      home-manager switch -f /home/vscode/home.nix
    " || {
      echo "[devcontainer-nix] WARNING: home-manager activation failed"
      echo "[devcontainer-nix] You can try manually with:"
      echo "[devcontainer-nix]   su - vscode"
      echo "[devcontainer-nix]   home-manager switch --flake /workspace/.devcontainer/my-nixos-demo#${FLAKE_CONFIG}"
    }
  }
else
  echo "[devcontainer-nix] WARNING: home.nix not found, skipping home-manager activation"
fi

# Install claude-code via npm for the vscode user
echo "[devcontainer-nix] Installing @anthropics/claude-code globally..."
su - vscode -c "
  export PATH=/home/vscode/.nix-profile/bin:\$PATH
  npm install -g @anthropics/claude-code || echo 'WARNING: Failed to install claude-code via npm'
" || echo "[devcontainer-nix] WARNING: npm install failed"

# Fix /tmp permissions for Nix builds
echo "[devcontainer-nix] Fixing /tmp permissions for Nix sandbox..."
setfacl -k /tmp 2>/dev/null || echo "[devcontainer-nix] WARNING: Could not fix /tmp ACL"

# Display welcome message
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 AI Agentic NixOS Development Environment Ready!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Installed AI Tools:"
echo "   • VS Code (vscode) - configured via home-manager"
echo "   • Claude Code (@anthropics/claude-code) - installed via npm"
echo "   • Node.js & npm - for additional tools"
echo ""
echo "🔧 Available Development Tools:"
echo "   • ripgrep, fd, bat, eza, fzf - modern CLI tools"
echo "   • git with delta - enhanced git experience"
echo "   • starship prompt - beautiful shell prompt"
echo "   • zsh with oh-my-zsh - configured shell"
echo ""
echo "💡 Quick Start:"
echo "   1. Switch to vscode user: su - vscode"
echo "   2. Check VS Code: code --version"
echo "   3. Check Claude Code: claude-code --version"
echo "   4. Set API key: export ANTHROPIC_API_KEY='your-key'"
echo "   5. Run Claude Code: claude-code chat"
echo ""
echo "📝 Configuration Files:"
echo "   • NixOS config: /etc/nixos/configuration.nix"
echo "   • Home Manager: /home/vscode/home.nix"
echo "   • Unfree packages: Enabled via NIXPKGS_ALLOW_UNFREE=1"
echo ""
echo "🔗 Shortcuts (in zsh):"
echo "   • cc - run claude-code"
echo "   • ccc - run claude-code chat"
echo "   • ls - aliased to eza"
echo "   • cat - aliased to bat"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "[devcontainer-nix] Post-create setup completed!"
