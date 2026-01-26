# remna-node-xhttp

<details>
  <summary>Дефолтный профиль в ремне ↓ </summary>
  
```bash
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      {
        "address": "https://dns.google/dns-query",
        "skipFallback": false
      }
    ],
    "queryStrategy": "UseIPv4"
  },
  "inbounds": [
    {
      "tag": "Steal",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "/dev/shm/nginx.sock",
          "show": false,
          "xver": 1,
          "spiderX": "",
          "shortIds": [
            "7be1e9c243451b14"
          ],
          "privateKey": "K-KQYLqDXqPDF_rTZO8ewpEe_k9lbCdCVGXcglF7ZSo",
          "serverNames": [
            "aeza-node.avtlk.ru"
          ]
        }
      }
    },
    {
      "tag": "XHTTP",
      "listen": "/dev/shm/xrxh.socket,0666",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "fallbacks": [],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "streamSettings": {
        "network": "xhttp",
        "xhttpSettings": {
          "mode": "auto",
          "path": "/xhttppath/",
          "extra": {
            "noSSEHeader": true,
            "xPaddingBytes": "100-1000",
            "scMaxBufferedPosts": 30,
            "scMaxEachPostBytes": 1000000,
            "scStreamUpServerSecs": "20-80"
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      "tag": "BLOCK",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "rules": [
      {
        "ip": [
          "geoip:private"
        ],
        "type": "field",
        "outboundTag": "BLOCK"
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "BLOCK"
      }
    ]
  }
}
```

</details>


Установка node + nginx + xhttp + защита
```bash
bash <(curl -Ls https://raw.githubusercontent.com/mr-Abdrahimov/remna-node-xhttp/refs/heads/main/install_node.sh)
```

### Настройка хоста в ремне
```
Security Layer: TLS (Transport Layer Security)
ALPN: h2,http/1.1
Отпечаток: любой
SNI, Хост (свой поддомен): node.example.ru
```

Путь
```bash
/xhttppath/
```
Xray Json & Raw -> xHTTP
```bash
{
  "xmux": {
    "cMaxReuseTimes": 0,
    "maxConcurrency": "16-32",
    "maxConnections": 0,
    "hKeepAlivePeriod": 0,
    "hMaxRequestTimes": "600-900",
    "hMaxReusableSecs": "1800-3000"
  },
  "noGRPCHeader": false,
  "xPaddingBytes": "100-1000",
  "scMaxEachPostBytes": 1000000,
  "scMinPostsIntervalMs": 30,
  "scStreamUpServerSecs": "20-80"
}
```





<details>
  <summary>Правим docker-compose ноды в случае если необходимо сменить порт ноды ↓ </summary>
  
```bash
cd /opt/remnawave/ && nano docker-compose.yml && docker compose up -d
```

</details>



<details>
  <summary>↓ Выполните следующую команду для закрытия всех доступов, пингов и тд:</summary>

```bash
#!/bin/bash

# Запрос данных
echo "=== Настройка безопасности ==="
read -p "Введите IP хосты с ремной для разрешения (например, 0.0.0.0): " ALLOW_IP
read -p "Введите порт ноды для разрешения (например, 2222): " ALLOW_PORT

echo ""
echo "IP: $ALLOW_IP"
echo "Порт: $ALLOW_PORT"
echo ""
echo "Нажмите ENTER для подтверждения или Ctrl+C для отмены"
read DUMMY

# Включаем UFW
echo "Включаем UFW..."
ufw enable
ufw allow OpenSSH
ufw allow 443
ufw allow from "$ALLOW_IP" to any port "$ALLOW_PORT"

# Включаем защиту SSH
echo "Устанавливаем Fail2Ban..."
sudo apt install fail2ban -y
cat > /etc/fail2ban/jail.d/jail.local << EOF
[DEFAULT]
ignoreip=
[sshd]
enabled=true
findtime=120
maxretry=1
bantime=43200
EOF

systemctl restart fail2ban
systemctl status fail2ban
fail2ban-client status sshd

# Выключаем ping сервера (с исключением)
echo "Настраиваем Anti-Ping..."
RULE1="-A ufw-before-input -s $ALLOW_IP -p icmp --icmp-type echo-request -j ACCEPT"
RULE2="-A ufw-before-input -p icmp --icmp-type echo-request -j DROP"
FILE="/etc/ufw/before.rules"

if ! grep -q "$RULE1" "$FILE"; then
    sudo sed -i "/# End required lines/i $RULE1" "$FILE"
    echo "Разрешение ping для $ALLOW_IP добавлено"
fi
if ! grep -q "$RULE2" "$FILE"; then
    sudo sed -i "/# End required lines/i $RULE2" "$FILE"
    echo "Блокировка ping для остальных добавлена"
fi

sudo ufw reload

echo ""
echo "=== ГОТОВО! ==="
echo "Проверьте:"
echo "ufw status"
echo "sudo fail2ban-client status sshd"
```

</details>
