#!/bin/bash

# Exit script on error
set -e

# Color definitions
CYAN='\033[0;36m'        # Cyan for spinner and interactive text
GREEN='\033[38;5;82m'       # Green for success messages
YELLOW='\033[1;33m'      # Yellow for warnings and prompts
RED='\033[38;5;196m'         # Red for errors and important alerts
BLUE='\033[38;5;117m'        # Blue for headers and important sections
WHITE='\033[1;37m'       # White for general text
BOLD='\033[1m'           # Bold for emphasis
NC='\033[0m'             # No Color (reset)

echo -e "${BLUE}Welcome to the AzerothCore installation script!${NC}"

# Set default installation directory
DEFAULT_INSTALL_DIR="/home/$USER/azerothcore"

# 1. Ask for user input (installation directory, MySQL root password, server IP, realm name, Playerbots)
read -p "$(echo -e ${CYAN}Enter the directory where you want to install AzerothCore (default: $DEFAULT_INSTALL_DIR): ${NC})" INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

# Check if directory exists, if not create it
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Directory $INSTALL_DIR does not exist. Creating it...${NC}"
    mkdir -p "$INSTALL_DIR"
fi

# MySQL root password
read -sp "$(echo -e ${CYAN}Enter the MySQL root password: ${NC})" MYSQL_ROOT_PASSWORD
echo ""

# Server IP address (for realmlist)
read -p "$(echo -e ${CYAN}Enter the server IP address (e.g., 192.168.60.174): ${NC})" SERVER_IP

# Realm name
read -p "$(echo -e ${CYAN}Enter the realm name (e.g., 'Northrend'): ${NC})" REALM_NAME

# Ask if they want to install the Playerbots module
read -p "$(echo -e ${CYAN}Do you want to install the Playerbots module? (y/n): ${NC})" INSTALL_PLAYERBOTS

# 2. Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
sudo apt-get update && sudo apt-get install git cmake make gcc g++ clang libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev lsb-release gnupg wget -y

# 3. Install MySQL server
echo -e "${BLUE}Installing MySQL server...${NC}"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.32-1_all.deb
sudo DEBIAN_FRONTEND="noninteractive" dpkg -i ./mysql-apt-config_0.8.32-1_all.deb
sudo apt-get update
sudo DEBIAN_FRONTEND="noninteractive" apt-get install -y mysql-server libmysqlclient-dev

# Install build essentials
echo -e "${BLUE}Installing build essentials...${NC}"
sudo apt-get update && sudo apt install build-essential -y

# 4. Clone and Build AzerothCore
echo -e "${BLUE}Cloning AzerothCore repository...${NC}"
if [ "$INSTALL_PLAYERBOTS" == "y" ]; then
    git clone https://github.com/liyunfan1223/azerothcore-wotlk.git --branch=Playerbot --single-branch $INSTALL_DIR/azerothcore
    echo -e "${YELLOW}Cloning Playerbots module...${NC}"
    git clone https://github.com/liyunfan1223/mod-playerbots.git --branch=master $INSTALL_DIR/azerothcore/modules/mod-playerbots
else
    git clone https://github.com/azerothcore/azerothcore-wotlk.git --branch master --single-branch $INSTALL_DIR/azerothcore
fi

# Build and install AzerothCore
cd $INSTALL_DIR/azerothcore
mkdir build
cd build

cmake ../ -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/azerothcore/env/dist/ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DWITH_WARNINGS=1 -DTOOLS_BUILD=all -DSCRIPTS=static -DMODULES=static

make -j $(nproc) install

# 5. Download and extract client data
echo -e "${BLUE}Downloading and extracting client data...${NC}"
cd $INSTALL_DIR/azerothcore/data/
wget https://github.com/wowgaming/client-data/releases/download/v16/data.zip
7z x data.zip
rm data.zip

# 6. Backup and configure auth and world server configurations
echo -e "${BLUE}Configuring server files...${NC}"
cd $INSTALL_DIR/azerothcore/env/dist/etc/
mkdir -p backup
cp $INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf.dist $INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf.dist $INSTALL_DIR/azerothcore/env/dist/etc/backup/

mv $INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf.dist $INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf
mv $INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf.dist $INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf

# Update server configuration files
echo -e "${YELLOW}Please edit the ${WHITE}worldserver.conf${YELLOW} file. Make sure to set the datadir path for map data.${NC}"
nano $INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf

# If needed, update authserver.conf as well
echo -e "${YELLOW}Please edit the ${WHITE}authserver.conf${YELLOW} file if necessary.${NC}"
nano $INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf

# 7. MySQL Configuration
echo -e "${BLUE}Configuring MySQL...${NC}"
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_ROOT_PASSWORD';
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
sudo systemctl status mysql
read -p "$(echo -e ${YELLOW}Press Enter to continue after confirming MySQL is running...${NC})"

# Update MySQL user and databases
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
use acore_auth;
DELETE FROM realmlist WHERE id=1;
INSERT INTO realmlist (id, name, address, localAddress, localSubnetMask, port, icon, flag, timezone, allowedSecurityLevel, gamebuild)
VALUES ('1', '$REALM_NAME', '$SERVER_IP', '127.0.0.1', '255.255.255.0', '8085', '1', '0', '1', '0', '12340');
EXIT;
EOF

# 9. Start the Server
echo -e "${BLUE}Starting the authserver and worldserver...${NC}"
cd $INSTALL_DIR/azerothcore/env/dist/bin

# Start authserver
sudo ./authserver

# Once authserver is loaded, start worldserver
sudo ./worldserver

# End of script
echo -e "${GREEN}AzerothCore has been successfully installed and the servers are running.${NC}"
