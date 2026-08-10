#!/bin/bash
# ============================================================
# 🔥 Voltssh-X Hysteria 2 — No-Key Edition
# ✅ ไม่มีตรวจ Key / ใช้งานฟรี / วางรันได้เลย
# 📌 รองรับ: Ubuntu 20.04+ / Debian 11+
# 🎯 คุณสมบัติ: Multi User, Port Hopping, OBFS Salamander, Auto SSL
# ============================================================

# --------------------------
# 🔐 ตรวจสิทธิ์ Root
# --------------------------
checkRoot() {
    user=$(whoami)
    if [ ! "${user}" = "root" ]; then
        echo -e "\e[91mกรุณารันสคริปต์ด้วยผู้ใช้ root!\e[0m"
        exit 1
    fi
}

T_BOLD=$(tput bold)
T_GREEN=$(tput setaf 2)
T_YELLOW=$(tput setaf 3)
T_RED=$(tput setaf 1)
T_RESET=$(tput sgr0)

# --------------------------
# 📋 หัวสคริปต์
# --------------------------
script_header() {
    clear
    echo ""
    echo ".-.   .-..---.  ,-.  _______     "
    echo " \ \ / // .-. ) | | |__   __|    "
    echo "  \ V / | | |(_)| |   )| |       "
    echo "   ) /  | | | | | |  (_) |       "
    echo "  (_)   \ \`-' / | \`--. | |       "
    echo "         )---'  |( __.'\`-'       "
    echo "        (_)     (_)              "
    echo "  Hysteria 2 Installer (No-Key)"
    echo ""
    echo -e "\e[1m\e[34m****************************************************"
    echo -e "  การติดตั้งและตั้งค่า \e[1;36mHysteria Protocol v2"
    echo -e "              เวอร์ชันปรับแต่ง — ไม่มี Key Lock"
    echo -e "\e[1m\e[34m****************************************************\e[0m"
    echo ""
}

# --------------------------
# 📦 อัปเดตและติดตั้งพื้นฐาน
# --------------------------
update_packages() {
    clear
    echo ""
    echo -e "\033[1;32m[✅] ⇢ กำลังเตรียมไฟล์ที่จำเป็น...\033[0m"
    echo -e "\033[1;33m       ♻️ กรุณารอสักครู่...\033[0m"
    echo ""

    sudo apt-get update -y && sudo apt-get upgrade -y

    local dependencies=("curl" "bc" "grep" "wget" "nano" "net-tools" "figlet" "jq" "python3" "openssl")
    for dependency in "${dependencies[@]}"; do
        if ! command -v "$dependency" &>/dev/null; then
            echo "${T_YELLOW}กำลังติดตั้ง $dependency...${T_RESET}"
            apt update -y && apt install -y "$dependency" >/dev/null 2>&1
        fi
    done

    sudo apt-get install -y wget nano net-tools figlet lolcat iptables-persistent >/dev/null 2>&1
    export PATH="/usr/games:$PATH"
    [ ! -e /usr/local/bin/lolcat ] && sudo ln -s /usr/games/lolcat /usr/local/bin/lolcat 2>/dev/null

    DEBIAN_FRONTEND=noninteractive apt-get -qq install -yqq --no-install-recommends ca-certificates >/dev/null 2>&1

    clear
    echo -e "\033[1;32m[✅] ⇢ เตรียมไฟล์เรียบร้อย\033[0m"
    echo ""
}

# --------------------------
# 🎨 ตั้งค่า Banner ตอน Login
# --------------------------
banner() {
    sed -i '/figlet -k Voltssh-X | lolcat/,/echo -e ""/d' ~/.bashrc 2>/dev/null
    sed -i '/figlet -k Hysteria | lolcat/,/echo -e ""/d' ~/.bashrc 2>/dev/null

    {
        echo 'clear'
        echo 'figlet -k Hysteria 2 | lolcat'
        echo 'echo ""'
        echo 'echo -e "\t\e[92m✅ Hysteria 2 Server — No-Key Edition\e[0m"'
        echo 'echo -e "\t\e[93mพิมพ์: volt-user เพื่อจัดการ User\e[0m"'
        echo 'echo ""'
        echo 'DATE=$(date +"%d-%m-%y")'
        echo 'TIME=$(date +"%T")'
        echo 'echo -e "\tIP: $(curl -s https://api.ipify.org 2>/dev/null)"'
        echo 'echo -e "\tเวลา: $DATE $TIME"'
        echo 'echo ""'
    } >> ~/.bashrc

    cat /dev/null > ~/.bash_history
    history -c
}

# --------------------------
# ✅ ตั้งค่าเริ่มต้น (ไม่มีตรวจ Key อีกต่อไป!)
# --------------------------
verification() {
    clear

    figlet -k Hysteria 2 | lolcat
    echo "───────────────────────────────────────────────────────────────────────•"
    echo ""
    echo -e "  ✅ ${T_GREEN}เวอร์ชันไม่มี Key — เริ่มติดตั้งเลย${T_RESET}"
    echo -e "  ℹ️  กรุณาเตรียม: โดเมน (ใช้ DuckDNS ฟรีได้), OBFS, รหัสผ่าน User แรก"
    echo ""
    echo "───────────────────────────────────────────────────────────────────────•"
    sleep 1

    # ฟังก์ชันตรวจความยาว
    validate_length() {
        local input_string="$1"
        local min_length="$2"
        if [ ${#input_string} -lt $min_length ]; then
            echo "⚠️  ต้องมีความยาวอย่างน้อย $min_length ตัวอักษร"
            return 1
        fi
        return 0
    }

    clear
    figlet -k Hysteria 2 | lolcat
    echo "───────────────────────────────────────────────────────────────────────•"
    echo -e "   ⚙️  การตั้งค่าเซิร์ฟเวอร์ Hysteria 2"
    echo "───────────────────────────────────────────────────────────────────────•"
    echo ""

    # ดึง IP อัตโนมัติ
    HYST_SERVER_IP=$(curl -s https://api.ipify.org)
    echo -e "\n🌐 IP เซิร์ฟเวอร์ของคุณ 👉 ${T_GREEN}$HYST_SERVER_IP${T_RESET}"
    echo "-------------------------------------------"

    # ถามโดเมน
    echo -e "\n🔗 กรุณากรอกโดเมนของคุณ:"
    echo -e "   (ฟรีได้ที่: https://duckdns.org)"
    read -p "   โดเมน: " DOMAIN
    DOMAIN=$(echo "$DOMAIN" | tr -d '[:space:]')
    echo "-------------------------------------------"

    # ถาม OBFS
    while true; do
        echo -e "\n🔐 กรุณากรอก OBFS (รหัสปกปิดแพ็กเกจ):"
        echo -e "   (อย่างน้อย 10 ตัวอักษร — ใช้ร่วมกับ Client)"
        read -p "   OBFS: " OBFS
        OBFS=$(echo "$OBFS" | tr -d '[:space:]')
        validate_length "$OBFS" 10 && break
    done
    echo "-------------------------------------------"

    # ถามรหัสผ่าน User แรก
    while true; do
        echo -e "\n👤 กรุณาสร้างรหัสผ่านสำหรับ User แรก:"
        echo -e "   (อย่างน้อย 10 ตัวอักษร — ใช้เข้าเชื่อมต่อ)"
        read -p "   Password: " PASSWORD
        PASSWORD=$(echo "$PASSWORD" | tr -d '[:space:]')
        validate_length "$PASSWORD" 10 && break
    done
    echo ""

    # ค่าคงที่
    mkdir -p /etc/volt
    PROTOCOL="udp"
    UDP_PORT="36712"
    UDP_PORT_HP="10000-65000"
    remarks="Hysteria2-NoKey"

    # บันทึกค่า
    echo "$DOMAIN" > /etc/volt/DOMAIN
    echo "$PROTOCOL" > /etc/volt/PROTOCOL
    echo "$UDP_PORT" > /etc/volt/UDP_PORT
    echo "$UDP_PORT_HP" > /etc/volt/UDP_PORT_HP
    echo "$OBFS" > /etc/volt/OBFS
    echo "$PASSWORD" > /etc/volt/PASSWORD

    # ส่งออกตัวแปร
    export DOMAIN PROTOCOL UDP_PORT UDP_PORT_HP OBFS PASSWORD HYST_SERVER_IP remarks
    SCRIPT_NAME="$(basename "$0")"
    SCRIPT_ARGS=("$@")

    # ✅ เรียกติดตั้งระบบ Multi User
    install_volt_multi_user
}

# --------------------------
# 🧩 ตัวแปรและฟังก์ชันพื้นฐาน Hysteria
# --------------------------
EXECUTABLE_INSTALL_PATH="/usr/local/bin/hysteria"
SYSTEMD_SERVICES_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/hysteria"
REPO_URL="https://github.com/apernet/hysteria"
API_BASE_URL="https://api.github.com/repos/apernet/hysteria"
CURL_FLAGS=(-L -f -q --retry 5 --retry-delay 10 --retry-max-time 60)

has_command() { type -P "$1" >/dev/null 2>&1; }
curl() { command curl "${CURL_FLAGS[@]}" "$@"; }
mktemp() { command mktemp "$@" "hyservinst.XXXXXXXXXX"; }
tred() { tput setaf 1; }; tgreen() { tput setaf 2; }; tyellow() { tput setaf 3; }
note() { echo -e "$(tput bold)ℹ️  $_msg$(tput sgr0)"; }
warning() { echo -e "$(tyellow)⚠️  $_msg$(tput sgr0)"; }
error() { echo -e "$(tred)❌ $_msg$(tput sgr0)"; }

systemctl() {
    [[ "x$FORCE_NO_SYSTEMD" == "x2" ]] || ! has_command systemctl && return
    command systemctl "$@"
}

detect_package_manager() {
    has_command apt && { PACKAGE_MANAGEMENT_INSTALL='apt update -y; apt -y install'; return 0; }
    has_command dnf && { PACKAGE_MANAGEMENT_INSTALL='dnf check-update; dnf -y install'; return 0; }
    has_command yum && { PACKAGE_MANAGEMENT_INSTALL='yum update -y; yum -y install'; return 0; }
    return 1
}

install_software() {
    local _p="$1"
    detect_package_manager || { error "ไม่พบ Package Manager"; exit 65; }
    echo "กำลังติดตั้ง $_p..."
    $PACKAGE_MANAGEMENT_INSTALL "$_p" >/dev/null 2>&1 || { error "ติดตั้ง $_p ไม่สำเร็จ"; exit 65; }
}

is_user_exists() { id "$1" >/dev/null 2>&1; }

check_environment() {
    [[ "x$(uname)" == "xLinux" ]] || { error "รองรับเฉพาะ Linux"; exit 95; }
    case "$(uname -m)" in
        'i386'|'i686') ARCHITECTURE='386' ;;
        'amd64'|'x86_64') ARCHITECTURE='amd64' ;;
        'armv5tel'|'armv6l'|'armv7'|'armv7l') ARCHITECTURE='arm' ;;
        'armv8'|'aarch64') ARCHITECTURE='arm64' ;;
        *) error "ไม่รองรับสถาปัตยกรรม $(uname -m)"; exit 8 ;;
    esac
    OPERATING_SYSTEM=linux
    has_command curl || install_software curl
    has_command grep || install_software grep
}

check_hysteria_user() {
    [[ -n "$HYSTERIA_USER" ]] && return
    [[ ! -e "$SYSTEMD_SERVICES_DIR/hysteria.service" ]] && { HYSTERIA_USER="$1"; return; }
    HYSTERIA_USER="$(grep -o '^User=\w*' "$SYSTEMD_SERVICES_DIR/hysteria.service" | tail -1 | cut -d= -f2)"
    [[ -z "$HYSTERIA_USER" ]] && HYSTERIA_USER="$1"
}

check_hysteria_homedir() {
    [[ -n "$HYSTERIA_HOME_DIR" ]] && return
    is_user_exists "$HYSTERIA_USER" && HYSTERIA_HOME_DIR="$(eval echo ~"$HYSTERIA_USER")" || HYSTERIA_HOME_DIR="$1"
}

# --------------------------
# 📥 ดาวน์โหลด Hysteria
# --------------------------
get_latest_version() {
    [[ -n "$VERSION" ]] && { echo "$VERSION"; return; }
    local _v
    _v="$(command curl -fsSL \
        -H 'Accept: application/vnd.github+json' \
        "$API_BASE_URL/releases/latest" |
        grep -o '"tag_name":[[:space:]]*"[^"]*"' | head -1 |
        sed -E 's/.*"tag_name":[[:space:]]*"([^"]*)".*/\1/')"
    [[ -z "$_v" ]] && { error "ไม่สามารถตรวจเวอร์ชันล่าสุดได้"; exit 11; }
    echo "$_v"
}

download_hysteria() {
    local _v="$1" _d="$2"
    local _url="$REPO_URL/releases/download/$_v/hysteria-$OPERATING_SYSTEM-$ARCHITECTURE"
    echo "📥 กำลังดาวน์โหลด Hysteria $_v ..."
    curl -R -H 'Cache-Control: no-cache' "$_url" -o "$_d" || { error "ดาวน์โหลดไม่สำเร็จ"; return 11; }
    return 0
}

perform_install_hysteria_binary() {
    local _tmp
    _tmp=$(mktemp)
    VERSION="$(get_latest_version)"
    echo "✅ ตรวจพบเวอร์ชันล่าสุด: $VERSION"
    download_hysteria "$VERSION" "$_tmp" || { rm -f "$_tmp"; exit 11; }
    echo -n "⚙️  กำลังติดตั้ง ... "
    install -Dm755 "$_tmp" "$EXECUTABLE_INSTALL_PATH" && echo "สำเร็จ" || { rm -f "$_tmp"; exit 13; }
    rm -f "$_tmp"
}

# --------------------------
# ⚙️ Systemd Service
# --------------------------
tpl_hysteria_service() {
    cat <<EOF
[Unit]
Description=Hysteria 2 Server (No-Key Edition)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/etc/hysteria
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
}

perform_install_systemd() {
    [[ "x$FORCE_NO_SYSTEMD" == "x2" ]] && return
    install -Dm644 <(tpl_hysteria_service) "$SYSTEMD_SERVICES_DIR/hysteria.service"
    systemctl daemon-reload
}

perform_install_home() {
    is_user_exists "$HYSTERIA_USER" || {
        echo -n "👤 สร้างผู้ใช้ $HYSTERIA_USER ... "
        useradd -r -d "$HYSTERIA_HOME_DIR" -m "$HYSTERIA_USER" && echo "สำเร็จ"
    }
}

# --------------------------
# 🔐 SSL Certificate (รับรองเอง)
# --------------------------
setup_ssl() {
    echo "🔐 กำลังสร้าง SSL Certificate..."
    mkdir -p /etc/hysteria
    openssl genrsa -out /etc/hysteria/hysteria.ca.key 2048 2>/dev/null
    openssl req -new -x509 -days 3650 \
        -key /etc/hysteria/hysteria.ca.key \
        -subj "/C=TH/ST=Bangkok/L=Bangkok/O=Hysteria/CN=Hysteria CA" \
        -out /etc/hysteria/hysteria.ca.crt 2>/dev/null
    openssl req -newkey rsa:2048 -nodes \
        -keyout /etc/hysteria/hysteria.server.key \
        -subj "/C=TH/ST=Bangkok/L=Bangkok/O=Hysteria/CN=$DOMAIN" \
        -out /etc/hysteria/hysteria.server.csr 2>/dev/null
    openssl x509 -req \
        -extfile <(printf "subjectAltName=DNS:$DOMAIN,DNS:*.$DOMAIN,IP:$HYST_SERVER_IP") \
        -days 3650 \
        -in /etc/hysteria/hysteria.server.csr \
        -CA /etc/hysteria/hysteria.ca.crt \
        -CAkey /etc/hysteria/hysteria.ca.key \
        -CAcreateserial \
        -out /etc/hysteria/hysteria.server.crt 2>/dev/null
    chmod 600 /etc/hysteria/*.key
    echo "✅ SSL สร้างเสร็จ"
}

# --------------------------
# 🧑‍🤝‍🧑 ระบบ Multi User (Python)
# --------------------------
VOLT_DIR="/etc/volt"
HY_CONFIG_DIR="/etc/hysteria"
VOLT_AUTH="$VOLT_DIR/auth.py"
VOLT_CFGUPT="$VOLT_DIR/cfgupt.py"
VOLT_CONFIG="$VOLT_DIR/config.json"
HY_CONFIG="$HY_CONFIG_DIR/config.json"

install_volt_python_dependencies() {
    mkdir -p "$VOLT_DIR" "$HY_CONFIG_DIR"
    has_command python3 || install_software python3
    has_command openssl || install_software openssl
}

install_volt_auth_py() {
cat <<'PYEOF' > "$VOLT_AUTH"
#!/usr/bin/env python3
import json, os, re, secrets, string, tempfile
from urllib.parse import quote

CONFIG_FILE = "/etc/volt/config.json"
DEFAULT_CONFIG = {
    "version": 2,
    "server": {"domain":"","ip":"","port":36712,"port_hopping":"10000-65000","protocol":"udp","obfs":"","bandwidth_up":"100 mbps","bandwidth_down":"100 mbps"},
    "users": {}
}

def atomic_write(p,d):
    d=os.path.dirname(p) or "."; os.makedirs(d,exist_ok=True)
    fd,t=tempfile.mkstemp(prefix=".cfg.",suffix=".tmp",dir=d)
    try:
        with os.fdopen(fd,"w",encoding="utf-8") as f: json.dump(d,f,indent=2,ensure_ascii=False); f.write("\n")
        os.chmod(t,0o600); os.replace(t,p)
    except:
        try: os.unlink(t)
        except: pass; raise

def norm(d):
    if not isinstance(d,dict): d={}
    d.setdefault("version",2)
    d.setdefault("server",{}); d.setdefault("users",{})
    for k,v in DEFAULT_CONFIG["server"].items(): d["server"].setdefault(k,v)
    return d

def load():
    os.makedirs(os.path.dirname(CONFIG_FILE) or ".",exist_ok=True)
    if not os.path.exists(CONFIG_FILE):
        d=json.loads(json.dumps(DEFAULT_CONFIG)); save(d); return d
    with open(CONFIG_FILE,"r",encoding="utf-8") as f: d=json.load(f)
    return norm(d)

def save(d): atomic_write(CONFIG_FILE,norm(d))
def valid_user(u): return isinstance(u,str) and bool(re.fullmatch(r"[A-Za-z0-9_.-]+",u)) and 1<=len(u)<=64
def valid_pass(p): return isinstance(p,str) and 10<=len(p)<=256
def gen_pass(l=16): return "".join(secrets.choice(string.ascii_letters+string.digits) for _ in range(l))

def add_user(u,p):
    if not valid_user(u): raise ValueError("Username ไม่ถูกต้อง (A-Z a-z 0-9 _ . -)")
    if not valid_pass(p): raise ValueError("Password ต้อง 10-256 ตัว")
    d=load()
    if u in d["users"]: raise ValueError("Username ซ้ำ")
    d["users"][u]={"password":p,"enabled":True}; save(d); return d

def update_pass(u,p):
    if not valid_pass(p): raise ValueError("Password ต้อง 10-256 ตัว")
    d=load()
    if u not in d["users"]: raise ValueError("ไม่พบ User")
    d["users"][u]["password"]=p; save(d); return d

def del_user(u):
    d=load()
    if u not in d["users"]: raise ValueError("ไม่พบ User")
    del d["users"][u]; save(d); return d

def set_enabled(u,e):
    d=load()
    if u not in d["users"]: raise ValueError("ไม่พบ User")
    d["users"][u]["enabled"]=bool(e); save(d); return d

def get_users():
    d=load(); r=[]
    for u,v in d["users"].items():
        if isinstance(v,dict): r.append({"username":u,"password":v.get("password",""),"enabled":v.get("enabled",True)})
        else: r.append({"username":u,"password":str(v),"enabled":True})
    return r

def get_enabled(): return [x for x in get_users() if x["enabled"]]
def get_user(u):
    d=load(); v=d["users"].get(u)
    if not v: return None
    if isinstance(v,dict): return {"username":u,"password":v.get("password",""),"enabled":v.get("enabled",True)}
    return {"username":u,"password":str(v),"enabled":True}

def build_auth(): return {u["username"]:u["password"] for u in get_enabled()}
def esc(v): return quote(str(v),safe="")

def build_uri(u):
    d=load(); s=d["server"]
    dom=s.get("domain",""); port=s.get("port_hopping","10000-65000"); obfs=s.get("obfs","")
    ud=get_user(u)
    if not ud: raise ValueError("ไม่พบ User")
    return (f"hysteria2://{esc(u)}:{esc(ud['password'])}@{dom}:{port}/"
            f"?obfs=salamander&obfs-password={esc(obfs)}&insecure=1&sni={dom}")

def migrate_old(p,u="user1"):
    d=load()
    if d["users"] or not p or not valid_pass(p): return False
    d["users"][u]={"password":p,"enabled":True}; save(d); return True

if __name__=="__main__": print(json.dumps(load(),indent=2,ensure_ascii=False))
PYEOF
chmod 700 "$VOLT_AUTH"
}

install_volt_cfgupt_py() {
cat <<'PYEOF' > "$VOLT_CFGUPT"
#!/usr/bin/env python3
import getpass, json, os, secrets, string, subprocess, sys
sys.path.insert(0,"/etc/volt")
import auth

CONFIG_FILE="/etc/volt/config.json"
HY_CONFIG="/etc/hysteria/config.json"
G="\033[92m"; Y="\033[93m"; R="\033[91m"; C="\033[96m"; W="\033[97m"; RS="\033[0m"; B="\033[1m"

def clear(): os.system("clear")
def header():
    clear()
    print(f"\n{C}{B}"+"="*46+f"{RS}")
    print(f"{C}{B}        Hysteria 2 — User Manager{RS}")
    print(f"{C}{B}"+"="*46+f"{RS}\n")
def pause(): input(f"\n{Y}กด Enter เพื่อดำเนินการต่อ...{RS}")
def rnd(l=16): return "".join(secrets.choice(string.ascii_letters+string.digits) for _ in range(l))

def restart():
    try: subprocess.run(["systemctl","restart","hysteria"],check=False); return True
    except: return False

def check_cfg():
    try:
        r=subprocess.run(["/usr/local/bin/hysteria","server","-c",HY_CONFIG,"check"],
                         capture_output=True,text=True)
        print(r.stdout); return r.returncode==0
    except: return True

def gen_cfg():
    d=auth.load(); s=d["server"]; users=auth.build_auth()
    if not users: print(f"{R}ต้องมี User อย่างน้อย 1{RS}"); sys.exit(1)
    cfg={
        "listen": ":"+str(s.get("port_hopping","10000-65000")),
        "tls":{"cert":"/etc/hysteria/hysteria.server.crt","key":"/etc/hysteria/hysteria.server.key"},
        "auth":{"type":"userpass","userpass":users},
        "obfs":{"type":"salamander","salamander":{"password":s.get("obfs","")}},
        "bandwidth":{"up":s.get("bandwidth_up","100 mbps"),"down":s.get("bandwidth_down","100 mbps")},
        "disableUDP": False
    }
    os.makedirs(os.path.dirname(HY_CONFIG),exist_ok=True)
    tmp=HY_CONFIG+".tmp"
    with open(tmp,"w",encoding="utf-8") as f: json.dump(cfg,f,indent=2,ensure_ascii=False); f.write("\n")
    os.chmod(tmp,0o600); os.replace(tmp,HY_CONFIG)
    return cfg

def apply():
    print(f"{Y}กำลังสร้าง Config...{RS}")
    try: gen_cfg()
    except Exception as e: print(f"{R}ผิดพลาด: {e}{RS}"); return False
    print(f"{G}✅ สร้าง Config เสร็จ{RS}")
    print(f"{Y}กำลังตรวจสอบ Config...{RS}")
    if not check_cfg(): print(f"{R}❌ Config ไม่ถูกต้อง{RS}"); return False
    print(f"{G}✅ Config ถูกต้อง{RS}")
    print(f"{Y}กำลังรีสตาร์ท Hysteria...{RS}")
    restart(); print(f"{G}✅ รีสตาร์ทเสร็จ{RS}")
    return True

def list_users():
    header(); us=auth.get_users()
    if not us: print(f"{Y}ยังไม่มี User{RS}"); pause(); return
    print(f"{W}{B}รายการ User ({len(us)} คน){RS}\n")
    for i,u in enumerate(us,1):
        st=f"{G}เปิด{RS}" if u["enabled"] else f"{R}ปิด{RS}"
        print(f"{C}{i:03d}.{RS} {W}{u['username']:<20}{RS} [{st}]")
    pause()

def add_user():
    header(); print(f"{C}➕ เพิ่ม User ใหม่{RS}\n")
    while True:
        u=input("Username: ").strip()
        if not auth.valid_user(u): print(f"{R}Username ไม่ถูกต้อง{RS}"); continue
        if auth.get_user(u): print(f"{R}Username นี้มีอยู่แล้ว{RS}"); continue
        break
    print("\n1. กรอก Password เอง\n2. สุ่มให้อัตโนมัติ")
    c=input("\nเลือก [1-2]: ").strip()
    if c=="2":
        p=rnd(20); print(f"\n{G}✅ Password: {p}{RS}")
    else:
        while True:
            p=getpass.getpass("Password: ")
            if not auth.valid_pass(p): print(f"{R}ต้อง 10-256 ตัว{RS}"); continue
            p2=getpass.getpass("ยืนยัน Password: ")
            if p!=p2: print(f"{R}ไม่ตรงกัน{RS}"); continue
            break
    try: auth.add_user(u,p)
    except Exception as e: print(f"{R}{e}{RS}"); pause(); return
    if apply():
        print(f"\n{G}✅ เพิ่มสำเร็จ{RS}\n{W}Username: {u}\nPassword: {p}{RS}")
        try: print(f"\n{C}🔗 URI:{RS}\n{auth.build_uri(u)}")
        except: pass
    pause()

def change_pass():
    header()
    u=input("Username ที่จะเปลี่ยน: ").strip()
    if not auth.get_user(u): print(f"{R}ไม่พบ{RS}"); pause(); return
    while True:
        p=getpass.getpass("Password ใหม่: ")
        if not auth.valid_pass(p): print(f"{R}ต้อง 10-256 ตัว{RS}"); continue
        p2=getpass.getpass("ยืนยัน: ")
        if p!=p2: print(f"{R}ไม่ตรงกัน{RS}"); continue
        break
    try: auth.update_pass(u,p)
    except Exception as e: print(f"{R}{e}{RS}"); pause(); return
    if apply():
        print(f"\n{G}✅ เปลี่ยนสำเร็จ{RS}")
        try: print(f"{C}🔗 URI:{RS}\n{auth.build_uri(u)}")
        except: pass
    pause()

def del_user():
    header()
    u=input("Username ที่จะลบ: ").strip()
    if not auth.get_user(u): print(f"{R}ไม่พบ{RS}"); pause(); return
    c=input(f"\n{Y}ยืนยันลบ {u}? [y/N]: {RS}").strip().lower()
    if c!="y": print("ยกเลิก"); pause(); return
    try: auth.del_user(u)
    except Exception as e: print(f"{R}{e}{RS}"); pause(); return
    if apply(): print(f"\n{G}✅ ลบสำเร็จ{RS}")
    pause()

def toggle():
    header(); u=input("Username: ").strip()
    ud=auth.get_user(u)
    if not ud: print(f"{R}ไม่พบ{RS}"); pause(); return
    ns=not ud["enabled"]; auth.set_enabled(u,ns)
    if apply(): print(f"\n{G}✅ {'เปิด' if ns else 'ปิด'} {u} เสร็จ{RS}")
    pause()

def show_user():
    header(); u=input("Username: ").strip()
    ud=auth.get_user(u)
    if not ud: print(f"{R}ไม่พบ{RS}"); pause(); return
    print(f"\n{C}👤 Username : {ud['username']}{RS}")
    print(f"{C}🔑 Password : {ud['password']}{RS}")
    print(f"{C}⚡ สถานะ   : {'เปิดใช้' if ud['enabled'] else 'ปิด'}{RS}")
    try: print(f"\n{Y}🔗 เชื่อมต่อ URI:{RS}\n{auth.build_uri(u)}")
    except Exception as e: print(f"{R}สร้าง URI ไม่ได้: {e}{RS}")
    pause()

def show_cfg():
    header()
    try:
        with open(CONFIG_FILE,"r",encoding="utf-8") as f: print(json.dumps(json.load(f),indent=2,ensure_ascii=False))
    except Exception as e: print(f"{R}{e}{RS}")
    pause()

def regenerate():
    header()
    if apply(): print(f"{G}✅ สร้าง Config ใหม่เสร็จ{RS}")
    pause()

def main():
    if os.geteuid()!=0: print("รันด้วย root เท่านั้น"); sys.exit(1)
    while True:
        header()
        us=auth.get_users()
        print(f"{W}👥 จำนวน User ทั้งหมด: {len(us)}{RS}\n")
        print(f"{G}1.{RS} เพิ่ม User ใหม่")
        print(f"{G}2.{RS} ดูรายการ User ทั้งหมด")
        print(f"{G}3.{RS} แสดงรายละเอียด + URI User")
        print(f"{G}4.{RS} เปลี่ยน Password User")
        print(f"{G}5.{RS} ลบ User")
        print(f"{G}6.{RS} เปิด/ปิด การใช้งาน User")
        print(f"{G}7.{RS} สร้าง Hysteria Config ใหม่ + รีสตาร์ท")
        print(f"{G}8.{RS} แสดงไฟล์ config.json ของระบบ")
        print(f"{R}0.{RS} ออกจากโปรแกรม\n")
        c=input("เลือกเมนู: ").strip()
        if c=="1": add_user()
        elif c=="2": list_users()
        elif c=="3": show_user()
        elif c=="4": change_pass()
        elif c=="5": del_user()
        elif c=="6": toggle()
        elif c=="7": regenerate()
        elif c=="8": show_cfg()
        elif c=="0": clear(); break
        else: print(f"{R}เลือกไม่ถูกต้อง{RS}"); pause()

if __name__=="__main__": main()
PYEOF
chmod 700 "$VOLT_CFGUPT"
}

install_volt_config_json() {
    if [ ! -f "$VOLT_CONFIG" ]; then
        cat <<EOF > "$VOLT_CONFIG"
{
  "version": 2,
  "server": {
    "domain": "$DOMAIN",
    "ip": "$HYST_SERVER_IP",
    "port": $UDP_PORT,
    "port_hopping": "$UDP_PORT_HP",
    "protocol": "$PROTOCOL",
    "obfs": "$OBFS",
    "bandwidth_up": "100 mbps",
    "bandwidth_down": "100 mbps"
  },
  "users": {
    "user1": {
      "password": "$PASSWORD",
      "enabled": true
    }
  }
}
EOF
        chmod 600 "$VOLT_CONFIG"
    fi
}

generate_hysteria_config() {
    python3 <<'PY'
import sys, os, json
sys.path.insert(0,"/etc/volt")
import auth
d=auth.load(); s=d["server"]; users=auth.build_auth()
if not users: print("ERROR: ต้องมี User อย่างน้อย 1",file=sys.stderr); sys.exit(1)
cfg={
    "listen": ":"+str(s.get("port_hopping","10000-65000")),
    "tls":{"cert":"/etc/hysteria/hysteria.server.crt","key":"/etc/hysteria/hysteria.server.key"},
    "auth":{"type":"userpass","userpass":users},
    "obfs":{"type":"salamander","salamander":{"password":s.get("obfs","")}},
    "bandwidth":{"up":s.get("bandwidth_up","100 mbps"),"down":s.get("bandwidth_down","100 mbps")},
    "disableUDP": False
}
p="/etc/hysteria/config.json"; t=p+".tmp"
os.makedirs("/etc/hysteria",exist_ok=True)
with open(t,"w",encoding="utf-8") as f: json.dump(cfg,f,indent=2,ensure_ascii=False); f.write("\n")
os.chmod(t,0o600); os.replace(t,p)
print("✅ Hysteria config สร้างเสร็จ")
PY
}

install_volt_multi_user() {
    echo ""
    echo "=============================================="
    echo "   🧑‍🤝‍🧑 ติดตั้งระบบ Multi User"
    echo "=============================================="
    echo ""
    install_volt_python_dependencies
    install_volt_auth_py
    install_volt_cfgupt_py
    install_volt_config_json
    generate_hysteria_config
    chmod 700 "$VOLT_AUTH" "$VOLT_CFGUPT"
    chmod 600 "$VOLT_CONFIG" "$HY_CONFIG" 2>/dev/null
    echo "✅ ติดตั้ง Multi User เสร็จ"
    echo ""
}

install_volt_command() {
    cat <<'EOF' > /usr/local/bin/volt-user
#!/bin/bash
exec python3 /etc/volt/cfgupt.py "$@"
EOF
    chmod 755 /usr/local/bin/volt-user
}

# --------------------------
# 🚀 เริ่มการติดตั้ง Hysteria จริง
# --------------------------
perform_install() {
    perform_install_hysteria_binary
    perform_install_home
    perform_install_systemd
    setup_ssl
}

# --------------------------
# 🔥 ตั้งค่าไฟร์วอลล์ + Port Hopping
# --------------------------
start_services() {
    echo "🔥 กำลังตั้งค่าไฟร์วอลล์และ Port Hopping..."

    echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
    echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
    apt-get install -y iptables-persistent >/dev/null 2>&1

    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

    # ส่งต่อพอร์ต 10000-65000 มาที่พอร์ตหลัก
    iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 10000:65000 -j DNAT --to-destination :$UDP_PORT
    ip6tables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 10000:65000 -j DNAT --to-destination :$UDP_PORT

    # ปรับ Sysctl
    sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
    sysctl -w net.ipv4.conf."$IFACE".rp_filter=0 >/dev/null
    sysctl -w net.ipv4.ip_forward=1 >/dev/null

    cat > /etc/sysctl.d/99-hysteria.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.$IFACE.rp_filter = 0
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
EOF
    sysctl -p /etc/sysctl.d/99-hysteria.conf >/dev/null 2>&1

    # บันทึกกฎไฟร์วอลล์
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6

    # เปิดใช้งานบริการ
    systemctl enable hysteria.service >/dev/null 2>&1
    systemctl start hysteria.service
    echo "✅ ตั้งค่าไฟร์วอลล์เสร็จ"
}

# --------------------------
# 📄 สร้างไฟล์ข้อมูล Client
# --------------------------
client_config() {
    clear
    echo ""
    echo "=============================================="
    echo "   📄 สร้างข้อมูลเชื่อมต่อ Client"
    echo "=============================================="
    echo ""
    mkdir -p /etc/hysteria/client

    python3 <<'PY'
import sys, os
sys.path.insert(0,"/etc/volt")
import auth
d=auth.load()
s=d["server"]
dom=s.get("domain",""); ip=s.get("ip","")
port=s.get("port",36712); hop=s.get("port_hopping","10000-65000")
us=auth.get_users()

print("🌐 ข้อมูลเซิร์ฟเวอร์")
print("----------------------------------------------")
print(f"โดเมน   : {dom}")
print(f"IP      : {ip}")
print(f"พอร์ต   : {port}")
print(f"Hopping : {hop}")
print(f"OBFS    : {s.get('obfs','')}")
print("----------------------------------------------\n")

if not us: print("ยังไม่มี User")
else:
    for u in us:
        print(f"👤 USERNAME : {u['username']}")
        print(f"🔑 PASSWORD : {u['password']}")
        try: print(f"🔗 URI      : {auth.build_uri(u['username'])}")
        except Exception as e: print(f"URI ERROR : {e}")
        print("----------------------------------------------")

p="/etc/hysteria/client/info.txt"
with open(p,"w",encoding="utf-8") as f:
    f.write("Hysteria 2 — Client Info\n")
    f.write("="*40+"\n\n")
    f.write(f"Domain: {dom}\nIP: {ip}\nPort: {port}\nHopping: {hop}\n\n")
    for u in us:
        f.write(f"Username: {u['username']}\nPassword: {u['password']}\n")
        try: f.write(f"URI: {auth.build_uri(u['username'])}\n")
        except: pass
        f.write("\n")
os.chmod(p,0o600)
print(f"\n✅ บันทึกไฟล์ไว้ที่: {p}")
PY

    echo ""
    echo "💡 คำสั่งจัดการ User:"
    echo "   ${T_GREEN}volt-user${T_RESET}  — เปิดเมนูจัดการ User"
    echo ""
}

# --------------------------
# 🔄 รีโหลดบริการ
# --------------------------
reload_service() {
    echo "🔄 กำลังรีสตาร์ทบริการทั้งหมด..."
    systemctl restart hysteria 2>/dev/null
    systemctl restart systemd-journald 2>/dev/null
    sleep 1
    if systemctl is-active hysteria >/dev/null 2>&1; then
        echo -e "${T_GREEN}✅ Hysteria ทำงานปกติ${T_RESET}"
    else
        echo -e "${T_RED}❌ บริการไม่เริ่ม — ตรวจสอบด้วย: journalctl -u hysteria${T_RESET}"
    fi
}

# --------------------------
# 🎯 MAIN — เรียกทำงานทั้งหมด
# --------------------------
main() {
    clear
    checkRoot
    script_header
    update_packages
    banner
    verification      # ✅ ไม่มีตรวจ Key แล้ว
    perform_install   # ติดตั้งไบนารี + SSL + Systemd
    start_services    # ตั้งค่าไฟร์วอลล์ + เริ่มบริการ
    install_volt_command
    client_config     # แสดงข้อมูลเชื่อมต่อ
    reload_service

    echo ""
    echo "${T_GREEN}🎉 ติดตั้ง Hysteria 2 เสร็จสมบูรณ์!${T_RESET}"
    echo "${T_YELLOW}💡 พิมพ์: ${T_GREEN}volt-user${T_YELLOW} เพื่อจัดการ User${T_RESET}"
    echo ""
    read -n 1 -s -r -p " ⇢ กดปุ่มใดก็ได้เพื่อออก ↩︎" key
    echo ""
}

# เริ่มทำงาน
main
