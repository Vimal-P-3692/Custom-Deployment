#!/bin/bash

set -e
trap 'echo "ERROR at line $LINENO"; exit 1' ERR

# -------------------------------
# LOAD MODULES
# -------------------------------

source ./detect_pkg.sh || { echo "Failed to load detect_pkg.sh"; exit 1; }
source ./dotnet_utils.sh || { echo "Failed to load dotnet_utils.sh"; exit 1; }
source ./system_utils.sh || { echo "Failed to load system_utils.sh"; exit 1; }
source ./build_utils.sh || { echo "Failed to load build_utils.sh"; exit 1; }

# -------------------------------
# INPUTS
# -------------------------------

REPO_URL=$1
DOTNET_VERSION=$2
PROJECT_PATH=${3:-$HOME}

[ -z "$REPO_URL" ] && { echo "Repo URL required"; exit 1; }
[ -z "$DOTNET_VERSION" ] && { echo "Dotnet version required"; exit 1; }

# -------------------------------
# STEP 1: DETECT PACKAGE MANAGER
# -------------------------------

detect_package_manager

# -------------------------------
# STEP 2: CHECK / INSTALL GIT
# -------------------------------

if ! check_git; then
    install_git || { echo "Git installation failed"; exit 1; }
fi

# -------------------------------
# STEP 3: CHECK / INSTALL DOTNET
# -------------------------------

if ! check_dotnet_version "$DOTNET_VERSION"; then
    install_dotnet_version "$DOTNET_VERSION" || {
        echo "Dotnet installation failed"
        exit 1
    }
fi

# -------------------------------
# STEP 4: INSTALL ICU
# -------------------------------

install_icu || { echo "ICU installation failed"; exit 1; }

# -------------------------------
# STEP 5: CLONE REPO
# -------------------------------

clone_repo "$REPO_URL" "$PROJECT_PATH" || {
    echo "Repo clone failed"
    exit 1
}

# -------------------------------
# STEP 6: BUILD PROCESS
# -------------------------------

dotnet_restore || exit 1
dotnet_build || exit 1
dotnet_publish || exit 1

# -------------------------------
# DONE
# -------------------------------

echo "--------------------------------------"
echo "Deployment completed successfully!"
echo "--------------------------------------"