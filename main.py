import configparser
import os
import socket
import subprocess
import time
import mysql.connector

INI_FILE = "db.ini"
SQL_FILE = "app/core/db_version/memoriz.sql"


def check_db_active(host="127.0.0.1", port=3306, timeout=10):
    print("🚀 MySQL indítása...")
    subprocess.run(
        ["sudo", "/opt/lampp/lampp", "startmysql"],
        check=False
    )

    print("⏳ Várakozás MySQL-re...")
    for _ in range(timeout):
        try:
            with socket.create_connection((host, port), timeout=2):
                print("✅ MySQL elérhető")
                return True
        except OSError:
            time.sleep(1)
    return False


def load_config():
    cfg = configparser.ConfigParser()
    cfg.read(INI_FILE)
    return cfg["mysql"]


def confirm_drop(db_name):
    print(f"\n⚠️ FIGYELEM ⚠️")
    print(f"Az adatbázis TELJESEN törölve lesz: {db_name}")
    ans = input("Biztosan törlöd? [I/N]: ").strip().upper()
    return ans == "I"


def run_sql_dump(cfg, sql_file):
    print("🐬 SQL dump betöltése...")

    cmd = [
        "/opt/lampp/bin/mysql",
        "-h", cfg.get("host", "127.0.0.1"),
        "-P", cfg.get("port", "3306"),
        "-u", cfg.get("user"),
        f"-p{cfg.get('password')}",
        cfg.get("database")
    ]

    with open(sql_file, "r", encoding="utf-8") as f:
        subprocess.run(cmd, stdin=f, check=True)


def main():
    cfg = load_config()
    db_name = cfg["database"]

    if not check_db_active():
        raise RuntimeError("❌ MySQL nem indult el")

    if not confirm_drop(db_name):
        print("❌ Művelet megszakítva")
        return

    print("🔌 Kapcsolódás MySQL-hez...")
    conn = mysql.connector.connect(
        host=cfg.get("host", "127.0.0.1"),
        port=int(cfg.get("port", 3306)),
        user=cfg.get("user"),
        password=cfg.get("password"),
        use_pure=True
    )

    cursor = conn.cursor()

    print(f"🗑️ Adatbázis törlése: {db_name}")
    cursor.execute(f"DROP DATABASE IF EXISTS `{db_name}`")

    print(f"🆕 Adatbázis létrehozása: {db_name}")
    cursor.execute(
        f"CREATE DATABASE `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    )

    cursor.close()
    conn.close()

    run_sql_dump(cfg, SQL_FILE)

    print("🎉 Adatbázis sikeresen újralétrehozva")


if __name__ == "__main__":
    main()
