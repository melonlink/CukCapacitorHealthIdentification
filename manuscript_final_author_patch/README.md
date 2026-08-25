# Manuscript final author patch

This directory applies the final author-level wording patch to
`manuscript_v031`. The theory, algorithms, cases, seeds, hyperparameters, and
simulation results are unchanged. Earlier manuscript packages remain intact.

## Final patch scope

- Section V-A describes validity gating through the predeclared edge/charge
  acceptance rules without implying a separate numeric capacitance gate.
- Limitations states the applicability boundary when either inductor-current
  measurement is unavailable.
- Fig. 8 uses `Mean of C/ESR MAPE (%)` and defines the ordinate only as a visual
  Pareto summary, not as the estimator-selection objective.

## Main decisions

- Primary novelty: topology-synchronous, physically direction-decoupled edge and charge observations.
- Primary realization: TS-D-RLS.
- Uncertainty-aware extension: TS-SLTVKE.
- Main-text calibration display: `k_R=0.9772`.
- Proposition 1 states local identifiability over the accepted finite window and does not invoke the stronger structural-identifiability terminology.
- Full computation precision is retained only in the calibration provenance, Supplementary, checksum, and source-trace records.
- The `±0.006` spread is calibrated casewise unit-to-unit variation supplied identically to all estimators, not residual unknown gain error.
- Evidence level: theory, algorithm, simulation, and device-realistic simulation; no hardware or accelerated-aging validation.
- Figs. 4--8 are pure-vector PDF redraws from frozen CSV outputs; no simulation is invoked by the redraw script.

## Build

```powershell
latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=build main.tex
```

The build output is `build/main.pdf`; the identical delivery copy is
`main.pdf`.

## Audit artifacts

- `FINAL_AUTHOR_PATCH_CHANGELOG.md`: P1--P3 author-patch record.
- `FINAL_AUTHOR_PATCH_AUDIT.md`: frozen-number, compilation, PDF-structure, and
  rendered-page acceptance record.
- `SCIENTIFIC_CHECKSUM_V031.csv`: v0.3-to-v0.31 frozen-number comparison.
- `AUTHOR_FINAL_WORDING_AUDIT.md`: final terminology, calibration, figure, accent, numeric, and claim audit.
- `MANUSCRIPT_V031_CHANGELOG.md`: author-cleanup revision record.
- `REVIEWER_ATTACK_AUDIT.md`: three reviewer perspectives and wording defenses.
- `COMPRESSION_AUDIT.md`: repeated points, sentence compression, moved detail, and retained adverse results.
- `figures/fig02_grayscale_check.png`: grayscale readability preview.
- `figures/generate_vector_figures_v031.m`: plot-only vector redraw from archived CSV data.

Detailed F28379D, calibration, bootstrap, tracking-definition, and operating-transient material remains under `supplementary/`.
