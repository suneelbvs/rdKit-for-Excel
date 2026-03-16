from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import BaseHTTPMiddleware
from rdkit import Chem
from rdkit.Chem import Descriptors, Crippen, Lipinski, Draw, QED
from rdkit.Chem.Scaffolds import MurckoScaffold
import base64
import os
import sys
from io import BytesIO


def resource_path(relative: str) -> str:
    """Resolve path — works both in dev and inside a PyInstaller bundle."""
    base = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, relative)

app = FastAPI(title="Atomicas ChemTools API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prevent Excel / WebView from caching JS, HTML and JSON — ensures every
# reload picks up the latest add-in files without a manual cache clear.
class NoCacheMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        path = request.url.path
        if path.endswith((".js", ".html", ".json", ".css")):
            response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
            response.headers["Pragma"] = "no-cache"
            response.headers["Expires"] = "0"
        return response

app.add_middleware(NoCacheMiddleware)

def mol_from_smiles(smiles: str):
    mol = Chem.MolFromSmiles(smiles)
    return mol

@app.get("/")
def root():
    return {"status": "Atomicas ChemTools API running"}

@app.get("/properties")
def compute_properties(smiles: str = Query(..., description="SMILES string")):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    props = {
        "MW": round(Descriptors.MolWt(mol), 3),
        "LogP": round(Crippen.MolLogP(mol), 3),
        "TPSA": round(Descriptors.TPSA(mol), 3),
        "HBD": Lipinski.NumHDonors(mol),
        "HBA": Lipinski.NumHAcceptors(mol),
        "RotBonds": Lipinski.NumRotatableBonds(mol),
        "HeavyAtoms": mol.GetNumHeavyAtoms(),
        "Rings": Descriptors.RingCount(mol),
    }
    props["Lipinski"] = (
        props["MW"] <= 500 and
        props["LogP"] <= 5 and
        props["HBD"] <= 5 and
        props["HBA"] <= 10
    )
    props["QED"] = round(QED.qed(mol), 4)
    return props

@app.get("/mw")
def get_mw(smiles: str = Query(...)):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    return {"MW": round(Descriptors.MolWt(mol), 3)}

@app.get("/logp")
def get_logp(smiles: str = Query(...)):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    return {"LogP": round(Crippen.MolLogP(mol), 3)}

@app.get("/tpsa")
def get_tpsa(smiles: str = Query(...)):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    return {"TPSA": round(Descriptors.TPSA(mol), 3)}

@app.get("/hbd")
def get_hbd(smiles: str = Query(...)):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    return {"HBD": Lipinski.NumHDonors(mol)}

@app.get("/hba")
def get_hba(smiles: str = Query(...)):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    return {"HBA": Lipinski.NumHAcceptors(mol)}

@app.get("/lipinski")
def check_lipinski(smiles: str = Query(...)):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    mw = Descriptors.MolWt(mol)
    logp = Crippen.MolLogP(mol)
    hbd = Lipinski.NumHDonors(mol)
    hba = Lipinski.NumHAcceptors(mol)
    passes = mw <= 500 and logp <= 5 and hbd <= 5 and hba <= 10
    return {
        "Lipinski": passes,
        "MW": round(mw, 3),
        "LogP": round(logp, 3),
        "HBD": hbd,
        "HBA": hba,
        "violations": sum([mw > 500, logp > 5, hbd > 5, hba > 10])
    }

@app.get("/qed")
def get_qed(smiles: str = Query(...)):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    return {"QED": round(QED.qed(mol), 4)}

@app.get("/scaffold")
def get_scaffold(smiles: str = Query(...)):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    scaffold = MurckoScaffold.GetScaffoldForMol(mol)
    return {"scaffold": Chem.MolToSmiles(scaffold)}

@app.get("/structure")
def draw_structure(smiles: str = Query(...), width: int = 300, height: int = 200):
    mol = mol_from_smiles(smiles)
    if mol is None:
        return {"error": "Invalid SMILES"}
    img = Draw.MolToImage(mol, size=(width, height))
    buffer = BytesIO()
    img.save(buffer, format="PNG")
    encoded = base64.b64encode(buffer.getvalue()).decode()
    return {"image": encoded, "format": "png", "encoding": "base64"}

@app.post("/batch_properties")
def batch_properties(smiles_list: list):
    results = []
    for smiles in smiles_list:
        mol = mol_from_smiles(smiles)
        if mol is None:
            results.append({"smiles": smiles, "error": "Invalid SMILES"})
            continue
        results.append({
            "smiles": smiles,
            "MW": round(Descriptors.MolWt(mol), 3),
            "LogP": round(Crippen.MolLogP(mol), 3),
            "TPSA": round(Descriptors.TPSA(mol), 3),
            "HBD": Lipinski.NumHDonors(mol),
            "HBA": Lipinski.NumHAcceptors(mol),
            "QED": round(QED.qed(mol), 4),
        })
    return results


# Mount webpack dist/ as static files — must come AFTER all API routes
# so that /properties, /mw, etc. resolve before the catch-all static handler
_dist_path = resource_path("dist")
if os.path.isdir(_dist_path):
    app.mount("/", StaticFiles(directory=_dist_path, html=True), name="static")
