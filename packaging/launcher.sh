#!/bin/bash
# launcher.sh — becomes ChemTools.app/Contents/MacOS/ChemTools
#
# Starts the chemtools-server, registers the manifest, opens Excel.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESOURCES_DIR="$(cd "$SCRIPT_DIR/../Resources" && pwd)"
SERVER_BIN="$RESOURCES_DIR/chemtools-server/chemtools-server"
MANIFEST="$RESOURCES_DIR/manifest.xml"
LOG_DIR="$HOME/.chemtools"
LOG_FILE="$LOG_DIR/server.log"

mkdir -p "$LOG_DIR"

# --- Step 1: Start server if not already running ---
if lsof -ti:8000 > /dev/null 2>&1; then
    echo "ChemTools server already running on port 8000."
else
    nohup "$SERVER_BIN" > "$LOG_FILE" 2>&1 &
    disown $!
    echo "ChemTools server started."
fi

# --- Step 2: Wait for server to be ready (max 15 seconds) ---
for i in $(seq 1 30); do
    if curl -s "http://localhost:8000/" > /dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

if ! curl -s "http://localhost:8000/" > /dev/null 2>&1; then
    osascript -e 'display alert "Atomicas ChemTools" message "Server failed to start.\n\nCheck log at ~/.chemtools/server.log" buttons {"OK"} default button "OK"'
    exit 1
fi

# --- Step 3: Register manifest with Excel ---
MAS_WEF="$HOME/Library/Containers/com.microsoft.Excel/Data/Documents/wef"
STANDALONE_WEF="$HOME/Library/Group Containers/UBF8T346G9.Office/User Content/Add-Ins"

if [ -d "$HOME/Library/Containers/com.microsoft.Excel" ]; then
    mkdir -p "$MAS_WEF"
    cp "$MANIFEST" "$MAS_WEF/ChemTools.xml"
fi

if [ -d "$HOME/Library/Group Containers/UBF8T346G9.Office" ]; then
    mkdir -p "$STANDALONE_WEF"
    cp "$MANIFEST" "$STANDALONE_WEF/ChemTools.xml"
fi

# --- Step 4: Open Excel ---
open -a "Microsoft Excel"
