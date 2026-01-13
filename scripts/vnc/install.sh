#!/bin/sh

if [ -f "/common.sh" ]; then
    . /common.sh
elif [ -f "$HOME/common.sh" ]; then
    . "$HOME/common.sh"
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    log() {
        printf "${3}[$1]${NC} $2\n"
    }
fi

VNC_DIR="$HOME/.vnc"
GUI_CONFIG_FILE="/gui_config.yml"

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

print_de_selection_menu() {
    printf "\n${CYAN}Select Desktop Environment:${NC}\n\n"
    printf "* [1] XFCE4 - Lightweight (~200MB)\n"
    printf "* [2] LXDE - Very lightweight (~100MB)\n"
    printf "* [3] LXQt - Modern lightweight (~150MB)\n"
    printf "* [4] MATE - Traditional desktop (~300MB)\n"
    printf "* [0] Cancel\n"
    printf "\n${YELLOW}Enter your choice (0-4): ${NC}\n"
}

get_port_input() {
    server_type="$1"
    default_port="$2"

    printf "${YELLOW}Enter $server_type port (default: $default_port): ${NC}\n" >&2
    read -r port_input

    if [ -z "$port_input" ]; then
        echo "$default_port"
        return
    fi

    case "$port_input" in
        *[!0-9]*)
            log "WARNING" "Invalid port, using default: $default_port" "$YELLOW" >&2
            echo "$default_port"
            ;;
        *)
            if [ "$port_input" -ge 1 ] && [ "$port_input" -le 65535 ]; then
                echo "$port_input"
            else
                log "WARNING" "Port out of range, using default: $default_port" "$YELLOW" >&2
                echo "$default_port"
            fi
            ;;
    esac
}

install_de_debian() {
    de="$1"
    case "$de" in
        "xfce4")
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xfce4 xfce4-terminal dbus-x11 x11-xserver-utils xfonts-base >&2
            echo "startxfce4"
            ;;
        "lxde")
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq lxde-core lxterminal dbus-x11 x11-xserver-utils xfonts-base >&2
            echo "startlxde"
            ;;
        "lxqt")
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq lxqt openbox dbus-x11 x11-xserver-utils xfonts-base >&2
            echo "startlxqt"
            ;;
        "mate")
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mate-desktop-environment-core dbus-x11 x11-xserver-utils xfonts-base >&2
            echo "mate-session"
            ;;
    esac
}

install_de_alpine() {
    de="$1"
    log "INFO" "Installing packages for Alpine (this may take a while)..." "$YELLOW" >&2

    sed -i 's|^#\(.*\/community\)$|\1|' /etc/apk/repositories 2>/dev/null
    apk update > /dev/null 2>&1

    apk add --no-cache dbus dbus-x11 xvfb xorg-server mesa-dri-gallium ttf-dejavu xterm 2>&1 | grep -v "^fetch\|^OK:" >&2

    case "$de" in
        "xfce4")
            apk add --no-cache xfce4 xfce4-terminal 2>&1 | grep -v "^fetch\|^OK:" >&2
            echo "startxfce4"
            ;;
        "lxde")
            apk add --no-cache lxsession pcmanfm openbox lxterminal lxdm 2>&1 | grep -v "^fetch\|^OK:" >&2
            echo "openbox-session"
            ;;
        "lxqt")
            apk add --no-cache lxqt-desktop openbox 2>&1 | grep -v "^fetch\|^OK:" >&2
            echo "startlxqt"
            ;;
        "mate")
            apk add --no-cache mate-desktop-environment mate-terminal 2>&1 | grep -v "^fetch\|^OK:" >&2
            echo "mate-session"
            ;;
    esac
}

install_de_arch() {
    de="$1"
    case "$de" in
        "xfce4")
            pacman -S --noconfirm --needed xfce4 xfce4-goodies xorg-server xorg-xinit dbus ttf-dejavu >&2
            echo "startxfce4"
            ;;
        "lxde")
            pacman -S --noconfirm --needed lxde xorg-server xorg-xinit dbus ttf-dejavu >&2
            echo "startlxde"
            ;;
        "lxqt")
            pacman -S --noconfirm --needed lxqt openbox xorg-server xorg-xinit dbus ttf-dejavu >&2
            echo "startlxqt"
            ;;
        "mate")
            pacman -S --noconfirm --needed mate mate-extra xorg-server xorg-xinit dbus ttf-dejavu >&2
            echo "mate-session"
            ;;
    esac
}

install_de_fedora() {
    de="$1"
    log "INFO" "Installing X11 base packages..." "$YELLOW" >&2
    dnf install -y xorg-x11-xauth dejavu-sans-fonts dbus dbus-x11 xterm >&2

    case "$de" in
        "xfce4")
            log "INFO" "Installing Xfce..." "$YELLOW" >&2
            dnf group install -y "Xfce Desktop" >&2 || dnf install -y xfce4-session xfwm4 xfce4-panel xfdesktop xfce4-terminal Thunar >&2
            echo "startxfce4"
            ;;
        "lxde")
            log "INFO" "Installing LXDE..." "$YELLOW" >&2
            dnf group install -y "LXDE Desktop" >&2 || dnf install -y openbox lxpanel lxsession pcmanfm lxterminal >&2
            echo "lxsession"
            ;;
        "lxqt")
            log "INFO" "Installing LXQt..." "$YELLOW" >&2
            dnf group install -y "LXQt Desktop" >&2 || dnf install -y openbox lxqt-session lxqt-panel pcmanfm-qt qterminal >&2
            echo "startlxqt"
            ;;
        "mate")
            log "INFO" "Installing MATE..." "$YELLOW" >&2
            dnf group install -y "MATE Desktop" >&2 || dnf install -y mate-session-manager marco mate-panel caja mate-terminal >&2
            echo "mate-session"
            ;;
    esac
}

install_de_void() {
    de="$1"
    case "$de" in
        "xfce4")
            xbps-install -y xfce4 xorg dbus dejavu-fonts-ttf >&2
            echo "startxfce4"
            ;;
        "lxde")
            xbps-install -y lxde xorg dbus dejavu-fonts-ttf >&2
            echo "startlxde"
            ;;
        "lxqt")
            xbps-install -y lxqt openbox xorg dbus dejavu-fonts-ttf >&2
            echo "startlxqt"
            ;;
        "mate")
            xbps-install -y mate xorg dbus dejavu-fonts-ttf >&2
            echo "mate-session"
            ;;
    esac
}

install_desktop_environment() {
    distro="$1"
    de="$2"

    log "INFO" "Installing $de desktop environment..." "$YELLOW" >&2

    de_startup=""
    case "$distro" in
        "debian"|"ubuntu"|"linuxmint"|"kali"|"devuan")
            apt-get update -qq >&2
            de_startup=$(install_de_debian "$de")
            ;;
        "alpine"|"chimera")
            apk update >&2
            de_startup=$(install_de_alpine "$de")
            ;;
        "arch"|"archlinux")
            pacman -Syu --noconfirm >&2
            de_startup=$(install_de_arch "$de")
            ;;
        "fedora")
            de_startup=$(install_de_fedora "$de")
            ;;
        "centos"|"rocky"|"almalinux"|"ol"|"openEuler"|"amzn")
            log "ERROR" "GUI installation not supported on RHEL-based distros (CentOS, AlmaLinux, Rocky, etc.)" "$RED" >&2
            log "INFO" "Try using Fedora, Debian, Ubuntu, or Alpine instead." "$YELLOW" >&2
            return 1
            ;;
        "void")
            xbps-install -Syu >&2
            de_startup=$(install_de_void "$de")
            ;;
        "opensuse"|"opensuse-tumbleweed"|"opensuse-leap")
            log "ERROR" "GUI installation not supported on openSUSE" "$RED" >&2
            log "INFO" "Try using Fedora, Debian, Ubuntu, or Alpine instead." "$YELLOW" >&2
            return 1
            ;;
        *)
            log "ERROR" "Unsupported distribution: $distro" "$RED" >&2
            return 1
            ;;
    esac

    if ! command -v "$de_startup" > /dev/null 2>&1; then
        log "ERROR" "Desktop startup command '$de_startup' not found after installation" "$RED" >&2
        log "INFO" "The package may not be available for $distro. Try a different DE." "$YELLOW" >&2
        return 1
    fi

    log "SUCCESS" "Desktop environment installed (startup: $de_startup)" "$GREEN" >&2
    echo "$de_startup"
    return 0
}

install_vnc_server() {
    distro="$1"

    log "INFO" "Installing VNC server..." "$YELLOW"

    case "$distro" in
        "debian"|"ubuntu"|"linuxmint"|"kali"|"devuan")
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq tigervnc-standalone-server tigervnc-common > /dev/null 2>&1
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq novnc websockify > /dev/null 2>&1
            ;;
        "alpine"|"chimera")
            apk add --no-cache tigervnc > /dev/null 2>&1
            apk add --no-cache novnc websockify > /dev/null 2>&1
            ;;
        "arch"|"archlinux")
            pacman -S --noconfirm --needed tigervnc > /dev/null 2>&1
            ;;
        "fedora")
            dnf install -y tigervnc-server > /dev/null 2>&1
            dnf install -y novnc python3-websockify > /dev/null 2>&1
            ;;

        "void")
            xbps-install -y tigervnc > /dev/null 2>&1
            ;;
    esac
}

setup_vnc() {
    de_startup="$1"
    vnc_port="$2"
    vnc_password="$3"

    mkdir -p "$VNC_DIR"

    cat > "$VNC_DIR/xstartup" << 'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources

XSTARTUP

    echo "exec $de_startup" >> "$VNC_DIR/xstartup"
    chmod +x "$VNC_DIR/xstartup"

    cat > "$VNC_DIR/config" << EOF
geometry=1280x720
depth=24
localhost=no
alwaysshared
EOF

    if command -v vncpasswd > /dev/null 2>&1; then
        printf "%s\n%s\nn\n" "$vnc_password" "$vnc_password" | vncpasswd > /dev/null 2>&1
    fi

    log "SUCCESS" "VNC configured on port $vnc_port" "$GREEN"
}

save_config() {
    de="$1"
    vnc_port="$2"
    vnc_password="$3"
    novnc_port="$4"
    de_startup="$5"

    cat > "$GUI_CONFIG_FILE" << EOF
desktop:
  environment: "$de"
  startup_command: "$de_startup"

vnc:
  port: "$vnc_port"
  password: "$vnc_password"
  resolution: "1280x720"
  depth: "24"

novnc:
  enable: true
  port: "$novnc_port"
EOF

    log "INFO" "Configuration saved to $GUI_CONFIG_FILE" "$YELLOW"
}

main() {
    distro=$(detect_distro)
    log "INFO" "Detected distribution: $distro" "$GREEN"

    print_de_selection_menu
    read -r de_choice

    case "$de_choice" in
        0)
            log "INFO" "Installation cancelled" "$YELLOW"
            return 0
            ;;
        1) de="xfce4" ;;
        2) de="lxde" ;;
        3) de="lxqt" ;;
        4) de="mate" ;;
        *)
            log "ERROR" "Invalid selection" "$RED"
            return 1
            ;;
    esac

    vnc_port=$(get_port_input "VNC" "5901")
    novnc_port=$(get_port_input "noVNC (web)" "6080")

    printf "${YELLOW}Enter VNC password: ${NC}\n"
    read -r gui_password
    if [ -z "$gui_password" ]; then
        gui_password="password"
        log "WARNING" "Using default password 'password' - CHANGE THIS!" "$RED"
    fi

    log "INFO" "Starting installation..." "$GREEN"

    de_startup=$(install_desktop_environment "$distro" "$de")
    if [ $? -ne 0 ] || [ -z "$de_startup" ]; then
        log "ERROR" "Failed to install desktop environment" "$RED"
        return 1
    fi

    install_vnc_server "$distro"
    setup_vnc "$de_startup" "$vnc_port" "$gui_password"

    save_config "$de" "$vnc_port" "$gui_password" "$novnc_port" "$de_startup"

    printf "\n"
    log "SUCCESS" "Installation completed!" "$GREEN"
    printf "\n${CYAN}Connection Information:${NC}\n"
    printf "  VNC Server:    port $vnc_port\n"
    printf "  noVNC (Web):   http://<server-ip>:$novnc_port\n"
    printf "  Start command: start-vnc\n"
    printf "\n"
    log "WARNING" "Remember to configure these ports in your Pterodactyl panel!" "$YELLOW"

    return 0
}

if [ "$1" = "install" ] || [ -z "$1" ]; then
    main
fi
