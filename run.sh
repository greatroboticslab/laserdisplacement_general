#!/bin/bash
set -euo pipefail

# ---- EDIT THESE ONCE ----
SOLUTION_ROOT="/mnt/c/Users/realvolney/source/repos/greatroboticslab/laserdisplacement/uMD_GUI-30-Dec-7.29PM-20250316T042754Z-001/uMD_GUI-30-Dec-7.29PM"
MSBUILD="/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/arm64/MSBuild.exe"
CONFIG="Debug"

PYEXE="/mnt/c/Users/realvolney/AppData/Local/Programs/Python/Python311/python.exe"
PYTHON_DIR="/mnt/c/Users/realvolney/laser/umd2Vcontrol/PYbridge"
MAIN_PY="$PYTHON_DIR/main.py"
# -------------------------

# Convert to Windows-style paths
VBPROJ_WIN=$(wslpath -w "$SOLUTION_ROOT/uMD_GUI.vbproj")
MSBUILD_WIN=$(wslpath -w "$MSBUILD")
VBEXE_WIN=$(wslpath -w "$SOLUTION_ROOT/bin/$CONFIG/uMD_GUI.exe")
PYEXE_WIN=$(wslpath -w "$PYEXE")
REQS_WIN=$(wslpath -w "$PYTHON_DIR/requirements.txt")
MAIN_PY_WIN=$(wslpath -w "$MAIN_PY")

POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

# ---- RESTORE PACKAGES ----
"$POWERSHELL" -NoProfile -Command "& '$MSBUILD_WIN' '$VBPROJ_WIN' /t:Restore"

# ---- BUILD VB ----
"$POWERSHELL" -NoProfile -Command "& '$MSBUILD_WIN' '$VBPROJ_WIN' /p:Configuration=$CONFIG /m"

# ---- RUN VB EXE (background) ----
"$POWERSHELL" -NoProfile -Command "Start-Process -FilePath '$VBEXE_WIN'"

# ---- INSTALL PYTHON DEPENDENCIES ----
"$POWERSHELL" -NoProfile -Command "& '$PYEXE_WIN' -m pip install --upgrade pip"
"$POWERSHELL" -NoProfile -Command "& '$PYEXE_WIN' -m pip install -r '$REQS_WIN'"

# ---- RUN PYTHON ----
"$POWERSHELL" -NoProfile -Command "& '$PYEXE_WIN' '$MAIN_PY_WIN'"
