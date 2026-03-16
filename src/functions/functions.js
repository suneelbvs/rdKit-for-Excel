/* global CustomFunctions, Office, Excel */

// Custom functions runtime — shared runtime allows Excel.run() here.
const API_BASE = "http://localhost:8000";

async function callApi(endpoint, smiles) {
  try {
    const url = `${API_BASE}${endpoint}?smiles=${encodeURIComponent(String(smiles).trim())}`;
    const resp = await fetch(url);
    const data = await resp.json();
    return data;
  } catch {
    return { error: "Server unavailable" };
  }
}

Office.onReady(() => {
  CustomFunctions.associate("MW", async (smiles) => {
    const d = await callApi("/mw", smiles);
    return d.error ? d.error : d.MW;
  });

  CustomFunctions.associate("LOGP", async (smiles) => {
    const d = await callApi("/logp", smiles);
    return d.error ? d.error : d.LogP;
  });

  CustomFunctions.associate("TPSA", async (smiles) => {
    const d = await callApi("/tpsa", smiles);
    return d.error ? d.error : d.TPSA;
  });

  CustomFunctions.associate("HBD", async (smiles) => {
    const d = await callApi("/hbd", smiles);
    return d.error ? d.error : d.HBD;
  });

  CustomFunctions.associate("HBA", async (smiles) => {
    const d = await callApi("/hba", smiles);
    return d.error ? d.error : d.HBA;
  });

  CustomFunctions.associate("LIPINSKI", async (smiles) => {
    const d = await callApi("/lipinski", smiles);
    return d.error ? d.error : (d.Lipinski ? "PASS" : "FAIL");
  });

  CustomFunctions.associate("QED", async (smiles) => {
    const d = await callApi("/qed", smiles);
    return d.error ? d.error : d.QED;
  });

  CustomFunctions.associate("SCAFFOLD", async (smiles) => {
    const d = await callApi("/scaffold", smiles);
    return d.error ? d.error : d.scaffold;
  });

  // SMI2IMAGE: renders a structure image into the calling cell.
  // Requires SharedRuntime (Runtimes declared in manifest.xml).
  CustomFunctions.associate("SMI2IMAGE", async (smiles, invocation) => {
    const smi = String(smiles || "").trim();
    if (!smi) return "";

    try {
      const url = `${API_BASE}/structure?smiles=${encodeURIComponent(smi)}&width=300&height=200`;
      const resp = await fetch(url);
      const data = await resp.json();
      if (data.error) return `Error: ${data.error}`;

      const imageBase64 = data.image;
      const cellAddress = invocation.address; // e.g. "Sheet1!B2" or "B2"

      // Fixed display size: 250px × 200px in Excel points (1px = 0.75pt)
      const IMG_W_PT = 187.5;  // 250px
      const IMG_H_PT = 150;    // 200px
      const IMG_W_CH = 33;     // column width in chars to accommodate 250px

      await Excel.run(async (context) => {
        const sheet = context.workbook.worksheets.getActiveWorksheet();
        const localAddress = cellAddress.includes("!") ? cellAddress.split("!")[1] : cellAddress;
        const cell = sheet.getRange(localAddress);

        // Step 1: resize row and column to fit the image
        cell.format.rowHeight = IMG_H_PT;
        cell.format.columnWidth = IMG_W_CH;
        await context.sync();

        // Step 2: read cell anchor position
        cell.load(["left", "top"]);
        await context.sync();

        // Step 3: remove previously inserted image if it exists
        const shapeName = `img_${localAddress.replace(/[^A-Za-z0-9]/g, "_")}`;
        try {
          sheet.shapes.getItem(shapeName).delete();
          await context.sync();
        } catch (_) { /* no existing shape — fine */ }

        // Step 4: insert image at fixed 250×200px dimensions (in points)
        const image = sheet.shapes.addImage(imageBase64);
        image.name = shapeName;
        image.left = cell.left;
        image.top = cell.top;
        image.width = IMG_W_PT;
        image.height = IMG_H_PT;
        await context.sync();
      });

      return ""; // formula cell shows blank; image is overlaid
    } catch (e) {
      return `Error: ${e.message}`;
    }
  });
});
