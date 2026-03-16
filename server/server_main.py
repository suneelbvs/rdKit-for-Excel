"""
server_main.py — PyInstaller entrypoint for Atomicas ChemTools server.

Starts a plain HTTP server on localhost:8000.
No SSL certificate needed — Office Add-ins allow HTTP for localhost sideloaded manifests.
"""

import os
import sys


def main():
    # Make server.py importable when running from PyInstaller bundle
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from server import app  # noqa: F401 — triggers StaticFiles mount

    import uvicorn

    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        log_level="error",
    )


if __name__ == "__main__":
    main()
