#!/usr/bin/env bash
# Set debugging options to help diagnose issues
set -x

echo "Starting direnv setup script..."

# Automatically try to use direnv if the .envrc file exists, regardless of USE_DIRENV variable
if [[ -f /workspaces/devcontainer-nix/.envrc ]]; then
    echo "Found .envrc file in workspace root"
    cd /workspaces/devcontainer-nix
    
    # Check if direnv is installed
    if command -v direnv &> /dev/null; then
        echo "Allowing direnv for workspace root"
        direnv allow .
        
        # Run a simple command to activate the environment
        direnv exec . echo "Direnv environment activated successfully"
        
        # If we have a specific USE_DIRENV flag, log it
        if [[ "${USE_DIRENV}" == "true" ]]; then
            echo "USE_DIRENV is set to true"
        else
            echo "USE_DIRENV variable not set to true, but activating direnv anyway"
        fi
    else
        echo "direnv command not found, cannot activate environment"
    fi
else
    echo "No .envrc file found in workspace root"
fi

echo "Direnv setup script completed"
