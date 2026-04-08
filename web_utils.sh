#!/bin/bash

set -e

source ./detect_pkg.sh

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

is_installed() {
    command -v "$1" >/dev/null 2>&1
}

install_nginx() {
    if is_installed nginx; then
        log "Nginx already installed. Skipping..."
        return
    fi

    detect_package_manager

    log "Installing Nginx..."

    case "$PKG_MANAGER" in
        apt)
            sudo apt update -y || error_exit "apt update failed"
            sudo apt install -y nginx || error_exit "Nginx install failed"
            ;;
        dnf|yum)
            sudo $PKG_MANAGER install -y nginx || error_exit "Nginx install failed"
            ;;
        pacman)
            sudo pacman -Sy --noconfirm nginx || error_exit "Nginx install failed"
            ;;
        *)
            error_exit "Unsupported package manager"
            ;;
    esac

    sudo systemctl enable nginx || warn "Failed to enable nginx"
    sudo systemctl start nginx || error_exit "Failed to start nginx"

    log "Nginx installed and started"
}

install_certbot() {
    if is_installed certbot; then
        log "Certbot already installed. Skipping..."
        return
    fi

    detect_package_manager

    log "Installing Certbot..."

    case "$PKG_MANAGER" in
        apt)
            sudo apt install -y certbot python3-certbot-nginx || error_exit "Certbot install failed"
            ;;
        dnf|yum)
            sudo $PKG_MANAGER install -y certbot python3-certbot-nginx || error_exit "Certbot install failed"
            ;;
        pacman)
            sudo pacman -Sy --noconfirm certbot certbot-nginx || error_exit "Certbot install failed"
            ;;
        *)
            error_exit "Unsupported package manager"
            ;;
    esac

    log "Certbot installed"
}

setup_nginx_reverse_proxy() {
    SERVICE_NAME=$1
    PORT=$2

    CONFIG_FILE="/etc/nginx/conf.d/${SERVICE_NAME}.conf"

    if [ -f "$CONFIG_FILE" ]; then
        warn "Nginx config already exists. Skipping..."
        return
    fi

    log "Creating Nginx reverse proxy config..."

    sudo bash -c "cat > $CONFIG_FILE" <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    sudo nginx -t || error_exit "Nginx config test failed"
    sudo systemctl reload nginx || error_exit "Failed to reload nginx"

    log "Nginx reverse proxy configured"
}

enable_https() {
    DOMAIN=$1

    if [ -z "$DOMAIN" ]; then
        warn "No domain provided. Skipping HTTPS..."
        return
    fi

    if ! is_installed certbot; then
        warn "Certbot not installed. Installing..."
        install_certbot
    fi

    log "Enabling HTTPS for $DOMAIN..."

    sudo certbot --nginx -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        -m admin@"$DOMAIN" \
        --redirect || error_exit "HTTPS setup failed"

    log "HTTPS enabled for $DOMAIN"
}