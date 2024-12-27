#!/bin/bash

ensure_run_script_exists() {
    # Check if run.sh exists in the container, if not copy it again
    if [ ! -f "$HOME/run.sh" ]; then
        cp /run.sh "$HOME/run.sh"
        chmod +x "$HOME/run.sh"
    fi
}

# Parse port configuration
parse_ports() {
    local config_file="$HOME/vps.config"
    local port_args=""
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        return
    fi
    
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        
        key=$(echo "$key" | tr -d '[:space:]')
        value=$(echo "$value" | tr -d '[:space:]')
        
        [ "$key" = "internalip" ] && continue
        
        if [[ "$key" =~ ^port[0-9]*$ ]] && [ -n "$value" ]; then
            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
                port_args="$port_args -p $value:$value"
            fi
        fi
    done < "$config_file"
    
    echo "$port_args"
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

ensure_run_script_exists

exec_proot
