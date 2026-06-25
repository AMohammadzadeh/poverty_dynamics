# Residual Normality Plot Decisions

This note records the decisions made for the first robustness-check figure comparing OLS residuals with a normal distribution.

## Scope

- Start with the all-household model only.
- Start with the 1398-1399 year pair only.
- Do not include subgroup residual plots yet.
- Do not include later year pairs yet.

## Model

Use the exact all-household 1398-1399 parametric specification behind the main synthetic-panel estimates, rather than a simpler diagnostic-only model.

The residual-generating regressions should mirror `parametric.do`:

```stata
global hdage98 "HAge>= 25 & HAge<= 55"
global hdage99 "HAge>= 26 & HAge<= 56"
global indvar "HAge i.HSex HEduYears HLiterate NKids i.Region i.ProvinceCode Size HEmployed HMarritalState"

xi: reg lcpc_98 $indvar if $hdage98 & samp==1, cluster(strata_98)
xi: reg lcpc_99 $indvar if $hdage99 & samp==2, cluster(strata_99)
```

This keeps the robustness diagnostic tied to the model that generates the reported parametric bounds.

## Plot Design

- Plot 1398 and 1399 residuals separately.
- Use two panels in one figure.
- For each year, show a residual histogram scaled as a density.
- Overlay a fitted normal density using that year's residual mean and standard deviation.
- Use raw residuals rather than standardized residuals because this is the more common applied-economics presentation and is closer to Dang et al.'s visual diagnostic.
- Keep the x-axis range common across panels when feasible.
- Do not add Q-Q plots in the main figure for now.

## Weighting Decision

Use unweighted OLS residuals, matching the current `parametric.do` workflow and the Dang et al. replication scripts.

Use HIES `Weight` only for the displayed residual distribution. This mirrors the broader pattern in Dang et al.'s replication code:

- Prediction regressions are unweighted, with clustered standard errors.
- Poverty summaries and tabulations are weighted.

The figure note should say:

> Residuals are from unweighted OLS consumption models; displayed densities are weighted by HIES Weight.

## Output

The standalone Stata script is:

```text
figures/residuals_9899_normality.do
```

Expected exported outputs:

```text
figures/residuals_9899_normality.pdf
figures/residuals_9899_normality.png
figures/residuals_9899_normality.gph
figures/residuals_1398_normality.gph
figures/residuals_1399_normality.gph
figures/residuals_9899_normality.log
```
