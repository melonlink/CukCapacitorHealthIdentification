# v0.4 Supplement Changelog (2026-08-25)

Closes out the priority-2 (rigor supplements) and priority-4 (submission
hygiene) items from the 90+-score roadmap. All 16 frozen scientific-
checksum quantities verified present and unchanged in the rebuilt PDF.
Build: TeX Live 2025 latexmk, 0 errors, 0 undefined references, 0 overfull
boxes, 13 pages (was 11; growth carries three new result subsections,
three figures, and 11 new references).

## New scientific content (all new numbers, no frozen number touched)

1. **CRLB efficiency (Sec. VII-D, Fig. 7)** — drawn from the frozen
   `verification_v21/results/tables/table_CRLB_v21.csv` (15 sensitivity
   cases x 20 seeds). Commissioned-chain RMSE/sqrt(CRLB): 1.38–2.34 (C),
   1.35–3.27 (ESR); medians 2.17/2.40; bias cases (AFE 1.5/3 MHz, timing
   100/200 ns) reported as diagnostics.
2. **Closed-loop operation (Sec. VII-H, Fig. 9)** — new package
   `closedloop_dcm_validation/`: PI-regulated Model-A plant, k_R
   re-commissioned under feedback (0.9987), three blind transition cases.
   Tail errors <= 0.222% (C) / 0.111% (ESR), convergence 3–7 cycles,
   post-transition peaks <= 0.410%/0.102%, CCM-gate rejections held the
   estimate without accuracy loss.
3. **Light-load availability (Sec. VII-I, Fig. 10)** — fixed-duty sweep
   100% -> 6.7% load; acceptance 100% down to 20% load, knee at 10–17%,
   zero at <= 8.3%; accepted-row errors <= 1.4% down to 10% load.

## Manuscript integration

- Abstract: one sentence on closed-loop accuracy and light-load
  availability. Introduction: contribution 4 extended; CRLB expanded at
  first use; two related-work sentences with new citations. Sec. IV:
  pointer from existence bounds to CRLB efficiency. Sec. VI: supplement
  pointer sentence. Sec. IX: limitations list grown to seven (new
  supplement-scope boundary); light-load cross-reference added.
  Conclusion: one supplementary-results sentence.

## Submission hygiene

- References 24 -> 35: eleven entries added, every one verified against
  Crossref/IEEE Xplore metadata (DOIs recorded in the reference-search
  audit) — Wang & Blaabjerg 2014; Zhao 2021 overview; Yao 2024 film-cap
  aging; Wu 2025 TIE rail (hardware-validated); Wang 2024 CHB; Wei 2024
  discharge-profile; Zhao 2023 grey-box; Deng 2020 MMC; Sundararajan 2020
  Goertzel; Asoodar 2024 OJPEL; Madrid 2021 SEPIC/Cuk/Zeta DCM.
- `fig_pe_lower_bound` converted from PNG to vector PDF, redrawn from the
  frozen `table_physical_PE_lower_bound.csv`
  (`figures/generate_supplement_figures_v04.m`); the manuscript now
  contains no raster figures in the main text.
- Empty v1 Simulink models rebuilt and validated
  (`cuk_cap_health_verification/model/MODEL_REBUILD_NOTE.md`): Model A
  matches a grid-exact RK4 to machine precision (~1e-13); the v1 Simscape
  circuit restored from the verified v2 model; `run_simulink_model_a.m`
  and `run_simscape_model_b.m` reproduce again.
- `FIGURE_SOURCE_MAP.csv` updated: pe_lower_bound row repointed to the
  frozen CSV; three new figure rows appended with caption boundaries.

## Not done (left deliberate)

- Significant-digit reduction of displayed numbers: conflicts with the
  frozen-checksum traceability discipline; would need a coordinated
  re-audit.
- Hardware experiments, temperature axis, measured WCET: priority-1 items
  requiring the bench.
