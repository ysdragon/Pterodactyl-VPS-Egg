#!/bin/sh

# Common color definitions
PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Common logger function
log() {
    level=$1
    message=$2
    color=$3
    
    if [ -z "$color" ]; then
        color="$NC"
    fi
    
    printf "${color}[$level]${NC} $message\n"
}

# Function to detect architecture
detect_architecture() {
    ARCH=$(uname -m)
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
            log "ERROR" "Unsupported CPU architecture: $ARCH" "$RED" >&2
            return 1
        ;;
    esac
}

# Function to print the main banner
print_main_banner() {
    printf "\033c"
    printf "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}\n"
    printf "${GREEN}┃                                                                             ┃${NC}\n"
    printf "${GREEN}┃                           ${PURPLE} Pterodactyl VPS EGG ${GREEN}                             ┃${NC}\n"
    printf "${GREEN}┃                                                                             ┃${NC}\n"
    printf "${GREEN}┃                          ${RED}© 2021 - $(date +%Y) ${PURPLE}@ysdragon${GREEN}                            ┃${NC}\n"
    printf "${GREEN}┃                                                                             ┃${NC}\n"
    printf "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}\n"
}

# Function to print the help banner
print_help_banner() {
    printf "${PURPLE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}\n"
    printf "${PURPLE}┃                                                                             ┃${NC}\n"
    printf "${PURPLE}┃                          ${GREEN}✦ Available Commands ✦${PURPLE}                             ┃${NC}\n"
    printf "${PURPLE}┃                                                                             ┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}clear, cls${GREEN}         ❯  Clear the screen                                  ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}exit${GREEN}               ❯  Shutdown the server                               ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}history${GREEN}            ❯  Show command history                              ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}reinstall${GREEN}          ❯  Reinstall the server                              ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}install-ssh${GREEN}        ❯  Install our custom SSH server                     ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}status${GREEN}             ❯  Show system status                                ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}backup${GREEN}             ❯  Create a system backup                            ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}restore${GREEN}            ❯  Restore a system backup                           ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃     ${YELLOW}help${GREEN}               ❯  Display this help message                         ${PURPLE}┃${NC}\n"
    printf "${PURPLE}┃                                                                             ┃${NC}\n"
    printf "${PURPLE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}\n"
}