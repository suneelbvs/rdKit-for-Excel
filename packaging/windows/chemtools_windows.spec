# chemtools_windows.spec — PyInstaller spec for Atomicas ChemTools (Windows)
#
# Run from the project root on a Windows machine:
#   conda activate cadd
#   pyinstaller packaging/windows/chemtools_windows.spec --clean -y
#
# Output: release\windows\pyinstaller_dist\chemtools-server\chemtools-server.exe

import sys
from PyInstaller.building.build_main import Analysis, PYZ, EXE, COLLECT

a = Analysis(
    ["../../server/server_main.py"],
    pathex=["../../server"],
    binaries=[],
    datas=[
        ("../../dist", "dist"),
        ("../../assets", "assets"),
    ],
    hiddenimports=[
        "rdkit", "rdkit.Chem", "rdkit.Chem.Descriptors", "rdkit.Chem.Crippen",
        "rdkit.Chem.Lipinski", "rdkit.Chem.Draw", "rdkit.Chem.QED",
        "rdkit.Chem.Scaffolds", "rdkit.Chem.Scaffolds.MurckoScaffold",
        "uvicorn", "uvicorn.logging", "uvicorn.loops", "uvicorn.loops.asyncio",
        "uvicorn.protocols", "uvicorn.protocols.http", "uvicorn.protocols.http.auto",
        "uvicorn.protocols.http.h11_impl", "uvicorn.protocols.websockets",
        "uvicorn.protocols.websockets.auto", "uvicorn.lifespan", "uvicorn.lifespan.on",
        "fastapi", "fastapi.staticfiles", "starlette", "starlette.staticfiles",
        "starlette.responses", "starlette.middleware.base",
        "anyio", "anyio.abc", "anyio._backends._asyncio",
        "PIL", "PIL.Image", "h11",
    ],
    hookspath=["../hooks"],
    runtime_hooks=[],
    excludes=["tkinter", "matplotlib", "IPython", "jupyter"],
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
    upx=False,
    console=True,
    icon="..\\..\\assets\\AppIcon.ico" if __import__("os").path.exists("..\\..\\assets\\AppIcon.ico") else None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    name="chemtools-server",
)
