#!/bin/bash

# For detecting which package manager does the system uses.
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
    else
        echo "❌ ERROR: Unsupported package manager"
        exit 1
    fi

    export PKG_MANAGER
    echo "Using Package Manager: $PKG_MANAGER"
}