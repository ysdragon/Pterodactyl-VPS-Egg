#!/bin/sh

# Source common functions and variables
. /common.sh

# Configuration variables
ROOTFS_DIR="/home/container"
BASE_URL="https://images.linuxcontainers.org/images"

# Add to PATH
export PATH="$PATH:~/.local/usr/bin"

# Define all available distributions
# Format: "number:name[:flag]"
distributions="
1:Debian
2:Ubuntu
3:Void Linux:true
4:Alpine Linux
5:CentOS
6:Rocky Linux
7:Fedora
8:AlmaLinux
9:Slackware Linux
10:Kali Linux
11:openSUSE
12:Gentoo Linux:true
13:Arch Linux
14:Devuan Linux
15:Chimera Linux:custom
16:Oracle Linux
17:Amazon Linux
18:Plamo Linux
19:Linux Mint
20:Alt Linux
21:Funtoo Linux
22:openEuler
23:Springdale Linux
"

# Count the number of distributions
num_distros=$(echo "$distributions" | wc -l)

# Error handling function
error_exit() {
    log "ERROR" "$1" "$RED"
    exit 1
}

# Detect the machine architecture.
ARCH=$(uname -m)

# Verify network connectivity
check_network() {
    if ! curl -s --head "$BASE_URL" >/dev/null; then
        error_exit "Unable to connect to $BASE_URL. Please check your internet connection."
    fi
}

# Function to cleanup temporary files
cleanup() {
    log "INFO" "Cleaning up temporary files..." "$YELLOW"
    rm -f "$ROOTFS_DIR/rootfs.tar.xz"
    rm -rf /tmp/sbin
}

# Function to install a specific distro
install() {
    distro_name="$1"
    pretty_name="$2"
    is_custom="$3"
    
    # Set default value if not provided
    if [ -z "$is_custom" ]; then
        is_custom="false"
    fi
    
    log "INFO" "Preparing to install $pretty_name..." "$GREEN"
    
    if [ "$is_custom" = "true" ]; then
        url_path="$BASE_URL/$distro_name/current/$ARCH_ALT/"
    else
        url_path="$BASE_URL/$distro_name/"
    fi
    
    # Fetch available versions with error handling
    image_names=$(curl -s "$url_path" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"/' | grep -v '^\.\.$') ||
    error_exit "Failed to fetch available versions for $pretty_name"
    
    # Convert to a list format
    versions=""
    counter=1
    
    # Use a temporary file to avoid subshell variable scope issues
    temp_file="/tmp/install_versions.$$"
    echo "$image_names" > "$temp_file"
    
    # Display versions
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            printf "* [%d] %s (%s)\n" "$counter" "$pretty_name" "$line"
            counter=$((counter + 1))
        fi
    done < "$temp_file"
    
    # Adjust counter to represent the actual number of versions
    version_count=$((counter - 1))
    
    printf "* [0] Go Back\n"
    
    # Version selection with validation
    version=""
    while true; do
        printf "${YELLOW}Enter the desired version (0-${version_count}): ${NC}\n"
        read -r version
        if [ "$version" = "0" ]; then
            rm -f "$temp_file"
            exec "$0"
        elif echo "$version" | grep -q '^[0-9]*$' && [ "$version" -ge 1 ] && [ "$version" -le "${version_count}" ]; then
            break
        fi
        log "ERROR" "Invalid selection. Please try again." "$RED"
    done
    
    # Extract the selected version from the list
    selected_version=$(sed -n "${version}p" "$temp_file")
    rm -f "$temp_file"
    
    log "INFO" "Selected version: $selected_version" "$GREEN"
    
    # Download and extract rootfs
    download_and_extract_rootfs "$distro_name" "$selected_version" "$is_custom"
}

# Function to install custom distribution from URL
install_custom() {
    pretty_name="$1"
    url="$2"
    
    log "INFO" "Installing $pretty_name..." "$GREEN"
    
    mkdir -p "$ROOTFS_DIR"
    
    file_name=$(basename "$url")
    
    if ! curl -Ls "$url" -o "$ROOTFS_DIR/$file_name"; then
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
    base_url="https://repo.chimera-linux.org/live/latest/"
    
    latest_file=$(curl -s "$base_url" | grep -o "chimera-linux-$ARCH-ROOTFS-[0-9]\{8\}-bootstrap\.tar\.gz" | sort -V | tail -n 1) ||
    error_exit "Failed to fetch Chimera Linux version"
    
    if [ -n "$latest_file" ]; then
        date=$(echo "$latest_file" | grep -o '[0-9]\{8\}')
        echo "${base_url}chimera-linux-$ARCH-ROOTFS-$date-bootstrap.tar.gz"
    else
        error_exit "No suitable Chimera Linux version found"
    fi
}

# Function to install openSUSE Linux based on version
install_opensuse_linux() {
    printf "Select openSUSE version:\n"
    printf "* [1] openSUSE Leap\n"
    printf "* [2] openSUSE Tumbleweed\n"
    printf "* [0] Go Back\n"
    
    opensuse_version=""
    while true; do
        printf "${YELLOW}Enter your choice (0-2): ${NC}\n"
        read -r opensuse_version
        case "$opensuse_version" in
            0)
            exec "$0"
            ;;
            1)
            log "INFO" "Selected version: openSUSE Leap" "$GREEN"
            case "$ARCH" in
                aarch64|x86_64)
                url="https://download.opensuse.org/distribution/openSUSE-current/appliances/opensuse-leap-image.${ARCH}-lxc.tar.xz"
                install_custom "openSUSE Leap" "$url"
                ;;
                *)
                error_exit "openSUSE Leap is not available for ${ARCH} architecture"
                ;;
            esac
            break
            ;;
            2)
            log "INFO" "Selected version: openSUSE Tumbleweed" "$GREEN"
            if [ "$ARCH" = "x86_64" ]; then
                install_custom "openSUSE Tumbleweed" "https://download.opensuse.org/tumbleweed/appliances/opensuse-tumbleweed-image.x86_64-lxc.tar.xz"
            else
                error_exit "openSUSE Tumbleweed is not available for ${ARCH} architecture"
            fi
            break
            ;;
            *)
            log "ERROR" "Invalid selection. Please try again." "$RED"
            ;;
        esac
    done
}

# Function to download and extract rootfs
download_and_extract_rootfs() {
    distro_name="$1"
    version="$2"
    is_custom="$3"
    
    if [ "$is_custom" = "true" ]; then
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
    latest_version=$(curl -s "$url" | grep 'href="' | grep -o '"[^/"]*/"' | tr -d '"' | sort -r | head -n 1) ||
    error_exit "Failed to determine latest version"
    
    log "INFO" "Downloading rootfs..." "$GREEN"
    mkdir -p "$ROOTFS_DIR"
    
    if ! curl -Ls "${url}${latest_version}/rootfs.tar.xz" -o "$ROOTFS_DIR/rootfs.tar.xz"; then
        error_exit "Failed to download rootfs"
    fi
    
    log "INFO" "Extracting rootfs..." "$GREEN"
    if ! tar -xf "$ROOTFS_DIR/rootfs.tar.xz" -C "$ROOTFS_DIR"; then
        error_exit "Failed to extract rootfs"
    fi
    
    # Removing existing /etc/resolv.conf to allow modification
    rm -f "$ROOTFS_DIR/etc/resolv.conf"
    
    mkdir -p "$ROOTFS_DIR/home/container/"
}

# Function to handle post-install configuration for specific distros
post_install_config() {
    distro="$1"
    
    case "$distro" in
        "archlinux")
            log "INFO" "Configuring Arch Linux specific settings..." "$GREEN"
            sed -i '/^#RootDir/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i 's|/var/lib/pacman/|/var/lib/pacman|' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i '/^#DBPath/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
        ;;
    esac
}

# Main menu display
display_menu() {
    print_main_banner
    printf "\n${YELLOW}Please choose your favorite distro:${NC}\n\n"
    
    # Display all distributions
    counter=1
    echo "$distributions" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            # Extract the name part (before any colon flag)
            name=$(echo "$line" | cut -d: -f2 | cut -d: -f1)
            printf "* [%d] %s\n" "$counter" "$name"
            counter=$((counter + 1))
        fi
    done
    
    printf "\n${YELLOW}Enter the desired distro (1-${num_distros}): ${NC}\n"
}

# Initial setup
ARCH_ALT=$(detect_architecture)
check_network

# Display menu and get selection
display_menu

# Handle user selection and installation
read -r selection

case "$selection" in
    1)
        install "debian" "Debian" "false"
    ;;
    2)
        install "ubuntu" "Ubuntu" "false"
    ;;
    3)
        install "voidlinux" "Void Linux" "true"
    ;;
    4)
        install "alpine" "Alpine Linux" "false"
    ;;
    5)
        install "centos" "CentOS" "false"
    ;;
    6)
        install "rockylinux" "Rocky Linux" "false"
    ;;
    7)
        install "fedora" "Fedora" "false"
    ;;
    8)
        install "almalinux" "Alma Linux" "false"
    ;;
    9)
        install "slackware" "Slackware" "false"
    ;;
    10)
        install "kali" "Kali Linux" "false"
    ;;
    11)
        install_opensuse_linux
    ;;
    12)
        install "gentoo" "Gentoo Linux" "true"
    ;;
    13)
        install "archlinux" "Arch Linux" "false"
        post_install_config "archlinux"
    ;;
    14)
        install "devuan" "Devuan Linux" "false"
    ;;
    15)
        chimera_url=$(get_chimera_linux)
        install_custom "Chimera Linux" "$chimera_url"
    ;;
    16)
        install "oracle" "Oracle Linux" "false"
    ;;
    17)
        install "amazonlinux" "Amazon Linux" "false"
    ;;
    18)
        install "plamo" "Plamo Linux" "false"
    ;;
    19)
        install "mint" "Linux Mint" "false"
    ;;
    20)
        install "alt" "Alt Linux" "false"
    ;;
    21)
        install "funtoo" "Funtoo Linux" "false"
    ;;
    22)
        install "openeuler" "openEuler" "false"
    ;;
    23)
        install "springdalelinux" "Springdale Linux" "false"
    ;;
    *)
        error_exit "Invalid selection (1-${num_distros})"
    ;;
esac

# Copy run.sh script to ROOTFS_DIR and make it executable
cp /run.sh "$ROOTFS_DIR/run.sh"
chmod +x "$ROOTFS_DIR/run.sh"

# Trap for cleanup on script exit
trap cleanup EXIT