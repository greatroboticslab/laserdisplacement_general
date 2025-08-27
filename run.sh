#!/bin/bash
set -euo pipefail

SOLUTION_ROOT="/mnt/c/Users/realvolney/source/repos/greatroboticslab/laserdisplacement/uMD_GUI-30-Dec-7.29PM-20250316T042754Z-001/uMD_GUI-30-Dec-7.29PM"
MSBUILD="/mnt/c/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/arm64/MSBuild.exe"
CONFIG="Debug"

PYEXE="/mnt/c/Users/realvolney/AppData/Local/Programs/Python/Python311/python.exe"   # adjust if needed
PYTHON_DIR="/mnt/c/Users/realvolney/laser/umd2Vcontrol/PYbridge"
MAIN_PY="$PYTHON_DIR/main.py"

VBPROJ_WIN=$(wslpath -w "$SOLUTION_ROOT/uMD_GUI.vbproj")
MSBUILD_WIN=$(wslpath -w "$MSBUILD")
VBEXE_WIN=$(wslpath -w "$SOLUTION_ROOT/bin/$CONFIG/uMD_GUI.exe")
PYEXE_WIN=$(wslpath -w "$PYEXE")
REQS_WIN=$(wslpath -w "$PYTHON_DIR/requirements.txt")
MAIN_PY_WIN=$(wslpath -w "$MAIN_PY")
POWERSHELL="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"

# 0) KILL any running uMD_GUI.exe so the copy step won’t fail
"$POWERSHELL" -NoProfile -Command "taskkill /IM uMD_GUI.exe /F /T 2>\$null; exit 0"

# 1) RESTORE + BUILD (single invocation)
"$POWERSHELL" -NoProfile -Command "& '$MSBUILD_WIN' '$VBPROJ_WIN' '/t:Restore,Build' '/p:Configuration=$CONFIG' '/m'"

# 2) START the app (background)
"$POWERSHELL" -NoProfile -Command "Start-Process -FilePath '$VBEXE_WIN'"

# 3) PY deps + run
"$POWERSHELL" -NoProfile -Command "& '$PYEXE_WIN' -m pip install --upgrade pip"
"$POWERSHELL" -NoProfile -Command "& '$PYEXE_WIN' -m pip install -r '$REQS_WIN'"
"$POWERSHELL" -NoProfile -Command "& '$PYEXE_WIN' '$MAIN_PY_WIN'"
