#!/bin/sh

# Source common functions and variables
. /common.sh

# Configuration variables
ROOTFS_DIR="/home/container"
BASE_URL="https://images.linuxcontainers.org/images"
DISTRO_MAP_URL="https://distromap.istan.to"

# Add to PATH
export PATH="$PATH:~/.local/usr/bin"

# Define all available distributions
# Format: "number:display_name:distro_id:flag:post_config:custom_handler"
distributions="
1:Debian:debian:false::
2:Ubuntu:ubuntu:false::
3:Void Linux:voidlinux:true::
4:Alpine Linux:alpine:false::
5:CentOS:centos:false::
6:Rocky Linux:rockylinux:false::
7:Fedora:fedora:false::
8:AlmaLinux:almalinux:false::
9:Slackware Linux:slackware:false::
10:Kali Linux:kali:false::
11:openSUSE:opensuse:special::opensuse_handler
12:Gentoo Linux:gentoo:true::
13:Arch Linux:archlinux:false:archlinux:
14:Devuan Linux:devuan:false::
15:Chimera Linux:chimera:custom::chimera_handler
16:Oracle Linux:oracle:false::
17:Amazon Linux:amazonlinux:false::
18:Plamo Linux:plamo:false::
19:Linux Mint:mint:false::
20:Alt Linux:alt:false::
21:Funtoo Linux:funtoo:false::
22:openEuler:openeuler:false::
23:Springdale Linux:springdalelinux:false::
"

# Count the number of distributions
num_distros=$(echo "$distributions" | grep -c "^[0-9]")

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

# Function to get version label from distromap
get_label() {
    local distro="$1"
    local version="$2"
    local response
    response=$(curl -s "$DISTRO_MAP_URL/distro/$distro/$version")
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "$version"
    else
        echo "$response" | jq -r '.label'
    fi
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
    
    # Count the number of available versions
    version_count=$(grep -c . "$temp_file")
    
    # If there is only one version, select it automatically.
    if [ "$version_count" -eq 1 ]; then
        version=1
    else
        # Display versions
        counter=1
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                label=$(get_label "$distro_name" "$line")
                printf "* [%d] %s %s\n" "$counter" "$pretty_name" "$label"
                counter=$((counter + 1))
            fi
        done < "$temp_file"
        
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
    fi
    
    # Extract the selected version from the list
    selected_version=$(sed -n "${version}p" "$temp_file")
    rm -f "$temp_file"

    selected_label=$(get_label "$distro_name" "$selected_version")
    log "INFO" "Selected version: $selected_label" "$GREEN"
    
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

# Custom handlers for special distributions
opensuse_handler() {
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

chimera_handler() {
    base_url="https://repo.chimera-linux.org/live/latest/"
    
    latest_file=$(curl -s "$base_url" | grep -o "chimera-linux-$ARCH-ROOTFS-[0-9]\{8\}-bootstrap\.tar\.gz" | sort -V | tail -n 1) ||
    error_exit "Failed to fetch Chimera Linux version"
    
    if [ -n "$latest_file" ]; then
        date=$(echo "$latest_file" | grep -o '[0-9]\{8\}')
        chimera_url="${base_url}chimera-linux-$ARCH-ROOTFS-$date-bootstrap.tar.gz"
        install_custom "Chimera Linux" "$chimera_url"
    else
        error_exit "No suitable Chimera Linux version found"
    fi
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
    latest_version=$(curl -s "$url" | grep 'href="' | grep -o '[0-9]\{8\}_[0-9]\{2\}:[0-9]\{2\}/' | sort -r | head -n 1) ||
    error_exit "Failed to determine latest version"

    log "INFO" "Downloading rootfs..." "$GREEN"
    mkdir -p "$ROOTFS_DIR"

    if ! curl -Ls "${url}${latest_version}rootfs.tar.xz" -o "$ROOTFS_DIR/rootfs.tar.xz"; then
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

# Function to parse distribution data by number
get_distro_data() {
    selection="$1"
    echo "$distributions" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            number=$(echo "$line" | cut -d: -f1)
            if [ "$number" = "$selection" ]; then
                echo "$line"
                break
            fi
        fi
    done
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
    echo "$distributions" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            number=$(echo "$line" | cut -d: -f1)
            display_name=$(echo "$line" | cut -d: -f2)
            printf "* [%s] %s\n" "$number" "$display_name"
        fi
    done
    
    printf "\n${YELLOW}Enter the desired distro (1-${num_distros}): ${NC}\n"
}

# Initial setup
ARCH_ALT=$(detect_architecture)
check_network

# Check if there is only one distribution
if [ "$num_distros" -eq 1 ]; then
    # Automatically select the only distribution
    selection=1
    distro_data=$(get_distro_data "$selection")
    display_name=$(echo "$distro_data" | cut -d: -f2)
else
    # Display menu and get selection
    display_menu

    # Handle user selection and installation
    read -r selection

    # Get distribution data for the selection
    distro_data=$(get_distro_data "$selection")
fi

if [ -z "$distro_data" ]; then
    error_exit "Invalid selection (1-${num_distros})"
fi

# Parse distribution data
number=$(echo "$distro_data" | cut -d: -f1)
display_name=$(echo "$distro_data" | cut -d: -f2)
distro_id=$(echo "$distro_data" | cut -d: -f3)
flag=$(echo "$distro_data" | cut -d: -f4)
post_config=$(echo "$distro_data" | cut -d: -f5)
custom_handler=$(echo "$distro_data" | cut -d: -f6)

# Handle installation based on the distribution data
if [ -n "$custom_handler" ]; then
    # Use custom handler for special distributions
    $custom_handler
else
    # Standard installation
    install "$distro_id" "$display_name" "$flag"
    
    # Run post-install configuration if specified
    if [ -n "$post_config" ]; then
        post_install_config "$post_config"
    fi
fi

# Copy run.sh and common.sh to ROOTFS_DIR and make them executable
cp /common.sh /run.sh "$ROOTFS_DIR"
chmod +x "$ROOTFS_DIR/common.sh" "$ROOTFS_DIR/run.sh"

# Trap for cleanup on script exit
trap cleanup EXIT
