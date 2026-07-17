"""Reproduce the read-only audit of GDP_PPP90_403.xlsx.

All external observations are pinned exactly as returned by the cited World Bank
APIs on 2026-07-11.  Decimal arithmetic is used throughout; rounding occurs only
in the presentation columns and uses ROUND_HALF_UP (nearest rial).
"""

from __future__ import annotations

import csv
from decimal import Decimal, ROUND_HALF_UP, getcontext
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET


getcontext().prec = 50

SOURCE_WORKBOOK = Path(r"E:\my_papers\GDP_PPP90_403.xlsx")
OUT_DIR = Path(__file__).resolve().parent
ACCESS_DATE = "2026-07-11"

POVERTY_LINE = Decimal("8.30")  # 2021 international dollars per person per day
PIP_CONSUMPTION_PPP_2021 = Decimal("48021.04296875")  # IRR per 2021 int$
DAYS_PER_AVERAGE_MONTH = Decimal(365) / Decimal(12)
DAYS_PER_30_DAY_MONTH = Decimal(30)

WDI_CPI_2010_100 = {
    1990: "2.97421701244274", 1991: "3.48365779420319",
    1992: "4.38271053462994", 1993: "5.31196046633819",
    1994: "6.98241418404714", 1995: "10.4496007830059",
    1996: "13.4734377099679", 1997: "15.8109748350774",
    1998: "18.6357848195023", 1999: "22.3761187395983",
    2000: "25.615453804342", 2001: "28.5034033705372",
    2002: "32.5896323907668", 2003: "37.9564968412533",
    2004: "43.559448423577", 2005: "49.4108405341712",
    2006: "54.3597800471328", 2007: "63.7863315003927",
    2008: "79.9947630269704", 2009: "90.8352971982194",
    2010: "100", 2011: "126.293385673861",
    2012: "160.716937290151", 2013: "219.54421493168",
    2014: "256.002941860307", 2015: "287.964093938751",
    2016: "308.828317801683", 2017: "333.673322422363",
    2018: "393.781629583152", 2019: "550.929425291206",
    2020: "719.481539670071", 2021: "1031.65750196386",
    2022: "1480.30950510605", 2023: "2140.21942916994",
    2024: "2834.84629484158",
}
WDI_CPI_2010_100 = {year: Decimal(value) for year, value in WDI_CPI_2010_100.items()}

# PIP's Iran survey-specific CPI conversion factors. Blank PIP years are omitted.
PIP_SURVEY_CPI = {
    1990: "0.002915893456382291", 1994: "0.0068454910445837095",
    1998: "0.018270342962262306", 2005: "0.04899794435656232",
    2006: "0.05479326993844068", 2009: "0.09009112137036779",
    2011: "0.1302115237433239", 2012: "0.16855999695097518",
    2013: "0.22387202792444236", 2014: "0.2565126370097023",
    2015: "0.2850364685186866", 2016: "0.30457626750977546",
    2017: "0.3296655876976866", 2018: "0.41818148637524716",
    2019: "0.5635554534167597", 2020: "0.7692581263071904",
    2021: "1.0785553259633645", 2022: "1.589071344376989",
    2023: "2.2358304187730877",
}
PIP_SURVEY_CPI = {year: Decimal(value) for year, value in PIP_SURVEY_CPI.items()}

# The paper's six current Stata literals.
CURRENT_STATA = {
    1398: 5_863_711, 1399: 8_205_691, 1400: 12_571_554,
    1401: 17_671_052, 1402: 22_258_561, 1403: 29_175_368,
}


def q0(value: Decimal) -> int:
    """Round once, at final presentation, to the nearest rial."""
    return int(value.quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def parse_workbook() -> list[dict[str, str]]:
    """Read the source XLSX directly from Open XML without changing it."""
    ns = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    with ZipFile(SOURCE_WORKBOOK) as archive:
        strings_root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
        shared_strings = [
            "".join(node.text or "" for node in si.findall(".//m:t", ns))
            for si in strings_root.findall("m:si", ns)
        ]
        sheet = ET.fromstring(archive.read("xl/worksheets/sheet1.xml"))

    cells: dict[str, dict[str, str]] = {}
    for cell in sheet.findall(".//m:c", ns):
        ref = cell.attrib["r"]
        value_node = cell.find("m:v", ns)
        value = "" if value_node is None else (value_node.text or "")
        if cell.attrib.get("t") == "s" and value:
            value = shared_strings[int(value)]
        formula_node = cell.find("m:f", ns)
        cells[ref] = {
            "value": value,
            "formula": "" if formula_node is None else (formula_node.text or ""),
            "formula_type": "" if formula_node is None else formula_node.attrib.get("t", ""),
            "formula_ref": "" if formula_node is None else formula_node.attrib.get("ref", ""),
        }

    records = []
    for row in range(1, 36):
        c = Decimal(cells[f"C{row}"]["value"])
        g = Decimal(cells[f"G{row}"]["value"])
        # Excel stores and evaluates these cells as IEEE-754 binary doubles.
        # Comparing Python floats therefore reproduces the cached Excel result;
        # an exact base-10 Decimal product can differ in its final sub-rial digits.
        expected_excel = float(c) * 8.3 * 30
        assert float(g) == expected_excel, (
            f"Arithmetic mismatch in G{row}: {float(g)} != {expected_excel}"
        )
        records.append({
            "row": str(row),
            "iranian_year": cells[f"F{row}"]["value"],
            "workbook_input": cells[f"C{row}"]["value"],
            "workbook_line_exact": cells[f"G{row}"]["value"],
            "formula": "=C1*8.3*30" if row == 1 else f"=C{row}*8.3*30",
        })
    assert cells["G2"]["formula_type"] == "shared"
    assert cells["G2"]["formula_ref"] == "G2:G35"
    return records


def calendar_reconstruction(records: list[dict[str, str]]) -> list[dict[str, str]]:
    """Audit all 35 rows and provide the best documented replacement available.

    Published PIP survey factors are preferred.  Where PIP has no Iran survey
    factor, the complete current WDI calendar-year CPI series is used as an
    explicitly labeled +621-year proxy.  The final 1403 row instead uses the
    survey-year SCI inflation extrapolation documented in the report.
    """
    base_cpi = WDI_CPI_2010_100[2021]
    output = []
    for record in records:
        iranian_year = int(record["iranian_year"])
        gregorian_year = iranian_year + 621
        calendar_cpi_ratio = WDI_CPI_2010_100[gregorian_year] / base_cpi
        calendar_effective_factor = PIP_CONSUMPTION_PPP_2021 * calendar_cpi_ratio
        calendar_line = calendar_effective_factor * POVERTY_LINE * DAYS_PER_AVERAGE_MONTH

        if gregorian_year in PIP_SURVEY_CPI:
            selected_cpi_factor = PIP_SURVEY_CPI[gregorian_year]
            source_status = "PIP survey-specific CPI factor"
        elif gregorian_year == 2024:
            selected_cpi_factor = PIP_SURVEY_CPI[2023] * Decimal("1.325")
            source_status = "provisional SCI 1403 annual-average inflation extrapolation"
        else:
            selected_cpi_factor = calendar_cpi_ratio
            source_status = "WDI calendar-year CPI proxy; PIP survey factor unavailable"

        selected_effective_factor = PIP_CONSUMPTION_PPP_2021 * selected_cpi_factor
        selected_line = selected_effective_factor * POVERTY_LINE * DAYS_PER_AVERAGE_MONTH
        workbook_line = Decimal(record["workbook_line_exact"])
        diff = selected_line - workbook_line
        pct = diff / workbook_line * Decimal(100)
        output.append({
            "workbook_row": record["row"],
            "iranian_year": str(iranian_year),
            "gregorian_calendar_year_proxy": str(gregorian_year),
            "workbook_GDP_PPP_input_IRR_per_intl_dollar": record["workbook_input"],
            "workbook_line_IRR_exact_30_day": record["workbook_line_exact"],
            "WDI_CPI_FP_CPI_TOTL_2010_100": str(WDI_CPI_2010_100[gregorian_year]),
            "WDI_calendar_CPI_ratio_to_2021": str(calendar_cpi_ratio),
            "WDI_calendar_effective_factor_IRR_per_2021_intl_dollar": str(calendar_effective_factor),
            "WDI_calendar_line_IRR_nearest_365_over_12": str(q0(calendar_line)),
            "selected_CPI_factor": str(selected_cpi_factor),
            "selected_effective_factor_IRR_per_2021_intl_dollar": str(selected_effective_factor),
            "corrected_line_IRR_exact_365_over_12": str(selected_line),
            "corrected_line_IRR_nearest": str(q0(selected_line)),
            "difference_from_workbook_IRR_exact": str(diff),
            "difference_from_workbook_percent": str(pct),
            "status": source_status,
        })
    return output


def paper_recommendations(records: list[dict[str, str]]) -> list[dict[str, str]]:
    """Preferred HIES conversion for 1398-1403 using PIP survey alignment.

    PIP currently has no 2024 Iran survey CPI.  The 1403 factor is explicitly
    provisional: PIP's 1402 factor times 1.325 (SCI's reported annual-average
    inflation for Iranian year 1403).
    """
    by_iranian_year = {int(row["iranian_year"]): row for row in records}
    output = []
    for iranian_year in range(1398, 1404):
        gregorian_start = iranian_year + 621
        if iranian_year <= 1402:
            cpi_factor = PIP_SURVEY_CPI[gregorian_start]
            input_status = "PIP survey-specific CPI factor"
        else:
            cpi_factor = PIP_SURVEY_CPI[2023] * Decimal("1.325")
            input_status = "provisional: PIP 1402 factor x SCI 1403 annual inflation 1.325"

        effective_factor = PIP_CONSUMPTION_PPP_2021 * cpi_factor
        line_30 = effective_factor * POVERTY_LINE * DAYS_PER_30_DAY_MONTH
        line_average_month = effective_factor * POVERTY_LINE * DAYS_PER_AVERAGE_MONTH
        workbook_line = Decimal(by_iranian_year[iranian_year]["workbook_line_exact"])
        stata = Decimal(CURRENT_STATA[iranian_year])
        output.append({
            "iranian_year": str(iranian_year),
            "PIP_survey_period": f"{gregorian_start}-{gregorian_start + 1}",
            "workbook_input_GDP_PPP": by_iranian_year[iranian_year]["workbook_input"],
            "workbook_line_IRR_exact": str(workbook_line),
            "PIP_consumption_PPP_2021": str(PIP_CONSUMPTION_PPP_2021),
            "survey_CPI_factor": str(cpi_factor),
            "authoritative_effective_factor_IRR_per_2021_intl_dollar": str(effective_factor),
            "line_IRR_exact_30_day": str(line_30),
            "line_IRR_nearest_30_day": str(q0(line_30)),
            "recommended_line_IRR_exact_365_over_12": str(line_average_month),
            "recommended_line_IRR_nearest": str(q0(line_average_month)),
            "difference_from_workbook_IRR_exact": str(line_average_month - workbook_line),
            "difference_from_workbook_percent": str((line_average_month / workbook_line - 1) * 100),
            "current_Stata_literal_IRR": str(CURRENT_STATA[iranian_year]),
            "difference_from_Stata_IRR_nearest": str(q0(line_average_month) - CURRENT_STATA[iranian_year]),
            "difference_from_Stata_percent": str((line_average_month / stata - 1) * 100),
            "input_status": input_status,
        })
    return output


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    records = parse_workbook()
    calendar_rows = calendar_reconstruction(records)
    recommended_rows = paper_recommendations(records)
    write_csv(OUT_DIR / "GDP_PPP90_403_all_35_rows_verification.csv", calendar_rows)
    write_csv(OUT_DIR / "GDP_PPP90_403_recommended_1398_1403.csv", recommended_rows)
    print(f"Verified {len(records)} workbook formulas exactly.")
    print(f"Wrote {len(calendar_rows)} all-row verification records.")
    print(f"Wrote {len(recommended_rows)} paper recommendations.")
    print("Recommended nearest-rial values:")
    for row in recommended_rows:
        print(row["iranian_year"], row["recommended_line_IRR_nearest"])


if __name__ == "__main__":
    main()
