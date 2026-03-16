# Atomicas ChemTools — Excel Add-in

> **RDKit-powered cheminformatics directly inside Microsoft Excel.**
> Compute molecular properties, render 2D structures, and run custom Excel formulas — all from a lightweight local server with no cloud dependency.

**Author:** Dr Suneel Kumar BVS — [suneelkumar.bvs@gmail.com](mailto:suneelkumar.bvs@gmail.com)

This tool is part of my ongoing research work in computational chemistry and drug discovery. It was built to reduce the friction of moving between cheminformatics tools and spreadsheets during lead optimisation and ADMET analysis workflows.

**Inputs, suggestions, and contributions are very welcome.**
If you use this in your research, encounter bugs, or have ideas for new features — please open an issue or start a discussion.

---

## Features

### Excel Custom Formulas
Use cheminformatics directly in cells — just like any built-in Excel function:

| Formula | Returns |
|---|---|
| `=CHEM.MW(A2)` | Molecular weight (Da) |
| `=CHEM.LOGP(A2)` | Lipophilicity (LogP) |
| `=CHEM.TPSA(A2)` | Topological polar surface area |
| `=CHEM.HBD(A2)` | Hydrogen bond donor count |
| `=CHEM.HBA(A2)` | Hydrogen bond acceptor count |
| `=CHEM.LIPINSKI(A2)` | Lipinski Rule of 5 — `PASS` / `FAIL` |
| `=CHEM.QED(A2)` | Quantitative estimate of drug-likeness (0–1) |
| `=CHEM.SCAFFOLD(A2)` | Murcko scaffold SMILES |
| `=CHEM.SMI2IMAGE(A2)` | Renders a 2D structure image into the calling cell |

All formulas accept a SMILES string (or a cell reference to one) and update live.

### Bulk Operations (Task Pane)
Select a column of SMILES strings and click:

- **Compute Properties** — writes MW, LogP, TPSA, HBD, HBA, RotBonds, Lipinski, and QED into adjacent columns, aligned row-by-row. Header rows (e.g. "SMILES") are automatically skipped.
- **Embed Structure Images** — renders each SMILES as a 250×200 px PNG and embeds it directly into its cell. The row and column are auto-resized to fit the image exactly.

### Single Molecule Analyser
Type or paste any SMILES into the task pane input and instantly see:
- 2D structure preview
- Full property table with Lipinski pass/fail indicators for each descriptor

### Architecture
```
Excel (Office JS add-in)
    │
    ├── Custom Functions (CHEM.*)  ─┐
    ├── Ribbon Buttons              ├──► FastAPI server (localhost:8000)
    └── Task Pane UI               ─┘         │
                                          RDKit (Python)
```

The server runs entirely locally — no data leaves your machine.

---

## Installation

### macOS (One-click installer)

**Requirements:** Microsoft Excel for Mac (Microsoft 365 or standalone 2019+)

1. Download `ChemToolsInstaller.dmg` from the [Releases](https://github.com/suneelbvs/rdKit-for-Excel/releases) page
2. Open the DMG and double-click **Install ChemTools.command**
3. When prompted "Launch ChemTools now?" press **Y**
4. Excel opens with ChemTools loaded in the ribbon

On subsequent launches, open **ChemTools.app** from `~/Applications/` — it starts the server and registers the add-in automatically.

> **Reinstalling / updating:** run the installer again. It replaces the previous version.

---

### Windows (Setup wizard)

**Requirements:** Microsoft Excel for Windows (Microsoft 365 or standalone 2019+)

1. Download `ChemToolsSetup.exe` from the [Releases](https://github.com/suneelbvs/rdKit-for-Excel/releases) page
2. Run the installer — it requires no administrator privileges
3. Follow the wizard; choose whether to auto-start the server with Windows
4. Excel opens with ChemTools loaded in the ribbon

The server runs silently in the background. If you need to restart it manually, run:
```
%LOCALAPPDATA%\ChemTools\chemtools-server\chemtools-server.exe
```

---

### Developer Setup (from source)

**Requirements:** Python 3.8+, conda (`cadd` environment with RDKit), Node.js 16+

```bash
# 1. Clone the repository
git clone https://github.com/suneelbvs/rdKit-for-Excel.git
cd Excel_plugin

# 2. Install frontend dependencies
npm install

# 3. Start the Python server
cd server
conda activate cadd
pip install -r requirements.txt
uvicorn server:app --reload --port 8000

# 4. Start the webpack dev server (separate terminal)
cd ..
npm run dev
# Serves the add-in at https://localhost:3000

# 5. Sideload the add-in in Excel
# Excel → Insert → Add-ins → Upload My Add-in → select manifest.xml
```

#### Building a distributable package

**macOS:**
```bash
# Prerequisites: conda (cadd env with pyinstaller), npm
bash packaging/build.sh
# Output: release/ChemToolsInstaller.dmg
```

**Windows** *(must be run on a Windows machine)*:
```bat
packaging\windows\build.bat
REM Output: release\windows\ChemToolsSetup.exe
REM Requires Inno Setup 6 for the .exe wizard (falls back to .zip without it)
REM https://jrsoftware.org/isdl.php
```

---

## Project Structure

```
Excel_plugin/
├── manifest.xml                    ← Office add-in manifest (SharedRuntime)
├── webpack.config.js
├── package.json
│
├── src/
│   ├── config.js                   ← API base URL, image dimensions
│   ├── api/chem.js                 ← All fetch calls to the Python server
│   ├── functions/
│   │   ├── functions.js            ← CHEM.* custom formula handlers
│   │   ├── functions.json          ← Formula metadata (name, params, return type)
│   │   └── functions.html          ← Custom functions runtime host page
│   ├── commands/
│   │   └── commands.js             ← Ribbon button handlers (ExecuteFunction)
│   └── taskpane/
│       ├── taskpane.html
│       ├── taskpane.css
│       └── taskpane.js             ← Task pane UI logic
│
├── server/
│   ├── server.py                   ← FastAPI + RDKit endpoints
│   ├── server_main.py              ← Uvicorn entry point (used by PyInstaller)
│   ├── requirements.txt
│   ├── start_server.sh             ← macOS/Linux dev launcher
│   └── start_server.bat            ← Windows dev launcher
│
├── packaging/
│   ├── build.sh                    ← macOS full build pipeline
│   ├── chemtools.spec              ← PyInstaller spec (macOS)
│   ├── launcher.sh                 ← macOS .app launcher script
│   ├── install.sh                  ← macOS end-user installer
│   ├── Info.plist                  ← macOS .app metadata
│   ├── hooks/                      ← PyInstaller hooks (RDKit, uvicorn, etc.)
│   └── windows/
│       ├── build.bat               ← Windows full build pipeline
│       ├── chemtools_windows.spec  ← PyInstaller spec (Windows)
│       ├── chemtools_setup.iss     ← Inno Setup script → ChemToolsSetup.exe
│       └── install.bat             ← Windows end-user installer (fallback)
│
├── dist/                           ← Webpack build output (served by FastAPI)
├── release/                        ← Final distributables (.dmg, .exe)
└── assets/
```

---

## API Endpoints

The local server exposes these REST endpoints (all `GET` with `?smiles=` parameter):

| Endpoint | Returns |
|---|---|
| `GET /` | Health check |
| `GET /properties` | All descriptors in one call |
| `GET /mw` | Molecular weight |
| `GET /logp` | LogP |
| `GET /tpsa` | TPSA |
| `GET /hbd` | H-bond donors |
| `GET /hba` | H-bond acceptors |
| `GET /lipinski` | Ro5 pass/fail + violation count |
| `GET /qed` | QED score |
| `GET /scaffold` | Murcko scaffold SMILES |
| `GET /structure` | Base64-encoded PNG (width/height params) |

---

## Test SMILES

| Molecule | SMILES |
|---|---|
| Aspirin | `CC(=O)Oc1ccccc1C(=O)O` |
| Caffeine | `Cn1cnc2c1c(=O)n(c(=O)n2C)C` |
| Ibuprofen | `CC(C)Cc1ccc(cc1)C(C)C(=O)O` |
| Paracetamol | `CC(=O)Nc1ccc(O)cc1` |
| Metformin | `CN(C)C(=N)NC(=N)N` |

---

## Requirements

| Component | Version |
|---|---|
| Python | 3.8+ |
| RDKit | 2022.09+ |
| FastAPI | 0.95+ |
| Uvicorn | 0.20+ |
| Node.js | 16+ |
| Microsoft Excel | 2019+ / Microsoft 365 |

---

## Roadmap / Ideas

- [ ] Substructure search across a column
- [ ] Similarity matrix / clustering
- [ ] SDF / MOL file import
- [ ] 3D conformation generation (RDKit ETKDGv3)
- [ ] Batch ADMET prediction integration
- [ ] Support for InChI / InChIKey input
- [ ] Windows auto-update mechanism

---

## Citation / Research Context

This add-in was developed by **Dr Suneel Kumar BVS** as part of research in computational drug discovery, with a focus on making cheminformatics accessible within everyday spreadsheet workflows used in medicinal chemistry and ADMET screening.

If you use this tool in your research, please consider citing or acknowledging this repository.

**Contact:** [suneelkumar.bvs@gmail.com](mailto:suneelkumar.bvs@gmail.com)

---

## Contributing

Contributions, bug reports, and feature requests are very welcome.

- **Bug / issue** → [Open an issue](https://github.com/suneelbvs/rdKit-for-Excel/issues)
- **Feature idea** → [Start a discussion](https://github.com/suneelbvs/rdKit-for-Excel/discussions)
- **Pull request** → Fork the repo, make changes, open a PR against `main`

Please keep PRs focused — one feature or fix per PR.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Built with [RDKit](https://www.rdkit.org/), [FastAPI](https://fastapi.tiangolo.com/), and the [Office JS API](https://learn.microsoft.com/en-us/office/dev/add-ins/overview/office-add-ins).*
