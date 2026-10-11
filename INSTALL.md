# VPSSCRIPT — Manual Install Guide

Repo: **https://github.com/dantemugetsu/VPSSCRIPT** · Brand: **TAKUMI1337Z / TAKUMIWASHERE**

---

## 0. Try it locally first (no VPS needed) — for TESTING only

You can run the whole installer inside a throwaway Docker container on your own
PC. Nothing touches your real machine, and you can poke every menu. This is the
recommended way to explore before renting a VPS.

**Verified working** — full run in `jrei/systemd-debian:12`: 14 services up,
35 ports listening, menus render.

**Also verified end-to-end on a real VPS** (Tencent Lighthouse, Ubuntu 22.04,
KVM, ap-singapore): **25 services** running, **zero failed units**, and a real
Let's Encrypt certificate issued for the configured domain.

### Prereqs
- Docker Desktop running (Windows/macOS) or Docker Engine (Linux)
- ~3 GB free disk
- Internet

### Steps

**1. Start a throwaway systemd Debian container**

```bash
docker run -d --name vps-test --privileged --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  jrei/systemd-debian:12
```

Wait ~10s, then confirm systemd is up:

```bash
docker exec vps-test systemctl is-system-running
# -> running   (or "initializing" — wait a few more seconds)
```

**2. Install the few tools the installer needs**

```bash
docker exec vps-test bash -c "apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wget curl screen unzip procps iproute2 net-tools"
```

**3. Drop into a shell inside the container**

```bash
docker exec -it vps-test bash
```

**4. Run the installer — exactly as on a real VPS**

```bash
export SKIP_REBOOT=1          # IMPORTANT: don't reboot the container
cd /root
wget -O installer.sh https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/installer.sh
chmod +x installer.sh
./installer.sh
```

Answer the prompts (see §3). It takes **~10–25 minutes** (it installs ~250 apt
packages). When it finishes you'll see `SUCCESFULLY INSTALLED THE SCRIPT` and,
because of `SKIP_REBOOT=1`, `[SKIP_REBOOT set] not rebooting`.

**5. Check it worked**

```bash
menu                                   # the main panel
systemctl list-units --type=service --state=running | grep -Ei 'xray|nginx|squid|openvpn|dropbear|ohp|stunnel'
ss -tlnp | head -40
cat /root/log-install.txt
```

Expected: **14 services**, ~35 listening ports.

**6. Stop / wipe when done**

```bash
exit                      # leave the container shell
docker rm -f vps-test     # delete the container (everything is inside it)
```

### What will NOT work locally (expected)

| Thing | Why |
|---|---|
| Let's Encrypt cert for your domain | the fake subdomain has no public DNS — the cert step fails but the install continues |
| Clients connecting from outside | ports are inside the container, not on your LAN |
| `reboot` at the end | suppressed by `SKIP_REBOOT=1` |
| Ports 22/80/443/8080 etc. on the host | they stay inside the container |

> ⚠️ The container needs `--privileged`, and it will use the same port numbers
> your host already uses — but **inside the container**, so your host is
> unaffected. Do **not** publish those ports with `-p` unless you know what
> you're doing.

> **Docker not available?** You can use **WSL2** instead: `wsl --install -d Ubuntu`,
> then run the installer inside WSL as root. But WSL isn't systemd-by-default on
> all setups, so Docker is the cleaner path.

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
apt update -y
apt install -y wget curl screen unzip procps iproute2 net-tools

cd /root
wget -O installer.sh https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/installer.sh
chmod +x installer.sh
./installer.sh
```

> `screen` and `unzip` matter — a bare Ubuntu/Debian image does not ship them,
> and the installer uses both.

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

> ⚠️ **The DNS record must exist BEFORE you run this.** The installer runs
> `acme.sh --issue -d <domain> -d sshws.<domain> --standalone`, so **both**
> names must resolve to this VPS or the certificate step fails:
> ```
> A   <your-domain>         -> <VPS IP>    (DNS only / grey cloud)
> A   sshws.<your-domain>   -> <VPS IP>    (DNS only / grey cloud)
> ```
> If you use Cloudflare, the proxy **must be OFF** (grey cloud) — orange-cloud
> proxying breaks the raw TLS/WS the VPN needs.
>
> If the cert fails the install still completes; you just get a self-signed cert
> and clients will warn. Re-run `renew-cert` later once DNS is right.

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
menu                        # the main panel
cat /root/log-install.txt   # full install log (service + port list)
```

If you set `SKIP_REBOOT=1`, reboot manually when ready:
```bash
reboot
```

Verify services — **all of these should say `active`**:
```bash
systemctl --failed                                          # should print NOTHING
systemctl list-units --type=service --state=running --no-pager
ss -tlnp
```

A healthy v2 install on a real VPS shows **25 services**:

```
dropbear  nginx  squid  stunnel4  ohp  ohpd  ohps  fail2ban
ws-http  ws-https  ws-ovpn
openvpn-server@server-tcp-1194   openvpn-server@server-udp-2200
xray  xray@none  xray@tcp  xray@vless  xray@vlessnone  xray@vlessc
xray@config  xray@vmess  xray@vmessnone  xray@vmessc  xray@trojan  xray@trojannone
```

> If `systemctl --failed` lists any `xray@*` unit, run the recovery sweep:
> ```bash
> for u in $(systemctl list-units --type=service --state=failed --no-legend | awk '{print $1}'); do systemctl restart "$u"; done
> ```
> See §11 for why this can happen.

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

### 6.1 Open the firewall

**Cloud providers have an edge firewall separate from anything in the VM.** The
installer removes `ufw`/`firewalld` *inside* the box, but that does nothing about
the provider's edge. If you skip this, services run perfectly and every client
still times out.

Tencent Lighthouse default is only **22, 80, ICMP** — and **443 is NOT open**
despite what the docs imply. Add (console → instance → **Firewall** tab, or via
API):

| Protocol | Ports |
|---|---|
| **TCP** | `81,109,143,222,442,443,777,1194,2086,2087,2096,2097,3128,8000,8080,8585,8686,8787,8880` |
| **UDP** | `2200` ← OpenVPN-UDP; **must be its own rule** |

Via API:

```bash
tccli lighthouse CreateFirewallRules --region <region> --InstanceId <instance-id> \
  --FirewallRules '[{"Protocol":"TCP","Port":"81,109,143,222,442,443,777,1194,2086,2087,2096,2097","CidrBlock":"0.0.0.0/0","Action":"ACCEPT","FirewallRuleDescription":"VPSSCRIPT-TCP-1"}]'
```

> The `Port` field is capped at **64 characters**, so split long lists across
> multiple rules. Do **not** open 7100–7900 — badvpn binds `127.0.0.1` only.

---

## 7. Main menu map (installed commands)

**v2 menu**

```
menu
 ├─ [ 1 ]  XRAY   - VMess / VLESS / XTLS   -> xray-menu
 ├─ [ 2 ]  TROJAN - TCP-TLS / WS-TLS       -> trojan-menu
 ├─ [ 3 ]  SSH / OPENVPN - user accounts   -> ssh-menu
 ├─ [ 4 ]  NOOBZVPN - menu                 -> noobzvpn-menu
 ├─ [ 5 ]  SYSTEM TOOLS                    -> system
 ├─ [ 6 ]  THEMES & BANNER                 -> themes
 ├─ [ 7 ]  CHANGE PORTS                    -> change-port
 ├─ [ 8 ]  CHECK RUNNING                   -> check-running
 ├─ [ 9 ]  SERVICE / PORT INFO             -> cat /root/log-install.txt
 ├─ [ 10 ] DELETE EXPIRED USERS            -> delete-expired
 ├─ [ 11 ] CLEAR LOGS                      -> clear-log
 ├─ [ 12 ] REBOOT VPS
 └─ [ x ]  EXIT
```

**v3 menu** (adds WARP + Xray-login check, so numbers shift)

```
menu
 ├─ [ 1 ]  XRAY   - VMess / VLESS / XTLS   -> xray-menu
 ├─ [ 2 ]  TROJAN - TCP-TLS / WS-TLS       -> trojan-menu
 ├─ [ 3 ]  SSH / OPENVPN - user accounts   -> ssh-menu
 ├─ [ 4 ]  NOOBZVPN - menu                 -> noobzvpn-menu
 ├─ [ 5 ]  CLOUDFLARE WARP - menu          -> proxy-warp
 ├─ [ 6 ]  CHECK XRAY USER LOGINS          -> check-xray
 ├─ [ 7 ]  SYSTEM TOOLS                    -> system
 ├─ [ 8 ]  THEMES & BANNER                 -> themes
 ├─ [ 9 ]  CHANGE PORTS                    -> change-port
 ├─ [ 10 ] CHECK RUNNING                   -> check-running
 ├─ [ 11 ] SERVICE / PORT INFO             -> cat /root/log-install.txt
 ├─ [ 12 ] DELETE EXPIRED USERS            -> delete-expired
 ├─ [ 13 ] CLEAR LOGS                      -> clear-log
 ├─ [ 14 ] REBOOT VPS
 └─ [ x ]  EXIT
```

> **Menu presentation was unified** (2026-10-12): every item now uses the same
> `[ N ]` format (was a mix of `(1)`, `(•1)`), the `system` menu's optional tools
> were renumbered from `44/55/66/77/88/99` to `20–25` (**old numbers still work**),
> and all prompts are English. No command name or menu action changed.

> Every menu entry script now **re-execs itself as root** if you run it as a
> normal user (`sudo -H "$0"`). If you were seeing
> `sed: couldn't open temporary file /usr/local/etc/xray/...: Permission denied`
> and a polkit password prompt, that was the cause — it's fixed. `-H` (not `-E`)
> is required so `HOME` becomes `/root`; otherwise the menus read
> `~/log-install.txt` from your home dir and print **blank ports**.

Other commands: `check-ssh`, `check-limit`, `list-member`, `quick-backup`, `backup`,
`restore`, `webmin`, `ipv6-menu`, `kernel-update`, `renew-cert`, `cf-account`,
`cf-domain`, `cf-pointing`, `kick-user`, `autokill`, `autoreboot`, `speedtest`,
`info`, `about`, `ram`, `swap`, `bbr`, `bbr-manager`, `dns`, `netf`, `restart`,
`update`, `run-update`, `message-ssh`, `panel-domain`, `antitorrent`,
`user-list`, `user-lock`, `user-unlock`, `user-password`.

**system menu** (`system`):

```
 ├─ [ 1 ]  Add New Subdomain        -> add-host
 ├─ [ 2 ]  Renew Cert Xray Core     -> renew-cert
 ├─ [ 3 ]  DNS Changer              -> dns
 ├─ [ 4 ]  Netflix Checker          -> netf
 ├─ [ 5 ]  Panel Domain             -> panel-domain
 ├─ [ 6 ]  Backup Vps               -> backup
 ├─ [ 7 ]  Restore Vps              -> restore
 ├─ [ 8 ]  Install Webmin           -> webmin
 ├─ [ 9 ]  Setup Speed VPS          -> limit-speed
 ├─ [ 10 ] Restart VPN              -> restart
 ├─ [ 11 ] Speedtest VPS            -> speedtest
 ├─ [ 12 ] Xray Version             -> xray version
 ├─ [ 13 ] BBR Manager              -> bbr-manager
 ├─ [ 14 ] ON/OF Auto Reboot        -> autoreboot
 ├─ [ 15 ] Change Password VPS      -> passwd
 ├─ [ 16 ] Check CPU & RAM          -> htop
 ├─ [ 17 ] Change Banner SSH        -> message-ssh
 ├─ [ 18 ] SwapRAM Menu             -> (downloads swapram)
 ├─ [ 19 ] ipv4/v6 Menu             -> ipv6-menu
 ├─ [ 20 ] Warp Installer Menu      -> (downloads cfwarp)   [was 44]
 ├─ [ 21 ] Install Noobzvpns        -> (downloads)          [was 55]
 ├─ [ 22 ] Uninstall Noobzvpns      ->                        [was 66]
 ├─ [ 23 ] Install UDP Custom       -> (downloads)          [was 77]
 ├─ [ 24 ] Xray-core Changer        -> (downloads)          [was 88]
 └─ [ 25 ] Change Dropbear Version  -> change-dropbear       [was 99]
```

> Items **20–25** were previously numbered `44/55/66/77/88/99`. **Both numbers
> still work** — type either one.

> Items 20–24 download their tool from the bundled `_deps/tools/` on first use
> (that's why they aren't pre-installed), then run it.

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

There is **no uninstaller** in the script, and **the installer is not
idempotent** — re-running it on an already-installed box produces duplicate
work and broken state. The reliable reset is to **wipe the VPS**.

### Re-image the VPS (recommended)

In the Tencent Lighthouse console: **instance → more → reinstall system**, or
via API:

```bash
tccli lighthouse ResetInstance --region <region> \
  --InstanceId <instance-id> \
  --BlueprintId lhbp-qnuz61zs \
  --LoginConfiguration '{"AutoGeneratePassword":"NO","Password":"<your-password>"}'
```

Then poll until `LatestOperationState` is `SUCCESS`:

```bash
tccli lighthouse DescribeInstances --region <region> --InstanceIds '["<instance-id>"]'
```

> Your **edge firewall rules survive** a reset (they live at the provider's
> edge, not on the disk), so you don't have to re-add them. Everything on the
> system disk is gone.

### Or remove the script's services manually

```bash
systemctl disable --now xray@* xray nginx squid openvpn-server@* dropbear ohp ohpd ohps \
  stunnel4 fail2ban ws-http ws-https ws-ovpn
rm -f /usr/bin/{menu,xray-menu,trojan-menu,ssh-menu,noobzvpn-menu,check-running,check-ssh,check-xray,check-limit,list-member,delete-expired,change-port,quick-backup,webmin,ipv6-menu,renew-cert,cf-account,cf-domain,cf-pointing,kick-user,autokill,autoreboot,clear-log,system,themes,info,about,ram,swap,bbr,bbr-manager,dns,netf,restart,update,run-update,message-ssh,panel-domain,antitorrent,user-list,user-lock,user-unlock,user-password,speedtest,bannerku}
rm -rf /usr/local/etc/xray /etc/xray /var/log/xray /etc/vps-theme
```

This is messier than re-imaging and easy to get incomplete. **Prefer the wipe.**

---

## 10. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `You need to run this script as root` | run as root |
| `OpenVZ is not supported` | use KVM/VMware/bare metal |
| `raw.githubusercontent.com` 404 or stale file | CDN lag after a push — wait 5–15 min and retry |
| Install "succeeds" but no services | check `/root/log-install.txt` and `systemctl --failed` |
| `screen: Must be connected to a terminal` | **fixed** — installer falls back to running the script directly when there's no TTY (headless/CI/piped stdin) |
| `figlet: invalid option -- '-'` | **fixed** — the theme name is stored in `/etc/vps-theme` (was clobbering `/usr/bin/test`) |
| `sed: couldn't open temporary file ... Permission denied` + polkit prompt | **fixed** — menus now re-exec as root |
| `cat: log-install.txt: No such file` | **fixed** — menu 9 now reads `/root/log-install.txt` |
| `ws-http`/`ws-https`/`ws-ovpn` are 0 bytes / dead | **fixed** — the websocket fetch URL now matches the directory |
| `check-running` shows blank user/order/validity | **fixed** — `GitUser` was wrong in `running-*.sh` |
| Backup fails | no `dr` rclone remote configured — see §8 |
| Menu banner shows a different name | it's the *theme* — change via menu 6 (themes) |

Report back with `/root/log-install.txt` + `systemctl --failed` + `ss -tlnp` if anything misbehaves.

---

## 11. Known-bad conditions to watch for

These were all real, reproduced bugs — fixed in the repo, but listed here so you
can recognise them if you run an older copy or hit a variant:

1. **xray units failing with `exit 23`**
   ```
   Failed to start: main: failed to create server > app/log:
   failed to initialize access logger > open /var/log/xray/access2.log: permission denied
   ```
   The services were being started *before* their log files were created and
   chowned to `www-data`, and `RestartPreventExitStatus=23` in `xray@.service`
   meant systemd never retried. Fixed by pre-creating/chowning every
   `access*.log` before the start, plus a restart sweep at the end.
   **If you see this**: `systemctl restart xray@vmess xray@vmessc xray@vmessnone xray@tcp xray@trojan`

2. **`/usr/bin/test` overwritten** — the original script used it as a scratch
   file for the figlet theme name, replacing the coreutils `test` binary with a
   9-byte text file. Check with `file /usr/bin/test` (must say `ELF ...`).
   Restore: `apt-get install --reinstall -y coreutils`.

3. **`ws-*` proxies at 0 bytes** — the installer `wget`s
   `.../websocket/ws-http` etc.; if the path is wrong you get empty files and
   the services exit instantly. Check `stat -c %s /usr/local/bin/ws-http`.

4. **Firewall looks fine but clients time out** — on Tencent Lighthouse the
   *edge* firewall is separate from the in-VM one. Only 22 and 80 are open by
   default; 443 is **not**, despite the docs. Open your ports in the console or
   via `tccli lighthouse CreateFirewallRules`. Remember **UDP 2200 needs its own
   rule** — a TCP rule does not cover it.
