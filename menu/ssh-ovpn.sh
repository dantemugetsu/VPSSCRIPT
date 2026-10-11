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
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
MYIP=$(wget -qO- ifconfig.me/ip);

echo -e ""
echo -e "   \e[$line══════════════════════════════════════════\e[m"
echo -e "   \e[$back_text         \e[30m═[\e[$box SSH & OPENVPN MENU\e[30m ]═         \e[m"
echo -e "   \e[$line══════════════════════════════════════════\e[m"
echo -e "    \e[$number [ 1 ]\e[m \e[$below CREATE SSH & OPENVPN ACCOUNT\e[m"
echo -e "    \e[$number [ 2 ]\e[m \e[$below TRIAL ACCOUNT SSH & OPENVPN\e[m"
echo -e "    \e[$number [ 3 ]\e[m \e[$below RENEW SSH & OPENVPN ACCOUNT\e[m"
echo -e "    \e[$number [ 4 ]\e[m \e[$below DELETE SSH & OPENVPN ACCOUNT\e[m"
echo -e "    \e[$number [ 5 ]\e[m \e[$below CHECK USER LOGIN SSH & OPENVPN\e[m"
echo -e "    \e[$number [ 6 ]\e[m \e[$below LIST MEMBER SSH & OPENVPN\e[m"
echo -e "    \e[$number [ 7 ]\e[m \e[$below DELETE USER EXPIRED SSH & OPENVPN\e[m"
echo -e "    \e[$number [ 8 ]\e[m \e[$below SET UP AUTOKILL SSH\e[m"
echo -e "    \e[$number [ 9 ]\e[m \e[$below CEK USERS WHO DO MULTI LOGIN SSH\e[m"
echo -e "    \e[$number [ 10 ]\e[m \e[$below USER LIST\e[m"
echo -e "    \e[$number [ 11 ]\e[m \e[$below USER LOCK\e[m"
echo -e "    \e[$number [ 12 ]\e[m \e[$below USER UNLOCK\e[m"
echo -e "    \e[$number [ 13 ]\e[m \e[$below USER PASSWORD\e[m"
echo -e "    \e[$number [ 14 ]\e[m \e[$below RESTART SERVICE DROPBEAR, SQUID3,\e[m"
echo -e "          \e[$below OPENVPN & SSH\e[m"
echo -e ""
echo -e "   \e[$line══════════════════════════════════════════\e[m"
echo -e "   \e[$number [ x ]\e[m \e[$below BACK TO MENU\e[m"
echo -e "   \e[$line══════════════════════════════════════════\e[m"
echo -e "\e[$line"
if ! read -p "   SELECT MENU [1-14 OR X] :  "  ssh; then echo; exit 0; fi
echo -e ""
case $ssh in
1)
add-ssh
;;
2)
trial
;;
3)
renew-ssh
;;
4)
del-ssh
;;
5)
check-ssh
;;
6)
list-member
;;
7)
delete
;;
8)
autokill
;;
9)
check-limit
;;
10)
user-list
;;
11)
user-lock
;;
12)
user-unlock
;;
13)
user-password
;;
14)
restart
;;
x)
menu
;;
*)
echo "Please enter an correct number"
;;
esac
