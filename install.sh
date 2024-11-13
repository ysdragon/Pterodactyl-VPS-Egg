#!/bin/bash

# Define color codes
declare -A colors=(
    ["PURPLE"]='\033[0;35m'
    ["RED"]='\033[0;31m'
    ["GREEN"]='\033[0;32m'
    ["YELLOW"]='\033[0;33m'
    ["NC"]='\033[0m'
)

# Configuration variables
readonly ROOTFS_DIR="/home/container"
readonly PROOT_VERSION="5.4.0"
readonly BASE_URL="https://images.linuxcontainers.org/images"

# Add to PATH
export PATH=$PATH:~/.local/usr/bin

# Error handling function
error_exit() {
    printf "${colors[RED]}Error: $1${colors[NC]}\n" >&2
    exit 1
}

# Logger function
log() {
    local level=$1
    local message=$2
    local color=${colors[$3]}
    
    if [ -z "$color" ]; then
        color=${colors[NC]}
    fi
    
    printf "${color}[$level] $message${colors[NC]}\n"
}

# Detect the machine architecture.
ARCH=$(uname -m)

# Detect architecture
detect_architecture() {
    case "$ARCH" in
        x86_64)
            echo "amd64"
        ;;
        aarch64)
            echo "arm64"
        ;;
        riscv64)
            echo "riscv64"
        ;;
        *)
            error_exit "Unsupported CPU architecture: $ARCH"
        ;;
    esac
}

# Verify network connectivity
check_network() {
    if ! curl -s --head "$BASE_URL" >/dev/null; then
        error_exit "Unable to connect to $BASE_URL. Please check your internet connection."
    fi
}

# Function to cleanup temporary files
cleanup() {
    log "INFO" "Cleaning up temporary files..." "YELLOW"
    rm -f "$ROOTFS_DIR/rootfs.tar.xz"
    rm -rf /tmp/sbin
}

# Install PRoot
install_proot() {
    local proot_path="$ROOTFS_DIR/usr/local/bin/proot"
    log "INFO" "Installing PRoot version ${PROOT_VERSION}..." "GREEN"
    
    mkdir -p "$ROOTFS_DIR/usr/local/bin"
    
    local proot_url="https://github.com/ysdragon/proot-static/releases/download/v${PROOT_VERSION}/proot-${ARCH}-static"
    if ! curl -Ls "$proot_url" -o "$proot_path"; then
        error_exit "Failed to download PRoot"
    fi
    
    chmod 755 "$proot_path" || error_exit "Failed to set PRoot permissions"
}

# Function to install a specific distro
install() {
    local distro_name="$1"
    local pretty_name="$2"
    local is_custom="${3:-false}"
    
    log "INFO" "Preparing to install $pretty_name..." "GREEN"
    
    local url_path
    local image_names
    
    if [[ "$is_custom" == "true" ]]; then
        url_path="$BASE_URL/$distro_name/current/$ARCH_ALT/"
    else
        url_path="$BASE_URL/$distro_name/"
    fi
    
    # Fetch available versions with error handling
    image_names=$(curl -s "$url_path" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"/' | grep -v '^\.\.$') ||
    error_exit "Failed to fetch available versions for $pretty_name"
    
    # Display available versions
    local -a versions=($image_names)
    for i in "${!versions[@]}"; do
        printf "* [%d] %s (%s)\n" $((i + 1)) "$pretty_name" "${versions[i]}"
    done
    
    # Version selection with validation
    local version
    while true; do
        printf "${colors[YELLOW]}Enter the desired version (1-${#versions[@]}): ${colors[NC]}\n"
        read -r version
        if [[ "$version" =~ ^[0-9]+$ ]] && ((version >= 1 && version <= ${#versions[@]})); then
            break
        fi
        log "ERROR" "Invalid selection. Please try again." "RED"
    done
    
    local selected_version=${versions[$((version - 1))]}
    log "INFO" "Selected version: $selected_version" "GREEN"
    
    # Download and extract rootfs
    download_and_extract_rootfs "$distro_name" "$selected_version" "$is_custom"
}

# Function to install custom distribution from URL
install_custom() {
    local pretty_name="$1"
    local url="$2"
    
    log "INFO" "Installing $pretty_name..." "GREEN"
    
    mkdir -p "$ROOTFS_DIR"
    
    local file_name
    file_name=$(basename "${url}")
    
    if ! curl -Ls "${url}" -o "$ROOTFS_DIR/$file_name"; then
        error_exit "Failed to download $pretty_name rootfs"
    fi
    
    if ! tar -xf "$ROOTFS_DIR/$file_name" -C "$ROOTFS_DIR"; then
        error_exit "Failed to extract $pretty_name rootfs"
    fi
    
    mkdir -p "$ROOTFS_DIR/home/container/"
    
    # Cleanup downloaded archive
    rm -f "$ROOTFS_DIR/$file_name"
}

# Function to get Chimera Linux URL
get_chimera_linux() {
    local base_url="https://repo.chimera-linux.org/live/latest/"
    local latest_file
    
    latest_file=$(curl -s "$base_url" | grep -o "chimera-linux-$ARCH-ROOTFS-[0-9]\{8\}-bootstrap\.tar\.gz" | sort -V | tail -n 1) ||
    error_exit "Failed to fetch Chimera Linux version"
    
    if [ -n "$latest_file" ]; then
        local date
        date=$(echo "$latest_file" | grep -o '[0-9]\{8\}')
        echo "${base_url}chimera-linux-$ARCH-ROOTFS-$date-bootstrap.tar.gz"
    else
        error_exit "No suitable Chimera Linux version found"
    fi
}

# Function to download and extract rootfs
download_and_extract_rootfs() {
    local distro_name="$1"
    local version="$2"
    local is_custom="$3"
    
    local arch_url
    local url
    if [[ "$is_custom" == "true" ]]; then
        arch_url="${BASE_URL}/${distro_name}/current/"
        url="${BASE_URL}/${distro_name}/current/${ARCH_ALT}/${version}/"
    else
        arch_url="${BASE_URL}/${distro_name}/${version}/"
        url="${BASE_URL}/${distro_name}/${version}/${ARCH_ALT}/default/"
    fi
    
    # Check if the distro support $ARCH_ALT
    if ! curl -s "$arch_url" | grep -q "$ARCH_ALT"; then
        error_exit "This distro doesn't support $ARCH_ALT. Exiting...."
        cleanup
        exit 1
    fi
    
    # Get latest version
    local latest_version
    latest_version=$(curl -s "$url" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"' | sort -r | head -n 1) ||
    error_exit "Failed to determine latest version"
    
    log "INFO" "Downloading rootfs..." "GREEN"
    mkdir -p "$ROOTFS_DIR"
    
    if ! curl -Ls "${url}${latest_version}/rootfs.tar.xz" -o "$ROOTFS_DIR/rootfs.tar.xz"; then
        error_exit "Failed to download rootfs"
    fi
    
    log "INFO" "Extracting rootfs..." "GREEN"
    if ! tar -xf "$ROOTFS_DIR/rootfs.tar.xz" -C "$ROOTFS_DIR"; then
        error_exit "Failed to extract rootfs"
    fi
    
    mkdir -p "$ROOTFS_DIR/home/container/"
}

# Parse port configuration
parse_ports() {
    local config_file="$ROOTFS_DIR/vps.config"
    local port_args=""
    
    while read line; do
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

# Function to handle post-install configuration for specific distros
post_install_config() {
    local distro="$1"
    
    case "$distro" in
        "archlinux")
            log "INFO" "Configuring Arch Linux specific settings..." "GREEN"
            sed -i '/^#RootDir/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i 's|/var/lib/pacman/|/var/lib/pacman|' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i '/^#DBPath/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
        ;;
    esac
}

# Main menu display
display_menu() {
    printf "\033c"
    printf "%b" \
    "${colors[GREEN]}╭────────────────────────────────────────────────────────────────────────────────╮${colors[NC]}\n" \
    "${colors[GREEN]}│                                                                                │${colors[NC]}\n" \
    "${colors[GREEN]}│                             Pterodactyl VPS EGG                                │${colors[NC]}\n" \
    "${colors[GREEN]}│                                                                                │${colors[NC]}\n" \
    "${colors[GREEN]}│                           ${colors[RED]}© 2021 - 2024 ${colors[PURPLE]}ysdragon${colors[GREEN]}                               │${colors[NC]}\n" \
    "${colors[GREEN]}│                                                                                │${colors[NC]}\n" \
    "${colors[GREEN]}╰────────────────────────────────────────────────────────────────────────────────╯${colors[NC]}\n\n" \
    "${colors[YELLOW]}Please choose your favorite distro:${colors[NC]}\n\n"
    
    # Define all available distributions
    declare distributions=(
        [1]="Debian"
        [2]="Ubuntu"
        [3]="Void Linux:true"
        [4]="Alpine Linux"
        [5]="CentOS"
        [6]="Rocky Linux"
        [7]="Fedora"
        [8]="AlmaLinux"
        [9]="Slackware Linux"
        [10]="Kali Linux"
        [11]="openSUSE"
        [12]="Gentoo Linux:true"
        [13]="Arch Linux"
        [14]="Devuan Linux"
        [15]="Chimera Linux:custom"
        [16]="Oracle Linux"
        [17]="Amazon Linux"
        [18]="Plamo Linux"
        [19]="Linux Mint"
        [20]="Alt Linux"
    )
    
    # Display all distributions
    for i in "${!distributions[@]}"; do
        printf "* [%d] %s\n" "$i" "${distributions[$i]%%:*}"
    done
    
    printf "                                                               \n"
    printf "${colors[YELLOW]}Enter the desired distro (1-20): ${colors[NC]}\n"
}

# Execute PRoot environment
exec_proot() {
    local port_args=$(parse_ports)
    
    "$ROOTFS_DIR/usr/local/bin/proot" \
    --rootfs="${ROOTFS_DIR}" \
    -0 -w "/root" \
    -b /dev -b /sys -b /proc -b /etc/resolv.conf \
    $port_args \
    --kill-on-exit \
    /bin/sh "/run.sh"
}


# Check if already installed
if [ -e "$ROOTFS_DIR/.installed" ]; then
    log "INFO" "System already installed, starting..." "GREEN"
    exec_proot
    exit 0
fi

# Initial setup
ARCH_ALT=$(detect_architecture)
check_network

# Display menu and get selection
display_menu

# Handle user selection and installation
read -rp "" selection

case "$selection" in
    1)
        install "debian" "Debian"
    ;;
    2)
        install "ubuntu" "Ubuntu"
    ;;
    3)
        install "voidlinux" "Void Linux" "true"
    ;;
    4)
        install "alpine" "Alpine Linux"
    ;;
    5)
        install "centos" "CentOS"
    ;;
    6)
        install "rockylinux" "Rocky Linux"
    ;;
    7)
        install "fedora" "Fedora"
    ;;
    8)
        install "almalinux" "Alma Linux"
    ;;
    9)
        install "slackware" "Slackware"
    ;;
    10)
        install "kali" "Kali Linux"
    ;;
    11)
        install "opensuse" "openSUSE"
    ;;
    12)
        install "gentoo" "Gentoo Linux" "true"
    ;;
    13)
        install "archlinux" "Arch Linux"
        post_install_config "archlinux"
    ;;
    14)
        install "devuan" "Devuan Linux"
    ;;
    15)
        chimera_url=$(get_chimera_linux)
        install_custom "Chimera Linux" "$chimera_url"
    ;;
    16)
        install "oracle" "Oracle Linux"
    ;;
    17)
        install "amazonlinux" "Amazon Linux"
    ;;
    18)
        install "plamo" "Plamo Linux"
    ;;
    19)
        install "mint" "Linux Mint"
    ;;
    20)
        install "alt" "Alt Linux"
    ;;
    *)
        error_exit "Invalid selection (1-20)"
    ;;
esac

# Post-installation tasks
install_proot
cleanup

# Mark as installed
touch "$ROOTFS_DIR/.installed"

# Start PRoot environment
exec_proot

# Trap for cleanup on script exit
trap cleanup EXIT