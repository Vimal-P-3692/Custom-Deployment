#!/bin/bash

# Function: Check if required .NET version is installed
check_dotnet_version() {
    REQUIRED_VERSION=$1

    if command -v dotnet >/dev/null 2>&1; then
        INSTALLED_VERSION=$(dotnet --version)

        echo "Installed .NET version: $INSTALLED_VERSION"
        echo "Required .NET version: $REQUIRED_VERSION"

        if [[ "$INSTALLED_VERSION" == "$REQUIRED_VERSION"* ]]; then
            echo "Required .NET version is already installed"
            return 0
        else
            echo "Different .NET version found"
            return 1
        fi
    else
        echo ".NET is not installed"
        return 1
    fi
}

# Function: Install required .NET version
install_dotnet_version() {
    REQUIRED_VERSION=$1

    echo "Installing .NET SDK version $REQUIRED_VERSION..."

    wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
        || { echo "Failed to download installer"; return 1; }

    chmod +x dotnet-install.sh || return 1

    ./dotnet-install.sh --version "$REQUIRED_VERSION" \
        || { echo ".NET installation failed"; return 1; }

    export PATH="$HOME/.dotnet:$PATH"

    echo ".NET SDK $REQUIRED_VERSION installed successfully"
    return 0
}