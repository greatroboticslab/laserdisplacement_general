#!/usr/bin/env python3
import os
import sys
import subprocess
import venv
import shutil

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
VENV_DIR = os.path.join(PROJECT_ROOT, ".venv")
PY_DIR = os.path.join(PROJECT_ROOT, "PYbridge")
REQ_FILE = os.path.join(PY_DIR, "requirements.txt")
MAIN_PY = os.path.join(PY_DIR, "main.py")

def run_cmd(cmd, check=False, capture_output=False):
    try:
        return subprocess.run(
            cmd, shell=True, check=check,
            capture_output=capture_output, text=True
        )
    except FileNotFoundError:
        return None

#Checks and/or install virtual enviroment into root directory*** -----------------
def ensure_venv():
    if not os.path.isdir(VENV_DIR):
        print(f"[SETUP] Creating virtual environment at {VENV_DIR}")
        venv.EnvBuilder(with_pip=True).create(VENV_DIR)
    else:
        print("[SETUP] Using existing virtual environment")

def venv_python():
    if os.name == "nt":
        return os.path.join(VENV_DIR, "Scripts", "python.exe")
    else:
        return os.path.join(VENV_DIR, "bin", "python")
#-----------------------------------------------------------------------------
def install_deps():
    py = venv_python()
    print("[SETUP] Installing dependencies...")
    subprocess.run([py, "-m", "pip", "install", "--upgrade", "pip"])
    subprocess.run([py, "-m", "pip", "install", "-r", REQ_FILE])

def check_external(tool, version_args, install_url):
    print(f"[CHECK] Looking for {tool}...")
    result = run_cmd(f"{tool} {version_args}", capture_output=True)
    if result and result.returncode == 0:
        print(f"  Found: {result.stdout.strip()}")
    else:
        print(f"  ERROR: {tool} not found in PATH.")
        print(f"  Please install: {install_url}")
        sys.exit(1)

def main():
    ensure_venv()
    install_deps()

    # Check Mosquitto
    check_external(
        "mosquitto", "-h",
        "https://mosquitto.org/download/"
    )

    # Check Moku:CLI
    check_external(
        "moku", "--version",
        "https://www.liquidinstruments.com/software/"
    )

    # Run main.py
    py = venv_python()
    print(f"[RUN] Launching {MAIN_PY}")
    subprocess.run([py, MAIN_PY])

if __name__ == "__main__":
    main()
