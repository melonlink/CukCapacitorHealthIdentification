# Manuscript v0.31 changelog

| ID | Section/artifact | Original issue | Revision | Scientific content changed? | Source check | Status |
|---|---|---|---|---|---|---|
| V031-001 | Baseline | Final author cleanup required an independent version | Copied `manuscript_v03` to `manuscript_v031`; all older packages remain intact | NO | v0.3 final audit and PDF | COMPLETE |
| V031-002 | Proposition 1 | `locally structurally identifiable` could imply a stronger system-level property | Replaced it with `locally identifiable over the accepted finite window` | NO | Positive finite-window Gramian and unchanged proof | COMPLETE |
| V031-003 | Section III-B | The calibrated `+/-0.006` spread could still be misread as unknown gain error | Defined it as calibrated unit-to-unit variation known casewise and shared by every estimator | NO | Frozen O1 stream generator and common `h_R` calls | COMPLETE |
| V031-004 | Supplementary S2 | Casewise variation and residual calibration sensitivity were not explicitly contrasted | Labeled the existing `+/-1%` study as residual-calibration sensitivity and distinguished it from the main evaluation | NO | Existing 35-row sensitivity record | COMPLETE |
| V031-005 | Table III/notation | Calibration description was mechanically phrased | Used `training-calibrated nominal value` and `case-specific calibrated value used in evaluation` | NO | Calibration provenance and parameter trace | COMPLETE |
| V031-006 | Calibration terminology | Historical simulation artifacts still used commissioning as a current-stage noun | Replaced current-stage prose with simulation/training calibration; hardware commissioning remains future tense | NO | Calibration provenance | COMPLETE |
| V031-007 | Fig. 4 | Dense labels omitted a visibly adverse p95 effect | Redrew C/ESR MAPE and p95 effects in grouped panels and retained negative Dual-EKF ESR-p95 | NO | Frozen observation-effect bootstrap CSV | COMPLETE |
| V031-008 | Fig. 5 | Static comparison was raster and style-inconsistent | Redrew zero-baseline C/ESR MAPE panels as vector PDF | NO | Frozen static-comparison CSV | COMPLETE |
| V031-009 | Fig. 6 | The plotted arithmetic mean conflicted with prose that kept C/ESR p95 separate | Redrew separate C and ESR p95 panels for the F28379D-realistic profile | NO | Frozen noise/timing CSV | COMPLETE |
| V031-010 | Fig. 7 | Ramp figure was raster and relied mainly on color | Redrew the frozen 1-s joint ramp with black dashed truth and method-specific lines/markers | NO | Frozen ramp-history CSV | COMPLETE |
| V031-011 | Fig. 8 | Pareto ordinate was not explicitly defined | Defined the ordinate as the arithmetic mean of C/ESR MAPE and retained the no-weighted-score boundary | NO | Frozen static and complexity CSV files | COMPLETE |
| V031-012 | Figure typography | Fig. 4--8 fonts, widths, markers, and grayscale encodings varied | Standardized 8-pt Times typography, 1.15-pt lines, marker order, and pure-vector PDF export | NO | Vector PDF inspection and grayscale renders | COMPLETE |
| V031-013 | Cuk accent | Fig. 1 used a caron and manuscript text did not force a nonbreaking accented word | Applied one robust nonbreaking acute-accent macro and regenerated Fig. 1 | NO | PDF visual inspection | COMPLETE |
| V031-014 | Results positioning | Primary/extension language could be more explicit | Stated the aggregate TS-D-RLS tradeoff and the calibrated-confidence role of TS-SLTVKE without universal superiority | NO | Frozen static, ramp, complexity, and coverage values | COMPLETE |
| V031-015 | Release audit | v0.31 lacked an independent numeric and wording gate | Added `SCIENTIFIC_CHECKSUM_V031.csv` and `AUTHOR_FINAL_WORDING_AUDIT.md` | NO | v0.3-to-v0.31 comparison | COMPLETE |
