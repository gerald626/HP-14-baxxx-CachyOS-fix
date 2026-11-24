#!/usr/bin/env bash
set -euo pipefail

QUIRK_DIR="/etc/libinput"
QUIRK_FILE="${QUIRK_DIR}/local-overrides.quirks"
DEVICE_NAME="AT Translated Set 2 keyboard"
FALLBACK_EVENT="/dev/input/event3"

# Ensure script is run with sudo so we can target both /etc and the invoking user's ~/.config
if [[ $EUID -ne 0 ]] || [[ -z "${SUDO_USER:-}" ]]; then
    echo "Please run this script with sudo from your normal user account (e.g., sudo $0)"
    exit 1
fi

USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
KWINRC_FILE="${USER_HOME}/.config/kwinrc"

echo "[1/5] Installing libinput, libinput-tools, and KDE virtual keyboard packages..."
pacman -S --needed --noconfirm libinput libinput-tools

# Install plasma-keyboard if available in CachyOS/Arch repos, falling back to maliit-keyboard
if pacman -Si plasma-keyboard &>/dev/null; then
    VKB_PKG="plasma-keyboard"
    VKB_DESKTOP="org.kde.plasma.keyboard.desktop"
else
    VKB_PKG="maliit-keyboard"
    VKB_DESKTOP="com.github.maliit.keyboard.desktop"
fi
pacman -S --needed --noconfirm "$VKB_PKG"

echo "[2/5] Writing libinput local override quirk for side volume buttons..."
mkdir -p "$QUIRK_DIR"
cat <<'EOF' > "$QUIRK_FILE"
[HP Pavilion x360 Side Volume Buttons]
MatchName=*AT Translated Set 2 keyboard*
ModelTabletModeNoSuspend=1
EOF

echo "[3/5] Validating libinput quirk syntax..."
libinput quirks validate

echo "[4/5] Enabling KWin virtual keyboard for tablet mode (${VKB_PKG})..."
sudo -u "$SUDO_USER" kwriteconfig6 --file "$KWINRC_FILE" --group "Wayland" --key "InputMethod[$e]" "/usr/share/applications/${VKB_DESKTOP}"
sudo -u "$SUDO_USER" kwriteconfig6 --file "$KWINRC_FILE" --group "Wayland" --key "VirtualKeyboardEnabled" "true"

echo "[5/5] Verifying hardware quirk detection..."
EVENT_NODE=$(libinput list-devices | awk -v dev="$DEVICE_NAME" '
    $0 ~ "Device:.*" dev { found=1 }
    found && /Kernel:/ { print $2; exit }
')
EVENT_NODE="${EVENT_NODE:-$FALLBACK_EVENT}"

echo "Detected keyboard node: $EVENT_NODE"
QUIRKS_OUT=$(libinput quirks list "$EVENT_NODE")
echo "$QUIRKS_OUT"

if grep -q "ModelTabletModeNoSuspend=1" <<< "$QUIRKS_OUT"; then
    echo "Success: Volume button quirk is active and ${VKB_PKG} is configured in ${KWINRC_FILE}."
    echo "Log out and back into KDE Plasma (or reboot) to apply all changes."
else
    echo "Warning: ModelTabletModeNoSuspend=1 was not reported on $EVENT_NODE."
    exit 1
fi