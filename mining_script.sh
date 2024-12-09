#!/bin/bash

# Colors for better visuals
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Log file for errors
LOG_FILE="error_log.txt"

function log_error {
    echo -e "${RED}[Error] $1${RESET}" | tee -a $LOG_FILE
}

function log_info {
    echo -e "${GREEN}[Info] $1${RESET}"
}

# Function to install miners
function install_miner {
    local miner_name=$1
    local repo_url=$2
    local backup_urls=("${@:3}")

    log_info "Installing $miner_name..."
    log_info "Trying to clone from $repo_url"

    # Prompt for GitHub PAT
    read -p "Enter your GitHub PAT (or press Enter to skip): " pat
    if [[ -n $pat ]]; then
        git clone https://$pat@$repo_url || log_error "$miner_name GitHub clone failed."
    else
        git clone https://$repo_url || log_error "$miner_name GitHub clone failed."
    fi

    # If cloning fails, try backups
    if [[ ! -d "$miner_name" ]]; then
        for url in "${backup_urls[@]}"; do
            log_info "Trying $url..."
            wget "$url" -O "$miner_name.zip" || log_error "Failed to download $url"
            if [[ -f "$miner_name.zip" ]]; then
                unzip "$miner_name.zip" -d "$miner_name"
                [[ -d "$miner_name" ]] && break
            fi
        done
    fi

    if [[ ! -d "$miner_name" ]]; then
        log_error "All download methods failed for $miner_name."
        return 1
    fi

    log_info "$miner_name installation complete."
    return 0
}

# Main menu
function main_menu {
    while true; do
        echo "========= Verus Mining Script ========="
        echo "1. Setup Environment"
        echo "2. Install Miners"
        echo "3. Start Mining"
        echo "4. Exit"
        echo "======================================="
        read -p "Select an option: " option

        case $option in
        1)
            log_info "Setting up dependencies..."
            apt update && apt upgrade -y
            apt install git wget curl unzip -y
            log_info "Environment setup complete."
            ;;
        2)
            install_miner "oink70" "github.com/oink70/VerusMiner.git" \
                "https://mirror1.example.com/oink70.zip" \
                "https://mirror2.example.com/oink70.zip" \
                "https://raw.githubusercontent.com/MrNova420/automated-termux-mining/main/prebuilt/oink70.zip"
            ;;
        3)
            log_info "Starting mining (placeholder)..."
            ;;
        4)
            log_info "Exiting script. Goodbye!"
            break
            ;;
        *)
            log_error "Invalid option. Please try again."
            ;;
        esac
    done
}

main_menu
