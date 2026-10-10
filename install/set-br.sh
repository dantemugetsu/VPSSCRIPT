#!/bin/bash

GitUser="TAKUMIWASHERE"
#curl https://rclone.org/install.sh | bash
# rclone v2
#wget https://rclone.org/install.sh
#chmod +x install.sh
#./install.sh
#printf "q\n" | rclone config

# rclone v3
#wget https://raw.githubusercontent.com/JebonRX/test/main/setup/rclone-v1.72.1-linux-amd64.zip
cd /root
LATEST=$(curl -s https://api.github.com/repos/rclone/rclone/releases/latest | grep tag_name | cut -d '"' -f4)
wget -O rclone.zip https://github.com/rclone/rclone/releases/download/${LATEST}/rclone-${LATEST}-linux-amd64.zip
unzip -o rclone.zip
cd rclone-${LATEST}-linux-amd64
cp rclone /usr/local/bin/
chmod 755 /usr/local/bin/rclone
rclone version
sleep 5

#wget -O /root/.config/rclone/rclone.conf "https://raw.githubusercontent.com/JebonRX/test/main/others/rclone.conf"
#git clone  https://github.com/MrMan21/wondershaper.git &> /dev/null
#cd wondershaper
#make install

# wonder v2
git clone https://github.com/MrMan21/wondershaper.git
cd wondershaper
chmod +x wondershaper
cp wondershaper /usr/local/bin/
cd
rm -rf wondershaper
cd /usr/bin
wget -O autobackup "https://raw.githubusercontent.com/${GitUser}/oddloop/main/system/autobackup.sh"
wget -O backup "https://raw.githubusercontent.com/${GitUser}/oddloop/main/system/backup.sh"
wget -O bckp "https://raw.githubusercontent.com/${GitUser}/oddloop/main/system/bckp.sh"
wget -O restore "https://raw.githubusercontent.com/${GitUser}/oddloop/main/system/restore.sh"
#wget -O strt "https://raw.githubusercontent.com/${GitUser}/oddloop/main/system/strt.sh"
wget -O limit-speed "https://raw.githubusercontent.com/${GitUser}/oddloop/main/limit-speed.sh"
chmod +x autobackup
chmod +x backup
chmod +x bckp
chmod +x restore
#chmod +x strt
chmod +x limit-speed
chmod +x clear-log

# custom rclone -- TOKEN REMOVED by TAKUMIWASHERE fork.
# Configure your OWN remote (e.g. `rclone config`) and name it [dr],
# or edit this file to point at your own Google Drive / storage.
mkdir -p /root/.config/rclone
if [ ! -s /root/.config/rclone/rclone.conf ]; then
  cat <<'EOF' > /root/.config/rclone/rclone.conf
[dr]
type = drive
scope = drive
# token = <PUT YOUR OWN rclone token here>
EOF
fi

# install nginx
tee /etc/nginx/nginx.conf >/dev/null <<'EOF'
user www-data;

worker_processes 1;
pid /var/run/nginx.pid;

events {
	multi_accept on;
	worker_connections 1024;
}

http {
	gzip on;
	gzip_vary on;
	gzip_comp_level 5;
	gzip_types text/plain application/x-javascript text/xml text/css;

	autoindex on;
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	server_tokens off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	client_max_body_size 32M;
	client_header_buffer_size 8m;
	large_client_header_buffers 8 8m;

	fastcgi_buffer_size 8m;
	fastcgi_buffers 8 8m;
	fastcgi_read_timeout 600;

	set_real_ip_from 204.93.240.0/24;
	set_real_ip_from 204.93.177.0/24;
	set_real_ip_from 199.27.128.0/21;
	set_real_ip_from 173.245.48.0/20;
	set_real_ip_from 103.21.244.0/22;
	set_real_ip_from 103.22.200.0/22;
	set_real_ip_from 103.31.4.0/22;
	set_real_ip_from 141.101.64.0/18;
	set_real_ip_from 108.162.192.0/18;
	set_real_ip_from 190.93.240.0/20;
	set_real_ip_from 188.114.96.0/20;
	set_real_ip_from 197.234.240.0/22;
	set_real_ip_from 198.41.128.0/17;
	real_ip_header CF-Connecting-IP;

	include /etc/nginx/conf.d/*.conf;
}
EOF

# install vps.conf
tee /etc/nginx/conf.d/vps.conf >/dev/null <<'EOF'
server {
    listen 81;
    server_name _;

    access_log /var/log/nginx/vps-access.log;
    error_log  /var/log/nginx/vps-error.log error;

    root /home/vps/public_html;
    index index.php index.html index.htm;

    # Allow local only
    location / {
        allow 127.0.0.1;
        allow ::1;
        deny all;

        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        allow 127.0.0.1;
        allow ::1;
        deny all;

        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    }
}
EOF

# install speedtest ookla latest
# 1️⃣ Update package list
#apt-get update

# 2️⃣ Pasang curl kalau belum ada
#apt-get install curl -y

# 3️⃣ Tambah repository rasmi Ookla
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash

# 4️⃣ Pasang Speedtest CLI
apt-get install speedtest -y

# 5️⃣ Jalankan ujian speed
#speedtest

#Buat script helper systemd
cat <<'EOF' > /usr/local/bin/limit-speed-apply.sh
#!/bin/bash
LIMIT_FILE="/home/limit"

if [[ -f "$LIMIT_FILE" ]] && [[ -s "$LIMIT_FILE" ]]; then
    read NIC DOWN UP < "$LIMIT_FILE"
    wondershaper -c -a "$NIC" 2>/dev/null
    wondershaper -a "$NIC" -d $((DOWN*1000)) -u $((UP*1000))
fi
EOF

chmod +x /usr/local/bin/limit-speed-apply.sh


#Buat systemd service untuk auto-apply limit saat boot
cat <<EOF > /etc/systemd/system/limit-speed.service
[Unit]
Description=Apply bandwidth limit with wondershaper
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/limit-speed-apply.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# start limit speed boot
systemctl daemon-reload
systemctl start limit-speed.service
#systemctl status limit-speed.service
systemctl enable limit-speed.service

#AUTO CLEAR LOG VPS EVERY 5 HOURS
tee /etc/systemd/system/clear-log.service > /dev/null <<'EOF'
[Unit]
Description=Run clear-log script

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/bin/clear-log
EOF

#systemd timer (setiap 5 jam)
tee /etc/systemd/system/clear-log.timer > /dev/null <<'EOF'
[Unit]
Description=Run clear-log every 5 hours

[Timer]
OnBootSec=10min
OnUnitActiveSec=5h
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload & enable timer
systemctl daemon-reload
systemctl enable --now clear-log.timer

#done
rm -r set-br.sh
rm -r rclone.zip
sleep 1
