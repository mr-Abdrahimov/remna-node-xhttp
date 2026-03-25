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
DOMAIN_LIST_URL="https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-raw.lst"
DOMAIN_LIST_FILE="${XRAY_DIR}/inside-raw.lst"

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

check_prereqs() {
  if [[ $EUID -ne 0 ]]; then
    echo "Run as root (sudo)."
    exit 1
  fi

  if [[ ! -f "$BASE_INSTALL_SCRIPT" ]]; then
    # If user runs this script from a directory without install_node.sh,
    # fetch base installer automatically.
    if [[ -f "./install_node.sh" ]]; then
      BASE_INSTALL_SCRIPT="./install_node.sh"
    else
      echo "Base installer not found locally. Downloading..."
      curl -fsSL "$BASE_INSTALL_URL" -o "$BASE_INSTALL_SCRIPT"
    fi
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker not found."
    exit 1
  fi

  if ! docker compose version >/dev/null 2>&1; then
    echo "docker compose not available (upgrade Docker / CLI)."
    exit 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl not found."
    exit 1
  fi
}

generate_xray_config() {
  mkdir -p "$XRAY_DIR"

  echo "Downloading domain list..."
  curl -fsSL "$DOMAIN_LIST_URL" -o "$DOMAIN_LIST_FILE"

  echo "Generating Xray-core config..."
  export DOMAIN_LIST_FILE XRAY_DIR
  export VLESS_UUID VLESS_HOST VLESS_PORT VLESS_FLOW REALITY_FP REALITY_SNI REALITY_PBK REALITY_SID REALITY_SPX
  export SOCKS_LISTEN SOCKS_PORT HTTP_LISTEN HTTP_PORT
  python3 - <<'PY'
import json
import os
import re
from pathlib import Path

domain_list_file = os.environ["DOMAIN_LIST_FILE"]
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

domains = set()
with open(domain_list_file, "r", encoding="utf-8", errors="ignore") as f:
    for raw in f:
        d = raw.strip()
        if not d or d.startswith("#"):
            continue
        # The list may contain leading dots (e.g. ".ua"); normalize them.
        d = d.lstrip(".")
        if not d:
            continue
        # Basic sanity: allow only typical domain characters.
        if not re.match(r"^[A-Za-z0-9.-]+$", d):
            continue
        domains.add(d)

domains_list = sorted(domains)
domain_matchers = [f"domain:{d}" for d in domains_list]

cfg = {
    "log": {"loglevel": "warning"},
    "inbounds": [
        {
            "tag": "in-socks",
            "listen": socks_listen,
            "port": socks_port,
            "protocol": "socks",
            "auth": "noauth",
            "settings": {"udp": False},
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
        {"tag": "DIRECT", "protocol": "freedom"},
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
        }
    ],
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "domain": domain_matchers,
                "outboundTag": "VPN"
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
    volumes:
      - ./xray-vpn/config.json:/usr/local/etc/xray/config.json:ro

  remnanode:
    environment:
      HTTP_PROXY: "http://${SOCKS_LISTEN}:${HTTP_PORT}"
      HTTPS_PROXY: "http://${SOCKS_LISTEN}:${HTTP_PORT}"
      http_proxy: "http://${SOCKS_LISTEN}:${HTTP_PORT}"
      https_proxy: "http://${SOCKS_LISTEN}:${HTTP_PORT}"
      ALL_PROXY: "socks5://${SOCKS_LISTEN}:${SOCKS_PORT}"
      no_proxy: "localhost,127.0.0.1"
      NO_PROXY: "localhost,127.0.0.1"
EOF
}

main() {
  check_prereqs

  echo "Running base installer (install_node.sh)..."
  bash "$BASE_INSTALL_SCRIPT"

  if [[ ! -d "$REMNA_DIR" ]]; then
    echo "Expected directory not found: $REMNA_DIR"
    exit 1
  fi

  cd "$REMNA_DIR"

  generate_xray_config
  generate_compose_override

  echo "Starting xray-vpn and applying proxy settings..."
  docker compose -f docker-compose.yml -f docker-compose.vpn.yml up -d

  echo "Done."
  echo "You can check logs:"
  echo "  docker compose -f docker-compose.yml -f docker-compose.vpn.yml logs -f remnanode"
  echo "  docker compose -f docker-compose.yml -f docker-compose.vpn.yml logs -f xray-vpn"
}

main "$@"

