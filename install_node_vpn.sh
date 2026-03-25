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
      echo "Base installer not found. Downloading from $BASE_INSTALL_URL ..."
      curl -fsSL --retry 3 --retry-delay 2 "$BASE_INSTALL_URL" -o "$BASE_INSTALL_SCRIPT"
    fi
  fi

  if [[ ! -f "$BASE_INSTALL_SCRIPT" ]]; then
    echo "Failed to locate or download base installer: $BASE_INSTALL_SCRIPT"
    exit 1
  fi

  ensure_docker

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
                    # Domain-list-community (dlc.dat) groups for Russian destinations.
                    # Names are provided by v2fly/domain-list-community.
                    "geosite:geolocation-ru",
                    "geosite:category-ru"
                ],
                "outboundTag": "DIRECT",
                "ruleTag": "direct-geosite-ru"
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
    command: ["xray", "run", "-c", "/usr/local/etc/xray/config.json"]

  remnanode:
    # Some compose versions error if override service lacks image/build.
    image: remnawave/node:latest
    env_file:
      - ./xray-vpn/remnanode-proxy.env
EOF
}

main() {
  check_prereqs

  echo "Running base installer (install_node.sh)..."
  # The base installer sometimes exits non-zero during the "node check" stage
  # even though containers may already be up. We keep going to finish VPN setup.
  set +e
  bash "$BASE_INSTALL_SCRIPT"
  base_install_exit_code=$?
  set -e
  if [[ $base_install_exit_code -ne 0 ]]; then
    echo "Warning: base installer exited with code $base_install_exit_code. Continuing with VPN setup..."
  fi

  if [[ ! -d "$REMNA_DIR" ]]; then
    echo "Expected directory not found: $REMNA_DIR"
    exit 1
  fi

  cd "$REMNA_DIR"

  generate_xray_config
  write_remnanode_proxy_env
  generate_compose_override

  echo "Starting xray-vpn and applying proxy settings..."
  docker compose -f docker-compose.yml -f docker-compose.vpn.yml up -d

  echo "Done."
  echo "You can check logs:"
  echo "  docker compose -f docker-compose.yml -f docker-compose.vpn.yml logs -f remnanode"
  echo "  docker compose -f docker-compose.yml -f docker-compose.vpn.yml logs -f xray-vpn"
}

main "$@"

