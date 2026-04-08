#!/bin/bash

set -e

log() {
    echo "[INFO] $1"
}

error_exit() {
    echo "[ERROR] $1"
    exit 1
}

# 🔹 Get correct DLL
get_main_dll() {
    PUBLISH_PATH=$1
    PROJECT_NAME=$2

    DLL_FILE="$PUBLISH_PATH/$PROJECT_NAME.dll"

    [ ! -f "$DLL_FILE" ] && error_exit "Main DLL not found: $DLL_FILE"

    echo "$DLL_FILE"
}

# 🔹 Create systemd service
create_service_file() {
    SERVICE_NAME=$(echo "$1" | xargs)
    PORT=$2
    PROJECT_PATH=$3
    PROJECT_NAME=$4

    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

    # ✅ Validations
    [ -z "$SERVICE_NAME" ] && error_exit "Service name is required"
    [[ "$SERVICE_NAME" =~ \  ]] && error_exit "Service name should not contain spaces"

    [ -z "$PORT" ] && error_exit "Port is required"
    [ -z "$PROJECT_PATH" ] && error_exit "Project path is required"

    log "Creating systemd service: $SERVICE_NAME"

    DLL_FILE=$(get_main_dll "$PROJECT_PATH" "$PROJECT_NAME")

    log "Using DLL: $DLL_FILE"

    # ✅ Create service file
    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=$SERVICE_NAME service
After=network.target

[Service]
WorkingDirectory=$PROJECT_PATH
ExecStart=$HOME/.dotnet/dotnet $DLL_FILE --urls=http://0.0.0.0:$PORT
Restart=always
RestartSec=10
SyslogIdentifier=$SERVICE_NAME
User=$(whoami)
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
EOF

    log "Service file created: $SERVICE_FILE"
}

# 🔹 Reload systemd
reload_systemd() {
    log "Reloading systemd daemon..."

    sudo systemctl daemon-reexec || error_exit "daemon-reexec failed"
    sudo systemctl daemon-reload || error_exit "daemon-reload failed"

    log "systemd reloaded"
}

# 🔹 Enable & start service
start_service() {
    SERVICE_NAME=$(echo "$1" | xargs)
    log "Service name after trim: '$SERVICE_NAME'"

    [ -z "$SERVICE_NAME" ] && error_exit "Service name required"

    log "Starting service: $SERVICE_NAME"

    sudo systemctl enable "${SERVICE_NAME}.service" || error_exit "Failed to enable service"
    sudo systemctl restart "${SERVICE_NAME}.service" || error_exit "Failed to start service"

    log "Service started successfully"
}

# 🔹 Check status
check_service_status() {
    SERVICE_NAME=$1

    log "Checking service status..."

    sudo systemctl status "$SERVICE_NAME" --no-pager \
        || error_exit "Failed to get service status"
}