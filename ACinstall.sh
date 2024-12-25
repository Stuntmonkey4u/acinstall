#!/bin/bash

# Improved AzerothCore Installation Script
# Author: Stuntmonkey4u (modified by Bard)
# Description: Automates the installation of AzerothCore on Debian/Ubuntu systems.
#
# IMPORTANT NOTE: This script follows the official AzerothCore recommendation
# to use MySQL. AzerothCore explicitly DOES NOT support MariaDB.
# Please see the official AzerothCore documentation for more information.
#
# For manual install, please see the offical instructions here:
# https://www.azerothcore.org/wiki/linux-requirements

# Exit immediately if a command exits with a non-zero status.
set -e

# ---- Color Codes for Output ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# ---- Helper functions ----

# Function to display messages with color
msg() {
  local color="$1"
  local text="$2"
  echo -e "${color}${text}${NC}"
}

# Function to get secure user input without echoing to terminal
read_secure() {
  local prompt="$1"
  local varname="$2"

  read -r -s -p "$prompt" input
  echo "" # Newline after input
  eval "$varname=\"\$input\""
  unset input
}

# Function to check if the script is being run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        msg "$RED" "This script must be run as root or with sudo."
        exit 1
    fi
}

# ---- Main Script ----
# Check if running as root
check_root

msg "$YELLOW" "Starting AzerothCore Installation Script..."

# Set default installation directory
DEFAULT_INSTALL_DIR="/opt/azerothcore"

# 1. Ask for user input (installation directory, MySQL root password, server IP, realm name, Playerbots)
if [ -z "$INSTALL_DIR" ]; then
    msg "$YELLOW" "Enter the directory where you want to install AzerothCore (default: ${DEFAULT_INSTALL_DIR}): "
    read INSTALL_DIR
    INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
else
    msg "$YELLOW" "Using installation directory from environment variable."
fi
# Ensure INSTALL_DIR is an absolute path and normalize it
INSTALL_DIR=$(realpath "$INSTALL_DIR")
msg "$YELLOW" "Installation directory set to: $INSTALL_DIR"

# Check if directory exists, if not create it
msg "$YELLOW" "Checking installation directory..."
if [ ! -d "$INSTALL_DIR" ]; then
    msg "$YELLOW" "Directory $INSTALL_DIR does not exist. Creating it..."
    sudo mkdir -p "$INSTALL_DIR"
fi

# MySQL root password (secure handling)
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    msg "$YELLOW" "Enter the MySQL root password: "
    read_secure "MySQL root password: " ROOT_PASSWORD
else
  ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD"
    msg "$YELLOW" "Using MySQL root password from environment variable."
fi

# Server IP address (for realmlist)
if [ -z "$SERVER_IP" ]; then
    msg "$YELLOW" "Enter the server IP address (e.g., 192.168.1.100): "
    read SERVER_IP
else
  msg "$YELLOW" "Using server ip from environment variable."
fi

# Realm name
if [ -z "$REALM_NAME" ]; then
    msg "$YELLOW" "Enter the realm name (e.g., 'MyRealm'): "
    read REALM_NAME
else
  msg "$YELLOW" "Using realm name from environment variable."
fi

# Ask if they want to install the Playerbots module
if [ -z "$INSTALL_PLAYERBOTS" ]; then
    msg "$YELLOW" "Do you want to install the Playerbots module? (y/N): "
    read -r -n 1 INSTALL_PLAYERBOTS
    echo "" # Newline after input
    INSTALL_PLAYERBOTS=$(echo "$INSTALL_PLAYERBOTS" | tr '[:upper:]' '[:lower:]')
else
  msg "$YELLOW" "Using playerbots install setting from environment variable."
    INSTALL_PLAYERBOTS=$(echo "$INSTALL_PLAYERBOTS" | tr '[:upper:]' '[:lower:]')
fi

# 2. Install Required Packages
msg "$YELLOW" "Installing required packages..."
sudo apt install -y git cmake gcc g++ make wget mysql-server mysql-client libssl-dev zlib1g-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev libmysqlclient-dev libpcre3-dev cmake-curses-gui
msg "$GREEN" "Required packages installed."

# 3. Create AzerothCore Directory
msg "$YELLOW" "Creating AzerothCore directory..."
sudo mkdir -p "$INSTALL_DIR/azerothcore"
msg "$GREEN" "AzerothCore directory created at $INSTALL_DIR/azerothcore."

# 4. Clone AzerothCore Repository
msg "$YELLOW" "Cloning AzerothCore repository..."
cd "$INSTALL_DIR/azerothcore"
git clone -b master https://github.com/azerothcore/azerothcore-wotlk.git azerothcore
cd azerothcore
msg "$GREEN" "AzerothCore repository cloned."

# 5. Create Build Directory
msg "$YELLOW" "Creating build directory..."
mkdir build
msg "$GREEN" "Build directory created."

# 6. Run CMake
msg "$YELLOW" "Running CMake..."
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR/azerothcore/env/dist/" -DCONF_INSTALL_DIR="$INSTALL_DIR/azerothcore/env/dist/etc" -DMODULES_INSTALL_DIR="$INSTALL_DIR/azerothcore/modules"
msg "$GREEN" "CMake configured."

# 7. Compile
msg "$YELLOW" "Compiling AzerothCore..."
make -j$(nproc)
msg "$GREEN" "AzerothCore compiled."

# 8. Install
msg "$YELLOW" "Installing AzerothCore..."
make install
msg "$GREEN" "AzerothCore installed."

# 9. Database Setup
msg "$YELLOW" "Setting up database..."
# Create the database
mysql -u root -p"$ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS acore_characters;"
mysql -u root -p"$ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS acore_auth;"
mysql -u root -p"$ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS acore_world;"
msg "$GREEN" "Created acore databases."

# Import SQL files for DB creation
msg "$YELLOW" "Importing SQL files..."
mysql -u root -p"$ROOT_PASSWORD" acore_auth < ../sql/auth/auth_full.sql
mysql -u root -p"$ROOT_PASSWORD" acore_world < ../sql/world/world_full.sql
mysql -u root -p"$ROOT_PASSWORD" acore_characters < ../sql/characters/characters_full.sql
msg "$GREEN" "SQL files imported."

# 10. Configuration
msg "$YELLOW" "Setting up configuration..."
# Copy example config files to etc folder.
cp ../configs/authserver.conf.dist "$INSTALL_DIR/azerothcore/env/dist/etc/authserver.conf"
cp ../configs/worldserver.conf.dist "$INSTALL_DIR/azerothcore/env/dist/etc/worldserver.conf"

msg "$GREEN" "Copied example configuration files."

# 11. Module Installation (Playerbots Example)
if [[ "$INSTALL_PLAYERBOTS" == "y" ]]; then
  msg "$YELLOW" "Installing Playerbots Module..."
  # Clone the Playerbots module from its official repo
    cd "$INSTALL_DIR/azerothcore/modules"
    git clone https://github.com/azerothcore/mod-playerbots.git playerbots

  # Install the playerbots module in the build directory.
    cd "$INSTALL_DIR/azerothcore/build"
    cmake ../ -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR/azerothcore/env/dist/" -DCONF_INSTALL_DIR="$INSTALL_DIR/azerothcore/env/dist/etc" -DMODULES_INSTALL_DIR="$INSTALL_DIR/azerothcore/modules" -DMODULE_PATH="$INSTALL_DIR/azerothcore/modules/playerbots"
      make -j$(nproc)
    make install
    msg "$GREEN" "Playerbots module installed."
    #Copy example playerbots configs to correct directory.
   msg "$YELLOW" "Copying Playerbots configs"
    cp "$INSTALL_DIR/azerothcore/modules/playerbots/configs/playerbots.conf.dist" "$INSTALL_DIR/azerothcore/env/dist/etc/playerbots.conf"
    msg "$GREEN" "Playerbots configs copied"
    msg "$YELLOW" "Please edit the server configuration files located in:"
    msg "$YELLOW" "$INSTALL_DIR/azerothcore/env/dist/etc"
    msg "$YELLOW" "You can now enable the Playerbot module by adding the following into the worldserver.conf file under the modules section: Module = \"mod-playerbots\""
fi

# 12. Realmlist Configuration
msg "$YELLOW" "Configuring realmlist and databases..."

# Update MySQL user and databases
mysql -u root -p"$ROOT_PASSWORD" << EOF
use acore_auth;
DELETE FROM realmlist WHERE id=1;
INSERT INTO realmlist (id, name, address, localAddress, localSubnetMask, port, icon, flag, timezone, allowedSecurityLevel, gamebuild)
VALUES ('1', '$REALM_NAME', '$SERVER_IP', '127.0.0.1', '255.255.255.0', '8085', '1', '0', '1', '0', '12340');
EXIT;
EOF
# Prompt user to edit the config file
msg "$YELLOW" "Configuration setup is mostly complete. Please edit the server configuration files located in:"
msg "$YELLOW" "$INSTALL_DIR/azerothcore/env/dist/etc"
msg "$YELLOW" "The server must have a different user than root, or it will be unable to start."
msg "$YELLOW" "The database password must be changed, or the server will be unable to connect."
msg "$YELLOW" "Please make sure to start the server with a non-root user."
msg "$GREEN" "Installation complete!"

# Display where server files are located
msg "$YELLOW" "Server files are located in: $INSTALL_DIR/azerothcore/env/dist/"
msg "$YELLOW" "The server can be run with:"
msg "$YELLOW" "$INSTALL_DIR/azerothcore/env/dist/bin/worldserver &"
msg "$YELLOW" "$INSTALL_DIR/azerothcore/env/dist/bin/authserver &"

exit 0
