#!/bin/bash
#
# Install Remnawave node and route selected outbound traffic via VLESS+Reality using Xray-core.
#
# This script:
# 1) runs the existing install_node.sh (prompts are the same)
# 2) downloads domain list (inside-raw.lst) and generates an Xray routing config
# 3) starts xray-core inside Docker Compose (xray-vpn)
# 4) sets proxy env vars for the remnanode container so outbound requests go through xray-vpn
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_INSTALL_SCRIPT="${SCRIPT_DIR}/install_node.sh"
# Where the base installer is published (same repo as README).
BASE_INSTALL_URL="https://raw.githubusercontent.com/mr-Abdrahimov/remna-node-xhttp/refs/heads/main/install_node.sh"

REMNA_DIR="/opt/remnawave"
XRAY_DIR="${REMNA_DIR}/xray-vpn"
GEOSITE_URL="https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"
GEOSITE_FILE="${XRAY_DIR}/geosite.dat"
GEOIP_URL="https://github.com/v2fly/geoip/releases/download/202501090053/geoip.dat"
GEOIP_FILE="${XRAY_DIR}/geoip.dat"

OVERRIDE_COMPOSE_FILE="${REMNA_DIR}/docker-compose.vpn.yml"

# Your VLESS+Reality parameters extracted from the URL you provided.
VLESS_UUID="d3958b70-9432-4c84-9ced-8f72abbc8a00"
VLESS_HOST="polka.de1beast3xui.ru"
VLESS_PORT="443"
VLESS_FLOW="xtls-rprx-vision"
REALITY_FP="qq"
REALITY_SNI="google.com"
REALITY_PBK="3x-xcM-iAp9rXbRh1QpCMQxAArVh2zHHtdrR-8s9EVs"
REALITY_SID="c52dc1b8b50fe1e3"
REALITY_SPX="/"

SOCKS_LISTEN="127.0.0.1"
SOCKS_PORT="1080"
HTTP_LISTEN="127.0.0.1"
HTTP_PORT="1081"

say() { printf '%s\n' "$*"; }
die() { say "$*"; exit 1; }

need_root() {
  if [[ ${EUID:-0} -ne 0 ]]; then
    die "Run as root (sudo)."
  fi
}

ensure_python3() {
  if command -v python3 >/dev/null 2>&1; then
    return 0
  fi
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y python3 >/dev/null 2>&1 || true
  fi
  command -v python3 >/dev/null 2>&1 || die "python3 not found."
}

ensure_curl() {
  if command -v curl >/dev/null 2>&1; then
    return 0
  fi
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y curl ca-certificates >/dev/null 2>&1 || true
  fi
  command -v curl >/dev/null 2>&1 || die "curl not found."
}

write_remnanode_proxy_env() {
  mkdir -p "$XRAY_DIR"
  cat > "${XRAY_DIR}/remnanode-proxy.env" <<EOF
HTTP_PROXY=http://${SOCKS_LISTEN}:${HTTP_PORT}
HTTPS_PROXY=http://${SOCKS_LISTEN}:${HTTP_PORT}
http_proxy=http://${SOCKS_LISTEN}:${HTTP_PORT}
https_proxy=http://${SOCKS_LISTEN}:${HTTP_PORT}
ALL_PROXY=socks5://${SOCKS_LISTEN}:${SOCKS_PORT}
NO_PROXY=localhost,127.0.0.1
no_proxy=localhost,127.0.0.1
EOF
}

ensure_docker() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    return 0
  fi

  echo "Docker is not available. Installing/starting Docker..."

  # Minimal deps for get.docker.com
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y ca-certificates curl >/dev/null 2>&1 || true
  fi

  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh

  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now docker >/dev/null 2>&1 || true
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker install failed (docker binary not found)."
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Docker is installed but not working (docker info failed)."
    exit 1
  fi
}

ensure_docker_compose() {
  docker compose version >/dev/null 2>&1 || die "docker compose not available (upgrade Docker / CLI)."
}

ensure_base_installer() {
  if [[ -f "$BASE_INSTALL_SCRIPT" ]]; then
    return 0
  fi

  if [[ ! -f "$BASE_INSTALL_SCRIPT" ]]; then
    # If user runs this script from a directory without install_node.sh,
    # fetch base installer automatically.
    if [[ -f "./install_node.sh" ]]; then
      BASE_INSTALL_SCRIPT="./install_node.sh"
    else
      say "Base installer not found. Downloading from $BASE_INSTALL_URL ..."
      curl -fsSL --retry 3 --retry-delay 2 "$BASE_INSTALL_URL" -o "$BASE_INSTALL_SCRIPT"
    fi
  fi

  if [[ ! -f "$BASE_INSTALL_SCRIPT" ]]; then
    die "Failed to locate or download base installer: $BASE_INSTALL_SCRIPT"
  fi
}

check_prereqs_install() {
  need_root
  ensure_curl
  ensure_docker
  ensure_docker_compose
  ensure_python3
  ensure_base_installer
}

check_prereqs_edit() {
  need_root
  ensure_curl
  ensure_docker
  ensure_docker_compose
  ensure_python3
  [[ -d "$REMNA_DIR" ]] || die "Not found: $REMNA_DIR"
  [[ -f "$REMNA_DIR/docker-compose.yml" ]] || die "Not found: $REMNA_DIR/docker-compose.yml"
  [[ -f "$XRAY_DIR/config.json" ]] || die "Not found: $XRAY_DIR/config.json (run Install first)"
}

generate_xray_config() {
  mkdir -p "$XRAY_DIR"

  echo "Downloading geosite database (dlc.dat -> geosite.dat)..."
  curl -fsSL --retry 3 --retry-delay 2 "$GEOSITE_URL" -o "$GEOSITE_FILE"

  echo "Downloading geoip database (geoip.dat)..."
  curl -fsSL --retry 3 --retry-delay 2 "$GEOIP_URL" -o "$GEOIP_FILE"

  echo "Generating Xray-core config..."
  export XRAY_DIR
  export VLESS_UUID VLESS_HOST VLESS_PORT VLESS_FLOW REALITY_FP REALITY_SNI REALITY_PBK REALITY_SID REALITY_SPX
  export SOCKS_LISTEN SOCKS_PORT HTTP_LISTEN HTTP_PORT
  python3 - <<'PY'
import json
import os
from pathlib import Path

xray_dir = os.environ["XRAY_DIR"]

uuid = os.environ["VLESS_UUID"]
host = os.environ["VLESS_HOST"]
port = int(os.environ["VLESS_PORT"])
flow = os.environ["VLESS_FLOW"]
fp = os.environ["REALITY_FP"]
sni = os.environ["REALITY_SNI"]
pbk = os.environ["REALITY_PBK"]
sid = os.environ["REALITY_SID"]
spx = os.environ["REALITY_SPX"]

socks_listen = os.environ["SOCKS_LISTEN"]
socks_port = int(os.environ["SOCKS_PORT"])
http_listen = os.environ["HTTP_LISTEN"]
http_port = int(os.environ["HTTP_PORT"])

cfg = {
    "log": {"loglevel": "warning"},
    "inbounds": [
        {
            "tag": "in-socks",
            "listen": socks_listen,
            "port": socks_port,
            "protocol": "socks",
            "auth": "noauth",
            "settings": {
                "udp": True,
                "ip": socks_listen
            },
            "sniffing": {
                "enabled": True,
                "destOverride": ["http", "tls", "quic"],
                "routeOnly": True
            }
        },
        {
            "tag": "in-http",
            "listen": http_listen,
            "port": http_port,
            "protocol": "http",
            "settings": {"allowTransparent": False, "userLevel": 0},
            "sniffing": {
                "enabled": True,
                "destOverride": ["http", "tls", "quic"],
                "routeOnly": True
            }
        }
    ],
    "outbounds": [
        {
            "tag": "VPN",
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": host,
                        "port": port,
                        "users": [
                            {
                                "id": uuid,
                                "encryption": "none",
                                "flow": flow
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "fingerprint": fp,
                    "serverName": sni,
                    "publicKey": pbk,
                    "shortId": sid,
                    "spiderX": spx
                }
            }
        },
        {"tag": "DIRECT", "protocol": "freedom"}
    ],
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "domain": [
                    # Route RU/SU/RF domains directly (reliable; no geosite tag dependency).
                    "regexp:^(.+\\\\.)?ru$",
                    "regexp:^(.+\\\\.)?su$",
                    "regexp:^(.+\\\\.)?xn--p1ai$"
                ],
                "outboundTag": "DIRECT",
                "ruleTag": "direct-ru-tlds"
            },
            {
                "type": "field",
                "ip": ["geoip:private"],
                "outboundTag": "DIRECT",
                "ruleTag": "direct-private"
            },
            {
                "type": "field",
                "ip": ["geoip:ru"],
                "outboundTag": "DIRECT",
                "ruleTag": "direct-geoip-ru"
            }
        ]
    }
}

out_path = Path(xray_dir) / "config.json"
out_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Xray config written: {out_path}")
PY

  echo "Xray config ready."
}

generate_compose_override() {
  cat > "$OVERRIDE_COMPOSE_FILE" <<EOF
services:
  xray-vpn:
    image: ghcr.io/xtls/xray-core:latest
    container_name: xray-vpn
    restart: always
    network_mode: host
    environment:
      XRAY_LOCATION_ASSET: /usr/local/share/xray
    volumes:
      - ./xray-vpn/config.json:/usr/local/etc/xray/config.json:ro
      - ./xray-vpn/geosite.dat:/usr/local/share/xray/geosite.dat:ro
      - ./xray-vpn/geoip.dat:/usr/local/share/xray/geoip.dat:ro
    command: ["run", "-c", "/usr/local/etc/xray/config.json"]

  remnanode:
    # Some compose versions error if override service lacks image/build.
    image: remnawave/node:latest
    env_file:
      - ./xray-vpn/remnanode-proxy.env
EOF
}

apply_vless_to_xray_config() {
  local vless_link="$1"
  python3 - "$XRAY_DIR/config.json" "$vless_link" <<'PY'
import json
import sys
from urllib.parse import urlparse, parse_qs

config_path = sys.argv[1]
link = sys.argv[2].strip()

u = urlparse(link)
if u.scheme.lower() != "vless":
    raise SystemExit("Not a vless:// link")

uuid = u.username
host = u.hostname
port = u.port or 443
qs = parse_qs(u.query)

def q1(key, default=None):
    v = qs.get(key)
    if not v:
        return default
    return v[0]

flow = q1("flow")
fp = q1("fp")
sni = q1("sni")
pbk = q1("pbk")
# sid parameter can be present but empty (e.g. "sid=#Name").
# Treat empty as "no shortId" and actively clear config.
# Some subscription links have `sid` empty or even missing.
# Stale shortId breaks REALITY, so we clear it unless an explicit non-empty sid is provided.
sid = q1("sid", None)
spx = q1("spx", "/")

cfg = json.load(open(config_path, "r", encoding="utf-8"))
vpn = None
for o in cfg.get("outbounds", []):
    if o.get("tag") == "VPN":
        vpn = o
        break
if vpn is None:
    raise SystemExit("Outbound tag VPN not found in config")

vpn.setdefault("settings", {}).setdefault("vnext", [{}])
vnext0 = vpn["settings"]["vnext"][0]
vnext0["address"] = host
vnext0["port"] = int(port)
vnext0.setdefault("users", [{}])
user0 = vnext0["users"][0]
user0["id"] = uuid
user0["encryption"] = "none"
if flow:
    user0["flow"] = flow

ss = vpn.setdefault("streamSettings", {})
ss["network"] = "tcp"
ss["security"] = "reality"
rs = ss.setdefault("realitySettings", {})
if fp:
    rs["fingerprint"] = fp
if sni:
    rs["serverName"] = sni
if pbk:
    rs["publicKey"] = pbk
# Apply / clear shortId explicitly (avoid stale value):
if sid is None or sid == "":
    rs.pop("shortId", None)
else:
    rs["shortId"] = sid
if spx is not None:
    rs["spiderX"] = spx

json.dump(cfg, open(config_path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("UPDATED")
PY
}

pick_vless_from_input() {
  local input="$1"
  python3 - "$input" <<'PY'
import base64
import re
import sys
from urllib.parse import unquote

inp = sys.argv[1].strip()

def fetch(url: str) -> str:
    import urllib.request
    with urllib.request.urlopen(url, timeout=20) as r:
        return r.read().decode("utf-8", "ignore")

text = inp
if re.match(r"^https?://", inp, re.I):
    text = fetch(inp)

raw = text.strip().encode()

def maybe_b64decode(b: bytes):
    for fn in (base64.b64decode, base64.urlsafe_b64decode):
        try:
            dec = fn(b + b"===")
            if b"vless://" in dec:
                return dec.decode("utf-8", "ignore")
        except Exception:
            pass
    return None

decoded = None
if re.fullmatch(rb"[A-Za-z0-9+/=\r\n_-]+", raw) and b"vless://" not in raw:
    decoded = maybe_b64decode(raw)
if decoded is not None:
    text = decoded

links = []
for line in text.splitlines():
    for m in re.finditer(r"(vless://[^\s]+)", line.strip()):
        links.append(m.group(1))

seen = set()
vless = []
for l in links:
    if l not in seen:
        seen.add(l)
        vless.append(l)

if not vless:
    print("NO_VLESS")
    sys.exit(0)

def label(link: str) -> str:
    if "#" in link:
        frag = link.split("#", 1)[1]
        try:
            frag = unquote(frag)
        except Exception:
            pass
        frag = frag.strip()
        if frag:
            return frag
    m = re.search(r"@([^/?#]+)", link)
    return m.group(1) if m else link[:60]

for i, l in enumerate(vless, 1):
    print(f"{i}\t{label(l)}\t{l}")
PY
}

restart_xray() {
  cd "$REMNA_DIR"
  docker compose -f docker-compose.yml -f docker-compose.vpn.yml up -d xray-vpn >/dev/null
}

edit_vpn_flow() {
  check_prereqs_edit
  say "Вставьте ссылку подписки (https://...) или vless://..."
  read -r input
  [[ -n "${input:-}" ]] || die "Empty input."

  local list
  list="$(pick_vless_from_input "$input")"
  [[ "$list" != "NO_VLESS" ]] || die "Не найдено vless:// ссылок."

  say ""
  say "Доступные VLESS:"
  echo "$list" | awk -F'\t' '{printf "%s) %s\n", $1, $2}'
  say ""
  read -r -p "Номер: " choice
  [[ "$choice" =~ ^[0-9]+$ ]] || die "Неверный номер."

  local picked
  picked="$(echo "$list" | awk -F'\t' -v n="$choice" '$1==n{print $3; exit}')"
  [[ -n "${picked:-}" ]] || die "Не найдено подключение с номером $choice."

  say "Обновляю xray-vpn конфиг..."
  apply_vless_to_xray_config "$picked"
  restart_xray
  say "Готово. xray-vpn перезапущен."
}

install_flow() {
  check_prereqs_install

  say "Running base installer (install_node.sh)..."
  set +e
  bash "$BASE_INSTALL_SCRIPT"
  base_install_exit_code=$?
  set -e
  if [[ $base_install_exit_code -ne 0 ]]; then
    say "Warning: base installer exited with code $base_install_exit_code. Continuing with VPN setup..."
  fi

  [[ -d "$REMNA_DIR" ]] || die "Expected directory not found: $REMNA_DIR"
  cd "$REMNA_DIR"

  generate_xray_config
  write_remnanode_proxy_env
  generate_compose_override

  say "Starting xray-vpn and applying proxy settings..."
  docker compose -f docker-compose.yml -f docker-compose.vpn.yml up -d
  say "Done."
}

main_menu() {
  need_root
  ensure_curl
  ensure_python3
  ensure_docker
  ensure_docker_compose

  say ""
  say "1) Установить"
  say "2) Редактировать VPN"
  say ""
  read -r -p "Выбор (1-2): " choice
  case "$choice" in
    1) install_flow ;;
    2) edit_vpn_flow ;;
    *) die "Неверный выбор." ;;
  esac
}

main_menu "$@"

