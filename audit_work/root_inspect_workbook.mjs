import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const source = "E:/my_papers/GDP_PPP90_403.xlsx";
const outDir = "E:/my_papers/poverty_dynamics/audit_work/root_artifact_inspection";
await fs.mkdir(outDir, { recursive: true });

const input = await FileBlob.load(source);
const workbook = await SpreadsheetFile.importXlsx(input);

const output = {};
output.summary = (await workbook.inspect({
  kind: "workbook,sheet,table,definedName,drawing",
  include: "id,name,values,formulas",
  maxChars: 30000,
  tableMaxRows: 20,
  tableMaxCols: 20,
  tableMaxCellChars: 200,
})).ndjson;

output.sheets = [];
for (const sheet of workbook.worksheets.items) {
  const used = sheet.getUsedRange();
  const address = used?.address ?? null;
  const record = {
    name: sheet.name,
    id: sheet.id,
    visibility: sheet.visibility ?? null,
    usedRange: address,
  };
  if (address) {
    const range = sheet.getRange(address.includes("!") ? address.split("!").at(-1) : address);
    record.values = range.values;
    record.formulas = range.formulas;
    record.displayFormulas = range.displayFormulas;
    record.formulaInfos = range.formulaInfos;
    record.regionInspect = (await workbook.inspect({
      kind: "region",
      sheetId: sheet.id,
      range: address,
      include: "values,formulas",
      maxChars: 30000,
      tableMaxRows: 200,
      tableMaxCols: 100,
      tableMaxCellChars: 500,
    })).ndjson;
    record.formulaInspect = (await workbook.inspect({
      kind: "formula",
      sheetId: sheet.id,
      range: address,
      maxChars: 30000,
      options: { maxResults: 1000 },
    })).ndjson;
    record.styleInspect = (await workbook.inspect({
      kind: "computedStyle",
      sheetId: sheet.id,
      range: address,
      maxChars: 30000,
    })).ndjson;
  }
  const safeName = sheet.name.replace(/[^a-zA-Z0-9_-]+/g, "_");
  const preview = await workbook.render({
    sheetName: sheet.name,
    autoCrop: "all",
    scale: 2,
    format: "png",
  });
  await fs.writeFile(path.join(outDir, `${safeName}.png`), new Uint8Array(await preview.arrayBuffer()));
  output.sheets.push(record);
}

output.errors = (await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!",
  options: { useRegex: true, maxResults: 1000 },
  summary: "formula error scan",
  maxChars: 30000,
})).ndjson;

await fs.writeFile(path.join(outDir, "inspection.json"), JSON.stringify(output, null, 2), "utf8");
console.log(JSON.stringify({ source, outDir, sheetCount: output.sheets.length, sheets: output.sheets.map(s => ({name:s.name, id:s.id, visibility:s.visibility, usedRange:s.usedRange})) }, null, 2));
