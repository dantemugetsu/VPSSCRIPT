# VPSSCRIPT — Manual Install Guide

Repo: **https://github.com/dantemugetsu/VPSSCRIPT** · Brand: **TAKUMI1337Z / TAKUMIWASHERE**

---

## 1. Requirements

| Item | Need |
|---|---|
| OS | Debian 10/11/12 **or** Ubuntu 20.04/22.04/24.04 (systemd) |
| Access | **root** (the installer exits if not root) |
| Virt | **KVM / VMware / bare metal** — **OpenVZ is NOT supported** (installer aborts) |
| RAM | 1 GB min (2 GB comfortable — runs nginx, squid, xray, openvpn, dropbear, stunnel, ohp) |
| Disk | ~3 GB free |
| Arch | x86_64 (amd64) |
| Net | outbound HTTPS (it downloads from raw.githubusercontent.com) |
| Firewall | open the ports listed in §6 |

> ⚠️ **Use a fresh VPS.** The installer overwrites `/etc/nginx`, drops services on
> standard ports, changes the timezone to Asia/Kuala_Lumpur, enables fail2ban and
> **reboots the box at the end**.

---

## 2. Install (one-liner)

SSH into your VPS as root, then:

```bash
apt update -y && apt install -y wget curl
wget -O installer.sh https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/installer.sh
chmod +x installer.sh
./installer.sh
```

You'll see:

```
╔════════════════════════════════════════════════════════╗
║              TAKUMI1337Z MULTIPORT SCRIPT              ║
╠════════════════════════════════════════════════════════╣
║  1) Install Version 2.0 [OLD XRAYCORE]                 ║
║  2) Install Version 3.0 [LATEST XRAYCORE+NEW SERVICES] ║
║  0) Exit                                               ║
╚════════════════════════════════════════════════════════╝
Pilih option [0-2]:
```

Pick **`1`** for v2 (legacy Xray core 1.7.2-1) or **`2`** for v3 (latest Xray).

**v2 vs v3 — which to pick?**

| | v2 | v3 |
|---|---|---|
| Xray core | 1.7.2-1 (multipath build) | latest |
| Extra menu item | — | Cloudflare WARP menu + Xray login check |
| Recommended | if you need the *multipath* WS fork | **default choice** |

---

## 3. The prompts (answer order)

After choosing 1 or 2, the setup asks **4 questions**:

```
Enable IPv4 + IPv6? [ default: no (IPv4 only) ] [y/N]:
```
→ **ENTER** = IPv4 only (recommended). Type `y` only if your VPS has working IPv6.

```
Please enter the name of Provider for Script.
   Name :
```
→ Any label, e.g. your brand — shows up in the menu header. (e.g. `TAKUMI1337Z`)

```
Please enter your email Domain/Cloudflare.
(Press ENTER for default email)
   Email :
```
→ **ENTER** to use the bundled default, or type your own email.

```
Please select a domain type below
     1) Enter your Subdomain
     2) Use a random Subdomain
   Please select numbers 1-2 or Any Button(Random) :
```
→ **`1`** = you type your own subdomain (you must have the DNS A-record pointed at this VPS **already**)
→ **`2`** or any other key = it auto-generates a random subdomain via the bundled Cloudflare script

```
   Subdomain:
```
→ (only if you chose `1`) type your subdomain, e.g. `sg1.yourdomain.com`

Then it installs everything and **reboots automatically after ~5 seconds**.

---

## 4. Non-interactive / unattended install

Set `SKIP_REBOOT=1` to stop the automatic reboot (handy for testing):

```bash
export SKIP_REBOOT=1
printf '\nMYBRAND\n\n1\nsg1.yourdomain.com\n' | ./installer.sh   # careful: installer reads from tty
```

Cleaner — fetch and drive `setup-v2.sh` directly:

```bash
export SKIP_REBOOT=1
wget -O setup-v2.sh https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/setup-v2.sh
chmod +x setup-v2.sh
printf '\nMYBRAND\n\n1\nsg1.yourdomain.com\n' > /root/answers.txt
bash setup-v2.sh < /root/answers.txt
```

> The installer now runs correctly **headless** (cloud-init, CI, piped stdin) —
> the old `screen -S` no-op bug is fixed.

---

## 5. After it finishes

```bash
menu                 # the main panel
cat /root/log-install.txt   # full install log (service + port list)
```

If you set `SKIP_REBOOT=1`, reboot manually when ready:
```bash
reboot
```

Verify services:
```bash
systemctl list-units --type=service --state=running | grep -Ei 'xray|nginx|squid|openvpn|dropbear|ohp|stunnel'
ss -tlnp | grep -E ':(22|80|81|109|143|222|442|443|777|1194|2086|2087|2096|2097|2200|3128|7100|8000|8080|8585|8686|8787|8880)\b'
```

Expected: **14 services**, **~24 listening ports**.

---

## 6. Services & ports (v2)

| Service | Port(s) |
|---|---|
| OpenSSH | 22 |
| Dropbear | 143, 109 |
| OpenVPN | TCP 1194, UDP 2200 |
| OpenVPN SSL | 110 |
| Stunnel4 | 222, 777, 442, 2096 |
| Nginx | 81 |
| Squid proxy | 3128, 8000 |
| Badvpn udpgw | 7100–7900 |
| OHP (dropbear/ssh/openvpn) | 8585 / 8686 / 8787 |
| Websocket SSH (HTTP) | 80 |
| Websocket SSL (HTTPS) | 443, 2096 |
| Websocket OpenVPN | 2097 |
| NoobzVPN | TLS 2087, none-TLS 2086 |
| Xray VMess/VLESS/Trojan WS TLS | 443 |
| Xray VMess/VLESS/Trojan WS none-TLS | 80 |
| VMess multipath none-TLS | 8880 |
| VLESS multipath none-TLS | 8080 |

Xray configs live in `/usr/local/etc/xray/` (`vmess.json`, `vless.json`, `trojan.json`, `none.json`, `vlessc.json`, `trojannone.json`, …).

---

## 7. Main menu map (installed commands)

**v2 menu**

```
menu
 ├─ 1) Xray VMess & VLESS      -> xray-menu
 ├─ 2) Trojan Xray & WS        -> trojan-menu
 ├─ 3) SSHWS & OpenVPN         -> ssh-menu
 ├─ 4) NoobzVPN menu           -> noobzvpn-menu
 ├─ 5) System tools            -> system
 ├─ 6) Themes & banner         -> themes
 ├─ 7) Change ports            -> change-port
 ├─ 8) Check running           -> check-running
 ├─ 9) Service / port info     -> cat log-install.txt
 ├─10) Delete expired users    -> delete-expired
 ├─11) Clear logs              -> clear-log
 └─12) Reboot VPS
```

**v3 menu** (adds WARP + Xray-login check, so numbers shift)

```
menu
 ├─ 1) Xray VMess & VLESS      -> xray-menu
 ├─ 2) Trojan Xray & WS        -> trojan-menu
 ├─ 3) SSHWS & OpenVPN         -> ssh-menu
 ├─ 4) NoobzVPN menu           -> noobzvpn-menu
 ├─ 5) Cloudflare WARP menu    -> proxy-warp
 ├─ 6) Check Xray user logins  -> check-xray
 ├─ 7) System tools            -> system
 ├─ 8) Themes & banner         -> themes
 ├─ 9) Change ports            -> change-port
 ├─10) Check running           -> check-running
 ├─11) Service / port info     -> cat log-install.txt
 ├─12) Delete expired users    -> delete-expired
 ├─13) Clear logs              -> clear-log
 └─14) Reboot VPS
```

Other commands: `check-ssh`, `check-limit`, `list-member`, `quick-backup`, `backup`,
`restore`, `webmin`, `ipv6-menu`, `kernel-update`, `renew-cert`, `cf-account`,
`cf-domain`, `cf-pointing`, `kick-user`, `autokill`, `autoreboot`, `speedtest`,
`info`, `about`, `ram`, `swap`, `bbr`, `bbr-manager`, `dns`, `netf`, `restart`,
`update`, `run-update`, `message-ssh`, `panel-domain`, `antitorrent`,
`user-list`, `user-lock`, `user-unlock`, `user-password`.

---

## 8. Backups need YOUR rclone

The author's Google Drive token was removed. Backups use an rclone remote named **`dr`**.
Either configure one:

```bash
rclone config        # create a remote named exactly: dr
```

…or leave it — `backup` / `quick-backup` will just fail, nothing else breaks.

---

## 9. Re-install / uninstall

There is **no uninstaller** in the script. To wipe a VPS clean, either:

```bash
# nuke and re-image the VPS (recommended)
```

or, to remove the script's services manually:

```bash
systemctl disable --now xray@* nginx squid openvpn-server@* dropbear ohp ohpd ohps stunnel4
rm -f /usr/bin/{menu,xray-menu,trojan-menu,ssh-menu,noobzvpn-menu,check-running,check-ssh,check-xray,check-limit,list-member,delete-expired,change-port,quick-backup,webmin,ipv6-menu,renew-cert,cf-account,cf-domain,cf-pointing,kick-user,autokill,autoreboot,clear-log,system,themes,info,about,ram,swap,bbr,bbr-manager,dns,netf,restart,update,run-update,message-ssh,panel-domain,antitorrent,user-list,user-lock,user-unlock,user-password,speedtest}
rm -rf /usr/local/etc/xray /var/lib/premium-script
```

Simplest is to **re-image** — the installer is not idempotent.

---

## 10. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `You need to run this script as root` | run as root |
| `OpenVZ is not supported` | use KVM/VMware/bare metal |
| `raw.githubusercontent.com` 404 or stale file | CDN lag after a push — wait 5–15 min and retry |
| Install "succeeds" but no services | should not happen now (screen/TTY fix). Check `/root/log-install.txt` and `systemctl --failed` |
| Backup fails | no `dr` rclone remote configured — see §8 |
| Menu banner shows a different name | it's the *theme* — change via menu 8 (themes) |

Report back with `/root/log-install.txt` + `systemctl --failed` + `ss -tlnp` if anything misbehaves.
