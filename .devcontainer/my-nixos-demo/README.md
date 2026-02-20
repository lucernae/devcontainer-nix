# AI Agentic NixOS Devcontainer Demo

This demo showcases a **full NixOS devcontainer** configured with AI agentic tools like **VS Code** and **Claude Code**, all managed declaratively through **home-manager**.

## 🎯 What's Inside

This devcontainer demonstrates:

- **Full NixOS environment** with systemd as PID 1
- **Home Manager** for declarative user environment management
- **AI Development Tools**:
  - VS Code (vscode) with extensions
  - Claude Code (@anthropics/claude-code) CLI
  - GitHub Copilot integration
- **Unfree Software Handling**: Properly configured to allow proprietary packages like VS Code
- **Modern CLI Tools**: ripgrep, fd, bat, eza, fzf, and more
- **Enhanced Git Experience**: delta for beautiful diffs, gitlens for VS Code
- **Zsh with Oh-My-Zsh**: Fully configured shell with aliases and plugins

## 🏗️ Architecture

```
NixOS Container (systemd PID 1)
├── System-level (configuration.nix)
│   ├── nixpkgs.config.allowUnfree = true
│   ├── Base packages: git, nodejs, docker, etc.
│   └── System services: dbus, nix-daemon, ssh
│
└── User-level (home.nix via home-manager)
    ├── nixpkgs.config.allowUnfree = true (user-level)
    ├── VS Code with extensions
    ├── Claude Code (installed via npm)
    ├── Modern CLI tools (ripgrep, fd, bat, etc.)
    └── Zsh configuration with Oh-My-Zsh
```

## 📋 Prerequisites

- **Docker** and **Docker Compose**
- **Nix with flakes enabled** (for building custom images)
- **VS Code** with Remote-Containers extension (optional)

To enable flakes in Nix:
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

## 🚀 Quick Start

### Option 1: Using Pre-built Image (Recommended)

```bash
cd .devcontainer/my-nixos-demo

# Start the container (uses ghcr.io/lucernae/devcontainer-nix:nixos)
docker-compose up -d

# Wait for systemd and post-create to finish (~2-5 minutes)
# The post-create script will:
# 1. Apply NixOS system configuration (nixos-rebuild switch)
# 2. Activate home-manager with AI tools
docker-compose logs -f

# Access the container as vscode user
docker-compose exec devcontainer su - vscode

# Check installed tools
code --version
claude-code --version
```

### Option 2: Using Home Manager with Flakes

The flake includes `homeConfigurations` that you can activate directly:

```bash
# Inside the container as vscode user
su - vscode

# Activate home-manager configuration from the flake
home-manager switch --flake /workspace/.devcontainer/my-nixos-demo#vscode

# Or for ARM64 systems
home-manager switch --flake /workspace/.devcontainer/my-nixos-demo#vscode-aarch64
```

### Option 3: Open in VS Code

1. Open the repository root in VS Code
2. Run **"Dev Containers: Open Folder in Container"**
3. Select `.devcontainer/my-nixos-demo`
4. Wait for the container to build and start
5. VS Code will automatically connect as the `vscode` user

## 🔑 Handling Unfree Software

### Why is this needed?

VS Code and many other popular development tools are proprietary (unfree). NixOS/nixpkgs requires explicit permission to install unfree packages.

### How it's configured:

#### System-level (`configuration.nix`):
```nix
nixpkgs.config.allowUnfree = true;
```

#### User-level (`home.nix`):
```nix
nixpkgs.config.allowUnfree = true;
```

#### Environment variable:
```bash
export NIXPKGS_ALLOW_UNFREE=1
```

All three methods are demonstrated in this setup for maximum compatibility.

## 🤖 Using AI Tools

### Claude Code

```bash
# Switch to vscode user
su - vscode

# Set your API key (required)
export ANTHROPIC_API_KEY="your-anthropic-api-key"

# Start a chat session
claude-code chat

# Or use the shortcut
ccc
```

### VS Code

VS Code is pre-configured with:
- **Nix IDE** for Nix language support
- **GitLens** for enhanced Git integration
- **GitHub Copilot** for AI code completion
- **Delta** for beautiful git diffs

The editor is configured to use `zsh` as the integrated terminal shell.

## 📦 Installed Packages

### AI Development Tools
- `vscode` - Visual Studio Code editor
- `nodejs` + `npm` - For installing claude-code
- `claude-code` - Anthropic's Claude CLI (installed via npm)

### Modern CLI Tools
- `ripgrep` (rg) - Fast text search
- `fd` - Fast file finder
- `bat` - Cat with syntax highlighting
- `eza` - Modern ls replacement
- `fzf` - Fuzzy finder
- `delta` - Beautiful git diffs
- `starship` - Cross-shell prompt
- `zoxide` - Smart cd command

### Development Tools
- `git` with enhanced configuration
- `gh` - GitHub CLI
- `docker` - Docker client
- `jq` / `yq` - JSON/YAML processors
- `httpie` - HTTP client

## 🎨 Customization

### Modifying System Configuration

Edit `.devcontainer/my-nixos-demo/etc/nixos/configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  # Add your system-level packages here
  postgresql
  redis
];
```

Then rebuild:
```bash
nix build .#layeredImage --rebuild
docker load < result
docker-compose down && docker-compose up -d
```

### Modifying User Environment

Edit `.devcontainer/my-nixos-demo/home.nix`:

```nix
home.packages = with pkgs; [
  # Add your user packages here
  python3
  rustc
  cargo
];
```

Then re-run home-manager:
```bash
su - vscode
NIXPKGS_ALLOW_UNFREE=1 home-manager switch -f ~/home.nix
```

### Adding VS Code Extensions

Edit `home.nix`:

```nix
programs.vscode = {
  enable = true;
  extensions = with pkgs.vscode-extensions; [
    # Add more extensions
    ms-python.python
    rust-lang.rust-analyzer
  ];
};
```

## 🔧 Shell Configuration

The Zsh shell is pre-configured with:

### Aliases

**AI Tools:**
- `cc` → `claude-code`
- `ccc` → `claude-code chat`

**Modern CLI:**
- `ls` → `eza --icons`
- `ll` → `eza -la --icons --git`
- `cat` → `bat`

**Git:**
- `gs` → `git status`
- `ga` → `git add`
- `gc` → `git commit`
- `gp` → `git push`
- `gl` → `git log --oneline --graph --decorate`

**Nix/NixOS:**
- `nrsf` → `sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --impure -I nixos-config=/etc/nixos/configuration.nix`
- `nrs` → `sudo nixos-rebuild switch` (simpler version)
- `nix-shell-unfree` → `NIXPKGS_ALLOW_UNFREE=1 nix-shell`
- `gs` → `git status`
- `ga` → `git add`
- `gc` → `git commit`

### Oh-My-Zsh Plugins
- git
- docker
- npm
- node
- direnv
- history
- command-not-found

### Starship Prompt
Beautiful, informative prompt showing:
- Git branch and status
- Nix shell indicator
- Command duration
- Exit status

## 🐛 Troubleshooting

### VS Code installation fails

**Symptom**: Error installing vscode package

**Solution**: Ensure unfree packages are allowed:
```bash
export NIXPKGS_ALLOW_UNFREE=1
home-manager switch -f ~/home.nix
```

### Claude Code not found

**Symptom**: `command not found: claude-code`

**Solution**: Install via npm manually:
```bash
su - vscode
npm install -g @anthropics/claude-code
```

### Home Manager activation fails

**Symptom**: `home-manager switch` fails

**Solution**:
1. Check home-manager channel is added:
   ```bash
   nix-channel --list | grep home-manager
   ```

2. Add if missing:
   ```bash
   nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz home-manager
   nix-channel --update
   ```

3. Retry with unfree flag:
   ```bash
   NIXPKGS_ALLOW_UNFREE=1 home-manager switch -f ~/home.nix
   ```

### Container exits immediately

**Symptom**: Container stops right after starting

**Solution**:
1. Check logs: `docker-compose logs`
2. Verify systemd is running: `docker-compose exec devcontainer systemctl status`
3. Ensure sufficient Docker resources (4GB+ RAM recommended)

## 🏠 Home Manager with Flakes

This demo uses **flake-based home-manager** for better reproducibility and easier activation.

### Available Home Configurations

The `flake.nix` defines two homeConfigurations:

- **`vscode`** - For x86_64 systems (Intel/AMD)
- **`vscode-aarch64`** - For ARM64 systems (Apple Silicon, ARM servers)

### Activation Methods

#### Method 1: Flake-based (Recommended)
```bash
su - vscode
home-manager switch --flake /workspace/.devcontainer/my-nixos-demo#vscode
```

#### Method 2: File-based (Fallback)
```bash
su - vscode
NIXPKGS_ALLOW_UNFREE=1 home-manager switch -f ~/home.nix
```

### Benefits of Flake-based Home Manager

✅ **Reproducible**: `flake.lock` pins all dependencies
✅ **Multi-architecture**: Separate configs for x86_64 and ARM64
✅ **Portable**: Reference the flake from anywhere
✅ **Composable**: Can import and extend configurations

### Auto-activation

The `post-create.sh` script automatically:
1. Detects your system architecture
2. Selects the appropriate homeConfiguration
3. Activates it with unfree packages enabled
4. Falls back to file-based activation if needed

## 📚 Key Files

| File | Purpose |
|------|---------|
| `flake.nix` | Nix flake with homeConfigurations and container outputs |
| `etc/nixos/configuration.nix` | System-level NixOS configuration (allows unfree) |
| `home.nix` | User-level home-manager configuration (AI tools) |
| `devcontainer.json` | VS Code devcontainer configuration |
| `docker-compose.yml` | Container runtime configuration |
| `opt/devcontainer/scripts/post-create.sh` | Post-startup initialization script |

## 🎁 Flake Outputs

This flake provides home-manager configurations for reproducible user environments:

### Home Configurations
```bash
# List available home configurations
nix flake show

# Activate home configuration (inside the container as vscode user)
home-manager switch --flake /workspace/.devcontainer/my-nixos-demo#vscode           # x86_64
home-manager switch --flake /workspace/.devcontainer/my-nixos-demo#vscode-aarch64   # ARM64
```

### Inspecting the Flake
```bash
# Show all outputs
nix flake show

# Check flake metadata
nix flake metadata

# Update flake inputs (updates home-manager and nixpkgs versions)
nix flake update

# Lock specific input
nix flake lock --update-input home-manager
```

### System Configuration (NixOS)

The system configuration is managed via traditional `/etc/nixos/configuration.nix`:

```bash
# Apply system configuration changes
sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --impure

# Or use the convenient alias (inside container as vscode user)
nrsf

# Check system configuration
sudo nixos-option environment.systemPackages
```

## 🌟 Highlights

### Flake-based Home Manager
Uses modern flake-based home-manager for reproducible user environments.

### Multi-architecture Support
Separate homeConfigurations for x86_64 and ARM64 systems.

### Declarative Configuration
Everything is defined in Nix expressions - no imperative setup steps needed.

### Reproducible
The `flake.lock` ensures the exact same packages are installed every time.

### Unfree Software Support
Demonstrates proper handling of proprietary software in NixOS/home-manager.

### AI-Ready
Pre-configured with modern AI development tools and workflows.

### Modern CLI Experience
All the modern replacements for traditional Unix tools, configured and ready to use.

## 📖 Learn More

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [Devcontainer Specification](https://containers.dev/)

## 🤝 Contributing

This demo is part of the [devcontainer-nix](https://github.com/lucernae/devcontainer-nix) project. Issues and improvements are welcome!

## 📄 License

This demo follows the same license as the parent project.

---

**Happy AI-assisted coding with NixOS! 🤖✨**
