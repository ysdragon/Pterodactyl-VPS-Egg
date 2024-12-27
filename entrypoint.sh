#!/bin/bash
# Sleep for 2 seconds to ensure container is ready
sleep 2

cd /home/container
MODIFIED_STARTUP=$(eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g'))

# Make internal Docker IP address available to processes.
export INTERNAL_IP=$(ip route get 1 | awk '{print $NF;exit}')

# Check if already installed
if [ ! -e "$HOME/.installed" ]; then
    /usr/local/bin/proot \
    --rootfs="/" \
    -0 -w "/root" \
    -b /dev -b /sys -b /proc -b /etc/resolv.conf \
    --kill-on-exit \
    /bin/bash "/install.sh" || exit 1
fi

# Run the startup helper script
bash /helper.sh