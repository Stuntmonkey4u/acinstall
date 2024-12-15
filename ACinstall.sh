#!/bin/bash

# Exit script on error
set -e

# Set USER to root if not already set (common in Docker containers)
USER=${USER:-root}

# Color definitions
CYAN='\033[0;36m'        # Cyan for spinner and interactive text
GREEN='\033[38;5;82m'    # Green for success messages
YELLOW='\033[1;33m'      # Yellow for warnings and prompts
RED='\033[38;5;196m'     # Red for errors and important alerts
BLUE='\033[38;5;117m'    # Blue for headers and important sections
WHITE='\033[1;37m'       # White for general text
BOLD='\033[1m'           # Bold for emphasis
NC='\033[0m'             # No Color (reset)

echo -e "${BLUE}Welcome to the AzerothCore installation script!${NC}"

# Set default installation directory
DEFAULT_INSTALL_DIR="/home/${USER}/azerothcore"

# 1. Ask for user input (installation directory, MySQL root password, server IP, realm name, Playerbots)
echo -e "${CYAN}Enter the directory where you want to install AzerothCore (default: ${DEFAULT_INSTALL_DIR}): ${NC}"
read INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

# Ensure INSTALL_DIR is an absolute path and normalize it
INSTALL_DIR=$(realpath "$INSTALL_DIR")
echo -e "${YELLOW}Installation directory set to: $INSTALL_DIR${NC}"

# Check if directory exists, if not create it
echo -e "${YELLOW}Checking installation directory...${NC}"
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Directory $INSTALL_DIR does not exist. Creating it...${NC}"
    mkdir -p "$INSTALL_DIR"
fi

# MySQL root password (secure handling)
echo -e "${CYAN}Enter the MySQL root password: ${NC}"
read -sp MYSQL_ROOT_PASSWORD
echo ""

# Server IP address (for realmlist)
echo -e "${CYAN}Enter the server IP address (e.g., 192.168.60.174): ${NC}"
read SERVER_IP

# Realm name
echo -e "${CYAN}Enter the realm name (e.g., 'Northrend'): ${NC}"
read REALM_NAME

# Ask if they want to install the Playerbots module
echo -e "${CYAN}Do you want to install the Playerbots module? (y/n): ${NC}"
read INSTALL_PLAYERBOTS

# 2. Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
apt-get update && apt-get install -y git cmake make gcc g++ clang libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev lsb-release gnupg wget p7zip-full

# 3. Install MySQL server
echo -e "${BLUE}Installing MySQL server...${NC}"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.32-1_all.deb
dpkg -i ./mysql-apt-config_0.8.32-1_all.deb
apt-get update
apt-get install -y mysql-server libmysqlclient-dev

# Install build essentials
echo -e "${BLUE}Installing build essentials...${NC}"
apt-get update && apt install build-essential -y

# 4. Clone and Build AzerothCore
echo -e "${BLUE}Cloning AzerothCore repository...${NC}"
if [ "$INSTALL_PLAYERBOTS" == "y" ]; then
    git clone https://github.com/liyunfan1223/azerothcore-wotlk.git --branch=Playerbot --single-branch "$INSTALL_DIR/azerothcore" || { echo "Error cloning AzerothCore repository"; exit 1; }
    echo -e "${YELLOW}Cloning Playerbots module...${NC}"
    git clone https://github.com/liyunfan1223/mod-playerbots.git --branch=master "$INSTALL_DIR/azerothcore/modules/mod-playerbots" || { echo "Error cloning Playerbots module"; exit 1; }
else
    git clone https://github.com/azerothcore/azerothcore-wotlk.git --branch master --single-branch "$INSTALL_DIR/azerothcore" || { echo "Error cloning AzerothCore repository"; exit 1; }
fi

# Build and install AzerothCore
cd "$INSTALL_DIR/azerothcore"
mkdir build
cd build

cmake ../ -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR/azerothcore/env/dist/" -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static || { echo "CMake configuration failed"; exit 1; }
make -j $(nproc) install || { echo "Build failed"; exit 1; }

# 5. Download and extract client data
echo -e "${BLUE}Downloading and extracting client data...${NC}"
cd "$INSTALL_DIR/azerothcore/data/"
mkdir -p "$INSTALL_DIR/azerothcore/data"  # Ensure the data directory exists
wget https://github.com/wowgaming/client-data/releases/download/v16/data.zip || { echo "Failed to download client data"; exit 1; }
7z x data.zip || { echo "Failed to extract client data"; exit 1; }
rm data.zip

# 6. Backup and configure auth and world server configurations
echo -e "${BLUE}Configuring server files...${NC}"
cd "$INSTALL_DIR/azerothcore/env/dist/etc/"
mkdir -p backup
cp "$INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/backup/"
mv "$INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf"
mv "$INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf"

# 7. MySQL Configuration (secure handling)
echo -e "${BLUE}Configuring MySQL...${NC}"
export MYSQL_PWD=$MYSQL_ROOT_PASSWORD
mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;

DROP USER IF EXISTS 'acore'@'localhost';
CREATE USER 'acore'@'localhost';
GRANT ALL PRIVILEGES ON * . * TO 'acore'@'localhost' WITH GRANT OPTION;
CREATE DATABASE acore_world DEFAULT CHARACTER SET UTF8MB4 COLLATE utf8mb4_general_ci;
CREATE DATABASE acore_characters DEFAULT CHARACTER SET UTF8MB4 COLLATE utf8mb4_general_ci;
CREATE DATABASE acore_auth DEFAULT CHARACTER SET UTF8MB4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON acore_world.* TO 'acore'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON acore_characters.* TO 'acore'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON acore_auth.* TO 'acore'@'localhost' WITH GRANT OPTION;
EXIT;
EOF

# 8. Realmlist Configuration
echo -e "${BLUE}Configuring realmlist and databases...${NC}"
systemctl status mysql
read -p "$(echo -e ${YELLOW}Press Enter to continue after confirming MySQL is running...${NC})"

# Update MySQL user and databases
mysql -u root << EOF
use acore_auth;
DELETE FROM realmlist WHERE id=1;
INSERT INTO realmlist (id, name, address, localAddress, localSubnetMask, port, icon, flag, timezone, allowedSecurityLevel, gamebuild)
VALUES ('1', '$REALM_NAME', '$SERVER_IP', '127.0.0.1', '255.255.255.0', '8085', '1', '0', '1', '0', '12340');
EXIT;
EOF

# 9. Start the Server
echo -e "${BLUE}Starting the authserver and worldserver...${NC}"
cd "$INSTALL_DIR/azerothcore/env/dist/bin"

# Start authserver
./authserver &

# Wait for authserver to start
while ! nc -z localhost 8085; do
    echo -e "${YELLOW}Waiting for authserver to start...${NC}"
    sleep 5
done

# Once authserver is ready, start worldserver
./worldserver

# End of script
echo -e "${GREEN}AzerothCore has been successfully installed and the servers are running.${NC}"
