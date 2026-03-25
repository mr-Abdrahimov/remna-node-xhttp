# 🚀 Remnawave Node + xHTTP

<div align="center">

**Автоматическая установка ноды Remnawave с поддержкой xHTTP протокола**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Remnawave](https://img.shields.io/badge/Remnawave-Node-green.svg)](https://github.com/remnawave)
[![xHTTP](https://img.shields.io/badge/Protocol-xHTTP-orange.svg)](https://github.com/XTLS/Xray-core)

</div>

---

## 📋 Содержание

- [Описание](#-описание)
- [Что устанавливается](#-что-устанавливается)
- [Быстрая установка](#-быстрая-установка)
- [Конфигурация профиля в панели](#-конфигурация-профиля-в-панели)
- [Настройка хоста в панели](#-настройка-хоста-в-панели)
- [Настройки xHTTP](#-настройки-xhttp)
- [Дополнительно](#-дополнительно)

---

## 📖 Описание

Этот скрипт автоматизирует установку и настройку ноды **Remnawave** с поддержкой протокола **xHTTP**. 

Включает в себя:
- Установку Docker и зависимостей
- Настройку SSL сертификатов (Cloudflare DNS / ACME HTTP / Gcore DNS)
- Конфигурацию Nginx с Reality и xHTTP
- Автоматическую установку маскировочного сайта
- Комплексную настройку безопасности сервера

---

## 🎯 Что устанавливается

### Основные компоненты:
- ✅ **Docker** и **Docker Compose**
- ✅ **Nginx** (для Reality и xHTTP)
- ✅ **Remnawave Node** (последняя версия)
- ✅ **Certbot** с поддержкой DNS-плагинов
- ✅ **UFW Firewall** с настроенными правилами
- ✅ **Fail2Ban** для защиты SSH
- ✅ **Anti-Ping** защита
- ✅ **BBR** TCP congestion control
- ✅ Случайный HTML шаблон для маскировки

### Автоматическая настройка безопасности:
- 🔒 **UFW**: разрешены только SSH (22), HTTPS (443) и порт ноды
- 🔒 **Fail2Ban**: защита от брутфорса SSH (1 попытка = бан на 12 часов)
- 🔒 **Anti-Ping**: ping доступен только с IP панели
- 🔒 **Автообновления**: unattended-upgrades для системных пакетов

---

## ⚡ Быстрая установка

### Требования:
- **OS**: Debian 11/12 или Ubuntu 22.04/24.04
- **Права**: Root доступ
- **Домен**: Настроенный A-запись, указывающий на IP сервера ноды

### Установка с VPN (xray-vpn)

Этот вариант поднимает дополнительный сервис **`xray-vpn`** и позволяет:
- выбирать апстрим **VLESS+Reality** (из `vless://...` или ссылки подписки)
- перезапускать **`xray-vpn`** после смены VPN (чтобы конфиг точно применился)
- управлять тем, что идёт **напрямую** и что через **VPN**, через routing в профиле Remnawave и `xray-vpn`

Команда:

```bash
curl -fsSL "https://raw.githubusercontent.com/mr-Abdrahimov/remna-xhttp/refs/heads/main/install_node_vpn.sh" -o /root/install_node_vpn.sh
chmod +x /root/install_node_vpn.sh
sudo bash /root/install_node_vpn.sh
```

После запуска появится меню:
- **1) Установить**: установка ноды как обычно + создание/запуск `xray-vpn`
- **2) Редактировать VPN**: вставляете ссылку подписки (`https://...`) или `vless://...`, выбираете нужный VLESS, скрипт обновляет `/opt/remnawave/xray-vpn/config.json` и перезапускает `xray-vpn`

### Перед установкой:
1. Создайте поддомен для ноды (например: `node.example.com`)
2. Настройте A-запись в DNS, чтобы она указывала на IP вашего сервера
3. ⚠️ **Для Reality**: отключите Cloudflare proxy (серая тучка)

### Команда установки:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mr-Abdrahimov/remna-node-xhttp/refs/heads/main/install_node.sh)
```

### Что будет запрошено при установке:

1. **Домен ноды** (например: `node.example.com`)
2. **IP адрес панели** (например: `10.20.30.40`)
3. **Порт ноды** (по умолчанию: `2222`, можно изменить)
4. **Сертификат от панели** (вставьте и нажмите Enter 2 раза)
5. **Метод получения SSL**:
   - Cloudflare DNS (поддерживает wildcard)
   - ACME HTTP-01
   - Gcore DNS (поддерживает wildcard)

---

## 🔧 Конфигурация профиля в панели

<details>
<summary>📄 <b>Дефолтный профиль для ноды с xHTTP</b> (нажмите для раскрытия)</summary>

```json
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
          "privateKey": "ВАШ_ПРИВАТНЫЙ_КЛЮЧ",
          "serverNames": [
            "ВАШ_ДОМЕН_НОДЫ"
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

---

## 🌐 Настройка хоста в панели

После установки ноды необходимо настроить хост в панели Remnawave:

### Основные параметры:

| Параметр | Значение |
|----------|----------|
| **Security Layer** | `TLS (Transport Layer Security)` |
| **ALPN** | `h2,http/1.1` |
| **Отпечаток** | Любой (например: `chrome`, `firefox`) |
| **SNI / Хост** | Ваш домен ноды (например: `node.example.com`) |
| **Путь** | `/xhttppath/` |

---

## 📡 Настройки xHTTP

### Xray JSON Configuration (Raw → xHTTP)

В панели Remnawave в разделе **Xray Json & Raw → xHTTP** вставьте:

```json
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

### Описание параметров:

- **maxConcurrency**: `16-32` - количество одновременных мультиплексных соединений
- **hMaxRequestTimes**: `600-900` - максимальное количество запросов на соединение
- **hMaxReusableSecs**: `1800-3000` - максимальное время повторного использования соединения (в секундах)
- **xPaddingBytes**: `100-1000` - случайный размер паддинга для обфускации трафика
- **scStreamUpServerSecs**: `20-80` - время потоковой передачи на сервер

---

## 🛠️ Дополнительно

### Изменение порта ноды (после установки)

<details>
<summary>Если необходимо изменить порт ноды после установки</summary>

```bash
# Редактируем docker-compose.yml
cd /opt/remnawave/
nano docker-compose.yml

# Найдите строку:
# - NODE_PORT=2222
# Измените на нужный порт, например:
# - NODE_PORT=3333

# Сохраните (Ctrl+O, Enter) и выйдите (Ctrl+X)

# Примените изменения
docker compose up -d

# Обновите правило UFW
ufw delete allow from IP_ПАНЕЛИ to any port 2222
ufw allow from IP_ПАНЕЛИ to any port 3333
ufw reload
```

</details>

### Проверка статуса

```bash
# Статус Docker контейнеров
cd /opt/remnawave && docker compose ps

# Логи ноды
cd /opt/remnawave && docker compose logs -f remnanode

# Логи Nginx
cd /opt/remnawave && docker compose logs -f remnawave-nginx

# Статус UFW
ufw status verbose

# Статус Fail2Ban
sudo fail2ban-client status sshd
```

### Обновление ноды

```bash
cd /opt/remnawave
docker compose pull
docker compose up -d
```

### Переустановка случайного шаблона сайта

```bash
cd /opt/remnawave
rm -rf /var/www/html/*
# Затем запустите функцию randomhtml из скрипта
# или установите шаблон вручную в /var/www/html/
```

---

## 📝 Примечания

- ⚠️ **Важно**: После установки сохраните сертификат от панели в надёжном месте
- 🔐 Fail2Ban банит на **12 часов** после **1 неудачной** попытки входа по SSH
- 🌐 Для Reality обязательно отключите Cloudflare proxy (серая тучка)
- 📊 Порт ноды по умолчанию **2222**, но вы можете указать любой при установке
- 🔄 SSL сертификаты автоматически обновляются через cron каждое воскресенье в 5:00

---

## 🔗 Полезные ссылки

- [Remnawave](https://github.com/remnawave)
- [Xray-core](https://github.com/XTLS/Xray-core)
- [xHTTP Protocol](https://github.com/XTLS/Xray-core/discussions/3711)

---

## 🏷️ Теги

`#remna` `#remnawave` `#remnanode` `#xhttp` `#reality` `#vless` `#xray` `#vpn` `#proxy`

---

<div align="center">

**Создано с ❤️ для сообщества Remnawave**

</div>
