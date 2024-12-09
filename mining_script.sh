#!/bin/bash

# ======= Global Variables =======
MINERS=("oink70" "verus-cli" "xmrig")
CONFIG_FILE="config.txt"
LOG_FILE="mining_log.txt"
ARCH=$(uname -m)
DEFAULT_POOL="na.luckpool.net:3956"
CLOUD_SYNC_INTERVAL=600  # Sync every 10 minutes
WATCHDOG_INTERVAL=60     # Watchdog check every minute
DOWNLOAD_URLS=(
    "https://github.com/oink70/VerusMiner.git"
    "https://mirror1.example.com/VerusMiner.zip"
    "https://mirror2.example.com/VerusMiner.zip"
)

# ======= Advanced Functions =======

# Setup Dependencies with Retry Logic
setup_environment() {
    echo "Setting up dependencies..."
    for attempt in {1..3}; do
        if pkg update -y && pkg upgrade -y && pkg install -y git clang make wget nano curl python openssh zip unzip; then
            pip install flask && echo "Environment setup completed." && return 0
        else
            echo "Retrying dependency setup... ($attempt/3)"
        fi
    done
    echo "Error: Failed to set up dependencies after multiple attempts."
    exit 1
}

# Robust Downloader with Enhanced Logging
robust_download() {
    local target_dir="$1"
    local repo_name="$2"
    echo "Downloading $repo_name..."

    for url in "${DOWNLOAD_URLS[@]}"; do
        echo "Trying $url..."
        if [[ $url == *.git ]]; then
            git clone "$url" "$target_dir" && return 0
        elif [[ $url == *.zip ]]; then
            wget "$url" -O "${repo_name}.zip" && unzip "${repo_name}.zip" -d "$target_dir" && rm "${repo_name}.zip" && return 0
        fi
    done

    echo "Error: All download methods failed for $repo_name."
    return 1
}

# Install or Update Miners
install_miners() {
    echo "Installing miners..."
    for miner in "${MINERS[@]}"; do
        if [ ! -d "$miner" ]; then
            echo "Installing $miner..."
            robust_download "$miner" "$miner" || echo "Failed to install $miner."
        else
            echo "Updating $miner..."
            cd "$miner" || continue
            git pull || robust_download "$miner" "$miner"
            cd ..
        fi
    done
}

# Auto-Updater for All Components
auto_update() {
    echo "Performing auto-update..."
    setup_environment
    install_miners
    echo "Auto-update completed."
}

# Configure Miner with Validation
configure_miner() {
    echo "Configuring miner..."
    read -p "Enter your Verus wallet address: " wallet
    while [[ ! $wallet =~ ^[a-zA-Z0-9]{34,36}$ ]]; do
        echo "Invalid wallet address. Please try again."
        read -p "Enter your Verus wallet address: " wallet
    done

    read -p "Enter pool URL [Default: $DEFAULT_POOL]: " pool
    pool=${pool:-$DEFAULT_POOL}

    cat > $CONFIG_FILE <<EOL
pool=$pool
user=$wallet
pass=x
algo=verushash
EOL
    echo "Configuration saved."
}

# Select Best Available Miner
select_best_miner() {
    for miner in "${MINERS[@]}"; do
        if [ -d "$miner" ]; then
            echo "$miner selected."
            echo $miner
            return 0
        fi
    done
    echo "No miners available. Please install miners first."
    exit 1
}

# Start Mining with Fallback
start_mining() {
    miner=$(select_best_miner)
    echo "Starting mining with $miner..."
    source $CONFIG_FILE

    cd "$miner" || exit
    case $miner in
    "oink70")
        ./verusminer -o $pool -u $user -p $pass --algo $algo --intensity medium || echo "Error: Mining failed with $miner."
        ;;
    "xmrig")
        ./xmrig --url=$pool --user=$user --pass=$pass --algo=$algo || echo "Error: Mining failed with $miner."
        ;;
    *)
        echo "Unsupported miner: $miner."
        ;;
    esac
}

# Watchdog to Ensure Uptime
watchdog() {
    echo "Starting watchdog..."
    while true; do
        if ! pgrep -f "verusminer|xmrig" > /dev/null; then
            echo "Miner not running. Restarting..."
            start_mining
        fi
        sleep $WATCHDOG_INTERVAL
    done
}

# Cloud Sync for Logs
cloud_sync() {
    echo "Starting cloud sync..."
    mkdir -p logs
    while true; do
        timestamp=$(date +%Y%m%d%H%M%S)
        cp $LOG_FILE "logs/mining_log_$timestamp.txt"
        git -C logs add . && git -C logs commit -m "Auto-sync logs $timestamp" && git -C logs push origin main
        sleep $CLOUD_SYNC_INTERVAL
    done
}

# Main Menu with Fail-Safe
main_menu() {
    while true; do
        echo "========= Verus Mining Script ========="
        echo "1. Setup Environment"
        echo "2. Install/Update Miners"
        echo "3. Configure Miner"
        echo "4. Start Mining"
        echo "5. Enable Watchdog"
        echo "6. View Logs"
        echo "7. Check for Updates"
        echo "8. Exit"
        echo "======================================="
        read -p "Select an option: " choice

        case $choice in
        1) setup_environment ;;
        2) install_miners ;;
        3) configure_miner ;;
        4) start_mining ;;
        5) watchdog & ;;
        6) tail -f $LOG_FILE ;;
        7) auto_update ;;
        8) echo "Exiting. Happy mining!"; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# ======= Script Execution =======
main_menu
