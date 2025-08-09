#!/bin/sh

ensure_run_script_exists() {
    # Check if common.sh exists in the container, if not copy it again
    if [ ! -f "$HOME/common.sh" ]; then
        cp /common.sh "$HOME/common.sh"
        chmod +x "$HOME/common.sh"
    fi
    
    # Check if run.sh exists in the container, if not copy it again
    if [ ! -f "$HOME/run.sh" ]; then
        cp /run.sh "$HOME/run.sh"
        chmod +x "$HOME/run.sh"
    fi
}

# Parse port configuration
parse_ports() {
    config_file="$HOME/vps.config"
    port_args=""
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        return
    fi
    
    while IFS='=' read -r key value; do
        case "$key" in
            ""|"#"*)
                continue
                ;;
        esac
        
        key=$(echo "$key" | tr -d '[:space:]')
        value=$(echo "$value" | tr -d '[:space:]')
        
        [ "$key" = "internalip" ] && continue
        
        # Check if key matches port pattern and value is not empty
        case "$key" in
            port[0-9]*)
                if [ -n "$value" ]; then
                    # Check if value is a number between 1 and 65535
                    case "$value" in
                        *[!0-9]*)
                            # Not a number, skip
                            ;;
                        *)
                            # It's a number, check range
                            if [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
                                port_args="$port_args -p $value:$value"
                            fi
                            ;;
                    esac
                fi
                ;;
        esac
    done < "$config_file"
    
    echo "$port_args"
}

# Execute PRoot environment
exec_proot() {
    port_args=$(parse_ports)
    
    /usr/local/bin/proot \
    --rootfs="${HOME}" \
    -0 -w "${HOME}" \
    -b /dev -b /sys -b /proc \
    $port_args \
    --kill-on-exit \
    /bin/sh "/run.sh"
}

ensure_run_script_exists

exec_proot
