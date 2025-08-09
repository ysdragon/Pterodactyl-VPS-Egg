#!/bin/sh

# Source common functions and variables
. /common.sh

# Configuration
HOSTNAME="MyVPS"
HISTORY_FILE="${HOME}/.custom_shell_history"
MAX_HISTORY=1000

# Check if not installed
if [ ! -e "/.installed" ]; then
    # Check if rootfs.tar.xz or rootfs.tar.gz exists and remove them if they do
    if [ -f "/rootfs.tar.xz" ]; then
        rm -f "/rootfs.tar.xz"
    fi
    
    if [ -f "/rootfs.tar.gz" ]; then
        rm -f "/rootfs.tar.gz"
    fi
    
    # Wipe the files we downloaded into /tmp previously
    rm -rf /tmp/sbin

    # Add DNS Resolver nameservers to resolv.conf
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > /etc/resolv.conf
    
    # Mark as installed.
    touch "/.installed"
fi

# Check if the autorun script exists
if [ ! -e "/autorun.sh" ]; then
    touch /autorun.sh
    chmod +x /autorun.sh
fi

printf "\033c"
printf "${GREEN}Starting..${NC}\n"
sleep 1
printf "\033c"

# Function to handle cleanup on exit
cleanup() {
    log "INFO" "Session ended. Goodbye!" "$GREEN"
    exit 0
}

# Function to get formatted directory
get_formatted_dir() {
    current_dir="$PWD"
    case "$current_dir" in
        "$HOME"*)
            printf "~${current_dir#$HOME}"
        ;;
        *)
            printf "$current_dir"
        ;;
    esac
}

print_instructions() {
    log "INFO" "Type 'help' to view a list of available custom commands." "$YELLOW"
}

# Function to print prompt
print_prompt() {
    user="$1"
    printf "\n${GREEN}${user}@${HOSTNAME}${NC}:${RED}$(get_formatted_dir)${NC}# "
}

# Function to save command to history
save_to_history() {
    cmd="$1"
    if [ -n "$cmd" ] && [ "$cmd" != "exit" ]; then
        printf "$cmd\n" >> "$HISTORY_FILE"
        # Keep only last MAX_HISTORY lines
        if [ -f "$HISTORY_FILE" ]; then
            tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
            mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        fi
    fi
}

# Function reinstall the OS
reinstall() {    
    log "INFO" "Reinstalling the OS..." "$YELLOW"
    
    find / -mindepth 1 -xdev -delete > /dev/null 2>&1
}

# Function to install wget
install_wget() {
    distro=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    
    case "$distro" in
        "debian"|"ubuntu"|"devuan"|"linuxmint"|"kali")
            apt-get update -qq && apt-get install -y -qq wget > /dev/null 2>&1
        ;;
        "void")
            xbps-install -Syu wget > /dev/null 2>&1
        ;;
        "centos"|"fedora"|"rocky"|"almalinux"|"openEuler"|"amzn"|"ol")
            yum install -y -q wget > /dev/null 2>&1
        ;;
        "opensuse"|"opensuse-tumbleweed"|"opensuse-leap")
            zypper install -y -q wget > /dev/null 2>&1
        ;;
        "alpine"|"chimera")
            apk add -q --no-interactive --no-scripts wget > /dev/null 2>&1
        ;;
        "gentoo")
            emerge --sync -q && emerge -q wget > /dev/null 2>&1
        ;;
        "arch")
            pacman -Syu --noconfirm --quiet wget > /dev/null 2>&1
        ;;
        "slackware")
            yes | slackpkg install wget > /dev/null 2>&1
        ;;
        *)
            log "ERROR" "Unsupported distribution: $distro" "$RED"
            return 1
        ;;
    esac
}

# Function to install SSH from the repository
install_ssh() {
    # Check if SSH is already installed
    if [ -f "/usr/local/bin/ssh" ]; then
        log "ERROR" "SSH is already installed." "$RED"
        return 1
    fi

    # Install wget if not found
    if ! command -v wget &> /dev/null; then
        log "INFO" "Installing wget." "$YELLOW"
        install_wget
    fi
    
    log "INFO" "Installing SSH." "$YELLOW"
    
    # Determine the architecture
    arch=$(detect_architecture)
    
    # URL to download the SSH binary
    url="https://github.com/ysdragon/ssh/releases/latest/download/ssh-$arch"
    
    # Download the SSH binary
    wget -q -O /usr/local/bin/ssh "$url" || {
        log "ERROR" "Failed to download SSH." "$RED"
        return 1
    }
    
    # Make the binary executable
    chmod +x /usr/local/bin/ssh || {
        log "ERROR" "Failed to make ssh executable." "$RED"
        return 1
    }    

    log "SUCCESS" "SSH installed successfully." "$GREEN"
}

# Function to show system status
show_system_status() {
    log "INFO" "System Status:" "$GREEN"
    uptime
    free -h
    df -h
    ps aux --sort=-%mem | head -n 10
}

# Function to create a backup
create_backup() {
    # Check if tar is installed
    if ! command -v tar > /dev/null 2>&1; then
        log "ERROR" "tar is not installed. Please install tar first." "$RED"
        return 1
    fi

    backup_file="/backup_$(date +%Y%m%d%H%M%S).tar.gz"
    exclude_file="/tmp/exclude-list.txt"

    # Create a file with a list of patterns to exclude. This is more
    # compatible with different versions of tar, including busybox tar.
    # We use relative paths for exclusion as we'll be running tar from /.
    cat > "$exclude_file" <<EOF
./${backup_file#/}
./proc
./tmp
./dev
./sys
./run
./vps.config
${exclude_file#/}
EOF

    log "INFO" "Starting backup process..." "$YELLOW"
    (cd / && tar --numeric-owner -czf "$backup_file" -X "$exclude_file" .) > /dev/null 2>&1
    log "SUCCESS" "Backup created at $backup_file" "$GREEN"

    # Clean up the exclude file
    rm -f "$exclude_file"
}

# Function to restore a backup
restore_backup() {
    backup_file="$1"

    # Check if tar is installed
    if ! command -v tar > /dev/null 2>&1; then
        log "ERROR" "tar is not installed. Please install tar first." "$RED"
        return 1
    fi

    if [ -z "$backup_file" ]; then
        log "INFO" "Usage: restore <backup_file>" "$YELLOW"
        log "INFO" "Example: restore backup_20250620024221.tar.gz" "$YELLOW"
        return 1
    fi

    if [ -f "/$backup_file" ]; then
        log "INFO" "Starting restore process..." "$YELLOW"
        tar --numeric-owner -xzf "/$backup_file" -C / --exclude="$backup_file" > /dev/null 2>&1
        log "SUCCESS" "Backup restored from $backup_file" "$GREEN"
    else
        log "ERROR" "Backup file not found: $backup_file" "$RED"
    fi
}

# Function to print initial banner
print_banner() {
    print_main_banner
}

# Function to print a beautiful help message
print_help_message() {
    print_help_banner
}

# Function to handle command execution
execute_command() {
    cmd="$1"
    user="$2"
    
    # Save command to history
    save_to_history "$cmd"
    
    # Handle special commands
    case "$cmd" in
        "clear"|"cls")
            printf "\033c"
            print_prompt "$user"
            return 0
        ;;
        "exit")
            cleanup
        ;;
        "history")
            if [ -f "$HISTORY_FILE" ]; then
                cat "$HISTORY_FILE"
            fi
            print_prompt "$user"
            return 0
        ;;
        "reinstall")
            reinstall
            exit 2
        ;;
        "sudo"*|"su"*)
            log "ERROR" "You are already running as root." "$RED"
            print_prompt "$user"
            return 0
        ;;
        "install-ssh")
            install_ssh
            print_prompt "$user"
            return 0
        ;;
        "status")
            show_system_status
            print_prompt "$user"
            return 0
        ;;
        "backup")
            create_backup
            print_prompt "$user"
            return 0
        ;;
        "restore")
            log "ERROR" "No backup file specified. Usage: restore <backup_file>" "$RED"
            print_prompt "$user"
            return 0
        ;;
        "restore "*)
            backup_file=$(echo "$cmd" | cut -d' ' -f2-)
            restore_backup "$backup_file"
            print_prompt "$user"
            return 0
        ;;
        "help")
            print_help_message
            print_prompt "$user"
            return 0
        ;;
        *)
            eval "$cmd"
            print_prompt "$user"
            return 0
        ;;
    esac
}

# Function to run command prompt for a specific user
run_prompt() {
    user="$1"
    read -r cmd
    
    execute_command "$cmd" "$user"
    print_prompt "$user"
}

# Create history file if it doesn't exist
touch "$HISTORY_FILE"

# Set up trap for clean exit
trap cleanup INT TERM

# Print the initial banner
print_banner

# Print the initial instructions
print_instructions

# Print initial command
printf "${GREEN}root@${HOSTNAME}${NC}:${RED}$(get_formatted_dir)${NC}#\n"

# Execute autorun.sh
sh "/autorun.sh"

# Main command loop
while true; do
    run_prompt "user"
done