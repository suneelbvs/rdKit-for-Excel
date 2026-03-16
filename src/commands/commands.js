/* global Excel, Office */

import { getProperties, getStructureImage } from "../api/chem.js";

Office.onReady(() => {
  // Commands context ready
});

// Returns true for common column-header strings that are not SMILES
function isHeader(val) {
  const s = String(val).trim().toLowerCase();
  return ["smiles", "smile", "smi", "structure", "name", "compound",
          "mol", "molecule", "id", "cmpd", "inchi", "inchikey"].includes(s);
}

async function computeProperties(event) {
  try {
    await Excel.run(async (context) => {
      const sheet = context.workbook.worksheets.getActiveWorksheet();
      const selection = context.workbook.getSelectedRange();
      selection.load(["values", "rowIndex", "columnIndex"]);
      await context.sync();

      const allValues = selection.values.flat();
      const startRow = selection.rowIndex;
      const startCol = selection.columnIndex + 1;

      const smilesList = allValues.filter(v => v && !isHeader(v));
      if (smilesList.length === 0) {
        event.completed();
        return;
      }

      const propHeaders = ["MW", "LogP", "TPSA", "HBD", "HBA", "RotBonds", "Lipinski", "QED"];

      // Write property headers aligned with the SMILES label row (or one above first data row)
      const firstDataIdx = allValues.findIndex(v => v && !isHeader(v));
      const headerRow = firstDataIdx > 0
        ? startRow + firstDataIdx - 1
        : (startRow > 0 ? startRow - 1 : startRow);
      sheet.getRangeByIndexes(headerRow, startCol, 1, propHeaders.length).values = [propHeaders];
      await context.sync();

      // Write each property row aligned exactly with its SMILES row (startRow + i)
      for (let i = 0; i < allValues.length; i++) {
        const raw = allValues[i];
        if (!raw || isHeader(raw)) continue;
        const smiles = String(raw).trim();
        if (!smiles) continue;
        try {
          const props = await getProperties(smiles);
          const row = props.error
            ? Array(propHeaders.length).fill(props.error)
            : [props.MW, props.LogP, props.TPSA, props.HBD, props.HBA, props.RotBonds,
               props.Lipinski ? "PASS" : "FAIL", props.QED];
          sheet.getRangeByIndexes(startRow + i, startCol, 1, row.length).values = [row];
          await context.sync();
        } catch {
          sheet.getRangeByIndexes(startRow + i, startCol, 1, propHeaders.length)
            .values = [Array(propHeaders.length).fill("API Error")];
          await context.sync();
        }
      }
    });
  } catch (error) {
    console.error("computeProperties error:", error);
  }
  event.completed();
}

async function renderStructures(event) {
  // Fixed display size: 250px × 200px in Excel points (1px = 0.75pt)
  const IMG_W_PT = 187.5;
  const IMG_H_PT = 150;
  const IMG_W_CH = 33;

  try {
    await Excel.run(async (context) => {
      const sheet = context.workbook.worksheets.getActiveWorksheet();
      const selection = context.workbook.getSelectedRange();
      selection.load(["values", "rowIndex", "columnIndex"]);
      await context.sync();

      const allValues = selection.values.flat();
      const destCol = selection.columnIndex; // same column as SMILES

      const smilesList = allValues.filter(v => v && !isHeader(v));
      if (smilesList.length === 0) {
        event.completed();
        return;
      }

      for (let i = 0; i < allValues.length; i++) {
        const raw = allValues[i];
        if (!raw || isHeader(raw)) continue;
        const smiles = String(raw).trim();
        if (!smiles) continue;

        const imageBase64 = await getStructureImage(smiles);
        if (!imageBase64) continue;

        const targetRow = selection.rowIndex + i;
        const cell = sheet.getRangeByIndexes(targetRow, destCol, 1, 1);

        // Resize row and column to fit the image
        cell.format.rowHeight = IMG_H_PT;
        cell.format.columnWidth = IMG_W_CH;
        await context.sync();

        // Read cell anchor position
        cell.load(["left", "top"]);
        await context.sync();

        // Remove any previously inserted image for this cell
        const shapeName = `img_r${targetRow}_c${destCol}`;
        try {
          sheet.shapes.getItem(shapeName).delete();
          await context.sync();
        } catch (_) { /* no prior image */ }

        // Insert image at fixed 250×200px (in points)
        const image = sheet.shapes.addImage(imageBase64);
        image.name = shapeName;
        image.left = cell.left;
        image.top = cell.top;
        image.width = IMG_W_PT;
        image.height = IMG_H_PT;
        await context.sync();
      }
    });
  } catch (error) {
    console.error("renderStructures error:", error);
  }
  event.completed();
}

// Expose functions globally for manifest FunctionName references
window.computeProperties = computeProperties;
window.renderStructures = renderStructures;
