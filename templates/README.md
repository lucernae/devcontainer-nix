# Devcontainer Nix Templates

This directory contains devcontainer templates for the `devcontainer-nix` project. Templates allow users to quickly bootstrap Nix-based development environments in their own repositories using the devcontainer CLI.

## Table of Contents

- [Directory Structure](#directory-structure)
- [Using the Template](#using-the-template)
- [AI Agent Quick Start](#ai-agent-quick-start)
- [Template Options](#template-options)
- [Testing Templates](#testing-templates)
- [Publishing Templates](#publishing-templates)

## Directory Structure

```
templates/
├── src/
│   └── nix/                              # The main Nix devcontainer template
│       ├── devcontainer-template.json    # Template metadata and options
│       ├── README.md                     # Auto-generated template docs
│       └── .devcontainer/
│           ├── Dockerfile
│           ├── devcontainer.json
│           ├── docker-compose.yml
│           └── library-scripts/
│               ├── build/                # Scripts run at image build time
│               └── runtime/              # Scripts run at container startup
├── test/                                 # Test cases for template validation
│   ├── nix-use-direnv/                  # Test: direnv + classic nix
│   ├── nix-use-flake/                   # Test: direnv + nix flakes
│   ├── nix-use-home-manager/            # Test: home-manager (classic)
│   ├── nix-use-home-manager-flake/      # Test: home-manager (flake)
│   └── test-utils/                      # Shared testing utilities
├── devcontainer-apply-manual.sh         # Manual template application
├── devcontainer-publish-manual.sh       # Manual template publishing
├── test.sh                              # Test runner wrapper
└── build.sh                             # Build helper
```

## Using the Template

### Prerequisites

Install the devcontainer CLI:

```bash
npm install -g @devcontainers/cli
```

### Applying the Template

#### Method 1: Using the Published Template

Apply the template to your project using the published GHCR template:

```bash
# Navigate to your project root
cd /path/to/your/project

# Create a directory for your devcontainer
mkdir -p .devcontainer

# Create an args.json file with your desired options
cat > .devcontainer/args.json <<EOF
{
    "useDirenv": "true",
    "useFlake": "true",
    "imageVariant": "latest"
}
EOF

# Apply the template
devcontainer templates apply \
  -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
  --workspace-folder . \
  -a "$(cat .devcontainer/args.json)"
```

#### Method 2: Local Development

For local testing or development of the template:

```bash
# From the templates directory
./devcontainer-apply-manual.sh
```

This script applies the template locally using:
```bash
devcontainer templates apply \
  -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
  --workspace-folder ../tmp \
  -a "$(cat ../tmp/args.json)"
```

### Building the Devcontainer

After applying the template, build and start your devcontainer:

```bash
# Build the container
devcontainer up --workspace-folder .

# Or use docker-compose directly
cd .devcontainer
docker-compose build
docker-compose up -d

# Execute commands inside
devcontainer exec --workspace-folder . /bin/bash
```

## AI Agent Quick Start

This section provides ready-to-use prompts for AI agents to bootstrap devcontainers based on existing Nix configurations in a repository. AI agents can use these prompts to automatically detect and configure the appropriate devcontainer setup.

### Detection and Setup Workflow

AI agents should follow this decision tree:

```
1. Check if flake.nix exists with devShells
   → Use Flake devShell bootstrap

2. Check if home-manager configuration exists
   → Use Home Manager bootstrap (flake or classic)

3. Check if shell.nix or default.nix exists
   → Use Classic Nix bootstrap

4. No Nix configuration found
   → Use minimal direnv setup
```

### Prompt 1: Bootstrap with Existing Flake devShell

**When to use:** Repository has `flake.nix` with `devShells` output defined.

**Detection command:**
```bash
# Check if flake.nix exists and has devShells
if [ -f "flake.nix" ]; then
  nix flake show --json 2>/dev/null | jq -e '.devShells' > /dev/null && echo "devShell found"
fi
```

**AI Agent Prompt:**
```
I need to bootstrap a devcontainer for this repository that has an existing Nix flake with devShell.

Steps:
1. Install devcontainer CLI if not available:
   npm install -g @devcontainers/cli

2. Create .devcontainer/args.json with the following content:
   {
     "useDirenv": "true",
     "useFlake": "true",
     "prebuildFlakeDevelop": ".",
     "imageVariant": "flake---latest"
   }

3. Apply the devcontainer-nix template:
   devcontainer templates apply \
     -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
     --workspace-folder . \
     -a "$(cat .devcontainer/args.json)"

4. Create or update .envrc in the project root:
   echo "use flake" > .envrc

5. Build and start the devcontainer:
   devcontainer up --workspace-folder .

This will create a devcontainer that automatically activates your flake's devShell environment.
```

### Prompt 2: Bootstrap with Home Manager (Flake)

**When to use:** Repository has home-manager configuration in a flake.

**Detection command:**
```bash
# Check if flake.nix has homeConfigurations
if [ -f "flake.nix" ]; then
  nix flake show --json 2>/dev/null | jq -e '.homeConfigurations' > /dev/null && echo "homeConfigurations found"
fi
```

**AI Agent Prompt:**
```
I need to bootstrap a devcontainer with home-manager configuration from a Nix flake.

Steps:
1. Identify the home-manager configuration name from flake.nix
   (Look for homeConfigurations.<name> in the outputs)

2. Create .devcontainer/args.json:
   {
     "useDirenv": "true",
     "useFlake": "true",
     "prebuildHomeManagerFlake": ".#homeConfigurations.<name>",
     "imageVariant": "flake---latest"
   }

   Replace <name> with the actual configuration name (e.g., "devcontainer", "vscode", etc.)

3. Apply the template:
   devcontainer templates apply \
     -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
     --workspace-folder . \
     -a "$(cat .devcontainer/args.json)"

4. Build and start:
   devcontainer up --workspace-folder .

The home-manager configuration will be activated automatically on container startup.
```

### Prompt 3: Bootstrap with Home Manager (Classic)

**When to use:** Repository has standalone `home.nix` or similar home-manager configuration file.

**Detection command:**
```bash
# Check for common home-manager config files
[ -f "home.nix" ] || [ -f ".config/home-manager/home.nix" ] || [ -f ".devcontainer/home.nix" ]
```

**AI Agent Prompt:**
```
I need to bootstrap a devcontainer with a standalone home-manager configuration.

Steps:
1. Locate the home-manager configuration file (e.g., home.nix, .config/home-manager/home.nix)

2. Create .devcontainer/args.json:
   {
     "useDirenv": "true",
     "useFlake": "false",
     "prebuildHomeManager": "<path-to-home.nix>",
     "imageVariant": "latest"
   }

   Replace <path-to-home.nix> with the actual path from project root.

3. Apply the template:
   devcontainer templates apply \
     -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
     --workspace-folder . \
     -a "$(cat .devcontainer/args.json)"

4. Build and start:
   devcontainer up --workspace-folder .

The home-manager configuration will be built and activated on container creation.
```

### Prompt 4: Bootstrap with Classic Nix (shell.nix or default.nix)

**When to use:** Repository has `shell.nix` or `default.nix` but no flake.

**Detection command:**
```bash
# Check for classic Nix files
[ -f "shell.nix" ] || [ -f "default.nix" ]
```

**AI Agent Prompt:**
```
I need to bootstrap a devcontainer for a repository using classic Nix (shell.nix/default.nix).

Steps:
1. Determine which files exist:
   - shell.nix (development environment)
   - default.nix (package definition)

2. Create .devcontainer/args.json based on what's available:

   If shell.nix exists:
   {
     "useDirenv": "true",
     "useFlake": "false",
     "prebuildNixShell": "shell.nix",
     "imageVariant": "latest"
   }

   If default.nix exists (and no shell.nix):
   {
     "useDirenv": "true",
     "useFlake": "false",
     "prebuildDefaultPackage": "default.nix",
     "imageVariant": "latest"
   }

   If both exist:
   {
     "useDirenv": "true",
     "useFlake": "false",
     "prebuildNixShell": "shell.nix",
     "prebuildDefaultPackage": "default.nix",
     "imageVariant": "latest"
   }

3. Create or update .envrc in the project root:
   echo "use nix" > .envrc

4. Apply the template:
   devcontainer templates apply \
     -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
     --workspace-folder . \
     -a "$(cat .devcontainer/args.json)"

5. Build and start:
   devcontainer up --workspace-folder .

The nix-shell environment will be automatically activated via direnv.
```

### Prompt 5: Bootstrap Minimal Setup (No Existing Nix Config)

**When to use:** Repository has no Nix configuration yet.

**AI Agent Prompt:**
```
I need to bootstrap a minimal Nix devcontainer for a repository without existing Nix configuration.

Steps:
1. Create .devcontainer/args.json with minimal options:
   {
     "useDirenv": "true",
     "useFlake": "true",
     "imageVariant": "flake---latest"
   }

2. Apply the template:
   devcontainer templates apply \
     -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
     --workspace-folder . \
     -a "$(cat .devcontainer/args.json)"

3. Create a basic flake.nix in the project root:
   cat > flake.nix <<'EOF'
   {
     description = "Development environment";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
       flake-utils.url = "github:numtide/flake-utils";
     };

     outputs = { self, nixpkgs, flake-utils }:
       flake-utils.lib.eachDefaultSystem (system:
         let
           pkgs = nixpkgs.legacyPackages.${system};
         in {
           devShells.default = pkgs.mkShell {
             buildInputs = with pkgs; [
               # Add your development packages here
               # Example: git nodejs python3
             ];

             shellHook = ''
               echo "Welcome to the development environment!"
             '';
           };
         });
   }
   EOF

4. Create .envrc:
   echo "use flake" > .envrc

5. Build and start:
   devcontainer up --workspace-folder .

6. Customize flake.nix by adding required packages to the buildInputs list.
```

### Advanced: Multi-System Setup with NixOS Configuration

**When to use:** Repository has NixOS `configuration.nix` for reproducible system-level configuration.

**AI Agent Prompt:**
```
I need to bootstrap a devcontainer with full NixOS system configuration support.

Note: This requires the nixos-arion variant which supports systemd and full NixOS features.

Steps:
1. Create .devcontainer/args.json:
   {
     "useDirenv": "true",
     "useFlake": "true",
     "imageVariant": "nixos-arion---latest"
   }

2. Apply the template:
   devcontainer templates apply \
     -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
     --workspace-folder . \
     -a "$(cat .devcontainer/args.json)"

3. Create or reference your configuration.nix in the devcontainer setup.
   The nixos-arion variant uses Arion to compose NixOS containers.

4. For full NixOS configuration, you may need to customize the
   .devcontainer/arion-compose.nix file to reference your configuration.nix

5. Build and start:
   devcontainer up --workspace-folder .

See .devcontainer/nixos-arion/ in the devcontainer-nix repository for examples.
```

### Complete AI Agent Bootstrap Script

AI agents can use this complete script to automatically detect and bootstrap:

```bash
#!/usr/bin/env bash
# Auto-detect Nix configuration and bootstrap appropriate devcontainer

set -e

echo "🔍 Detecting Nix configuration..."

# Install devcontainer CLI if needed
if ! command -v devcontainer &> /dev/null; then
    echo "📦 Installing @devcontainers/cli..."
    npm install -g @devcontainers/cli
fi

mkdir -p .devcontainer

# Detection and configuration
if [ -f "flake.nix" ]; then
    echo "✅ Found flake.nix"

    # Check for devShells
    if nix flake show --json 2>/dev/null | jq -e '.devShells' > /dev/null 2>&1; then
        echo "📦 Detected devShells - using flake develop"
        cat > .devcontainer/args.json <<EOF
{
  "useDirenv": "true",
  "useFlake": "true",
  "prebuildFlakeDevelop": ".",
  "imageVariant": "flake---latest"
}
EOF
        echo "use flake" > .envrc

    # Check for homeConfigurations
    elif nix flake show --json 2>/dev/null | jq -e '.homeConfigurations' > /dev/null 2>&1; then
        echo "🏠 Detected homeConfigurations"
        CONFIG_NAME=$(nix flake show --json 2>/dev/null | jq -r '.homeConfigurations | keys[0]')
        cat > .devcontainer/args.json <<EOF
{
  "useDirenv": "true",
  "useFlake": "true",
  "prebuildHomeManagerFlake": ".#homeConfigurations.${CONFIG_NAME}",
  "imageVariant": "flake---latest"
}
EOF
    else
        echo "📦 Using flake for basic setup"
        cat > .devcontainer/args.json <<EOF
{
  "useDirenv": "true",
  "useFlake": "true",
  "imageVariant": "flake---latest"
}
EOF
        echo "use flake" > .envrc
    fi

elif [ -f "home.nix" ] || [ -f ".config/home-manager/home.nix" ]; then
    echo "🏠 Found home-manager configuration (classic)"
    HOME_CONFIG=$([ -f "home.nix" ] && echo "home.nix" || echo ".config/home-manager/home.nix")
    cat > .devcontainer/args.json <<EOF
{
  "useDirenv": "true",
  "useFlake": "false",
  "prebuildHomeManager": "${HOME_CONFIG}",
  "imageVariant": "latest"
}
EOF

elif [ -f "shell.nix" ]; then
    echo "🐚 Found shell.nix (classic Nix)"
    cat > .devcontainer/args.json <<EOF
{
  "useDirenv": "true",
  "useFlake": "false",
  "prebuildNixShell": "shell.nix",
  "imageVariant": "latest"
}
EOF
    echo "use nix" > .envrc

elif [ -f "default.nix" ]; then
    echo "📦 Found default.nix (classic Nix)"
    cat > .devcontainer/args.json <<EOF
{
  "useDirenv": "true",
  "useFlake": "false",
  "prebuildDefaultPackage": "default.nix",
  "imageVariant": "latest"
}
EOF
    echo "use nix" > .envrc

else
    echo "⚠️  No Nix configuration found - creating minimal flake setup"
    cat > .devcontainer/args.json <<EOF
{
  "useDirenv": "true",
  "useFlake": "true",
  "imageVariant": "flake---latest"
}
EOF

    # Create minimal flake.nix
    cat > flake.nix <<'EOF'
{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
          ];
        };
      });
}
EOF
    echo "use flake" > .envrc
fi

echo "🚀 Applying devcontainer template..."
devcontainer templates apply \
  -t ghcr.io/lucernae/devcontainer-nix/nix:1 \
  --workspace-folder . \
  -a "$(cat .devcontainer/args.json)"

echo "✅ Devcontainer configuration created!"
echo "📝 Configuration saved to .devcontainer/args.json"
echo ""
echo "Next steps:"
echo "  1. Review and customize .devcontainer/devcontainer.json"
echo "  2. Build the container: devcontainer up --workspace-folder ."
echo "  3. Open in VS Code or GitHub Codespaces"
```

### Usage Notes for AI Agents

#### Always Ask for Human Confirmation

1. **Present your plan before execution** - Show the detected configuration and proposed `args.json` to the human for review
2. **Explain your reasoning** - Tell them why you chose a specific configuration (e.g., "I detected a flake.nix with devShells, so I'm configuring the devcontainer to use `nix develop`")
3. **Ask before applying** - Don't automatically run the template application without explicit approval
4. **Summarize what will happen** - Explain that this will create `.devcontainer/` directory with Docker configuration

Example confirmation prompt:
```
I detected the following Nix configuration in your repository:
- flake.nix with devShells.default output

I recommend creating a devcontainer with these settings:
{
  "useDirenv": "true",
  "useFlake": "true",
  "prebuildFlakeDevelop": ".",
  "imageVariant": "flake---latest"
}

This will:
1. Create .devcontainer/ directory with Docker configuration
2. Set up direnv to automatically activate the flake devShell
3. Use the latest flake-based devcontainer image

Would you like me to proceed with this configuration?
```

#### Remote Repository Configurations

When you detect that the user might want to use configurations from remote repositories (e.g., personal dotfiles, shared team configurations):

1. **Ask about remote home-manager configurations**
   ```
   I notice you might have a home-manager configuration elsewhere.
   Do you have a remote repository with home-manager configuration you'd like to use?

   If yes, I can configure the devcontainer to use:
   - prebuildHomeManagerFlake: "github:username/dotfiles#homeConfigurations.devcontainer"

   This will pull and activate your home-manager configuration from the remote repository.
   ```

2. **Ask about prebuilding vs. on-demand loading**
   ```
   For remote Nix flakes, I can configure two modes:

   Option A - Prebuild (slower initial setup, faster container start):
   - prebuildFlake: "github:owner/repo"
   - Downloads and builds everything during container creation
   - First startup takes longer, but subsequent operations are faster

   Option B - On-demand (faster initial setup, slower first use):
   - No prebuild, just enable flake support
   - Container starts quickly, but first `nix develop` will download

   Which would you prefer?
   ```

3. **Confirm remote repository access**
   ```
   I see you want to use: github:username/private-dotfiles

   Important: If this is a private repository, make sure:
   - Your GitHub credentials are configured in the devcontainer
   - The repository is accessible from the container
   - You've set up SSH keys or GitHub tokens

   Should I proceed with this remote configuration?
   ```

4. **Ask about specific remote flake outputs**
   ```
   I can see your flake has multiple outputs:
   - devShells.default
   - devShells.python
   - devShells.nodejs
   - homeConfigurations.desktop
   - homeConfigurations.devcontainer

   Which output would you like to use in the devcontainer?
   ```

#### Technical Best Practices

1. **Always check existing configurations first** - Don't overwrite user's existing Nix setup
2. **Preserve .envrc if it exists** - Append rather than replace if direnv is already configured
3. **Validate flake.nix syntax** - Use `nix flake check` before proceeding with flake-based setups
4. **Ask for confirmation on conflicts** - When multiple configurations exist (e.g., both shell.nix and flake.nix), ask which to prioritize
5. **Document the choice** - Add comments in the generated args.json explaining why certain options were selected
6. **Verify remote flake accessibility** - Before using remote flakes, check if they're publicly accessible or require authentication
7. **Test the setup** - After applying, verify with `devcontainer up --workspace-folder .` before reporting success
8. **Handle errors gracefully** - If remote flake fails to fetch, offer to fall back to local configuration

#### Example: Complete AI Agent Interaction Flow

```
🤖 AI Agent: I've analyzed your repository and found:
   - flake.nix with devShells.default
   - No existing .devcontainer/ directory

   I can set up a Nix-based devcontainer for you. However, I have a few questions:

   1. Do you have a personal home-manager configuration in a remote repository
      (like dotfiles) that you'd like to use? (yes/no)

👤 Human: Yes, it's at github:myuser/dotfiles

🤖 AI Agent: Great! I can see your dotfiles repo has homeConfigurations.
   Which configuration should I use?
   - homeConfigurations.desktop
   - homeConfigurations.laptop
   - homeConfigurations.devcontainer

👤 Human: Use devcontainer

🤖 AI Agent: Perfect! One more question:
   Would you like me to prebuild the home-manager configuration during
   container creation? This makes the first startup slower (~5-10 min)
   but subsequent uses will be instant. (yes/no)

👤 Human: Yes, prebuild it

🤖 AI Agent: Excellent! Here's what I'll create:

   .devcontainer/args.json:
   {
     "useDirenv": "true",
     "useFlake": "true",
     "prebuildFlakeDevelop": ".",
     "prebuildHomeManagerFlake": "github:myuser/dotfiles#homeConfigurations.devcontainer",
     "imageVariant": "flake---latest"
   }

   This will:
   ✅ Use your local flake.nix devShell
   ✅ Load your home-manager config from GitHub
   ✅ Prebuild everything during container creation
   ✅ Set up direnv for automatic activation

   Shall I proceed? (yes/no)

👤 Human: Yes

🤖 AI Agent: 🚀 Creating devcontainer configuration...
   ✅ Created .devcontainer/args.json
   ✅ Applied template
   ✅ Created .envrc

   Next steps:
   1. Build the container: devcontainer up --workspace-folder .
   2. First build will take ~5-10 minutes (prebuilding home-manager)
   3. After that, the container will start instantly!
```

## Template Options

The template supports the following options (defined in `src/nix/devcontainer-template.json`):

### Core Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `useDirenv` | bool | `true` | Install direnv and automatically activate the repo when direnv configuration exists |
| `useFlake` | bool | `true` | Add Nix Flake experimental configuration to use Nix Flake |
| `imageVariant` | string | `v1` | Devcontainer image variant (see [Image Variants](#image-variants)) |

### Package Installation

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installRootPackages` | string | `""` | Install additional nix packages at build time as root. Syntax follows nix flake or nix-env commands |

**Examples:**
```json
{
  "installRootPackages": "nixpkgs.vim nixpkgs.git"
}
```
or with flakes:
```json
{
  "installRootPackages": "nixpkgs#vim nixpkgs#git"
}
```

### Prebuild Options

These options prebuild packages at container startup to improve subsequent load times:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `prebuildDefaultPackage` | string | `""` | Run `nix-build` on default.nix package(s). Comma-separated list of package locations |
| `prebuildNixShell` | string | `""` | Run `nix-build` on shell.nix package(s). Comma-separated list of package locations |
| `prebuildFlake` | string | `""` | Run `nix build` on the specified flake URI(s). Comma-separated list |
| `prebuildFlakeRun` | string | `""` | Like prebuildFlake, but uses `nix run` |
| `prebuildFlakeDevelop` | string | `""` | Like prebuildFlake, but uses `nix develop` |

**Flake URI Examples:**
```json
{
  "prebuildFlake": "flake.nix",
  "prebuildFlakeDevelop": "github:owner/repository#outputName"
}
```

**Supported Flake URI formats:**
- `flake.nix` - Local flake
- `github:owner/repository` - GitHub repository
- `github:owner/repository/ref` - Specific branch/tag
- `github:owner/repository/ref?dir=directory` - Subdirectory
- `github:owner/repository#outputName.outputChildName` - Specific output

### Channels and Registries

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `additionalNixChannel` | string | `""` | Comma-separated list of `{channel-name}={channel-url}` to add |
| `additionalNixFlakeRegistry` | string | `""` | Comma-separated list of `{flake-name}={flake-registry-uri}` to add |

**Examples:**
```json
{
  "additionalNixChannel": "nixpkgs-unstable=https://nixos.org/channels/nixpkgs-unstable,home-manager=https://github.com/nix-community/home-manager/archive/master.tar.gz"
}
```

```json
{
  "additionalNixFlakeRegistry": "nixpkgs=github:NixOS/nixpkgs/nixos-unstable,home-manager=github:nix-community/home-manager"
}
```

### Home Manager

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `prebuildHomeManager` | string | `""` | Install home-manager and activate configuration from a file path |
| `prebuildHomeManagerFlake` | string | `""` | Like prebuildHomeManager, but uses Nix Flake URI to specify configuration |

**Examples:**
```json
{
  "prebuildHomeManager": ".devcontainer/home.nix"
}
```

```json
{
  "prebuildHomeManagerFlake": "github:owner/repository#homeConfigurations.myconfig"
}
```

### Image Variants

The `imageVariant` option selects which base image to use:

| Variant | Description |
|---------|-------------|
| `v1` | Stable release (from `main` branch) |
| `latest` | Latest build (from `develop` branch) |
| `stable` | Alias for `v1` |
| `flake---v1` | Flake-based variant (stable) |
| `flake---latest` | Flake-based variant (latest) |
| `flake---stable` | Flake-based variant (stable alias) |
| `nixos-dockertools---v1` | NixOS experimental (stable) |
| `nixos-dockertools---latest` | NixOS experimental (latest) |
| `nixos-arion---v1` | NixOS via Arion (stable) |
| `nixos-arion---latest` | NixOS via Arion (latest) |

## Testing Templates

### Test Structure

Each test case includes:
- `arg.json` - Template options to test
- `overlay-files/` - Files to copy into the test workspace (e.g., `flake.nix`, `shell.nix`)
- `tests/test.sh` - Test script that validates the container setup

### Running Tests

#### Run All Tests via GitHub Actions

The `.github/workflows/test-pr.yaml` workflow automatically runs smoke tests on PR changes.

#### Run Tests Locally

Test a specific template variant:

```bash
cd templates

# Test the direnv variant
./test.sh nix nix-use-direnv

# Test the flake variant
./test.sh nix nix-use-flake

# Test home-manager
./test.sh nix nix-use-home-manager

# Test home-manager with flakes
./test.sh nix nix-use-home-manager-flake
```

The test script:
1. Copies the template to a temporary directory
2. Applies template options from `arg.json`
3. Builds the devcontainer using `devcontainer up`
4. Executes the test script inside the container
5. Cleans up the container and temporary files

### Writing Custom Tests

Use the test utilities from `test/test-utils/test-utils.sh`:

```bash
#!/bin/bash
cd $(dirname "$0")/../
source test-project/test-utils.sh

# Template specific tests
check "direnv status" direnv status
check "package installed" curl --version
check "custom script works" ./my-script.sh

# Report result
reportResults
```

**Available test utilities:**

- `check "label" command args...` - Run a command and mark pass/fail
- `reportResults` - Print summary and exit with appropriate code

### Test Workflow

The smoke test workflow (`.github/actions/smoke-test/`):

1. **Build** (`build.sh`):
   - Copy template to temp directory
   - Apply options from `arg.json`
   - Replace template variables
   - Copy overlay files
   - Run `devcontainer up`

2. **Test** (`test.sh`):
   - Execute `test.sh` inside the container
   - Check results
   - Clean up

## Publishing Templates

### Manual Publishing

```bash
cd templates
./devcontainer-publish-manual.sh
```

This runs:
```bash
devcontainer templates publish \
  -r ghcr.io \
  -n lucernae/devcontainer-nix \
  src
```

### Automated Publishing

The `.github/workflows/release.yaml` workflow:
- Publishes templates to GHCR on manual dispatch
- Auto-generates README documentation from `devcontainer-template.json`
- Creates a PR with updated docs

**DO NOT manually edit `src/nix/README.md`** - it is auto-generated from `devcontainer-template.json`.

## Example Configurations

### Minimal Setup (direnv only)

```json
{
  "useDirenv": "true",
  "useFlake": "false",
  "imageVariant": "v1"
}
```

### Flake-based Development

```json
{
  "useDirenv": "true",
  "useFlake": "true",
  "prebuildFlake": ".",
  "prebuildFlakeDevelop": ".",
  "imageVariant": "flake---latest"
}
```

### Home Manager Configuration

```json
{
  "useDirenv": "true",
  "useFlake": "true",
  "prebuildHomeManagerFlake": "github:username/dotfiles#homeConfigurations.devcontainer",
  "imageVariant": "flake---latest"
}
```

### Multi-channel Setup

```json
{
  "useDirenv": "true",
  "useFlake": "true",
  "additionalNixChannel": "nixpkgs-unstable=https://nixos.org/channels/nixpkgs-unstable",
  "installRootPackages": "nixpkgs.vim nixpkgs-unstable.neovim",
  "imageVariant": "latest"
}
```

## Contributing

When modifying templates:

1. Update `devcontainer-template.json` with new options
2. Add corresponding scripts to `library-scripts/build/` or `library-scripts/runtime/`
3. Create test cases in `test/`
4. Run local tests to validate
5. Create a PR - the README will be auto-generated on merge

## Resources

- [Devcontainer Specification](https://containers.dev/)
- [Devcontainer CLI Documentation](https://github.com/devcontainers/cli)
- [Nix Package Manager](https://nixos.org/)
- [Home Manager Documentation](https://nix-community.github.io/home-manager/)
- [Project Repository](https://github.com/lucernae/devcontainer-nix)
