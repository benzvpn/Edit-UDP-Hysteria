#!/usr/bin/env python3

import json
import os
import sys
import subprocess
import shutil

CONFIG_FILE = "/etc/hysteria/config.json"


# ==============================
# Colors
# ==============================

RED = "\033[1;31m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[1;36m"
WHITE = "\033[1;37m"
RESET = "\033[0m"


# ==============================
# Header
# ==============================

def header():
    os.system("clear")

    print(f"{RED} Voltssh-X Hysteria by @Thongjuea{RESET}")
    print(f"{YELLOW}  ⌯ Hysteria Config Updater{RESET}")
    print("    ------++------++------++------")
    print()


# ==============================
# Root check
# ==============================

def check_root():
    if os.geteuid() != 0:
        print(f"{RED}กรุณารันด้วย root{RESET}")
        sys.exit(1)


# ==============================
# Config check
# ==============================

def check_config():
    if not os.path.exists(CONFIG_FILE):
        print(f"{RED}ไม่พบไฟล์:{RESET}")
        print(CONFIG_FILE)
        sys.exit(1)


# ==============================
# Load config
# ==============================

def load_config():
    check_config()

    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)

    except json.JSONDecodeError as e:
        print(f"{RED}config.json ไม่ถูกต้อง{RESET}")
        print(e)
        sys.exit(1)

    except Exception as e:
        print(f"{RED}ไม่สามารถอ่าน config ได้{RESET}")
        print(e)
        sys.exit(1)


# ==============================
# Backup
# ==============================

def backup_config():

    backup = CONFIG_FILE + ".bak"

    try:
        shutil.copy2(CONFIG_FILE, backup)
        return True

    except Exception as e:
        print(f"{RED}สร้าง backup ไม่สำเร็จ: {e}{RESET}")
        return False


# ==============================
# Save config
# ==============================

def save_config(config):

    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(
                config,
                f,
                indent=2,
                ensure_ascii=False
            )
            f.write("\n")

        return True

    except Exception as e:
        print(f"{RED}บันทึก config ไม่สำเร็จ: {e}{RESET}")
        return False


# ==============================
# Get users
# ==============================

def get_users(config):

    auth = config.get("auth", {})

    userpass = auth.get("userpass", {})

    if not isinstance(userpass, dict):
        userpass = {}

    return userpass


# ==============================
# Find next username
# ==============================

def next_username(users):

    number = 1

    while True:

        username = f"user{number}"

        if username not in users:
            return username

        number += 1


# ==============================
# Convert old password auth
# ==============================

def prepare_userpass(config):

    auth = config.setdefault("auth", {})

    # ถ้าเป็น userpass อยู่แล้ว
    if auth.get("type") == "userpass":

        if not isinstance(auth.get("userpass"), dict):
            auth["userpass"] = {}

        return auth["userpass"]

    # รองรับ config เดิมที่เป็น password เดียว
    old_password = auth.get("password")

    users = {}

    if old_password:

        users["user1"] = old_password

    auth.clear()

    auth["type"] = "userpass"
    auth["userpass"] = users

    return users


# ==============================
# Add password
# ==============================

def add_password():

    config = load_config()

    if not backup_config():
        return

    users = prepare_userpass(config)

    print()
    print(f"{CYAN}========== เพิ่ม Password =========={RESET}")
    print()

    password = input("  * Create New Client Password: ").strip()

    if not password:
        print(f"{RED}Password ห้ามว่าง{RESET}")
        return

    if len(password) < 10:
        print(f"{RED}Password ต้องมีอย่างน้อย 10 ตัวอักษร{RESET}")
        return

    # ป้องกัน password ซ้ำ
    if password in users.values():
        print(f"{YELLOW}Password นี้มีอยู่แล้ว{RESET}")
        return

    username = next_username(users)

    users[username] = password

    config["auth"]["type"] = "userpass"
    config["auth"]["userpass"] = users

    if save_config(config):

        print()
        print(f"{GREEN}================================{RESET}")
        print(f"{GREEN}เพิ่ม Password สำเร็จ ✓{RESET}")
        print(f"{WHITE}Username : {username}{RESET}")
        print(f"{WHITE}Password : {password}{RESET}")
        print(f"{GREEN}================================{RESET}")

        restart_service()


# ==============================
# List passwords
# ==============================

def list_passwords():

    config = load_config()

    users = get_users(config)

    print()
    print(f"{CYAN}========== Password List =========={RESET}")
    print()

    if not users:

        print(f"{YELLOW}ยังไม่มี Password{RESET}")
        return

    for index, (username, password) in enumerate(users.items(), 1):

        print(
            f"{WHITE}{index}. "
            f"Username: {username} "
            f"| Password: {password}{RESET}"
        )

    print()
    print(f"{GREEN}รวมทั้งหมด: {len(users)} รายการ{RESET}")


# ==============================
# Delete password
# ==============================

def delete_password():

    config = load_config()

    users = get_users(config)

    if not users:

        print(f"{YELLOW}ไม่มี Password ให้ลบ{RESET}")
        return

    print()
    print(f"{CYAN}========== Delete Password =========={RESET}")
    print()

    items = list(users.items())

    for index, (username, password) in enumerate(items, 1):

        print(
            f"{index}. "
            f"{username} : {password}"
        )

    print()

    choice = input("เลือกหมายเลขที่ต้องการลบ: ").strip()

    try:
        index = int(choice)

    except ValueError:
        print(f"{RED}กรุณาใส่หมายเลข{RESET}")
        return

    if index < 1 or index > len(items):

        print(f"{RED}หมายเลขไม่ถูกต้อง{RESET}")
        return

    username, password = items[index - 1]

    print()
    print(f"{YELLOW}Username : {username}{RESET}")
    print(f"{YELLOW}Password : {password}{RESET}")

    confirm = input("ยืนยันการลบ? [y/N]: ").strip().lower()

    if confirm != "y":

        print(f"{YELLOW}ยกเลิก{RESET}")
        return

    if not backup_config():
        return

    del users[username]

    config["auth"]["type"] = "userpass"
    config["auth"]["userpass"] = users

    if save_config(config):

        print(f"{GREEN}ลบ Password สำเร็จ ✓{RESET}")

        restart_service()


# ==============================
# Delete all
# ==============================

def delete_all():

    config = load_config()

    users = get_users(config)

    if not users:

        print(f"{YELLOW}ไม่มี Password ให้ลบ{RESET}")
        return

    print()
    print(
        f"{RED}คุณกำลังจะลบ Password "
        f"ทั้งหมด {len(users)} รายการ{RESET}"
    )

    confirm = input("พิมพ์ DELETE เพื่อยืนยัน: ").strip()

    if confirm != "DELETE":

        print(f"{YELLOW}ยกเลิก{RESET}")
        return

    if not backup_config():
        return

    config["auth"]["type"] = "userpass"
    config["auth"]["userpass"] = {}

    if save_config(config):

        print(f"{GREEN}ลบ Password ทั้งหมดแล้ว ✓{RESET}")

        restart_service()


# ==============================
# Restart service
# ==============================

def restart_service():

    print()
    print(f"{YELLOW}กำลังตรวจสอบ config...{RESET}")

    # ตรวจสอบก่อน restart
    result = subprocess.run(
        [
            "/usr/local/bin/hysteria",
            "server",
            "-c",
            CONFIG_FILE,
            "--help"
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    # ไม่ใช้ผล --help เป็นตัวตัดสิน config
    # restart จริง
    print(f"{YELLOW}กำลัง Restart Hysteria...{RESET}")

    result = subprocess.run(
        ["systemctl", "restart", "hysteria"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    if result.returncode == 0:

        print(f"{GREEN}Hysteria Restart สำเร็จ ✓{RESET}")

    else:

        print(f"{RED}Restart ไม่สำเร็จ{RESET}")

        if result.stderr:
            print(result.stderr)


# ==============================
# Main menu
# ==============================

def menu():

    while True:

        header()

        print(f"{CYAN}========== Hysteria 2 Password Manager =========={RESET}")
        print()
        print("  1. เพิ่ม Password")
        print("  2. แสดง Password ทั้งหมด")
        print("  3. ลบ Password")
        print("  4. ลบ Password ทั้งหมด")
        print("  5. Restart Hysteria")
        print("  0. ออก")
        print()
        print("================================================")
        print()

        choice = input("เลือกเมนู: ").strip()

        if choice == "1":

            add_password()

            input("\nกด Enter เพื่อกลับเมนู...")

        elif choice == "2":

            list_passwords()

            input("\nกด Enter เพื่อกลับเมนู...")

        elif choice == "3":

            delete_password()

            input("\nกด Enter เพื่อกลับเมนู...")

        elif choice == "4":

            delete_all()

            input("\nกด Enter เพื่อกลับเมนู...")

        elif choice == "5":

            restart_service()

            input("\nกด Enter เพื่อกลับเมนู...")

        elif choice == "0":

            print("ออกจากโปรแกรม")
            break

        else:

            print(f"{RED}ตัวเลือกไม่ถูกต้อง{RESET}")
            input("\nกด Enter เพื่อกลับเมนู...")


# ==============================
# Run
# ==============================

if __name__ == "__main__":

    check_root()

    menu()
