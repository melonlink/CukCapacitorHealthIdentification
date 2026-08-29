# Final Author Patch Audit

Baseline: `manuscript_v031`

The task referred to `main(6).tex/pdf`, but no files with those names were
present in the workspace. The latest completed author-cleanup package,
`manuscript_v031/main.tex` and its 11-page PDF, was therefore used as the
equivalent frozen input. The baseline package remains unchanged.

## P1--P3 acceptance

| ID | Acceptance check | Result |
|---|---|---|
| P1 | Section V-A says that validity gating rejects observations failing the predeclared edge/charge acceptance rules; no separate numeric capacitance-channel gate is implied. | PASS |
| P2 | Limitations states that both inductor currents are assumed available and that a missing measurement requires an additional sensor or independently validated current reconstruction. | PASS |
| P3 | Fig. 8 uses `Mean of C/ESR MAPE (%)`; its caption identifies the ordinate only as a visual Pareto summary and not as the estimator-selection objective. | PASS |

The manuscript makes no `requires no additional sensors`, `sensorless`, or
`current-sensorless` claim for the proposed method. Literature titles and
descriptions retain their original terminology.

## Scientific checksum

| Quantity | Frozen value | Final value | Status |
|---|---:|---:|---|
| TS-D-RLS C MAPE (%) | 0.3727 | 0.3727 | UNCHANGED |
| TS-D-RLS ESR MAPE (%) | 0.2233 | 0.2233 | UNCHANGED |
| TS-D-RLS convergence (cycles) | 13.21 | 13.21 | UNCHANGED |
| TS-SLTVKE C MAPE (%) | 0.3011 | 0.3011 | UNCHANGED |
| TS-SLTVKE ESR MAPE (%) | 0.6446 | 0.6446 | UNCHANGED |
| Dual EKF C MAPE (%) | 0.3043 | 0.3043 | UNCHANGED |
| Dual EKF ESR MAPE (%) | 1.1938 | 1.1938 | UNCHANGED |
| `mu_C` | 0.217943 | 0.217943 | UNCHANGED |
| `mu_R` | 880.008 | 880.008 | UNCHANGED |
| `k_R` main-text display | 0.9772 | 0.9772 | UNCHANGED |
| `k_R` full precision | 0.97719802594550731 | 0.97719802594550731 | UNCHANGED |
| `I_Sigma,gate` (A) | 0.12 | 0.12 | UNCHANGED |
| `T_w,C` (us) | 2.0 | 2.0 | UNCHANGED |
| `T_w,R` (us) | 2.2 | 2.2 | UNCHANGED |
| F28379D p95 C (%) | 1.6425 | 1.6425 | UNCHANGED |
| F28379D p95 ESR (%) | 2.6109 | 2.6109 | UNCHANGED |

Results:

- 16/16 rows in `SCIENTIFIC_CHECKSUM_V031.csv` remain `UNCHANGED`.
- The baseline and final checksum CSV SHA-256 values are identical:
  `B200D0F9F847DAC179166D9CB6A206943BCAD2EFE803BED0D2267886239206D4`.
- All frozen manuscript and scientific source files outside the three requested
  locations are byte-identical to the baseline.
- Figs. 4--7 are byte-identical to the v0.31 files. Fig. 8 was redrawn from the
  same archived static-comparison and operation-count CSV files; no model,
  estimator, calibration, or simulation was run.

## Compilation and PDF structure

- Toolchain: MATLAB R2023b plot-only redraw; TeX Live 2025 `latexmk` build.
- Output: 11 pages, US Letter, PDF 1.7, 614961 bytes.
- Final PDF SHA-256:
  `073467A5DAC42C7D77C44AD9958DD161F97928FF427A2FCC2E6A6A9A5F875FEB`.
- Root `main.pdf` and `build/main.pdf` are byte-identical.
- LaTeX errors, undefined control sequences, undefined references/citations,
  emergency/fatal errors, and overfull boxes: 0 each.
- All main-PDF fonts are embedded. Fig. 8 embeds Times New Roman and contains
  zero raster-image objects (pure vector content).

## Visual audit

All 11 pages were rendered at 180 dpi with the specified shared document
runtime and Poppler. Section V-A (page 6), Limitations and Fig. 8 (page 10), and
the standalone Fig. 8 artwork (300 dpi) received focused inspection.

- New wording is legible and does not overflow either column.
- Fig. 8 axis and caption are aligned, unclipped, and mutually consistent.
- Figures, tables, equations, references, page numbers, and section transitions
  show no overlap, clipping, black boxes, or broken references.
- The `\Cuk{}` acute accent remains correct in the title, text, and figures.
- The final page count remains 11, matching the baseline.

## Final status

`FINAL_AUTHOR_PATCH_PASS`
