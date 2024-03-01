#!/bin/bash
sleep 2
export HOME=/home/container
cd /home/container
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`

# Make internal Docker IP address available to processes.
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`
curl -Ls https://raw.githubusercontent.com/ysdragon/Pterodactyl-VPS-Egg/main/install.sh -o install.sh
chmod +x ./install.sh
# Run the VPS Installer
sh ./install.sh
