#!/bin/bash
# ============================================================
# 🚀 HYSTERIA2 MANAGER SCRIPT (THAI EDITION) - UDP PROXY
# ✅ รองรับทุกเวอร์ชัน Hysteria2 | พอร์ต 10000-65000
# ✅ จัดการผู้ใช้: Auth/Obfs Password, วันหมดอายุ, จำกัด IP/CIDR
# ✅ ระบบเมนูแบบ Modular เรียกใช้ฟังก์ชันแยกหมวดชัดเจน
# ============================================================

# ===================== ตรวจสอบสิทธิ์ root =====================
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31m❌ กรุณารันสคริปต์นี้ด้วยสิทธิ์ root (ใช้คำสั่ง: sudo su)\033[0m"
    exit 1
fi

# ===================== ตัวแปรระบบ =====================
HYSTERIA_DIR="/etc/hysteria"
HYSTERIA_CONFIG="$HYSTERIA_DIR/config.yaml"
HYSTERIA_USERS="$HYSTERIA_DIR/users.json"
HYSTERIA_BIN="/usr/local/bin/hysteria"
HYSTERIA_SERVICE="/etc/systemd/system/hysteria-server.service"
HYSTERIA_LOG="/var/log/hysteria"
HYSTERIA_ACL="$HYSTERIA_DIR/acl.conf"
MIN_PORT=10000
MAX_PORT=65000

# ===================== สีข้อความ =====================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# ============================================================
# 🛠️ ฟังก์ชันช่วยเหลือทั่วไป
# ============================================================
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║          🚀 HYSTERIA2 MANAGER - UDP PROXY               ║"
    echo "║     รองรับทุกเวอร์ชัน | พอร์ต 10000-65000 | ไทย         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_dependencies() {
    echo -e "${YELLOW}🔍 กำลังตรวจสอบและติดตั้งแพ็กเกจที่จำเป็น...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y -qq curl wget jq openssl qrencode cron iptables > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        dnf install -y -q curl wget jq openssl qrencode cronie iptables > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y -q curl wget jq openssl qrencode cronie iptables > /dev/null 2>&1
    fi
    echo -e "${GREEN}✅ ติดตั้งแพ็กเกจเสร็จสิ้น${NC}"
}

random_port() {
    echo $((RANDOM % (MAX_PORT - MIN_PORT + 1) + MIN_PORT))
}

generate_password() {
    openssl rand -base64 16 | tr -d '/+=' | cut -c1-16
}

is_valid_date() {
    date -d "$1" "+%Y-%m-%d" > /dev/null 2>&1
    return $?
}

is_valid_ip_cidr() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        return 0
    fi
    return 1
}

# ============================================================
# 🚀 ฟังก์ชันติดตั้ง Hysteria2 (รองรับทุกเวอร์ชัน)
# ============================================================
install_hysteria() {
    print_banner
    if [[ -f "$HYSTERIA_BIN" ]]; then
        echo -e "${YELLOW}⚠️  Hysteria2 ติดตั้งอยู่แล้วในระบบ${NC}"
        read -p "ต้องการติดตั้งซ้ำ / อัปเดตเวอร์ชันหรือไม่? (y/N): " choice
        [[ "$choice" != "y" && "$choice" != "Y" ]] && return
    fi

    check_dependencies

    # เลือกเวอร์ชัน
    echo ""
    echo -e "${CYAN}📌 เลือกเวอร์ชัน Hysteria2 ที่จะติดตั้ง:${NC}"
    echo " 1) เวอร์ชันล่าสุด (แนะนำ)"
    echo " 2) ระบุเวอร์ชันเอง (เช่น v2.5.0, v2.4.5, v2.0.0)"
    read -p "กรุณาเลือก [1-2]: " ver_choice

    if [[ "$ver_choice" == "2" ]]; then
        read -p "ป้อนเวอร์ชันที่ต้องการ (ตัวอย่าง: v2.5.0): " VERSION
        [[ -z "$VERSION" ]] && { echo -e "${RED}❌ ไม่ได้ระบุเวอร์ชัน${NC}"; sleep 1; return; }
    else
        VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | jq -r '.tag_name')
        [[ -z "$VERSION" || "$VERSION" == "null" ]] && { echo -e "${RED}❌ ไม่สามารถดึงเวอร์ชันล่าสุดได้ กรุณาเลือกระบุเอง${NC}"; sleep 1; return; }
    fi
    echo -e "${BLUE}ℹ️  กำลังติดตั้ง Hysteria2 เวอร์ชัน: ${YELLOW}$VERSION${NC}"

    # ตรวจสอบสถาปัตยกรรมเซิร์ฟเวอร์
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
        *) echo -e "${RED}❌ สถาปัตยกรรม $ARCH ไม่รองรับ${NC}"; sleep 1; return ;;
    esac

    # ดาวน์โหลดไฟล์ไบนารี
    DOWNLOAD_URL="https://github.com/apernet/hysteria/releases/download/${VERSION}/hysteria-linux-${ARCH}"
    echo -e "${YELLOW}⬇️  กำลังดาวน์โหลดจาก GitHub...${NC}"
    wget -q --show-progress -O "$HYSTERIA_BIN" "$DOWNLOAD_URL" || { 
        echo -e "${RED}❌ ดาวน์โหลดล้มเหลว! ตรวจสอบเวอร์ชันหรืออินเทอร์เน็ต${NC}"; sleep 1; return; 
    }
    chmod +x "$HYSTERIA_BIN"

    # สร้างไดเรกทอรีเก็บไฟล์ระบบ
    mkdir -p "$HYSTERIA_DIR" "$HYSTERIA_LOG"

    # กำหนดพอร์ต
    read -p "ป้อนพอร์ต UDP (เว้นว่างเพื่อสุ่มในช่วง 10000-65000): " PORT
    [[ -z "$PORT" ]] && PORT=$(random_port)
    while ! [[ "$PORT" =~ ^[0-9]+$ && "$PORT" -ge $MIN_PORT && "$PORT" -le $MAX_PORT ]]; do
        echo -e "${RED}❌ พอร์ตไม่ถูกต้อง กรุณาป้อนตัวเลขระหว่าง $MIN_PORT - $MAX_PORT${NC}"
        read -p "ป้อนพอร์ต UDP ใหม่: " PORT
    done

    # สร้างใบรับรอง SSL แบบลงชื่อเอง (อายุ 100 ปี)
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$HYSTERIA_DIR/server.key" -out "$HYSTERIA_DIR/server.crt" \
        -days 36500 -subj "/CN=www.bing.com" > /dev/null 2>&1

    # สร้างฐานข้อมูลผู้ใช้เริ่มต้น
    echo '[]' > "$HYSTERIA_USERS"

    # สร้างไฟล์กฎ ACL เริ่มต้น
    echo "# ACL Rule - จำกัด IP ผู้ใช้งาน Hysteria2" > "$HYSTERIA_ACL"
    echo "allow all" >> "$HYSTERIA_ACL"

    # สร้างไฟล์ config.yaml
    build_config

    # สร้าง Systemd Service ให้เริ่มอัตโนมัติ
    cat > "$HYSTERIA_SERVICE" << EOF
[Unit]
Description=Hysteria2 Server Service (UDP QUIC)
After=network.target

[Service]
Type=simple
User=root
ExecStart=$HYSTERIA_BIN server --config $HYSTERIA_CONFIG
Restart=on-failure
RestartSec=5
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    # เปิดพอร์ตในไฟร์วอลล์อัตโนมัติ
    open_firewall "$PORT"

    # เริ่มบริการและตั้งให้เริ่มต้นร่วมกับระบบ
    systemctl daemon-reload
    systemctl enable --now hysteria-server > /dev/null 2>&1

    # ตั้ง Cron Job ตรวจสอบผู้ใช้หมดอายุอัตโนมัติ ทุกวันเวลา 00:00 น.
    (crontab -l 2>/dev/null | grep -v "hysteria-expire"; 
     echo "0 0 * * * /usr/local/bin/hysteria2-manager.sh expire > /dev/null 2>&1") | crontab -

    # สร้างคำสั่งลัดเรียกใช้เมนู
    SCRIPT_PATH=$(realpath "$0")
    ln -sf "$SCRIPT_PATH" /usr/local/bin/hysteria2-manager 2>/dev/null

    sleep 1
    # ตรวจสอบว่าบริการทำงานหรือไม่
    if systemctl is-active --quiet hysteria-server; then
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✅ ติดตั้ง Hysteria2 เสร็จสิ้นสมบูรณ์!${NC}"
        echo -e "${BLUE}📡 พอร์ต UDP: ${YELLOW}$PORT${NC}"
        echo -e "${BLUE}💻 เวอร์ชันที่ติดตั้ง: ${YELLOW}$VERSION${NC}"
        echo -e "${BLUE}💾 ไฟล์ตั้งค่า: ${YELLOW}$HYSTERIA_CONFIG${NC}"
        echo -e "${CYAN}💡 พิมพ์คำสั่ง ${YELLOW}hysteria2-manager${CYAN} เพื่อเข้าเมนูจัดการ${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    else
        echo -e "${RED}❌ บริการไม่สามารถเริ่มได้! กรุณาตรวจสอบ Log ด้านล่าง${NC}"
        journalctl -u hysteria-server -n 20 --no-pager
    fi
    echo ""
    read -n 1 -s -r -p "กดปุ่มใดๆ เพื่อกลับเมนู..."
}

# ============================================================
# ⚙️ ฟังก์ชันสร้าง Config & ACL จากฐานผู้ใช้อัตโนมัติ
# ============================================================
build_config() {
    local PORT AUTH_LIST OBFUSCATION=""

    # ดึงพอร์ตจาก config เดิมถ้ามี
    if [[ -f "$HYSTERIA_CONFIG" ]]; then
        PORT=$(grep -oP 'listen: :\K[0-9]+' "$HYSTERIA_CONFIG" 2>/dev/null)
    fi
    [[ -z "$PORT" ]] && PORT=$(random_port)

    # สร้างรายการ Auth Password จากผู้ใช้ที่เปิดใช้และยังไม่หมดอายุ
    local today_ts=$(date -d "$(date '+%Y-%m-%d')" '+%s')
    AUTH_LIST=$(jq -r --argjson today "$today_ts" '
        .[] | select(
            .enabled == true and 
            (.expire == "" or .expire == null or 
             ((.expire | strptime("%Y-%m-%d") | mktime) >= $today))
        ) | "    - \(.auth_password)"
    ' "$HYSTERIA_USERS" 2>/dev/null)
    
    # ถ้าไม่มีผู้ใช้เลย สร้างรหัสชั่วคราว
    if [[ -z "$AUTH_LIST" ]]; then
        local temp_pass=$(generate_password)
        AUTH_LIST="    - $temp_pass"
    fi

    # ใช้ Obfuscation Password จากผู้ใช้แรกที่กำหนดไว้
    OBF_PASS=$(jq -r '[.[] | select(.enabled == true and .obfs_password != "" and .obfs_password != null)][0].obfs_password' "$HYSTERIA_USERS" 2>/dev/null)
    if [[ -n "$OBF_PASS" && "$OBF_PASS" != "null" ]]; then
        OBFUSCATION="obfs:
  type: salamander
  password: \"$OBF_PASS\""
    fi

    # เขียนไฟล์ config.yaml ใหม่ทุกครั้ง
    cat > "$HYSTERIA_CONFIG" << EOF
# ==============================================
# ไฟล์ตั้งค่าอัตโนมัติ - ห้ามแก้ไขด้วยตัวเอง!
# ใช้เมนู hysteria2-manager จัดการแทน
# ==============================================
listen: :$PORT

tls:
  cert: $HYSTERIA_DIR/server.crt
  key: $HYSTERIA_DIR/server.key

auth:
  type: password
  password:
$AUTH_LIST

$OBFUSCATION

acl:
  file: $HYSTERIA_ACL

quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 33554432
  initConnReceiveWindow: 67108864
  maxConnReceiveWindow: 134217728
  maxIdleTimeout: 60s
  keepAlivePeriod: 10s
  disablePathMTUDiscovery: false

bandwidth:
  up: 1 gbps
  down: 1 gbps

udpIdleTimeout: 120s

masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com
    rewriteHost: true
EOF

    # สร้างกฎ ACL สำหรับจำกัด IP
    build_acl

    # รีสตาร์ทบริการถ้าทำงานอยู่ เพื่อให้ค่าใหม่ใช้งาน
    if systemctl is-active --quiet hysteria-server 2>/dev/null; then
        systemctl restart hysteria-server > /dev/null 2>&1
    fi
}

build_acl() {
    echo "# =============================================" > "$HYSTERIA_ACL"
    echo "# Auto-generated ACL - ห้ามแก้ไขด้วยตัวเอง!" >> "$HYSTERIA_ACL"
    echo "# กฎจำกัด IP ผู้ใช้งาน Hysteria2" >> "$HYSTERIA_ACL"
    echo "# =============================================" >> "$HYSTERIA_ACL"
    echo "" >> "$HYSTERIA_ACL"

    # ดึงผู้ใช้ที่เปิดใช้และมีการจำกัด IP
    local has_restrict=false
    jq -c '.[] | select(.enabled == true and .allowed_ips != null and (.allowed_ips | length) > 0)' "$HYSTERIA_USERS" 2>/dev/null | while read -r user; do
        has_restrict=true
        local u ips
        u=$(echo "$user" | jq -r '.username')
        ips=$(echo "$user" | jq -r '.allowed_ips[]')
        echo "# -------- ผู้ใช้: $u --------" >> "$HYSTERIA_ACL"
        while IFS= read -r ip; do
            [[ -n "$ip" ]] && echo "allow ip $ip" >> "$HYSTERIA_ACL"
        done <<< "$ips"
        echo "" >> "$HYSTERIA_ACL"
    done

    # ถ้ามีผู้ใช้ที่จำกัด IP → บล็อกทุก IP อื่นๆ, ถ้าไม่มี → อนุญาตทุก IP
    local restrict_count
    restrict_count=$(jq '[.[] | select(.allowed_ips != null and (.allowed_ips | length) > 0)] | length' "$HYSTERIA_USERS" 2>/dev/null)
    if [[ "$restrict_count" -gt 0 ]]; then
        echo "# บล็อกทุก IP ที่ไม่อยู่ในรายการอนุญาต" >> "$HYSTERIA_ACL"
        echo "block all" >> "$HYSTERIA_ACL"
    else
        echo "# ไม่มีการจำกัด IP → อนุญาตทุกการเชื่อมต่อ" >> "$HYSTERIA_ACL"
        echo "allow all" >> "$HYSTERIA_ACL"
    fi
}

# ============================================================
# 🔥 ฟังก์ชันเปิดพอร์ตในไฟร์วอลล์ (UFW / Firewalld / iptables)
# ============================================================
open_firewall() {
    local port=$1
    echo -e "${YELLOW}🔥 กำลังเปิดพอร์ต UDP $port ในไฟร์วอลล์...${NC}"
    if command -v ufw &> /dev/null; then
        ufw allow "$port/udp" > /dev/null 2>&1
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port="$port/udp" > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
    else
        iptables -I INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null
        mkdir -p /etc/iptables && iptables-save > /etc/iptables/rules.v4 2>/dev/null
    fi
}

# ============================================================
# 👤 ฟังก์ชันจัดการผู้ใช้ทั้งหมด
# ============================================================

# ---------------- เพิ่มผู้ใช้ใหม่ ----------------
add_user() {
    print_banner
    echo -e "${CYAN}➕ เพิ่มผู้ใช้ใหม่${NC}"
    echo "─────────────────────────────────────────────"

    read -p "👤 ชื่อผู้ใช้ (Username): " username
    [[ -z "$username" ]] && { echo -e "${RED}❌ กรุณาป้อนชื่อผู้ใช้${NC}"; sleep 1; return; }

    # ตรวจสอบว่ามีผู้ใช้นี้อยู่แล้วหรือไม่
    local exists
    exists=$(jq --arg u "$username" '.[] | select(.username == $u)' "$HYSTERIA_USERS")
    [[ -n "$exists" ]] && { echo -e "${RED}❌ มีชื่อผู้ใช้นี้อยู่แล้วในระบบ${NC}"; sleep 1; return; }

    # กำหนด Auth Password
    local default_auth=$(generate_password)
    read -p "🔑 Auth Password (เว้นว่างสุ่มอัตโนมัติ: $default_auth): " auth_pass
    [[ -z "$auth_pass" ]] && auth_pass=$default_auth

    # กำหนด Obfuscation Password
    local default_obfs=$(generate_password)
    read -p "🔐 Obfuscation Password (เว้นว่างสุ่มอัตโนมัติ: $default_obfs): " obfs_pass
    [[ -z "$obfs_pass" ]] && obfs_pass=$default_obfs

    # กำหนดวันหมดอายุ
    local expire=""
    read -p "📅 วันหมดอายุ (รูปแบบ YYYY-MM-DD, เว้นว่าง=ไม่หมดอายุ): " expire_input
    if [[ -n "$expire_input" ]]; then
        while ! is_valid_date "$expire_input"; do
            echo -e "${RED}❌ รูปแบบวันที่ไม่ถูกต้อง!${NC}"
            read -p "📅 ป้อนใหม่ (YYYY-MM-DD): " expire_input
            [[ -z "$expire_input" ]] && break
        done
        [[ -n "$expire_input" ]] && expire=$(date -d "$expire_input" "+%Y-%m-%d")
    fi

    # กำหนด IP ที่อนุญาตเชื่อมต่อ
    local ips_json="[]"
    read -p "🌐 จำกัด IP/CIDR (คั่นด้วยช่องว่าง, เว้นว่าง=ไม่จำกัด): " ips_input
    if [[ -n "$ips_input" ]]; then
        local valid_ips=()
        for ip in $ips_input; do
            if is_valid_ip_cidr "$ip"; then
                valid_ips+=("$ip")
            else
                echo -e "${YELLOW}⚠️  ข้าม IP รูปแบบไม่ถูกต้อง: $ip${NC}"
            fi
        done
        if [[ ${#valid_ips[@]} -gt 0 ]]; then
            ips_json=$(printf '%s\n' "${valid_ips[@]}" | jq -R . | jq -s .)
        fi
    fi

    # เพิ่มข้อมูลลงฐานข้อมูล JSON
    jq --arg u "$username" \
       --arg a "$auth_pass" \
       --arg o "$obfs_pass" \
       --arg e "$expire" \
       --argjson i "$ips_json" \
       '. += [{
           "username": $u,
           "auth_password": $a,
           "obfs_password": $o,
           "expire": $e,
           "allowed_ips": $i,
           "enabled": true,
           "created": "'$(date '+%Y-%m-%d %H:%M:%S')'"
       }]' "$HYSTERIA_USERS" > "$HYSTERIA_USERS.tmp" && mv "$HYSTERIA_USERS.tmp" "$HYSTERIA_USERS"

    # อัปเดต Config + รีสตาร์ทบริการ
    build_config

    # แสดงข้อมูลผู้ใช้ + URL เชื่อมต่อ + QR Code
    local port server_ip
    port=$(grep -oP 'listen: :\K[0-9]+' "$HYSTERIA_CONFIG")
    server_ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    local hy_url="hy2://$auth_pass@$server_ip:$port/?obfs=salamander&obfs-password=$obfs_pass&insecure=1#$username"

    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ เพิ่มผู้ใช้เสร็จสิ้น!${NC}"
    echo -e "${BLUE}👤 ชื่อผู้ใช้: ${YELLOW}$username${NC}"
    echo -e "${BLUE}🔑 Auth Pass: ${YELLOW}$auth_pass${NC}"
    echo -e "${BLUE}🔐 Obfs Pass: ${YELLOW}$obfs_pass${NC}"
    echo -e "${BLUE}📅 หมดอายุ: ${YELLOW}${expire:-ไม่จำกัด}${NC}"
    echo -e "${BLUE}🌐 IP อนุญาต: ${YELLOW}${ips_input:-ทุก IP}${NC}"
    echo -e "${BLUE}📡 URL เชื่อมต่อ:${NC}"
    echo -e "${CYAN}$hy_url${NC}"
    echo ""
    if command -v qrencode &> /dev/null; then
        echo -e "${BLUE}📱 QR Code (สแกนใช้งานได้เลย):${NC}"
        qrencode -t ANSIUTF8 "$hy_url"
    fi
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"

    echo ""
    read -n 1 -s -r -p "กดปุ่มใดๆ เพื่อกลับเมนู..."
}

# ---------------- แสดงรายการผู้ใช้ทั้งหมด ----------------
list_users() {
    print_banner
    echo -e "${CYAN}📋 รายการผู้ใช้ทั้งหมดในระบบ${NC}"
    echo "─────────────────────────────────────────────────────────────────────────────────────"

    if [[ ! -f "$HYSTERIA_USERS" || $(jq 'length' "$HYSTERIA_USERS") -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  ยังไม่มีผู้ใช้ในระบบ กรุณาเพิ่มผู้ใช้ก่อน${NC}"
        echo ""
        read -n 1 -s -r -p "กดปุ่มใดๆ เพื่อกลับเมนู..."
        return
    fi

    local today=$(date '+%Y-%m-%d')
    printf "${BLUE}%-4s %-16s %-12s %-14s %-12s %-18s %s${NC}\n" \
        "ลำดับ" "ชื่อผู้ใช้" "สถานะ" "วันหมดอายุ" "จำกัด IP" "Auth Password" "Obfs Password"
    printf "%-4s %-16s %-12s %-14s %-12s %-18s %s\n" \
        "----" "----------------" "------------" "--------------" "------------" "------------------" "------------------"

    local idx=0
    jq -c '.[]' "$HYSTERIA_USERS" | while read -r user; do
        idx=$((idx+1))
        local u e enabled status ip_count auth obfs expire_ts today_ts
        u=$(echo "$user" | jq -r '.username')
        e=$(echo "$user" | jq -r '.expire')
        enabled=$(echo "$user" | jq -r '.enabled')
        ip_count=$(echo "$user" | jq -r '.allowed_ips | length')
        auth=$(echo "$user" | jq -r '.auth_password')
        obfs=$(echo "$user" | jq -r '.obfs_password')

        # ตรวจสอบสถานะ
        if [[ "$enabled" != "true" ]]; then
            status="${RED}ปิดใช้${NC}"
        elif [[ -n "$e" && "$e" != "null" ]]; then
            expire_ts=$(date -d "$e" '+%s')
            today_ts=$(date -d "$today" '+%s')
            if [[ $expire_ts -lt $today_ts ]]; then
                status="${RED}หมดอายุ${NC}"
            else
                status="${GREEN}ใช้งาน${NC}"
            fi
        else
            status="${GREEN}ใช้งาน${NC}"
        fi

        local ip_text
        [[ "$ip_count" -gt 0 ]] && ip_text="${YELLOW}$ip_count รายการ${NC}" || ip_text="${GREEN}ไม่จำกัด${NC}"

        printf "%-4s %-16s %b %-14s %b %-18s %s\n" \
            "$idx" "$u" "$status" "${e:-ไม่จำกัด}" "$ip_text" "${auth:0:16}" "${obfs:0:16}"
    done

    echo "─────────────────────────────────────────────────────────────────────────────────────"
    echo -e "${BLUE}📊 สรุป: ${YELLOW}$(jq 'length' "$HYSTERIA_USERS") ${BLUE}รายการ${NC}"
    echo ""
    read -n 1 -s -r -p "กดปุ่มใดๆ เพื่อกลับเมนู..."
}

# ---------------- แก้ไขข้อมูลผู้ใช้ ----------------
edit_user() {
    print_banner
    echo -e "${CYAN}✏️  แก้ไขข้อมูลผู้ใช้${NC}"
    echo "─────────────────────────────────────────────"

    if [[ $(jq 'length' "$HYSTERIA_USERS") -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  ยังไม่มีผู้ใช้ในระบบ${NC}"
        sleep 1
        return
    fi

    read -p "👤 ป้อนชื่อผู้ใช้ที่ต้องการแก้ไข: " username
    local user_data
    user_data=$(jq --arg u "$username" '.[] | select(.username == $u)' "$HYSTERIA_USERS")
    [[ -z "$user_data" ]] && { echo -e "${RED}❌ ไม่พบผู้ใช้ชื่อ $username ในระบบ${NC}"; sleep 1; return; }

    # ดึงค่าเดิมมาแสดง
    local old_auth old_obfs old_expire old_ips old_enabled
    old_auth=$(echo "$user_data" | jq -r '.auth_password')
    old_obfs=$(echo "$user_data" | jq -r '.obfs_password')
    old_expire=$(echo "$user_data" | jq -r '.expire')
    old_ips=$(echo "$user_data" | jq -r '.allowed_ips | join(" ")')
    old_enabled=$(echo "$user_data" | jq -r '.enabled')

    echo ""
    echo -e "${BLUE}💡 เว้นว่างทุกช่องเพื่อใช้ค่าเดิม${NC}"
    echo "─────────────────────────────────────────────"

    read -p "🔑 Auth Password ใหม่ [$old_auth]: " new_auth
    [[ -z "$new_auth" ]] && new_auth=$old_auth

    read -p "🔐 Obfuscation Password ใหม่ [$old_obfs]: " new_obfs
    [[ -z "$new_obfs" ]] && new_obfs=$old_obfs

    read -p "📅 วันหมดอายุใหม่ YYYY-MM-DD [${old_expire:-ไม่จำกัด}]: " new_expire
    if [[ -n "$new_expire" ]]; then
        while ! is_valid_date "$new_expire"; do
            echo -e "${RED}❌ รูปแบบวันที่ไม่ถูกต้อง${NC}"
            read -p "📅 ป้อนใหม่ (YYYY-MM-DD): " new_expire
            [[ -z "$new_expire" ]] && break
        done
        [[ -n "$new_expire" ]] && new_expire=$(date -d "$new_expire" "+%Y-%m-%d")
    else
        new_expire=$old_expire
    fi

    read -p "🌐 IP อนุญาตใหม่ (คั่นช่องว่าง) [${old_ips:-ไม่จำกัด}]: " new_ips_input
    local new_ips_json
    if [[ -n "$new_ips_input" ]]; then
        local valid=()
        for ip in $new_ips_input; do
            is_valid_ip_cidr "$ip" && valid+=("$ip") || echo -e "${YELLOW}⚠️  ข้าม IP ไม่ถูกต้อง: $ip${NC}"
        done
        new_ips_json=$(printf '%s\n' "${valid[@]}" | jq -R . | jq -s .)
    else
        new_ips_json=$(echo "$user_data" | jq '.allowed_ips')
    fi

    read -p "✅ เปิดใช้งานผู้ใช้หรือไม่? (y/N) [ปัจจุบัน: $old_enabled]: " en_choice
    case "$en_choice" in
        y|Y) new_enabled=true ;;
        n|N) new_enabled=false ;;
        *) new_enabled=$old_enabled ;;
    esac

    # อัปเดตฐานข้อมูล
    jq --arg u "$username" \
       --arg a "$new_auth" \
       --arg o "$new_obfs" \
       --arg e "$new_expire" \
       --argjson i "$new_ips_json" \
       --argjson en "$new_enabled" \
       'map(if .username == $u then
           .auth_password=$a | .obfs_password=$o | .expire=$e | 
           .allowed_ips=$i | .enabled=$en | .updated="'$(date '+%Y-%m-%d %H:%M:%S')'"
       else . end)' "$HYSTERIA_USERS" > "$HYSTERIA_USERS.tmp" && mv "$HYSTERIA_USERS.tmp" "$HYSTERIA_USERS"

    # อัปเดต Config
    build_config
    echo -e "\n${GREEN}✅ อัปเดตข้อมูลผู้ใช้ $username เสร็จสิ้น${NC}"
    sleep 1
}

# ---------------- ลบผู้ใช้ ----------------
delete_user() {
    print_banner
    echo -e "${RED}🗑️  ลบผู้ใช้ออกจากระบบ${NC}"
    echo "─────────────────────────────────────────────"

    if [[ $(jq 'length' "$HYSTERIA_USERS") -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  ยังไม่มีผู้ใช้ในระบบ${NC}"
        sleep 1
        return
    fi

    read -p "👤 ป้อนชื่อผู้ใช้ที่ต้องการลบ: " username
    local exists
    exists=$(jq --arg u "$username" '.[] | select(.username == $u)' "$HYSTERIA_USERS")
    [[ -z "$exists" ]] && { echo -e "${RED}❌ ไม่พบผู้ใช้ชื่อ $username${NC}"; sleep 1; return; }

    read -p "❓ ยืนยันการลบผู้ใช้ ${YELLOW}$username${NC} ถาวร? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "${YELLOW}ℹ️  ยกเลิกการลบ${NC}"; sleep 1; return; }

    jq --arg u "$username" 'map(select(.username != $u))' "$HYSTERIA_USERS" > "$HYSTERIA_USERS.tmp" && mv "$HYSTERIA_USERS.tmp" "$HYSTERIA_USERS"
    build_config
    echo -e "${GREEN}✅ ลบผู้ใช้ $username เสร็จสิ้น${NC}"
    sleep 1
}

# ---------------- แสดง URL/QR ผู้ใช้ ----------------
show_user_detail() {
    print_banner
    echo -e "${CYAN}🔍 แสดงข้อมูลเชื่อมต่อผู้ใช้${NC}"
    echo "─────────────────────────────────────────────"

    if [[ $(jq 'length' "$HYSTERIA_USERS") -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  ยังไม่มีผู้ใช้ในระบบ${NC}"
        sleep 1
        return
    fi

    read -p "👤 ป้อนชื่อผู้ใช้: " username
    local user
    user=$(jq --arg u "$username" '.[] | select(.username == $u)' "$HYSTERIA_USERS")
    [[ -z "$user" ]] && { echo -e "${RED}❌ ไม่พบผู้ใช้ชื่อ $username${NC}"; sleep 1; return; }

    local auth obfs port server_ip
    auth=$(echo "$user" | jq -r '.auth_password')
    obfs=$(echo "$user" | jq -r '.obfs_password')
    port=$(grep -oP 'listen: :\K[0-9]+' "$HYSTERIA_CONFIG")
    server_ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    local hy_url="hy2://$auth@$server_ip:$port/?obfs=salamander&obfs-password=$obfs&insecure=1#$username"

    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}👤 ชื่อผู้ใช้: ${YELLOW}$username${NC}"
    echo -e "${BLUE}🔑 Auth Pass: ${YELLOW}$auth${NC}"
    echo -e "${BLUE}🔐 Obfs Pass: ${YELLOW}$obfs${NC}"
    echo -e "${BLUE}📅 หมดอายุ: ${YELLOW}$(echo "$user" | jq -r '.expire // "ไม่จำกัด"')${NC}"
    echo -e "${BLUE}🌐 IP อนุญาต: ${YELLOW}$(echo "$user" | jq -r '.allowed_ips | join(", ") // "ทุก IP"')${NC}"
    echo -e "${BLUE}📌 สถานะ: ${YELLOW}$(echo "$user" | jq -r '.enabled')${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}📡 URL เชื่อมต่อ Hysteria2:${NC}"
    echo -e "${CYAN}$hy_url${NC}"
    echo ""
    if command -v qrencode &> /dev/null; then
        echo -e "${BLUE}📱 QR Code สำหรับมือถือ:${NC}"
        qrencode -t ANSIUTF8 "$hy_url"
    fi

    echo ""
    read -n 1 -s -r -p "กดปุ่มใดๆ เพื่อกลับเมนู..."
}

# ============================================================
# ⏰ ฟังก์ชันตรวจสอบผู้ใช้หมดอายุ (รันอัตโนมัติ + รันด้วยมือ)
# ============================================================
check_expire_users() {
    local today=$(date '+%Y-%m-%d')
    local today_ts=$(date -d "$today" '+%s')
    local changed=false

    echo -e "${CYAN}🔍 กำลังตรวจสอบผู้ใช้หมดอายุ...${NC}"
    jq -c '.[] | select(.enabled == true and .expire != "" and .expire != null)' "$HYSTERIA_USERS" 2>/dev/null | while read -r user; do
        local u exp exp_ts
        u=$(echo "$user" | jq -r '.username')
        exp=$(echo "$user" | jq -r '.expire')
        exp_ts=$(date -d "$exp" '+%s')

        if [[ $exp_ts -lt $today_ts ]]; then
            echo -e "${RED}🔒 ปิดการใช้งาน: $u (หมดอายุเมื่อ $exp)${NC}"
            jq --arg un "$u" 'map(if .username == $un then .enabled = false else . end)' "$HYSTERIA_USERS" > "$HYSTERIA_USERS.tmp" && mv "$HYSTERIA_USERS.tmp" "$HYSTERIA_USERS"
            changed=true
        fi
    done

    if [[ "$changed" == "true" ]]; then
        build_config
        echo -e "${GREEN}✅ อัปเดตสถานะผู้ใช้หมดอายุเสร็จสิ้น${NC}"
    else
        echo -e "${GREEN}✅ ไม่พบผู้ใช้ที่หมดอายุ${NC}"
    fi
}

# ============================================================
# ❌ ฟังก์ชันถอนการติดตั้ง Hysteria2 ทั้งหมด
# ============================================================
uninstall_hysteria() {
    print_banner
    echo -e "${RED}══════════════════════════════════════════════${NC}"
    echo -e "${RED}⚠️  คำเตือน! กำลังจะลบ Hysteria2 ทั้งหมดออกจากระบบ${NC}"
    echo -e "${RED}→ ไฟล์ตั้งค่า, ผู้ใช้, บริการทั้งหมดจะหายไปถาวร${NC}"
    echo -e "${RED}══════════════════════════════════════════════${NC}"
    read -p "❓ พิมพ์คำว่า ${YELLOW}YES${NC} เพื่อยืนยันการถอนการติดตั้ง: " confirm
    [[ "$confirm" != "YES" ]] && { echo -e "${YELLOW}ℹ️  ยกเลิกการถอนการติดตั้ง${NC}"; sleep 1; return; }

    echo -e "${YELLOW}🗑️  กำลังลบทุกอย่าง...${NC}"
    systemctl stop hysteria-server > /dev/null 2>&1
    systemctl disable hysteria-server > /dev/null 2>&1
    rm -f "$HYSTERIA_SERVICE" "$HYSTERIA_BIN"
    rm -rf "$HYSTERIA_DIR" "$HYSTERIA_LOG"
    rm -f /usr/local/bin/hysteria2-manager
    (crontab -l 2>/dev/null | grep -v "hysteria-expire") | crontab - 2>/dev/null
    systemctl daemon-reload

    echo -e "${GREEN}✅ ถอนการติดตั้ง Hysteria2 เสร็จสิ้นสมบูรณ์${NC}"
    sleep 2
    exit 0
}

# ============================================================
# 📋 ระบบเมนูแบบ Modular (เรียกใช้ฟังก์ชันแยกหมวด)
# ============================================================

# ---------------- เมนูย่อย 1: จัดการผู้ใช้ ----------------
menu_user_management() {
    while true; do
        print_banner
        echo -e "${CYAN}👤 เมนูจัดการผู้ใช้ทั้งหมด${NC}"
        echo "───────────────────────────────────"
        echo " 1) ➕ เพิ่มผู้ใช้ใหม่"
        echo " 2) 📋 แสดงรายการผู้ใช้ทั้งหมด"
        echo " 3) ✏️  แก้ไขข้อมูลผู้ใช้"
        echo " 4) 🔍 แสดง URL เชื่อมต่อ + QR Code"
        echo " 5) 🗑️  ลบผู้ใช้ออกจากระบบ"
        echo "───────────────────────────────────"
        echo " 9) 🔙 ย้อนกลับเมนูหลัก"
        echo " 0) 🚪 ออกจากโปรแกรม"
        echo ""
        read -p "กรุณาเลือกทำการ [0-9]: " choice

        case "$choice" in
            1) add_user ;;
            2) list_users ;;
            3) edit_user ;;
            4) show_user_detail ;;
            5) delete_user ;;
            9) return ;;
            0) clear; exit 0 ;;
            *) echo -e "${RED}❌ ตัวเลือกไม่ถูกต้อง กรุณาเลือก 0-9${NC}"; sleep 1 ;;
        esac
    done
}

# ---------------- เมนูย่อย 2: จัดการบริการ & พอร์ต ----------------
menu_service_management() {
    while true; do
        print_banner
        echo -e "${CYAN}⚙️  เมนูจัดการบริการ & พอร์ต${NC}"
        echo "───────────────────────────────────"
        echo " 1) ▶️  เริ่มบริการ (Start)"
        echo " 2) ⏹️  หยุดบริการ (Stop)"
        echo " 3) 🔄 รีสตาร์ทบริการ (Restart)"
        echo " 4) 📊 ตรวจสอบสถานะ + ดู Log ล่าสุด"
        echo " 5) 🔌 เปลี่ยนพอร์ต UDP (10000-65000)"
        echo "───────────────────────────────────"
        echo " 9) 🔙 ย้อนกลับเมนูหลัก"
        echo " 0) 🚪 ออกจากโปรแกรม"
        echo ""
        read -p "กรุณาเลือกทำการ [0-9]: " choice

        case "$choice" in
            1) 
                systemctl start hysteria-server \
                    && echo -e "${GREEN}✅ เริ่มบริการ Hysteria2 แล้ว${NC}" \
                    || echo -e "${RED}❌ เริ่มบริการล้มเหลว${NC}"
                sleep 1 ;;
            2) 
                systemctl stop hysteria-server \
                    && echo -e "${GREEN}✅ หยุดบริการ Hysteria2 แล้ว${NC}" \
                    || echo -e "${RED}❌ หยุดบริการล้มเหลว${NC}"
                sleep 1 ;;
            3) 
                systemctl restart hysteria-server \
                    && echo -e "${GREEN}✅ รีสตาร์ทบริการแล้ว${NC}" \
                    || echo -e "${RED}❌ รีสตาร์ทล้มเหลว${NC}"
                sleep 1 ;;
            4) 
                echo -e "${BLUE}📊 สถานะบริการ:${NC}"
                systemctl status hysteria-server --no-pager
                echo -e "\n${BLUE}📜 Log ล่าสุด 20 บรรทัด:${NC}"
                journalctl -u hysteria-server -n 20 --no-pager
                echo ""
                read -n 1 -s -r -p "กดปุ่มใดๆ เพื่อกลับเมนู..."
                ;;
            5)
                local old_port new_port
                old_port=$(grep -oP 'listen: :\K[0-9]+' "$HYSTERIA_CONFIG")
                read -p "ป้อนพอร์ตใหม่ [$MIN_PORT-$MAX_PORT] (ปัจจุบัน: $old_port): " new_port
                while ! [[ "$new_port" =~ ^[0-9]+$ && "$new_port" -ge $MIN_PORT && "$new_port" -le $MAX_PORT ]]; do
                    echo -e "${RED}❌ พอร์ตไม่ถูกต้อง!${NC}"
                    read -p "ป้อนใหม่: " new_port
                done
                sed -i "s/listen: :$old_port/listen: :$new_port/" "$HYSTERIA_CONFIG"
                open_firewall "$new_port"
                systemctl restart hysteria-server
                echo -e "${GREEN}✅ เปลี่ยนพอร์ตเป็น $new_port เสร็จสิ้น${NC}"
                sleep 1
                ;;
            9) return ;;
            0) clear; exit 0 ;;
            *) echo -e "${RED}❌ ตัวเลือกไม่ถูกต้อง${NC}"; sleep 1 ;;
        esac
    done
}

# ---------------- เมนูย่อย 3: ระบบ & การติดตั้ง ----------------
menu_system() {
    while true; do
        print_banner
        echo -e "${CYAN}🖥️  เมนูระบบ & การติดตั้ง${NC}"
        echo "───────────────────────────────────"
        echo " 1) 🚀 ติดตั้ง / อัปเดต Hysteria2"
        echo " 2) 🔍 ตรวจสอบผู้ใช้หมดอายุทันที"
        echo " 3) ❌ ถอนการติดตั้ง Hysteria2 ทั้งหมด"
        echo "───────────────────────────────────"
        echo " 9) 🔙 ย้อนกลับเมนูหลัก"
        echo " 0) 🚪 ออกจากโปรแกรม"
        echo ""
        read -p "กรุณาเลือกทำการ [0-9]: " choice

        case "$choice" in
            1) install_hysteria ;;
            2) 
                check_expire_users
                echo ""
                read -n 1 -s -r -p "กดปุ่มใดๆ เพื่อกลับ..."
                ;;
            3) uninstall_hysteria ;;
            9) return ;;
            0) clear; exit 0 ;;
            *) echo -e "${RED}❌ ตัวเลือกไม่ถูกต้อง${NC}"; sleep 1 ;;
        esac
    done
}

# ---------------- 🏠 เมนูหลัก (กระจายการเรียกใช้ฟังก์ชัน) ----------------
main_menu() {
    # ถ้ายังไม่ติดตั้ง Hysteria2 → แสดงแค่ตัวเลือกติดตั้ง
    if [[ ! -f "$HYSTERIA_BIN" ]]; then
        while true; do
            print_banner
            echo -e "${YELLOW}⚠️  ยังไม่พบ Hysteria2 ในระบบ${NC}"
            echo -e "${CYAN}กรุณาเลือกทำการ:${NC}"
            echo " 1) 🚀 ติดตั้ง Hysteria2"
            echo " 0) 🚪 ออกจากโปรแกรม"
            echo ""
            read -p "เลือก: " c
            case "$c" in
                1) install_hysteria; break ;;
                0) clear; exit 0 ;;
                *) echo -e "${RED}❌ ไม่ถูกต้อง${NC}"; sleep 1 ;;
            esac
        done
    fi

    # ✅ ลูปหลักของเมนู
    while true; do
        print_banner
        echo -e "${CYAN}🏠 เมนูหลัก — Hysteria2 Manager${NC}"
        echo "═══════════════════════════════════"
        echo " 1) 👤 จัดการผู้ใช้ทั้งหมด"
        echo " 2) ⚙️  จัดการบริการ & พอร์ต"
        echo " 3) 🖥️  ระบบ / ติดตั้ง / ถอนการติดตั้ง"
        echo "═══════════════════════════════════"
        echo " 0) 🚪 ออกจากโปรแกรม"
        echo ""
        read -p "กรุณาเลือกหมวดทำการ [0-3]: " main_choice

        case "$main_choice" in
            1) menu_user_management ;;
            2) menu_service_management ;;
            3) menu_system ;;
            0) clear; exit 0 ;;
            *) echo -e "${RED}❌ กรุณาเลือก 0 - 3 เท่านั้น${NC}"; sleep 1 ;;
        esac
    done
}

# ============================================================
# 🚀 จุดเริ่มต้นสคริปต์
# ============================================================
# ✅ ถ้ารันด้วยอาร์กิวเมนต์ "expire" → รันแค่ตรวจสอบหมดอายุ (ใช้สำหรับ Cron Job)
if [[ "$1" == "expire" ]]; then
    check_expire_users
    exit 0
fi

# ✅ ปกติ → เรียกใช้เมนูหลัก
main_menu
