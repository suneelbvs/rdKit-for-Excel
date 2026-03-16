#!/bin/bash
# install.sh — Atomicas ChemTools one-time installer (no password required)
#
# End users double-click "Install ChemTools.command" in the DMG.
# What it does:
#   1. Copies ChemTools.app to ~/Applications/
#   2. Strips macOS Gatekeeper quarantine flag
#   3. Registers the Excel add-in manifest
#   4. Launches ChemTools (which opens Excel)

set -e

INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="$INSTALLER_DIR/ChemTools.app"
APP_DEST="$HOME/Applications/ChemTools.app"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Atomicas ChemTools Installer v1.0      ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if [ ! -d "$APP_SRC" ]; then
    echo "ERROR: ChemTools.app not found in installer folder."
    echo "Make sure install.sh and ChemTools.app are in the same folder."
    exit 1
fi

# --- Step 1: Copy app to ~/Applications ---
echo "[1/3] Installing ChemTools.app to ~/Applications..."
mkdir -p "$HOME/Applications"
rm -rf "$APP_DEST"
cp -R "$APP_SRC" "$APP_DEST"
chmod +x "$APP_DEST/Contents/MacOS/ChemTools"
echo "      Done."

# --- Step 2: Remove Gatekeeper quarantine ---
echo "[2/3] Removing Gatekeeper quarantine..."
xattr -rd com.apple.quarantine "$APP_DEST" 2>/dev/null || true
echo "      Done."

# --- Step 3: Register Excel add-in manifest ---
echo "[3/3] Registering Excel add-in..."
MANIFEST="$APP_DEST/Contents/Resources/manifest.xml"
REGISTERED=false

# Mac App Store Excel
MAS_WEF="$HOME/Library/Containers/com.microsoft.Excel/Data/Documents/wef"
if [ -d "$HOME/Library/Containers/com.microsoft.Excel" ]; then
    mkdir -p "$MAS_WEF"
    cp "$MANIFEST" "$MAS_WEF/ChemTools.xml"
    echo "      Registered (Mac App Store Excel)"
    REGISTERED=true
fi

# Standalone / volume-licensed Excel
STANDALONE_WEF="$HOME/Library/Group Containers/UBF8T346G9.Office/User Content/Add-Ins"
if [ -d "$HOME/Library/Group Containers/UBF8T346G9.Office" ]; then
    mkdir -p "$STANDALONE_WEF"
    cp "$MANIFEST" "$STANDALONE_WEF/ChemTools.xml"
    echo "      Registered (standalone Excel)"
    REGISTERED=true
fi

if [ "$REGISTERED" = false ]; then
    echo "      NOTE: Excel not found yet. Open Excel once, then re-run this installer."
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Installation complete! (no password)   ║"
echo "║                                          ║"
echo "║   Launch: ~/Applications/ChemTools.app  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

read -p "Launch ChemTools now? [Y/n] " LAUNCH
if [[ "$LAUNCH" =~ ^[Nn]$ ]]; then
    echo "You can launch later from ~/Applications/ChemTools.app"
else
    open "$APP_DEST"
fi
