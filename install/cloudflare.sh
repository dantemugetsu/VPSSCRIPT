#!/bin/bash
GitUser="dantemugetsu"
#IZIN SCRIPT
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
clear
apt install jq curl -y
DOMAIN="${CF_DOMAIN:-}"       # set your own; used only by option 2 (random subdomain)
sub=$(</dev/urandom tr -dc a-z0-9 | head -c4)
SUB_DOMAIN="${sub}.${DOMAIN}"
CF_ID=admin@chubcity.dpdns.org
CF_KEY="${CF_APIKEY:-}"       # set your own; used only by option 2 (random subdomain)
set -euo pipefail
IP=$(wget -qO- icanhazip.com);
echo "Updating DNS for ${SUB_DOMAIN}..."
ZONE=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" | jq -r .result[0].id)

RECORD=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${SUB_DOMAIN}" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" | jq -r .result[0].id)

if [[ "${#RECORD}" -le 10 ]]; then
     RECORD=$(curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'${SUB_DOMAIN}'","content":"'${IP}'","ttl":120,"proxied":false}' | jq -r .result.id)
fi

RESULT=$(curl -sLX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${RECORD}" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'${SUB_DOMAIN}'","content":"'${IP}'","ttl":120,"proxied":false}')
echo "Host : $SUB_DOMAIN"
echo "IP=" >> /var/lib/premium-script/ipvps.conf

# --- validate before writing: refuse garbage like "2hq5." ---
if [[ -z "${DOMAIN}" || "${SUB_DOMAIN}" != *.*.* || "${SUB_DOMAIN}" == *".."* ]]; then
    echo
    echo "ERROR: random subdomain generation failed."
    echo "  CF_DOMAIN is empty -> SUB_DOMAIN would be '${SUB_DOMAIN}'"
    echo "  Set CF_DOMAIN and CF_APIKEY, or use option 1 to enter your own domain."
    echo "  NOT writing /root/domain (refusing to install a broken domain)."
    rm -f /root/cf.sh
    exit 1
fi

echo $SUB_DOMAIN > /root/domain
rm -f /root/cf.sh
