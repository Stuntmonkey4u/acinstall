#!/bin/bash
#
# Exit script on error
set -ex

# Color definitions for output
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
DEFAULT_INSTALL_DIR="/home/runner/azerothcore"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"  # Use INSTALL_DIR if set, else use default

# MySQL root password (use the provided environment variable or default)
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-default_password}"

# Server IP address (use the provided environment variable or default)
SERVER_IP="${SERVER_IP:-127.0.0.1}"

# Realm name (use the provided environment variable or default)
REALM_NAME="${REALM_NAME:-MyRealm}"

# Playerbots installation option (use the provided environment variable or default)
INSTALL_PLAYERBOTS="${INSTALL_PLAYERBOTS:-n}"

# Display the installation configuration
echo -e "${CYAN}Install Directory: $INSTALL_DIR${NC}"
echo -e "${CYAN}MySQL Root Password: $MYSQL_ROOT_PASSWORD${NC}"
echo -e "${CYAN}Server IP: $SERVER_IP${NC}"
echo -e "${CYAN}Realm Name: $REALM_NAME${NC}"
echo -e "${CYAN}Install Playerbots: $INSTALL_PLAYERBOTS${NC}"

# Confirm with the user before proceeding (defaults to yes)
read -p "$(echo -e "${YELLOW}Proceed with these settings? (y/n): ${NC}")" CONFIRM
CONFIRM="${CONFIRM:-y}"  # Default to "yes" if no input is provided

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${RED}Installation aborted.${NC}"
  exit 1
fi

# Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
sudo apt-get update && sudo apt-get install -y git cmake make gcc g++ clang libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev lsb-release gnupg wget p7zip-full

# Install MySQL server
echo -e "${BLUE}Installing MySQL server...${NC}"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.32-1_all.deb
sudo DEBIAN_FRONTEND="noninteractive" dpkg -i ./mysql-apt-config_0.8.32-1_all.deb
sudo apt-get update
sudo DEBIAN_FRONTEND="noninteractive" apt-get install -y mysql-server libmysqlclient-dev

# Install build essentials
echo -e "${BLUE}Installing build essentials...${NC}"
sudo apt-get install build-essential -y

# Clone and Build AzerothCore
echo -e "${BLUE}Cloning AzerothCore repository...${NC}"
if [[ "$INSTALL_PLAYERBOTS" == "y" || "$INSTALL_PLAYERBOTS" == "Y" ]]; then
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

cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/azerothcore/env/dist/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static
 || { echo "CMake configuration failed"; exit 1; }

make -j "$(nproc)" install || { echo "Build failed"; exit 1; }

# Download and extract client data
echo -e "${BLUE}Downloading and extracting client data...${NC}"
cd "$INSTALL_DIR/azerothcore/data/"
wget https://github.com/wowgaming/client-data/releases/download/v16/data.zip || { echo "Failed to download client data"; exit 1; }
7z x data.zip || { echo "Failed to extract client data"; exit 1; }
rm data.zip

# Backup and configure auth and world server configurations
echo -e "${BLUE}Configuring server files...${NC}"
cd "$INSTALL_DIR/azerothcore/env/dist/etc/"
mkdir -p backup
cp "$INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/backup/"

mv "$INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf"
mv "$INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf"

# MySQL Configuration (secure handling)
echo -e "${BLUE}Configuring MySQL...${NC}"
export MYSQL_PWD=$MYSQL_ROOT_PASSWORD
sudo mysql -u root << EOF
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

# Realmlist Configuration
echo -e "${BLUE}Configuring realmlist and databases...${NC}"
sudo systemctl status mysql
read -p "$(echo -e "${YELLOW}Press Enter to continue after confirming MySQL is running...${NC}")"

# Update MySQL user and databases
sudo mysql -u root << EOF
use acore_auth;
DELETE FROM realmlist WHERE id=1;
INSERT INTO realmlist (id, name, address, localAddress, localSubnetMask, port, icon, flag, timezone, allowedSecurityLevel, gamebuild)
VALUES ('1', '$REALM_NAME', '$SERVER_IP', '127.0.0.1', '255.255.255.0', '8085', '1', '0', '1', '0', '12340');
EXIT;
EOF

# Start the Server
echo -e "${BLUE}Starting the authserver and worldserver...${NC}"
cd "$INSTALL_DIR/azerothcore/env/dist/bin"

# Start authserver
sudo ./authserver &

# Wait for authserver to start
while ! nc -z localhost 8085; do
    echo -e "${YELLOW}Waiting for authserver to start...${NC}"
    sleep 5
done

# Once authserver is ready, start worldserver
sudo ./worldserver

# End of script
echo -e "${GREEN}AzerothCore has been successfully installed and the servers are running.${NC}"
