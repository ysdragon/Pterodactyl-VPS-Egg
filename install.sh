#!/bin/bash

PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

#############################
# Linux Installation #
#############################

# Define the root directory to /home/container.
# We can only write in /home/container and /tmp in the container.
ROOTFS_DIR=/home/container

export PATH=$PATH:~/.local/usr/bin

PROOT_VERSION="5.4.0"

# Detect the machine architecture.
ARCH=$(uname -m)

# Check machine architecture to make sure it is supported.
# If not, we exit with a non-zero status code.
if [ "$ARCH" = "x86_64" ]; then
    ARCH_ALT=amd64
    elif [ "$ARCH" = "aarch64" ]; then
    ARCH_ALT=arm64
    elif [ "$ARCH" = "riscv64" ]; then
    ARCH_ALT=riscv64
else
    printf "Unsupported CPU architecture: ${ARCH}"
    exit 1
fi

# Base mirror url
BASE_URL="https://images.linuxcontainers.org/images"

# Function to install a specific distro
install() {
    local distro_name="$1"
    local pretty_name="$2"
    # Fetch the directory listing and extract the image names
    image_names=$(curl -s "$BASE_URL/$distro_name/" | grep -oP '(?<=href=")[^/]+(?=/")' | grep -v '^\.\.$')
    
    # Convert the space-separated string into an array
    set -- $image_names
    image_names=("$@")
    
    # Display the available versions
    for i in "${!image_names[@]}"; do
        echo "* [$((i + 1))] ${pretty_name} (${image_names[i]})"
    done
    
    echo -e "${YELLOW}Enter the desired version (1-${#image_names[@]}): ${NC}"
    read -p "" version
    
    # Validate the input
    if [[ $version -lt 1 || $version -gt ${#image_names[@]} ]]; then
        echo -e "${RED}Invalid selection. Exiting.${NC}"
        exit 1
    fi
    
    # Get the selected version
    selected_version=${image_names[$((version - 1))]}
    echo -e "${GREEN}Installing $pretty_name (${selected_version})...${NC}"
    
    ARCH_URL="${BASE_URL}/${distro_name}/${selected_version}/"

    # Check if the distro support $ARCH_ALT
    if ! curl -s "$ARCH_URL" | grep -q "$ARCH_ALT"; then
        echo -e "${RED}Error: This distro doesn't support $ARCH_ALT. Exiting.${NC}"
        exit 1
    fi
    
    URL="${BASE_URL}/${distro_name}/${selected_version}/${ARCH_ALT}/default/"

    # Fetch the latest version of the root filesystem
    LATEST_VERSION=$(curl -s "$URL" | grep -oP 'href="\K[^"]+/' | sort -r | head -n 1)
    
    # Download and extract the root filesystem
    mkdir -p "$ROOTFS_DIR"
    curl -Ls "${URL}${LATEST_VERSION}/rootfs.tar.xz" -o "$ROOTFS_DIR/rootfs.tar.xz"
    tar -xf "$ROOTFS_DIR/rootfs.tar.xz" -C "$ROOTFS_DIR"
    mkdir -p "$ROOTFS_DIR/home/container/"
}

# Function to install a specific distro (custom)
install_custom() {
    local distro_name="$1"
    local pretty_name="$2"
    # Fetch the directory listing and extract the image names
    image_names=$(curl -s "$BASE_URL/$distro_name/current/$ARCH_ALT/" | grep -oP '(?<=href=")[^/]+(?=/")' | grep -v '^\.\.$')
    
    # Convert the space-separated string into an array
    set -- $image_names
    image_names=("$@")
    
    # Display the available versions
    for i in "${!image_names[@]}"; do
        echo "* [$((i + 1))] ${pretty_name} (${image_names[i]})"
    done
    
    echo -e "${YELLOW}Enter the desired version (1-${#image_names[@]}): ${NC}"
    read -p "" version
    
    # Validate the input
    if [[ $version -lt 1 || $version -gt ${#image_names[@]} ]]; then
        echo -e "${RED}Invalid selection. Exiting.${NC}"
        exit 1
    fi
    
    # Get the selected version
    selected_version=${image_names[$((version - 1))]}
    echo -e "${GREEN}Installing $pretty_name (${selected_version})...${NC}"
    
    URL="$BASE_URL/${distro_name}/current/$ARCH_ALT/$selected_version/"
    
    # Fetch the latest version of the root filesystem
    LATEST_VERSION=$(curl -s "$URL" | grep -oP 'href="\K[^"]+/' | sort -r | head -n 1)
    
    # Download and extract the root filesystem
    mkdir -p "$ROOTFS_DIR"
    curl -Ls "${URL}${LATEST_VERSION}/rootfs.tar.xz" -o "$ROOTFS_DIR/rootfs.tar.xz"
    tar -xf "$ROOTFS_DIR/rootfs.tar.xz" -C "$ROOTFS_DIR"
    mkdir -p "$ROOTFS_DIR/home/container/"
}

# Download & decompress the Linux root file system if not already installed.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    
    # Clear the terminal
    printf "\033c"
    
    # Display the menu
    echo -e "${GREEN}╭────────────────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${GREEN}│                                                                                │${NC}"
    echo -e "${GREEN}│                             Pterodactyl VPS EGG                                │${NC}"
    echo -e "${GREEN}│                                                                                │${NC}"
    echo -e "${GREEN}│                           ${RED}© 2021 - 2024 ${PURPLE}ysdragon${GREEN}                               │${NC}"
    echo -e "${GREEN}│                                                                                │${NC}"
    echo -e "${GREEN}╰────────────────────────────────────────────────────────────────────────────────╯${NC}"
    echo "                                                                                               "
    echo -e "${YELLOW}Please choose your favorite distro                                               ${NC}"
    echo "                                                                                               "
    echo "* [1] Debian                                                                                   "
    echo "* [2] Ubuntu                                                                                   "
    echo "* [3] Void Linux                                                                               "
    echo "* [4] Alpine Linux                                                                             "
    echo "* [5] CentOS                                                                                   "
    echo "* [6] Rocky Linux                                                                              "
    echo "* [7] Fedora                                                                                   "
    echo "* [8] AlmaLinux                                                                                "
    echo "* [9] Slackware Linux                                                                          "
    echo "* [10] Kali Linux                                                                              "
    echo "* [11] openSUSE                                                                                "
    echo "* [12] Gentoo Linux                                                                            "
    echo "* [13] Arch Linux                                                                              "
    echo "* [14] Devuan Linux                                                                            "
    echo "                                                                                               "
    echo -e "${YELLOW}Enter OS (1-14):                                                                 ${NC}"
    
    read -p "" input
    
    case $input in
        
        1)
            install             "debian"        "Debian"
        ;;
        
        2)
            install             "ubuntu"        "Ubuntu"
        ;;
        
        3)
            install_custom      "voidlinux"     "Void Linux"
        ;;
        
        4)
            install             "alpine"        "Alpine Linux"
        ;;
        
        5)
            install             "centos"        "CentOS"
        ;;
        
        6)
            install             "rockylinux"    "Rocky Linux"
        ;;
        
        7)
            install             "fedora"        "Fedora"
        ;;
        
        8)
            install             "almalinux"     "Alma Linux"
        ;;
        
        9)
            install             "slackware"     "Slackware"
        ;;
        
        
        10)
            install             "kali"          "Kali Linux"
        ;;
        
        11)
            install             "opensuse"      "openSUSE"
        ;;
        
        12)
            install_custom      "gentoo"        "Gentoo Linux"
        ;;
        
        13)
            install             "archlinux"     "Arch Linux"
            
            # Fix pacman
            sed -i '/^#RootDir/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i 's|/var/lib/pacman/|/var/lib/pacman|' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i '/^#DBPath/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
        ;;
        
        14)
            install             "devuan"        "Devuan Linux"
        ;;
        
        *)
            echo "${RED}Invalid selection. Exiting.${NC}"
            exit 1
        ;;
    esac
fi

################################
# Package Installation & Setup #
#################################

# Download static proot.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    # Create "$ROOTFS_DIR/usr/local/bin" dir
    mkdir -p "$ROOTFS_DIR/usr/local/bin"
    # Download static proot.
    curl -Ls "https://github.com/ysdragon/proot-static/releases/download/v${PROOT_VERSION}/proot-${ARCH}-static" -o "$ROOTFS_DIR/usr/local/bin/proot"
    # Make PRoot executable.
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
fi

# Clean-up after installation complete & finish up.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    # Add DNS Resolver nameservers to resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
    # Wipe the files we downloaded into /tmp previously.
    rm -rf $ROOTFS_DIR/rootfs.tar.xz /tmp/sbin
    # Create .installed to later check whether OS is installed.
    touch "$ROOTFS_DIR/.installed"
fi

###########################
# Start PRoot environment #
###########################

# Get all ports from vps.config
port_args=""
while read line; do
    case "$line" in
        internalip=*) ;;
        port[0-9]*=*) port=${line#*=}; if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi;;
        port=*) port=${line#*=}; if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi;;
    esac
done < "$ROOTFS_DIR/vps.config"

# This command starts PRoot and binds several important directories
# from the host file system to our special root file system.
"$ROOTFS_DIR/usr/local/bin/proot" \
--rootfs="${ROOTFS_DIR}" \
-0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf $port_args --kill-on-exit \
/bin/sh "/run.sh"