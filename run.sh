#!/bin/bash
set -euo pipefail

# ---- EDIT THESE ONCE ----
SOLUTION_ROOT="/mnt/c/Users/realvolney/source/repos/greatroboticslab/laserdisplacement/uMD_GUI-30-Dec-7.29PM-20250316T042754Z-001/uMD_GUI-30-Dec-7.29PM"
MSBUILD="/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/arm64/MSBuild.exe"
CONFIG="Debug"

PYTHON_DIR="/mnt/c/Users/realvolney/source/repos/greatroboticslab/laserdisplacement/PYbridge"
MAIN_PY="$PYTHON_DIR/main.py"
VENV="$HOME/.venvs/umd"
POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
# -------------------------

VBPROJ_WIN=$(wslpath -w "$SOLUTION_ROOT/uMD_GUI.vbproj")
MSBUILD_WIN=$(wslpath -w "$MSBUILD")
VBEXE_WIN=$(wslpath -w "$SOLUTION_ROOT/bin/$CONFIG/uMD_GUI.exe")
ps() { "$POWERSHELL" -NoProfile -Command "$@"; }

echo "[VB] Kill any existing uMD_GUI.exe (ignore errors)"
ps "taskkill /IM uMD_GUI.exe /F /T 2>\$null; exit 0"

echo "[VB] Restore + Build"
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -Command "& '$MSBUILD_WIN' '$VBPROJ_WIN' /restore /p:Configuration=$CONFIG /m"

echo "[VB] Launching EXE"
ps "Start-Process -FilePath '$VBEXE_WIN'"

echo "[PY] Ensure python3-venv is installed (one-time)"
if ! dpkg -s python3-venv >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y python3-venv
fi

echo "[PY] Ensure venv exists at $VENV"
if [ ! -d "$VENV" ]; then
  python3 -m venv "$VENV" || true
fi

# ---- Bootstrap pip inside the venv if missing ----
if ! "$VENV/bin/python" -m pip --version >/dev/null 2>&1; then
  echo "[PY] pip missing in venv; trying ensurepip"
  "$VENV/bin/python" -m ensurepip --upgrade || true
fi

# If pip still missing, install the full Python components and recreate/repair
if ! "$VENV/bin/python" -m pip --version >/dev/null 2>&1; then
  echo "[PY] ensurepip unavailable; installing python3-full (one-time, needs sudo)"
  sudo apt update
  sudo apt install -y python3-full
  # recreate venv to pick up ensurepip
  rm -rf "$VENV"
  python3 -m venv "$VENV"
  "$VENV/bin/python" -m ensurepip --upgrade
fi

# --- Moku CLI environment setup (Option 1: auto-download + symlink) ---
# --- Moku CLI environment setup (auto-download + detect binary + symlink) ---
MOKUCLI_BIN="$PYTHON_DIR/mokucli"

if [ ! -f "$MOKUCLI_BIN" ]; then
  echo "[MOKU] mokucli not found, downloading..."
  cd "$PYTHON_DIR"
  wget -q https://apis.liquidinstruments.com/cli/mokucli-linux-x64-latest.tar.gz -O mokucli.tar.gz
  tar -xvzf mokucli.tar.gz

  # auto-detect the extracted binary
  DETECTED_BIN=$(find "$PYTHON_DIR" -type f -name "mokucli" | head -n 1)
  if [ -n "$DETECTED_BIN" ]; then
    MOKUCLI_BIN="$DETECTED_BIN"
    chmod +x "$MOKUCLI_BIN"
    echo "[MOKU] Detected mokucli binary at $MOKUCLI_BIN"
  else
    echo "[MOKU] ERROR: Could not detect mokucli binary after extraction."
  fi
fi

if [ -f "$MOKUCLI_BIN" ]; then
  echo "[MOKU] Installing symlink to /usr/local/bin"
  sudo ln -sf "$MOKUCLI_BIN" /usr/local/bin/mokucli
fi

if command -v mokucli >/dev/null 2>&1; then
  export MOKU_CLI_PATH="$(command -v mokucli)"
  echo "[MOKU] Found mokucli in PATH: $MOKU_CLI_PATH"
else
  echo "[MOKU] ERROR: mokucli still not available!"
fi



echo "[PY] Install deps and run"
"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/python" -m pip install -r "$PYTHON_DIR/requirements.txt"
"$VENV/bin/python" "$MAIN_PY"
