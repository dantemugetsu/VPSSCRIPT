#!/bin/bash
# ============================================================================
#  add-ip - RESELLER LICENSE MANAGER (Ed25519, no master key)
#
#  Every customer VPS gets a UNIQUE license key, cryptographically bound to
#  that VPS's IP. The key is an Ed25519-signed token:
#
#      <b64url(Name|OrderID|Validity|sha256(IPVPS))> . <b64url(signature)>
#
#  Properties:
#    - unique per IP (the IP hash is inside the signed payload)
#    - cannot be forged without the owner private key
#    - cannot be moved to another VPS (the IP hash won't match)
#    - cannot be edited (signature covers the whole payload)
#    - works fully OFFLINE - no GitHub needed at install time
#
#  A signed REGISTRY (registry.txt + registry.sig) is also published for
#  customers who would rather not paste a key.
#
#  The owner PRIVATE key lives only here: /etc/adminip/owner.key (mode 600).
#  There is deliberately NO master key.
# ============================================================================
GitUser="dantemugetsu"
GITHUB_REPO="VPSSCRIPT"
REGISTRY_PATH="_deps/allow/registry.txt"
REGISTRY_SIG_PATH="_deps/allow/registry.sig"
TOKEN_FILE="/etc/adminip/access.conf"     # GitHub PAT (for publishing only)
OWNER_KEY="/etc/adminip/owner.key"

if [ "${EUID}" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then exec sudo -H "$0" "$@"; fi
  echo "RUN AS ROOT: sudo $0"; exit 1
fi

green='\e[32m'; red='\e[31m'; Lyellow='\e[93m'; Lgreen='\e[92m'; Lred='\e[91m'
NC='\e[0m'; BOLD='\e[1m'; RESET='\e[0m'

tokengit=""
[ -f "$TOKEN_FILE" ] && tokengit="$(head -n1 "$TOKEN_FILE" | tr -d '\r\n ')"

# ---------------------------------------------------------------- crypto
b64url() { base64 -w0 | tr '+/' '-_' | tr -d '='; }

ip_hash() { printf '%s' "$1" | sha256sum | awk '{print $1}'; }

has_owner_key() { [ -f "$OWNER_KEY" ]; }

sign_payload() {
  # sign_payload <payload>  -> prints <b64url(payload)>.<b64url(sig)>
  local payload="$1" tmp
  tmp="$(mktemp -d)"
  printf '%s' "$payload" > "$tmp/msg"
  if ! openssl pkeyutl -sign -inkey "$OWNER_KEY" -rawin \
        -in "$tmp/msg" -out "$tmp/sig" 2>/dev/null; then
    rm -rf "$tmp"; return 1
  fi
  printf '%s.%s' "$(b64url < "$tmp/msg")" "$(b64url < "$tmp/sig")"
  rm -rf "$tmp"
}

owner_pubkey_b64() {
  openssl pkey -in "$OWNER_KEY" -pubout -outform DER 2>/dev/null | base64 -w0
}

# ---------------------------------------------------------------- 05 OWNER KEY
owner_key_menu() {
  clear
  echo -e "${BOLD}=== OWNER KEY ===${RESET}"
  echo
  if has_owner_key; then
    echo -e "${Lgreen}A key already exists.${RESET}"
    echo
    echo "  Public key (this is what is embedded in setup-*.sh):"
    echo
    echo -e "  ${BOLD}$(owner_pubkey_b64)${RESET}"
    echo
    echo "  Private key : ${OWNER_KEY}  ($(stat -c '%a %U' "$OWNER_KEY"))"
    echo
    read -rp "  Re-generate a NEW key? This invalidates all issued licenses! [y/N] : " r
    case "$r" in
      y|Y) ;;
      *) echo "  Keeping existing key."; sleep 2; return ;;
    esac
    mv "$OWNER_KEY" "${OWNER_KEY}.old.$(date +%s)"
    echo "  Old key backed up."
  fi
  openssl genpkey -algorithm ed25519 -out "$OWNER_KEY" 2>/dev/null || {
    echo -e "${Lred}openssl failed.${NC}"; sleep 3; return; }
  chmod 600 "$OWNER_KEY"
  echo
  echo -e "${Lgreen}New Ed25519 owner key generated.${NC}"
  echo
  echo "  PUBLIC KEY - put this in setup-v2.sh / setup-v3.sh as OWNER_PUBKEY:"
  echo
  echo -e "  ${BOLD}$(owner_pubkey_b64)${RESET}"
  echo
  echo "  (The private key stays on this box and is never shared.)"
  echo
  read -n 1 -s -r -p "Press any key to continue"; echo
}

# ---------------------------------------------------------------- registry IO
get_registry() {
  # prints registry contents; empty if absent
  local resp
  resp="$(curl -s --max-time 20 \
    -H "Authorization: token ${tokengit}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${GitUser}/${GITHUB_REPO}/contents/${REGISTRY_PATH}")"
  printf '%s' "$resp" | jq -r '.content // empty' 2>/dev/null | base64 -d 2>/dev/null
}

# ---------------------------------------------------------------- 01 ADD
add_ip() {
  if ! has_owner_key; then
    echo -e "${Lred}No owner key yet. Run [ 05 ] OWNER KEY first.${NC}"
    sleep 3; return
  fi
  clear
  echo -e "${BOLD}=== ISSUE A LICENSE ===${RESET}"
  echo
  read -rp "  - Client Name   : " client
  read -rp "  - Order ID      : " oid
  read -rp "  - Customer VPS IP : " daftar
  if [ -z "$client" ] || [ -z "$daftar" ]; then
    echo -e "${Lred}Name and IP are required.${NC}"; sleep 2; return
  fi
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

  local h; h="$(ip_hash "$daftar")"
  local payload="${client}|${oid}|${validity}|${h}"
  local token; token="$(sign_payload "$payload")" || {
    echo -e "${Lred}Signing failed.${NC}"; sleep 3; return; }

  clear
  echo -e "${Lgreen}LICENSE ISSUED${NC}"
  echo -e "\033[0;34m------------------------------------------------------------\033[0m"
  echo "  Client      : $client"
  echo "  Order ID    : $oid"
  echo "  VPS IP      : $daftar"
  echo "  Validity    : $validity"
  echo -e "\033[0;34m------------------------------------------------------------\033[0m"
  echo
  echo -e "${BOLD}LICENSE KEY (send this to the customer):${NC}"
  echo
  echo "$token"
  echo
  echo -e "\033[0;34m------------------------------------------------------------\033[0m"
  echo "  The customer installs with:"
  echo
  echo "    VPSSCRIPT_LICENSE='$token' ./installer.sh"
  echo
  echo "  ...or pastes it when the installer asks."
  echo -e "\033[0;34m------------------------------------------------------------\033[0m"
  echo
  echo "  This key ONLY works on $daftar."
  echo "  (Optional) add it to the signed registry so the customer"
  echo "  needs no key at all -> menu [ 06 ] PUBLISH REGISTRY."
  echo

  # keep a local record (one line per IP - a re-issue supersedes the old one)
  mkdir -p /etc/adminip
  if [ -f /etc/adminip/issued.log ] && [ -s /etc/adminip/issued.log ]; then
    grep -v "|${daftar}$" /etc/adminip/issued.log > /etc/adminip/issued.log.tmp 2>/dev/null || true
    mv /etc/adminip/issued.log.tmp /etc/adminip/issued.log
  fi
  printf '%s|%s|%s|%s\n' "$client" "$oid" "$validity" "$daftar" >> /etc/adminip/issued.log
  chmod 600 /etc/adminip/issued.log 2>/dev/null

  read -n 1 -s -r -p "Press any key to continue"; echo
}

# ---------------------------------------------------------------- 04 LIST
list_issued() {
  clear
  echo -e "${BOLD}=== ISSUED LICENSES (this box) ===${RESET}"
  echo
  if [ -f /etc/adminip/issued.log ] && [ -s /etc/adminip/issued.log ]; then
    echo "    No.  NAME            ORDER        VALIDITY       IPVPS"
    echo "  ------------------------------------------------------------"
    awk -F'|' '{printf "  %4d)  %-15s %-12s %-14s %s\n", NR, $1, $2, $3, $4}' /etc/adminip/issued.log
    echo
    echo "  Total: $(wc -l < /etc/adminip/issued.log)"
  else
    echo "  (none yet)"
  fi
  echo
  read -n 1 -s -r -p "Press any key to continue"; echo
}

# ---------------------------------------------------------------- 06 REGISTRY
publish_registry() {
  if ! has_owner_key; then
    echo -e "${Lred}No owner key yet. Run [ 05 ] OWNER KEY first.${NC}"; sleep 3; return
  fi
  if [ -z "$tokengit" ]; then
    echo -e "${Lred}No GitHub token set. Run [ 07 ] SET GITHUB TOKEN first.${NC}"; sleep 3; return
  fi
  if [ ! -s /etc/adminip/issued.log ]; then
    echo -e "${Lyellow}Nothing issued yet - registry would be empty.${NC}"; sleep 3; return
  fi

  clear
  echo -e "${BOLD}=== PUBLISH SIGNED REGISTRY ===${RESET}"
  echo
  # build registry.txt : Name|OrderID|Validity|iphash   (deduped, last wins)
  local tmp; tmp="$(mktemp -d)"
  : > "$tmp/registry.txt"
  while IFS='|' read -r name oid validity ip; do
    [ -z "$name" ] && continue
    printf '%s|%s|%s|%s\n' "$name" "$oid" "$validity" "$(ip_hash "$ip")" >> "$tmp/raw.txt"
  done < /etc/adminip/issued.log
  # keep only the LAST entry per ip hash (a re-issue supersedes the old one)
  if [ -s "$tmp/raw.txt" ]; then
    tac "$tmp/raw.txt" | awk -F'|' '!seen[$4]++' | tac > "$tmp/registry.txt"
  fi
  rm -f "$tmp/raw.txt"

  # sign it
  if ! openssl pkeyutl -sign -inkey "$OWNER_KEY" -rawin \
        -in "$tmp/registry.txt" -out "$tmp/registry.sig" 2>/dev/null; then
    echo -e "${Lred}Signing failed.${NC}"; rm -rf "$tmp"; sleep 3; return
  fi

  echo "  Registry entries: $(wc -l < "$tmp/registry.txt")"
  echo

  # push both files
  local ok=0
  for pair in "registry.txt:${REGISTRY_PATH}" "registry.sig:${REGISTRY_SIG_PATH}"; do
    local local_f="${pair%%:*}" remote_p="${pair#*:}"
    local sha b64 payload code
    sha="$(curl -s --max-time 20 -H "Authorization: token ${tokengit}" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/${GitUser}/${GITHUB_REPO}/contents/${remote_p}" \
      | jq -r '.sha // empty')"
    b64="$(base64 -w0 < "$tmp/$local_f")"
    if [ -n "$sha" ]; then
      payload="$(jq -n --arg m "registry update" --arg c "$b64" --arg s "$sha" \
        '{message:$m, content:$c, sha:$s}')"
    else
      payload="$(jq -n --arg m "registry update" --arg c "$b64" \
        '{message:$m, content:$c}')"
    fi
    code="$(curl -s -o /tmp/.reg_put.json -w '%{http_code}' --max-time 25 -X PUT \
      -H "Authorization: token ${tokengit}" \
      -H "Accept: application/vnd.github+json" \
      -d "$payload" \
      "https://api.github.com/repos/${GitUser}/${GITHUB_REPO}/contents/${remote_p}")"
    if [ "$code" = "200" ] || [ "$code" = "201" ]; then
      echo -e "  ${Lgreen}pushed${NC} ${remote_p}"
      ok=$((ok+1))
    else
      echo -e "  ${Lred}FAILED${NC} ${remote_p} (HTTP $code)"
      jq -r '.message // empty' /tmp/.reg_put.json 2>/dev/null | sed 's/^/    /'
    fi
  done
  rm -rf "$tmp"
  echo
  [ "$ok" -eq 2 ] && echo -e "${Lgreen}Registry published and signed.${NC}"
  echo
  read -n 1 -s -r -p "Press any key to continue"; echo
}

# ---------------------------------------------------------------- 07 TOKEN
set_github_token() {
  clear
  echo -e "${BOLD}=== SET GITHUB TOKEN ===${RESET}"
  echo
  echo "Only needed to PUBLISH the signed registry."
  echo "Paste a GitHub PAT with 'repo' scope:"
  echo
  read -rp "  TOKEN : " ans
  if [ -z "$ans" ]; then echo -e "${Lred}Empty - aborted.${NC}"; sleep 2; return; fi
  mkdir -p "$(dirname "$TOKEN_FILE")"
  printf '%s\n' "$ans" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  tokengit="$ans"
  echo -e "${Lgreen}Saved.${NC}"
  sleep 2
}

# ---------------------------------------------------------------- MENU
while true; do
  clear
  echo -e "\033[0;34m--------------------------------------------------\033[0m"
  echo -e "\E[44;1;39m     RESELLER LICENSE MANAGER (Ed25519)           \E[0m"
  echo -e "\033[0;34m--------------------------------------------------\033[0m"
  echo ""
  echo -e " [\e[36m 01 \e[0m] ISSUE LICENSE (per-VPS KEY)"
  echo -e " [\e[36m 02 \e[0m] LIST ISSUED LICENSES"
  echo -e " [\e[36m 03 \e[0m] PUBLISH SIGNED REGISTRY"
  echo ""
  echo -e " [\e[36m 05 \e[0m] OWNER KEY (generate / show)"
  echo -e " [\e[36m 07 \e[0m] SET GITHUB TOKEN"
  echo ""
  echo -e " [\e[36m x  \e[0m] BACK TO MENU"
  echo -e "\033[0;34m--------------------------------------------------\033[0m"
  echo ""
  if has_owner_key; then
    echo -e "  Owner key : ${Lgreen}present${NC}"
  else
    echo -e "  Owner key : ${Lred}MISSING${NC}  <- run [ 05 ]"
  fi
  if [ -n "$tokengit" ]; then
    echo -e "  GH token  : ${Lgreen}set${NC}"
  else
    echo -e "  GH token  : ${Lyellow}not set${NC}  (only for registry)"
  fi
  echo ""
  if ! read -rp "   SELECT MENU : " opt; then echo; exit 0; fi
  case "$opt" in
    1|01) add_ip ;;
    2|02) list_issued ;;
    3|03) publish_registry ;;
    5|05) owner_key_menu ;;
    7|07) set_github_token ;;
    x|X) exec menu 2>/dev/null || exit 0 ;;
    *) echo -e "${Lred}Invalid selection.${NC}"; sleep 1 ;;
  esac
done
