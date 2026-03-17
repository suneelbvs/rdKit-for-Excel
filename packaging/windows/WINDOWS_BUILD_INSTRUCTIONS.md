# Windows Build Instructions — ChemToolsSetup.exe

These steps must be run on a **Windows machine** (or Windows VM).

---

## Prerequisites

### 1. Install Miniconda (Python environment manager)
- Download from: https://docs.conda.io/en/latest/miniconda.html
- Choose the **64-bit Windows installer**
- During install, check **"Add Miniconda to my PATH"**

### 2. Create the Python environment with RDKit
Open **Anaconda Prompt** and run:
```bat
conda create -n cadd python=3.11 -y
conda activate cadd
conda install -c conda-forge rdkit -y
pip install fastapi uvicorn[standard] pillow starlette python-multipart pyinstaller
```

### 3. Install Node.js
- Download from: https://nodejs.org (LTS version)
- Accept defaults during install

### 4. Install Inno Setup 6 (creates the .exe installer)
- Download from: https://jrsoftware.org/isdl.php
- Run the installer with default settings
- Required for `ChemToolsSetup.exe` — without it, a `.zip` is created instead

---

## Build Steps

### Step 1 — Copy the project to Windows
Transfer the full `Excel_plugin` project folder to your Windows machine.
(USB drive, network share, `git clone`, or zip copy all work.)

```bat
git clone https://github.com/suneelbvs/rdKit-for-Excel.git
cd rdKit-for-Excel
```

### Step 2 — Install Node dependencies
Open **Command Prompt** in the project root and run:
```bat
npm install
```

### Step 3 — Run the build script
Still in the project root, run:
```bat
packaging\windows\build.bat
```

The script does 4 things automatically:
1. Builds frontend JS/HTML with webpack → `dist\`
2. Bundles Python server as a standalone `.exe` with PyInstaller
3. Assembles the installer folder
4. Creates `ChemToolsSetup.exe` with Inno Setup

### Step 4 — Find the output
After the build completes:
```
release\windows\ChemToolsSetup.exe   ← installer for end users
```

---

## What the Installer Does (for end users)
When an end user runs `ChemToolsSetup.exe`:
1. Installs ChemTools to `%LOCALAPPDATA%\ChemTools\`
2. Registers the Excel add-in manifest automatically
3. Adds the server to Windows startup (auto-starts on login)
4. Starts the server and opens Excel

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `conda` not found | Re-open a fresh Command Prompt after Miniconda install |
| `npm` not found | Re-open a fresh Command Prompt after Node.js install |
| PyInstaller fails with missing module | Run `conda activate cadd` before running build.bat |
| Inno Setup not found | Install Inno Setup 6 from https://jrsoftware.org/isdl.php — without it, a `.zip` is created |
| `release\windows\ChemToolsSetup.exe` not found after build | Check if Inno Setup was installed; otherwise look for `ChemToolsSetup.zip` in the same folder |
| Server doesn't start after install | Check logs at `%LOCALAPPDATA%\ChemTools\logs\server.log` |
| Excel doesn't show ChemTools ribbon | Restart Excel after installation |

---

## Manual Alternative (no Inno Setup)
If you skip Inno Setup, the build creates `ChemToolsSetup.zip` instead.
Distribute the zip — the end user:
1. Extracts the zip
2. Double-clicks **"Install ChemTools.bat"**
3. Opens Excel

---

## Expected folder structure after build
```
release\
└── windows\
    ├── ChemToolsSetup.exe          ← final installer (if Inno Setup installed)
    ├── ChemToolsSetup.zip          ← fallback (if Inno Setup not installed)
    ├── ChemToolsSetup\
    │   ├── chemtools-server\       ← PyInstaller bundle
    │   │   └── chemtools-server.exe
    │   ├── manifest.xml
    │   └── Install ChemTools.bat
    ├── pyinstaller_dist\
    └── pyinstaller_build\
```
