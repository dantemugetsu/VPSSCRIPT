#!/bin/bash
# --- non-interactive apt: needrestart would otherwise prompt on every apt call ---
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
if [ -d /etc/needrestart ]; then
  mkdir -p /etc/needrestart/conf.d
  printf '%s\n' "\$nrconf{restart} = 'l';" "\$nrconf{kernelhints} = 0;" \
    > /etc/needrestart/conf.d/99-vpsscript.conf
fi
# dpkg must never stop on a conffile prompt (e.g. /etc/crontab vs cron-daemon-common)
mkdir -p /etc/apt/apt.conf.d
cat > /etc/apt/apt.conf.d/99-vpsscript-noninteractive <<'APTCONF'
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
};
APT::Get::Assume-Yes "true";
APTCONF
GitUser="dantemugetsu"

# ================== COLOR ==================
Lred='\e[1;91m'
Lgreen='\e[92m'
Lyellow='\e[93m'
green='\e[32m'
RED='\033[0;31m'
NC='\033[0m'
BGBLUE='\e[1;44m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\e[97m'
BOLD='\e[1m'
RESET='\e[0m'

# ================== LICENSE / RESELLER CONFIG ==================
# Owner PUBLIC key (Ed25519, DER base64). Safe to publish: verify-only.
# The matching PRIVATE key lives only on the reseller box (/etc/adminip/owner.key).
OWNER_PUBKEY="MCowBQYDK2VwAyEA6P9rNBtkk10GwqaSW1Kkne910X9l1G318JChKt32wX4="

GITHUB_OWNER="${GitUser}"
GITHUB_REPO="VPSSCRIPT"
REGISTRY_FILE="_deps/allow/registry.txt"
REGISTRY_SIG="_deps/allow/registry.sig"
OWNER_KEY="/etc/adminip/owner.key"
LICENSE_CACHE="/etc/vpscript-license"

AUTHORIZED=0
IP_MODE="ipv4"   # default
# ===============================================================

# ================== LICENSE FUNCTIONS ==================

get_public_ip() {
  curl -s4 --max-time 6 https://api.ipify.org 2>/dev/null || \
  curl -s4 --max-time 6 https://ipv4.icanhazip.com 2>/dev/null || \
  curl -s4 --max-time 6 https://ifconfig.me 2>/dev/null || echo ""
}

b64url_decode() {
  local s="${1//-/+}"; s="${s//_//}"
  local pad=$(( (4 - ${#s} % 4) % 4 ))
  case "$pad" in 1) s="${s}=" ;; 2) s="${s}==" ;; 3) s="${s}===" ;; esac
  printf '%s' "$s" | base64 -d 2>/dev/null
}

ip_hash() { printf '%s' "$1" | sha256sum | awk '{print $1}'; }

verify_sig() {
  local msg="$1" sig="$2" tmp
  tmp="$(mktemp -d)"
  printf '%s' "$OWNER_PUBKEY" | base64 -d > "$tmp/pub.der" 2>/dev/null
  if [ -s "$tmp/pub.der" ] && \
     openssl pkeyutl -verify -pubin -inkey "$tmp/pub.der" -keyform DER \
       -rawin -in "$msg" -sigfile "$sig" >/dev/null 2>&1; then
    rm -rf "$tmp"; return 0
  fi
  rm -rf "$tmp"; return 1
}

expiry_ok() {
  local v="$1" e
  [ "$v" = "LIFETIME" ] && return 0
  e="$(date -d "$v" +%s 2>/dev/null)" || \
    e="$(date -d "$(awk -F/ '{print $3"-"$2"-"$1}' <<< "$v")" +%s 2>/dev/null)"
  [ -n "$e" ] || return 1
  [ "$(date +%s)" -le "$e" ]
}

verify_token() {
  local token="$1"
  case "$token" in *.*) ;; *) return 1 ;; esac
  local p="${token%%.*}" s="${token#*.}"
  [ -n "$p" ] && [ -n "$s" ] || return 1
  local tmp; tmp="$(mktemp -d)"
  b64url_decode "$p" > "$tmp/msg" || { rm -rf "$tmp"; return 1; }
  b64url_decode "$s" > "$tmp/sig" || { rm -rf "$tmp"; return 1; }
  [ -s "$tmp/msg" ] && [ -s "$tmp/sig" ] || { rm -rf "$tmp"; return 1; }
  if verify_sig "$tmp/msg" "$tmp/sig"; then
    cat "$tmp/msg"; rm -rf "$tmp"; return 0
  fi
  rm -rf "$tmp"; return 1
}

is_owner_box() {
  [ -f "$OWNER_KEY" ] || return 1
  command -v openssl >/dev/null 2>&1 || return 1
  local d
  d="$(openssl pkey -in "$OWNER_KEY" -pubout -outform DER 2>/dev/null | base64 -w0)"
  [ -n "$d" ] && [ "$d" = "$OWNER_PUBKEY" ]
}

check_registry() {
  local TS; TS="$(date +%s)"
  local RURL="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/main/${REGISTRY_FILE}?t=${TS}"
  local SURL="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/main/${REGISTRY_SIG}?t=${TS}"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL --connect-timeout 8 "$RURL" -o "$tmp/reg" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  curl -fsSL --connect-timeout 8 "$SURL" -o "$tmp/sig" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  [ -s "$tmp/reg" ] && [ -s "$tmp/sig" ] || { rm -rf "$tmp"; return 1; }
  if ! verify_sig "$tmp/reg" "$tmp/sig"; then
    echo -e "${Lred}Registry signature INVALID - refusing it.${RESET}"
    rm -rf "$tmp"; return 1
  fi
  local MYIP MYH
  MYIP="$(get_public_ip)"
  [ -n "$MYIP" ] || { rm -rf "$tmp"; return 1; }
  MYH="$(ip_hash "$MYIP")"
  local name oid validity iph
  while IFS='|' read -r name oid validity iph; do
    [ -z "$name" ] && continue
    case "$name" in \#*) continue ;; esac
    [ "$iph" = "$MYH" ] || continue
    echo
    echo -e "${Lgreen}Name    : ${BOLD}$name${RESET}"
    echo -e "${Lgreen}Order   : ${BOLD}$oid${RESET}"
    echo -e "${Lgreen}Expired : ${BOLD}$validity${RESET}"
    if expiry_ok "$validity"; then
      echo -e "${Lgreen}Status  : ACTIVE${RESET}"; rm -rf "$tmp"; return 0
    else
      echo -e "${Lred}Status  : EXPIRED${RESET}"; rm -rf "$tmp"; return 1
    fi
  done < "$tmp/reg"
  rm -rf "$tmp"; return 1
}

check_authorized() {
  echo
  echo -e "${Lyellow}Checking license...${RESET}"
  if is_owner_box; then
    echo -e "${Lgreen}OWNER BOX - authorized.${RESET}"
    printf '%s|%s|%s\n' "OWNER" "LOCAL" "LIFETIME" > /etc/vpscript-license-info 2>/dev/null
    AUTHORIZED=1; return 0
  fi
  local TOKEN=""
  if [ -n "${VPSSCRIPT_LICENSE:-}" ]; then
    TOKEN="$VPSSCRIPT_LICENSE"
  elif [ -f "$LICENSE_CACHE" ]; then
    TOKEN="$(head -n1 "$LICENSE_CACHE" | tr -d '
 ')"
  elif [ -t 0 ]; then
    echo
    echo -e "${Lyellow}Enter your LICENSE KEY (ENTER to skip):${RESET}"
    read -r TOKEN
  fi
  if [ -n "$TOKEN" ]; then
    local PAYLOAD
    if PAYLOAD="$(verify_token "$TOKEN")"; then
      local tname toid tval tiph
      IFS='|' read -r tname toid tval tiph <<< "$PAYLOAD"
      local MYH; MYH="$(ip_hash "$(get_public_ip)")"
      if [ "$tiph" != "$MYH" ]; then
        echo -e "${Lred}This license is for a different VPS IP.${RESET}"
      elif ! expiry_ok "$tval"; then
        echo -e "${Lred}License EXPIRED ($tval).${RESET}"
      else
        echo -e "${Lgreen}License OK - ${BOLD}$tname${RESET} (${tval})"
        printf '%s|%s|%s\n' "$tname" "$toid" "$tval" > /etc/vpscript-license-info
        chmod 600 /etc/vpscript-license-info 2>/dev/null
        printf '%s
' "$TOKEN" > "$LICENSE_CACHE"
        chmod 600 "$LICENSE_CACHE" 2>/dev/null
        AUTHORIZED=1; return 0
      fi
    else
      echo -e "${Lred}License key is invalid.${RESET}"
    fi
  fi
  if check_registry; then
    printf '%s|%s|%s\n' "REGISTRY" "-" "ACTIVE" > /etc/vpscript-license-info 2>/dev/null
    AUTHORIZED=1; return 0
  fi
  return 1
}
# ======================================================

ask_ip_mode() {
  echo
  echo -ne "${Lyellow}Enable IPv4 + IPv6? [ default: no (IPv4 only) ] [y/N]: ${RESET}"
  read ans
  ans="$(echo "$ans" | tr '[:upper:]' '[:lower:]')"

  if [ "$ans" = "y" ] || [ "$ans" = "yes" ]; then
    IP_MODE="dual"
    echo -e "${Lgreen}Dipilih: IPv4 + IPv6.${RESET}"
  else
    IP_MODE="ipv4"
    echo -e "${Lgreen}Dipilih: IPv4 only (default).${RESET}"
  fi
}

set_ip_mode() {
  if [ "$1" = "dual" ]; then
    echo -e "${BLUE}Setting mode: IPv4 + IPv6 (enable IPv6)...${RESET}"
    sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1 || true
    sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null 2>&1 || true
  else
    echo -e "${BLUE}Setting mode: IPv4 only (disable IPv6)...${RESET}"
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1 || true
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1 || true
  fi
}

# ======= PLACEHOLDER: letak flow installer kau di sini =======
run_install() {
  echo
  echo -e "${Lyellow}${BOLD}AUTH OK. IP MODE: ${IP_MODE}${RESET}"
  echo -e "${Lyellow}Sila sambung bahagian installer anda dalam fungsi run_install().${RESET}"
  echo
}
# =============================================================

# =================== UI BANNER (Optional) ===================
clear
echo "                                                              "
echo "████████╗ █████╗ ██╗  ██╗██╗   ██╗███╗   ███╗██╗ ██╗██████╗ ██████╗ ███████╗███████╗";
echo "╚══██╔══╝██╔══██╗██║ ██╔╝██║   ██║████╗ ████║██║███║╚════██╗╚════██╗╚════██║╚══███╔╝";
echo "   ██║   ███████║█████╔╝ ██║   ██║██╔████╔██║██║╚██║ █████╔╝ █████╔╝    ██╔╝  ███╔╝";
echo "   ██║   ██╔══██║██╔═██╗ ██║   ██║██║╚██╔╝██║██║ ██║ ╚═══██╗ ╚═══██╗   ██╔╝  ███╔╝";
echo "   ██║   ██║  ██║██║  ██╗╚██████╔╝██║ ╚═╝ ██║██║ ██║██████╔╝██████╔╝   ██║  ███████╗";
echo "   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝ ╚═╝╚═════╝ ╚═════╝    ╚═╝  ╚══════╝";
echo "                                                              "
echo -e "${Lyellow}⚡TAKUMI1337Z SCRIPT V3.0 (MULTIPORT + LATEST XRAYCORE + SUPPORT MULTIPATH ) ⚡${RESET}"
echo -e "${Lyellow}           ⚡DEFAULT XRAYCORE MOD V25.3.15 + NEW SERVICES ⚡${RESET}"
echo -e "${green}.............................................................................${RESET}"
echo
sleep 1

# =================== BASIC CHECKS ===================
if [ "${EUID}" -ne 0 ]; then
  echo "You need to run this script as root"
  exit 1
fi
if [ "$(systemd-detect-virt)" == "openvz" ]; then
  echo "OpenVZ is not supported"
  exit 1
fi

# =================== AUTH GATE ===================
if ! check_authorized; then
  echo
  echo -e "${Lred}NOT AUTHORIZED - INSTALL ABORTED.${RESET}"
  echo -e "${Lyellow}Ask your reseller for a license key for THIS VPS IP.${RESET}"
  exit 1
fi
ask_ip_mode
set_ip_mode "$IP_MODE"

clear
mkdir /var/lib/premium-script;
default_email=$( curl https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/_deps/email/default.conf )
clear
#Nama penyedia script
echo -e "\e[1;32m════════════════════════════════════════════════════════════\e[0m"
echo ""
echo -e "   \e[1;32mPlease enter the name of Provider for Script."
read -p "   Name : " nm
echo $nm > /root/provided
echo ""
#Email domain
echo -e "\e[1;32m════════════════════════════════════════════════════════════\e[0m"
echo -e ""
echo -e "   \e[1;32mPlease enter your email Domain/Cloudflare."
echo -e "   \e[1;31m(Press ENTER for default email)\e[0m"
read -p "   Email : " email
default=${default_email}
new_email=$email
if [[ $email == "" ]]; then
sts=$default_email
else
sts=$new_email
fi
# email
mkdir -p /usr/local/etc/xray/
touch /usr/local/etc/xray/email
echo $sts > /usr/local/etc/xray/email
echo ""
echo -e "\e[1;32m════════════════════════════════════════════════════════════\e[0m"
echo ""
echo -e "   .----------------------------------."
echo -e "   |\e[1;32mPlease select a domain type below \e[0m|"
echo -e "   '----------------------------------'"
echo -e "     \e[1;32m1)\e[0m Enter your Subdomain"
echo -e "     \e[1;32m2)\e[0m Use a random Subdomain"
echo -e "   ------------------------------------"
read -p "   Please select numbers 1-2 or Any Button(Random) : " host
echo ""
if [[ $host == "1" ]]; then
echo -e "   \e[1;32mPlease enter your subdomain "
read -p "   Subdomain: " host1
echo "IP=" >> /var/lib/premium-script/ipvps.conf
echo $host1 > /root/domain
echo ""
elif [[ "$host" == *.* ]]; then
# user typed an actual domain at this prompt -> use it directly
echo -e "   \e[1;32mUsing your domain: $host"
mkdir -p /var/lib/premium-script
echo "IP=" >> /var/lib/premium-script/ipvps.conf
echo "$host" > /root/domain
echo ""
elif [[ $host == "2" ]]; then
#install cf
wget -O cf.sh https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/install/cloudflare.sh && chmod +x cf.sh && ./cf.sh
rm -f /root/cf.sh
clear
else
echo -e "Random Subdomain/Domain is used"
wget -O cf.sh https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/install/cloudflare.sh && chmod +x cf.sh && ./cf.sh
rm -f /root/cf.sh
clear
fi
echo ""
clear
echo -e "\e[0;32mREADY FOR INSTALLATION SCRIPT...\e[0m"
sleep 2
#install ssh ovpn
echo -e "\e[0;32mINSTALLING SSH & OVPN...\e[0m"
sleep 1
wget -O ssh-vpn2.sh https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/install/ssh-ovpn-v3.sh && chmod +x ssh-vpn2.sh && if [ -t 0 ]; then screen -S ssh-vpn ./ssh-vpn2.sh; else echo "[no tty] running ./ssh-vpn2.sh directly"; ./ssh-vpn2.sh; fi
echo -e "\e[0;32mDONE INSTALLING SSH & OVPN\e[0m"
clear
#install Xray
echo -e "\e[0;32mINSTALLING XRAY CORE...\e[0m"
sleep 1
wget -O ins-xray2.sh https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/install/xray-v3.sh && chmod +x ins-xray2.sh && if [ -t 0 ]; then screen -S ins-xray ./ins-xray2.sh; else echo "[no tty] running ./ins-xray2.sh directly"; ./ins-xray2.sh; fi
echo -e "\e[0;32mDONE INSTALLING XRAY CORE\e[0m"
clear
#install ohp-server
echo -e "\e[0;32mINSTALLING OHP PORT...\e[0m"
sleep 1
wget https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/install/ohp.sh && chmod +x ohp.sh && ./ohp.sh
wget https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/install/ohp-dropbear.sh && chmod +x ohp-dropbear.sh && ./ohp-dropbear.sh
wget https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/install/ohp-ssh.sh && chmod +x ohp-ssh.sh && ./ohp-ssh.sh
echo -e "\e[0;32mDONE INSTALLING OHP PORT\e[0m"
clear
#install websocket
echo -e "\e[0;32mINSTALLING WEBSOCKET PORT...\e[0m"
wget -O websocket2.sh https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/websocket/websocket-v3.sh && chmod +x websocket2.sh && if [ -t 0 ]; then screen -S websocket.sh ./websocket2.sh; else echo "[no tty] running ./websocket2.sh directly"; ./websocket2.sh; fi
echo -e "\e[0;32mDONE INSTALLING WEBSOCKET PORT\e[0m"
clear
#install SET-BR
echo -e "\e[0;32mINSTALLING SET-BR...\e[0m"
sleep 1
wget -O set-br.sh https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/install/base-config.sh && chmod +x set-br.sh && ./set-br.sh
echo -e "\e[0;32mDONE INSTALLING SET-BR...\e[0m"
clear
# set time GMT +8
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
# install clouflare JQ
apt install jq curl -y
# install webserver
apt -y install nginx
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
#wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/nginx.conf"
mkdir -p /home/vps/public_html
#wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/vps.conf"
systemctl restart nginx
#finish
rm -f /root/ssh-vpn.sh
rm -f /root/ins-xray.sh
rm -f /root/ohp.sh
rm -f /root/ohp-dropbear.sh
rm -f /root/ohp-ssh.sh
rm -f /root/websocket.sh
rm -f /root/set-br.sh
# Colour Default
echo "1;34m" > /etc/banner
echo "30m" > /etc/box
echo "1;34m" > /etc/line
echo "1;37m" > /etc/text
echo "1;37m" > /etc/below
echo "47m" > /etc/back
echo "1;35m" > /etc/number
echo Standard > /etc/vps-theme
# Version
ver=$( curl https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/_deps/version/version.conf )
history -c
echo "$ver" > /home/ver
clear
echo " "
echo "Installation has been completed!!"
echo " "
echo -e "\e[1;32m══════════════════ Autoscript TAKUMI1337Z ══════════════════\e[0m" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "   >>> Service & Port"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "    [INFORMASI SSH & OpenVPN]" | tee -a log-install.txt
echo "    -------------------------" | tee -a log-install.txt
echo "   - OpenSSH                   : 22"  | tee -a log-install.txt
echo "   - OpenVPN                   : TCP 1194, UDP 2200"  | tee -a log-install.txt
echo "   - OpenVPN SSL               : 110"  | tee -a log-install.txt
echo "   - Stunnel4                  : 222, 777"  | tee -a log-install.txt
echo "   - Dropbear                  : 143, 109"  | tee -a log-install.txt
echo "   - Udp Custom                : 1-65535"  | tee -a log-install.txt
echo "   - OHP Dropbear              : 8585"  | tee -a log-install.txt
echo "   - OHP SSH                   : 8686"  | tee -a log-install.txt
echo "   - OHP OpenVPN               : 8787"  | tee -a log-install.txt
echo "   - Websocket SSH(HTTP)       : 8880"  | tee -a log-install.txt
echo "   - Websocket SSL(HTTPS)      : 443, 2096"  | tee -a log-install.txt
echo "   - Websocket OpenVPN         : 2097"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "    [INFORMASI Sqd, Bdvp, Ngnx]" | tee -a log-install.txt
echo "    ---------------------------" | tee -a log-install.txt
echo "   - Squid Proxy               : 3128, 8000 (limit to IP Server)"  | tee -a log-install.txt
echo "   - Badvpn                    : 7100, 7200, 7300"  | tee -a log-install.txt
echo "   - Nginx                     : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "    [INFORMASI XRAY]"  | tee -a log-install.txt
echo "    ----------------" | tee -a log-install.txt
echo "   - Xray Vmess Ws Tls         : 443"  | tee -a log-install.txt
echo "   - Xray Vless Ws Tls         : 443"  | tee -a log-install.txt
echo "   - Xray HttpUpgrade Tls      : 443"  | tee -a log-install.txt
echo "   - Xray Trojan Ws Tls        : 443"  | tee -a log-install.txt
echo "   - Xray Vless Xtls Vision    : 443"  | tee -a log-install.txt
echo "   - Xray Trojan Tcp Tls       : 443"  | tee -a log-install.txt
echo "   - Xray Vless Xhttp Tls      : 8443" | tee -a log-install.txt
echo "   - Xray Vmess Ws None Tls    : 80"   | tee -a log-install.txt
echo "   - Xray Vless Ws None Tls    : 80"   | tee -a log-install.txt
echo "   - Xray HttpUpgrade None Tls : 80"   | tee -a log-install.txt
echo "   - Xray Trojan Ws None Tls   : 80"   | tee -a log-install.txt
echo "   - Xray Vless Xhttp None Tls : 8080" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "    [INFORMASI NOOBZVPN ]"  | tee -a log-install.txt
echo "    ---------------------" | tee -a log-install.txt
echo "   - Noobzvpn Tls              : 2087"  | tee -a log-install.txt
echo "   - Noobzvpn None Tls         : 2086"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "    [INFORMASI CLASH FOR ANDROID (YAML)]"  | tee -a log-install.txt
echo "    -----------------------------------" | tee -a log-install.txt
echo "   - Xray Vmess Ws Yaml        : Yes"  | tee -a log-install.txt
echo "   - Xray Vless Ws Yaml        : Yes"  | tee -a log-install.txt
echo "   - Xray Trojan Ws Yaml       : Yes"  | tee -a log-install.txt
echo "   --------------------------------------------------------------" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "   >>> Server Information & Other Features"  | tee -a log-install.txt
echo "   - Timezone                  : Asia/Kuala_Lumpur (GMT +8)"  | tee -a log-install.txt
echo "   - Fail2Ban                  : [ON]"  | tee -a log-install.txt
echo "   - Dflate                    : [ON]"  | tee -a log-install.txt
echo "   - IPtables                  : [ON]"  | tee -a log-install.txt
echo "   - Auto-Reboot               : [ON]"  | tee -a log-install.txt
echo "   - IPv6                      : [OFF]"  | tee -a log-install.txt
echo "   - Autoreboot On 05.00 GMT +8" | tee -a log-install.txt
echo "   - Autobackup Data" | tee -a log-install.txt
echo "   - Restore Data" | tee -a log-install.txt
echo "   - Auto Delete Expired Account" | tee -a log-install.txt
echo "   - Full Orders For Various Services" | tee -a log-install.txt
echo "   - White Label" | tee -a log-install.txt
echo "   - Installation Log --> /root/log-install.txt"  | tee -a log-install.txt
echo -e "\e[1;32m══════════════════ Autoscript By TAKUMIWASHERE ══════════════════\e[0m" | tee -a log-install.txt
sleep 7
clear
echo ""
echo -e "    \e[1;32m.------------------------------------------.\e[0m"
echo -e "    \e[1;32m|     SUCCESFULLY INSTALLED THE SCRIPT     |\e[0m"
echo -e "    \e[1;32m|         TAKUMI1337Z BY TAKUMIWASHERE            |\e[0m"
echo -e "    \e[1;32m'------------------------------------------'\e[0m"
echo ""
echo -e "   \e[1;32mYour VPS Will Be Automatical Reboot In 5 seconds\e[0m"
rm -f /root/setup-v3.sh
sleep 5
[ -n "$SKIP_REBOOT" ] && { echo "[SKIP_REBOOT set] not rebooting"; exit 0; } || reboot
