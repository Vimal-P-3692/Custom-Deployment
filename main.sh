#!/bin/bash

set -e
trap 'echo "ERROR at line $LINENO. Command: $BASH_COMMAND"; exit 1' ERR

source ./detect_pkg.sh
source ./dotnet_utils.sh
source ./system_utils.sh
source ./build_utils.sh
source ./service_utils.sh 

REPO_URL=$1
DOTNET_VERSION=$2
PROJECT_SUB_PATH=$3
SERVICE_NAME=$4      
PORT=$5          

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

# Move into cloned repo first
REPO_NAME=$(basename "$REPO_URL" .git)
CLONED_PATH="$BASE_DIR/$REPO_NAME"

# Step 5: Move into required sub-folder
enter_project_path "$CLONED_PATH" "$PROJECT_SUB_PATH"

# Step 6: Build steps
dotnet_restore
dotnet_build
dotnet_publish

# Step 7: Service setup
PUBLISH_PATH="$(pwd)/publish"

echo "Using publish path: $PUBLISH_PATH"

create_service_file "$SERVICE_NAME" "$PORT" "$PUBLISH_PATH"
reload_systemd
start_service "$SERVICE_NAME"
check_service_status "$SERVICE_NAME"

# Step 8: Web server + HTTPS
install_nginx
setup_nginx_reverse_proxy "$SERVICE_NAME" "$PORT"

install_certbot
DOMAIN=$6
enable_https "$DOMAIN"

echo "Deployment + Service setup completed successfully!"