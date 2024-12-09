#!/bin/bash

# Function to install necessary packages with checks
install_dependencies() {
    echo "Installing necessary dependencies..."
    required_packages=("git" "wget" "curl" "python" "python3-pip" "clang" "make" "unzip")
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$package"; then
            apt install -y "$package" || { echo "Failed to install $package"; exit 1; }
        fi
    done
    echo "Dependencies installed."
}

# Function to configure SSH key for GitHub (automate adding key to GitHub using GitHub API)
setup_ssh_key() {
    echo "Checking for SSH key setup..."
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        echo "SSH key not found, creating a new one..."
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
        echo "SSH key generated, adding to GitHub..."
        key=$(cat "$HOME/.ssh/id_rsa.pub")
        curl -u "your_github_username" -X POST -H "Content-Type: application/json" \
            -d "{\"title\":\"Termux Key\",\"key\":\"$key\"}" \
            "https://api.github.com/user/keys" || { echo "Failed to add SSH key to GitHub"; exit 1; }
    else
        echo "SSH key found."
    fi
}

# Function to clone and setup Verus miner from GitHub with backup mirrors
clone_miner_repo() {
    echo "Cloning miner repositories..."
    MINER_REPOS=("https://github.com/oink70/VerusMiner.git" "https://github.com/username/alternative-repo.git")
    for repo in "${MINER_REPOS[@]}"; do
        git clone "$repo" || {
            echo "Failed to clone repository $repo, trying next mirror..."
            continue
        }
        echo "Cloned repository from $repo"
        break
    done
}

# Function to install required miners with retries and backup methods
install_miners() {
    echo "Installing miners..."
    MINERS=("oink70" "verus-cli" "xmrig")
    for miner in "${MINERS[@]}"; do
        echo "Attempting to install $miner..."
        if ! git clone "https://github.com/oink70/VerusMiner.git"; then
            echo "Failed to clone $miner from GitHub, trying backup mirrors..."
            wget -O miner.zip https://mirror1.example.com/VerusMiner.zip || wget -O miner.zip https://mirror2.example.com/VerusMiner.zip
            unzip miner.zip
        fi
    done
}

# Function to configure miner automatically (wallet address, pool address)
configure_miner() {
    echo "Configuring miner..."
    miner_config="$HOME/VerusMiner/config.conf"
    if [ -f "$miner_config" ]; then
        sed -i 's/POOL_ADDRESS/new_pool_address/g' "$miner_config"
        sed -i 's/WALLET_ADDRESS/new_wallet_address/g' "$miner_config"
        echo "Miner configured."
    else
        echo "Miner configuration file not found."
        exit 1
    fi
}

# Function to start mining with error handling
start_mining() {
    echo "Starting the mining process..."
    if [ -f "$HOME/VerusMiner/your_miner_executable" ]; then
        ./VerusMiner/your_miner_executable & 
        echo "Mining started."
    else
        echo "Miner executable not found."
        exit 1
    fi
}

# Function for watchdog process to monitor mining and restart if necessary
watchdog() {
    while true; do
        if ! pgrep -x "your_miner_executable" > /dev/null; then
            echo "Miner stopped, restarting..."
            start_mining
        fi
        sleep 60
    done
}

# Function to check for updates automatically
check_for_updates() {
    echo "Checking for updates..."
    git -C "$HOME/VerusMiner" pull origin main || echo "Failed to pull updates."
}

# Function to view logs and handle log file rotation
view_logs() {
    echo "Displaying miner logs..."
    tail -n 50 "$HOME/VerusMiner/miner.log"
}

# Function for auto-start on boot (add cron job for Termux)
auto_start() {
    echo "Setting up auto-start for the mining process..."
    (crontab -l 2>/dev/null; echo "@reboot $HOME/automated-termux-mining.sh") | crontab -
    echo "Auto-start configured."
}

# Main setup function with expanded features
main() {
    echo "========= Verus Mining Script ========="
    echo "1. Setup Environment"
    echo "2. Install/Update Miners"
    echo "3. Configure Miner"
    echo "4. Start Mining"
    echo "5. Enable Watchdog"
    echo "6. View Logs"
    echo "7. Check for Updates"
    echo "8. Setup Auto-Start"
    echo "9. Exit"
    echo "======================================="

    select option in "Setup Environment" "Install/Update Miners" "Configure Miner" "Start Mining" "Enable Watchdog" "View Logs" "Check for Updates" "Setup Auto-Start" "Exit"; do
        case $option in
            "Setup Environment")
                install_dependencies
                setup_ssh_key
                ;;
            "Install/Update Miners")
                install_miners
                ;;
            "Configure Miner")
                configure_miner
                ;;
            "Start Mining")
                start_mining
                ;;
            "Enable Watchdog")
                watchdog
                ;;
            "View Logs")
                view_logs
                ;;
            "Check for Updates")
                check_for_updates
                ;;
            "Setup Auto-Start")
                auto_start
                ;;
            "Exit")
                echo "Exiting script."
                break
                ;;
            *)
                echo "Invalid option, try again."
                ;;
        esac
    done
}

main
