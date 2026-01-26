#!/bin/bash

# Скрипт для установки только ноды Remnawave
# Версия: 1.0.0

DIR_REMNAWAVE="/usr/local/remnawave_reverse/"
LOGFILE="${DIR_REMNAWAVE}install.log"

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_WHITE="\033[1;37m"
COLOR_RED="\033[1;31m"

# Русские тексты
declare -A LANG=(
    [ERROR_ROOT]="Скрипт нужно запускать с правами root"
    [ERROR_OS]="Поддержка только Debian 11/12 и Ubuntu 22.04/24.04"
    [INSTALL_PACKAGES]="Установка необходимых пакетов..."
    [ERROR_UPDATE_LIST]="Ошибка: Не удалось обновить список пакетов"
    [ERROR_INSTALL_PACKAGES]="Ошибка: Не удалось установить необходимые пакеты"
    [ERROR_INSTALL_CRON]="Ошибка: Не удалось установить cron"
    [ERROR_START_CRON]="Ошибка: Не удалось запустить cron"
    [ERROR_DOWNLOAD_DOCKER_KEY]="Ошибка: Не удалось загрузить ключ Docker"
    [ERROR_INSTALL_DOCKER]="Ошибка: Не удалось установить Docker"
    [ERROR_DOCKER_NOT_INSTALLED]="Ошибка: Docker не установлен"
    [ERROR_START_DOCKER]="Ошибка: Не удалось запустить Docker"
    [ERROR_ENABLE_DOCKER]="Ошибка: Не удалось включить автозапуск Docker"
    [ERROR_DOCKER_NOT_WORKING]="Ошибка: Docker не работает корректно"
    [ERROR_CONFIGURE_UFW]="Ошибка: Не удалось настроить UFW"
    [ERROR_CONFIGURE_UPGRADES]="Ошибка: Не удалось настроить unattended-upgrades"
    [ERROR_INSTALL_CERTBOT]="Ошибка: Не удалось установить certbot"
    [SUCCESS_INSTALL]="Все пакеты успешно установлены"
    [INSTALLING_NODE]="Установка ноды"
    [SELFSTEAL]="Введите selfsteal домен для ноды, который указали при установке панели:"
    [PANEL_IP_PROMPT]="Введите IP адрес панели, чтобы установить соединение между панелью и ноды:"
    [IP_ERROR]="Введите корректный IP-адрес в формате X.X.X.X (например, 192.168.1.1)"
    [NODE_PORT_PROMPT]="Введите порт для ноды (по умолчанию 2222):"
    [PORT_ERROR]="Введите корректный порт (число от 1 до 65535)"
    [CERT_PROMPT]="Введите сертификат, полученный от панели (вставьте содержимое и 2 раза нажмите Enter):"
    [CERT_CONFIRM]="Вы уверены, что сертификат правильный? (y/n):"
    [ABORT_MESSAGE]="Установка прервана пользователем"
    [CHECK_DOMAIN_IP_FAIL]="Не удалось определить IP домена или IP сервера"
    [CHECK_DOMAIN_IP_FAIL_INSTRUCTION]="Домен %s указывает на неизвестный IP.\nУбедитесь, что:\n1. DNS настроен правильно\n2. IP сервера: %s"
    [CHECK_DOMAIN_MISMATCH]="Домен %s указывает на %s, но IP сервера: %s"
    [CHECK_DOMAIN_MISMATCH_INSTRUCTION]="Убедитесь, что DNS настроен правильно"
    [CHECK_DOMAIN_CLOUDFLARE]="Домен %s использует Cloudflare proxy (IP: %s)"
    [CHECK_DOMAIN_CLOUDFLARE_INSTRUCTION]="Для selfsteal домена необходимо отключить Cloudflare proxy (серая тучка)"
    [WARNING_LABEL]="ВНИМАНИЕ:"
    [CONFIRM_PROMPT]="Введите 'y' для продолжения или 'n' для выхода (y/n):"
    [CHECK_CERTS]="Проверка сертификатов..."
    [REQUIRED_DOMAINS]="Необходимые домены для проверки:"
    [CERT_NOT_FOUND]="Сертификаты не найдены для"
    [CERT_FOUND]="Сертификаты найдены в /etc/letsencrypt/live/"
    [WILDCARD_CERT_FOUND]="Найден wildcard сертификат для"
    [FOR_DOMAIN]="для домена"
    [CERTS_SKIPPED]="Сертификаты уже установлены, пропускаем генерацию"
    [CERT_METHOD_PROMPT]="Выберите способ получения SSL сертификатов:"
    [CERT_METHOD_CF]="Cloudflare DNS (рекомендуется, поддерживает wildcard)"
    [CERT_METHOD_ACME]="ACME HTTP-01 (без wildcard)"
    [CERT_METHOD_GCORE]="Gcore DNS (поддерживает wildcard)"
    [EXIT]="Выход"
    [CERT_METHOD_CHOOSE]="Выберите способ (0-3):"
    [CERT_INVALID_CHOICE]="Неверный выбор. Выберите 0-3."
    [EMAIL_PROMPT]="Введите email для уведомлений Let's Encrypt:"
    [GENERATING_CERTS]="Генерация сертификатов для %s..."
    [ENTER_CF_TOKEN]="Введите Cloudflare API токен или глобальный ключ:"
    [ENTER_CF_EMAIL]="Введите зарегистрированную почту Cloudflare:"
    [CF_VALIDATING]="Cloudflare API ключ и email валидны"
    [CF_INVALID]="Неверный Cloudflare API ключ или email после %d попыток."
    [CF_INVALID_ATTEMPT]="Неверный Cloudflare API ключ или email. Попытка %d из %d."
    [ENTER_GCORE_TOKEN]="Введите API‑токен Gcore:"
    [ERROR_INSTALL_GCORE_PLUGIN]="Не удалось установить плагин certbot-dns-gcore"
    [INVALID_CERT_METHOD]="Неверный метод сертификата"
    [CERT_GENERATION_FAILED]="Не удалось сгенерировать сертификат для"
    [ADDING_CRON_FOR_EXISTING_CERTS]="Добавление cron-задачи для автообновления сертификатов..."
    [CERT_EXPIRY_SOON]="Сертификат истекает через"
    [DAYS]="дней"
    [UPDATING_CRON]="Обновление cron-задачи..."
    [CRON_ALREADY_EXISTS]="Cron-задача для обновления сертификатов уже существует"
    [UPDATED_RENEW_AUTH]="Обновлен хук обновления сертификата"
    [WAITING]="Пожалуйста, подождите..."
    [RANDOM_TEMPLATE]="Установка случайного шаблона для маскировочного сайта"
    [DOWNLOAD_FAIL]="Ошибка загрузки, повторная попытка..."
    [UNPACK_ERROR]="Ошибка распаковки архива"
    [SELECT_TEMPLATE]="Выбран шаблон:"
    [TEMPLATE_COPY]="Шаблон скопирован в /var/www/html/"
    [FAILED_TO_MODIFY_HTML_FILES]="Не удалось модифицировать HTML файлы"
    [STARTING_NODE]="Запуск ноды"
    [NODE_CHECK]="Проверка подключения ноды для %s..."
    [NODE_ATTEMPT]="Попытка %d из %d..."
    [NODE_UNAVAILABLE]="Нода недоступна на попытке %d."
    [NODE_LAUNCHED]="Нода успешно подключена!"
    [NODE_NOT_CONNECTED]="Нода не подключена после %d попыток!"
    [CHECK_CONFIG]="Проверьте конфигурацию или перезапустите панель."
    [ERROR_PARSING_CERT]="Ошибка парсинга сертификата"
)

question() {
    echo -e "${COLOR_GREEN}[?]${COLOR_RESET} ${COLOR_YELLOW}$*${COLOR_RESET}"
}

reading() {
    read -rp " $(question "$1")" "$2"
}

error() {
    echo -e "${COLOR_RED}$*${COLOR_RESET}"
    exit 1
}

check_os() {
    if ! grep -q "bullseye" /etc/os-release && ! grep -q "bookworm" /etc/os-release && ! grep -q "jammy" /etc/os-release && ! grep -q "noble" /etc/os-release && ! grep -q "trixie" /etc/os-release; then
        error "${LANG[ERROR_OS]}"
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "${LANG[ERROR_ROOT]}"
    fi
}

log_clear() {
    sed -i -e 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$LOGFILE"
}

spinner() {
    local pid=$1
    local text=$2

    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local text_code="$COLOR_GREEN"
    local bg_code=""
    local effect_code="\033[1m"
    local delay=0.1
    local reset_code="$COLOR_RESET"

    printf "${effect_code}${text_code}${bg_code}%s${reset_code}" "$text" > /dev/tty

    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r${effect_code}${text_code}${bg_code}[%s] %s${reset_code}" "$(echo -n "${spinstr:$i:1}")" "$text" > /dev/tty
            sleep $delay
        done
    done

    printf "\r\033[K" > /dev/tty
}

add_cron_rule() {
    local rule="$1"
    local logged_rule="${rule} >> ${DIR_REMNAWAVE}cron_jobs.log 2>&1"

    if ! crontab -u root -l > /dev/null 2>&1; then
        crontab -u root -l 2>/dev/null | crontab -u root -
    fi

    if ! crontab -u root -l | grep -Fxq "$logged_rule"; then
        (crontab -u root -l 2>/dev/null; echo "$logged_rule") | crontab -u root -
    fi
}

install_packages() {
    echo -e "${COLOR_YELLOW}${LANG[INSTALL_PACKAGES]}${COLOR_RESET}"
    
    if ! apt-get update -y; then
        echo -e "${COLOR_RED}${LANG[ERROR_UPDATE_LIST]}${COLOR_RESET}" >&2
        return 1
    fi

    if ! apt-get install -y ca-certificates curl jq ufw wget gnupg unzip nano dialog git certbot python3-certbot-dns-cloudflare unattended-upgrades locales dnsutils coreutils grep gawk python3-pip; then
        echo -e "${COLOR_RED}${LANG[ERROR_INSTALL_PACKAGES]}${COLOR_RESET}" >&2
        return 1
    fi

    if ! dpkg -l | grep -q '^ii.*cron '; then
        if ! apt-get install -y cron; then
            echo -e "${COLOR_RED}${LANG[ERROR_INSTALL_CRON]}" "${COLOR_RESET}" >&2
            return 1
        fi
    fi

    if ! systemctl is-active --quiet cron; then
        if ! systemctl start cron; then
            echo -e "${COLOR_RED}${LANG[ERROR_START_CRON]}${COLOR_RESET}" >&2
            return 1
        fi
    fi
    if ! systemctl is-enabled --quiet cron; then
        if ! systemctl enable cron; then
            echo -e "${COLOR_RED}${LANG[ERROR_START_CRON]}${COLOR_RESET}" >&2
            return 1
        fi
    fi

    if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
        echo -e "${COLOR_YELLOW}Installing Docker via get.docker.com...${COLOR_RESET}"

        if ! curl -fsSL https://get.docker.com -o /tmp/get-docker.sh; then
            echo -e "${COLOR_RED}${LANG[ERROR_DOWNLOAD_DOCKER_KEY]}${COLOR_RESET}" >&2
            return 1
        fi

        if ! sh /tmp/get-docker.sh; then
            echo -e "${COLOR_RED}${LANG[ERROR_INSTALL_DOCKER]}${COLOR_RESET}" >&2
            return 1
        fi
    fi

    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${COLOR_RED}${LANG[ERROR_DOCKER_NOT_INSTALLED]}${COLOR_RESET}" >&2
        return 1
    fi

    if ! systemctl is-active --quiet docker; then
        if ! systemctl start docker; then
            echo -e "${COLOR_RED}${LANG[ERROR_START_DOCKER]}${COLOR_RESET}" >&2
            return 1
        fi
    fi

    if ! systemctl is-enabled --quiet docker; then
        if ! systemctl enable docker; then
            echo -e "${COLOR_RED}${LANG[ERROR_ENABLE_DOCKER]}${COLOR_RESET}" >&2
            return 1
        fi
    fi

    if ! docker info >/dev/null 2>&1; then
        echo -e "${COLOR_RED}${LANG[ERROR_DOCKER_NOT_WORKING]}${COLOR_RESET}" >&2
        return 1
    fi

    # BBR
    if ! grep -q "net.core.default_qdisc = fq" /etc/sysctl.conf; then
        echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    fi
    if ! grep -q "net.ipv4.tcp_congestion_control = bbr" /etc/sysctl.conf; then
        echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    fi
    sysctl -p >/dev/null

    # UFW
    if ! ufw allow 22/tcp comment 'SSH' || ! ufw allow 443/tcp comment 'HTTPS' || ! ufw --force enable; then
        echo -e "${COLOR_RED}${LANG[ERROR_CONFIGURE_UFW]}${COLOR_RESET}" >&2
        return 1
    fi

    # Unattended-upgrades
    echo 'Unattended-Upgrade::Mail "root";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
    if ! dpkg-reconfigure -f noninteractive unattended-upgrades || ! systemctl restart unattended-upgrades; then
        echo -e "${COLOR_RED}${LANG[ERROR_CONFIGURE_UPGRADES]}" "${COLOR_RESET}" >&2
        return 1
    fi

    touch ${DIR_REMNAWAVE}install_packages
    echo -e "${COLOR_GREEN}${LANG[SUCCESS_INSTALL]}${COLOR_RESET}"
    clear
}

extract_domain() {
    local SUBDOMAIN=$1
    echo "$SUBDOMAIN" | awk -F'.' '{if (NF > 2) {print $(NF-1)"."$NF} else {print $0}}'
}

check_domain() {
    local domain="$1"
    local show_warning="${2:-true}"
    local allow_cf_proxy="${3:-true}"

    local domain_ip=$(dig +short A "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)
    local server_ip=$(curl -s -4 ifconfig.me || curl -s -4 api.ipify.org || curl -s -4 ipinfo.io/ip)

    if [ -z "$domain_ip" ] || [ -z "$server_ip" ]; then
        if [ "$show_warning" = true ]; then
            echo -e "${COLOR_YELLOW}${LANG[WARNING_LABEL]}${COLOR_RESET}"
            echo -e "${COLOR_RED}${LANG[CHECK_DOMAIN_IP_FAIL]}${COLOR_RESET}"
            printf "${COLOR_YELLOW}${LANG[CHECK_DOMAIN_IP_FAIL_INSTRUCTION]}${COLOR_RESET}\n" "$domain" "$server_ip"
            reading "${LANG[CONFIRM_PROMPT]}" confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                return 2
            fi
        fi
        return 1
    fi

    local cf_ranges=$(curl -s https://www.cloudflare.com/ips-v4)
    local cf_array=()
    if [ -n "$cf_ranges" ]; then
        IFS=$'\n' read -r -d '' -a cf_array <<<"$cf_ranges"
    fi

    local ip_in_cloudflare=false
    local IFS='.'
    read -r a b c d <<<"$domain_ip"
    local domain_ip_int=$(( (a << 24) + (b << 16) + (c << 8) + d ))

    if [ ${#cf_array[@]} -gt 0 ]; then
        for cidr in "${cf_array[@]}"; do
            if [[ -z "$cidr" ]]; then
                continue
            fi
            local network=$(echo "$cidr" | cut -d'/' -f1)
            local mask=$(echo "$cidr" | cut -d'/' -f2)
            read -r a b c d <<<"$network"
            local network_int=$(( (a << 24) + (b << 16) + (c << 8) + d ))
            local mask_bits=$(( 32 - mask ))
            local range_size=$(( 1 << mask_bits ))
            local min_ip_int=$network_int
            local max_ip_int=$(( network_int + range_size - 1 ))

            if [ "$domain_ip_int" -ge "$min_ip_int" ] && [ "$domain_ip_int" -le "$max_ip_int" ]; then
                ip_in_cloudflare=true
                break
            fi
        done
    fi

    if [ "$domain_ip" = "$server_ip" ]; then
        return 0
    elif [ "$ip_in_cloudflare" = true ]; then
        if [ "$allow_cf_proxy" = true ]; then
            return 0
        else
            if [ "$show_warning" = true ]; then
                echo -e "${COLOR_YELLOW}${LANG[WARNING_LABEL]}${COLOR_RESET}"
                printf "${COLOR_RED}${LANG[CHECK_DOMAIN_CLOUDFLARE]}${COLOR_RESET}\n" "$domain" "$domain_ip"
                echo -e "${COLOR_YELLOW}${LANG[CHECK_DOMAIN_CLOUDFLARE_INSTRUCTION]}${COLOR_RESET}"
                reading "${LANG[CONFIRM_PROMPT]}" confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    return 1
                else
                    return 2
                fi
            fi
            return 1
        fi
    else
        if [ "$show_warning" = true ]; then
            echo -e "${COLOR_YELLOW}${LANG[WARNING_LABEL]}${COLOR_RESET}"
            printf "${COLOR_RED}${LANG[CHECK_DOMAIN_MISMATCH]}${COLOR_RESET}\n" "$domain" "$domain_ip" "$server_ip"
            echo -e "${COLOR_YELLOW}${LANG[CHECK_DOMAIN_MISMATCH_INSTRUCTION]}${COLOR_RESET}"
            reading "${LANG[CONFIRM_PROMPT]}" confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                return 1
            else
                return 2
            fi
        fi
        return 1
    fi

    return 0
}

is_wildcard_cert() {
    local domain=$1
    local cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"

    if [ ! -f "$cert_path" ]; then
        return 1
    fi

    if openssl x509 -in "$cert_path" -text -noout | grep -q "DNS:\*\.$domain"; then
        return 0
    else
        return 1
    fi
}

check_certificates() {
    local DOMAIN=$1
    local cert_dir="/etc/letsencrypt/live"

    if [ ! -d "$cert_dir" ]; then
        echo -e "${COLOR_RED}${LANG[CERT_NOT_FOUND]} $DOMAIN${COLOR_RESET}"
        return 1
    fi

    local live_dir=$(find "$cert_dir" -maxdepth 1 -type d -name "${DOMAIN}*" 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$live_dir" ] && [ -d "$live_dir" ]; then
        local files=("cert.pem" "chain.pem" "fullchain.pem" "privkey.pem")
        for file in "${files[@]}"; do
            local file_path="$live_dir/$file"
            if [ ! -f "$file_path" ]; then
                echo -e "${COLOR_RED}${LANG[CERT_NOT_FOUND]} $DOMAIN (missing $file)${COLOR_RESET}"
                return 1
            fi
        done
        echo -e "${COLOR_GREEN}${LANG[CERT_FOUND]}$(basename "$live_dir")${COLOR_RESET}"
        return 0
    fi

    local base_domain=$(extract_domain "$DOMAIN")
    if [ "$base_domain" != "$DOMAIN" ]; then
        live_dir=$(find "$cert_dir" -maxdepth 1 -type d -name "${base_domain}*" 2>/dev/null | sort -V | tail -n 1)
        if [ -n "$live_dir" ] && [ -d "$live_dir" ] && is_wildcard_cert "$base_domain"; then
            echo -e "${COLOR_GREEN}${LANG[WILDCARD_CERT_FOUND]}$base_domain ${LANG[FOR_DOMAIN]} $DOMAIN${COLOR_RESET}"
            return 0
        fi
    fi

    echo -e "${COLOR_RED}${LANG[CERT_NOT_FOUND]} $DOMAIN${COLOR_RESET}"
    return 1
}

check_api() {
    local attempts=3
    local attempt=1

    while [ $attempt -le $attempts ]; do
        if [[ $CLOUDFLARE_API_KEY =~ [A-Z] ]]; then
            api_response=$(curl --silent --request GET --url https://api.cloudflare.com/client/v4/zones --header "Authorization: Bearer ${CLOUDFLARE_API_KEY}" --header "Content-Type: application/json")
        else
            api_response=$(curl --silent --request GET --url https://api.cloudflare.com/client/v4/zones --header "X-Auth-Key: ${CLOUDFLARE_API_KEY}" --header "X-Auth-Email: ${CLOUDFLARE_EMAIL}" --header "Content-Type: application/json")
        fi

        if echo "$api_response" | grep -q '"success":true'; then
            echo -e "${COLOR_GREEN}${LANG[CF_VALIDATING]}${COLOR_RESET}"
            return 0
        else
            echo -e "${COLOR_RED}$(printf "${LANG[CF_INVALID_ATTEMPT]}" "$attempt" "$attempts")${COLOR_RESET}"
            if [ $attempt -lt $attempts ]; then
                reading "${LANG[ENTER_CF_TOKEN]}" CLOUDFLARE_API_KEY
                reading "${LANG[ENTER_CF_EMAIL]}" CLOUDFLARE_EMAIL
            fi
            attempt=$((attempt + 1))
        fi
    done
    error "$(printf "${LANG[CF_INVALID]}" "$attempts")"
}

get_certificates() {
    local DOMAIN=$1
    local CERT_METHOD=$2
    local LETSENCRYPT_EMAIL=$3
    local BASE_DOMAIN=$(extract_domain "$DOMAIN")
    local WILDCARD_DOMAIN="*.$BASE_DOMAIN"

    printf "${COLOR_YELLOW}${LANG[GENERATING_CERTS]}${COLOR_RESET}\n" "$DOMAIN"

    case $CERT_METHOD in
        1)
            # Cloudflare API (DNS-01 support wildcard)
            reading "${LANG[ENTER_CF_TOKEN]}" CLOUDFLARE_API_KEY
            reading "${LANG[ENTER_CF_EMAIL]}" CLOUDFLARE_EMAIL

            check_api

            mkdir -p ~/.secrets/certbot
            if [[ $CLOUDFLARE_API_KEY =~ [A-Z] ]]; then
                cat > ~/.secrets/certbot/cloudflare.ini <<EOL
dns_cloudflare_api_token = $CLOUDFLARE_API_KEY
EOL
            else
                cat > ~/.secrets/certbot/cloudflare.ini <<EOL
dns_cloudflare_email = $CLOUDFLARE_EMAIL
dns_cloudflare_api_key = $CLOUDFLARE_API_KEY
EOL
            fi
            chmod 600 ~/.secrets/certbot/cloudflare.ini

            certbot certonly \
                --dns-cloudflare \
                --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
                --dns-cloudflare-propagation-seconds 60 \
                -d "$BASE_DOMAIN" \
                -d "$WILDCARD_DOMAIN" \
                --email "$CLOUDFLARE_EMAIL" \
                --agree-tos \
                --non-interactive \
                --key-type ecdsa \
                --elliptic-curve secp384r1
            ;;
        2)
            # ACME HTTP-01 (without wildcard)
            ufw allow 80/tcp comment 'HTTP for ACME challenge' > /dev/null 2>&1

            certbot certonly \
                --standalone \
                -d "$DOMAIN" \
                --email "$LETSENCRYPT_EMAIL" \
                --agree-tos \
                --non-interactive \
                --http-01-port 80 \
                --key-type ecdsa \
                --elliptic-curve secp384r1

            ufw delete allow 80/tcp > /dev/null 2>&1
            ufw reload > /dev/null 2>&1
            ;;
        3)
            # Gcore DNS-01 (wildcard)

            if ! certbot plugins 2>/dev/null | grep -q "dns-gcore"; then
                echo -e "${COLOR_YELLOW}Installing certbot-dns-gcore plugin...${COLOR_RESET}"
                
                if python3 -m pip install --help 2>&1 | grep -q "break-system-packages"; then
                    python3 -m pip install --break-system-packages certbot-dns-gcore >/dev/null 2>&1
                else
                python3 -m pip install certbot-dns-gcore >/dev/null 2>&1
                fi
                    
                if certbot plugins 2>/dev/null | grep -q "dns-gcore"; then
                    echo -e "${COLOR_GREEN}Plugin installed successfully.${COLOR_RESET}"
                else
                    echo -e "${COLOR_RED}${LANG[ERROR_INSTALL_GCORE_PLUGIN]}${COLOR_RESET}"
                    exit 1
                fi
            else
                echo -e "${COLOR_GREEN}Gcore plugin already available.${COLOR_RESET}"
            fi

            reading "${LANG[ENTER_GCORE_TOKEN]}" GCORE_API_KEY

            mkdir -p ~/.secrets/certbot
            cat > ~/.secrets/certbot/gcore.ini <<EOL
dns_gcore_apitoken = $GCORE_API_KEY
EOL
            chmod 600 ~/.secrets/certbot/gcore.ini

            certbot certonly \
                --authenticator dns-gcore \
                --dns-gcore-credentials ~/.secrets/certbot/gcore.ini \
                --dns-gcore-propagation-seconds 80 \
                -d "$BASE_DOMAIN" \
                -d "$WILDCARD_DOMAIN" \
                --email "$LETSENCRYPT_EMAIL" \
                --agree-tos \
                --non-interactive \
                --key-type ecdsa \
                --elliptic-curve secp384r1
            ;;
        *)
            echo -e "${COLOR_RED}${LANG[INVALID_CERT_METHOD]}${COLOR_RESET}"
            exit 1
            ;;
    esac

    if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        echo -e "${COLOR_RED}${LANG[CERT_GENERATION_FAILED]} $DOMAIN${COLOR_RESET}"
        exit 1
    fi
}

check_cert_expiry() {
    local domain="$1"
    local cert_dir="/etc/letsencrypt/live"
    local live_dir=$(find "$cert_dir" -maxdepth 1 -type d -name "${domain}*" | sort -V | tail -n 1)
    if [ -z "$live_dir" ] || [ ! -d "$live_dir" ]; then
        return 1
    fi
    local cert_file="$live_dir/fullchain.pem"
    if [ ! -f "$cert_file" ]; then
        return 1
    fi
    local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | sed 's/notAfter=//')
    if [ -z "$expiry_date" ]; then
        echo -e "${COLOR_RED}${LANG[ERROR_PARSING_CERT]}${COLOR_RESET}"
        return 1
    fi
    local expiry_epoch=$(TZ=UTC date -d "$expiry_date" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}${LANG[ERROR_PARSING_CERT]}${COLOR_RESET}"
        return 1
    fi
    local current_epoch=$(date +%s)
    local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
    echo "$days_left"
    return 0
}

handle_certificates() {
    local -n domains_to_check_ref=$1
    local cert_method="$2"
    local letsencrypt_email="$3"
    local target_dir="/opt/remnawave"

    declare -A unique_domains
    local need_certificates=false
    local min_days_left=9999

    echo -e "${COLOR_YELLOW}${LANG[CHECK_CERTS]}${COLOR_RESET}"
    sleep 1

    echo -e "${COLOR_YELLOW}${LANG[REQUIRED_DOMAINS]}${COLOR_RESET}"
    for domain in "${!domains_to_check_ref[@]}"; do
        echo -e "${COLOR_WHITE}- $domain${COLOR_RESET}"
    done

    for domain in "${!domains_to_check_ref[@]}"; do
        if ! check_certificates "$domain"; then
            need_certificates=true
        else
            days_left=$(check_cert_expiry "$domain")
            if [ $? -eq 0 ] && [ "$days_left" -lt "$min_days_left" ]; then
                min_days_left=$days_left
            fi
        fi
    done

    if [ "$need_certificates" = true ]; then
        echo -e ""
        echo -e "${COLOR_YELLOW}${LANG[CERT_METHOD_PROMPT]}${COLOR_RESET}"
        echo -e ""
        echo -e "${COLOR_YELLOW}1. ${LANG[CERT_METHOD_CF]}${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}2. ${LANG[CERT_METHOD_ACME]}${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}3. ${LANG[CERT_METHOD_GCORE]}${COLOR_RESET}"
        echo -e ""
        echo -e "${COLOR_YELLOW}0. ${LANG[EXIT]}${COLOR_RESET}"
        echo -e ""
        reading "${LANG[CERT_METHOD_CHOOSE]}" cert_method

        if [ "$cert_method" == "0" ]; then
            echo -e "${COLOR_YELLOW}${LANG[EXIT]}${COLOR_RESET}"
            exit 1
        elif [ "$cert_method" == "2" ] || [ "$cert_method" == "3" ]; then
            reading "${LANG[EMAIL_PROMPT]}" letsencrypt_email
        elif [ "$cert_method" != "1" ]; then
            echo -e "${COLOR_RED}${LANG[CERT_INVALID_CHOICE]}${COLOR_RESET}"
            exit 1
        fi
    else
        echo -e "${COLOR_GREEN}${LANG[CERTS_SKIPPED]}${COLOR_RESET}"
        cert_method="1"
    fi

    declare -A cert_domains_added

    if [ "$need_certificates" = true ] && [ "$cert_method" == "1" ]; then
        for domain in "${!domains_to_check_ref[@]}"; do
            local base_domain
            base_domain=$(extract_domain "$domain")
            unique_domains["$base_domain"]="1"
        done

        for domain in "${!unique_domains[@]}"; do
            get_certificates "$domain" "1" ""
            if [ $? -ne 0 ]; then
                echo -e "${COLOR_RED}${LANG[CERT_GENERATION_FAILED]} $domain${COLOR_RESET}"
                return 1
            fi
            min_days_left=90
            if [ -z "${cert_domains_added[$domain]}" ]; then
                echo "      - /etc/letsencrypt/live/$domain/fullchain.pem:/etc/nginx/ssl/$domain/fullchain.pem:ro" >> "$target_dir/docker-compose.yml"
                echo "      - /etc/letsencrypt/live/$domain/privkey.pem:/etc/nginx/ssl/$domain/privkey.pem:ro" >> "$target_dir/docker-compose.yml"
                cert_domains_added["$domain"]="1"
            fi
        done

    elif [ "$need_certificates" = true ] && [ "$cert_method" == "3" ]; then
        for domain in "${!domains_to_check_ref[@]}"; do
            local base_domain
            base_domain=$(extract_domain "$domain")
            unique_domains["$base_domain"]="1"
        done

        for domain in "${!unique_domains[@]}"; do
            get_certificates "$domain" "3" "$letsencrypt_email"
            if [ $? -ne 0 ]; then
                echo -e "${COLOR_RED}${LANG[CERT_GENERATION_FAILED]} $domain${COLOR_RESET}"
                return 1
            fi
            min_days_left=90
            if [ -z "${cert_domains_added[$domain]}" ]; then
                echo "      - /etc/letsencrypt/live/$domain/fullchain.pem:/etc/nginx/ssl/$domain/fullchain.pem:ro" >> "$target_dir/docker-compose.yml"
                echo "      - /etc/letsencrypt/live/$domain/privkey.pem:/etc/nginx/ssl/$domain/privkey.pem:ro" >> "$target_dir/docker-compose.yml"
                cert_domains_added["$domain"]="1"
            fi
        done

    elif [ "$need_certificates" = true ] && [ "$cert_method" == "2" ]; then
        for domain in "${!domains_to_check_ref[@]}"; do
            get_certificates "$domain" "2" "$letsencrypt_email"
            if [ $? -ne 0 ]; then
                echo -e "${COLOR_RED}${LANG[CERT_GENERATION_FAILED]} $domain${COLOR_RESET}"
                continue
            fi
            if [ -z "${cert_domains_added[$domain]}" ]; then
                echo "      - /etc/letsencrypt/live/$domain/fullchain.pem:/etc/nginx/ssl/$domain/fullchain.pem:ro" >> "$target_dir/docker-compose.yml"
                echo "      - /etc/letsencrypt/live/$domain/privkey.pem:/etc/nginx/ssl/$domain/privkey.pem:ro" >> "$target_dir/docker-compose.yml"
                cert_domains_added["$domain"]="1"
            fi
        done
    else
        for domain in "${!domains_to_check_ref[@]}"; do
            local base_domain
            base_domain=$(extract_domain "$domain")
            local cert_domain="$domain"
            if [ -d "/etc/letsencrypt/live/$base_domain" ] && is_wildcard_cert "$base_domain"; then
                cert_domain="$base_domain"
            fi
            if [ -z "${cert_domains_added[$cert_domain]}" ]; then
                echo "      - /etc/letsencrypt/live/$cert_domain/fullchain.pem:/etc/nginx/ssl/$cert_domain/fullchain.pem:ro" >> "$target_dir/docker-compose.yml"
                echo "      - /etc/letsencrypt/live/$cert_domain/privkey.pem:/etc/nginx/ssl/$cert_domain/privkey.pem:ro" >> "$target_dir/docker-compose.yml"
                cert_domains_added["$cert_domain"]="1"
            fi
        done
    fi

    local cron_command
    if [ "$cert_method" == "2" ]; then
        cron_command="ufw allow 80 && /usr/bin/certbot renew --quiet && ufw delete allow 80 && ufw reload"
    else
        cron_command="/usr/bin/certbot renew --quiet"
    fi

    if ! crontab -u root -l 2>/dev/null | grep -q "/usr/bin/certbot renew"; then
        echo -e "${COLOR_YELLOW}${LANG[ADDING_CRON_FOR_EXISTING_CERTS]}${COLOR_RESET}"
        add_cron_rule "0 5 * * 0 $cron_command"
    elif [ "$min_days_left" -le 30 ] && ! crontab -u root -l 2>/dev/null | grep -q "0 5 * * 0.*$cron_command"; then
        echo -e "${COLOR_YELLOW}${LANG[CERT_EXPIRY_SOON]} $min_days_left ${LANG[DAYS]}${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}${LANG[UPDATING_CRON]}${COLOR_RESET}"
        crontab -u root -l 2>/dev/null | grep -v "/usr/bin/certbot renew" | crontab -u root -
        add_cron_rule "0 5 * * 0 $cron_command"
    else
        echo -e "${COLOR_YELLOW}${LANG[CRON_ALREADY_EXISTS]}${COLOR_RESET}"
    fi

    for domain in "${!unique_domains[@]}"; do
        if [ -f "/etc/letsencrypt/renewal/$domain.conf" ]; then
            desired_hook="renew_hook = sh -c 'cd /opt/remnawave && docker compose down remnawave-nginx && docker compose up -d remnawave-nginx'"
            if ! grep -q "renew_hook" "/etc/letsencrypt/renewal/$domain.conf"; then
                echo "$desired_hook" >> "/etc/letsencrypt/renewal/$domain.conf"
            elif ! grep -Fx "$desired_hook" "/etc/letsencrypt/renewal/$domain.conf"; then
                sed -i "/renew_hook/c\\$desired_hook" "/etc/letsencrypt/renewal/$domain.conf"
                echo -e "${COLOR_YELLOW}${LANG[UPDATED_RENEW_AUTH]}${COLOR_RESET}"
            fi
        fi
    done
}

randomhtml() {
    local template_source="$1"

    cd /opt/ || { echo "${LANG[UNPACK_ERROR]}"; exit 1; }

    rm -f main.zip 2>/dev/null
    rm -rf simple-web-templates-main/ sni-templates-main/ nothing-sni-main/ 2>/dev/null

    echo -e "${COLOR_YELLOW}${LANG[RANDOM_TEMPLATE]}${COLOR_RESET}"
    sleep 1
    spinner $$ "${LANG[WAITING]}" &
    spinner_pid=$!

    template_urls=(
        "https://github.com/eGamesAPI/simple-web-templates/archive/refs/heads/main.zip"
        "https://github.com/distillium/sni-templates/archive/refs/heads/main.zip"
        "https://github.com/prettyleaf/nothing-sni/archive/refs/heads/main.zip"
    )

    if [ -z "$template_source" ]; then
        selected_url=${template_urls[$RANDOM % ${#template_urls[@]}]}
    else
        if [ "$template_source" = "simple" ]; then
            selected_url=${template_urls[0]}  # Simple web templates
        elif [ "$template_source" = "sni" ]; then
            selected_url=${template_urls[1]}  # Sni templates
        elif [ "$template_source" = "nothing" ]; then
            selected_url=${template_urls[2]}  # Nothing templates
        else
            selected_url=${template_urls[1]}  # Default to Sni templates
        fi
    fi

    while ! wget -q --timeout=30 --tries=10 --retry-connrefused "$selected_url"; do
        echo "${LANG[DOWNLOAD_FAIL]}"
        sleep 3
    done

    unzip -o main.zip &>/dev/null || { echo "${LANG[UNPACK_ERROR]}"; exit 0; }
    rm -f main.zip

    if [[ "$selected_url" == *"eGamesAPI"* ]]; then
        cd simple-web-templates-main/ || { echo "${LANG[UNPACK_ERROR]}"; exit 0; }
        rm -rf assets ".gitattributes" "README.md" "_config.yml" 2>/dev/null
    elif [[ "$selected_url" == *"nothing-sni"* ]]; then
        cd nothing-sni-main/ || { echo "${LANG[UNPACK_ERROR]}"; exit 0; }
        rm -rf .github README.md 2>/dev/null
    else
        cd sni-templates-main/ || { echo "${LANG[UNPACK_ERROR]}"; exit 0; }
        rm -rf assets "README.md" "index.html" 2>/dev/null
    fi

    # Special handling for nothing-sni - select random HTML file
    if [[ "$selected_url" == *"nothing-sni"* ]]; then
        # Randomly select one HTML file from 1-8.html
        selected_number=$((RANDOM % 8 + 1))
        RandomHTML="${selected_number}.html"
    else
        mapfile -t templates < <(find . -maxdepth 1 -type d -not -path . | sed 's|./||')

        RandomHTML="${templates[$RANDOM % ${#templates[@]}]}"
    fi

    if [[ "$selected_url" == *"distillium"* && "$RandomHTML" == "503 error pages" ]]; then
        cd "$RandomHTML" || { echo "${LANG[UNPACK_ERROR]}"; exit 0; }
        versions=("v1" "v2")
        RandomVersion="${versions[$RANDOM % ${#versions[@]}]}"
        RandomHTML="$RandomHTML/$RandomVersion"
        cd ..
    fi

    local random_meta_id=$(openssl rand -hex 16)
    local random_comment=$(openssl rand -hex 8)
    local random_class_suffix=$(openssl rand -hex 4)
    local random_title_prefix="Page_"
    local random_title_suffix=$(openssl rand -hex 4)
    local random_footer_text="Designed by RandomSite_${random_title_suffix}"
    local random_id_suffix=$(openssl rand -hex 4)

    local meta_names=("viewport-id" "session-id" "track-id" "render-id" "page-id" "config-id")
    local meta_usernames=("Payee6296" "UserX1234" "AlphaBeta" "GammaRay" "DeltaForce" "EchoZulu" "Foxtrot99" "HotelCalifornia" "IndiaInk" "JulietBravo")
    local random_meta_name=${meta_names[$RANDOM % ${#meta_names[@]}]}
    local random_username=${meta_usernames[$RANDOM % ${#meta_usernames[@]}]}

    local class_prefixes=("style" "data" "ui" "layout" "theme" "view")
    local random_class_prefix=${class_prefixes[$RANDOM % ${#class_prefixes[@]}]}
    local random_class="$random_class_prefix-$random_class_suffix"
    local random_title="${random_title_prefix}${random_title_suffix}"

    find "./$RandomHTML" -type f -name "*.html" -exec sed -i \
        -e "s|<!-- Website template by freewebsitetemplates.com -->||" \
        -e "s|<!-- Theme by: WebThemez.com -->||" \
        -e "s|<a href=\"http://freewebsitetemplates.com\">Free Website Templates</a>|<span>${random_footer_text}</span>|" \
        -e "s|<a href=\"http://webthemez.com\" alt=\"webthemez\">WebThemez.com</a>|<span>${random_footer_text}</span>|" \
        -e "s|id=\"Content\"|id=\"rnd_${random_id_suffix}\"|" \
        -e "s|id=\"subscribe\"|id=\"sub_${random_id_suffix}\"|" \
        -e "s|<title>.*</title>|<title>${random_title}</title>|" \
        -e "s/<\/head>/<meta name=\"$random_meta_name\" content=\"$random_meta_id\">\n<!-- $random_comment -->\n<\/head>/" \
        -e "s/<body/<body class=\"$random_class\"/" \
        -e "s/CHANGEMEPLS/$random_username/g" \
        {} \;

    find "./$RandomHTML" -type f -name "*.css" -exec sed -i \
        -e "1i\/* $random_comment */" \
        -e "1i.$random_class { display: block; }" \
        {} \;

    kill "$spinner_pid" 2>/dev/null
    wait "$spinner_pid" 2>/dev/null
    printf "\r\033[K" > /dev/tty

    echo "${LANG[SELECT_TEMPLATE]}" "${RandomHTML}"

    if [[ -d "${RandomHTML}" ]]; then
        if [[ ! -d "/var/www/html/" ]]; then
            mkdir -p "/var/www/html/" || { echo "Failed to create /var/www/html/"; exit 1; }
        fi
        rm -rf /var/www/html/*
        cp -a "${RandomHTML}"/. "/var/www/html/"
        echo "${LANG[TEMPLATE_COPY]}"
    elif [[ -f "${RandomHTML}" ]]; then
        cp "${RandomHTML}" "/var/www/html/index.html"
        echo "${LANG[TEMPLATE_COPY]}"
    else
        echo "${LANG[UNPACK_ERROR]}" && exit 1
    fi

    if ! find "/var/www/html" -type f -name "*.html" -exec grep -q "$random_meta_name" {} \; 2>/dev/null; then
        echo -e "${COLOR_RED}${LANG[FAILED_TO_MODIFY_HTML_FILES]}${COLOR_RESET}"
        return 1
    fi

    cd /opt/
    rm -rf simple-web-templates-main/ sni-templates-main/ nothing-sni-main/
}

install_remnawave_node() {
    mkdir -p /opt/remnawave && cd /opt/remnawave

    reading "${LANG[SELFSTEAL]}" SELFSTEAL_DOMAIN

    check_domain "$SELFSTEAL_DOMAIN" true false
    local domain_check_result=$?
    if [ $domain_check_result -eq 2 ]; then
        echo -e "${COLOR_RED}${LANG[ABORT_MESSAGE]}${COLOR_RESET}"
        exit 1
    fi

    while true; do
        reading "${LANG[PANEL_IP_PROMPT]}" PANEL_IP
        if echo "$PANEL_IP" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' >/dev/null && \
           [[ $(echo "$PANEL_IP" | tr '.' '\n' | wc -l) -eq 4 ]] && \
           [[ ! $(echo "$PANEL_IP" | tr '.' '\n' | grep -vE '^[0-9]{1,3}$') ]] && \
           [[ ! $(echo "$PANEL_IP" | tr '.' '\n' | grep -E '^(25[6-9]|2[6-9][0-9]|[3-9][0-9]{2})$') ]]; then
            break
        else
            echo -e "${COLOR_RED}${LANG[IP_ERROR]}${COLOR_RESET}"
        fi
    done

    while true; do
        reading "${LANG[NODE_PORT_PROMPT]}" NODE_PORT
        # Если пользователь не ввел порт, использовать значение по умолчанию
        if [ -z "$NODE_PORT" ]; then
            NODE_PORT=2222
            echo -e "${COLOR_YELLOW}Использован порт по умолчанию: $NODE_PORT${COLOR_RESET}"
            break
        fi
        # Проверка, что введено число от 1 до 65535
        if [[ "$NODE_PORT" =~ ^[0-9]+$ ]] && [ "$NODE_PORT" -ge 1 ] && [ "$NODE_PORT" -le 65535 ]; then
            echo -e "${COLOR_GREEN}Установлен порт: $NODE_PORT${COLOR_RESET}"
            break
        else
            echo -e "${COLOR_RED}${LANG[PORT_ERROR]}${COLOR_RESET}"
        fi
    done

    while true; do
        echo -n "$(question "${LANG[CERT_PROMPT]}")"
        CERTIFICATE=""
        while IFS= read -r line; do
            if [ -z "$line" ]; then
                if [ -n "$CERTIFICATE" ]; then
                    break
                fi
            else
                CERTIFICATE="$CERTIFICATE$line\n"
            fi
        done

        echo -e "${COLOR_YELLOW}${LANG[CERT_CONFIRM]}${COLOR_RESET}"
        read confirm
        echo

        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            break
        else
            echo -e "${COLOR_YELLOW}Введите сертификат заново...${COLOR_RESET}"
            echo ""
        fi
    done

SELFSTEAL_BASE_DOMAIN=$(extract_domain "$SELFSTEAL_DOMAIN")

unique_domains["$SELFSTEAL_BASE_DOMAIN"]=1

cat > docker-compose.yml <<EOL
services:
  remnawave-nginx:
    image: nginx:1.28
    container_name: remnawave-nginx
    hostname: remnawave-nginx
    restart: always
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
EOL
}

installation_node() {
    echo -e "${COLOR_YELLOW}${LANG[INSTALLING_NODE]}${COLOR_RESET}"
    sleep 1

    declare -A unique_domains
    install_remnawave_node

    declare -A domains_to_check
    domains_to_check["$SELFSTEAL_DOMAIN"]=1

    handle_certificates domains_to_check "$CERT_METHOD" "$LETSENCRYPT_EMAIL"

    if [ -z "$CERT_METHOD" ]; then
        local base_domain=$(extract_domain "$SELFSTEAL_DOMAIN")
        if [ -d "/etc/letsencrypt/live/$base_domain" ] && is_wildcard_cert "$base_domain"; then
            CERT_METHOD="1"
        else
            CERT_METHOD="2"
        fi
    fi

    if [ "$CERT_METHOD" == "1" ]; then
        local base_domain=$(extract_domain "$SELFSTEAL_DOMAIN")
        NODE_CERT_DOMAIN="$base_domain"
    else
        NODE_CERT_DOMAIN="$SELFSTEAL_DOMAIN"
    fi

    cat >> /opt/remnawave/docker-compose.yml <<EOL
      - /dev/shm:/dev/shm:rw
      - /var/www/html:/var/www/html:ro
    command: sh -c 'rm -f /dev/shm/nginx.sock && exec nginx -g "daemon off;"'
    network_mode: host
    depends_on:
      - remnanode
    logging:
      driver: 'json-file'
      options:
        max-size: '30m'
        max-file: '5'

  remnanode:
    image: remnawave/node:latest
    container_name: remnanode
    hostname: remnanode
    restart: always
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    network_mode: host
    environment:
      - NODE_PORT=$NODE_PORT
      - SECRET_KEY=$(echo -e "$CERTIFICATE")
    volumes:
      - /dev/shm:/dev/shm:rw
    logging:
      driver: 'json-file'
      options:
        max-size: '30m'
        max-file: '5'
EOL

cat > /opt/remnawave/nginx.conf <<EOL
server_names_hash_bucket_size 64;

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ""      close;
}

ssl_protocols TLSv1.2 TLSv1.3;
ssl_ecdh_curve X25519:prime256v1:secp384r1;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers on;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;

server {
    server_name $SELFSTEAL_DOMAIN;
    listen unix:/dev/shm/nginx.sock ssl proxy_protocol;
    http2 on;

    ssl_certificate "/etc/nginx/ssl/$NODE_CERT_DOMAIN/fullchain.pem";
    ssl_certificate_key "/etc/nginx/ssl/$NODE_CERT_DOMAIN/privkey.pem";
    ssl_trusted_certificate "/etc/nginx/ssl/$NODE_CERT_DOMAIN/fullchain.pem";

    location /xhttppath/ {
        client_max_body_size 0;
        grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        client_body_timeout 5m;
        grpc_read_timeout 315;
        grpc_send_timeout 5m;
        grpc_pass unix:/dev/shm/xrxh.socket;
    }

    root /var/www/html;
    index index.html;
    add_header X-Robots-Tag "noindex, nofollow, noarchive, nosnippet, noimageindex" always;
}

server {
    listen unix:/dev/shm/nginx.sock ssl proxy_protocol default_server;
    server_name _;
    add_header X-Robots-Tag "noindex, nofollow, noarchive, nosnippet, noimageindex" always;
    ssl_reject_handshake on;
    return 444;
}
EOL

    ufw allow from $PANEL_IP to any port $NODE_PORT > /dev/null 2>&1
    ufw reload > /dev/null 2>&1

    echo -e "${COLOR_YELLOW}${LANG[STARTING_NODE]}${COLOR_RESET}"
    sleep 3
    cd /opt/remnawave
    docker compose up -d > /dev/null 2>&1 &

    spinner $! "${LANG[WAITING]}"

    randomhtml

    printf "${COLOR_YELLOW}${LANG[NODE_CHECK]}${COLOR_RESET}\n" "$SELFSTEAL_DOMAIN"
    local max_attempts=5
    local attempt=1
    local delay=15

    while [ $attempt -le $max_attempts ]; do
        printf "${COLOR_YELLOW}${LANG[NODE_ATTEMPT]}${COLOR_RESET}\n" "$attempt" "$max_attempts"
        if curl -s --fail --max-time 10 "https://$SELFSTEAL_DOMAIN" | grep -q "html"; then
            echo -e "${COLOR_GREEN}${LANG[NODE_LAUNCHED]}${COLOR_RESET}"
            break
        else
            printf "${COLOR_RED}${LANG[NODE_UNAVAILABLE]}${COLOR_RESET}\n" "$attempt"
            if [ $attempt -eq $max_attempts ]; then
                printf "${COLOR_RED}${LANG[NODE_NOT_CONNECTED]}${COLOR_RESET}\n" "$max_attempts"
                echo -e "${COLOR_YELLOW}${LANG[CHECK_CONFIG]}${COLOR_RESET}"
                exit 1
            fi
            sleep $delay
        fi
        ((attempt++))
    done

}

# Main execution
main() {
    mkdir -p "$DIR_REMNAWAVE"
    exec > >(tee -a "$LOGFILE")
    exec 2>&1

    check_root
    check_os

    clear
    echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
    echo -e "${COLOR_GREEN}  Установка ноды Remnawave${COLOR_RESET}"
    echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
    echo -e ""

    # Установка пакетов если нужно
    if [ ! -f "${DIR_REMNAWAVE}install_packages" ] || ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1 || ! command -v certbot >/dev/null 2>&1; then
        install_packages || {
            echo -e "${COLOR_RED}${LANG[ERROR_INSTALL_DOCKER]}${COLOR_RESET}"
            log_clear
            exit 1
        }
    fi

    # Запуск установки ноды
    installation_node
    
    echo -e ""
    echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
    echo -e "${COLOR_GREEN}  Установка завершена!${COLOR_RESET}"
    echo -e "${COLOR_GREEN}========================================${COLOR_RESET}"
    echo -e ""
    
    log_clear
}

main "$@"
