import CONFIG from "../config.js";

async function apiFetch(endpoint, params = {}) {
  const url = new URL(`${CONFIG.API_BASE_URL}${endpoint}`);
  Object.entries(params).forEach(([k, v]) => url.searchParams.append(k, v));
  const response = await fetch(url.toString());
  if (!response.ok) throw new Error(`API error: ${response.status}`);
  return response.json();
}

export async function getProperties(smiles) {
  return apiFetch("/properties", { smiles });
}

export async function getMW(smiles) {
  const data = await apiFetch("/mw", { smiles });
  return data.error ? data.error : data.MW;
}

export async function getLogP(smiles) {
  const data = await apiFetch("/logp", { smiles });
  return data.error ? data.error : data.LogP;
}

export async function getTPSA(smiles) {
  const data = await apiFetch("/tpsa", { smiles });
  return data.error ? data.error : data.TPSA;
}

export async function getHBD(smiles) {
  const data = await apiFetch("/hbd", { smiles });
  return data.error ? data.error : data.HBD;
}

export async function getHBA(smiles) {
  const data = await apiFetch("/hba", { smiles });
  return data.error ? data.error : data.HBA;
}

export async function getLipinski(smiles) {
  const data = await apiFetch("/lipinski", { smiles });
  return data.error ? data.error : (data.Lipinski ? "PASS" : "FAIL");
}

export async function getQED(smiles) {
  const data = await apiFetch("/qed", { smiles });
  return data.error ? data.error : data.QED;
}

export async function getScaffold(smiles) {
  const data = await apiFetch("/scaffold", { smiles });
  return data.error ? data.error : data.scaffold;
}

export async function getStructureImage(smiles) {
  const data = await apiFetch("/structure", {
    smiles,
    width: CONFIG.STRUCTURE_WIDTH,
    height: CONFIG.STRUCTURE_HEIGHT,
  });
  return data.error ? null : data.image;
}

export async function checkServerHealth() {
  try {
    const data = await apiFetch("/");
    return data.status !== undefined;
  } catch {
    return false;
  }
}
