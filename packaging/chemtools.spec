# chemtools.spec — PyInstaller spec for Atomicas ChemTools server
#
# Run from inside the packaging/ directory:
#   conda activate cadd
#   pyinstaller chemtools.spec --clean

import sys
from PyInstaller.building.build_main import Analysis, PYZ, EXE, COLLECT

a = Analysis(
    ["../server/server_main.py"],
    pathex=["../server"],
    binaries=[],
    datas=[
        ("../dist", "dist"),       # webpack production build output
        ("../assets", "assets"),   # icon files
    ],
    hiddenimports=[
        # RDKit
        "rdkit",
        "rdkit.Chem",
        "rdkit.Chem.Descriptors",
        "rdkit.Chem.Crippen",
        "rdkit.Chem.Lipinski",
        "rdkit.Chem.Draw",
        "rdkit.Chem.QED",
        "rdkit.Chem.Scaffolds",
        "rdkit.Chem.Scaffolds.MurckoScaffold",
        # uvicorn internals (not picked up by static analysis)
        "uvicorn",
        "uvicorn.logging",
        "uvicorn.loops",
        "uvicorn.loops.asyncio",
        "uvicorn.protocols",
        "uvicorn.protocols.http",
        "uvicorn.protocols.http.auto",
        "uvicorn.protocols.http.h11_impl",
        "uvicorn.protocols.websockets",
        "uvicorn.protocols.websockets.auto",
        "uvicorn.lifespan",
        "uvicorn.lifespan.on",
        # FastAPI / Starlette
        "fastapi",
        "fastapi.staticfiles",
        "starlette",
        "starlette.staticfiles",
        "starlette.responses",
        "anyio",
        "anyio.abc",
        "anyio._backends._asyncio",
        # Image
        "PIL",
        "PIL.Image",
        # h11 (HTTP/1.1 implementation used by uvicorn)
        "h11",
    ],
    hookspath=["./hooks"],
    hooksconfig={},
    runtime_hooks=[],
    excludes=["tkinter", "matplotlib", "IPython", "jupyter"],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="chemtools-server",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,          # UPX corrupts RDKit shared libraries
    console=True,       # required for background server (console=False suppresses stdout on macOS)
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name="chemtools-server",
)
