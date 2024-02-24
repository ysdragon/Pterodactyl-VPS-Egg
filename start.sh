#!/bin/sh

#############################
# Linux Installation #
#############################

# Define the root directory to /home/container.
# We can only write in /home/container and /tmp in the container.
ROOTFS_DIR=/home/container

export PATH=$PATH:~/.local/usr/bin

PROOT_VERSION="5.3.0" # Some releases do not have static builds attached.

# Detect the machine architecture.
ARCH=$(uname -m)

# Check machine architecture to make sure it is supported.
# If not, we exit with a non-zero status code.
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# Download & decompress the Linux root file system if not already installed.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then

  echo "╭────────────────────────────────────────────────────────────────────────────────╮"
  echo "│                                                                                │"
  echo "│                             Pterodactyl VPS EGG                                │"
  echo "│                                                                                │"
  echo "│                           © 2021 - 2024 ysdragon                               │"
  echo "│                                                                                │"
  echo "╰────────────────────────────────────────────────────────────────────────────────╯"
  echo "                                                                                  "
  echo "Please choose your favorite distro                                                "
  echo "                                                                                  "  
  echo "* [1] Debian                                                                      "
  echo "* [2] Ubuntu                                                                      "
  echo "* [3] Void Linux                                                                  "

  read -p "Enter OS (1-2): " input

  case $input in

    1)
      wget --no-hsts -O /tmp/rootfs.tar.gz \
      "https://github.com/JuliaCI/rootfs-images/releases/download/v7.0/debian_minimal.${ARCH}.tar.gz"
      tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
      mkdir $ROOTFS_DIR/home/container/ -p
      ;;

    2)
      wget --no-hsts -O /tmp/rootfs.tar.gz \
      "https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"
      tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
      mkdir $ROOTFS_DIR/home/container/ -p
      ;;

    3)
      wget --no-hsts -O /tmp/rootfs.tar.xz \
      "https://repo-fastly.voidlinux.org/live/current/void-${ARCH}-ROOTFS-20230628.tar.xz"
      tar -xf /tmp/rootfs.tar.xz -C "$ROOTFS_DIR"
      mkdir $ROOTFS_DIR/home/container/ -p
      ;;

    *)
      echo "Invalid selection. Exiting."
      exit 1
      ;;
  esac
fi

################################
# Package Installation & Setup #
#################################

# Download static proot.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    # Download the packages from their sources
    mkdir -p "$ROOTFS_DIR/usr/local/bin"
    wget --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    # Make PRoot executable.
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
fi

# Clean-up after installation complete & finish up.
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    # Add DNS Resolver nameservers to resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
    # Wipe the files we downloaded into /tmp previously.
    rm -rf /tmp/rootfs.tar.xz /tmp/sbin
    # Create .installed to later check whether OS is installed.
    touch "$ROOTFS_DIR/.installed"
fi

###########################
# Start PRoot environment #
###########################

# This command starts PRoot and binds several important directories
# from the host file system to our special root file system.
"$ROOTFS_DIR/usr/local/bin/proot" \
--rootfs="${ROOTFS_DIR}" \
-0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit \
/bin/bash
