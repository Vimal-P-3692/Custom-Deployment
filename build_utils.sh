#!/bin/bash

# -------------------------------
# CLONE REPOSITORY
# -------------------------------

clone_repo() {
    REPO_URL=$1
    TARGET_PATH=${2:-$HOME}

    [ -z "$REPO_URL" ] && { echo "Repo URL not provided"; return 1; }

    cd "$TARGET_PATH" || { echo "Cannot access path: $TARGET_PATH"; return 1; }

    REPO_NAME=$(basename "$REPO_URL" .git)

    if [ -d "$REPO_NAME" ]; then
        echo "Repo already exists. Skipping clone..."
    else
        echo "Cloning repository..."
        git clone "$REPO_URL" || { echo "Git clone failed"; return 1; }
    fi

    cd "$REPO_NAME" || { echo "Failed to enter repo directory"; return 1; }

    return 0
}

# -------------------------------
# RESTORE DEPENDENCIES
# -------------------------------

dotnet_restore() {
    echo "Restoring dependencies..."

    dotnet restore || { echo "dotnet restore failed"; return 1; }

    echo "Restore completed"
    return 0
}

# -------------------------------
# BUILD PROJECT
# -------------------------------

dotnet_build() {
    echo "Building project..."

    PROJECT_FILE=$(find . -name "*.csproj" | head -n 1)

    [ -z "$PROJECT_FILE" ] && { echo "No .csproj file found"; return 1; }

    dotnet build "$PROJECT_FILE" --no-restore \
        || { echo "dotnet build failed"; return 1; }

    echo "Build completed"
    return 0
}

# -------------------------------
# PUBLISH PROJECT
# -------------------------------

dotnet_publish() {
    OUTPUT_DIR=${1:-publish}

    echo "Publishing project..."

    PROJECT_FILE=$(find . -name "*.csproj" | head -n 1)

    [ -z "$PROJECT_FILE" ] && { echo "No .csproj file found"; return 1; }

    dotnet publish "$PROJECT_FILE" -c Release -o "$OUTPUT_DIR" \
        || { echo "dotnet publish failed"; return 1; }

    echo "Publish completed → $OUTPUT_DIR"
    return 0
}