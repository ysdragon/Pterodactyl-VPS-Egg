#!/bin/bash

# Parse port configuration
parse_ports() {
    local config_file="$HOME/vps.config"
    local port_args=""
    
    while read -r line; do
        case "$line" in
            internalip=*) ;;
            port[0-9]*=*)
                port=${line#*=}
                if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi
            ;;
            port=*)
                port=${line#*=}
                if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi
            ;;
        esac
    done <"$config_file"
}

# Execute PRoot environment
exec_proot() {
    local port_args=$(parse_ports)
    
    /usr/local/bin/proot \
    --rootfs="${HOME}" \
    -0 -w "${HOME}" \
    -b /dev -b /sys -b /proc -b /etc/resolv.conf \
    $port_args \
    --kill-on-exit \
    /bin/sh "/run.sh"
}

exec_proot
