#!/bin/bash

# Function: Clone repo
clone_repo() {
    REPO_URL=$1
    TARGET_DIR=$2

    echo "Cloning repository..."

    git clone "$REPO_URL" "$TARGET_DIR" \
        || { echo "Failed to clone repository"; return 1; }

    echo "Repository cloned into $TARGET_DIR"
    return 0
}

# Function: Enter project path inside repo
enter_project_path() {
    BASE_DIR=$1
    PROJECT_PATH=$2

    FULL_PATH="$BASE_DIR/$PROJECT_PATH"

    echo "Navigating to project path: $FULL_PATH"

    [ ! -d "$FULL_PATH" ] && { echo "Path does not exist: $FULL_PATH"; return 1; }

    cd "$FULL_PATH" || { echo "Failed to enter directory"; return 1; }

    echo "Now inside $(pwd)"
    return 0
}

# Function: Restore
dotnet_restore() {
    echo "Restoring project..."

    dotnet restore \
        || { echo "dotnet restore failed"; return 1; }

    echo "Restore completed"
    return 0
}

# Function: Build
dotnet_build() {
    echo "Building project..."

    PROJECT_FILE=$(find . -name "*.csproj" | head -n 1)

    [ -z "$PROJECT_FILE" ] && { echo "No .csproj file found"; return 1; }

    dotnet build "$PROJECT_FILE" --no-restore \
        || { echo "dotnet build failed"; return 1; }

    echo "Build completed"
    return 0
}

# Function: Publish
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