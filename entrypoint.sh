#!/bin/bash
sleep 2

cd /home/container
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`

# Make internal Docker IP address available to processes.
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`
rm start.sh
curl -Lo ./start.sh https://gitlab.com/samcozza03/pterodactyl-vps-egg/raw/main/start.sh
chmod +x ./start.sh
# Run the Server
bash ./start.sh
