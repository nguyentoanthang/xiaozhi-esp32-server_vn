#!/bin/sh
# Script author: @VanillaNahida
# This file automatically downloads the files required by this project in one step and creates the directories
# Currently only the x86 version of Ubuntu is supported; other systems are untested

# Define the interrupt handler
handle_interrupt() {
    echo ""
    echo "Installation was interrupted by the user (Ctrl+C or Esc)"
    echo "To reinstall, please run the script again"
    exit 1
}

# Set up signal trapping to handle Ctrl+C
trap handle_interrupt SIGINT

# Handle the Esc key
# Save the terminal settings
old_stty_settings=$(stty -g)
# Make the terminal respond immediately without echo
stty -icanon -echo min 1 time 0

# Background process that detects the Esc key
(while true; do
    read -r key
    if [[ $key == $'\e' ]]; then
        # Esc key detected, trigger interrupt handling
        kill -SIGINT $$
        break
    fi
done) &

# Restore the terminal settings when the script ends
trap 'stty "$old_stty_settings"' EXIT


# Print the colored ASCII art
echo -e "\e[1;32m"  # Set the color to bright green
cat << "EOF"
Script author: @Bilibili VanillaNahida
 __      __            _  _  _            _   _         _      _      _        
 \ \    / /           (_)| || |          | \ | |       | |    (_)    | |       
  \ \  / /__ _  _ __   _ | || |  __ _    |  \| |  __ _ | |__   _   __| |  __ _ 
   \ \/ // _` || '_ \ | || || | / _` |   | . ` | / _` || '_ \ | | / _` | / _` |
    \  /| (_| || | | || || || || (_| |   | |\  || (_| || | | || || (_| || (_| |
     \/  \__,_||_| |_||_||_||_| \__,_|   |_| \_| \__,_||_| |_||_| \__,_| \__,_|                                                                                                                                                                                                                               
EOF
echo -e "\e[0m"  # Reset the color
echo -e "\e[1;36m  Xiaozhi server full deployment one-click install script Ver 0.2 (updated 2025-08-20) \e[0m\n"
sleep 1



# Check for and install whiptail
check_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        echo "Installing whiptail..."
        apt update
        apt install -y whiptail
    fi
}

check_whiptail

# Create the confirmation dialog
whiptail --title "Install Confirmation" --yesno "The Xiaozhi server is about to be installed. Continue?" \
  --yes-button "Continue" --no-button "Exit" 10 50

# Act on the user's choice
case $? in
  0)
    ;;
  1)
    exit 1
    ;;
esac

# Check for root privileges
if [ $EUID -ne 0 ]; then
    whiptail --title "Permission Error" --msgbox "Please run this script as root" 10 50
    exit 1
fi

# Check the system version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
        whiptail --title "System Error" --msgbox "This script only supports Debian/Ubuntu systems" 10 60
        exit 1
    fi
else
    whiptail --title "System Error" --msgbox "Unable to determine the system version. This script only supports Debian/Ubuntu systems" 10 60
    exit 1
fi

# Function to download configuration files
check_and_download() {
    local filepath=$1
    local url=$2
    if [ ! -f "$filepath" ]; then
        if ! curl -fL --progress-bar "$url" -o "$filepath"; then
            whiptail --title "Error" --msgbox "Failed to download ${filepath}" 10 50
            exit 1
        fi
    else
        echo "${filepath} already exists, skipping download"
    fi
}

# Check whether it is already installed
check_installed() {
    # Check whether the directory exists and is non-empty
    if [ -d "/opt/xiaozhi-server/" ] && [ "$(ls -A /opt/xiaozhi-server/)" ]; then
        DIR_CHECK=1
    else
        DIR_CHECK=0
    fi
    
    # Check whether the container exists
    if docker inspect xiaozhi-esp32-server > /dev/null 2>&1; then
        CONTAINER_CHECK=1
    else
        CONTAINER_CHECK=0
    fi
    
    # Both checks passed
    if [ $DIR_CHECK -eq 1 ] && [ $CONTAINER_CHECK -eq 1 ]; then
        return 0  # Installed
    else
        return 1  # Not installed
    fi
}

# Upgrade handling
if check_installed; then
    if whiptail --title "Installation Detected" --yesno "The Xiaozhi server is already installed. Upgrade it?" 10 60; then
        # The user chose to upgrade; run the cleanup
        echo "Starting the upgrade..."
        
        # Stop and remove all docker-compose services
        docker compose -f /opt/xiaozhi-server/docker-compose_all.yml down
        
        # Stop and remove specific containers (the containers may not exist)
        containers=(
            "xiaozhi-esp32-server"
            "xiaozhi-esp32-server-web"
            "xiaozhi-esp32-server-db"
            "xiaozhi-esp32-server-redis"
        )
        
        for container in "${containers[@]}"; do
            if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
                docker stop "$container" >/dev/null 2>&1 && \
                docker rm "$container" >/dev/null 2>&1 && \
                echo "Container removed successfully: $container"
            else
                echo "Container does not exist, skipping: $container"
            fi
        done
        
        # Remove specific images (the images may not exist)
        images=(
            "ghcr.nju.edu.cn/xinnan-tech/xiaozhi-esp32-server:server_latest"
            "ghcr.nju.edu.cn/xinnan-tech/xiaozhi-esp32-server:web_latest"
        )
        
        for image in "${images[@]}"; do
            if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${image}$"; then
                docker rmi "$image" >/dev/null 2>&1 && \
                echo "Image removed successfully: $image"
            else
                echo "Image does not exist, skipping: $image"
            fi
        done
        
        echo "All cleanup operations completed"
        
        # Back up the existing configuration file
        mkdir -p /opt/xiaozhi-server/backup/
        if [ -f /opt/xiaozhi-server/data/.config.yaml ]; then
            cp /opt/xiaozhi-server/data/.config.yaml /opt/xiaozhi-server/backup/.config.yaml
            echo "Backed up the existing configuration file to /opt/xiaozhi-server/backup/.config.yaml"
        fi
        
        # Download the latest configuration files
        check_and_download "/opt/xiaozhi-server/docker-compose_all.yml" "https://ghfast.top/https://raw.githubusercontent.com/xinnan-tech/xiaozhi-esp32-server/refs/heads/main/main/xiaozhi-server/docker-compose_all.yml"
        check_and_download "/opt/xiaozhi-server/data/.config.yaml" "https://ghfast.top/https://raw.githubusercontent.com/xinnan-tech/xiaozhi-esp32-server/refs/heads/main/main/xiaozhi-server/config_from_api.yaml"
        
        # Start the Docker services
        echo "Starting the latest version of the services..."
        # Mark the upgrade as completed so the later download steps are skipped
        UPGRADE_COMPLETED=1
        docker compose -f /opt/xiaozhi-server/docker-compose_all.yml up -d
    else
          whiptail --title "Upgrade Skipped" --msgbox "Upgrade cancelled. The current version will continue to be used." 10 50
          # Skip the upgrade and continue with the rest of the installation
    fi
fi


# Check the curl installation
if ! command -v curl &> /dev/null; then
    echo "------------------------------------------------------------"
    echo "curl not detected, installing..."
    apt update
    apt install -y curl
else
    echo "------------------------------------------------------------"
    echo "curl is already installed, skipping installation"
fi

# Check the Docker installation
if ! command -v docker &> /dev/null; then
    echo "------------------------------------------------------------"
    echo "Docker not detected, installing..."
    
    # Use a domestic mirror instead of the official source
    DISTRO=$(lsb_release -cs)
    MIRROR_URL="https://mirrors.aliyun.com/docker-ce/linux/ubuntu"
    GPG_URL="https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg"
    
    # Install base dependencies
    apt update
    apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg
    
    # Create the keyring directory and add the domestic mirror key
    mkdir -p /etc/apt/keyrings
    curl -fsSL "$GPG_URL" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add the domestic mirror source
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $MIRROR_URL $DISTRO stable" \
        > /etc/apt/sources.list.d/docker.list
    
    # Add the backup official source key (to avoid key verification failure on the domestic source)
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8 2>/dev/null || \
    echo "Warning: some keys failed to be added, continuing with the installation..."
    
    # Install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    
    # Start the service
    systemctl start docker
    systemctl enable docker
    
    # Check whether the installation succeeded
    if docker --version; then
        echo "------------------------------------------------------------"
        echo "Docker installation complete!"
    else
        whiptail --title "Error" --msgbox "Docker installation failed. Please check the logs." 10 50
        exit 1
    fi
else
    echo "Docker is already installed, skipping installation"
fi

# Docker registry mirror configuration
MIRROR_OPTIONS=(
    "1" "Xuanyuan mirror (recommended)"
    "2" "Tencent Cloud mirror"
    "3" "USTC mirror"
    "4" "NetEase 163 mirror"
    "5" "Huawei Cloud mirror"
    "6" "Aliyun mirror"
    "7" "Custom mirror"
    "8" "Skip configuration"
)

MIRROR_CHOICE=$(whiptail --title "Select Docker Mirror" --menu "Please select the Docker mirror to use" 20 60 10 \
"${MIRROR_OPTIONS[@]}" 3>&1 1>&2 2>&3) || {
    echo "User cancelled the selection, exiting the script"
    exit 1
}

case $MIRROR_CHOICE in
    1) MIRROR_URL="https://docker.xuanyuan.me" ;; 
    2) MIRROR_URL="https://mirror.ccs.tencentyun.com" ;; 
    3) MIRROR_URL="https://docker.mirrors.ustc.edu.cn" ;; 
    4) MIRROR_URL="https://hub-mirror.c.163.com" ;; 
    5) MIRROR_URL="https://05f073ad3c0010ea0f4bc00b7105ec20.mirror.swr.myhuaweicloud.com" ;; 
    6) MIRROR_URL="https://registry.aliyuncs.com" ;; 
    7) MIRROR_URL=$(whiptail --title "Custom Mirror" --inputbox "Please enter the full mirror URL:" 10 60 3>&1 1>&2 2>&3) ;; 
    8) MIRROR_URL="" ;; 
esac

if [ -n "$MIRROR_URL" ]; then
    mkdir -p /etc/docker
    if [ -f /etc/docker/daemon.json ]; then
        cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    fi
    cat > /etc/docker/daemon.json <<EOF
{
    "dns": ["8.8.8.8", "114.114.114.114"],
    "registry-mirrors": ["$MIRROR_URL"]
}
EOF
    whiptail --title "Configuration Successful" --msgbox "Mirror added successfully: $MIRROR_URL\nPress Enter to restart the Docker service and continue..." 12 60
    echo "------------------------------------------------------------"
    echo "Restarting the Docker service..."
    systemctl restart docker.service
fi

# Create the installation directories
echo "------------------------------------------------------------"
echo "Creating the installation directories..."
# Check for and create the data directory
if [ ! -d /opt/xiaozhi-server/data ]; then
    mkdir -p /opt/xiaozhi-server/data
    echo "Created data directory: /opt/xiaozhi-server/data"
else
    echo "Directory xiaozhi-server/data already exists, skipping creation"
fi

# Check for and create the model directory
if [ ! -d /opt/xiaozhi-server/models/SenseVoiceSmall ]; then
    mkdir -p /opt/xiaozhi-server/models/SenseVoiceSmall
    echo "Created model directory: /opt/xiaozhi-server/models/SenseVoiceSmall"
else
    echo "Directory xiaozhi-server/models/SenseVoiceSmall already exists, skipping creation"
fi

echo "------------------------------------------------------------"
echo "Starting to download the speech recognition model"
# Download the model file
MODEL_PATH="/opt/xiaozhi-server/models/SenseVoiceSmall/model.pt"
if [ ! -f "$MODEL_PATH" ]; then
    (
    for i in {1..20}; do
        echo $((i*5))
        sleep 0.5
    done
    ) | whiptail --title "Downloading" --gauge "Starting to download the speech recognition model..." 10 60 0
    curl -fL --progress-bar https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt -o "$MODEL_PATH" || {
        whiptail --title "Error" --msgbox "Failed to download model.pt" 10 50
        exit 1
    }
else
    echo "model.pt already exists, skipping download"
fi

# Only download if the upgrade was not completed
if [ -z "$UPGRADE_COMPLETED" ]; then
    check_and_download "/opt/xiaozhi-server/docker-compose_all.yml" "https://ghfast.top/https://raw.githubusercontent.com/xinnan-tech/xiaozhi-esp32-server/refs/heads/main/main/xiaozhi-server/docker-compose_all.yml"
    check_and_download "/opt/xiaozhi-server/data/.config.yaml" "https://ghfast.top/https://raw.githubusercontent.com/xinnan-tech/xiaozhi-esp32-server/refs/heads/main/main/xiaozhi-server/config_from_api.yaml"
fi

# Start the Docker services
(
echo "------------------------------------------------------------"
echo "Pulling Docker images..."
echo "This may take a few minutes, please be patient"
docker compose -f /opt/xiaozhi-server/docker-compose_all.yml up -d

if [ $? -ne 0 ]; then
    whiptail --title "Error" --msgbox "Failed to start the Docker services. Please try switching the mirror and run this script again" 10 60
    exit 1
fi

echo "------------------------------------------------------------"
echo "Checking the service startup status..."
TIMEOUT=300
START_TIME=$(date +%s)
while true; do
    CURRENT_TIME=$(date +%s)
    if [ $((CURRENT_TIME - START_TIME)) -gt $TIMEOUT ]; then
        whiptail --title "Error" --msgbox "Service startup timed out; the expected log content was not found within the specified time" 10 60
        exit 1
    fi
    
    if docker logs xiaozhi-esp32-server-web 2>&1 | grep -q "Started AdminApplication in"; then
        break
    fi
    sleep 1
done

    echo "Server started successfully! Finishing the configuration..."
    echo "Starting the services..."
    docker compose -f /opt/xiaozhi-server/docker-compose_all.yml up -d
    echo "Service startup complete!"
)

# Secret key configuration

# Get the server's public address
PUBLIC_IP=$(hostname -I | awk '{print $1}')
whiptail --title "Configure Server Secret Key" --msgbox "Please use a browser to open the link below, open the Control Panel, and register an account: \n\nInternal address: http://127.0.0.1:8002/\nPublic address: http://$PUBLIC_IP:8002/ (if this is a cloud server, open ports 8000 8001 8002 in the server security group).\n\nThe first registered user is the super administrator; users registered afterwards are regular users. Regular users can only bind devices and configure agents; the super administrator can manage models, manage users, configure parameters, and more.\n\nAfter registering, press Enter to continue" 18 70
SECRET_KEY=$(whiptail --title "Configure Server Secret Key" --inputbox "Please log in to the Control Panel with the super administrator account\nInternal address: http://127.0.0.1:8002/\nPublic address: http://$PUBLIC_IP:8002/\nIn the top menu, go to Parameter Dictionary -> Parameter Management and find the parameter code: server.secret (server secret key) \nCopy the parameter value and enter it in the input box below\n\nPlease enter the secret key (leave empty to skip configuration):" 15 60 3>&1 1>&2 2>&3)

if [ -n "$SECRET_KEY" ]; then
    python3 -c "
import sys, yaml; 
config_path = '/opt/xiaozhi-server/data/.config.yaml'; 
with open(config_path, 'r') as f: 
    config = yaml.safe_load(f) or {}; 
config['manager-api'] = {'url': 'http://xiaozhi-esp32-server-web:8002/xiaozhi', 'secret': '$SECRET_KEY'}; 
with open(config_path, 'w') as f: 
    yaml.dump(config, f); 
"
    docker restart xiaozhi-esp32-server
fi

# Get and display the address information
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Fix the problem that ws cannot be obtained from the log file by hard-coding it
whiptail --title "Installation Complete!" --msgbox "\
The server addresses are as follows:\n\
Admin console URL: http://$LOCAL_IP:8002\n\
OTA URL: http://$LOCAL_IP:8002/xiaozhi/ota/\n\
Vision analysis API URL: http://$LOCAL_IP:8003/mcp/vision/explain\n\
WebSocket URL: ws://$LOCAL_IP:8000/xiaozhi/v1/\n\
\nInstallation finished! Thank you for using it!\nPress Enter to exit..." 16 70
