#!/bin/bash

set -e
trap 'echo "ERROR at line $LINENO. Command: $BASH_COMMAND"; exit 1' ERR

source ./detect_pkg.sh
source ./dotnet_utils.sh
source ./system_utils.sh
source ./build_utils.sh  

REPO_URL=$1
DOTNET_VERSION=$2
PROJECT_SUB_PATH=$3  

BASE_DIR="$HOME"

# Step 1: Detect package manager
detect_package_manager

# Step 2: Install dependencies
install_icu

if ! check_git; then
    install_git
fi

# Step 3: .NET
if ! check_dotnet_version "$DOTNET_VERSION"; then
    install_dotnet_version "$DOTNET_VERSION"
fi

# Step 4: Clone repo
clone_repo "$REPO_URL" "$BASE_DIR"

# Step 5: Move into required sub-folder
enter_project_path "$BASE_DIR" "$PROJECT_SUB_PATH"

# Step 6: Build steps
dotnet_restore
dotnet_build
dotnet_publish

echo "Deployment completed successfully!"