# Forensic inventory of `GDP_PPP90_403.xlsx`

Read-only source: `E:\my_papers\GDP_PPP90_403.xlsx`  
SHA-256: `97F75738D099C31244045E3393AB38FE53C140DEFCFEDD569F91435994FE3B73`  
Size: 11,301 bytes

## Package and workbook structure

- One worksheet only: `Sheet1`, sheet ID 1, visible (no `state` attribute), used range/dimension `A1:G35`.
- No hidden or veryHidden sheets. No row or column has a `hidden` attribute.
- No defined names, external links, external connections, hyperlinks, comments/notes, merged cells, structured tables, pivot tables, charts/drawings, images, filters, validations, conditional formatting, sparklines, or sheet protection.
- Open XML parts are limited to workbook, one worksheet, styles, theme, shared strings, calculation chain, content types/relationships, and document properties.
- Core metadata: creator `Keshavarz`; last modified by `Ahmad Mohammadzadeh`; created `2025-11-27T12:18:35Z`; modified `2026-01-03T21:18:43Z`. Excel application version is recorded as `16.0300`.
- Default font Calibri 11. Gridlines are not suppressed. There are no headers, frozen panes, or unit/source notes. The saved view starts at `C14`; active cell is `H17` (outside the used range).

## Cell structure and formula method

- `A1 = "gen "`; `A2:A35 = "replace"`.
- `B1:B35 = "PPP_GDP="`.
- `C1:C35` are hard-coded numeric inputs (no formulas, URLs, links, or comments).
- `D1:D35 = "if "`, centered.
- `E1:E2 = " year=="` (leading space); `E3:E35 = "year=="`.
- `F1:F35` are integer Iranian-year labels 1369 through 1403.
- `G1` has the explicit formula `=C1*8.3*30`.
- `G2` is the shared-formula master `=C2*8.3*30`, with shared range `G2:G35` and shared index 0. `G3:G35` are its shared followers, so each effective formula is `=C[row]*8.3*30`.
- The calculation chain contains all 35 cells `G1:G35`. Independent IEEE-double recomputation equals every cached result exactly; there is no arithmetic/formula error.
- `G1:G35` use Excel Comma style with zero displayed decimals (`#,##0`). This is display rounding only: formulas contain no `ROUND`, `INT`, `TRUNC`, or floor operation. `C1:C35` use General format and therefore appear with fewer digits than are stored.
- The workbook never states a unit. The names and arithmetic imply that column C is intended as an annual `PPP_GDP` factor and column G as `PPP_GDP × $8.30/day × 30 days`, but rial/toman, per-person, price-basis, and calendar conventions are undocumented inside the file.

## Complete numerical inventory

`C exact` and `G cached exact` below reproduce the literal numeric text stored in the worksheet XML. `G displayed` is confirmed by the artifact-tool render.

| Row | Iranian year (F) | Implied Gregorian year (+621; not labeled in file) | C exact | G cached exact | G displayed |
|---:|---:|---:|---:|---:|---:|
| 1 | 1369 | 1990 | 96.673921771269704 | 24071.806521046157 | 24,072 |
| 2 | 1370 | 1991 | 117.466494532144 | 29249.157138503859 | 29,249 |
| 3 | 1371 | 1992 | 148.54777679894201 | 36988.396422936559 | 36,988 |
| 4 | 1372 | 1993 | 217.51263009152501 | 54160.644892789736 | 54,161 |
| 5 | 1373 | 1994 | 285.22772122241003 | 71021.702584380095 | 71,022 |
| 6 | 1374 | 1995 | 385.35625211913202 | 95953.706777663887 | 95,954 |
| 7 | 1375 | 1996 | 487.54274879978499 | 121398.14445114648 | 121,398 |
| 8 | 1376 | 1997 | 553.70053104010105 | 137871.43222898518 | 137,871 |
| 9 | 1377 | 1998 | 598.91504111875201 | 149129.84523856925 | 149,130 |
| 10 | 1378 | 1999 | 777.81131360294501 | 193675.01708713331 | 193,675 |
| 11 | 1379 | 2000 | 950.19025841983205 | 236597.37434653821 | 236,597 |
| 12 | 1380 | 2001 | 1066.8478025878701 | 265645.10284437967 | 265,645 |
| 13 | 1381 | 2002 | 1347.60735134329 | 335554.23048447922 | 335,554 |
| 14 | 1382 | 2003 | 1495.1160743673399 | 372283.90251746768 | 372,284 |
| 15 | 1383 | 2004 | 1815.7070255394201 | 452111.04935931566 | 452,111 |
| 16 | 1384 | 2005 | 2115.5343646689298 | 526768.05680256349 | 526,768 |
| 17 | 1385 | 2006 | 2351.51718071803 | 585527.77799878956 | 585,528 |
| 18 | 1386 | 2007 | 2814.6762933396199 | 700854.39704156539 | 700,854 |
| 19 | 1387 | 2008 | 3297.8030924026998 | 821152.97000827233 | 821,153 |
| 20 | 1388 | 2009 | 3428.3079829491398 | 853648.68775433581 | 853,649 |
| 21 | 1389 | 2010 | 3925.1119543723298 | 977352.87663871027 | 977,353 |
| 22 | 1390 | 2011 | 4758.86962890625 | 1184958.5375976563 | 1,184,959 |
| 23 | 1391 | 2012 | 6093.5625 | 1517297.0625000002 | 1,517,297 |
| 24 | 1392 | 2013 | 8503.8466796875 | 2117457.8232421875 | 2,117,458 |
| 25 | 1393 | 2014 | 9758.5537109375 | 2429879.8740234375 | 2,429,880 |
| 26 | 1394 | 2015 | 10701.5615234375 | 2664688.8193359375 | 2,664,689 |
| 27 | 1395 | 2016 | 11796.810546875 | 2937405.826171875 | 2,937,406 |
| 28 | 1396 | 2017 | 13061.294921875 | 3252262.4355468755 | 3,252,262 |
| 29 | 1397 | 2018 | 16923.19921875 | 4213876.60546875 | 4,213,877 |
| 30 | 1398 | 2019 | 23549.041015625 | 5863711.212890625 | 5,863,711 |
| 31 | 1399 | 2020 | 32954.5859375 | 8205691.8984375 | 8,205,692 |
| 32 | 1400 | 2021 | 50488.171875 | 12571554.796875002 | 12,571,555 |
| 33 | 1401 | 2022 | 70968.082972096905 | 17671052.660052132 | 17,671,053 |
| 34 | 1402 | 2023 | 89391.812935857699 | 22258561.421028569 | 22,258,561 |
| 35 | 1403 | 2024 | 117170.156249744 | 29175368.90618626 | 29,175,369 |

## Forensic implications

- An external value match conclusively identifies column C as a prior vintage of WDI indicator `PA.NUS.PPP`, **PPP conversion factor, GDP (LCU per international $)**, for Iran. Values for 2011–2021 match the current API exactly, including full precision; 1990–2010 differ only by microscopic subsequent revisions. The workbook itself still provides no provenance, citation, indicator code, or download date.
- The official WDI API response accessed 2026-07-11 reports metadata `lastupdated: 2026-07-01`. Its 2022–2024 values have been revised since this workbook was saved: 2022 is 71,211.4312451727 versus `C33` 70,968.082972096905 (+0.342898%); 2023 is 94,280.2670719049 versus `C34` 89,391.812935857699 (+5.468570%); and 2024 is 118,096.561683588 versus `C35` 117,170.156249744 (+0.790650%). Direct API: <https://api.worldbank.org/v2/country/IRN/indicator/PA.NUS.PPP?format=json&per_page=100>.
- The file maps Iranian labels to a single implied Gregorian year by adding 621. It gives no dates or explanation for Iranian years that span parts of two Gregorian calendar years.
- Current paper/Stata integers 1398–1403 are the floors/truncations of the cached G results. They are **not** always the workbook's displayed zero-decimal values. Relative to the display, current values are one rial lower in 1399, 1400, 1401, and 1403; they match in 1398 and 1402. No cell formula performs that truncation.

| Iranian year | G cached exact | Workbook display | Current paper/Stata | Current minus display |
|---:|---:|---:|---:|---:|
| 1398 | 5863711.212890625 | 5,863,711 | 5,863,711 | 0 |
| 1399 | 8205691.8984375 | 8,205,692 | 8,205,691 | -1 |
| 1400 | 12571554.796875002 | 12,571,555 | 12,571,554 | -1 |
| 1401 | 17671052.660052132 | 17,671,053 | 17,671,052 | -1 |
| 1402 | 22258561.421028569 | 22,258,561 | 22,258,561 | 0 |
| 1403 | 29175368.90618626 | 29,175,369 | 29,175,368 | -1 |

Artifact-tool evidence is stored in `audit_work/root_artifact_inspection/inspection.json`; its visual render is `audit_work/root_artifact_inspection/Sheet1.png`. Raw XML inspection independently confirmed visibility, formulas, cached values, formats, and absence of external/source metadata. The source workbook was never edited or exported.
