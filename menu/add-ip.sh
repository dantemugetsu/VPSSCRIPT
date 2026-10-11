#!/bin/bash
# ============================================================================
#  add-ip - reseller allow-list manager
#
#  Single source of truth: _deps/allow/ipvps.conf in the script repo.
#  The install gate (setup-v2/v3.sh) and `check-running` both read that file,
#  so what you register here is exactly what authorises a customer's VPS.
#
#  File format (one per line):
#      ### Name OrderID VALIDITY IPVPS
#  VALIDITY = LIFETIME or YYYY-MM-DD
#
#  Uses the GitHub Contents API, so there is no local clone/push dance and
#  only one repo is involved.
# ============================================================================
GitUser="dantemugetsu"
GITHUB_REPO="VPSSCRIPT"
ALLOW_PATH="_deps/allow/ipvps.conf"
TOKEN_FILE="/etc/adminip/access.conf"
OWNER_MARKER="/etc/vpscript-owner"
API="https://api.github.com/repos/${GitUser}/${GITHUB_REPO}/contents/${ALLOW_PATH}"

# --- root guard ---
if [ "${EUID}" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then exec sudo -H "$0" "$@"; fi
  echo "RUN AS ROOT: sudo $0"; exit 1
fi

# --- colours ---
green='\e[32m'; red='\e[31m'; Lyellow='\e[93m'; Lgreen='\e[92m'; Lred='\e[91m'
NC='\e[0m'; BOLD='\e[1m'; RESET='\e[0m'

tokengit=""
[ -f "$TOKEN_FILE" ] && tokengit="$(head -n1 "$TOKEN_FILE" | tr -d '\r\n ')"

need_token() {
  if [ -z "$tokengit" ]; then
    echo -e "[ ${red}ERROR${NC} ] No GitHub token set."
    echo -e "            Run ${BOLD}[ 05 ] SET ADMIN${RESET} first."
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------- API helpers
# get_allow -> writes the decoded file to stdout, sets globals SHA
SHA=""
get_allow() {
  local resp
  resp="$(curl -s --max-time 20 \
    -H "Authorization: token ${tokengit}" \
    -H "Accept: application/vnd.github+json" \
    "$API")"
  SHA="$(printf '%s' "$resp" | jq -r '.sha // empty')"
  if [ -z "$SHA" ]; then
    echo -e "[ ${Lred}ERROR${NC} ] Could not read ${ALLOW_PATH} from GitHub." >&2
    printf '%s' "$resp" | jq -r '.message // empty' >&2
    return 1
  fi
  printf '%s' "$resp" | jq -r '.content' | base64 -d
}

# put_allow <file> <message>
put_allow() {
  local file="$1" msg="$2" b64 payload code
  b64="$(base64 -w0 < "$file")"
  payload="$(jq -n --arg m "$msg" --arg c "$b64" --arg s "$SHA" \
              '{message:$m, content:$c, sha:$s}')"
  code="$(curl -s -o /tmp/.allow_put.json -w '%{http_code}' --max-time 25 \
    -X PUT \
    -H "Authorization: token ${tokengit}" \
    -H "Accept: application/vnd.github+json" \
    -d "$payload" "$API")"
  if [ "$code" = "200" ] || [ "$code" = "201" ]; then
    return 0
  fi
  echo -e "[ ${Lred}ERROR${NC} ] GitHub returned HTTP ${code}." >&2
  jq -r '.message // empty' /tmp/.allow_put.json >&2
  return 1
}

# ---------------------------------------------------------------- 05 SET ADMIN
setadmin() {
  clear
  echo -e "${BOLD}=== SET ADMIN (owner) ===${RESET}"
  echo
  echo "Paste a GitHub personal access token with 'repo' scope."
  echo "It is stored in ${TOKEN_FILE} (root only) and is only used to"
  echo "update ${ALLOW_PATH} in ${GitUser}/${GITHUB_REPO}."
  echo
  read -rp "  TOKEN : " ans
  if [ -z "$ans" ]; then
    echo -e "${Lred}Empty token - aborted.${NC}"; sleep 2; return
  fi
  mkdir -p "$(dirname "$TOKEN_FILE")"
  printf '%s\n' "$ans" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  tokengit="$ans"

  # owner bypass marker so the installer never locks the owner out
  touch "$OWNER_MARKER"
  chmod 600 "$OWNER_MARKER"

  echo
  echo -e "${Lgreen}Token saved.${NC}"
  echo -e "${Lgreen}Owner bypass enabled (${OWNER_MARKER}).${NC}"
  echo -e "This box can now install with no allow-list entry."
  sleep 3
}

# ---------------------------------------------------------------- 01 ADD IP
add_ip() {
  need_token || { sleep 3; return; }
  clear
  echo -e "${BOLD}=== ADD IP TO ALLOW-LIST ===${RESET}"
  echo
  read -rp "  - Client Name   : " client
  read -rp "  - Order ID      : " oid
  read -rp "  - VPS IP        : " daftar
  [ -z "$client" ] || [ -z "$daftar" ] && { echo -e "${Lred}Name and IP are required.${NC}"; sleep 2; return; }

  echo
  echo "  Validity:"
  echo "    1) LIFETIME"
  echo "    2) N days from today"
  echo "    3) Fixed date (YYYY-MM-DD)"
  read -rp "  SELECT [1-3] : " v
  case "$v" in
    1) validity="LIFETIME" ;;
    2) read -rp "  DAYS : " nd
       validity="$(date -d "+${nd} days" +%Y-%m-%d)" ;;
    3) read -rp "  DATE (YYYY-MM-DD) : " validity ;;
    *) echo -e "${Lred}Invalid.${NC}"; sleep 2; return ;;
  esac

  local tmp; tmp="$(mktemp)"
  if ! get_allow > "$tmp"; then rm -f "$tmp"; sleep 3; return; fi

  if grep -qE "^###[[:space:]]+.*[[:space:]]${daftar//./\\.}[[:space:]]*$" "$tmp"; then
    echo -e "${Lred}That IP is already registered.${NC}"
    rm -f "$tmp"; sleep 3; return
  fi

  printf '### %s %s %s %s\n' "$client" "$oid" "$validity" "$daftar" >> "$tmp"

  if put_allow "$tmp" "add: ${client} (${daftar})"; then
    echo
    echo -e "${Lgreen}Registered.${NC}"
    echo "  Client   : $client"
    echo "  Order ID : $oid"
    echo "  IP VPS   : $daftar"
    echo "  Validity : $validity"
  fi
  rm -f "$tmp"
  echo
  read -n 1 -s -r -p "Press any key to continue"; echo
}

# ---------------------------------------------------------------- 02 DELETE IP
del_ip() {
  need_token || { sleep 3; return; }
  clear
  local tmp; tmp="$(mktemp)"
  if ! get_allow > "$tmp"; then rm -f "$tmp"; sleep 3; return; fi

  if ! grep -q '^### ' "$tmp"; then
    echo -e "${Lyellow}The allow-list is empty.${NC}"; rm -f "$tmp"; sleep 3; return
  fi

  echo -e "${BOLD}=== DELETE IP ===${RESET}"
  echo
  echo "    No.   NAME            ORDER        VALIDITY      IPVPS"
  echo "  ------------------------------------------------------------"
  grep '^### ' "$tmp" | awk '{printf "  %3d)  %-15s %-12s %-13s %s\n", NR, $2, $3, $4, $5}'
  echo
  read -rp "  SELECT NUMBER : " n
  local line
  line="$(grep '^### ' "$tmp" | sed -n "${n}p")"
  if [ -z "$line" ]; then echo -e "${Lred}Invalid number.${NC}"; rm -f "$tmp"; sleep 2; return; fi

  grep -vxF "$line" "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
  if put_allow "$tmp" "delete: entry ${n}"; then
    echo -e "${Lgreen}Deleted:${NC} $line"
  fi
  rm -f "$tmp"
  echo
  read -n 1 -s -r -p "Press any key to continue"; echo
}

# ---------------------------------------------------------------- 03 RENEW IP
renew_ip() {
  need_token || { sleep 3; return; }
  clear
  local tmp; tmp="$(mktemp)"
  if ! get_allow > "$tmp"; then rm -f "$tmp"; sleep 3; return; fi

  if ! grep -q '^### ' "$tmp"; then
    echo -e "${Lyellow}The allow-list is empty.${NC}"; rm -f "$tmp"; sleep 3; return
  fi

  echo -e "${BOLD}=== RENEW IP ===${RESET}"
  echo
  grep '^### ' "$tmp" | awk '{printf "  %3d)  %-15s %-12s %-13s %s\n", NR, $2, $3, $4, $5}'
  echo
  read -rp "  SELECT NUMBER : " n
  local line
  line="$(grep '^### ' "$tmp" | sed -n "${n}p")"
  if [ -z "$line" ]; then echo -e "${Lred}Invalid number.${NC}"; rm -f "$tmp"; sleep 2; return; fi

  read -rp "  NEW VALIDITY (LIFETIME | YYYY-MM-DD | +N days) : " nv
  local newval
  case "$nv" in
    LIFETIME|lifetime) newval="LIFETIME" ;;
    +*) newval="$(date -d "+${nv#+} days" +%Y-%m-%d)" ;;
    *)  newval="$nv" ;;
  esac

  local name oid ip
  name="$(echo "$line" | awk '{print $2}')"
  oid="$(echo  "$line" | awk '{print $3}')"
  ip="$(echo   "$line" | awk '{print $5}')"

  grep -vxF "$line" "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
  printf '### %s %s %s %s\n' "$name" "$oid" "$newval" "$ip" >> "$tmp"

  if put_allow "$tmp" "renew: ${name} (${ip}) -> ${newval}"; then
    echo -e "${Lgreen}Renewed:${NC} $name  ->  $newval"
  fi
  rm -f "$tmp"
  echo
  read -n 1 -s -r -p "Press any key to continue"; echo
}

# ---------------------------------------------------------------- 04 CHECK IP
cek_ip() {
  need_token || { sleep 3; return; }
  clear
  local tmp; tmp="$(mktemp)"
  if ! get_allow > "$tmp"; then rm -f "$tmp"; sleep 3; return; fi

  echo -e "${BOLD}=== REGISTERED VPS (allow-list) ===${RESET}"
  echo
  echo "    No.   NAME            ORDER        VALIDITY      IPVPS"
  echo "  ------------------------------------------------------------"
  if grep -q '^### ' "$tmp"; then
    grep '^### ' "$tmp" | awk '{printf "  %3d)  %-15s %-12s %-13s %s\n", NR, $2, $3, $4, $5}'
  else
    echo "  (empty)"
  fi
  echo
  echo "  Total: $(grep -c '^### ' "$tmp" 2>/dev/null || echo 0)"
  echo
  echo "  This VPS IP : $(curl -s --max-time 8 https://api.ipify.org || echo unknown)"
  rm -f "$tmp"
  echo
  read -n 1 -s -r -p "Press any key to continue"; echo
}

# ---------------------------------------------------------------- MENU
while true; do
  clear
  echo -e "\033[0;34m----------------------------------------\033[0m"
  echo -e "\E[44;1;39m       ALLOW-LIST MANAGER (RESELLER)     \E[0m"
  echo -e "\033[0;34m----------------------------------------\033[0m"
  echo ""
  echo -e " [\e[36m 01 \e[0m] ADD IP"
  echo -e " [\e[36m 02 \e[0m] DELETE IP"
  echo -e " [\e[36m 03 \e[0m] RENEW IP"
  echo -e " [\e[36m 04 \e[0m] LIST REGISTERED IP"
  echo -e " [\e[36m 05 \e[0m] SET ADMIN (GITHUB TOKEN)"
  echo ""
  echo -e " [\e[36m x  \e[0m] BACK TO MENU"
  echo -e "\033[0;34m----------------------------------------\033[0m"
  echo ""
  if [ -n "$tokengit" ]; then
    echo -e "  Token : ${Lgreen}set${NC}"
  else
    echo -e "  Token : ${Lred}not set${NC}"
  fi
  if [ -f "$OWNER_MARKER" ]; then
    echo -e "  Owner : ${Lgreen}enabled${NC}"
  else
    echo -e "  Owner : ${Lyellow}not enabled${NC}"
  fi
  echo ""
  if ! read -rp "   SELECT MENU : " opt; then echo; exit 0; fi
  case "$opt" in
    1) add_ip ;;
    2) del_ip ;;
    3) renew_ip ;;
    4) cek_ip ;;
    5) setadmin ;;
    x|X) exec menu 2>/dev/null || exit 0 ;;
    *) echo -e "${Lred}Invalid selection.${NC}"; sleep 1 ;;
  esac
done
