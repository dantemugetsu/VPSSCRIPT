#!/bin/bash
# =========================================
# Quick Setup | Swap RAM Manager
# Edition : Stable Edition V1.0
# Auther  : NevermoreSSH
# Date    : 22/11/2025
# (C) Copyright 2025
# =========================================
# Warna
line="38;5;208"         # Oyen terang
GREEN="\e[92m" # hijau
PINK="\e[38;5;205m" # Pink terang
back_text="1;37;44"  # Putih + biru gelap
box="1;37"           # Putih bold
# ============================
# COLOR THEME PREMIUM
# ============================
text="1;37"          # Putih bold (info text)
title="\e[30;107m"   # 30 = hitam, 107 = background putih
number="\e[38;5;205"        # Kuning gold (untuk nombor menu)
below="0;37"         # Putih lembut
reset="\e[0m"
P='\e[0;35m'
B='\033[0;36m'
G='\033[0;32m'
R='\033[0;31m'
W='\033[1;37m'
NC='\e[0m'

# Function Show Current Swap
showswap() {
    curr_swap=$(grep -w "/swapfile" /proc/swaps | awk '{print $3}')
    curr_swap_mb=$((curr_swap / 1024))

    if [ "$curr_swap_mb" -gt 0 ]; then
        swap_status="${G}Active${NC}"
    else
        swap_status="${R}Not Active${NC}"
    fi

    echo -e "${W}Current Swap : ${G}${curr_swap_mb} MB${NC} (${swap_status})"
    echo ""
}

swapram() {
clear
echo -e "\e[${line}m═══════════════════════════════════${reset}"
echo -e "\e[${title}        [ CUSTOM SWAP-RAM ]         ${reset}"
echo -e "\e[${line}m═══════════════════════════════════${reset}"
echo -e "\033[1;37mSwapRAM By TAKUMIWASHERE\033[0m"
echo -e "\033[1;37mTelegram : https://t.me/TAKUMIWASHERE \033[0m"
echo -e ""

# **Current Swap Info (ATAS NOMBOR 1)**
showswap

echo -e " [\033[1;36m•1\033[0m]  Add 512MB RAM"
echo -e " [\033[1;36m•2\033[0m]  Add 768MB RAM"
echo -e " [\033[1;36m•3\033[0m]  Add 1GB RAM"
echo -e " [\033[1;36m•4\033[0m]  Add 2GB RAM"
echo -e " [\033[1;36m•5\033[0m]  Add 4GB RAM"
echo -e " [\033[1;36m•6\033[0m]  Disable Swap RAM"
echo -e ""
echo -e " [\033[1;36m•0\033[0m]  Back to menu"
echo ""
echo -e "\033[1;37mPress [ Ctrl+C ] • To-Exit-Script\033[0m"
echo ""
read -p "Select From Options [ 1 - 6 ] :  " swap1
echo -e ""

case $swap1 in
1)
clear
echo -e "[ ${G}INFO${NC} ] Disabling old swap..."
swapoff --all
rm -f /swapfile
echo -e "[ ${G}INFO${NC} ] Creating new 512MB swap..."
dd if=/dev/zero of=/swapfile bs=1024 count=524288
mkswap /swapfile
chmod 600 /swapfile
swapon /swapfile
sed -i '/\/swapfile/d' /etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
sleep 2
swapram
;;

2)
clear
echo -e "[ ${G}INFO${NC} ] Disabling old swap..."
swapoff --all
rm -f /swapfile
echo -e "[ ${G}INFO${NC} ] Creating new 768MB swap..."
dd if=/dev/zero of=/swapfile bs=1024 count=786432
mkswap /swapfile
chmod 600 /swapfile
swapon /swapfile
sed -i '/\/swapfile/d' /etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
sleep 2
swapram
;;

3)
clear
echo -e "[ ${G}INFO${NC} ] Disabling old swap..."
swapoff --all
rm -f /swapfile
echo -e "[ ${G}INFO${NC} ] Creating new 1GB swap..."
dd if=/dev/zero of=/swapfile bs=1024 count=1048576
mkswap /swapfile
chmod 600 /swapfile
swapon /swapfile
sed -i '/\/swapfile/d' /etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
sleep 2
swapram
;;

4)
clear
echo -e "[ ${G}INFO${NC} ] Disabling old swap..."
swapoff --all
rm -f /swapfile
echo -e "[ ${G}INFO${NC} ] Creating new 2GB swap..."
dd if=/dev/zero of=/swapfile bs=1024 count=2097152
mkswap /swapfile
chmod 600 /swapfile
swapon /swapfile
sed -i '/\/swapfile/d' /etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
sleep 2
swapram
;;

5)
clear
echo -e "[ ${G}INFO${NC} ] Disabling old swap..."
swapoff --all
rm -f /swapfile
echo -e "[ ${G}INFO${NC} ] Creating new 4GB swap..."
dd if=/dev/zero of=/swapfile bs=1024 count=4194304
mkswap /swapfile
chmod 600 /swapfile
swapon /swapfile
sed -i '/\/swapfile/d' /etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
sleep 2
swapram
;;

6)
clear
echo -e "[ ${G}INFO${NC} ] Disabling Swap..."
swapoff --all
rm -f /swapfile
sed -i '/\/swapfile/d' /etc/fstab
echo -e "[ ${G}INFO${NC} ] Swap Disabled!"
sleep 2
exec swapram
;;

0)
clear
exec menu
;;

x)
clear
exec menu
;;

*)
clear
echo -e "[ ${R}ERROR${NC} ] Invalid Option!"
sleep 2
swapram
;;
esac
}

swapram
