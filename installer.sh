#!/usr/bin/env bash

if [ ! -t 0 ]; then
    x-terminal-emulator -e "$0" "$@" || gnome-terminal -- "$0" "$@" || konsole -e "$0" "$@" || xterm -e "$0" "$@"
    exit 0
fi

set -e

echo "=========================================="
echo "          kdlManager Installer            "
echo "=========================================="
echo ""

# 1. Detect Linux Distro & Package Manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    LIKE=$ID_LIKE
else
    echo "[-] Unable to determine OS. /etc/os-release not found."
    exit 1
fi

echo "[+] Detected Distro: $NAME ($DISTRO)"

PUYO=$(which puyo || true)  # puyo can be found at https://github.comm/catcodelabs/puyo

if [ "$PUYO" ]; then
        echo "[+] Found puyo at $PUYO"
        echo "[+] delegating install process to puyo"
        puyo .puyo
else

    if [[ "$DISTRO" =~ (ubuntu|debian|mint|pop) ]] || [[ "$LIKE" =~ (ubuntu|debian) ]]; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt-get install -y"
    elif [[ "$DISTRO" =~ (fedora|rhel|centos|nobara) ]] || [[ "$LIKE" =~ (fedora|rhel) ]]; then # added nobara to pay homage to the original OS where this was coded on :)
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
    elif [[ "$DISTRO" =~ (arch|manjaro|endeavouros|hyprarch) ]] || [[ "$LIKE" =~ (arch) ]]; then # "hyprarch" is my custom os-release name because its arch with hyprland. duh.
        echo "[-] puyo not found, skipping"
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"

    else
        echo "[-] Unsupported distribution family: $DISTRO"
        echo "    Please install dependencies manually."
        exit 1
    fi

    echo "[+] Using Package Manager: $PKG_MANAGER"
    echo ""

    # 2. Check for Native Kdenlive Installation
    echo "[*] Checking for Kdenlive installation..."
    KDENLIVE_PATH=$(which kdenlive || true)

    if [ -z "$KDENLIVE_PATH" ]; then
        echo "[-] Kdenlive installation was NOT found on your standard PATH."
        echo "    WARNING: kdlManager only supports native package installations of Kdenlive (Flatpak/AppImage are not supported)."
        read -p "--> Would you like to install native Kdenlive now via $PKG_MANAGER? [Y/n]: " INSTALL_KDEN
        INSTALL_KDEN=${INSTALL_KDEN:-Y}

        if [[ "$INSTALL_KDEN" =~ ^[Yy]$ ]]; then
            $INSTALL_CMD kdenlive
        else
            echo "[-] Native Kdenlive is required for kdlManager to function. Exiting installer."
            exit 1
        fi
    else
        echo "[+] Found Kdenlive at: $KDENLIVE_PATH"
    fi
    echo ""

    # 3. Check and Install General Dependencies
    echo "[*] Checking System Dependencies..."

    MISSING_DEPS=()

    # Check for PyQt6
    if ! python3 -c "import PyQt6" &>/dev/null; then
        if [ "$PKG_MANAGER" == "apt" ]; then
            MISSING_DEPS+=("python3-pyqt6")
        elif [ "$PKG_MANAGER" == "dnf" ]; then
            MISSING_DEPS+=("python3-qt6")
        elif [ "$PKG_MANAGER" == "pacman" ]; then
            MISSING_DEPS+=("python-pyqt6")
        fi
    fi

    # Check for FFmpeg binary (works with standard ffmpeg or ffmpeg-free)
    if ! command -v ffmpeg &>/dev/null; then
        MISSING_DEPS+=("ffmpeg")
    fi

    # Install missing system packages if any
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        echo "[!] Missing required packages: ${MISSING_DEPS[*]}"
        echo "[*] Installing missing dependencies..."
        $INSTALL_CMD "${MISSING_DEPS[@]}"
    else
        echo "[+] All required dependencies (PyQt6, FFmpeg) are present."
    fi
    echo ""
fi

# 4. Interactive Default Settings Configuration
echo "=========================================="
echo "      Configure Default Settings          "
echo "=========================================="

# Auto reopen setting
read -p "--> Reopen kdlManager automatically when Kdenlive closes? [Y/n]: " OPT_REOPEN
OPT_REOPEN=${OPT_REOPEN:-Y}
REOPEN_VAL=true
if [[ ! "$OPT_REOPEN" =~ ^[Yy]$ ]]; then REOPEN_VAL=false; fi

# Show Launch Kdenlive button setting
read -p "--> Show 'Launch Kdenlive' button on the main toolbar? [Y/n]: " OPT_LAUNCH
OPT_LAUNCH=${OPT_LAUNCH:-Y}
LAUNCH_VAL=true
if [[ ! "$OPT_LAUNCH" =~ ^[Yy]$ ]]; then LAUNCH_VAL=false; fi

# Auto-scan background setting
read -p "--> Enable background auto-scanning for project directories? [Y/n]: " OPT_AUTOSCAN
OPT_AUTOSCAN=${OPT_AUTOSCAN:-Y}
AUTOSCAN_VAL=true
if [[ ! "$OPT_AUTOSCAN" =~ ^[Yy]$ ]]; then AUTOSCAN_VAL=false; fi

CONFIG_DIR="$HOME/.config/kdlManager"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

# Write default config without overwriting existing history/indexed folders if file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "[*] Existing configuration file found. Updating preferences..."
    python3 -c "
import json
path = '$CONFIG_FILE'
try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}
data['reopenOnClose'] = $REOPEN_VAL
data['showLaunchButton'] = $LAUNCH_VAL
data['watchFolders'] = $AUTOSCAN_VAL
with open(path, 'w') as f:
    json.dump(data, f, indent=4)
"
else
    echo "[*] Creating new configuration file..."
    cat <<EOF > "$CONFIG_FILE"
{
    "reopenOnClose": $REOPEN_VAL,
    "showLaunchButton": $LAUNCH_VAL,
    "watchFolders": $AUTOSCAN_VAL,
    "autoProjectThumbnails": false,
    "projectPaths": [],
    "indexedFolders": [],
    "launchHistory": [],
    "sortBy": "modified"
}
EOF
fi

echo "[+] Settings saved to $CONFIG_FILE"
echo ""

# 5. Make main.py executable and generate Desktop Entry
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DESKTOP_FILE="$HOME/.local/share/applications/kdlManager.desktop"

mkdir -p "$HOME/.local/share/applications"

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=kdlManager
Comment=Kdenlive Project & Asset Manager
Exec=python3 "$SCRIPT_DIR/main.py"
Path=$SCRIPT_DIR
Icon=kdenlive
Terminal=false
Categories=AudioVideo;Video;Editing;
EOF

chmod +x "$DESKTOP_FILE"

echo "=========================================="
echo "      Installation Completed!             "
echo "=========================================="
echo "[+] kdlManager has been configured."
echo "[+] Desktop shortcut created at: $DESKTOP_FILE"
echo ""
read -p "Press [Enter] to exit..."
