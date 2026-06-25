# Population Stability Robustness Decisions

This note records the decisions for the robustness check tied to Dang et al.'s first assumption: the underlying sampled population should be comparable across the two survey rounds used to construct the synthetic panel.

## Scope

- Start with the all-household model only.
- Start with the 1398-1399 year pair only.
- Treat 1398 as the base year for this check.
- Do not use 1395 in this check. The earlier 1395 note may refer to a CPI/base-price year or a broader pre-shock benchmark, but it is not needed for Dang's same-population assumption in the 1398-1399 pair.

## Sample

Use the same age-cohort alignment as the current all-household 1398-1399 model:

```stata
1398: HAge >= 25 & HAge <= 55
1399: HAge >= 26 & HAge <= 56
```

For descriptive age comparisons, define aligned base-year age as:

```stata
base_age = HAge      if year == 1398
base_age = HAge - 1  if year == 1399
```

This compares the same synthetic cohort one year later.

## Weighting

Use HIES `Weight` for all descriptive composition checks. This is a descriptive survey-composition diagnostic, not a residual-generating regression.

## Variables

The core check should focus on variables that are time-invariant, slow moving, or define the sampling/composition of the synthetic population:

- aligned household-head age
- aligned age groups
- head sex
- head education years and broad education groups
- head literacy indicator, reported using the native `HLiterate` coding
- urban/rural composition
- province composition in the balance CSV only; omit ProvinceCode rows from the Love plot

Variables such as household size, number of children, employment, and marital status are useful supplementary diagnostics because they appear in the current model, but they are not the cleanest evidence for Dang's same-population assumption because they can change within households.

## Outputs

The standalone Stata script is:

```text
figures/population_stability_9899.do
```

Expected exported outputs:

```text
figures/population_stability_9899_balance.csv
figures/population_stability_9899_love_plot.pdf
figures/population_stability_9899_love_plot.png
figures/population_stability_9899_age_barplot.pdf
figures/population_stability_9899_age_barplot.png
figures/population_stability_9899_education_barplot.pdf
figures/population_stability_9899_education_barplot.png
figures/population_stability_9899_children_barplot.pdf
figures/population_stability_9899_children_barplot.png
figures/population_stability_9899.log
```

## Interpretation

The preferred main-text evidence is a weighted balance table plus a Love plot of absolute standardized mean differences. The Love plot omits ProvinceCode rows to keep the main diagnostic readable.

Bar plots are useful as an intuitive supplement for categorical distributions. Export age groups, education groups, and number-of-children groups as separate figures so each remains readable.

A conventional applied threshold is that absolute standardized differences below about `0.10` indicate small observable composition differences. This threshold should be presented as a descriptive rule of thumb, not a formal proof that the assumption holds.