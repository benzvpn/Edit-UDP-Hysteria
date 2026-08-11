cat <<'PY' > /etc/volt/cfgupt.py
#!/usr/bin/env python3

import json
import os
import sys
import subprocess
import shutil
import tempfile

CONFIG_FILE = "/etc/hysteria/config.json"
PASSWORD_FILE = "/etc/volt/PASSWORD"


# ============================================================
# Colors
# ============================================================

RED = "\033[1;31m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[1;36m"
WHITE = "\033[1;37m"
BLUE = "\033[1;34m"
RESET = "\033[0m"


# ============================================================
# Header
# ============================================================

def header():
    os.system("clear")

    print(f"{RED}Voltssh-X Hysteria by @Thongjuea{RESET}")
    print(f"{YELLOW}  ⌯ Hysteria Config Updater{RESET}")
    print("    ------++------++------++------")
    print()


# ============================================================
# Root
# ============================================================

def check_root():
    if os.geteuid() != 0:
        print(f"{RED}กรุณารันด้วย root{RESET}")
        sys.exit(1)


# ============================================================
# Config
# ============================================================

def check_config():
    if not os.path.isfile(CONFIG_FILE):
        print(f"{RED}ไม่พบไฟล์:{RESET}")
        print(CONFIG_FILE)
        sys.exit(1)


def load_config():
    check_config()

    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            config = json.load(f)

        if not isinstance(config, dict):
            print(f"{RED}config.json ต้องเป็น JSON object{RESET}")
            sys.exit(1)

        return config

    except json.JSONDecodeError as e:
        print(f"{RED}config.json ไม่ถูกต้อง{RESET}")
        print(f"{YELLOW}{e}{RESET}")
        sys.exit(1)

    except Exception as e:
        print(f"{RED}ไม่สามารถอ่าน config ได้{RESET}")
        print(e)
        sys.exit(1)


# ============================================================
# Backup
# ============================================================

def backup_config():
    if not os.path.isfile(CONFIG_FILE):
        return False

    backup = CONFIG_FILE + ".bak"

    try:
        shutil.copy2(CONFIG_FILE, backup)
        return True

    except Exception as e:
        print(f"{RED}สร้าง backup ไม่สำเร็จ: {e}{RESET}")
        return False


# ============================================================
# Save JSON แบบปลอดภัย
# ============================================================

def save_config(config):
    directory = os.path.dirname(CONFIG_FILE)

    try:
        # ตรวจสอบก่อนว่าข้อมูลสามารถสร้าง JSON ได้
        encoded = json.dumps(
            config,
            indent=2,
            ensure_ascii=False
        )

        # ตรวจสอบ JSON ที่กำลังจะเขียน
        json.loads(encoded)

        # เขียน temporary file ก่อน
        fd, temp_file = tempfile.mkstemp(
            prefix=".config.",
            suffix=".tmp",
            dir=directory,
            text=True
        )

        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(encoded)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())

        # เปลี่ยนไฟล์แบบ atomic
        os.replace(temp_file, CONFIG_FILE)

        # permission
        os.chmod(CONFIG_FILE, 0o600)

        return True

    except Exception as e:
        try:
            if "temp_file" in locals() and os.path.exists(temp_file):
                os.remove(temp_file)
        except Exception:
            pass

        print(f"{RED}บันทึก config ไม่สำเร็จ: {e}{RESET}")
        return False


# ============================================================
# อ่าน Auth
#
# รองรับ:
#
# 1.
# auth:
#   type: password
#   password: xxx
#
# 2.
# auth:
#   type: userpass
#   userpass:
#     user1: xxx
#     user2: xxx
#
# 3. Legacy:
# auth:
#   config:
#     - xxx
# ============================================================

def get_auth_accounts(config):

    auth = config.get("auth")

    if not isinstance(auth, dict):
        return []

    accounts = []

    auth_type = auth.get("type", "")

    # --------------------------------------------------------
    # Hysteria 2 password
    # --------------------------------------------------------

    if auth_type == "password":

        password = auth.get("password", "")

        if isinstance(password, str) and password.strip():
            accounts.append(("password", password.strip()))

        return accounts

    # --------------------------------------------------------
    # Hysteria 2 userpass
    # --------------------------------------------------------

    if auth_type == "userpass":

        userpass = auth.get("userpass", {})

        if isinstance(userpass, dict):

            for username, password in userpass.items():

                if (
                    isinstance(username, str)
                    and isinstance(password, str)
                    and username.strip()
                    and password.strip()
                ):
                    accounts.append(
                        (username.strip(), password.strip())
                    )

        return accounts

    # --------------------------------------------------------
    # Legacy
    # --------------------------------------------------------

    legacy = auth.get("config")

    if isinstance(legacy, list):

        for password in legacy:

            if isinstance(password, str) and password.strip():
                accounts.append(
                    (f"user{len(accounts) + 1}", password.strip())
                )

    return accounts


# ============================================================
# Normalize Auth
#
# ถ้ามี 1 รหัส -> password
#
# ถ้ามีหลายรหัส -> userpass
#
# ============================================================

def normalize_auth_config(config):

    accounts = get_auth_accounts(config)

    auth = config.setdefault("auth", {})

    if not isinstance(auth, dict):
        auth = {}
        config["auth"] = auth

    # --------------------------------------------------------
    # ไม่มีรหัส
    # --------------------------------------------------------

    if not accounts:

        auth.clear()
        auth["type"] = "password"
        auth["password"] = ""

        return []


    # --------------------------------------------------------
    # มี 1 รหัส
    # --------------------------------------------------------

    if len(accounts) == 1:

        username, password = accounts[0]

        auth.clear()
        auth["type"] = "password"
        auth["password"] = password

        return [password]


    # --------------------------------------------------------
    # หลายรหัส
    #
    # ใช้ userpass ของ Hysteria 2
    # --------------------------------------------------------

    userpass = {}

    used_names = set()

    for index, (username, password) in enumerate(accounts, 1):

        # ถ้า username เดิมไม่เหมาะสม
        if not username or username == "password":
            username = f"user{index}"

        original = username
        counter = 2

        while username in used_names:

            username = f"{original}{counter}"
            counter += 1

        used_names.add(username)

        userpass[username] = password

    auth.clear()
    auth["type"] = "userpass"
    auth["userpass"] = userpass

    return list(userpass.values())


# ============================================================
# Sync /etc/volt/PASSWORD
#
# เก็บรหัสแรกไว้สำหรับเมนูหลัก
# ============================================================

def sync_password_file(config=None):

    if config is None:
        config = load_config()

    accounts = get_auth_accounts(config)

    os.makedirs("/etc/volt", exist_ok=True)

    if accounts:

        password = accounts[0][1]

        try:
            with open(
                PASSWORD_FILE,
                "w",
                encoding="utf-8"
            ) as f:
                f.write(password + "\n")

            os.chmod(PASSWORD_FILE, 0o600)

            return password

        except Exception:
            return ""

    # ไม่มี password
    try:
        if os.path.exists(PASSWORD_FILE):
            os.remove(PASSWORD_FILE)
    except Exception:
        pass

    return ""


# ============================================================
# Validate Auth
# ============================================================

def validate_auth(config):

    accounts = get_auth_accounts(config)

    auth = config.get("auth", {})

    if not isinstance(auth, dict):
        return False, "auth ไม่ใช่ object"

    auth_type = auth.get("type")

    # password
    if auth_type == "password":

        password = auth.get("password")

        if not isinstance(password, str):
            return False, "auth.password ต้องเป็น string"

        if not password:
            return False, "ยังไม่มีรหัสผ่าน"

        return True, "OK"

    # userpass
    if auth_type == "userpass":

        userpass = auth.get("userpass")

        if not isinstance(userpass, dict):
            return False, "auth.userpass ต้องเป็น object"

        if not userpass:
            return False, "ยังไม่มีบัญชี"

        for username, password in userpass.items():

            if not isinstance(username, str):
                return False, "username ต้องเป็น string"

            if not isinstance(password, str):
                return False, "password ต้องเป็น string"

            if not username or not password:
                return False, "username/password ห้ามว่าง"

        return True, "OK"

    return False, f"auth.type ไม่รองรับ: {auth_type}"


# ============================================================
# Add Password
# ============================================================

def add_password():

    config = load_config()

    print()
    print(f"{CYAN}========== เพิ่มรหัสผ่าน =========={RESET}")
    print()

    password = input("  * รหัสผ่านใหม่: ").strip()

    if not password:
        print(f"{RED}รหัสผ่านห้ามว่าง{RESET}")
        return

    if len(password) < 10:
        print(
            f"{RED}รหัสผ่านต้องมีอย่างน้อย 10 ตัวอักษร{RESET}"
        )
        return

    accounts = get_auth_accounts(config)

    # ตรวจซ้ำ
    for username, old_password in accounts:

        if old_password == password:

            print(
                f"{YELLOW}รหัสผ่านนี้มีอยู่แล้ว{RESET}"
            )
            return

    # ========================================================
    # ไม่มีรหัสเดิม
    #
    # ใช้ password แบบปกติ
    # ========================================================

    if not accounts:

        auth = config.setdefault("auth", {})

        auth.clear()
        auth["type"] = "password"
        auth["password"] = password

    # ========================================================
    # มี 1 รหัสเดิม
    #
    # เปลี่ยนเป็น userpass เพื่อรองรับหลายบัญชี
    # ========================================================

    elif len(accounts) == 1:

        old_username, old_password = accounts[0]

        auth = config.setdefault("auth", {})

        auth.clear()
        auth["type"] = "userpass"
        auth["userpass"] = {
            "user1": old_password,
            "user2": password
        }

    # ========================================================
    # มีหลายรหัส
    # ========================================================

    else:

        auth = config.setdefault("auth", {})

        if auth.get("type") != "userpass":

            passwords = [
                pwd
                for _, pwd in accounts
            ]

            auth.clear()
            auth["type"] = "userpass"
            auth["userpass"] = {}

            for index, pwd in enumerate(
                passwords,
                1
            ):
                auth["userpass"][
                    f"user{index}"
                ] = pwd

        userpass = auth.setdefault(
            "userpass",
            {}
        )

        next_number = len(userpass) + 1

        username = f"user{next_number}"

        while username in userpass:
            next_number += 1
            username = f"user{next_number}"

        userpass[username] = password

    # ========================================================
    # Backup
    # ========================================================

    if not backup_config():
        return

    # ========================================================
    # Validate
    # ========================================================

    valid, message = validate_auth(config)

    if not valid:

        print(
            f"{RED}Auth ไม่ถูกต้อง: {message}{RESET}"
        )

        return

    # ========================================================
    # Save
    # ========================================================

    if save_config(config):

        sync_password_file(config)

        print()
        print(
            f"{GREEN}============================{RESET}"
        )
        print(
            f"{GREEN}เพิ่มรหัสผ่านสำเร็จ ✓{RESET}"
        )
        print(
            f"{WHITE}รหัสผ่าน: {password}{RESET}"
        )
        print(
            f"{GREEN}============================{RESET}"
        )

        restart_service()


# ============================================================
# List Passwords
# ============================================================

def list_passwords():

    config = load_config()

    accounts = get_auth_accounts(config)

    print()
    print(
        f"{CYAN}========== รายการรหัสผ่าน =========={RESET}"
    )
    print()

    if not accounts:

        print(
            f"{YELLOW}ยังไม่มีรหัสผ่าน{RESET}"
        )

        return

    for index, (username, password) in enumerate(
        accounts,
        1
    ):

        if username == "password":
            print(
                f"{WHITE}{index}. {password}{RESET}"
            )

        else:
            print(
                f"{WHITE}{index}. "
                f"{username} : {password}{RESET}"
            )

    print()

    print(
        f"{GREEN}รวมทั้งหมด: "
        f"{len(accounts)} รายการ{RESET}"
    )

    # sync รหัสแรก
    sync_password_file(config)


# ============================================================
# Delete Password
# ============================================================

def delete_password():

    config = load_config()

    accounts = get_auth_accounts(config)

    if not accounts:

        print(
            f"{YELLOW}ไม่มีรหัสผ่านให้ลบ{RESET}"
        )

        return

    print()
    print(
        f"{CYAN}========== ลบรหัสผ่าน =========={RESET}"
    )
    print()

    for index, (username, password) in enumerate(
        accounts,
        1
    ):

        if username == "password":

            print(
                f"{index}. {password}"
            )

        else:

            print(
                f"{index}. "
                f"{username} : {password}"
            )

    print()

    choice = input(
        "เลือกหมายเลขที่ต้องการลบ: "
    ).strip()

    try:
        index = int(choice)

    except ValueError:

        print(
            f"{RED}กรุณาใส่หมายเลข{RESET}"
        )

        return

    if index < 1 or index > len(accounts):

        print(
            f"{RED}หมายเลขไม่ถูกต้อง{RESET}"
        )

        return

    username, password = accounts[index - 1]

    print()
    print(
        f"{YELLOW}รหัสผ่าน: {password}{RESET}"
    )

    if username != "password":

        print(
            f"{YELLOW}Username: {username}{RESET}"
        )

    confirm = input(
        "ยืนยันการลบ? [y/N]: "
    ).strip().lower()

    if confirm != "y":

        print(
            f"{YELLOW}ยกเลิก{RESET}"
        )

        return

    if not backup_config():
        return

    # ========================================================
    # เหลือ 0
    # ========================================================

    accounts.pop(index - 1)

    auth = config.setdefault("auth", {})

    if len(accounts) == 0:

        auth.clear()
        auth["type"] = "password"
        auth["password"] = ""

    # ========================================================
    # เหลือ 1
    # ========================================================

    elif len(accounts) == 1:

        auth.clear()
        auth["type"] = "password"
        auth["password"] = accounts[0][1]

    # ========================================================
    # เหลือหลายตัว
    # ========================================================

    else:

        auth.clear()
        auth["type"] = "userpass"
        auth["userpass"] = {}

        for i, (_, pwd) in enumerate(
            accounts,
            1
        ):

            auth["userpass"][
                f"user{i}"
            ] = pwd

    valid, message = validate_auth(config)

    if not valid and len(accounts) > 0:

        print(
            f"{RED}Auth ไม่ถูกต้อง: "
            f"{message}{RESET}"
        )

        return

    if save_config(config):

        sync_password_file(config)

        print(
            f"{GREEN}ลบรหัสผ่านสำเร็จ ✓{RESET}"
        )

        restart_service()


# ============================================================
# Delete All
# ============================================================

def delete_all():

    config = load_config()

    accounts = get_auth_accounts(config)

    if not accounts:

        print(
            f"{YELLOW}ไม่มีรหัสผ่านให้ลบ{RESET}"
        )

        return

    print()

    print(
        f"{RED}คุณกำลังจะลบรหัสผ่านทั้งหมด "
        f"{len(accounts)} รายการ{RESET}"
    )

    confirm = input(
        "พิมพ์ DELETE เพื่อยืนยัน: "
    ).strip()

    if confirm != "DELETE":

        print(
            f"{YELLOW}ยกเลิก{RESET}"
        )

        return

    if not backup_config():
        return

    auth = config.setdefault("auth", {})

    auth.clear()
    auth["type"] = "password"
    auth["password"] = ""

    if save_config(config):

        sync_password_file(config)

        print(
            f"{GREEN}ลบรหัสผ่านทั้งหมดแล้ว ✓{RESET}"
        )

        restart_service()


# ============================================================
# Restart
# ============================================================

def restart_service():

    print()

    print(
        f"{YELLOW}"
        f"กำลังตรวจสอบและรีสตาร์ท Hysteria..."
        f"{RESET}"
    )

    # ตรวจสอบ config ก่อน
    result = subprocess.run(
        [
            "hysteria",
            "server",
            "config",
            CONFIG_FILE
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # ถ้า command ข้างบนไม่มี/ไม่รองรับ
    # ให้ลอง systemctl ต่อ
    subprocess.run(
        [
            "systemctl",
            "restart",
            "hysteria"
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    result = subprocess.run(
        [
            "systemctl",
            "is-active",
            "hysteria"
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    if result.stdout.strip() == "active":

        print(
            f"{GREEN}"
            f"Hysteria ทำงานปกติ ✓"
            f"{RESET}"
        )

    else:

        print(
            f"{RED}"
            f"รีสตาร์ทไม่สำเร็จ ✗"
            f"{RESET}"
        )

        print()

        print(
            f"{YELLOW}"
            f"ดูรายละเอียดด้วย:"
            f"{RESET}"
        )

        print(
            "systemctl status hysteria --no-pager"
        )


# ============================================================
# Main Menu
# ============================================================

def menu():

    while True:

        header()

        print(
            f"{CYAN}"
            f"========== Hysteria Password Manager =========="
            f"{RESET}"
        )

        print()

        print("  1. เพิ่มรหัสผ่าน")
        print("  2. แสดงรหัสผ่านทั้งหมด")
        print("  3. ลบรหัสผ่าน")
        print("  4. ลบรหัสผ่านทั้งหมด")
        print("  5. รีสตาร์ท Hysteria")
        print("  0. ออก")

        print()

        print(
            "================================================"
        )

        print()

        choice = input(
            "เลือกเมนู: "
        ).strip()

        if choice == "1":

            add_password()

        elif choice == "2":

            list_passwords()

        elif choice == "3":

            delete_password()

        elif choice == "4":

            delete_all()

        elif choice == "5":

            restart_service()

        elif choice == "0":

            print("ออกจากโปรแกรม")
            break

        else:

            print(
                f"{RED}"
                f"ตัวเลือกไม่ถูกต้อง"
                f"{RESET}"
            )

        input(
            "\nกด Enter เพื่อกลับเมนู..."
        )


# ============================================================
# Run
# ============================================================

if __name__ == "__main__":

    check_root()
    menu()
PY

chmod +x /etc/volt/cfgupt.py
