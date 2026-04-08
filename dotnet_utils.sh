#!/bin/bash

set -e

log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

error_exit() {
    echo "[ERROR] $1"
    exit 1
}

# Function: Check if required .NET version is installed
check_dotnet_version() {
    REQUIRED_VERSION=$1

    if ! command -v dotnet >/dev/null 2>&1; then
        warn ".NET is not installed"
        return 1
    fi

    log "Checking installed .NET SDKs..."

    # Get all installed SDK versions
    INSTALLED_VERSIONS=$(dotnet --list-sdks | awk '{print $1}')

    echo "Installed SDKs:"
    echo "$INSTALLED_VERSIONS"

    for version in $INSTALLED_VERSIONS; do
        if [[ "$version" == "$REQUIRED_VERSION"* ]]; then
            log "Required .NET version $REQUIRED_VERSION is already installed"
            return 0
        fi
    done

    warn "Required .NET version not found"
    return 1
}

# Function: Install required .NET version
install_dotnet_version() {
    REQUIRED_VERSION=$1

    # 🔹 Skip if already installed
    if check_dotnet_version "$REQUIRED_VERSION"; then
        log "Skipping installation (already installed)"
        return 0
    fi

    log "Installing .NET SDK version $REQUIRED_VERSION..."

    INSTALL_SCRIPT="dotnet-install.sh"

    # Download only if not already present
    if [ ! -f "$INSTALL_SCRIPT" ]; then
        log "Downloading dotnet-install.sh..."
        wget https://dot.net/v1/dotnet-install.sh -O "$INSTALL_SCRIPT" \
            || error_exit "Failed to download installer"
        chmod +x "$INSTALL_SCRIPT"
    else
        log "Installer already exists. Skipping download..."
    fi

    # Run installer
    ./"$INSTALL_SCRIPT" --version "$REQUIRED_VERSION" \
        || error_exit ".NET installation failed"

    export PATH="$HOME/.dotnet:$PATH"

    # Verify installation
    if check_dotnet_version "$REQUIRED_VERSION"; then
        log ".NET SDK $REQUIRED_VERSION installed successfully"
    else
        error_exit "Installation completed but version not found"
    fi
}