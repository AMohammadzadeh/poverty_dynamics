# Audit of `GDP_PPP90_403.xlsx`

**Audit date:** 11 July 2026  
**Source workbook:** `E:\my_papers\GDP_PPP90_403.xlsx` (read-only)  
**SHA-256:** `97F75738D099C31244045E3393AB38FE53C140DEFCFEDD569F91435994FE3B73`

## 1. Verdict

The workbook's multiplication is arithmetically sound, but its poverty-line method is **not valid** for converting the World Bank's $8.30-per-person-per-day line in 2021 PPP into Iranian rials.

The decisive error is conceptual: column C is an older vintage of WDI **GDP PPP**, indicator `PA.NUS.PPP`, and every result is `GDP PPP × 8.30 × 30`. World Bank global-poverty measurement instead puts welfare into 2021 local prices with a CPI and applies an **individual/household-consumption PPP**. For Iran, PIP's exact 2021 benchmark is **48,021.04296875 Iranian rials per 2021 international dollar**, equal to WDI `PA.NUS.PRVT.PP` in 2021. PIP then supplies a country- and survey-specific CPI factor. [PIP conversion methodology](https://datanalytics.worldbank.org/PIP-Methodology/convert.html), [PIP Iran query](https://api.worldbank.org/pip/v1/pip?country=IRN&year=all&povline=8.3&fill_gaps=false&ppp_version=2021), [WDI household-consumption PPP](https://api.worldbank.org/v2/country/IRN/indicator/PA.NUS.PRVT.PP?format=json&per_page=100).

For this paper's HIES average-month expenditure aggregate, the recommended formula is:

```text
nominal monthly line_t
  = 8.30 2021 international dollars/person/day
  × 48,021.04296875 IRR/2021 international dollar
  × PIP survey CPI factor_t
  × 365/12 days/average month
```

This yields **6,832,159; 9,325,957; 13,075,663; 19,264,808; and 27,105,671 rials/month for 1398–1402**. The analogous **1403 value is 35,915,014 rials/month, but is provisional** because PIP currently has no Iran 2024 survey-CPI observation; it extrapolates PIP's 1402 factor by the Statistical Centre of Iran's reported 32.5% annual-average inflation for 1403.

## 2. Workbook method and forensic inspection

- The file has one visible worksheet, `Sheet1`, used range `A1:G35`. There are no hidden or very hidden sheets, hidden rows or columns, defined names, comments, notes, hyperlinks, external links, connections, tables, pivots, charts, filters, validations, conditional formatting, merged cells, or protection.
- `F1:F35` contains Iranian years 1369–1403. The file never records the corresponding Gregorian dates; its values imply the shortcut `Gregorian year = Iranian year + 621`.
- `C1:C35` contains hard-coded inputs labeled `PPP_GDP=`. No cell gives a URL, indicator code, vintage, unit, currency, CPI, or nominal/real-price note.
- `G1` is `=C1*8.3*30`; `G2:G35` is a shared relative formula equivalent to `=C[row]*8.3*30`. Independent IEEE-754 recomputation matches all 35 cached results exactly. There are **no arithmetic errors**.
- Column G is formatted to display zero decimals, but the formulas do not round. The current Stata literals are truncations of the cached values, not always the displayed Excel integers: 1399, 1400, 1401, and 1403 are each one rial below Excel's display.
- The workbook still has the same hash, size (11,301 bytes), and modification timestamp after this audit; it was not changed.

### Inferred source series

The label and values identify column C as a prior vintage of WDI `PA.NUS.PPP`, **PPP conversion factor, GDP (LCU per international dollar)**. Values for 2011–2021 match the current series at stored precision; early differences are microscopic revisions. The last three workbook values are stale relative to the current API:

| Implied Gregorian year | Workbook GDP PPP | Current WDI `PA.NUS.PPP` | Difference |
|---:|---:|---:|---:|
| 2022 | 70,968.082972096905 | 71,211.4312451727 | +0.343% |
| 2023 | 89,391.812935857699 | 94,280.2670719049 | +5.469% |
| 2024 | 117,170.156249744 | 118,096.561683588 | +0.791% |

The match establishes the source family, but the workbook itself does not establish its download date or exact WDI vintage. Updating the GDP series would not fix the methodological error. [Current WDI GDP PPP data](https://api.worldbank.org/v2/country/IRN/indicator/PA.NUS.PPP?format=json&per_page=100).

## 3. Methodological assessment

### Threshold and PPP concept

The World Bank raised the upper-middle-income international poverty line from $6.85 in 2017 PPP to **$8.30 in 2021 PPP** in June 2025. It is a daily, per-person global comparison line, not an official Iranian national poverty line. [World Bank June 2025 factsheet](https://www.worldbank.org/en/news/factsheet/2025/06/05/june-2025-update-to-global-poverty-lines), [PIP dictionary](https://api.worldbank.org/pip/v1/aux?table=dictionary&ppp_version=2021).

PIP's documented order is: (1) use a CPI to place local welfare in the ICP reference-year prices; then (2) use the 2021 consumption PPP to express it in 2021 international dollars. PIP states that global poverty uses consumption PPPs; GDP PPP includes government consumption, investment, and other GDP components and is not interchangeable with a household-welfare PPP. Market exchange rates are also unsuitable for this conversion. [PIP methodology, Chapter 3](https://datanalytics.worldbank.org/PIP-Methodology/convert.html), [ICP 2021 concepts](https://www.worldbank.org/en/programs/icp/brief/ICP2021_Concepts_definitions), [ICP 2021 methodology](https://www.worldbank.org/en/programs/icp/brief/ICP2021_Methodology_PPP).

The annual WDI household-consumption PPP series has the right expenditure concept, but its nonbenchmark-year observations are calendar-year national-accounts extrapolations and are not a drop-in substitute for PIP's survey-specific CPI conversion. WDI extrapolates consumption PPPs using domestic and United States inflation; directly multiplying a fixed 2021-international-dollar line by a later year's current-international-dollar PPP changes the time basis. [WDI PPP extrapolation note](https://datahelpdesk.worldbank.org/knowledgebase/articles/665452-how-do-you-extrapolate-the-ppp-conversion-factors).

### Inflation, calendar, and nominal prices

For 1398–1402, PIP maps Iran's HIES records to reporting years `2019.23` through `2023.23` and survey periods `2019-2020` through `2023-2024`. These are survey-year factors, not calendar-year assignments. The corrected lines are nominal rials for each HIES period; the CPI factor moves the fixed 2021-price benchmark to that survey period. [PIP survey means](https://api.worldbank.org/pip/v1/aux?table=survey_means&ppp_version=2021&format=csv), [PIP CPI factors](https://api.worldbank.org/pip/v1/aux?table=cpi&ppp_version=2021&format=csv).

Where PIP has no Iran survey observation in the older 1369–1403 workbook range, Appendix A supplies a fully documented WDI calendar-CPI proxy and labels it as such. It uses the starting Gregorian calendar year (`Iranian year + 621`) only as an explicit sensitivity convention; it is not presented as an exact Solar Hijri-year conversion. [WDI `FP.CPI.TOTL`](https://api.worldbank.org/v2/country/IRN/indicator/FP.CPI.TOTL?format=json&per_page=100).

### Rial/toman and daily/monthly units

The PPP unit is local currency per international dollar; Iran's local-currency observations here are Iranian rials. There is no market-exchange-rate step and no unexplained factor of ten. If a manuscript table is displayed in tomans, the final rial line may be divided by ten solely as a display conversion.

The workbook's 30-day month is a convention, not an arithmetic mistake. It is unsuitable for this paper's welfare aggregate because the HIES preparation treats monthly expenditure as one-twelfth of annual expenditure. Therefore `365/12 = 30.416666...` days is internally consistent. A fixed 30-day convention produces values 1.369863% below the recommendation; PIP's separate 30.5-day harmonization convention would be 0.274% above it. These are timing differences, not PPP differences. [World Bank PIP harmonization technical note](https://openknowledge.worldbank.org/server/api/core/bitstreams/74465bb0-25f0-49aa-ad35-a2c760688b04/content).

## 4. Verification table: paper years

`Authoritative input` reports `PIP survey CPI factor; effective IRR per 2021 international dollar`. Corrected lines use 365/12 and are rounded to the nearest rial only at the end. Differences in this table are against the unrounded workbook result.

| Iranian year | Gregorian period | Workbook input | Workbook poverty line (IRR) | Authoritative input | Corrected poverty line (IRR) | Rial difference | Percentage difference | Status |
|---:|---|---:|---:|---:|---:|---:|---:|---|
| 1398 | 2019-03-21–2020-03-19; PIP 2019.23 | 23,549.041015625 | 5,863,711.213 | 0.5635554534167597; 27,062.520644 | 6,832,159 | +968,448 | +16.516% | Replace; PIP survey factor published |
| 1399 | 2020-03-20–2021-03-20; PIP 2020.23 | 32,954.5859375 | 8,205,691.898 | 0.7692581263071904; 36,940.577537 | 9,325,957 | +1,120,265 | +13.652% | Replace; PIP survey factor published |
| 1400 | 2021-03-21–2022-03-20; PIP 2021.23 | 50,488.171875 | 12,571,554.797 | 1.0785553259633645; 51,793.351652 | 13,075,663 | +504,108 | +4.010% | Replace; PIP survey factor published |
| 1401 | 2022-03-21–2023-03-20; PIP 2022.23 | 70,968.082972096905 | 17,671,052.660 | 1.589071344376989; 76,308.863309 | 19,264,808 | +1,593,756 | +9.019% | Replace; PIP survey factor published |
| 1402 | 2023-03-21–2024-03-19; PIP 2023.23 | 89,391.812935857699 | 22,258,561.421 | 2.2358304187730877; 107,366.908611 | 27,105,671 | +4,847,109 | +21.776% | Replace; PIP survey factor published |
| 1403 | 2024-03-20–2025-03-20; no PIP record | 117,170.156249744 | 29,175,368.906 | 2.9624753048743412025; 142,261.153909 | 35,915,014 | +6,739,645 | +23.100% | Replace provisionally; SCI extrapolation |

## 5. Recommended values and repository reconciliation

### Values ready for Stata and the manuscript

| Iranian year | Recommended IRR/month | Current Stata literal | Difference from current (IRR) | Difference from current | 30-day alternative |
|---:|---:|---:|---:|---:|---:|
| 1398 | **6,832,159** | 5,863,711 | +968,448 | +16.516% | 6,738,568 |
| 1399 | **9,325,957** | 8,205,691 | +1,120,266 | +13.652% | 9,198,204 |
| 1400 | **13,075,663** | 12,571,554 | +504,109 | +4.010% | 12,896,545 |
| 1401 | **19,264,808** | 17,671,052 | +1,593,756 | +9.019% | 19,000,907 |
| 1402 | **27,105,671** | 22,258,561 | +4,847,110 | +21.776% | 26,734,360 |
| 1403 | **35,915,014 (provisional)** | 29,175,368 | +6,739,646 | +23.100% | 35,423,027 |

```stata
local pl_98    6832159
local pl_99    9325957
local pl_1400  13075663
local pl_1401  19264808
local pl_1402  27105671
local pl_1403  35915014   // provisional pending PIP Iran 2024 CPI
```

When regenerated, the threshold and log-threshold variables should be created as `double`, not Stata's default `float`, to prevent large integer thresholds from being silently quantized. The current prepared `.dta` files store these generated threshold variables as float32; for example, the literal 22,258,561 is represented as 22,258,560.

The six existing literals occur in `codes_v2/data_prepration_v2.do` and `codes_v2/preparation_diff_hh_v2.do` and flow into 30 year-pair/subgroup scripts. The manuscript is not synchronized: `paper_text/thesis.tex` still contains references to $6.85/2017 PPP and older 1398–1399 national-line figures of 9,060,000 and 12,540,000 rials, while the compiled PDF is stale. Replacing constants therefore requires rerunning preparation, all dependent parametric scripts, results tables, and the manuscript build; this audit intentionally did not modify them.

### Defensible alternatives, kept distinct

- **Recommended for this paper:** PIP survey CPI × 2021 household-consumption PPP × 365/12.
- **Fixed 30-day month:** same PPP/CPI method, 1.369863% lower; use only if welfare is explicitly standardized to 30 days.
- **PIP 30.5-day harmonization:** same PPP/CPI method, 0.274% above the recommendation; it does not match this project's annual/12 construction.
- **WDI calendar-CPI proxy:** primary-source fallback when PIP has no survey record; it explicitly maps each Solar Hijri label to its starting Gregorian calendar year. For 1398–1403 it gives 6,474,135; 8,454,840; 12,123,312; 17,395,555; 25,150,352; and 33,313,117 rials/month. It is not survey aligned.
- **Direct annual WDI `PA.NUS.PRVT.PP` × $8.30 × 365/12:** has the right consumption concept but a different current-international-dollar/calendar-year time basis; it gives 6,053,919; 8,147,390; 12,123,312; 16,106,578; 22,366,095; and 28,776,437. Do not silently substitute it for PIP's survey conversion.
- **GDP PPP or market exchange rate:** not defensible for this poverty-line conversion.

## 6. Full 35-row verification

For every workbook year, the table below reports the best documented input available under the hierarchy: published PIP survey factor; for 1403, provisional SCI extrapolation; otherwise, an explicitly labeled WDI calendar-year CPI proxy. `Authoritative factor` is the resulting nominal IRR per 2021 international dollar. Differences are from the unrounded workbook result. Full input precision is retained in the accompanying CSV.

| Iranian year | Gregorian span; proxy year | Workbook GDP input | Workbook line | Authoritative factor | Reconstructed line | Rial difference | Percent difference | Status |
|---:|---|---:|---:|---:|---:|---:|---:|---|
| 1369 | 1990–91; 1990 | 96.673922 | 24,072 | 140.024245 | 35,350 | +11,278 | +46.853% | PIP survey |
| 1370 | 1991–92; 1991 | 117.466495 | 29,249 | 162.155444 | 40,937 | +11,688 | +39.961% | WDI calendar proxy |
| 1371 | 1992–93; 1992 | 148.547777 | 36,988 | 204.004072 | 51,503 | +14,514 | +39.240% | WDI calendar proxy |
| 1372 | 1993–94; 1993 | 217.512630 | 54,161 | 247.258302 | 62,422 | +8,262 | +15.254% | WDI calendar proxy |
| 1373 | 1994–95; 1994 | 285.227721 | 71,022 | 328.727620 | 82,990 | +11,968 | +16.852% | PIP survey |
| 1374 | 1995–96; 1995 | 385.356252 | 95,954 | 486.402442 | 122,796 | +26,843 | +27.975% | WDI calendar proxy |
| 1375 | 1996–97; 1996 | 487.542749 | 121,398 | 627.154390 | 158,330 | +36,932 | +30.422% | WDI calendar proxy |
| 1376 | 1997–98; 1997 | 553.700531 | 137,871 | 735.960821 | 185,799 | +47,928 | +34.763% | WDI calendar proxy |
| 1377 | 1998–99; 1998 | 598.915041 | 149,130 | 877.360924 | 221,497 | +72,367 | +48.526% | PIP survey |
| 1378 | 1999–2000; 1999 | 777.811314 | 193,675 | 1,041.551636 | 262,948 | +69,273 | +35.768% | WDI calendar proxy |
| 1379 | 2000–01; 2000 | 950.190258 | 236,597 | 1,192.334477 | 301,015 | +64,417 | +27.227% | WDI calendar proxy |
| 1380 | 2001–02; 2001 | 1,066.847803 | 265,645 | 1,326.761212 | 334,952 | +69,307 | +26.090% | WDI calendar proxy |
| 1381 | 2002–03; 2002 | 1,347.607351 | 335,554 | 1,516.964821 | 382,970 | +47,416 | +14.131% | WDI calendar proxy |
| 1382 | 2003–04; 2003 | 1,495.116074 | 372,284 | 1,766.778764 | 446,038 | +73,754 | +19.811% | WDI calendar proxy |
| 1383 | 2004–05; 2004 | 1,815.707026 | 452,111 | 2,027.581964 | 511,880 | +59,769 | +13.220% | WDI calendar proxy |
| 1384 | 2005–06; 2005 | 2,115.534365 | 526,768 | 2,352.932391 | 594,017 | +67,249 | +12.766% | PIP survey |
| 1385 | 2006–07; 2006 | 2,351.517181 | 585,528 | 2,631.229970 | 664,276 | +78,748 | +13.449% | PIP survey |
| 1386 | 2007–08; 2007 | 2,814.676293 | 700,854 | 2,969.092126 | 749,572 | +48,718 | +6.951% | WDI calendar proxy |
| 1387 | 2008–09; 2008 | 3,297.803092 | 821,153 | 3,723.553549 | 940,042 | +118,889 | +14.478% | WDI calendar proxy |
| 1388 | 2009–10; 2009 | 3,428.307983 | 853,649 | 4,326.269610 | 1,092,203 | +238,554 | +27.945% | PIP survey |
| 1389 | 2010–11; 2010 | 3,925.111954 | 977,353 | 4,654.746646 | 1,175,130 | +197,777 | +20.236% | WDI calendar proxy |
| 1390 | 2011–12; 2011 | 4,758.869629 | 1,184,959 | 6,252.893177 | 1,578,595 | +393,636 | +33.219% | PIP survey |
| 1391 | 2012–13; 2012 | 6,093.562500 | 1,517,297 | 8,094.426856 | 2,043,506 | +526,208 | +34.681% | PIP survey |
| 1392 | 2013–14; 2013 | 8,503.846680 | 2,117,458 | 10,750.568272 | 2,714,071 | +596,613 | +28.176% | PIP survey |
| 1393 | 2014–15; 2014 | 9,758.553711 | 2,429,880 | 12,318.004364 | 3,109,783 | +679,903 | +27.981% | PIP survey |
| 1394 | 2015–16; 2015 | 10,701.561523 | 2,664,689 | 13,687.748502 | 3,455,586 | +790,897 | +29.681% | PIP survey |
| 1395 | 2016–17; 2016 | 11,796.810547 | 2,937,406 | 14,626.070029 | 3,692,473 | +755,067 | +25.705% | PIP survey |
| 1396 | 2017–18; 2017 | 13,061.294922 | 3,252,262 | 15,830.885352 | 3,996,639 | +744,376 | +22.888% | PIP survey |
| 1397 | 2018–19; 2018 | 16,923.199219 | 4,213,877 | 20,081.511126 | 5,069,745 | +855,868 | +20.311% | PIP survey |
| 1398 | 2019–20; 2019.23 | 23,549.041016 | 5,863,711 | 27,062.520644 | 6,832,159 | +968,448 | +16.516% | PIP survey |
| 1399 | 2020–21; 2020.23 | 32,954.585938 | 8,205,692 | 36,940.577537 | 9,325,957 | +1,120,265 | +13.652% | PIP survey |
| 1400 | 2021–22; 2021.23 | 50,488.171875 | 12,571,555 | 51,793.351652 | 13,075,663 | +504,108 | +4.010% | PIP survey |
| 1401 | 2022–23; 2022.23 | 70,968.082972 | 17,671,053 | 76,308.863309 | 19,264,808 | +1,593,756 | +9.019% | PIP survey |
| 1402 | 2023–24; 2023.23 | 89,391.812936 | 22,258,561 | 107,366.908611 | 27,105,671 | +4,847,109 | +21.776% | PIP survey |
| 1403 | 2024–25; no PIP record | 117,170.156250 | 29,175,369 | 142,261.153909 | 35,915,014 | +6,739,645 | +23.100% | Provisional SCI extrapolation |

## 7. Sources and reproducibility

All external sources below were accessed **2026-07-11**.

| Input | Exact series/indicator | Code | Year/value used | Unit | Direct source |
|---|---|---|---|---|---|
| International line | Upper-middle-income international poverty line | — | 2021 PPP; $8.30 | 2021 international dollars/person/day | [World Bank factsheet](https://www.worldbank.org/en/news/factsheet/2025/06/05/june-2025-update-to-global-poverty-lines) |
| Poverty PPP | PIP national PPP; WDI **PPP conversion factor, households and NPISHs Final consumption expenditure (LCU per international $)** | `PA.NUS.PRVT.PP` | Iran 2021: 48,021.04296875 | IRR per 2021 international dollar | [PIP PPP CSV](https://api.worldbank.org/pip/v1/aux?table=ppp&ppp_version=2021&format=csv), [WDI API](https://api.worldbank.org/v2/country/IRN/indicator/PA.NUS.PRVT.PP?format=json&per_page=100) |
| Survey CPI factors | PIP national CPI conversion factors | `cpi` | 2019: 0.5635554534167597; 2020: 0.7692581263071904; 2021: 1.0785553259633645; 2022: 1.589071344376989; 2023: 2.2358304187730877 | Ratio putting each HIES survey period on the 2021 PIP price basis | [PIP CPI CSV](https://api.worldbank.org/pip/v1/aux?table=cpi&ppp_version=2021&format=csv) |
| Survey mapping | PIP Iran survey metadata and means | — | 2019.23–2023.23; survey periods 2019-2020–2023-2024 | Survey reporting year/period | [PIP survey means CSV](https://api.worldbank.org/pip/v1/aux?table=survey_means&ppp_version=2021&format=csv) |
| Workbook match | PPP conversion factor, GDP | `PA.NUS.PPP` | Current 2019–2024 values documented above | LCU per international dollar | [WDI GDP PPP](https://api.worldbank.org/v2/country/IRN/indicator/PA.NUS.PPP?format=json&per_page=100) |
| Full-range fallback CPI | Consumer price index (2010 = 100) | `FP.CPI.TOTL` | Iran 1990–2024; exact values in CSV | Index, 2010 = 100 | [WDI CPI](https://api.worldbank.org/v2/country/IRN/indicator/FP.CPI.TOTL?format=json&per_page=100) |
| 1403 extrapolation | Consumer Price Index — Esfand 1403 (1400 = 100), annual-average inflation | — | 1403: 32.5% | Percent change in 12-month average over prior 12-month average | SCI release indexed at [Khabar Farsi](https://khabarfarsi.com/u/210006428); corroborating [Tasnim report](https://www.tasnimnews.com/fa/news/1404/01/01/3278999/%D9%86%D8%B1%D8%AE-%D8%AA%D9%88%D8%B1%D9%85-%D8%B3%D8%A7%D9%84%D8%A7%D9%86%D9%87-1403-%D8%A7%D8%B9%D9%84%D8%A7%D9%85-%D8%B4%D8%AF) |

The PIP vintage queried was `20260324_2021_01_02_PROD`; its [citation endpoint](https://api.worldbank.org/pip/v1/citation?version=20260324_2021_01_02_PROD) should accompany published estimates.

Independent reproduction files:

- `reproduce_gdp_ppp90_403_audit.py`: parses the original XLSX directly from Open XML, verifies all 35 formulas, and recalculates with Python `Decimal` precision.
- `GDP_PPP90_403_recommended_1398_1403.csv`: exact PIP inputs, 30-day and 365/12 outputs, and differences from workbook and Stata.
- `GDP_PPP90_403_all_35_rows_verification.csv`: exact full-range WDI/PIP inputs and all unrounded results.

Calculations retain all published digits. Presentation uses `ROUND_HALF_UP` to the nearest rial only after multiplication. Workbook values are retained as the stored Excel doubles for comparisons.

## 8. Uncertainties and stop conditions

1. **1403 is not uniquely determined by PIP today.** PIP publishes no Iran 2024 survey CPI. The 35,915,014-rial recommendation is the PIP-consistent survey-year extrapolation using SCI's 32.5% annual-average inflation. The SCI portal's original page was not retrievable during the audit; only the indexed primary-source title and contemporaneous reports were accessible. The 32.5% value is also rounded to 0.1 percentage point, implying roughly ±13,600 rials of rounding uncertainty. Until PIP publishes an Iran 2024 factor, label this line provisional. A primary-source-only calendar-year WDI alternative is 33,313,117 rials.
2. **Older workbook years without PIP observations are not unique Solar Hijri-year lines.** Appendix A's WDI results are explicit calendar-year proxies, not claims about exact HIES survey timing. A researcher using those historical years should obtain the actual survey dates and construct survey-weighted CPI factors before treating them as final.
3. **No workbook provenance exists.** The GDP-PPP series family is established by the value match, but the exact download vintage for 2022–2024 cannot be recovered from the file.
4. **Changing the line changes the empirical results.** None of the Stata estimates or manuscript tables has been regenerated in this audit. The recommended constants should not be inserted into prose without rerunning every dependent result.
