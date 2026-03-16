/* global Office, Excel */

import { getProperties, getStructureImage, checkServerHealth } from "../api/chem.js";

Office.onReady(async () => {
  await initializeUI();
});

async function initializeUI() {
  await updateServerStatus();
  setInterval(updateServerStatus, 30000);

  document.getElementById("analyze-btn").addEventListener("click", analyzeSmiles);
  document.getElementById("smiles-input").addEventListener("keydown", (e) => {
    if (e.key === "Enter") analyzeSmiles();
  });
  document.getElementById("compute-btn").addEventListener("click", runComputeProperties);
  document.getElementById("render-btn").addEventListener("click", runRenderStructures);
}

async function updateServerStatus() {
  const dot = document.getElementById("status-dot");
  const text = document.getElementById("status-text");
  dot.className = "dot yellow";
  text.textContent = "Checking...";
  const ok = await checkServerHealth();
  if (ok) {
    dot.className = "dot green";
    text.textContent = "Server online";
  } else {
    dot.className = "dot red";
    text.textContent = "Server offline";
  }
}

async function analyzeSmiles() {
  const smiles = document.getElementById("smiles-input").value.trim();
  if (!smiles) return;

  const btn = document.getElementById("analyze-btn");
  btn.textContent = "Loading...";
  btn.disabled = true;

  try {
    const [props, imageBase64] = await Promise.all([
      getProperties(smiles),
      getStructureImage(smiles),
    ]);

    if (props.error) {
      alert(`Error: ${props.error}`);
      return;
    }

    // Show structure image
    if (imageBase64) {
      const img = document.getElementById("structure-img");
      img.src = `data:image/png;base64,${imageBase64}`;
      img.style.display = "block";
    }

    // Render properties table
    const tbody = document.getElementById("properties-body");
    const lipinskiRules = {
      MW: { rule: "≤ 500", pass: props.MW <= 500 },
      LogP: { rule: "≤ 5", pass: props.LogP <= 5 },
      TPSA: { rule: "≤ 140", pass: props.TPSA <= 140 },
      HBD: { rule: "≤ 5", pass: props.HBD <= 5 },
      HBA: { rule: "≤ 10", pass: props.HBA <= 10 },
      RotBonds: { rule: "≤ 10", pass: props.RotBonds <= 10 },
      QED: { rule: "0–1", pass: true },
    };

    tbody.innerHTML = Object.entries({
      MW: props.MW,
      LogP: props.LogP,
      TPSA: props.TPSA,
      HBD: props.HBD,
      HBA: props.HBA,
      RotBonds: props.RotBonds,
      QED: props.QED,
    }).map(([key, val]) => {
      const info = lipinskiRules[key];
      const passClass = info.pass ? "pass" : "fail";
      const passText = info.pass ? "✓" : "✗";
      return `<tr>
        <td>${key}</td>
        <td>${val}</td>
        <td class="${passClass}">${passText} ${info.rule}</td>
      </tr>`;
    }).join("") + `<tr>
      <td><strong>Lipinski Ro5</strong></td>
      <td colspan="2" class="${props.Lipinski ? "pass" : "fail"}">
        ${props.Lipinski ? "PASS" : "FAIL"}
      </td>
    </tr>`;

    document.getElementById("properties-section").style.display = "block";
  } catch (err) {
    alert(`Failed to analyze molecule. Is the server running?\n${err.message}`);
  } finally {
    btn.textContent = "Analyze";
    btn.disabled = false;
  }
}

// Returns true for common column-header strings that are not SMILES
function isHeader(val) {
  const s = String(val).trim().toLowerCase();
  return ["smiles", "smile", "smi", "structure", "name", "compound",
          "mol", "molecule", "id", "cmpd", "inchi", "inchikey"].includes(s);
}

async function runComputeProperties() {
  try {
    await Excel.run(async (context) => {
      const selection = context.workbook.getSelectedRange();
      selection.load(["values", "rowIndex", "columnIndex"]);
      await context.sync();

      const sheet = context.workbook.worksheets.getActiveWorksheet();
      const allValues = selection.values.flat();
      const startRow = selection.rowIndex;
      const startCol = selection.columnIndex + 1;

      const smilesList = allValues.filter(v => v && !isHeader(v));
      if (smilesList.length === 0) {
        alert("Please select cells containing SMILES strings.");
        return;
      }

      const propHeaders = ["MW", "LogP", "TPSA", "HBD", "HBA", "RotBonds", "Lipinski", "QED"];

      // Write property column headers one row above the first data row.
      // If selection starts with a header (e.g. "SMILES"), use that same row.
      // If selection starts with data, write headers one row above (or same row if at top).
      const firstDataIdx = allValues.findIndex(v => v && !isHeader(v));
      const headerRow = firstDataIdx > 0
        ? startRow + firstDataIdx - 1          // row of the SMILES/header label
        : (startRow > 0 ? startRow - 1 : startRow); // one above data, or same if no room
      sheet.getRangeByIndexes(headerRow, startCol, 1, propHeaders.length).values = [propHeaders];
      await context.sync();

      // Write each property row aligned exactly with its SMILES row (startRow + i)
      for (let i = 0; i < allValues.length; i++) {
        const raw = allValues[i];
        if (!raw || isHeader(raw)) continue;
        const smiles = String(raw).trim();
        if (!smiles) continue;
        const props = await getProperties(smiles);
        const row = props.error
          ? Array(propHeaders.length).fill(props.error)
          : [props.MW, props.LogP, props.TPSA, props.HBD, props.HBA, props.RotBonds, props.Lipinski ? "PASS" : "FAIL", props.QED];
        sheet.getRangeByIndexes(startRow + i, startCol, 1, row.length).values = [row];
        await context.sync();
      }

      alert(`Done! Computed properties for ${smilesList.length} molecules.`);
    });
  } catch (err) {
    alert(`Error: ${err.message}`);
  }
}

async function runRenderStructures() {
  try {
    await Excel.run(async (context) => {
      const selection = context.workbook.getSelectedRange();
      selection.load(["values", "rowIndex", "columnIndex"]);
      await context.sync();

      const sheet = context.workbook.worksheets.getActiveWorksheet();
      const allValues = selection.values.flat();
      const smilesList = allValues.filter(v => v && !isHeader(v));

      if (smilesList.length === 0) {
        alert("Please select cells containing SMILES strings.");
        return;
      }

      // Images go into the SAME cells as the SMILES strings
      const destCol = selection.columnIndex;

      // Fixed display size: 250px × 200px converted to Excel points (1px = 0.75pt)
      const IMG_W_PT = 187.5;  // 250px
      const IMG_H_PT = 150;    // 200px
      const IMG_W_CH = 33;     // column width in chars to accommodate 250px

      for (let i = 0; i < allValues.length; i++) {
        const raw = allValues[i];
        if (!raw || isHeader(raw)) continue;
        const smiles = String(raw).trim();
        if (!smiles) continue;
        const imageBase64 = await getStructureImage(smiles);
        if (!imageBase64) continue;

        const targetRow = selection.rowIndex + i;
        const cell = sheet.getRangeByIndexes(targetRow, destCol, 1, 1);

        // Step 1: resize row height and column width to fit the image
        cell.format.rowHeight = IMG_H_PT;
        cell.format.columnWidth = IMG_W_CH;
        await context.sync();

        // Step 2: read cell position (top-left anchor)
        cell.load(["left", "top"]);
        await context.sync();

        // Step 3: remove any previously inserted image for this cell
        const shapeName = `img_r${targetRow}_c${destCol}`;
        try {
          sheet.shapes.getItem(shapeName).delete();
          await context.sync();
        } catch (_) { /* no prior image */ }

        // Step 4: insert image at fixed 250×200px dimensions (in points)
        const image = sheet.shapes.addImage(imageBase64);
        image.name = shapeName;
        image.left = cell.left;
        image.top = cell.top;
        image.width = IMG_W_PT;
        image.height = IMG_H_PT;
        await context.sync();
      }

      alert(`Done! Embedded ${smilesList.length} structure images.`);
    });
  } catch (err) {
    alert(`Error: ${err.message}`);
  }
}
