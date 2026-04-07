#!/bin/bash

# Load package manager (do NOT exit here)
source ./detect_pkg.sh || return 1

# -------------------------------
# ICU FUNCTIONS
# -------------------------------

install_icu() {
    echo "Checking ICU library..."

    if ! ldconfig -p | grep -q libicu; then
        echo "ICU not found. Installing..."

        case $PKG_MANAGER in
            apt)
                sudo apt update || return 1
                sudo apt install -y libicu-dev || return 1
                ;;
            dnf)
                sudo dnf install -y icu || return 1
                ;;
            yum)
                sudo yum install -y icu || return 1
                ;;
            pacman)
                sudo pacman -S --noconfirm icu || return 1
                ;;
        esac

        echo "ICU installed successfully"
    else
        echo "ICU already installed"
    fi

    return 0
}

# -------------------------------
# GIT
# -------------------------------

check_git() {
    if command -v git >/dev/null 2>&1; then
        echo "Git already installed"
        return 0
    else
        echo "❌ Git not installed"
        return 1
    fi
}

install_git() {
    echo "Installing Git..."

    case $PKG_MANAGER in
        apt)
            sudo apt update || return 1
            sudo apt install -y git || return 1
            ;;
        dnf)
            sudo dnf install -y git || return 1
            ;;
        yum)
            sudo yum install -y git || return 1
            ;;
        pacman)
            sudo pacman -S --noconfirm git || return 1
            ;;
    esac

    echo "Git installed successfully"
    return 0
}