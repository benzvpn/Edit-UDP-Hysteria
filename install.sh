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
    echo "  Telegram: @voltsshx //"
    echo "  ..SSHX.. (c)2021 </> 2024 //"
    echo ""

    echo -e "\e[1m\e[34m****************************************************"
    echo -e "  การติดตั้งและตั้งค่า \e[1;36mHysteria Protocol"
    echo -e "              (เวอร์ชัน 1.3.5) - โดย: @voltsshx"
    echo -e "\e[1m\e[34m****************************************************\e[0m"
    echo ""
}

update_packages() {
    clear
    echo ""
    echo ".-.   .-..---.  ,-.  _______     "
    echo " \ \ / // .-. ) | | |__   __|    "
    echo "  \ V / | | |(_)| |   )| |       "
    echo "   ) /  | | | | | |  (_) |       "
    echo "  (_)   \ \`-' / | \`--. | |       "
    echo "         )---'  |( __.'\`-'       "
    echo "        (_)     (_)              "
    echo "  Telegram: @voltsshx //"
    echo "  ..SSHX.. (c)2021 </> 2024 //"
    echo ""

    echo -e "\033[1;32m[\033[1;32mสำเร็จ ✅\033[1;32m] \033[1;37m ⇢  \033[1;33mกำลังเตรียมไฟล์ที่จำเป็น...\033[0m"
    echo -e "\033[1;32m      ♻️ \033[1;37m      \033[1;33mกรุณารอสักครู่...\033[0m"
    echo ""

    sudo apt-get update && sudo apt-get upgrade -y

    local dependencies=("curl" "bc" "grep" "wget" "nano" "net-tools" "figlet" "jq" "python3")

    for dependency in "${dependencies[@]}"; do
        if ! command -v "$dependency" &>/dev/null; then
            echo "${T_YELLOW}กำลังติดตั้ง $dependency...${T_RESET}"
            apt update && apt install -y "$dependency" >/dev/null 2>&1
        fi
    done

    sudo apt-get install wget nano net-tools figlet lolcat -y

    export PATH="/usr/games:$PATH"

    if [ ! -e /usr/local/bin/lolcat ]; then
        sudo ln -s /usr/games/lolcat /usr/local/bin/lolcat
    fi

    apt install sudo -y > /dev/null 2>&1

    DEBIAN_FRONTEND=noninteractive apt-get -qq install -yqq \
        --no-install-recommends ca-certificates > /dev/null 2>&1

    clear
    echo ""

    echo -e "\033[1;32m[\033[1;32mสำเร็จ ✅\033[1;32m] \033[1;37m ⇢  \033[1;33mเตรียมไฟล์ที่จำเป็น...\033[0m"
    echo -e "\033[1;32m      ♻️ \033[1;37m      \033[1;33mกรุณารอสักครู่...\033[0m"
    echo ""
}

banner() {
    sed -i '/figlet -k Voltssh-X | lolcat/,/echo -e ""/d' ~/.bashrc
    sed -i '/figlet -k Hysteria | lolcat/,/echo -e ""/d' ~/.bashrc

    echo 'clear' >>~/.bashrc
    echo 'echo ""' >>~/.bashrc
    echo 'figlet -k Voltssh-X | lolcat' >>~/.bashrc
    echo 'figlet -k Hysteria | lolcat' >>~/.bashrc

    echo 'echo -e "\t\e\033[94m⚙︎ Voltssh-X Hysteria โดย @voltsshx ⚙︎\033[0m"' >>~/.bashrc
    echo 'echo -e "\t\e\033[94mTelegram: @voltsshx // \033[0m"' >>~/.bashrc
    echo 'echo -e "\t\e\033[94m..SSHX.. (c)2021 </> 2024 // \033[0m"' >>~/.bashrc
    echo 'echo "" ' >>~/.bashrc

    echo 'echo -e "\t\033[92mTelegram   : @voltsshx | LS Tunnels" ' >>~/.bashrc
    echo 'echo -e "\t\e[1;33mPowered by : AIB Tech Pvt."' >>~/.bashrc
    echo 'echo ""' >>~/.bashrc

    echo 'DATE=$(date +"%d-%m-%y")' >>~/.bashrc
    echo 'TIME=$(date +"%T")' >>~/.bashrc

    echo 'echo -e "\t\e[1;33mชื่อเซิร์ฟเวอร์ : $HOSTNAME"' >>~/.bashrc
    echo 'echo -e "\t\e[1;33mเวลาที่เซิร์ฟเวอร์ทำงาน : $(uptime -p)"' >>~/.bashrc
    echo 'echo -e "\t\e[1;33mวันที่เซิร์ฟเวอร์ : $DATE"' >>~/.bashrc
    echo 'echo -e "\t\e[1;33mเวลาของเซิร์ฟเวอร์ : $TIME"' >>~/.bashrc
    echo 'echo "" ' >>~/.bashrc

    echo 'echo -e "\t\e\033[94mอีเมลติดต่อ: iyke.earth@gmail.com \033[0m"' >>~/.bashrc
    echo 'echo "" ' >>~/.bashrc

    echo 'echo -e "\t\e\033[92mคำสั่งเมนู: volt \033[0m"' >>~/.bashrc
    echo 'echo -e ""' >>~/.bashrc
    echo 'echo -e ""' >>~/.bashrc

    rm -f /root/install.sh
    cat /dev/null >~/.bash_history
    history -c

    find / -type f -name "hys.json" -delete >/dev/null 2>&1
    find / -type f -name "install.sh" -delete >/dev/null 2>&1
}

verification() {
    clear

    fetch_valid_keys() {
        keys=$(curl -s \
            -H "Cache-Control: no-cache" \
            -H "Pragma: no-cache" \
            "https://raw.githubusercontent.com/benzvpn/Edit-UDP-Hysteria/refs/heads/main/key.json")

        echo "$keys"
    }

    verify_key() {
        local key_to_verify="$1"
        local valid_keys="$2"

        if [[ $valid_keys == *"$key_to_verify"* ]]; then
            return 0
        else
            return 1
        fi
    }

    valid_keys=$(fetch_valid_keys)

    echo ""

    figlet -k Voltssh-X | awk '{gsub(/./,"\033[3"int(rand()*5+1)"m&\033[0m")}1' &&
    figlet -k Hysteria | awk '{gsub(/./,"\033[3"int(rand()*5+1)"m&\033[0m")}1'

    echo "───────────────────────────────────────────────────────────────────────•"
    echo ""
    echo ""

    echo -e " 〄 \033[1;37m ⌯  \033[1;33mคุณต้องมี Key ที่ซื้อมาเพื่อดำเนินการติดตั้ง\033[0m"
    echo -e " 〄 \033[1;37m ⌯  \033[1;33mหากยังไม่มี กรุณาติดต่อ [v3r!f.y.Key 𝕏]\033[0m"
    echo -e " 〄 \033[1;37m ⌯ ⇢ \033[1;33mhttps://t.me/voltverifybot\033[0m"
    echo -e " 〄 \033[1;37m ⌯  \033[1;33mสามารถติดต่อ @voltsshx ผ่าน Telegram ได้เช่นกัน\033[0m"

    echo ""
    echo "───────────────────────────────────────────────────────────────────────•"

    read -p " ⇢ กรุณากรอก Installation Key: " user_key
    user_key=$(echo "$user_key" | tr -d '[:space:]')

    if [[ ${#user_key} -ne 10 ]]; then
        echo "${T_RED} ⇢ การตรวจสอบไม่สำเร็จ ยกเลิกการติดตั้ง${T_RESET}"

        find / -type f -name "hys.json" -delete >/dev/null 2>&1
        rm -f /root/hys.json >/dev/null 2>&1
        rm -f hys.json >/dev/null 2>&1

        echo ""
        exit 1
    fi

    if verify_key "$user_key" "$valid_keys"; then

        sleep 2

        echo "${T_GREEN} ⇢ ตรวจสอบ Key สำเร็จ${T_RESET}"
        echo "${T_GREEN} ⇢ กำลังดำเนินการติดตั้ง...${T_RESET}"

        echo ""
        echo ""
        echo -e "\033[1;32m ♻️ กรุณารอสักครู่...\033[0m"

        find / -type f -name "hys.json" -delete >/dev/null 2>&1
        rm -f /root/hys.json >/dev/null 2>&1
        rm -f hys.json >/dev/null 2>&1

        sleep 1
        clear
        clear

        validate_length() {
            local input_string="$1"
            local min_length="$2"

            if [ ${#input_string} -lt $min_length ]; then
                echo "ข้อมูลต้องมีความยาวอย่างน้อย $min_length ตัวอักษร"
                return 1
            fi
        }

        figlet -k Voltssh-X | awk '{gsub(/./,"\033[3"int(rand()*5+1)"m&\033[0m")}1' &&
        figlet -k Hysteria | awk '{gsub(/./,"\033[3"int(rand()*5+1)"m&\033[0m")}1'

        echo "───────────────────────────────────────────────────────────────────────•"

        echo -e "   การตั้งค่าเซิร์ฟเวอร์ Hysteria"
        echo -e "*******************************************\e[0m"
        echo ""

        HYST_SERVER_IP=$(curl -s https://api.ipify.org)

        echo -e "\nIP โฮสต์/เซิร์ฟเวอร์ 👉 $HYST_SERVER_IP"
        echo "-------------------------------------------"

        echo -e "\nกรุณากรอกโดเมนของคุณ: 👇"
        echo -e "(สามารถรับโดเมนฟรีได้จาก 'https://duckdns.org')"

        read -p "" DOMAIN

        echo "-------------------------------------------"

        while true; do
            echo -e "\nกรุณากรอก Obfuscation (OBFS): 👇"
            echo -e "(ต้องมีความยาวอย่างน้อย 10 ตัวอักษร)"

            read -p "" OBFS

            if validate_length "$OBFS" 10; then
                break
            fi
        done

        echo "-------------------------------------------"

        while true; do
            echo -e "\nกรุณากรอก Authentication (AUTH): 👇"
            echo -e "(ต้องมีความยาวอย่างน้อย 10 ตัวอักษร)"

            read -p "" PASSWORD

            if validate_length "$PASSWORD" 10; then
                break
            fi
        done

        echo ""

        mkdir -p /etc/volt

PROTOCOL="udp"

# Hysteria Server listen port
UDP_PORT="36712"

# Port Hopping range
UDP_PORT_HP="10000-65000"
HPStart="10000"
HPEnd="65000"

# QUIC Receive Window
UDP_QUIC_WINDOW="196608"

# URI remark
remarks="VoltxHysteriaConfig"

# Self-signed certificate
sec="1"

        url="hysteria://${DOMAIN}:${UDP_PORT_HP}?protocol=${PROTOCOL}&auth=${PASSWORD}&obfsParam=${OBFS}&peer=${DOMAIN}&insecure=${sec}&upmbps=100&downmbps=100&alpn=h3#${remarks}"
        url="hysteria2://${PASSWORD}@${DOMAIN}:${UDP_PORT_HP}/?obfs=salamander&obfs-password=${OBFS}&insecure=1&sni=${DOMAIN}#${remarks}"

        supportedApps="แอปที่รองรับ: AIO Tunnel, AIO Injector, Http Injector, NekoBox"

        echo "$DOMAIN" >/etc/volt/DOMAIN
        echo "$PROTOCOL" >/etc/volt/PROTOCOL
        echo "$UDP_PORT" >/etc/volt/UDP_PORT
        echo "$UDP_PORT_HP" >/etc/volt/UDP_PORT_HP
        echo "$OBFS" >/etc/volt/OBFS
        install_volt_multi_user

        export DOMAIN
        export PROTOCOL
        export UDP_PORT
        export UDP_PORT_HP
        export OBFS
        export PASSWORD

        SCRIPT_NAME="$(basename "$0")"
        SCRIPT_ARGS=("$@")

        EXECUTABLE_INSTALL_PATH="/usr/local/bin/hysteria"
        SYSTEMD_SERVICES_DIR="/etc/systemd/system"
        CONFIG_DIR="/etc/hysteria"

        REPO_URL="https://github.com/apernet/hysteria"
        API_BASE_URL="https://api.github.com/repos/apernet/hysteria"

        CURL_FLAGS=(-L -f -q --retry 5 --retry-delay 10 --retry-max-time 60)

        PACKAGE_MANAGEMENT_INSTALL="${PACKAGE_MANAGEMENT_INSTALL:-}"
        OPERATING_SYSTEM="${OPERATING_SYSTEM:-}"
        ARCHITECTURE="${ARCHITECTURE:-}"
        HYSTERIA_USER="${HYSTERIA_USER:-}"
        HYSTERIA_HOME_DIR="${HYSTERIA_HOME_DIR:-}"

        OPERATION=
        VERSION=
        FORCE=
        LOCAL_FILE=

        has_command() {
            local _command=$1
            type -P "$_command" >/dev/null 2>&1
        }

        curl() {
            command curl "${CURL_FLAGS[@]}" "$@"
        }

        mktemp() {
            command mktemp "$@" "hyservinst.XXXXXXXXXX"
        }

        tput() {
            if has_command tput; then
                command tput "$@"
            fi
        }

        tred() {
            tput setaf 1
        }

        tgreen() {
            tput setaf 2
        }

        tyellow() {
            tput setaf 3
        }

        tblue() {
            tput setaf 4
        }

        taoi() {
            tput setaf 6
        }

        tbold() {
            tput bold
        }

        treset() {
            tput sgr0
        }

        note() {
            local _msg="$1"
            echo -e "$SCRIPT_NAME: $(tbold)หมายเหตุ: $_msg$(treset)"
        }

        warning() {
            local _msg="$1"
            echo -e "$SCRIPT_NAME: $(tyellow)คำเตือน: $_msg$(treset)"
        }

        error() {
            local _msg="$1"
            echo -e "$SCRIPT_NAME: $(tred)ข้อผิดพลาด: $_msg$(treset)"
        }

        has_prefix() {
            local _s="$1"
            local _prefix="$2"

            if [[ -z "$_prefix" ]]; then
                return 0
            fi

            if [[ -z "$_s" ]]; then
                return 1
            fi

            [[ "x$_s" != "x${_s#"$_prefix"}" ]]
        }

        systemctl() {
            if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]] || ! has_command systemctl; then
                return
            fi

            command systemctl "$@"
        }

        show_argument_error_and_exit() {
            local _error_msg="$1"

            error "$_error_msg"
            echo "ลองใช้ \"$0 --help\" เพื่อดูวิธีใช้งาน" >&2
            exit 22
        }

        install_content() {
            local _install_flags="$1"
            local _content="$2"
            local _destination="$3"
            local _tmpfile="$(mktemp)"

            echo -ne "กำลังติดตั้ง $_destination ... "

            echo "$_content" >"$_tmpfile"

            if install "$_install_flags" "$_tmpfile" "$_destination"; then
                echo -e "สำเร็จ"
            fi

            rm -f "$_tmpfile"
        }

        remove_file() {
            local _target="$1"

            echo -ne "กำลังลบ $_target ... "

            if rm "$_target"; then
                echo -e "สำเร็จ"
            fi
        }

        exec_sudo() {
            local _saved_ifs="$IFS"
            IFS=$'\n'

            local _preserved_env=(
                $(env | grep "^PACKAGE_MANAGEMENT_INSTALL=" || true)
                $(env | grep "^OPERATING_SYSTEM=" || true)
                $(env | grep "^ARCHITECTURE=" || true)
                $(env | grep "^HYSTERIA_\w*=" || true)
                $(env | grep "^FORCE_\w*=" || true)
            )

            IFS="$_saved_ifs"

            exec sudo env \
                "${_preserved_env[@]}" \
                "$@"
        }

        detect_package_manager() {
            if [[ -n "$PACKAGE_MANAGEMENT_INSTALL" ]]; then
                return 0
            fi

            if has_command apt; then
                PACKAGE_MANAGEMENT_INSTALL='apt update; apt -y install'
                return 0
            fi

            if has_command dnf; then
                PACKAGE_MANAGEMENT_INSTALL='dnf check-update; dnf -y install'
                return 0
            fi

            if has_command yum; then
                PACKAGE_MANAGEMENT_INSTALL='yum update; yum -y install'
                return 0
            fi

            if has_command zypper; then
                PACKAGE_MANAGEMENT_INSTALL='zypper update; zypper install -y --no-recommends'
                return 0
            fi

            if has_command pacman; then
                PACKAGE_MANAGEMENT_INSTALL='pacman -Syu; pacman -Syu --noconfirm'
                return 0
            fi

            return 1
        }

        install_software() {
            local _package_name="$1"

            if ! detect_package_manager; then
                error "ไม่พบ Package Manager ที่รองรับ กรุณาติดตั้งแพ็กเกจต่อไปนี้ด้วยตนเอง:"
                echo
                echo -e "\t* $_package_name"
                echo
                exit 65
            fi

            echo "กำลังติดตั้ง dependency ที่ขาดหายไป '$_package_name' ด้วย '$PACKAGE_MANAGEMENT_INSTALL' ... "

            if $PACKAGE_MANAGEMENT_INSTALL "$_package_name"; then
                echo "สำเร็จ"
            else
                error "ไม่สามารถติดตั้ง '$_package_name' ด้วย Package Manager ที่ตรวจพบ กรุณาติดตั้งด้วยตนเอง"
                exit 65
            fi
        }

        is_user_exists() {
            local _user="$1"
            id "$_user" >/dev/null 2>&1
        }

        check_permission() {
            if [[ "$UID" -eq '0' ]]; then
                return
            fi

            note "ผู้ใช้ที่กำลังเรียกใช้สคริปต์นี้ไม่ใช่ root"

            case "$FORCE_NO_ROOT" in
                '1')
                    warning "กำหนด FORCE_NO_ROOT=1 ระบบจะทำงานโดยไม่ใช้ root และอาจพบข้อผิดพลาดด้านสิทธิ์"
                    ;;
                *)
                    if has_command sudo; then
                        note "กำลังเรียกใช้สคริปต์ใหม่ด้วย sudo หากต้องการบังคับใช้ผู้ใช้ปัจจุบัน ให้กำหนด FORCE_NO_ROOT=1"

                        exec_sudo "$0" "${SCRIPT_ARGS[@]}"
                    else
                        error "กรุณารันสคริปต์ด้วย root หรือกำหนด FORCE_NO_ROOT=1 เพื่อบังคับใช้ผู้ใช้ปัจจุบัน"
                        exit 13
                    fi
                    ;;
            esac
        }

        check_environment_operating_system() {
            if [[ -n "$OPERATING_SYSTEM" ]]; then
                warning "กำหนด OPERATING_SYSTEM=$OPERATING_SYSTEM ระบบจะไม่ตรวจสอบระบบปฏิบัติการ"
                return
            fi

            if [[ "x$(uname)" == "xLinux" ]]; then
                OPERATING_SYSTEM=linux
                return
            fi

            error "สคริปต์นี้รองรับเฉพาะ Linux"
            note "กำหนด OPERATING_SYSTEM=[linux|darwin|freebsd|windows] เพื่อข้ามการตรวจสอบนี้"

            exit 95
        }

        check_environment_architecture() {
            if [[ -n "$ARCHITECTURE" ]]; then
                warning "กำหนด ARCHITECTURE=$ARCHITECTURE ระบบจะไม่ตรวจสอบสถาปัตยกรรม"
                return
            fi

            case "$(uname -m)" in
                'i386' | 'i686')
                    ARCHITECTURE='386'
                    ;;
                'amd64' | 'x86_64')
                    ARCHITECTURE='amd64'
                    ;;
                'armv5tel' | 'armv6l' | 'armv7' | 'armv7l')
                    ARCHITECTURE='arm'
                    ;;
                'armv8' | 'aarch64')
                    ARCHITECTURE='arm64'
                    ;;
                'mips' | 'mipsle' | 'mips64' | 'mips64le')
                    ARCHITECTURE='mipsle'
                    ;;
                's390x')
                    ARCHITECTURE='s390x'
                    ;;
                *)
                    error "ไม่รองรับสถาปัตยกรรม '$(uname -a)'"
                    note "กำหนด ARCHITECTURE=<architecture> เพื่อข้ามการตรวจสอบนี้"
                    exit 8
                    ;;
            esac
        }

        check_environment_systemd() {
            if [[ -d "/run/systemd/system" ]] || grep -q systemd <(ls -l /sbin/init); then
                return
            fi

            case "$FORCE_NO_SYSTEMD" in
                '1')
                    warning "กำหนด FORCE_NO_SYSTEMD=1 ระบบจะดำเนินการต่อแม้ไม่พบ systemd"
                    ;;
                '2')
                    warning "กำหนด FORCE_NO_SYSTEMD=2 ระบบจะดำเนินการต่อ แต่จะไม่เรียกใช้คำสั่งที่เกี่ยวข้องกับ systemd"
                    ;;
                *)
                    error "สคริปต์นี้รองรับเฉพาะ Linux distribution ที่ใช้ systemd"
                    note "กำหนด FORCE_NO_SYSTEMD=1 เพื่อข้ามการตรวจสอบ"
                    note "กำหนด FORCE_NO_SYSTEMD=2 เพื่อข้ามการตรวจสอบและปิดคำสั่ง systemd ทั้งหมด"
                    ;;
            esac
        }

        check_environment_curl() {
            if has_command curl; then
                return
            fi

            apt update
            apt -y install curl
        }

        check_environment_grep() {
            if has_command grep; then
                return
            fi

            apt update
            apt -y install grep
        }

        check_environment() {
            check_environment_operating_system
            check_environment_architecture
            check_environment_systemd
            check_environment_curl
            check_environment_grep
        }

        vercmp_segment() {
            local _lhs="$1"
            local _rhs="$2"

            if [[ "x$_lhs" == "x$_rhs" ]]; then
                echo 0
                return
            fi

            if [[ -z "$_lhs" ]]; then
                echo -1
                return
            fi

            if [[ -z "$_rhs" ]]; then
                echo 1
                return
            fi

            local _lhs_num="${_lhs//[A-Za-z]*/}"
            local _rhs_num="${_rhs//[A-Za-z]*/}"

            if [[ "x$_lhs_num" == "x$_rhs_num" ]]; then
                echo 0
                return
            fi

            if [[ -z "$_lhs_num" ]]; then
                echo -1
                return
            fi

            if [[ -z "$_rhs_num" ]]; then
                echo 1
                return
            fi

            local _numcmp=$(($_lhs_num - $_rhs_num))

            if [[ "$_numcmp" -ne 0 ]]; then
                echo "$_numcmp"
                return
            fi

            local _lhs_suffix="${_lhs#"$_lhs_num"}"
            local _rhs_suffix="${_rhs#"$_rhs_num"}"

            if [[ "x$_lhs_suffix" == "x$_rhs_suffix" ]]; then
                echo 0
                return
            fi

            if [[ -z "$_lhs_suffix" ]]; then
                echo 1
                return
            fi

            if [[ -z "$_rhs_suffix" ]]; then
                echo -1
                return
            fi

            if [[ "$_lhs_suffix" < "$_rhs_suffix" ]]; then
                echo -1
                return
            fi

            echo 1
        }

        vercmp() {
            local _lhs=${1#v}
            local _rhs=${2#v}

            while [[ -n "$_lhs" && -n "$_rhs" ]]; do
                local _clhs="${_lhs/.*/}"
                local _crhs="${_rhs/.*/}"

                local _segcmp="$(vercmp_segment "$_clhs" "$_crhs")"

                if [[ "$_segcmp" -ne 0 ]]; then
                    echo "$_segcmp"
                    return
                fi

                _lhs="${_lhs#"$_clhs"}"
                _lhs="${_lhs#.}"

                _rhs="${_rhs#"$_crhs"}"
                _rhs="${_rhs#.}"
            done

            if [[ "x$_lhs" == "x$_rhs" ]]; then
                echo 0
                return
            fi

            if [[ -z "$_lhs" ]]; then
                echo -1
                return
            fi

            if [[ -z "$_rhs" ]]; then
                echo 1
                return
            fi

            return
        }

        check_hysteria_user() {
            local _default_hysteria_user="$1"

            if [[ -n "$HYSTERIA_USER" ]]; then
                return
            fi

            if [[ ! -e "$SYSTEMD_SERVICES_DIR/hysteria.service" ]]; then
                HYSTERIA_USER="$_default_hysteria_user"
                return
            fi

            HYSTERIA_USER="$(grep -o '^User=\w*' "$SYSTEMD_SERVICES_DIR/hysteria.service" |
                tail -1 | cut -d '=' -f 2 || true)"

            if [[ -z "$HYSTERIA_USER" ]]; then
                HYSTERIA_USER="$_default_hysteria_user"
            fi
        }

        check_hysteria_homedir() {
            local _default_hysteria_homedir="$1"

            if [[ -n "$HYSTERIA_HOME_DIR" ]]; then
                return
            fi

            if ! is_user_exists "$HYSTERIA_USER"; then
                HYSTERIA_HOME_DIR="$_default_hysteria_homedir"
                return
            fi

            HYSTERIA_HOME_DIR="$(eval echo ~"$HYSTERIA_USER")"
        }

        tpl_hysteria_server_service_base() {
    local _config_name="$1"

    cat <<EOF
[Unit]
Description=Voltssh-X Hysteria 2 Service
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

[Install]
WantedBy=multi-user.target
EOF
}

        tpl_hysteria_server_service() {
            tpl_hysteria_server_service_base 'config'
        }

        tpl_hysteria_server_x_service() {
            tpl_hysteria_server_service_base '%i'
        }

        # ============================================================
# VOLTSSH-X HYSTERIA 2
# MULTI USER / MULTI PASSWORD SYSTEM
# ============================================================

VOLT_DIR="/etc/volt"
HY_CONFIG_DIR="/etc/hysteria"
VOLT_CONFIG="$VOLT_DIR/config.json"
VOLT_AUTH="$VOLT_DIR/auth.py"
VOLT_CFGUPT="$VOLT_DIR/cfgupt.py"
HY_CONFIG="$HY_CONFIG_DIR/config.json"


# ------------------------------------------------------------
# ตรวจ dependency
# ------------------------------------------------------------

install_volt_python_dependencies() {

    mkdir -p "$VOLT_DIR"
    mkdir -p "$HY_CONFIG_DIR"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "กำลังติดตั้ง Python3..."
        apt-get update
        apt-get install -y python3
    fi

    if ! command -v openssl >/dev/null 2>&1; then
        echo "กำลังติดตั้ง OpenSSL..."
        apt-get update
        apt-get install -y openssl
    fi
}


# ------------------------------------------------------------
# สร้าง auth.py
# ------------------------------------------------------------

install_volt_auth_py() {

cat <<'PY' > "$VOLT_AUTH"
#!/usr/bin/env python3

import json
import os
import re
import secrets
import string
import tempfile
from urllib.parse import quote

CONFIG_FILE = "/etc/volt/config.json"


DEFAULT_CONFIG = {
    "version": 2,

    "server": {
        "domain": "",
        "ip": "",
        "port": 36712,
        "port_hopping": "10000-65000",
        "protocol": "udp",
        "obfs": "",
        "bandwidth_up": "100 mbps",
        "bandwidth_down": "100 mbps"
    },

    "users": {}
}


def ensure_directory():
    directory = os.path.dirname(CONFIG_FILE)

    if directory:
        os.makedirs(directory, exist_ok=True)


def atomic_write_json(path, data):

    directory = os.path.dirname(path) or "."

    os.makedirs(directory, exist_ok=True)

    fd, tmp = tempfile.mkstemp(
        prefix=".config.",
        suffix=".tmp",
        dir=directory
    )

    try:

        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(
                data,
                f,
                indent=2,
                ensure_ascii=False
            )
            f.write("\n")

        os.chmod(tmp, 0o600)

        os.replace(tmp, path)

    except Exception:

        try:
            os.unlink(tmp)
        except OSError:
            pass

        raise


def normalize_config(data):

    if not isinstance(data, dict):
        data = {}

    if not isinstance(data.get("server"), dict):
        data["server"] = {}

    if not isinstance(data.get("users"), dict):
        data["users"] = {}

    data.setdefault("version", 2)

    server_defaults = DEFAULT_CONFIG["server"]

    for key, value in server_defaults.items():
        data["server"].setdefault(key, value)

    return data


def load_config():

    ensure_directory()

    if not os.path.exists(CONFIG_FILE):

        data = json.loads(
            json.dumps(DEFAULT_CONFIG)
        )

        save_config(data)

        return data

    try:

        with open(
            CONFIG_FILE,
            "r",
            encoding="utf-8"
        ) as f:

            data = json.load(f)

    except (OSError, json.JSONDecodeError):

        raise RuntimeError(
            "ไม่สามารถอ่าน /etc/volt/config.json ได้"
        )

    return normalize_config(data)


def save_config(data):

    data = normalize_config(data)

    atomic_write_json(
        CONFIG_FILE,
        data
    )


def valid_username(username):

    if not isinstance(username, str):
        return False

    if not 1 <= len(username) <= 64:
        return False

    return re.fullmatch(
        r"[A-Za-z0-9_.-]+",
        username
    ) is not None


def valid_password(password):

    if not isinstance(password, str):
        return False

    if len(password) < 10:
        return False

    if len(password) > 256:
        return False

    return True


def generate_password(length=16):

    alphabet = (
        string.ascii_letters +
        string.digits
    )

    return "".join(
        secrets.choice(alphabet)
        for _ in range(length)
    )


def add_user(username, password):

    if not valid_username(username):
        raise ValueError(
            "Username ต้องประกอบด้วย A-Z, a-z, 0-9, _ . -"
        )

    if not valid_password(password):
        raise ValueError(
            "Password ต้องมีอย่างน้อย 10 ตัวอักษร"
        )

    data = load_config()

    if username in data["users"]:
        raise ValueError(
            "Username นี้มีอยู่แล้ว"
        )

    data["users"][username] = {
        "password": password,
        "enabled": True
    }

    save_config(data)

    return data


def update_password(username, password):

    if not valid_password(password):
        raise ValueError(
            "Password ต้องมีอย่างน้อย 10 ตัวอักษร"
        )

    data = load_config()

    if username not in data["users"]:
        raise ValueError(
            "ไม่พบ Username นี้"
        )

    data["users"][username]["password"] = password

    save_config(data)

    return data


def remove_user(username):

    data = load_config()

    if username not in data["users"]:
        raise ValueError(
            "ไม่พบ Username นี้"
        )

    del data["users"][username]

    save_config(data)

    return data


def set_user_enabled(username, enabled):

    data = load_config()

    if username not in data["users"]:
        raise ValueError(
            "ไม่พบ Username นี้"
        )

    data["users"][username]["enabled"] = bool(enabled)

    save_config(data)

    return data


def get_users():

    data = load_config()

    result = []

    for username, value in data["users"].items():

        if isinstance(value, dict):

            password = value.get(
                "password",
                ""
            )

            enabled = value.get(
                "enabled",
                True
            )

        else:

            password = str(value)
            enabled = True

        result.append({
            "username": username,
            "password": password,
            "enabled": enabled
        })

    return result


def get_enabled_users():

    return [
        user
        for user in get_users()
        if user["enabled"]
    ]


def get_user(username):

    data = load_config()

    user = data["users"].get(username)

    if user is None:
        return None

    if isinstance(user, dict):

        return {
            "username": username,
            "password": user.get(
                "password",
                ""
            ),
            "enabled": user.get(
                "enabled",
                True
            )
        }

    return {
        "username": username,
        "password": str(user),
        "enabled": True
    }


def build_hysteria_auth():

    auth = {}

    for user in get_enabled_users():

        username = user["username"]
        password = user["password"]

        auth[username] = password

    return auth


def uri_escape(value):

    return quote(
        str(value),
        safe=""
    )


def build_uri(username):

    data = load_config()
    server = data["server"]

    domain = server.get("domain", "")
    port = server.get(
        "port_hopping",
        "10000-65000"
    )

    obfs = server.get(
        "obfs",
        ""
    )

    password_data = get_user(username)

    if password_data is None:
        raise ValueError(
            "ไม่พบ Username"
        )

    password = password_data["password"]

    user_enc = uri_escape(username)
    pass_enc = uri_escape(password)
    domain_enc = domain

    obfs_enc = uri_escape(obfs)

    return (
        f"hysteria2://"
        f"{user_enc}:{pass_enc}"
        f"@{domain_enc}:{port}/"
        f"?obfs=salamander"
        f"&obfs-password={obfs_enc}"
        f"&insecure=1"
        f"&sni={domain_enc}"
    )


def migrate_old_password(old_password, username="user1"):

    data = load_config()

    if data["users"]:
        return False

    if not old_password:
        return False

    if not valid_password(old_password):
        return False

    data["users"][username] = {
        "password": old_password,
        "enabled": True
    }

    save_config(data)

    return True


if __name__ == "__main__":

    data = load_config()

    print(
        json.dumps(
            data,
            indent=2,
            ensure_ascii=False
        )
    )
PY

chmod 700 "$VOLT_AUTH"
}


# ------------------------------------------------------------
# สร้าง cfgupt.py
# ------------------------------------------------------------

install_volt_cfgupt_py() {

cat <<'PY' > "$VOLT_CFGUPT"
#!/usr/bin/env python3

import getpass
import json
import os
import secrets
import string
import subprocess
import sys

sys.path.insert(
    0,
    "/etc/volt"
)

import auth


CONFIG_FILE = "/etc/volt/config.json"
HY_CONFIG = "/etc/hysteria/config.json"


GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
CYAN = "\033[96m"
BLUE = "\033[94m"
WHITE = "\033[97m"
RESET = "\033[0m"
BOLD = "\033[1m"


def clear():

    os.system("clear")


def header():

    clear()

    print()
    print(
        f"{CYAN}{BOLD}"
        "=============================================="
        f"{RESET}"
    )

    print(
        f"{CYAN}{BOLD}"
        "       Voltssh-X Hysteria 2"
        f"{RESET}"
    )

    print(
        f"{CYAN}{BOLD}"
        "       User / Password Manager"
        f"{RESET}"
    )

    print(
        f"{CYAN}{BOLD}"
        "=============================================="
        f"{RESET}"
    )

    print()


def pause():

    input(
        f"\n{YELLOW}"
        "กด Enter เพื่อดำเนินการต่อ..."
        f"{RESET}"
    )


def random_password(length=16):

    alphabet = (
        string.ascii_letters +
        string.digits
    )

    return "".join(
        secrets.choice(alphabet)
        for _ in range(length)
    )


def restart_hysteria():

    try:

        subprocess.run(
            [
                "systemctl",
                "restart",
                "hysteria"
            ],
            check=False
        )

        return True

    except Exception:

        return False


def check_config():

    try:

        result = subprocess.run(
            [
                "/usr/local/bin/hysteria",
                "server",
                "-c",
                HY_CONFIG,
                "check"
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False
        )

        print(result.stdout)

        return result.returncode == 0

    except Exception:

        return True


def generate_hysteria_config():

    data = auth.load_config()

    server = data["server"]

    listen = (
        f":{server.get('port_hopping', '10000-65000')}"
    )

    users = auth.build_hysteria_auth()

    config = {

        "listen": listen,

        "tls": {
            "cert": "/etc/hysteria/hysteria.server.crt",
            "key": "/etc/hysteria/hysteria.server.key"
        },

        "auth": {
            "type": "userpass",
            "userpass": users
        },

        "obfs": {
            "type": "salamander",
            "salamander": {
                "password": server.get(
                    "obfs",
                    ""
                )
            }
        },

        "bandwidth": {
            "up": server.get(
                "bandwidth_up",
                "100 mbps"
            ),
            "down": server.get(
                "bandwidth_down",
                "100 mbps"
            )
        },

        "disableUDP": False
    }

    os.makedirs(
        os.path.dirname(HY_CONFIG),
        exist_ok=True
    )

    temporary = HY_CONFIG + ".tmp"

    with open(
        temporary,
        "w",
        encoding="utf-8"
    ) as f:

        json.dump(
            config,
            f,
            indent=2,
            ensure_ascii=False
        )

        f.write("\n")

    os.chmod(
        temporary,
        0o600
    )

    os.replace(
        temporary,
        HY_CONFIG
    )

    return config


def apply_changes():

    print(
        f"{YELLOW}"
        "กำลังสร้าง Hysteria configuration..."
        f"{RESET}"
    )

    try:

        generate_hysteria_config()

    except Exception as e:

        print(
            f"{RED}"
            f"ไม่สามารถสร้าง config: {e}"
            f"{RESET}"
        )

        return False

    print(
        f"{GREEN}"
        "สร้าง config สำเร็จ"
        f"{RESET}"
    )

    print(
        f"{YELLOW}"
        "กำลังตรวจสอบ configuration..."
        f"{RESET}"
    )

    if not check_config():

        print(
            f"{RED}"
            "Configuration ไม่ผ่านการตรวจสอบ"
            f"{RESET}"
        )

        return False

    print(
        f"{GREEN}"
        "Configuration ถูกต้อง"
        f"{RESET}"
    )

    print(
        f"{YELLOW}"
        "กำลัง restart Hysteria..."
        f"{RESET}"
    )

    restart_hysteria()

    print(
        f"{GREEN}"
        "Hysteria restart แล้ว"
        f"{RESET}"
    )

    return True


def list_users():

    header()

    users = auth.get_users()

    if not users:

        print(
            f"{YELLOW}"
            "ยังไม่มีผู้ใช้งาน"
            f"{RESET}"
        )

        pause()
        return

    print(
        f"{WHITE}{BOLD}"
        "รายการผู้ใช้งาน"
        f"{RESET}"
    )

    print()

    for index, user in enumerate(
        users,
        start=1
    ):

        status = (
            f"{GREEN}ON{RESET}"
            if user["enabled"]
            else
            f"{RED}OFF{RESET}"
        )

        print(
            f"{CYAN}{index:03d}.{RESET} "
            f"{WHITE}{user['username']}{RESET} "
            f"[{status}]"
        )

    print()

    pause()


def add_user():

    header()

    print(
        f"{CYAN}"
        "เพิ่ม Username / Password"
        f"{RESET}"
    )

    print()

    while True:

        username = input(
            "Username: "
        ).strip()

        if not auth.valid_username(
            username
        ):

            print(
                f"{RED}"
                "Username ไม่ถูกต้อง"
                f"{RESET}"
            )

            continue

        if auth.get_user(
            username
        ) is not None:

            print(
                f"{RED}"
                "Username นี้มีอยู่แล้ว"
                f"{RESET}"
            )

            continue

        break

    print()

    print(
        "เลือกวิธีสร้าง Password"
    )

    print(
        "1. กรอก Password เอง"
    )

    print(
        "2. สร้าง Password อัตโนมัติ"
    )

    choice = input(
        "\nเลือก [1-2]: "
    ).strip()

    if choice == "2":

        password = random_password(20)

        print()
        print(
            f"{GREEN}"
            f"Password: {password}"
            f"{RESET}"
        )

    else:

        while True:

            password = getpass.getpass(
                "Password: "
            )

            if not auth.valid_password(
                password
            ):

                print(
                    f"{RED}"
                    "Password ต้องมีอย่างน้อย "
                    "10 ตัวอักษร"
                    f"{RESET}"
                )

                continue

            password2 = getpass.getpass(
                "ยืนยัน Password: "
            )

            if password != password2:

                print(
                    f"{RED}"
                    "Password ไม่ตรงกัน"
                    f"{RESET}"
                )

                continue

            break

    try:

        auth.add_user(
            username,
            password
        )

    except Exception as e:

        print(
            f"{RED}"
            f"ไม่สามารถเพิ่ม user: {e}"
            f"{RESET}"
        )

        pause()
        return

    if apply_changes():

        print()
        print(
            f"{GREEN}"
            "เพิ่มผู้ใช้งานสำเร็จ"
            f"{RESET}"
        )

        print()
        print(
            f"{WHITE}"
            f"Username : {username}"
            f"{RESET}"
        )

        print(
            f"{WHITE}"
            f"Password : {password}"
            f"{RESET}"
        )

        try:

            print()
            print(
                f"{CYAN}"
                "URI:"
                f"{RESET}"
            )

            print(
                auth.build_uri(
                    username
                )
            )

        except Exception:
            pass

    pause()


def change_password():

    header()

    username = input(
        "Username ที่ต้องการเปลี่ยน Password: "
    ).strip()

    user = auth.get_user(
        username
    )

    if user is None:

        print(
            f"{RED}"
            "ไม่พบ Username นี้"
            f"{RESET}"
        )

        pause()
        return

    while True:

        password = getpass.getpass(
            "Password ใหม่: "
        )

        if not auth.valid_password(
            password
        ):

            print(
                f"{RED}"
                "Password ต้องมีอย่างน้อย "
                "10 ตัวอักษร"
                f"{RESET}"
            )

            continue

        password2 = getpass.getpass(
            "ยืนยัน Password ใหม่: "
        )

        if password != password2:

            print(
                f"{RED}"
                "Password ไม่ตรงกัน"
                f"{RESET}"
            )

            continue

        break

    try:

        auth.update_password(
            username,
            password
        )

    except Exception as e:

        print(
            f"{RED}"
            f"{e}"
            f"{RESET}"
        )

        pause()
        return

    if apply_changes():

        print()
        print(
            f"{GREEN}"
            "เปลี่ยน Password สำเร็จ"
            f"{RESET}"
        )

        print(
            f"{CYAN}"
            "URI:"
            f"{RESET}"
        )

        try:

            print(
                auth.build_uri(
                    username
                )
            )

        except Exception:
            pass

    pause()


def remove_user():

    header()

    username = input(
        "Username ที่ต้องการลบ: "
    ).strip()

    user = auth.get_user(
        username
    )

    if user is None:

        print(
            f"{RED}"
            "ไม่พบ Username นี้"
            f"{RESET}"
        )

        pause()
        return

    print()

    print(
        f"{YELLOW}"
        f"กำลังจะลบ: {username}"
        f"{RESET}"
    )

    confirm = input(
        "ยืนยันหรือไม่ [y/N]: "
    ).strip().lower()

    if confirm != "y":

        print(
            "ยกเลิก"
        )

        pause()
        return

    try:

        auth.remove_user(
            username
        )

    except Exception as e:

        print(
            f"{RED}"
            f"{e}"
            f"{RESET}"
        )

        pause()
        return

    if apply_changes():

        print()
        print(
            f"{GREEN}"
            "ลบผู้ใช้งานสำเร็จ"
            f"{RESET}"
        )

    pause()


def toggle_user():

    header()

    username = input(
        "Username: "
    ).strip()

    user = auth.get_user(
        username
    )

    if user is None:

        print(
            f"{RED}"
            "ไม่พบ Username นี้"
            f"{RESET}"
        )

        pause()
        return

    new_state = not user["enabled"]

    auth.set_user_enabled(
        username,
        new_state
    )

    if apply_changes():

        state = (
            "เปิดใช้งาน"
            if new_state
            else
            "ปิดใช้งาน"
        )

        print(
            f"{GREEN}"
            f"{state} {username} สำเร็จ"
            f"{RESET}"
        )

    pause()


def show_user():

    header()

    username = input(
        "Username: "
    ).strip()

    user = auth.get_user(
        username
    )

    if user is None:

        print(
            f"{RED}"
            "ไม่พบ Username นี้"
            f"{RESET}"
        )

        pause()
        return

    print()

    print(
        f"{CYAN}"
        f"Username : {user['username']}"
        f"{RESET}"
    )

    print(
        f"{CYAN}"
        f"Password : {user['password']}"
        f"{RESET}"
    )

    print(
        f"{CYAN}"
        f"Enabled  : {user['enabled']}"
        f"{RESET}"
    )

    print()

    try:

        print(
            f"{YELLOW}"
            "URI:"
            f"{RESET}"
        )

        print(
            auth.build_uri(
                username
            )
        )

    except Exception as e:

        print(
            f"{RED}"
            f"สร้าง URI ไม่สำเร็จ: {e}"
            f"{RESET}"
        )

    pause()


def show_config():

    header()

    try:

        with open(
            CONFIG_FILE,
            "r",
            encoding="utf-8"
        ) as f:

            data = json.load(f)

        print(
            json.dumps(
                data,
                indent=2,
                ensure_ascii=False
            )
        )

    except Exception as e:

        print(
            f"{RED}"
            f"{e}"
            f"{RESET}"
        )

    pause()


def regenerate():

    header()

    if apply_changes():

        print(
            f"{GREEN}"
            "สร้าง Configuration ใหม่สำเร็จ"
            f"{RESET}"
        )

    pause()


def main_menu():

    while True:

        header()

        users = auth.get_users()

        print(
            f"{WHITE}"
            f"จำนวน User: {len(users)}"
            f"{RESET}"
        )

        print()

        print(
            f"{GREEN}"
            "1."
            f"{RESET} เพิ่ม User"
        )

        print(
            f"{GREEN}"
            "2."
            f"{RESET} รายการ User"
        )

        print(
            f"{GREEN}"
            "3."
            f"{RESET} แสดงข้อมูล User"
        )

        print(
            f"{GREEN}"
            "4."
            f"{RESET} เปลี่ยน Password"
        )

        print(
            f"{GREEN}"
            "5."
            f"{RESET} ลบ User"
        )

        print(
            f"{GREEN}"
            "6."
            f"{RESET} เปิด/ปิด User"
        )

        print(
            f"{GREEN}"
            "7."
            f"{RESET} สร้าง Hysteria Config ใหม่"
        )

        print(
            f"{GREEN}"
            "8."
            f"{RESET} แสดง config.json"
        )

        print(
            f"{RED}"
            "0."
            f"{RESET} ออกจากโปรแกรม"
        )

        print()

        choice = input(
            "เลือกเมนู: "
        ).strip()

        if choice == "1":
            add_user()

        elif choice == "2":
            list_users()

        elif choice == "3":
            show_user()

        elif choice == "4":
            change_password()

        elif choice == "5":
            remove_user()

        elif choice == "6":
            toggle_user()

        elif choice == "7":
            regenerate()

        elif choice == "8":
            show_config()

        elif choice == "0":
            clear()
            break

        else:

            print(
                f"{RED}"
                "เลือกเมนูไม่ถูกต้อง"
                f"{RESET}"
            )

            pause()


if __name__ == "__main__":

    if os.geteuid() != 0:

        print(
            "กรุณารันด้วย root"
        )

        sys.exit(1)

    main_menu()
PY

chmod 700 "$VOLT_CFGUPT"
}


# ------------------------------------------------------------
# สร้างฐานข้อมูล config.json
# ------------------------------------------------------------

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

    else

        python3 - "$VOLT_CONFIG" "$DOMAIN" "$HYST_SERVER_IP" "$UDP_PORT" "$UDP_PORT_HP" "$PROTOCOL" "$OBFS" <<'PY'

import json
import sys

path = sys.argv[1]

domain = sys.argv[2]
server_ip = sys.argv[3]
port = int(sys.argv[4])
port_hopping = sys.argv[5]
protocol = sys.argv[6]
obfs = sys.argv[7]

try:

    with open(
        path,
        "r",
        encoding="utf-8"
    ) as f:
        data = json.load(f)

except Exception:

    data = {
        "version": 2,
        "server": {},
        "users": {}
    }

data.setdefault(
    "version",
    2
)

data.setdefault(
    "server",
    {}
)

data.setdefault(
    "users",
    {}
)

data["server"].update({
    "domain": domain,
    "ip": server_ip,
    "port": port,
    "port_hopping": port_hopping,
    "protocol": protocol,
    "obfs": obfs,
    "bandwidth_up": "100 mbps",
    "bandwidth_down": "100 mbps"
})

if not data["users"]:

    data["users"]["user1"] = {
        "password": "",
        "enabled": True
    }

tmp = path + ".tmp"

with open(
    tmp,
    "w",
    encoding="utf-8"
) as f:

    json.dump(
        data,
        f,
        indent=2,
        ensure_ascii=False
    )

    f.write("\n")

import os

os.chmod(
    tmp,
    0o600
)

os.replace(
    tmp,
    path
)

PY

    fi
}


# ------------------------------------------------------------
# สร้าง Hysteria config จาก config.json
# ------------------------------------------------------------

generate_hysteria_config_from_users() {

    python3 <<'PY'

import sys
import os

sys.path.insert(
    0,
    "/etc/volt"
)

import auth

data = auth.load_config()

users = auth.build_hysteria_auth()

if not users:

    print(
        "ERROR: ต้องมี User อย่างน้อย 1 รายการ",
        file=sys.stderr
    )

    sys.exit(1)

server = data["server"]

config = {

    "listen": ":" + str(
        server.get(
            "port_hopping",
            "10000-65000"
        )
    ),

    "tls": {
        "cert": "/etc/hysteria/hysteria.server.crt",
        "key": "/etc/hysteria/hysteria.server.key"
    },

    "auth": {
        "type": "userpass",
        "userpass": users
    },

    "obfs": {
        "type": "salamander",
        "salamander": {
            "password": server.get(
                "obfs",
                ""
            )
        }
    },

    "bandwidth": {
        "up": server.get(
            "bandwidth_up",
            "100 mbps"
        ),
        "down": server.get(
            "bandwidth_down",
            "100 mbps"
        )
    },

    "disableUDP": False
}


path = "/etc/hysteria/config.json"
tmp = path + ".tmp"

os.makedirs(
    "/etc/hysteria",
    exist_ok=True
)

import json

with open(
    tmp,
    "w",
    encoding="utf-8"
) as f:

    json.dump(
        config,
        f,
        indent=2,
        ensure_ascii=False
    )

    f.write("\n")

os.chmod(
    tmp,
    0o600
)

os.replace(
    tmp,
    path
)

print(
    "Hysteria configuration generated successfully"
)

PY

}


# ------------------------------------------------------------
# ติดตั้งระบบทั้งหมด
# ------------------------------------------------------------

install_volt_multi_user() {

    echo ""
    echo "=============================================="
    echo "   ติดตั้ง Voltssh-X Multi User System"
    echo "=============================================="
    echo ""

    install_volt_python_dependencies

    install_volt_auth_py

    install_volt_cfgupt_py

    install_volt_config_json

    generate_hysteria_config_from_users

    chmod 700 "$VOLT_AUTH"
    chmod 700 "$VOLT_CFGUPT"
    chmod 600 "$VOLT_CONFIG"
    chmod 600 "$HY_CONFIG"

    echo ""
    echo "ติดตั้ง Multi User Authentication สำเร็จ"
    echo ""
}


# ------------------------------------------------------------
# คำสั่ง volt
# ------------------------------------------------------------

install_volt_command() {

cat <<'SH' > /usr/local/bin/volt-user

#!/bin/bash

exec python3 /etc/volt/cfgupt.py "$@"

SH

chmod 755 /usr/local/bin/volt-user
}


# ------------------------------------------------------------
# เรียกใช้งาน
# ------------------------------------------------------------

install_volt_multi_user
install_volt_command

        get_running_services() {
            if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
                return
            fi

            systemctl list-units --state=active --plain --no-legend |
                grep -o "hysteria-server@*[^\s]*.service" || true
        }

        restart_running_services() {
            if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
                return
            fi

            echo "กำลังรีสตาร์ทบริการที่กำลังทำงาน ... "

            for service in $(get_running_services); do
                echo -ne "กำลังรีสตาร์ท $service ... "
                systemctl restart "$service"
                echo "เสร็จสิ้น"
            done
        }

        stop_running_services() {
            if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
                return
            fi

            echo "กำลังหยุดบริการที่กำลังทำงาน ... "

            for service in $(get_running_services); do
                echo -ne "กำลังหยุด $service ... "
                systemctl stop "$service"
                echo "เสร็จสิ้น"
            done
        }

        is_hysteria_installed() {
            if [[ -f "$EXECUTABLE_INSTALL_PATH" || -L "$EXECUTABLE_INSTALL_PATH" ]]; then
                return 0
            fi

            return 1
        }

        get_installed_version() {
            if is_hysteria_installed; then
                "$EXECUTABLE_INSTALL_PATH" -v | cut -d ' ' -f 3
            fi
        }

        get_latest_version() {
            if [[ -n "$VERSION" ]]; then
                echo "$VERSION"
                return
            fi

            local _tmpfile=$(mktemp)

            if ! curl -sS \
                -H 'Accept: application/vnd.github.v3+json' \
                "$API_BASE_URL/releases/latest" \
                -o "$_tmpfile"; then

                error "ไม่สามารถตรวจสอบเวอร์ชันล่าสุดได้ กรุณาตรวจสอบเครือข่าย"
                exit 11
            fi

            local _latest_version=$(grep 'tag_name' "$_tmpfile" |
                head -1 | grep -o '"v.*"')

            _latest_version=${_latest_version#'"'}
            _latest_version=${_latest_version%'"'}

            if [[ -n "$_latest_version" ]]; then
                echo "$_latest_version"
            fi

            rm -f "$_tmpfile"
        }
get_latest_version() {
    if [[ -n "$VERSION" ]]; then
        echo "$VERSION"
        return
    fi

    local _latest_version

    _latest_version="$(
        command curl -fsSL \
            -H 'Accept: application/vnd.github+json' \
            -H 'X-GitHub-Api-Version: 2022-11-28' \
            "$API_BASE_URL/releases/latest" |
            grep -o '"tag_name":[[:space:]]*"[^"]*"' |
            head -1 |
            sed -E 's/.*"tag_name":[[:space:]]*"([^"]*)".*/\1/'
    )"

    if [[ -z "$_latest_version" ]]; then
        error "ไม่สามารถตรวจสอบเวอร์ชัน Hysteria ล่าสุดจาก GitHub ได้"
        exit 11
    fi

    echo "$_latest_version"
}
        download_hysteria() {
            local _version="$1"
            local _destination="$2"

            local _download_url="$REPO_URL/releases/download/$_version/hysteria-$OPERATING_SYSTEM-$ARCHITECTURE"

            echo "กำลังดาวน์โหลด Hysteria: $_download_url ..."

            if ! curl -R \
                -H 'Cache-Control: no-cache' \
                "$_download_url" \
                -o "$_destination"; then

                error "ดาวน์โหลดไม่สำเร็จ! กรุณาตรวจสอบเครือข่ายแล้วลองใหม่"
                return 11
            fi

            return 0
        }

        perform_install_hysteria_binary() {
    if [[ -n "$LOCAL_FILE" ]]; then
        note "กำลังใช้ไฟล์ภายในเครื่อง: $LOCAL_FILE"

        echo -ne "กำลังติดตั้งไฟล์ Hysteria ... "

        if install -Dm755 "$LOCAL_FILE" "$EXECUTABLE_INSTALL_PATH"; then
            echo "สำเร็จ"
        else
            exit 2
        fi

        return
    fi

    local _tmpfile
    _tmpfile=$(mktemp)

    VERSION="$(get_latest_version)"

    echo "ตรวจพบ Hysteria เวอร์ชันล่าสุด: $VERSION"

    if ! download_hysteria "$VERSION" "$_tmpfile"; then
        rm -f "$_tmpfile"
        exit 11
    fi

    echo -ne "กำลังติดตั้งไฟล์ Hysteria $VERSION ... "

    if install -Dm755 "$_tmpfile" "$EXECUTABLE_INSTALL_PATH"; then
        echo "สำเร็จ"
    else
        rm -f "$_tmpfile"
        exit 13
    fi

    rm -f "$_tmpfile"
}


        tpl_etc_hysteria_config_json() {
    cat /etc/hysteria/config.json
}

        perform_install_hysteria_systemd() {
            if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
                return
            fi

            install_content -Dm644 \
                "$(tpl_hysteria_server_service)" \
                "$SYSTEMD_SERVICES_DIR/hysteria.service"

            install_content -Dm644 \
                "$(tpl_hysteria_server_x_service)" \
                "$SYSTEMD_SERVICES_DIR/hysteria@.service"

            systemctl daemon-reload
        }

        perform_remove_hysteria_systemd() {
            remove_file "$SYSTEMD_SERVICES_DIR/hysteria.service"
            remove_file "$SYSTEMD_SERVICES_DIR/hysteria@.service"

            systemctl daemon-reload
        }

        perform_install_hysteria_home_legacy() {
            if ! is_user_exists "$HYSTERIA_USER"; then
                echo -ne "กำลังสร้างผู้ใช้ $HYSTERIA_USER ... "

                useradd -r -d "$HYSTERIA_HOME_DIR" -m "$HYSTERIA_USER"

                echo "สำเร็จ"
            fi
        }

        perform_install() {
            local _is_frash_install

            if ! is_hysteria_installed; then
                _is_frash_install=1
            fi

            perform_install_hysteria_binary
           
            perform_install_hysteria_home_legacy
            perform_install_hysteria_systemd

            setup_ssl
            start_services
        }

        setup_ssl() {
            echo "กำลังสร้าง SSL Certificate..."

            openssl genrsa \
                -out /etc/hysteria/hysteria.ca.key 2048

            openssl req -new -x509 -days 3650 \
                -key /etc/hysteria/hysteria.ca.key \
                -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=Hysteria Root CA" \
                -out /etc/hysteria/hysteria.ca.crt

            openssl req -newkey rsa:2048 -nodes \
                -keyout /etc/hysteria/hysteria.server.key \
                -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=$DOMAIN" \
                -out /etc/hysteria/hysteria.server.csr

            openssl x509 -req \
                -extfile <(printf "subjectAltName=DNS:$DOMAIN,DNS:$DOMAIN") \
                -days 3650 \
                -in /etc/hysteria/hysteria.server.csr \
                -CA /etc/hysteria/hysteria.ca.crt \
                -CAkey /etc/hysteria/hysteria.ca.key \
                -CAcreateserial \
                -out /etc/hysteria/hysteria.server.crt
        }

        start_services() {
            echo "กำลังตั้งค่าและเริ่มบริการ Hysteria..."

            apt update

            sudo debconf-set-selections <<<"iptables-persistent iptables-persistent/autosave_v4 boolean true"
            sudo debconf-set-selections <<<"iptables-persistent iptables-persistent/autosave_v6 boolean true"

            sudo apt -y install iptables-persistent

            iptables -t nat -A PREROUTING \
                -i $(ip -4 route ls | grep default |
                grep -Po '(?<=dev )(\S+)' | head -1) \
                -p udp --dport 10000:65000 \
                -j DNAT --to-destination $UDP_PORT

            ip6tables -t nat -A PREROUTING \
                -i $(ip -4 route ls | grep default |
                grep -Po '(?<=dev )(\S+)' | head -1) \
                -p udp --dport 10000:65000 \
                -j DNAT --to-destination $UDP_PORT

            sysctl net.ipv4.conf.all.rp_filter=0

            sysctl net.ipv4.conf.$(ip -4 route ls |
                grep default |
                grep -Po '(?<=dev )(\S+)' |
                head -1).rp_filter=0

            echo "net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1).rp_filter=0" >/etc/sysctl.conf

            sysctl -p

            sudo iptables-save >/etc/iptables/rules.v4
            sudo ip6tables-save >/etc/iptables/rules.v6

            systemctl enable hysteria.service
            systemctl start hysteria.service
        }

        volt() {
            clear

            figlet -k volt-udp |
                awk '{gsub(/./,"\033[3"int(rand()*5+1)"m&\033[0m")}1' &&
            figlet -k hysteria |
                awk '{gsub(/./,"\033[3"int(rand()*5+1)"m&\033[0m")}1'

            echo "───────────────────────────────────────────────────────────────────────•"
            echo ""

            echo -e "\033[1;32m[\033[1;32mสำเร็จ ✅\033[1;32m] \033[1;37m ⇢  \033[1;33mกำลังตรวจสอบไฟล์ที่จำเป็น...\033[0m"
            echo -e "\033[1;32m      ♻️ \033[1;37m      \033[1;33mกรุณารอสักครู่...\033[0m"
            echo ""

            wget -O /usr/bin/volt --no-cache \
                'https://raw.githubusercontent.com/benzvpn/Edit-UDP-Hysteria/main/lib/volt.so' \
                &>/dev/null

            wget -O /etc/volt/cfgupt.py --no-cache \
                'https://raw.githubusercontent.com/benzvpn/Edit-UDP-Hysteria/main/lib/cfgupt.py' \
                &>/dev/null

            chmod +x /usr/bin/volt &>/dev/null
            chmod +x /etc/volt/cfgupt.py &>/dev/null

            echo ""
        }

        voltx_hysteria_inst() {
            check_permission
            check_environment
            check_hysteria_user "hysteria"
            check_hysteria_homedir "/var/lib/$HYSTERIA_USER"

            perform_install
            volt
        }

        voltx_hysteria_inst

        sleep 2

    else

        clear

        figlet -k volt-udp |
            awk '{gsub(/./,"\033[3"int(rand()*5+1)"m&\033[0m")}1' &&
        figlet -k hysteria |
            awk '{gsub(/./,"\033[3"int(rand()*5+1)"m&\033[0m")}1'

        echo "───────────────────────────────────────────────────────────────────────•"
        echo "${T_RED} ⇢ การตรวจสอบไม่สำเร็จ ยกเลิกการติดตั้ง${T_RESET}"

        exit 1
    fi
}

client_config() {

    clear

    echo ""
    echo "=============================================="
    echo "       Hysteria 2 Client Configuration"
    echo "=============================================="
    echo ""

    mkdir -p /etc/hysteria/client

    python3 <<'PY'

import sys
import os

sys.path.insert(
    0,
    "/etc/volt"
)

import auth

data = auth.load_config()

domain = data["server"].get(
    "domain",
    ""
)

ip = data["server"].get(
    "ip",
    ""
)

port = data["server"].get(
    "port",
    36712
)

port_hopping = data["server"].get(
    "port_hopping",
    "10000-65000"
)

obfs = data["server"].get(
    "obfs",
    ""
)

users = auth.get_users()

print()
print("----------------------------------------------")
print(" Hysteria 2 Client Configuration")
print("----------------------------------------------")
print()

print("Domain :", domain)
print("IP     :", ip)
print("Port   :", port)
print("Hopping:", port_hopping)
print()

if not users:

    print("ยังไม่มี User")

else:

    for user in users:

        username = user["username"]

        print(
            "Username :",
            username
        )

        print(
            "Password :",
            user["password"]
        )

        try:

            print(
                "URI      :",
                auth.build_uri(username)
            )

        except Exception as e:

            print(
                "URI      : ERROR",
                e
            )

        print(
            "----------------------------------------------"
        )


# สร้างไฟล์ข้อมูลรวม

info_path = (
    "/etc/hysteria/client/info.txt"
)

with open(
    info_path,
    "w",
    encoding="utf-8"
) as f:

    f.write(
        "Voltssh-X Hysteria 2 Client Configuration\n"
    )

    f.write(
        "==========================================\n\n"
    )

    f.write(
        f"Domain: {domain}\n"
    )

    f.write(
        f"IP: {ip}\n"
    )

    f.write(
        f"Server Port: {port}\n"
    )

    f.write(
        f"Port Hopping: {port_hopping}\n\n"
    )

    for user in users:

        username = user["username"]

        f.write(
            f"Username: {username}\n"
        )

        f.write(
            f"Password: {user['password']}\n"
        )

        try:

            f.write(
                f"URI: {auth.build_uri(username)}\n"
            )

        except Exception:
            pass

        f.write(
            "\n"
        )

os.chmod(
    info_path,
    0o600
)

PY

    echo ""
    echo "ไฟล์ Client Configuration:"
    echo ""
    echo "/etc/hysteria/client/info.txt"
    echo ""
    echo "จัดการ User:"
    echo ""
    echo "  volt-user"
    echo ""
}
reload_service() {
    echo "กำลังรีสตาร์ทบริการ Hysteria..."

    systemctl restart hysteria
    systemctl restart systemd-journald
}

main() {
    clear

    checkRoot
    script_header
    update_packages
    banner
    verification
    client_config
    reload_service

    echo "${T_GREEN}ติดตั้ง Voltssh-X Hysteria Server เสร็จสมบูรณ์!${T_RESET}"
    echo "${T_YELLOW}พิมพ์คำว่า \"volt\" เพื่อเข้าสู่เมนูจัดการ${T_RESET}"

    echo ""
    echo ""

    read -p " ⇢  กดปุ่มใดก็ได้เพื่อออก ↩︎" key
}

main
