# VPSSCRIPT — deobfuscated, license-free, fully self-contained fork

Fork of `NiL070/oddloop` (AutoScriptVPN). Plaintext — the original shipped every
`.sh` as an shc-compiled encrypted ELF. Brand: **TAKUMIWASHERE**.

- Repo: **https://github.com/dantemugetsu/VPSSCRIPT** (public)
- Owner var `GitUser` = `dantemugetsu` · repo `GITHUB_REPO` = `VPSSCRIPT`
- **No external repos required.** Everything is bundled under `_deps/`.

## Install (fresh Debian/Ubuntu VPS, root)

```bash
wget -O installer.sh https://raw.githubusercontent.com/dantemugetsu/VPSSCRIPT/main/installer.sh
chmod +x installer.sh && ./installer.sh
# pick 2 (v3) or 1 (v2) — license gate already bypassed
```

## Layout

```
installer.sh / setup.sh / setup2.sh / install/*      core installer
menu.sh / menu2.sh / menu/ system/ change-port/ ...  admin panels
ohp ohpd ohps badvpn-udpgw64 system/speedtest_cli.py binaries
_deps/
  email/    default.conf
  version/  version.conf
  banner/   bannerssh1..4, bannersshDefault
  allow/    ipvps.conf, accessmenu
  xray/     Xray-linux-64-v1.7.2-1        (v2 core, custom mod)
  xray-v3/  xray-linux-amd64              (v3 core)
  tools/
    swapram/            swapram.sh
    cfwarp/             setup.sh, menu.sh, warp.sh, LICENSE, README
    noobzvpns.tar.gz    full noobzvpns
    addon/udp-custom/   udp.sh, udp-custom-linux-amd64, config.json
    XrayCoreChanger/    xcorechanger.sh
```

## Changes vs upstream

| change | where |
|---|---|
| shc ELF → plaintext shell (incl. cfwarp/setup.sh, cfwarp/menu.sh, xcorechanger.sh) | all `.sh` |
| license + owner gates removed | `setup.sh`, `setup2.sh`, `menu/addip.sh` |
| **author Google Drive token stripped** | `install/set-br.sh` |
| **Telegram bot token stripped** | `_deps/tools/cfwarp/setup.sh` |
| **Telegram shadow-exfil deleted** | `system/backupbot` |
| brand `NiLphreakz`→`TAKUMIWASHERE`, `oddloop`→`VPSSCRIPT` | everywhere |
| all sibling repos folded into `_deps/` | see layout |
| vnstat tarball (404 upstream) removed | `install/ssh-vpn{,2}.sh` |
| CRLF→LF, dangling `esac` fixed | 11 files, `system/info.sh` |

## Menu tools — all local now

| menu opt | tool | source |
|---|---|---|
| 17 | swapram | `_deps/tools/swapram/` |
| 44 | cfwarp | `_deps/tools/cfwarp/` |
| 55/66 | noobzvpns | `_deps/tools/noobzvpns.tar.gz` |
| 77 | udp-custom | `_deps/tools/addon/udp-custom/` |
| 88 | xcorechanger | `_deps/tools/XrayCoreChanger/` |
| v2 core | custom Xray 1.7.2 mod | `_deps/xray/` |
| v3 core | Xray 25.10.15 | `_deps/xray-v3/` |

Verified: 0 shc binaries remain, 0 `nilphreakz`/`nil070`/`oddloop` strings,
0 telegram tokens, `bash -n` clean on every `.sh`, all raw URLs 200.

## Backups

`system/backup*.sh` upload via `rclone` to a remote named `dr`. Token is blank
in this fork (upstream sent backups to the author's Drive) — run
`rclone config` to set up your own, or leave it and backups just fail.

## Update flow

```bash
cd <local fork>   # C:\AI PROJECT\projects\VPSSCRIPT-RE\05-fork\VPSSCRIPT
# edit...
git add -A && git commit -m "..." && git push
```
