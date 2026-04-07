#!/bin/bash

# Function: Create systemd service file
create_service_file() {
    SERVICE_NAME=$1
    PORT=$2
    PROJECT_PATH=$3

    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

    echo "Creating systemd service: $SERVICE_NAME"

    [ -z "$SERVICE_NAME" ] && { echo "Service name is required"; return 1; }
    [ -z "$PORT" ] && { echo "Port is required"; return 1; }
    [ -z "$PROJECT_PATH" ] && { echo "Project path is required"; return 1; }

    # Determine main project DLL
    PROJECT_NAME=$(basename "$PROJECT_PATH")
    DLL_FILE=$(find "$PROJECT_PATH" -maxdepth 1 -name "$PROJECT_NAME.dll" | head -n 1)

    # Fallback: pick first DLL in publish folder
    if [ -z "$DLL_FILE" ]; then
        DLL_FILE=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.dll" | head -n 1)
    fi

    [ -z "$DLL_FILE" ] && { echo "No DLL file found in $PROJECT_PATH"; return 1; }

    echo "Project name: $PROJECT_NAME"
    echo "Using DLL: $DLL_FILE"

    # Create systemd service
    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=$SERVICE_NAME service
After=network.target

[Service]
WorkingDirectory=$PROJECT_PATH
ExecStart=$HOME/.dotnet/dotnet $DLL_FILE --urls "http://0.0.0.0:$PORT"
Restart=always
RestartSec=10
SyslogIdentifier=$SERVICE_NAME
User=$(whoami)
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
EOF

    [ $? -ne 0 ] && { echo "Failed to create service file"; return 1; }

    echo "Service file created: $SERVICE_FILE"
    return 0
}

# Function: Reload systemd 
reload_systemd() 
{ 
    echo "Reloading systemd daemon..." 
    sudo systemctl daemon-reexec || { echo "daemon-reexec failed";  return 1; } 
    sudo systemctl daemon-reload || { echo "daemon-reload failed"; return 1; } 
    echo "systemd reloaded" 
}

# Function: Enable and start service 
start_service() 
{ 
    SERVICE_NAME=$1 
    echo "Starting service: $SERVICE_NAME" 
    sudo systemctl enable "$SERVICE_NAME" \ || { echo "Failed to enable service"; return 1; } 
    sudo systemctl restart "$SERVICE_NAME" \ || { echo "Failed to start service"; return 1; } 
    echo "Service started successfully" 
}

# Function: Check status 
check_service_status() 
{ 
    SERVICE_NAME=$1 echo "Checking service status..." 
    sudo systemctl status "$SERVICE_NAME" --no-pager \ || { echo "Failed to get service status"; return 1; } 
}