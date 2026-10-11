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
yl='\e[031;1m'
bl='\e[36;1m'
gl='\e[32;1m'
BLUE='\e[0;34m'
clear
echo -e ""
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "   \e[$back_text         \e[30m═[\e[$box CHANGE PORT MENU\e[30m ]═         \e[m"
echo -e "   \e[$line════════════════════════════════════════\e[m"
echo -e "\e[$number   >>\e[$number SELECT AN OPTION BELOW :\e[0m"
echo -e "   \e[$number [ 1 ]\e[m \e[$below CHANGE PORT STUNNEL\e[m"
echo -e "   \e[$number [ 2 ]\e[m \e[$below CHANGE PORT OPENVPN\e[m"
echo -e "   \e[$number [ 3 ]\e[m \e[$below CHANGE PORT OHP SSH\e[m"
echo -e "   \e[$number [ 4 ]\e[m \e[$below CHANGE PORT WEBSOCKET SSH\e[m"
echo -e "   \e[$number [ 5 ]\e[m \e[$below CHANGE PORT XRAY CORE\e[m"
echo -e "   \e[$number [ 6 ]\e[m \e[$below CHANGE PORT SQUID PROXY\e[m"
echo -e ""
echo -e "   \e[$line═══════════════════════════════════════\e[m"
echo -e "   \e[$number [ x ]\e[m \e[$below BACK TO MENU\e[m"
echo -e "   \e[$line═══════════════════════════════════════\e[m"
echo -e ""
read -p "     SELECT FROM OPTIONS [1-8 OR X] :  " port
echo -e ""
case $port in
1)
port-ssl
;;
2)
port-ovpn
;;
3)
port-ohp
;;
4)
port-websocket
;;
5)
port-xray
;;
6)
port-squid
;;
x)
clear
menu
;;
*)
echo "Please enter an correct number"
;;
esac
