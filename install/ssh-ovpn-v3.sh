#!/bin/bash

GitUser="dantemugetsu"

# // initializing var
export DEBIAN_FRONTEND=noninteractive
MYIP=$(wget -qO- icanhazip.com);
MYIP=$(curl -s ipinfo.io/ip )
MYIP=$(curl -sS ipv4.icanhazip.com)
MYIP=$(curl -sS ifconfig.me )
MYIP2="s/xxxxxxxxx/$MYIP/g";
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}');
source /etc/os-release
ver=$VERSION_ID

# // detail nama perusahaan
country="MY"
state="Kuala_Lumpur"
locality="Kuala_Lumpur"
organization="@TAKUMIWASHERE"
organizationalunit="@TAKUMIWASHERE"
commonname="TAKUMIWASHERE"
email="admin@takumiwashere.com"

# // simple password minimal
wget -O /etc/pam.d/common-password "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/assets/pam-common-password"
chmod +x /etc/pam.d/common-password

# // go to root
cd

# // Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# // nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# // Ubah izin akses
chmod +x /etc/rc.local

# // enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# // disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# // update
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y

# // install wget and curl
apt -y install wget curl

# // install netstat
apt install net-tools -y

# // install dos2unix
apt install -y dos2unix

# // install iftop & htop
apt install iftop -y
apt install htop -y

# install git
apt install git -y

apt install irqbalance -y
systemctl enable --now irqbalance

# // set time GMT +8
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# // set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config

# // install
apt-get --reinstall --fix-missing install -y bzip2 gzip coreutils wget screen rsyslog iftop htop net-tools zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr libxml-parser-perl neofetch git lsof
echo "clear" >> .profile
echo "menu" >> .profile

# // install webserver
apt -y install nginx
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/nginx.conf"
mkdir -p /home/vps/public_html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/vps.conf"
/etc/init.d/nginx restart

# // install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500' /etc/rc.local
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7700 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7800 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7900 --max-clients 500

# // setting port ssh
cd
apt-get -y update
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g'

# /etc/ssh/sshd_config
sed -i '/Port 22/a Port 500' /etc/ssh/sshd_config
#sed -i '/Port 22/a Port 40000' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 51443' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 58080' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 200' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

# install dropbear
apt update -y
apt install -y dropbear

# tulis ulang konfigurasi dropbear
cat > /etc/default/dropbear <<'EOF'
NO_START=0
DROPBEAR_PORT=143
DROPBEAR_EXTRA_ARGS="-p 109 -p 22"
DROPBEAR_BANNER=""
EOF

# pastikan shell dibatasi untuk user tertentu (jika diperlukan)
grep -qxF "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
grep -qxF "/usr/sbin/nologin" /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells

# Systemd Dropbear Service
tee /etc/systemd/system/dropbear.service > /dev/null <<'EOF'
[Unit]
Description=Lightweight SSH server
Documentation=man:dropbear(8)
After=network.target

[Service]
Environment=DROPBEAR_PORT=22 DROPBEAR_RECEIVE_WINDOW=65536
EnvironmentFile=-/etc/default/dropbear

# Clear previous ExecStart and set new one that includes banner
ExecStart=/usr/sbin/dropbear -EF -p "$DROPBEAR_PORT" -W "$DROPBEAR_RECEIVE_WINDOW" -b "$DROPBEAR_BANNER" $DROPBEAR_EXTRA_ARGS

KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# enable & restart dropbear
systemctl enable dropbear
systemctl restart dropbear

# // install squid for debian 9,10 & ubuntu 20.04
apt -y install squid3

# install squid for debian 11
apt -y install squid
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/assets/squid.conf"
sed -i $MYIP2 /etc/squid/squid.conf

# // setting vnstat
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
# vnstat source build removed by fork (upstream tarball is 404); apt package used instead
vnstat -u -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -rf /root/vnstat-2.6

# Ws-Ovpn EnvironmentFile
tee /etc/default/ws-ovpn > /dev/null <<'EOF'
# PORT for ws-ovpn
WS_OVPN_PORT="2097"
# Extra args (optional)
WS_OVPN_OPTS=""
EOF

# // install stunnel
apt install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
pid = /var/run/stunnel4/stunnel.pid
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 222
connect = 127.0.0.1:22

[dropbear]
accept = 777
connect = 127.0.0.1:109

[openvpn]
accept = 442
connect = 127.0.0.1:1194

[ws-stunnel]
accept = 2096
connect = 127.0.0.1:2091
END

groupadd stunnel
useradd -r -g stunnel -s /usr/sbin/nologin stunnel

mkdir -p /var/run/stunnel4
chown stunnel:stunnel /var/run/stunnel4

# // make a certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# // konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/lib/systemd/systemd-sysv-install enable stunnel4
systemctl start stunnel4
/etc/init.d/stunnel4 restart

# // OpenVPN
wget -O vpn.sh https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/openvpn.sh && chmod +x vpn.sh && ./vpn.sh

# // install lolcat
wget https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/assets/lolcat.sh &&  chmod +x lolcat.sh && ./lolcat.sh

# // install fail2ban
apt -y install fail2ban

# // Instal DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
echo -n '.'
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
echo -n '.'
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
echo -n '.'
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
echo '...done'
echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'
echo 'Please send in your comments and/or suggestions to zaf@vsnl.com'

# // banner /etc/issue.net
wget -O /etc/issue.net "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/assets/banner/bannerssh.conf"
echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear

# // Bannerku menu
wget -O /usr/bin/bannerku https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/assets/banner/bannerku && chmod +x /usr/bin/bannerku

# // install bbr
wget https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/bbr.sh && chmod +x bbr.sh && ./bbr.sh

# // blockir torrent
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# // download script
#cd /usr/local/sbin
#wget -O xray-quota.sh "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/quota-xray/xray-quota.sh"
#wget -O menu-quota-vmess.sh "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/quota-xray/menu-quota-vmess.sh"
#chmod +x xray-quota.sh
#chmod +x menu-quota-vmess.sh
#sed -i 's/\r$//' /usr/local/sbin/xray-quota.sh
#sed -i 's/\r$//' /usr/local/sbin/menu-quota-vmess.sh
#xray-quota.sh

# // download script
cd /usr/bin
#wget -O quota-vless "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/menu/quota-vless.sh"
wget -O proxy-warp "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/proxy-warp.sh"
wget -O change-dropbear "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/change-dropbear.sh"
wget -O menu-noobzvpn "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/noobzvpn.sh"
wget -O add-host "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/add-host.sh"
wget -O about "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/about.sh"
wget -O menu "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/menu-v3.sh"
wget -O add-ssh "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/add/ssh-v3.sh"
wget -O trial "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/add/ssh-trial-v2.sh"
wget -O del-ssh "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/delete/ssh.sh"
wget -O member "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/list.sh"
wget -O delete "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/delete/all.sh"
wget -O cek-ssh "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/check/ssh.sh"
wget -O cek-xray "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/check/xray.sh"
wget -O restart "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/restart.sh"
wget -O speedtest "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/info.sh"
wget -O ip6menu "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/ipv6.sh"
wget -O ram "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/ram.sh"
wget -O renew-ssh "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/renew/ssh.sh"
wget -O autokill "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/service/autokill.sh"
wget -O ceklim "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/check/limit.sh"
wget -O tendang "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/service/kick.sh"
wget -O clear-log "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/service/clear-log.sh"
wget -O change-port "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/menu/change-port.sh"
wget -O port-ovpn "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/network/ports/port-ovpn.sh"
wget -O port-ssl "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/network/ports/port-ssl.sh"
wget -O port-squid "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/network/ports/port-squid.sh"
wget -O port-websocket "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/network/ports/port-websocket.sh"
wget -O wbmn "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/webmin.sh"
wget -O xp "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/accounts/expired.sh"
wget -O xp2 "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/xp2.sh"
wget -O kernel-updt "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/kernel.sh"
wget -O user-list "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/tools/user-list.sh"
wget -O user-lock "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/tools/user-lock.sh"
wget -O user-unlock "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/tools/user-unlock.sh"
wget -O user-password "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/tools/user-password.sh"
wget -O antitorrent "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/tools/antitorrent.sh"
wget -O cfa "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/cloudflare/account.sh"
wget -O cfd "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/cloudflare/domain.sh"
wget -O cfp "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/cloudflare/pointing.sh"
wget -O swap "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/swap.sh"
wget -O check-sc "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/running-v3.sh"
wget -O bbr-manager "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/bbr-manager.sh"
wget -O ssh2 "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/menu/ssh-ovpn.sh"
wget -O autoreboot "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/autoreboot.sh"
wget -O bbr "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/bbr.sh"
wget -O port-ohp "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/network/ports/port-ohp.sh"
wget -O port-xray "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/network/ports/xray-v2.sh"
wget -O panel-domain "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/menu/panel-domain.sh"
wget -O system "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/menu/system.sh"
wget -O themes "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/menu/themes.sh"
wget -O update "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/update/update.sh"
wget -O run-update "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/update/run-update.sh"
wget -O message-ssh "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/update/message-ssh.sh"
wget -O dns "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/dns.sh"
wget -O netf "https://raw.githubusercontent.com/${GitUser}/VPSSCRIPT/main/system/netf.sh"
chmod +x add-host
chmod +x menu
chmod +x add-ssh
chmod +x trial
chmod +x del-ssh
chmod +x member
chmod +x delete
chmod +x cek-ssh
chmod +x restart
chmod +x speedtest
chmod +x info
chmod +x about
chmod +x autokill
chmod +x tendang
chmod +x ceklim
chmod +x ram
chmod +x renew-ssh
chmod +x clear-log
chmod +x change-port
chmod +x restore
chmod +x port-ovpn
chmod +x port-ssl
chmod +x port-squid
chmod +x port-websocket
chmod +x wbmn
chmod +x xp
chmod +x xp2
chmod +x kernel-updt
chmod +x user-list
chmod +x user-lock
chmod +x user-unlock
chmod +x user-password
chmod +x antitorrent
chmod +x cfa
chmod +x cfd
chmod +x cfp
chmod +x swap
chmod +x check-sc
chmod +x ssh2
chmod +x autoreboot
chmod +x bbr
chmod +x port-ohp
chmod +x port-xray
chmod +x panel-domain
chmod +x system
chmod +x themes
chmod +x update
chmod +x run-update
chmod +x message-ssh
chmod +x dns
chmod +x ip6menu
chmod +x netf
chmod +x bbr-manager
chmod +x menu-noobzvpn
chmod +x change-dropbear
chmod +x proxy-warp
chmod +x cek-xray
#chmod +x quota-vless
#sed -i 's/\r$//' /usr/bin/quota-vless
sed -i 's/\r$//' /usr/bin/proxy-warp
sed -i 's/\r$//' /usr/bin/menu-noobzvpn
sed -i 's/\r$//' /usr/bin/change-dropbear
sed -i 's/\r$//' /usr/bin/install-figlet
sed -i 's/\r$//' /usr/bin/cek-xray
#quota-vless
install-figlet
echo "0 1 * * * root delete" >> /etc/crontab
echo "0 2 * * * root xp" >> /etc/crontab
echo "0 5 * * * root reboot" >> /etc/crontab
echo "0 14 * * * root backup" >> /etc/crontab
echo "0 23 * * * root clear-log" >> /etc/crontab
echo "0 5 * * * root clear-log" >> /etc/crontab
echo "0 12 * * * root clear-log" >> /etc/crontab
echo "0 18 * * * root clear-log" >> /etc/crontab
echo "0 1 * * * root backup" >> /etc/crontab
echo "0 3 * * * root /usr/bin/xp" >> /etc/crontab
echo "0 4 * * * root /usr/bin/delete" >> /etc/crontab
echo "0 9 * * * root /usr/bin/clear-log" >> /etc/crontab
#echo "10 23 * * * root /usr/bin/backup" >> /etc/crontab

# // remove unnecessary files
cd
apt autoclean -y
apt -y remove --purge unscd
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove bind9*;
apt-get -y remove sendmail*
apt autoremove -y

# // finishing
cd
chown -R www-data:www-data /home/vps/public_html
systemctl restart nginx
systemctl restart openvpn
systemctl restart cron
systemctl restart ssh
systemctl restart dropbear
systemctl restart fail2ban
systemctl restart vnstat
systemctl restart stunnel4
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7700 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7800 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7900 --max-clients 500
history -c
echo "unset HISTFILE" >> /etc/profile

cd
rm -f /root/key.pem
rm -f /root/cert.pem
rm -f /root/ssh-vpn.sh
clear
