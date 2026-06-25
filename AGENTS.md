# AGENTS.md

## Project Overview

This repository supports a paper titled `Poverty Dynamics in Iran: Substitutes for Missing Data`.
The empirical core is an adaptation of Dang, Lanjouw, Luoto, and McKenzie (2014), "Using repeated cross-sections to explore movements into and out of poverty", to Iranian HIES household expenditure data.

The paper estimates chronic and transient poverty using synthetic panels when true panel data are unavailable or limited. The main welfare variable is log monthly per-capita household consumption/expenditure (`lcpc_*`). The code estimates lower and upper bounds for poverty transition matrices, compares them with available "truth" or simulated truth, and repeats the exercise for key subgroups.

## Repository Layout

- `paper_text/`: tracked working manuscript assets.
  - `thesis.tex`: main LaTeX manuscript.
  - `myref.bib`: bibliography.
  - `chicago-fa.bst`: local bibliography style used at the end of the manuscript.
  - `Poverty_Dynamics_in_Iran.pdf`: current compiled manuscript.
  - `Figures/GL Pop.pdf`: figure included in the introduction.
- `codes_v2/`: current preparation workflow for years 1398-1399 through 1402-1403.
  - `data_prepration_v2.do`: creates year-pair datasets and logs poverty lines.
  - `preparation_diff_hh_v2.do`: creates subgroup datasets.
- `docs/`: project decision notes and methodological handoffs.
  - `residual_plot_decisions.md`: decisions for the 1398-1399 all-household residual normality figure.
- `1399-1400/`, `1400-1401/`, `1401-1402/`, `1402-1403/`: templated parametric scripts for each year pair and subgroup.
- Root `parametric*.do`: current 1398-1399 scripts, including subgroup versions.
- `88-89/` and `89-90/`: older historical scripts/results. Many paths still point to `D:\Ahmad\...`; port before rerunning.
- `figures/`: figure scripts and generated image files. `figures/idn_figure 1.do` is adapted from Dang et al.'s Indonesia figure workflow.
  - `residuals_9899_normality.do`: standalone robustness script for all-household 1398 and 1399 OLS residual histograms with fitted normal densities.
- `irheis_weights/`: HIES weight files. Treat these as source inputs; do not modify casually.
- `poverty_line_data/`: generated `.dta` intermediates and logs. This directory is ignored by git via `.gitignore`.

## External Reference Materials

The base article is outside the repo:

- `E:\my_papers\shared_resources\Literature\Dang et al 2014.pdf`

Its replication package is also outside the repo:

- `E:\my_papers\shared_resources\dang et al 2014 replication files`
- Key Stata references are in `...\do_files\`, especially:
  - `idn_table 1.do`
  - `idn_tables 2&4.do`
  - `idn_figure 1.do`
  - `vnm_tables 2&4.do`
  - `vnm_figures 2 to 5.do`

Use these as read-only methodological references unless the user explicitly asks to edit shared resources.

## Method Notes

The paper follows the DLLM synthetic panel logic:

1. Estimate consumption models separately in two rounds.
2. Use only time-invariant, deterministic, or plausibly recallable covariates when cross-predicting.
3. Predict unobserved first-round consumption for households observed in the second round.
4. Estimate poverty transition cells:
   - poor in both years (chronic poverty)
   - poor then nonpoor (exit)
   - nonpoor then poor (entry)
   - nonpoor in both years
5. Produce nonparametric bounds using bootstrapped residual draws.
6. Produce parametric bounds using bivariate normal residual assumptions and a grid for `rho`.
7. Validate against available true panel transitions or the script's simulated truth column.

Important assumptions from Dang et al.:

- The underlying sampled population is comparable across survey rounds.
- Residuals are positive quadrant dependent, so the error correlation is nonnegative.
- Household-head ages should usually be restricted to stable household-forming ages.
- Richer prediction models narrow bounds; omitted retrospective/asset variables can widen them.
- Parametric bounds are tighter but depend on the assumed `rho` range.

## Year and Variable Conventions

The code uses Iranian year suffixes:

- `98` = 1398
- `99` = 1399
- `1400`, `1401`, `1402`, `1403` as written

Current year pairs in `codes_v2`:

- `98 99`
- `99 1400`
- `1400 1401`
- `1401 1402`
- `1402 1403`

Current poverty lines in `codes_v2/data_prepration_v2.do` and `codes_v2/preparation_diff_hh_v2.do`:

- `pl_98 = 5863711`
- `pl_99 = 8205691`
- `pl_1400 = 12571554`
- `pl_1401 = 17671052`
- `pl_1402 = 22258561`
- `pl_1403 = 29175368`

Be careful: older root preparation scripts and some manuscript prose mention older lines for 1398-1399, such as `9060000` and `12540000`. Do not mix these without explaining the change.

Common variables:

- Household ID: `HHID`
- Welfare stub: `lcpc_`
- Poverty line stub: `lpoverty_line`
- Strata stub: `strata_`
- Weight: `Weight`
- Area: `Region` (`1` urban, `2` rural)
- Head sex: `HSex` (`2` female in subgroup scripts)
- Head education years: `HEduYears`
- Head age: `HAge`

Subgroup filters:

- Female-headed households: `HSex==2`
- Head lacks university education: `HEduYears<16`
- Head has university education: `HEduYears>=16`
- Urban: `Region==1`
- Rural: `Region==2`

Poverty status coding in Stata scripts is inverted from plain language:

- `gen pov... = (consumption > poverty_line)`
- `1` means nonpoor.
- `0` means poor.
- Tables label rows/columns accordingly, usually with poor first because Stata tabulates `0` before `1`.

## Stata Workflow

Run Stata from the repository root or from Stata's UI, then execute scripts in this order when regenerating data/results:

```stata
do codes_v2/data_prepration_v2.do
do codes_v2/preparation_diff_hh_v2.do
```

Then run the relevant year-pair scripts, for example:

```stata
do 1402-1403/parametric.do
do 1402-1403/parametric_female.do
do 1402-1403/parametric_educ.do
do 1402-1403/parametric_have_educ.do
do 1402-1403/parametric_urban.do
do 1402-1403/parametric_rural.do
```

For 1398-1399, the analogous scripts are at repo root: `parametric.do`, `parametric_female.do`, `parametric_educ.do`, `parametric_have_educ.do`, `parametric_urban.do`, and `parametric_rural.do`.

Most current parametric scripts are templated. The editable configuration block is near the top:

- `global working_dir`
- `global file_cross`
- `global file_panel`
- `global yr1`
- `global yr2`
- `global indvar`
- `global age_cond_1`
- `global age_cond_2`

Current age filters are:

- First year: `HAge>= 25 & HAge<= 55`
- Second year: `HAge>= 26 & HAge<= 56`

This one-year shift is intentional for adjacent-year pairs. If using a two-year gap or another interval, adjust the second-year age condition accordingly.

Parametric scripts use:

- `rho = 1`, `0.8`, `0.7` for lower-bound columns.
- `rho = 0.3`, `0.2`, `0` for upper-bound columns.
- `simulate ..., reps(500)` for simulated truth standard errors.
- `mat li pov_final` as the final result matrix in the newer scripts.

The final matrix columns are usually:

`LB`, `r1`, `r0.8`, `r0.7`, `TruthSim`, `r0.3`, `r0.2`, `r0`, `UB`

## Manuscript Workflow

The main source is `paper_text/thesis.tex`. It currently contains:

- Introduction with a poverty headcount figure.
- Literature review.
- Data section focused on HIES.
- DLLM model section.
- Poverty line subsection.
- Results tables for 1398-1399 through 1402-1403 and subgroups.
- Empty `Robustness Checks` section.
- Draft `Potential Mechanisms` section.
- Conclusion.

When editing the manuscript:

- Keep numeric claims synchronized with the Stata tables and logs.
- Prefer consistent year notation. The prose currently mixes Gregorian years (`2019 and 2020`) and Iranian years (`1398-1399`).
- Preserve LaTeX table labels if text references depend on them.
- Be cautious with the bibliography: `myref.bib` contains duplicate keys such as `Ferreira2016`, `cruces2015estimating`, and `bilenkisi2015impact`.
- The preamble has `\bibliographystyle{elsarticle-harv}`, while the end of the file uses `\bibliographystyle{chicago-fa}`. Resolve deliberately if citation formatting becomes a task.
- `paper_text/commandsforbib.bat` refers to `main`, but the current source file is `thesis.tex`. Adjust the batch file or run commands manually against `thesis`.

Suggested manual compile sequence from `paper_text/` when TeX is installed:

```powershell
xelatex thesis
bibtex8 -W -c cp1256fa thesis
xelatex thesis
xelatex thesis
```

If `bibtex8` is unavailable or Persian bibliography support is not needed for the task, use the locally available BibTeX tool and report the difference.

## Robustness Figure Workflow

For the first residual normality robustness check, follow `docs/residual_plot_decisions.md`.

Current decision:

- Use the all-household 1398-1399 model only.
- Generate residuals from the exact unweighted OLS regressions used in `parametric.do`.
- Plot 1398 and 1399 separately in two panels.
- Use raw residuals with fitted normal densities.
- Weight the displayed residual histograms by HIES `Weight`.
- Export the figure from `figures/residuals_9899_normality.do`.

Run from Stata with:

```stata
do "E:\my_papers\poverty_dynamics\figures\residuals_9899_normality.do"
```

In this desktop environment, Stata was found at `C:\Program Files\StataNow19\StataMP-64.exe`; `StataMP-64` may not be visible on PATH inside Codex shells.

## Known Open Issues

The manuscript has explicit red notes and structural gaps:

- SPL paragraph in the introduction has `\textcolor{red}{to be completed}`.
- The Iran poverty-rate sentence asks which rate, scope, and poverty line it refers to.
- `Robustness Checks` is currently empty.
- `Potential Mechanisms` asks for a histogram of non-labor earnings by head education and gender for two years.
- The abstract emphasizes 1398-1399, but the results section now includes multiple year pairs through 1402-1403.
- Some prose says the method is validated "for the first time in a developing country under sanctions"; treat this as a strong claim that needs careful support.

## Verification

Before handing off Stata changes:

- Confirm the target `global file_cross`, `global file_panel`, and year suffixes match the script folder.
- Confirm the relevant `.dta` files exist in `poverty_line_data/`.
- Run the relevant `.do` file in Stata if Stata is available.
- Inspect the final `mat li pov_final` output and any generated `.log`.
- Check that transition cells sum to approximately 100, allowing for rounding.
- Check that lower-bound, truth/simulated-truth, and upper-bound columns are logically ordered for the interpretation being made.

Before handing off manuscript changes:

- Compile the PDF if TeX is available.
- Inspect the generated PDF around edited sections, tables, figures, bibliography, and cross-references.
- If TeX is not available, say that clearly and at least run text-level checks with `rg` or `Select-String`.

Stata verification has been performed for `figures/residuals_9899_normality.do`; LaTeX PDF rebuilds still require a local TeX toolchain.

## Working Principles

- Use `rg`/`Select-String` for searches before broad edits.
- Keep generated data in `poverty_line_data/`; do not commit it unless the user explicitly asks.
- Do not overwrite source data in `shared_resources` or `irheis_weights` without explicit confirmation.
- Do not modernize all Stata scripts at once. Keep edits targeted to the year pair/subgroup being worked on.
- When changing model covariates, poverty lines, weights, sampling, or `rho` assumptions, update both the Stata output and manuscript explanation.
- If a result changes, trace it back to the exact script, year pair, subgroup, poverty line, and weight convention.
