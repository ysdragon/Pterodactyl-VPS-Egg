#!/bin/sh

# Common color definitions
PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
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
    printf "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}║            ${PURPLE}${BOLD}██╗   ██╗██████╗ ███████╗    ███████╗ ██████╗  ██████╗${CYAN}             ║${NC}\n"
    printf "${CYAN}║            ${PURPLE}${BOLD}██║   ██║██╔══██╗██╔════╝    ██╔════╝██╔════╝ ██╔════╝${CYAN}             ║${NC}\n"
    printf "${CYAN}║            ${PURPLE}${BOLD}██║   ██║██████╔╝███████╗    █████╗  ██║  ███╗██║  ███╗${CYAN}            ║${NC}\n"
    printf "${CYAN}║            ${PURPLE}${BOLD}╚██╗ ██╔╝██╔═══╝ ╚════██║    ██╔══╝  ██║   ██║██║   ██║${CYAN}            ║${NC}\n"
    printf "${CYAN}║             ${PURPLE}${BOLD}╚████╔╝ ██║     ███████║    ███████╗╚██████╔╝╚██████╔╝${CYAN}            ║${NC}\n"
    printf "${CYAN}║              ${PURPLE}${BOLD}╚═══╝  ╚═╝     ╚══════╝    ╚══════╝ ╚═════╝  ╚═════╝${CYAN}             ║${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}║                      ${GREEN}✨  Lightweight • Fast • Reliable ✨${CYAN}                       ║${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}║                           ${DIM}© 2021 - $(date +%Y) ${PURPLE}@ysdragon${CYAN}                             ║${NC}\n"
    printf "${CYAN}║                                                                               ║${NC}\n"
    printf "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
}

# Function to print the help banner
print_help_banner() {
    printf "${BLUE}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}║                           ${WHITE}${BOLD}📋  AVAILABLE COMMANDS 📋${BLUE}                             ║${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}╠═══════════════════════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}║  ${CYAN}🧹  ${YELLOW}${BOLD}clear, cls${NC}        ${GREEN}▶  ${WHITE}Clear the terminal screen${BLUE}                            ║${NC}\n"
    printf "${BLUE}║  ${RED}🔌  ${YELLOW}${BOLD}exit${NC}              ${GREEN}▶  ${WHITE}Shutdown the container server${BLUE}                        ║${NC}\n"
    printf "${BLUE}║  ${PURPLE}📜  ${YELLOW}${BOLD}history${NC}           ${GREEN}▶  ${WHITE}Display command history${BLUE}                              ║${NC}\n"
    printf "${BLUE}║  ${CYAN}🔄  ${YELLOW}${BOLD}reinstall${NC}         ${GREEN}▶  ${WHITE}Reinstall the operating system${BLUE}                       ║${NC}\n"
    printf "${BLUE}║  ${GREEN}🔐  ${YELLOW}${BOLD}install-ssh${NC}       ${GREEN}▶  ${WHITE}Install custom SSH server${BLUE}                            ║${NC}\n"
    printf "${BLUE}║  ${BLUE}📊  ${YELLOW}${BOLD}status${NC}            ${GREEN}▶  ${WHITE}Show detailed system status${BLUE}                          ║${NC}\n"
    printf "${BLUE}║  ${YELLOW}💾  ${YELLOW}${BOLD}backup${NC}            ${GREEN}▶  ${WHITE}Create a complete system backup${BLUE}                      ║${NC}\n"
    printf "${BLUE}║  ${PURPLE}📥  ${YELLOW}${BOLD}restore${NC}           ${GREEN}▶  ${WHITE}Restore from a system backup${BLUE}                         ║${NC}\n"
    printf "${BLUE}║  ${WHITE}❓  ${YELLOW}${BOLD}help${NC}              ${GREEN}▶  ${WHITE}Display this help information${BLUE}                        ║${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}╠═══════════════════════════════════════════════════════════════════════════════╣${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}║                     ${DIM}💡 Tip: Type any command to get started!${BLUE}                   ║${NC}\n"
    printf "${BLUE}║                                                                               ║${NC}\n"
    printf "${BLUE}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
}