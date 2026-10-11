#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

REPO="https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main"

# ---------------------------------------------------------------------------
# The heavy part: apt update/upgrade + fetch + run the chosen setup script.
# Runs INSIDE a detached screen so an SSH drop (e.g. sshd being upgraded by
# `apt upgrade`) can NOT kill the install.
# ---------------------------------------------------------------------------
run_install() {
    local V="$1"

    echo -e "${YELLOW}${BOLD}>> Installing Script Multiport Version ${V}.0${RESET}"
    echo

    apt update -y && \
    apt upgrade -y && \
    apt dist-upgrade -y && \
    apt update && \
    apt install -y bzip2 gzip coreutils screen wget curl && \
    wget -O "setup-v${V}.sh" "${REPO}/setup-v${V}.sh" && \
    chmod +x "setup-v${V}.sh" && \
    sed -i -e 's/\r$//' "setup-v${V}.sh" && \
    "./setup-v${V}.sh"

    local rc=$?
    echo
    if [ "$rc" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}=== install chain finished OK ===${RESET}"
    else
        echo -e "${RED}${BOLD}=== install chain exited with code $rc ===${RESET}"
    fi
    echo -e "${CYAN}Full log: /root/install.log  |  service list: /root/log-install.txt${RESET}"
}

# ---------------------------------------------------------------------------
# INNER MODE — already inside the detached screen.
# ---------------------------------------------------------------------------
if [ "$1" = "--run" ]; then
    run_install "$2"
    echo
    echo -e "${GREEN}${BOLD}Done.${RESET}"
    echo -e "${YELLOW}Press ENTER to close this screen (the install is finished).${RESET}"
    read -r -p "> " _
    exit 0
fi

# ---------------------------------------------------------------------------
# OUTER MODE — the chooser menu.
# ---------------------------------------------------------------------------
while true; do
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}              ${BOLD}${MAGENTA}TAKUMI1337Z MULTIPORT SCRIPT${RESET}              ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}  ${GREEN}1)${RESET} Install Version 2.0 [OLD XRAYCORE]                 ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${GREEN}2)${RESET} Install Version 3.0 [LATEST XRAYCORE+NEW SERVICES] ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${RED}0)${RESET} Exit                                               ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -ne "${BOLD}${WHITE}Pilih option [0-2]: ${RESET}"
    read -r choice

    case "$choice" in
        1|2)
            if ! command -v screen >/dev/null 2>&1; then
                echo -e "${YELLOW}Installing 'screen' first (needed for a crash-proof install)...${RESET}"
                apt update -y >/dev/null 2>&1
                apt install -y screen >/dev/null 2>&1
            fi

            if [ -z "$STY" ] && command -v screen >/dev/null 2>&1; then
                screen -wipe >/dev/null 2>&1
                echo
                echo -e "${GREEN}Starting install inside screen session 'setup'.${RESET}"
                echo -e "${YELLOW}If your SSH drops, the install KEEPS RUNNING.${RESET}"
                echo -e "${YELLOW}Reconnect and run:   screen -r setup${RESET}"
                sleep 3
                # -L logs the whole session; the chain (apt included) runs inside screen
                exec screen -L -Logfile /root/install.log -S setup bash "$0" --run "$choice"
            fi

            # no screen available (rare) — fall back to a direct run
            run_install "$choice"
            read -r dummy
            ;;
        0)
            echo
            echo -e "${RED}${BOLD}Keluar dari installer. Bye!${RESET}"
            exit 0
            ;;
        *)
            echo
            echo -e "${RED}Pilihan tak sah! Sila pilih 0, 1 atau 2.${RESET}"
            echo -ne "${CYAN}Tekan ENTER untuk cuba lagi...${RESET}"
            read -r dummy
            ;;
    esac
done
