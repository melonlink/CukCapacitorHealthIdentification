# Manuscript v0.31 author final wording audit

Date: 2026-08-25

## Release decision

`MANUSCRIPT_V031_AUTHOR_CLEANUP_PASS`

The audit compares `manuscript_v031` with the frozen `manuscript_v03` baseline. This pass changed scientific wording and graphical presentation only. It did not invoke a simulation model, estimator, calibration routine, or hyperparameter search.

## Scientific wording

- [x] Proposition 1 no longer uses `structural identifiability` or `structurally identifiable` in the main source or extracted PDF.
- [x] Its conclusion is `locally identifiable over the accepted finite window`.
- [x] The Proposition 1 assumptions, Gramian inequality, lower bounds, numerical constants, and proof are unchanged.
- [x] The Abstract, Contribution 3, Discussion, and Conclusion use the appropriately scoped local/finite-window identifiability language.
- [x] No stronger global, asymptotic, or system-structural claim was added.

## Calibration semantics

- [x] The `±0.006` spread is defined as case-to-case variation in calibrated measurement-chain gain.
- [x] Each realized coefficient is assumed known after calibration and supplied identically to all compared estimators through the same ESR regressor.
- [x] The main evaluation explicitly tests calibrated unit-to-unit variability, not residual unknown calibration error.
- [x] No occurrence of `calibration uncertainty robustness`, `unknown gain-error robustness`, or `k_R uncertainty test` appears in the main source.
- [x] The existing `±1%` Supplementary S2 check is explicitly labeled residual-calibration sensitivity, distinguishing it from the main casewise variation.
- [x] The manuscript display remains `k_R=0.9772`; the main source and extracted PDF contain no full-precision coefficient.
- [x] Table III now uses `training-calibrated nominal value; case-specific calibrated value used in evaluation`.
- [x] Present-stage prose uses simulation/training calibration. Hardware commissioning occurs only in the future-tense hardware requirement.

## Estimator positioning

- [x] TS-D-RLS remains the primary lightweight realization because of the evaluated aggregate ESR-accuracy, convergence, degradation-tracking, and arithmetic-cost tradeoff.
- [x] No sentence claims that TS-D-RLS is universally superior, best, or dominant in every metric.
- [x] TS-SLTVKE remains an uncertainty-aware realization of the same observation framework, with better-calibrated coverage and retained point-estimation/dynamic limitations.
- [x] No new novelty claim or hardware-experiment claim was added.

## Figures and typography

- [x] Figs. 4--8 were redrawn from archived CSV outputs only; the plot script contains no model, estimator, or simulation call.
- [x] All five result figures are pure-vector PDF files. `pdfimages -list` reports zero embedded image rows for each.
- [x] All five vector figures embed a subset Times New Roman TrueType font.
- [x] Plot typography is set to 8 pt, primary line width to 1.15 pt, and method order to TS-D-RLS, TS-SLTVKE, Dual EKF.
- [x] Line and marker styles remain distinguishable in grayscale; truth is black dashed in Fig. 7.
- [x] Fig. 4 separates C and ESR effects, shortens category labels, and visibly retains the adverse Dual-EKF ESR-p95 effect.
- [x] Fig. 5 uses zero-baseline C/ESR MAPE panels and makes no numerical-SOTA claim.
- [x] Fig. 6 separates C and ESR p95, labels residual timing mismatch in ns, and places legends away from curves.
- [x] Fig. 7 retains Truth, TS-D-RLS, TS-SLTVKE, and Dual EKF; its caption continues to identify trace-derived statistics rather than measured aging data.
- [x] Fig. 8 defines both axes and states that its ordinate is not a weighted selection score.
- [x] Fig. 2 passed the final 100%-zoom and grayscale check; edge and charge paths remain separable by layout and solid/dashed encoding.
- [x] The manuscript and Fig. 1 use a robust nonbreaking acute-accent macro for `Ćuk`; the title and figure heading render without a detached accent.
- [x] Bibliography titles preserve their audited source metadata, including source-authored plain `Cuk` spellings.

## Scientific checksum

- [x] `SCIENTIFIC_CHECKSUM_V031.csv` contains 16 unique required checks.
- [x] All 16 rows have identical v0.3 and v0.31 values and status `UNCHANGED`.
- [x] TS-D-RLS C/ESR MAPE and convergence are unchanged.
- [x] TS-SLTVKE and Dual-EKF static metrics are unchanged.
- [x] The two finite-window lower bounds are unchanged.
- [x] The internal and displayed calibration values, both observation-window lengths, the ESR current gate, and both F28379D p95 metrics are unchanged.
- [x] No `STOP_AND_REPORT_NUMERIC_DRIFT` condition was triggered.

## LaTeX and PDF release gate

- [x] Final `latexmk` compilation completed with exit code 0.
- [x] The log contains no LaTeX error, undefined citation/reference, fatal error, emergency stop, or overfull box.
- [x] The compiled bibliography contains 24 resolved entries; no reference metadata was changed.
- [x] Final PDF length is 11 letter-size IEEE pages.
- [x] Final PDF size is 614902 bytes.
- [x] Final PDF SHA-256 is `972743A4B433B07C66004C54384A3C9BF9A61A04C8713787BB40E1EF7A0ED8D9`.
- [x] All 11 pages were rasterized at 180 dpi with the required document runtime and Poppler path.
- [x] Contact sheets and full-size pages containing Table III and Figs. 4--8 were inspected.
- [x] No clipping, overlap, missing glyph, detached accent, unreadable legend, or undersized figure text was observed.

## Author-review boundary

The v0.31 cleanup is complete. Remaining work is final human author review, journal-specific formatting, or future hardware/accelerated-aging evidence; none is an unresolved wording or figure defect in this package.
