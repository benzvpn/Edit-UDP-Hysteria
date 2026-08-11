#!/usr/bin/env bash
#
# hysteria2.sh - อัปเกรดจาก install_server.sh ต้นฉบับ
# ฟีเจอร์: ติดตั้ง/ถอน/อัปเดต + เพิ่ม-ลบผู้ใช้ + จำกัด IP + จำกัดวันหมดอายุ + เมนูภาษาไทย
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2023 Aperture Internet Laboratory
# Thai Mod + User Manager: Custom Build

set -e


### ============================================================
### 🔧 การตั้งค่า (จาก install_server.sh ต้นฉบับ ไม่แก้ไข)
### ============================================================
SCRIPT_NAME="$(basename "$0")"
SCRIPT_ARGS=("$@")

EXECUTABLE_INSTALL_PATH="/usr/local/bin/hysteria"
SYSTEMD_SERVICES_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/hysteria"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
REPO_URL="https://github.com/apernet/hysteria"
HY2_API_BASE_URL="https://api.hy2.io/v1"
CURL_FLAGS=(-L -f -q --retry 5 --retry-delay 10 --retry-max-time 60)

# ➕ เพิ่มสำหรับระบบผู้ใช้
USER_DB="${CONFIG_DIR}/users.db"
AUTH_HELPER="${CONFIG_DIR}/auth.sh"
ACL_FILE="${CONFIG_DIR}/acl.txt"
CRON_FILE="/etc/cron.d/hysteria-expire"

PACKAGE_MANAGEMENT_INSTALL="${PACKAGE_MANAGEMENT_INSTALL:-}"
OPERATING_SYSTEM="${OPERATING_SYSTEM:-}"
ARCHITECTURE="${ARCHITECTURE:-}"
HYSTERIA_USER="${HYSTERIA_USER:-}"
HYSTERIA_HOME_DIR="${HYSTERIA_HOME_DIR:-}"
SECONTEXT_SYSTEMD_UNIT="${SECONTEXT_SYSTEMD_UNIT:-}"

OPERATION=""
VERSION=""
FORCE=""
LOCAL_FILE=""


### ============================================================
### 🎨 ยูทิลิตี้ + สี (แปลงเป็นไทย)
### ============================================================
has_command() { type -P "$1" > /dev/null 2>&1; }
curl() { command curl "${CURL_FLAGS[@]}" "$@"; }
mktemp() { command mktemp "$@" "/tmp/hyservinst.XXXXXXXXXX"; }

tput() { has_command tput && command tput "$@" || true; }
tred() { tput setaf 1; }; tgreen() { tput setaf 2; }; tyellow() { tput setaf 3; }
tblue() { tput setaf 4; }; taoi() { tput setaf 6; }; tbold() { tput bold; }
treset() { tput sgr0; }

msg()     { echo -e "$(tbold)$*$(treset)"; }
ok()      { echo -e " $(tgreen)✓$(treset) $*"; }
warn()    { echo -e " $(tyellow)⚠$(treset) $*"; }
fail()    { echo -e " $(tred)✗$(treset) $*"; }
error()   { echo -e "$SCRIPT_NAME: $(tred)❌ ข้อผิดพลาด:$(treset) $*" >&2; }
note()    { echo -e "$SCRIPT_NAME: $(tbold)📝 หมายเหตุ:$(treset) $*"; }
line()    { echo "─────────────────────────────────────────────"; }
pause()   { read -rp "กด Enter เพื่อกลับเมนูหลัก... " _; }

has_prefix() {
  [[ -z "$2" ]] && return 0
  [[ -z "$1" ]] && return 1
  [[ "x$1" != "x${1#"$2"}" ]]
}

generate_random_password() {
  dd if=/dev/random bs=18 count=1 status=none | base64 | tr -d '/+=' | head -c 16
}

systemctl() {
  if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]] || ! has_command systemctl; then
    warn "ข้ามคำสั่ง systemd: systemctl $*"; return
  fi
  command systemctl "$@"
}

chcon() {
  if ! has_command chcon || [[ "x$FORCE_NO_SELINUX" == "x1" ]]; then return; fi
  command chcon "$@"
}

show_help() {
  echo
  msg "🔧 hysteria2.sh - วิธีใช้งาน"
  echo
  echo "  🖥️  เปิดเมนูแบบตอบโต้ (แนะนำ):"
  echo "     sudo bash $SCRIPT_NAME"
  echo
  echo "  ⚡ เรียกคำสั่งโดยตรง:"
  echo "     sudo bash $SCRIPT_NAME install    ติดตั้ง/อัปเดต Hysteria 2"
  echo "     sudo bash $SCRIPT_NAME remove     ถอนการติดตั้ง"
  echo "     sudo bash $SCRIPT_NAME check      ตรวจสอบเวอร์ชัน"
  echo "     sudo bash $SCRIPT_NAME add        เพิ่มผู้ใช้"
  echo "     sudo bash $SCRIPT_NAME del        ลบผู้ใช้"
  echo "     sudo bash $SCRIPT_NAME list       ดูรายชื่อ"
  echo "     sudo bash $SCRIPT_NAME ip         จำกัด IP"
  echo "     sudo bash $SCRIPT_NAME expire     ตั้งวันหมดอายุ"
  echo "     sudo bash $SCRIPT_NAME apply      นำไปใช้งาน + รีสตาร์ท"
  echo "     sudo bash $SCRIPT_NAME status     สถานะบริการ"
  echo
  exit 0
}


### ============================================================
### 🔐 สิทธิ์ / OS / สถาปัตยกรรม / systemd (จากต้นฉบับ เก็บไว้เหมือนเดิม)
### ============================================================
exec_sudo() {
  local _saved_ifs="$IFS"; IFS=$'\n'
  local _preserved_env=(
    $(env | grep "^PACKAGE_MANAGEMENT_INSTALL=" || true)
    $(env | grep "^OPERATING_SYSTEM=" || true)
    $(env | grep "^ARCHITECTURE=" || true)
    $(env | grep "^HYSTERIA_\w*=" || true)
    $(env | grep "^SECONTEXT_SYSTEMD_UNIT=" || true)
    $(env | grep "^FORCE_\w*=" || true)
  )
  IFS="$_saved_ifs"
  exec sudo env "${_preserved_env[@]}" "$@"
}

rerun_with_sudo() {
  has_command sudo || return 13
  local _target_script="$0"
  if has_prefix "$0" "/dev/" || has_prefix "$0" "/proc/"; then
    _target_script="$(mktemp)"; chmod +x "$_target_script"
    if has_command curl;      then curl -o "$_target_script" 'https://get.hy2.sh/'
    elif has_command wget;    then wget -O "$_target_script" 'https://get.hy2.sh'
    else return 127; fi
  fi
  note "กำลังรันซ้ำด้วยสิทธิ์ sudo..."
  exec_sudo "$_target_script" "${SCRIPT_ARGS[@]}"
}

check_permission() {
  [[ "$UID" -eq '0' ]] && return
  note "ผู้ใช้ปัจจุบันไม่ใช่ root"
  case "$FORCE_NO_ROOT" in
    '1') warn "FORCE_NO_ROOT=1 ดำเนินการต่อ (อาจผิดพลาด)"; ;;
    *)   rerun_with_sudo || { error "รันด้วย sudo หรือระบุ FORCE_NO_ROOT=1"; exit 13; } ;;
  esac
}

detect_package_manager() {
  [[ -n "$PACKAGE_MANAGEMENT_INSTALL" ]] && return 0
  if has_command apt;     then apt update; PACKAGE_MANAGEMENT_INSTALL='apt -y --no-install-recommends install'; return 0; fi
  if has_command dnf;     then PACKAGE_MANAGEMENT_INSTALL='dnf -y install'; return 0; fi
  if has_command yum;     then PACKAGE_MANAGEMENT_INSTALL='yum -y install'; return 0; fi
  if has_command zypper;  then PACKAGE_MANAGEMENT_INSTALL='zypper install -y --no-install-recommends'; return 0; fi
  if has_command pacman;  then PACKAGE_MANAGEMENT_INSTALL='pacman -Syu --noconfirm'; return 0; fi
  return 1
}

install_software() {
  local _p="$1"
  detect_package_manager || { error "ไม่พบตัวจัดการแพ็กเกจ ติดตั้ง '$_p' เอง"; exit 65; }
  echo "กำลังติดตั้ง $_p ..."
  $PACKAGE_MANAGEMENT_INSTALL "$_p" >/dev/null && ok "ติดตั้ง $_p เสร็จ" || { error "ติดตั้ง $_p ไม่สำเร็จ"; exit 65; }
}

is_user_exists() { id "$1" >/dev/null 2>&1; }

check_environment() {
  if [[ -n "$OPERATING_SYSTEM" ]]; then warn "บังคับ OS=$OPERATING_SYSTEM"
  else [[ "x$(uname)" == "xLinux" ]] || { error "รองรับเฉพาะ Linux"; exit 95; }; OPERATING_SYSTEM=linux; fi

  if [[ -n "$ARCHITECTURE" ]]; then warn "บังคับ ARCH=$ARCHITECTURE"
  else
    case "$(uname -m)" in
      i386|i686)         ARCHITECTURE=386 ;;
      amd64|x86_64)      ARCHITECTURE=amd64 ;;
      armv5*|armv6*|armv7*) ARCHITECTURE=arm ;;
      armv8*|aarch64)    ARCHITECTURE=arm64 ;;
      mips*|mips64*)     ARCHITECTURE=mipsle ;;
      s390x)             ARCHITECTURE=s390x ;;
      loongarch64)       ARCHITECTURE=loong64 ;;
      *) error "สถาปัตยกรรม $(uname -m) ไม่รองรับ"; exit 8 ;;
    esac
  fi

  if [[ ! -d "/run/systemd/system" ]] && ! grep -q systemd <(ls -l /sbin/init 2>/dev/null); then
    case "$FORCE_NO_SYSTEMD" in
      1) warn "FORCE_NO_SYSTEMD=1 ดำเนินการต่อ" ;;
      2) warn "FORCE_NO_SYSTEMD=2 ข้าม systemd" ;;
      *) error "ต้องการ Linux ที่ใช้ systemd"; exit 1 ;;
    esac
  fi

  has_command curl || install_software curl
  has_command grep || install_software grep
  has_command jq   || install_software jq
}

get_systemd_version() {
  has_command systemctl || return
  command systemctl --version 2>/dev/null | head -1 | cut -d' ' -f2
}

systemd_unit_working_directory() {
  local v="$(get_systemd_version || true)"
  if [[ -n "$v" && "$v" -lt "227" ]]; then echo "$HYSTERIA_HOME_DIR"; return; fi
  echo "~"
}

get_selinux_context() {
  local _f="$1" _r="$(ls -dZ "$_f" 2>/dev/null | head -1)"
  case "$(echo "$_r" | wc -w)" in
    2) echo "$_r" | cut -d' ' -f1 ;;
    5) echo "$_r" | cut -d' ' -f4 ;;
    *) echo "" ;;
  esac
}

check_hysteria_user() {
  [[ -n "$HYSTERIA_USER" ]] && return
  if [[ -e "$SYSTEMD_SERVICES_DIR/hysteria-server.service" ]]; then
    HYSTERIA_USER="$(grep -oP '^User=\K\w+' "$SYSTEMD_SERVICES_DIR/hysteria-server.service" 2>/dev/null || true)"
  fi
  : "${HYSTERIA_USER:=$1}"
}

check_hysteria_homedir() {
  [[ -n "$HYSTERIA_HOME_DIR" ]] && return
  if is_user_exists "$HYSTERIA_USER"; then HYSTERIA_HOME_DIR="$(eval echo ~"$HYSTERIA_USER")"
  else HYSTERIA_HOME_DIR="$1"; fi
}


### ============================================================
### 📦 เปรียบเทียบเวอร์ชัน / ดาวน์โหลด (จากต้นฉบับ เก็บเหมือนเดิม)
### ============================================================
vercmp_segment() {
  local l="$1" r="$2"
  [[ "x$l" == "x$r" ]] && { echo 0; return; }
  [[ -z "$l" ]] && { echo -1; return; }
  [[ -z "$r" ]] && { echo 1; return; }
  local ln="${l//[A-Za-z]*/}" rn="${r//[A-Za-z]*/}"
  [[ "x$ln" == "x$rn" ]] || { echo $((10#$ln - 10#$rn)); return; }
  local ls="${l#"$ln"}" rs="${r#"$rn"}"
  [[ "x$ls" == "x$rs" ]] && { echo 0; return; }
  [[ -z "$ls" ]] && { echo 1; return; }
  [[ -z "$rs" ]] && { echo -1; return; }
  [[ "$ls" < "$rs" ]] && echo -1 || echo 1
}

vercmp() {
  local l="${1#v}" r="${2#v}"
  while [[ -n "$l" && -n "$r" ]]; do
    local cl="${l/.*/}" cr="${r/.*/}" sc="$(vercmp_segment "$cl" "$cr")"
    [[ "$sc" -ne 0 ]] && { echo "$sc"; return; }
    l="${l#"$cl"}"; l="${l#.}"; r="${r#"$cr"}"; r="${r#.}"
  done
  [[ "x$l" == "x$r" ]] && echo 0 || { [[ -z "$l" ]] && echo -1 || echo 1; }
}

is_hysteria_installed() { [[ -f "$EXECUTABLE_INSTALL_PATH" || -h "$EXECUTABLE_INSTALL_PATH" ]]; }
is_hysteria1_version() { has_prefix "$1" "v1." || has_prefix "$1" "v0."; }

get_installed_version() {
  is_hysteria_installed || return
  if "$EXECUTABLE_INSTALL_PATH" version >/dev/null 2>&1; then
    "$EXECUTABLE_INSTALL_PATH" version | grep -oP '^Version\s+\Kv[\d.]+'
  elif "$EXECUTABLE_INSTALL_PATH" -v >/dev/null 2>&1; then
    "$EXECUTABLE_INSTALL_PATH" -v | awk '{print $3}'
  fi
}

get_latest_version() {
  [[ -n "$VERSION" ]] && { echo "$VERSION"; return; }
  local tmp="$(mktemp)"
  if ! curl -sS "$HY2_API_BASE_URL/update?cver=thai&plat=${OPERATING_SYSTEM}&arch=${ARCHITECTURE}&chan=release&side=server" -o "$tmp"; then
    error "ไม่สามารถเรียก Hysteria API ได้"; exit 11
  fi
  local lv="$(grep -oP '"lver"\s*:\s*"\Kv[^"]+' "$tmp" | head -1)"
  rm -f "$tmp"
  [[ -n "$lv" ]] && echo "$lv" || { error "ไม่พบเวอร์ชันล่าสุด"; exit 11; }
}

download_hysteria() {
  local ver="$1" out="$2"
  local url="$REPO_URL/releases/download/app/$ver/hysteria-$OPERATING_SYSTEM-$ARCHITECTURE"
  echo "🔽 ดาวน์โหลด $url"
  curl -R -H 'Cache-Control: no-cache' "$url" -o "$out" || { error "ดาวน์โหลดล้มเหลว"; return 11; }
  chmod +x "$out"
}

check_update() {
  echo -n "   เวอร์ชันที่ติดตั้ง : "
  local iv="$(get_installed_version)"
  [[ -n "$iv" ]] && echo "$iv" || echo "(ยังไม่ติดตั้ง)"
  echo -n "   เวอร์ชันล่าสุด     : "
  local lv="$(get_latest_version)"
  echo "$lv"; VERSION="$lv"
  local c="$(vercmp "$iv" "$lv")"
  [[ "$c" -lt 0 ]] && return 0 || return 1
}


### ============================================================
### 👤 ระบบฐานข้อมูลผู้ใช้ (users.db) ใหม่
###    รูปแบบ: user|pass|IP1,IP2|YYYY-MM-DD|note
### ============================================================
init_user_db() {
  mkdir -p "$CONFIG_DIR"
  [[ -f "$USER_DB" ]] || : > "$USER_DB"
  chown -R "$HYSTERIA_USER":"$HYSTERIA_USER" "$CONFIG_DIR" 2>/dev/null || true
  chmod 600 "$USER_DB" 2>/dev/null || true
}
user_exists()     { [[ -n "$1" ]] && grep -q "^${1}|" "$USER_DB" 2>/dev/null; }
add_user_db()     { echo "$1|$2|$3|$4|$5" >> "$USER_DB"; }
del_user_db()     { sed -i "/^${1}|/d" "$USER_DB"; }
count_users()     { wc -l < "$USER_DB" | tr -d ' '; }
get_user_field()  { awk -F'|' -v u="$1" -v i="$2" '$1==u {print $i; exit}' "$USER_DB"; }
set_user_field()  {
  awk -F'|' -v OFS='|' -v u="$1" -v i="$2" -v v="$3" '$1==u{$i=v} {print}' "$USER_DB" > "${USER_DB}.tmp"
  mv "${USER_DB}.tmp" "$USER_DB"
}


### ============================================================
### 🔑 Auth Helper (เช็ค รหัสผ่าน ✅ IP ✅ หมดอายุ ✅)
### ============================================================
build_auth_helper() {
  cat > "$AUTH_HELPER" <<'AUTH_EOF'
#!/usr/bin/env bash
set -euo pipefail
DB="/etc/hysteria/users.db"
LOG="/etc/hysteria/auth.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

[[ -z "${AUTH:-}" ]] && { log "AUTH ว่าง"; exit 1; }
USER="${AUTH%%:*}"; PASS="${AUTH#*:}"
[[ -z "$USER" || -z "$PASS" ]] && { log "AUTH ไม่ถูกต้อง"; exit 1; }

LINE="$(grep "^${USER}|" "$DB" 2>/dev/null || true)"
[[ -z "$LINE" ]] && { log "❌ ไม่พบ user=[$USER]"; exit 1; }
IFS='|' read -r DB_U DB_P DB_IPS DB_EXP DB_NOTE <<< "$LINE"

# 1) รหัสผ่าน
[[ "$PASS" != "$DB_P" ]] && { log "❌ [$USER] รหัสผิด IP=${SRC_ADDR:-?}"; exit 1; }

# 2) หมดอายุ
if [[ -n "$DB_EXP" && "$DB_EXP" != "0000-00-00" ]]; then
  [[ "$(date +%Y-%m-%d)" > "$DB_EXP" ]] && { log "⏰ [$USER] หมดอายุ $DB_EXP"; exit 1; }
fi

# 3) IP Whitelist
if [[ -n "$DB_IPS" ]]; then
  SIP="${SRC_ADDR%:*}"; SIP="${SIP#[}"; SIP="${SIP%]}"
  OK=0
  IFS=',' read -ra IPL <<< "$DB_IPS"
  for IP in "${IPL[@]}"; do
    [[ -z "$IP" ]] && continue
    if [[ "$IP" == */* ]] && command -v grepcidr >/dev/null; then
      echo "$SIP" | grepcidr "$IP" >/dev/null 2>&1 && { OK=1; break; }
    else
      [[ "$SIP" == "$IP" ]] && { OK=1; break; }
    fi
  done
  [[ "$OK" -ne 1 ]] && { log "🚫 [$USER] IP=$SIP ไม่อยู่ใน [$DB_IPS]"; exit 1; }
fi

log "✅ [$USER] เข้าสู่ระบบ IP=${SRC_ADDR:-?} exp=$DB_EXP"
echo "$USER"; exit 0
AUTH_EOF
  chmod +x "$AUTH_HELPER"
  chown "$HYSTERIA_USER":"$HYSTERIA_USER" "$AUTH_HELPER" 2>/dev/null || true
}


### ============================================================
### ⚙️ สร้าง config.yaml / ACL / systemd / cron
### ============================================================
install_content() {
  local _f="$1" _c="$2" _d="$3" _o="$4" _t="$(mktemp)"
  echo -ne "ติดตั้ง $_d ... "
  echo "$_c" > "$_t"
  if [[ -z "$_o" && -e "$_d" ]]; then echo "มีอยู่แล้ว"
  elif install "$_f" "$_t" "$_d"; then echo "เสร็จ"; fi
  rm -f "$_t"
}

tpl_server_svc() {
  cat <<EOF
[Unit]
Description=Hysteria 2 Server (ภาษาไทย)
After=network.target nss-lookup.target
[Service]
Type=simple
ExecStart=$EXECUTABLE_INSTALL_PATH server --config $CONFIG_FILE
WorkingDirectory=$(systemd_unit_working_directory)
User=$HYSTERIA_USER
Group=$HYSTERIA_USER
Environment=HYSTERIA_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF
}

tpl_server_x_svc() {
  cat <<EOF
[Unit]
Description=Hysteria 2 Server (%i)
After=network.target nss-lookup.target
[Service]
Type=simple
ExecStart=$EXECUTABLE_INSTALL_PATH server --config ${CONFIG_DIR}/%i.yaml
WorkingDirectory=$(systemd_unit_working_directory)
User=$HYSTERIA_USER
Group=$HYSTERIA_USER
Environment=HYSTERIA_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
}

tpl_config_yaml() {
  local D E
  D="$(grep -oP '^\s+-\s+\K\S+' "$CONFIG_FILE" 2>/dev/null | head -1)"
  E="$(grep -oP 'email:\s+\K\S+' "$CONFIG_FILE" 2>/dev/null | head -1)"
  : "${D:=your.domain.net}"; : "${E:=your@email.com}"
  cat <<CFG
# Hysteria 2 Config - สร้างโดย hysteria2.sh
# จัดการผู้ใช้ผ่านเมนู → ห้ามแก้ไขส่วน auth ด้วยตัวเอง!

# listen: :443

acme:
  domains:
    - $D
  email: $E

auth:
  type: command
  command: "$AUTH_HELPER"

acl:
  file: $ACL_FILE

masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com/
    rewriteHost: true

bandwidth:
  up: 1000 mbps
  down: 1000 mbps

udpIdleTimeout: 300s
CFG
}

tpl_acl() {
  cat <<'ACL'
# Hysteria 2 ACL
reject(10.0.0.0/8)
reject(172.16.0.0/12)
reject(192.168.0.0/16)
reject(127.0.0.0/8)
reject(169.254.0.0/16)
reject(fd00::/8)
reject(::1/128)
reject(fe80::/10)
reject(all, tcp/22)
reject(all, tcp/25)
reject(all, tcp/23)
direct(all)
ACL
}

build_all_configs() {
  init_user_db
  build_auth_helper
  mkdir -p "$CONFIG_DIR"
  install_content -Dm640 "$(tpl_config_yaml)"  "$CONFIG_FILE" "1"
  install_content -Dm644 "$(tpl_acl)"          "$ACL_FILE"    "1"
  install_content -Dm644 "$(tpl_server_svc)"   "$SYSTEMD_SERVICES_DIR/hysteria-server.service" "1"
  install_content -Dm644 "$(tpl_server_x_svc)" "$SYSTEMD_SERVICES_DIR/hysteria-server@.service" "1"
  if [[ -n "$SECONTEXT_SYSTEMD_UNIT" ]]; then
    chcon "$SECONTEXT_SYSTEMD_UNIT" "$SYSTEMD_SERVICES_DIR/hysteria-server.service" 2>/dev/null || true
    chcon "$SECONTEXT_SYSTEMD_UNIT" "$SYSTEMD_SERVICES_DIR/hysteria-server@.service" 2>/dev/null || true
  fi
  systemctl daemon-reload

  # cron หมดอายุอัตโนมัติ
  cat > "$CRON_FILE" <<CRON
0 3 * * * root [ -f $USER_DB ] && sed -i -E '/\|([0-9]{4}-[0-9]{2}-[0-9]{2})\$/ { s/^/EXPIRED_/; }' $USER_DB 2>/dev/null; systemctl restart hysteria-server >/dev/null 2>&1 || true
CRON
  chmod 644 "$CRON_FILE"
  systemctl restart cron >/dev/null 2>&1 || systemctl restart crond >/dev/null 2>&1 || true

  chown -R "$HYSTERIA_USER":"$HYSTERIA_USER" "$CONFIG_DIR" 2>/dev/null || true
  ok "สร้างไฟล์การตั้งค่าทั้งหมดเสร็จ"
}

apply_changes() {
  build_all_configs
  if is_hysteria_installed; then
    msg "🔄 รีสตาร์ทบริการ..."
    if systemctl restart hysteria-server 2>/dev/null; then
      ok "รีสตาร์ทสำเร็จ"
      sleep 1
      systemctl is-active --quiet hysteria-server && ok "บริการปกติ ✅" || warn "ยังไม่ขึ้น → journalctl -u hysteria-server -f"
    else
      warn "รีสตาร์ทไม่ได้ → systemctl enable --now hysteria-server"
    fi
  else
    note "ยังไม่ติดตั้ง binary → เมนู 1"
  fi
}


### ============================================================
### 🧑‍🤝‍🧑 เมนูจัดการผู้ใช้ (4 ฟีเจอร์ที่คุณขอ)
### ============================================================
input_required() {
  local v=""
  while [[ -z "$v" ]]; do
    read -rp "   $1 " v
    v="${v:-${2:-}}"
    [[ -z "$v" && -z "$2" ]] && fail "ห้ามเว้นว่าง"
  done
  echo "$v"
}
valid_date() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 1
  date -d "$1" "+%Y-%m-%d" >/dev/null 2>&1
}

list_simple() {
  echo "   ผู้ใช้ปัจจุบัน:"
  while IFS='|' read -r u _ _ e _; do
    [[ -z "$u" ]] && continue
    [[ "$e" == "0000-00-00" ]] && e="ไม่จำกัด"
    echo "     • $u  (หมดอายุ: $e)"
  done < "$USER_DB"
}

menu_add() {
  line; msg "➕ เพิ่มผู้ใช้ใหม่"
  local u p ips exp note
  while :; do
    u="$(input_required "ชื่อผู้ใช้ (ภาษาอังกฤษ): ")"
    user_exists "$u" && fail "มีชื่อนี้อยู่แล้ว" || break
  done
  p="$(input_required "รหัสผ่าน (Enter = สุ่ม): " "$(generate_random_password)")"
  read -rp "   IP ที่อนุญาต (คั่นด้วย , เว้นว่าง = ไม่จำกัด): " ips; ips="${ips// /}"
  while :; do
    read -rp "   วันหมดอายุ (YYYY-MM-DD / 0 = ไม่หมด): " exp
    exp="${exp:-0}"
    [[ "$exp" == "0" ]] && { exp="0000-00-00"; break; }
    valid_date "$exp" && break || fail "รูปแบบผิด เช่น $(date -d '+30 days' +%Y-%m-%d)"
  done
  read -rp "   หมายเหตุ: " note

  add_user_db "$u" "$p" "$ips" "$exp" "$note"
  line; ok "เพิ่ม [$u] เสร็จ"
  echo "   👤 User: $u   🔑 Pass: $p"
  [[ -n "$ips" ]] && echo "   🌐 IP: $ips" || echo "   🌐 IP: ไม่จำกัด"
  [[ "$exp" == "0000-00-00" ]] && echo "   ⏰ หมดอายุ: ไม่มีกำหนด" || echo "   ⏰ หมดอายุ: $exp"
  echo "   🔗 URI: hysteria2://${u}:${p}@โดเมนคุณ:443/?sni=โดเมนคุณ#${u}"
  echo
  read -rp "นำไปใช้งานทันที? (Y/n): " a
  [[ "${a,,}" != "n" ]] && apply_changes
  pause
}

menu_del() {
  line; msg "🗑️  ลบผู้ใช้"
  [[ "$(count_users)" -eq 0 ]] && { warn "ยังไม่มีผู้ใช้"; pause; return; }
  list_simple
  local u="$(input_required "ชื่อผู้ใช้ที่จะลบ: ")"
  user_exists "$u" || { fail "ไม่พบ [$u]"; pause; return; }
  read -rp "   พิมพ์ YES เพื่อยืนยันลบ [$u]: " ans
  [[ "$ans" == "YES" ]] || { warn "ยกเลิก"; pause; return; }
  del_user_db "$u"; ok "ลบ [$u] เสร็จ"
  read -rp "นำไปใช้งานทันที? (Y/n): " a
  [[ "${a,,}" != "n" ]] && apply_changes
  pause
}

menu_list() {
  line
  local n="$(count_users)"
  msg "📋 รายชื่อผู้ใช้ทั้งหมด ($n คน)"
  [[ "$n" -eq 0 ]] && { echo "   (ว่างเปล่า)"; pause; return; }
  printf "   %-3s %-14s %-14s %-20s %-12s %s\n" "ที่" "User" "Password" "IP" "หมดอายุ" "Note"
  printf "   %-3s %-14s %-14s %-20s %-12s %s\n" "───" "────────────" "────────────" "────────────────────" "────────────" "──────────"
  local i=0
  while IFS='|' read -r u p ips e nt; do
    [[ -z "$u" ]] && continue; ((i++))
    [[ "$e" == "0000-00-00" ]] && e="ไม่จำกัด"
    [[ -z "$ips" ]] && ips="ไม่จำกัด"
    [[ "$e" != "ไม่จำกัด" ]] && valid_date "$e" && [[ "$(date +%Y-%m-%d)" > "$e" ]] && e="❌ $e"
    printf "   %-3s %-14s %-14s %-20s %-12s %s\n" "$i" "$u" "$p" "${ips:0:20}" "$e" "${nt:0:18}"
  done < "$USER_DB"
  echo; pause
}

menu_ip() {
  line; msg "🌐 จำกัด IP ต่อผู้ใช้"
  [[ "$(count_users)" -eq 0 ]] && { warn "ยังไม่มีผู้ใช้"; pause; return; }
  list_simple
  local u="$(input_required "เลือก User: ")"
  user_exists "$u" || { fail "ไม่พบ [$u]"; pause; return; }
  local old="$(get_user_field "$u" 3)"; [[ -z "$old" ]] && old="(ไม่จำกัด)"
  echo "   IP ปัจจุบัน: $old"
  read -rp "   IP ใหม่ (, คั่น / เว้นว่าง = ไม่จำกัด / CIDR ได้): " ips; ips="${ips// /}"
  set_user_field "$u" 3 "$ips"
  [[ -z "$ips" ]] && ok "เปิดให้ทุก IP" || ok "ตั้ง IP = $ips"
  read -rp "นำไปใช้งานทันที? (Y/n): " a
  [[ "${a,,}" != "n" ]] && apply_changes
  pause
}

menu_expire() {
  line; msg "⏰ ตั้ง/แก้ไขวันหมดอายุ"
  [[ "$(count_users)" -eq 0 ]] && { warn "ยังไม่มีผู้ใช้"; pause; return; }
  list_simple
  local u="$(input_required "เลือก User: ")"
  user_exists "$u" || { fail "ไม่พบ [$u]"; pause; return; }
  local old="$(get_user_field "$u" 4)"; [[ "$old" == "0000-00-00" ]] && old="ไม่มีกำหนด"
  echo "   หมดอายุปัจจุบัน: $old"
  echo "   💡 เช่น +30 วัน = $(date -d '+30 days' +%Y-%m-%d)  |  +1 ปี = $(date -d '+1 year' +%Y-%m-%d)"
  local exp
  while :; do
    read -rp "   วันใหม่ (YYYY-MM-DD / 0 = ไม่หมด): " exp
    exp="${exp:-0}"
    [[ "$exp" == "0" ]] && { exp="0000-00-00"; break; }
    valid_date "$exp" && break || fail "รูปแบบผิด"
  done
  set_user_field "$u" 4 "$exp"
  [[ "$exp" == "0000-00-00" ]] && ok "ตั้งเป็นไม่หมดอายุ" || ok "ตั้งหมดอายุ = $exp"
  read -rp "นำไปใช้งานทันที? (Y/n): " a
  [[ "${a,,}" != "n" ]] && apply_changes
  pause
}


### ============================================================
### 🚀 ติดตั้ง / ถอน / อัปเดต / สถานะ (ปรับจาก install_server.sh)
### ============================================================
get_running_services() {
  [[ "x$FORCE_NO_SYSTEMD" == "x2" ]] && return
  systemctl list-units --state=active --plain --no-legend 2>/dev/null \
    | grep -o "hysteria-server@*[^\s]*.service" || true
}
restart_running() {
  [[ "x$FORCE_NO_SYSTEMD" == "x2" ]] && return
  for s in $(get_running_services); do
    echo -n "รีสตาร์ท $s ... "
    systemctl restart "$s" && echo "เสร็จ" || echo "ผิดพลาด"
  done
}
stop_running() {
  [[ "x$FORCE_NO_SYSTEMD" == "x2" ]] && return
  for s in $(get_running_services); do
    echo -n "หยุด $s ... "
    systemctl stop "$s" && echo "เสร็จ" || echo "ผิดพลาด"
  done
}

perform_install_binary() {
  if [[ -n "$LOCAL_FILE" ]]; then
    note "ติดตั้งจากไฟล์: $LOCAL_FILE"
    install -Dm755 "$LOCAL_FILE" "$EXECUTABLE_INSTALL_PATH" && ok "ติดตั้ง binary เสร็จ" || exit 2
    return
  fi
  local tmp="$(mktemp)"
  download_hysteria "$VERSION" "$tmp" || { rm -f "$tmp"; exit 11; }
  install -Dm755 "$tmp" "$EXECUTABLE_INSTALL_PATH" && ok "ติดตั้ง Hysteria $VERSION เสร็จ" || exit 13
  rm -f "$tmp"
}

menu_install() {
  line; msg "1️⃣  ติดตั้ง / อัปเดต Hysteria 2"
  check_permission; check_environment
  check_hysteria_user "hysteria"
  check_hysteria_homedir "/var/lib/$HYSTERIA_USER"
  if [[ -z "$SECONTEXT_SYSTEMD_UNIT" && -z "$FORCE_NO_SELINUX" ]] && has_command getenforce; then
    note "ตรวจพบ SELinux"
    [[ -e "$SYSTEMD_SERVICES_DIR" ]] && SECONTEXT_SYSTEMD_UNIT="$(get_selinux_context "$SYSTEMD_SERVICES_DIR")"
    [[ -z "$SECONTEXT_SYSTEMD_UNIT" ]] && warn "อ่าน SELinux context ไม่ได้"
  fi

  local fresh=0 up1=0 need=0
  if ! is_hysteria_installed; then fresh=1
  elif is_hysteria1_version "$(get_installed_version)"; then up1=1; fi

  if [[ -n "$LOCAL_FILE" || -n "$VERSION" ]] || check_update; then need=1; fi
  [[ "x$FORCE" == "x1" ]] && need=1

  if is_hysteria1_version "$VERSION"; then error "ติดตั้งได้แค่ Hysteria 2"; exit 95; fi
  [[ "$need" -eq 1 ]] && perform_install_binary

  if ! is_user_exists "$HYSTERIA_USER"; then
    echo -n "สร้าง user $HYSTERIA_USER ... "
    useradd -r -d "$HYSTERIA_HOME_DIR" -m -s /usr/sbin/nologin "$HYSTERIA_USER" 2>/dev/null && echo "OK" || echo "ข้าม"
  fi

  build_all_configs
  has_command apt && apt install -y grepcidr >/dev/null 2>&1 && ok "ติดตั้ง grepcidr (รองรับ CIDR)" || true

  line
  if [[ "$fresh" -eq 1 ]]; then
    msg "🎉 ติดตั้งเสร็จสมบูรณ์!"
    echo "   1) แก้ $CONFIG_FILE ใส่โดเมน+อีเมล ACME"
    echo "   2) DNS ชี้ไปที่ VPS นี้ + เปิด UDP 443"
    echo "   3) กลับเมนู → 4 เพิ่มผู้ใช้"
    echo "   4) systemctl enable --now hysteria-server"
  elif [[ "$up1" -eq 1 ]]; then
    warn "อัปเกรดจาก v1 → v2 (โปรโตคอลไม่เข้ากัน ต้องสร้างผู้ใช้ใหม่)"
  else
    msg "✅ อัปเดตเป็น $VERSION เสร็จ"
    restart_running
  fi
  pause
}

menu_remove() {
  line; msg "2️⃣  ถอนการติดตั้งทั้งหมด"
  read -rp "   ⚠ พิมพ์ DELETE เพื่อยืนยันลบทุกอย่าง: " ans
  [[ "$ans" != "DELETE" ]] && { warn "ยกเลิก"; pause; return; }
  stop_running
  systemctl disable hysteria-server.service >/dev/null 2>&1 || true
  rm -f "$EXECUTABLE_INSTALL_PATH"
  rm -f "$SYSTEMD_SERVICES_DIR"/hysteria-server*.service
  rm -f "$CRON_FILE"
  systemctl daemon-reload >/dev/null 2>&1 || true
  read -rp "   ลบ config + ผู้ใช้ทั้งหมดด้วย? (y/N): " a
  [[ "${a,,}" == "y" ]] && rm -rf "$CONFIG_DIR" && ok "ลบ $CONFIG_DIR เสร็จ"
  read -rp "   ลบ user $HYSTERIA_USER ด้วย? (y/N): " a
  [[ "${a,,}" == "y" && "$HYSTERIA_USER" != "root" ]] && userdel -r "$HYSTERIA_USER" 2>/dev/null && ok "ลบ user เสร็จ"
  ok "ถอนการติดตั้งเสร็จ"; pause
}

menu_check() {
  line; msg "3️⃣  ตรวจสอบเวอร์ชัน"
  check_permission; check_environment
  if check_update; then
    msg "💡 มีเวอร์ชันใหม่!"
    read -rp "   อัปเดตตอนนี้? (Y/n): " a
    [[ "${a,,}" != "n" ]] && { FORCE=1 perform_install_binary; apply_changes; }
  else ok "เป็นเวอร์ชันล่าสุดแล้ว ✅"; fi
  pause
}

menu_status() {
  line; msg "📊 สถานะบริการ"
  is_hysteria_installed || { warn "ยังไม่ติดตั้ง → เมนู 1"; pause; return; }
  echo "   เวอร์ชัน       : $(get_installed_version)"
  echo "   ผู้ใช้ทั้งหมด : $(count_users) คน"
  echo -n "   สถานะ         : "
  if systemctl is-active --quiet hysteria-server 2>/dev/null; then
    echo "$(tgreen)กำลังทำงาน ✅$(treset)"
    echo -n "   เปิดอัตโนมัติ : "
    systemctl is-enabled --quiet hysteria-server 2>/dev/null && echo "$(tgreen)เปิด$(treset)" || echo "$(tyellow)ยังไม่เปิด$(treset)"
    echo; msg "Log ล่าสุด (10 บรรทัด):"
    journalctl -u hysteria-server -n 10 --no-pager 2>/dev/null || warn "ดู log ไม่ได้"
  else
    echo "$(tred)หยุด ❌$(treset)  →  systemctl enable --now hysteria-server"
  fi
  pause
}


### ============================================================
### 🧭 เมนูหลัก & ตัวแยกวิเคราะห์
### ============================================================
show_main_menu() {
  clear
  echo
  msg "╔══════════════════════════════════════════╗"
  msg "║   🚀 Hysteria 2 Manager (ภาษาไทย)        ║"
  msg "╚══════════════════════════════════════════╝"
  echo
  echo "   $(tblue)0$(treset) 📖 คู่มือ / ช่วยเหลือ"
  echo "   $(tblue)1$(treset) 🟢 ติดตั้ง / อัปเดต Hysteria 2"
  echo "   $(tblue)2$(treset) 🔴 ถอนการติดตั้ง"
  echo "   $(tblue)3$(treset) 🔍 ตรวจสอบเวอร์ชันอัปเดต"
  echo
  echo "   ─────────── 🧑‍🤝‍🧑 จัดการผู้ใช้ ───────────"
  echo "   $(tgreen)4$(treset) ➕ เพิ่มผู้ใช้ (รหัสผ่าน + IP + หมดอายุ)"
  echo "   $(tgreen)5$(treset) ➖ ลบผู้ใช้"
  echo "   $(tgreen)6$(treset) 📋 แสดงรายชื่อทั้งหมด"
  echo "   $(tgreen)7$(treset) 🌐 จำกัด IP ต่อผู้ใช้"
  echo "   $(tgreen)8$(treset) ⏰ ตั้ง/แก้ไขวันหมดอายุ"
  echo
  echo "   ───────────── ⚙️ อื่นๆ ─────────────────"
  echo "   $(taoi)9$(treset)  ♻️ บันทึกการเปลี่ยนแปลง + รีสตาร์ท"
  echo "   $(taoi)10$(treset) 📊 สถานะบริการ & Log"
  echo "   $(tred)00$(treset) 🚪 ออกจากโปรแกรม"
  echo; line
}

main_menu() {
  check_permission; check_environment
  check_hysteria_user "hysteria"
  check_hysteria_homedir "/var/lib/$HYSTERIA_USER"
  init_user_db
  while :; do
    show_main_menu
    read -rp "   เลือก [0-10 / 00=ออก]: " c
    case "$c" in
      0)  show_help ;;
      1)  menu_install ;;
      2)  menu_remove ;;
      3)  menu_check ;;
      4)  menu_add ;;
      5)  menu_del ;;
      6)  menu_list ;;
      7)  menu_ip ;;
      8)  menu_expire ;;
      9)  apply_changes; pause ;;
      10) menu_status ;;
      00|q|Q|exit) msg "👋 ลาก่อน!"; exit 0 ;;
      *) fail "เลือกไม่ถูกต้อง"; sleep 1.2 ;;
    esac
  done
}

parse_arguments() {
  [[ $# -eq 0 ]] && { main_menu; exit 0; }
  case "$1" in
    -h|--help|help)     show_help ;;
    install)            OPERATION=install ;;
    remove|uninstall)   OPERATION=remove ;;
    check|update)       OPERATION=check ;;
    add|adduser)        OPERATION=add ;;
    del|rm|delete)      OPERATION=del ;;
    list|ls|users)      OPERATION=list ;;
    ip)                 OPERATION=ip ;;
    expire|date)        OPERATION=expire ;;
    apply|reload)       OPERATION=apply ;;
    status|info)        OPERATION=status ;;
    -f|--force)         FORCE=1; shift; parse_arguments "$@" ;;
    --version)          VERSION="$2"; shift 2; parse_arguments "$@" ;;
    -l|--local)         LOCAL_FILE="$2"; shift 2; parse_arguments "$@" ;;
    *) error "คำสั่ง '$1' ไม่รู้จัก → $SCRIPT_NAME --help"; exit 22 ;;
  esac
}

main() {
  parse_arguments "$@"
  check_permission; check_environment
  check_hysteria_user "hysteria"
  check_hysteria_homedir "/var/lib/$HYSTERIA_USER"
  init_user_db
  case "$OPERATION" in
    install) menu_install ;;
    remove)  menu_remove ;;
    check)   menu_check ;;
    add)     menu_add ;;
    del)     menu_del ;;
    list)    menu_list ;;
    ip)      menu_ip ;;
    expire)  menu_expire ;;
    apply)   apply_changes ;;
    status)  menu_status ;;
  esac
}

main "$@"
