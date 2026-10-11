#!/bin/bash
# --- root guard: re-exec as root (system files need root) ---
if [ "${EUID}" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then exec sudo -H "$0" "$@"; fi
  echo "RUN AS ROOT: sudo $0"; exit 1
fi

GitUser="dantemugetsu"
#IZIN SCRIPT
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
echo -e "\e[32mLOADING...\e[0m"

clear
# LINE COLOUR
line=$(cat /etc/line)
# TEXT COLOUR BELOW
below=$(cat /etc/below)
# BACKGROUND TEXT COLOUR
back_text=$(cat /etc/back)
# NUMBER COLOUR
number=$(cat /etc/number)
# TEXT ON BOX COLOUR
box=$(cat /etc/box)
clear
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
MYIP=$(wget -qO- ifconfig.me/ip);
clear
echo -e ""
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "   \e[$back_text             \e[30m═[\e[$box SYSTEM MENU\e[30m ]═          \e[m"
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "   \e[$number [ 1 ]\e[m \e[$below ADD NEW SUBDOMAIN\e[m"
echo -e "   \e[$number [ 2 ]\e[m \e[$below RENEW CERT XRAY CORE\e[m"
echo -e "   \e[$number [ 3 ]\e[m \e[$below DNS CHANGER\e[m"
echo -e "   \e[$number [ 4 ]\e[m \e[$below NETFLIX CHECKER\e[m"
echo -e "   \e[$number [ 5 ]\e[m \e[$below PANEL DOMAIN\e[m"
echo -e "   \e[$number [ 6 ]\e[m \e[$below BACKUP VPS\e[m"
echo -e "   \e[$number [ 7 ]\e[m \e[$below RESTORE VPS\e[m"
echo -e "   \e[$number [ 8 ]\e[m \e[$below INSTALL WEBMIN\e[m"
echo -e "   \e[$number [ 9 ]\e[m \e[$below SETUP SPEED VPS\e[m"
echo -e "   \e[$number [ 10 ]\e[m \e[$below RESTART VPN\e[m"
echo -e "   \e[$number [ 11 ]\e[m \e[$below SPEEDTEST VPS\e[m"
echo -e "   \e[$number [ 12 ]\e[m \e[$below XRAY VERSION\e[m"
echo -e "   \e[$number [ 13 ]\e[m \e[$below BBR MANAGER\e[m"
echo -e "   \e[$number [ 14 ]\e[m \e[$below ON/OF AUTO REBOOT\e[m"
echo -e "   \e[$number [ 15 ]\e[m \e[$below CHANGE PASSWORD VPS\e[m"
echo -e "   \e[$number [ 16 ]\e[m \e[$below CHECK CPU & RAM\e[m"
echo -e "   \e[$number [ 17 ]\e[m \e[$below CHANGE BANNER SSH\e[m"
echo -e "   \e[$number [ 18 ]\e[m \e[$below SWAPRAM MENU \e[m"
echo -e "   \e[$number [ 19 ]\e[m \e[$below IPV4/V6 MENU \e[m"
echo -e ""
echo -e "   \e[$number [ 20 ]\e[m \e[$below WARP INSTALLER MENU\e[m"
echo -e "   \e[$number [ 21 ]\e[m \e[$below INSTALL NOOBZVPNS\e[m"
echo -e "   \e[$number [ 22 ]\e[m \e[$below UNINSTALL NOOBZVPNS\e[m"
echo -e "   \e[$number [ 23 ]\e[m \e[$below INSTALL UDP CUSTOM\e[m"
echo -e "   \e[$number [ 24 ]\e[m \e[$below XRAY-CORE CHANGER\e[m"
echo -e "   \e[$number [ 25 ]\e[m \e[$below CHANGE DROPBEAR VERSION\e[m"
echo -e "   \e[$number [ 26 ]\e[m \e[$below ALLOW-LIST MANAGER (RESELLER)\e[m"
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "   \e[$number [ x ]\e[m \e[$below BACK TO MENU\e[m"
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "\e[$line"
if ! read -p "   SELECT MENU [1-26 OR X] :  "  sys; then echo; exit 0; fi
echo -e ""
case $sys in
1)
add-host
;;
2)
renew-cert
;;
3)
dns
;;
4)
netf
;;
5)
panel-domain
;;
6)
backup
;;
7)
restore
;;
8)
webmin
;;
9)
limit-speed
;;
10)
restart
;;
11)
speedtest
;;
12)
xray version
;;
13)
bbr-manager
;;
14)
autoreboot
;;
15)
passwd
;;
16)
htop
;;
17)
message-ssh
;;
18)
wget -q -O /usr/bin/swapram "https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/_deps/tools/swapram/swapram.sh" && chmod +x /usr/bin/swapram && swapram
;;
19)
ipv6-menu
;;
20|44)
wget -q -O /usr/sbin/setup2 "https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/_deps/tools/cfwarp/setup.sh" && chmod +x /usr/sbin/setup2 && setup2
;;
21|55)
rm -rf /root/noobzvpns /root/noobzvpns.tar.gz; wget -q -O /root/noobzvpns.tar.gz "https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/_deps/tools/noobzvpns.tar.gz" && mkdir -p /root/noobzvpns && tar xzf /root/noobzvpns.tar.gz -C /root/noobzvpns && cd /root/noobzvpns && chmod +x install.sh && ./install.sh
;;
22|66)
cd noobzvpns && chmod +x uninstall.sh && ./uninstall.sh
;;
23|77)
wget -O udp.sh "https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/_deps/tools/addon/udp-custom/udp.sh" && bash udp.sh
;;
24|88)
wget -q -O /usr/bin/xcorechanger "https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/_deps/tools/XrayCoreChanger/xcorechanger.sh" && chmod +x /usr/bin/xcorechanger && xcorechanger
;;
25|99)
change-dropbear
;;
26)
add-ip
;;
x)
menu
;;
*)
echo "Invalid selection. Please try again."
sleep 1
system
;;
esac
