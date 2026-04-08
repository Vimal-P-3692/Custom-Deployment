#!/bin/bash

set -e

log() {
    echo "[INFO] $1"
}

error_exit() {
    echo "[ERROR] $1"
    exit 1
}

# Function: Clone repo (idempotent)
clone_repo() {
    REPO_URL=$1
    TARGET_DIR=$2

    command -v git >/dev/null 2>&1 || error_exit "Git not installed"

    REPO_NAME=$(basename "$REPO_URL" .git)
    TARGET_PATH="$TARGET_DIR/$REPO_NAME"

    log "Preparing repository at $TARGET_PATH..."

    mkdir -p "$TARGET_DIR" || error_exit "Failed to create/access $TARGET_DIR"
    cd "$TARGET_DIR" || error_exit "Failed to access $TARGET_DIR"

    if [ -d "$TARGET_PATH/.git" ]; then
        log "Repository exists. Pulling latest changes..."
        cd "$TARGET_PATH" || error_exit "Failed to enter repo"
        git pull || error_exit "Git pull failed"
    else
        log "Cloning repository..."
        git clone "$REPO_URL" "$TARGET_PATH" \
            || error_exit "Failed to clone repository"
    fi

    export CLONED_PATH="$TARGET_PATH"
    log "Repository ready: $CLONED_PATH"
}

# Function: Enter project path inside repo
enter_project_path() {
    BASE_DIR=$1
    PROJECT_PATH=$2

    FULL_PATH="$BASE_DIR/$PROJECT_PATH"

    log "Navigating to project path: $FULL_PATH"

    [ ! -d "$FULL_PATH" ] && error_exit "Path does not exist: $FULL_PATH"

    cd "$FULL_PATH" || error_exit "Failed to enter directory"

    log "Now inside $(pwd)"
}

# Function: Find correct .csproj
find_project_file() {
    PROJECT_FILE=$(find . -maxdepth 2 -name "*.csproj" ! -name "*Test*" | head -n 1)

    [ -z "$PROJECT_FILE" ] && error_exit "No valid .csproj file found"

    echo "$PROJECT_FILE"
}

# Function: Restore
dotnet_restore() {
    log "Restoring project..."

    dotnet restore \
        || error_exit "dotnet restore failed"

    log "Restore completed"
}

# Function: Build
dotnet_build() {
    log "Building project..."

    PROJECT_FILE=$(find_project_file)

    log "Using project file: $PROJECT_FILE"

    dotnet build "$PROJECT_FILE" --no-restore \
        || error_exit "dotnet build failed"

    log "Build completed"
}

# Function: Publish
dotnet_publish() {
    OUTPUT_DIR=${1:-publish}

    log "Publishing project..."

    PROJECT_FILE=$(find_project_file)

    log "Using project file: $PROJECT_FILE"

    dotnet publish "$PROJECT_FILE" -c Release -o "$OUTPUT_DIR" \
        || error_exit "dotnet publish failed"

    log "Publish completed → $OUTPUT_DIR"
}