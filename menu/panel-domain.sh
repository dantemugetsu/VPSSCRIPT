#!/bin/bash
# --- root guard: re-exec as root (system files need root) ---
if [ "${EUID}" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then exec sudo -H "$0" "$@"; fi
  echo "Run as root: sudo $0"; exit 1
fi

GitUser="dantemugetsu"
#IZIN SCRIPT
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
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
echo -e "   \e[$back_text            \e[30m═[\e[$box PANEL DOMAIN\e[30m ]═          \e[m"
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "   \e[$number [ 1 ]\e[m \e[$below Add ID Cloudflare\e[m"
echo -e "   \e[$number [ 2 ]\e[m \e[$below Add Subdomain\e[m"
echo -e "   \e[$number [ 3 ]\e[m \e[$below Pointing IP\e[m"
echo -e ""
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "   \e[$back_text \e[$box x) SYSTEM MENU                        \e[m"
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "\e[$line"
read -p "   SELECT MENU :  "  sys
echo -e ""
case $sys in
1)
cf-account
;;
2)
cf-domain
;;
3)
cf-pointing
;;
x)
system
;;
*)
echo "Please enter an correct number"
sleep 1
panel-domain
;;
esac
