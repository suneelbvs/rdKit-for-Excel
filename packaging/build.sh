#!/bin/bash
# build.sh — Atomicas ChemTools developer build pipeline
#
# Prerequisites (one-time setup):
#   conda activate cadd
#   pip install pyinstaller cryptography
#   npm install   (in project root)
#
# Run from the packaging/ directory:
#   bash packaging/build.sh
#
# Output:
#   release/ChemToolsInstaller.dmg

set -e

PACKAGING_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$PACKAGING_DIR/.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/release"
APP_DIR="$RELEASE_DIR/ChemTools.app"
INSTALLER_DIR="$RELEASE_DIR/ChemToolsInstaller"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Atomicas ChemTools Build Pipeline      ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- Step 1: Build JS/CSS/HTML with webpack ---
echo "[1/4] Building frontend (webpack)..."
cd "$PROJECT_ROOT"
npm run build
# Output: dist/taskpane.html, dist/commands.html, dist/taskpane.js, dist/assets/
echo "      Done. Output: dist/"

# --- Step 2: Bundle Python + RDKit + static files with PyInstaller ---
echo "[2/4] Bundling Python server (PyInstaller)..."
cd "$PACKAGING_DIR"
conda run -n cadd pyinstaller chemtools.spec \
    --clean \
    -y \
    --distpath "$RELEASE_DIR/pyinstaller_dist" \
    --workpath "$RELEASE_DIR/pyinstaller_build"
# Output: release/pyinstaller_dist/chemtools-server/
echo "      Done. Output: release/pyinstaller_dist/chemtools-server/"

# --- Step 3: Assemble macOS .app bundle ---
echo "[3/4] Assembling ChemTools.app..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Info.plist
cp "$PACKAGING_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

# Launcher script → becomes the executable
cp "$PACKAGING_DIR/launcher.sh" "$APP_DIR/Contents/MacOS/ChemTools"
chmod +x "$APP_DIR/Contents/MacOS/ChemTools"

# PyInstaller bundle (self-contained binary + all shared libs)
cp -R "$RELEASE_DIR/pyinstaller_dist/chemtools-server" "$APP_DIR/Contents/Resources/"

# Manifest (so launcher can copy it to Excel's WEF folder)
cp "$PROJECT_ROOT/manifest.xml" "$APP_DIR/Contents/Resources/manifest.xml"

# App icon (if .icns exists)
if [ -f "$PROJECT_ROOT/assets/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/assets/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo "      Done. Output: release/ChemTools.app"

# --- Step 4: Package as installer folder + DMG ---
echo "[4/4] Creating installer DMG..."
rm -rf "$INSTALLER_DIR"
mkdir -p "$INSTALLER_DIR"
cp -R "$APP_DIR" "$INSTALLER_DIR/ChemTools.app"
cp "$PACKAGING_DIR/install.sh" "$INSTALLER_DIR/install.sh"
chmod +x "$INSTALLER_DIR/install.sh"

# Create a double-clickable .command wrapper (Terminal opens and runs install.sh)
cat > "$INSTALLER_DIR/Install ChemTools.command" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
bash install.sh
EOF
chmod +x "$INSTALLER_DIR/Install ChemTools.command"

# Build DMG
DMG_PATH="$RELEASE_DIR/ChemToolsInstaller.dmg"
rm -f "$DMG_PATH"
hdiutil create \
    -volname "ChemTools Installer" \
    -srcfolder "$INSTALLER_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "      Done."
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Build complete!                        ║"
echo "║                                          ║"
echo "║   Distributable: release/               ║"
echo "║   └── ChemToolsInstaller.dmg            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "End-user workflow:"
echo "  1. Open ChemToolsInstaller.dmg"
echo "  2. Double-click 'Install ChemTools.command'"
echo "  3. Enter password once (to trust SSL cert)"
echo "  4. Excel opens with ChemTools ready"
