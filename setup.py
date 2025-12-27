#!/usr/bin/env python3
import os
import sys
import subprocess
import platform

VENV_DIR = "venvpatcher"
REQUIREMENTS_FILE = "requirements.txt"

def get_venv_paths():
    """Visszaadja a venv python és pip elérési útját platform szerint"""
    if platform.system() == "Windows":
        python_exe = os.path.join(VENV_DIR, "Scripts", "python.exe")
        pip_exe = os.path.join(VENV_DIR, "Scripts", "pip.exe")
    else:
        python_exe = os.path.join(VENV_DIR, "bin", "python")
        pip_exe = os.path.join(VENV_DIR, "bin", "pip")
    return python_exe, pip_exe

def create_venv():
    if not os.path.exists(VENV_DIR):
        print(f"🐍 Virtualenv létrehozása: {VENV_DIR}")
        subprocess.check_call([sys.executable, "-m", "venv", VENV_DIR])
    else:
        print(f"✅ Virtualenv már létezik: {VENV_DIR}")

def install_requirements():
    print("📦 Csomagok telepítése a virtualenvbe...")
    python_exe, pip_exe = get_venv_paths()
    packages = ["mysql-connector-python"]
    subprocess.check_call([pip_exe, "install"] + packages)

def start_mysql():
    system = platform.system()
    if system == "Linux":
        print("🚀 LAMPP MySQL indítása Linuxon...")
        subprocess.run(["sudo", "/opt/lampp/lampp", "startmysql"], check=False)
    elif system == "Windows":
        print("🚀 XAMPP MySQL indítása Windows-on...")
        xampp_path = r"C:\xampp\xampp_start.exe"
        if os.path.exists(xampp_path):
            subprocess.Popen([xampp_path])
        else:
            print("❌ XAMPP nincs telepítve az alapértelmezett útvonalon.")
    else:
        print(f"❌ Nem támogatott OS: {system}")

def run_main():
    python_exe, _ = get_venv_paths()
    print("▶ main.py futtatása a virtualenv-ből...")
    subprocess.check_call([python_exe, "main.py"])

if __name__ == "__main__":
    create_venv()
    install_requirements()
    start_mysql()
    run_main()
