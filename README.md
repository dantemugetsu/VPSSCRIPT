# VPSSCRIPT

SSH / Xray / WebSocket multiport VPS installer — plaintext, license-free,
fully self-contained build. Brand: **TAKUMIWASHERE**.

- Repo: **https://github.com/dantemugetsu/VPSSCRIPT**
- Owner `GitUser` = `dantemugetsu` · repo `GITHUB_REPO` = `VPSSCRIPT`
- **No external repos required** — everything is bundled under `_deps/`.

## Install (fresh Debian/Ubuntu VPS, as root)

```bash
apt update -y
apt install -y wget curl screen unzip procps iproute2 net-tools

cd /root
wget -O installer.sh https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/installer.sh
chmod +x installer.sh && ./installer.sh
# pick 1 (v2, legacy Xray core) or 2 (v3, latest) — no license gate
```

Prompts: `IPv4+IPv6? [y/N]` → `N` · provider name → anything · email → ENTER ·
domain type → `1` then type your subdomain.

> **Point your DNS first.** `acme.sh` issues a cert for **both** `<domain>` and
> `sshws.<domain>`, so create both A-records → your VPS IP (Cloudflare: **DNS
> only / grey cloud**) before running. Full walkthrough: **[INSTALL.md](INSTALL.md)**.
>
> `SKIP_REBOOT=1 ./installer.sh` suppresses the automatic reboot at the end.
> Expect **25 services** and a real Let's Encrypt cert on a clean KVM box.

Provider edge firewalls are separate from the VM's — open the ports in §6.1 of
INSTALL.md or clients will time out even though everything is running.

## Directory layout

```
installer.sh              entry point / version chooser
setup-v2.sh setup-v3.sh   install orchestration (v2 = legacy core, v3 = latest)
menu-v2.sh menu-v3.sh     main panel

install/                  one-shot installers
  ssh-ovpn-v2.sh  ssh-ovpn-v3.sh      SSH + OpenVPN stack
  xray-v2.sh      xray-v3.sh          Xray core + configs
  openvpn.sh  ohp.sh  ohp-dropbear.sh  ohp-ssh.sh
  base-config.sh  cloudflare.sh

menu/                     submenus
  xray-v2.sh xray-v3.sh  trojan-v2.sh trojan-v3.sh
  ssh-ovpn.sh  system.sh  themes.sh  change-port.sh
  noobzvpn.sh  panel-domain.sh

accounts/                 user management
  add/    ssh-v2.sh ssh-v3.sh ssh-trial-v2.sh ssh-trial-v3.sh
  delete/ ssh.sh all.sh        renew/ ssh.sh
  check/  ssh.sh xray.sh limit.sh
  list.sh list-v2.sh lock.sh unlock.sh passwd.sh expired.sh

network/                  tuning + ports
  ports/  port-{ohp,ovpn,squid,ssl,websocket}.sh  port-xray-v2.sh port-xray-v3.sh
  bbr.sh bbr-manager.sh dns.sh dns-setup.sh ipv6.sh netf.sh
  proxy-warp.sh speed-limit.sh antitorrent.sh

service/                  control + housekeeping
  restart.sh autoreboot.sh autokill.sh kick.sh clear-log.sh

system/                   server info + tools
  info.sh about.sh ram.sh swap.sh kernel.sh webmin.sh
  backup.sh quick-backup.sh restore.sh autobackup.sh
  cert.sh acme.sh change-dropbear.sh add-host.sh noobzvpn.sh
  running-v2.sh running-v3.sh speedtest_cli.py

cloudflare/               cf-account.sh cf-domain.sh cf-pointing.sh
update/                   update.sh run-update.sh message-ssh.sh
websocket/                websocket-v2.sh websocket-v3.sh ws-{http,http2,https,ovpn}
assets/                   banner/  pam-common-password  squid.conf  accel.conf  lolcat.sh
tools/                    antitorrent.sh user-{list,lock,unlock,password}.sh
_deps/                    bundled dependencies (email, version, banner, allow,
                          xray, xray-v3, tools/{swapram,cfwarp,noobzvpns,
                          addon/udp-custom,XrayCoreChanger})
```

## Installed commands

| command | purpose |
|---|---|
| `menu` | main panel |
| `xray-menu` / `trojan-menu` | Xray / Trojan account menus |
| `ssh-menu` | SSH & OpenVPN accounts |
| `check-ssh` `check-xray` `check-limit` | login / limit checks |
| `list-member` `list-v2` | member listings |
| `delete-expired` | remove expired accounts (cron) |
| `check-running` | live service / port status |
| `change-port` | port editor |
| `quick-backup` `backup` `restore` | backups |
| `webmin` `ipv6-menu` `kernel-update` `renew-cert` | system utilities |
| `cf-account` `cf-domain` `cf-pointing` | Cloudflare helpers |
| `kick-user` `autokill` | session control |
| `clear-log` | log rotation |

## Secrets

All author-owned credentials have been removed:

- hardcoded Google Drive OAuth token (was in the base-config installer)
- embedded Telegram bot token + chat id (was in the cfwarp helper)
- Telegram `/etc/shadow` exfil script (deleted)

Backups use your own `rclone` remote named `dr` — run `rclone config` to set it
up, or leave it and backups simply fail.

## Notes

- `system/ram.sh` is Python (upstream `ps_mem.py`), not shell.
- `system/speedtest_cli.py` is the Ookla binary.
- The figlet theme name is stored in **`/etc/vps-theme`** — never in
  `/usr/bin/test` (an upstream bug that clobbered the coreutils binary).
- Menu entry scripts **re-exec as root**, so running `menu` as a normal user no
  longer produces `sed: ... Permission denied` or a polkit prompt.
- A few optional URLs (`nginx.conf`, `vps.conf`, `xp2.sh`, quota helpers) are
  commented out — those files were never present in the source project.
- **Not idempotent.** Don't re-run the installer on an installed box — re-image
  it instead (see INSTALL.md §9).
