# Letter Manuscript: Supervised Covariance Reset

Companion letter to `manuscript/` (Route B decision, 2026-08-26): a
supervised-reset construction that resolves the tracking-vs-confidence
tradeoff documented as limitation 6 of the main paper.

- `main.tex` — IEEEtran letter, 3 pages; `main.pdf` is the compiled copy
  (`latexmk -pdf -outdir=build main.tex`, TeX Live 2025).
- `references.bib` — 10 entries; the five classical references (Page 1954,
  Willsky 1976, Mehra 1970, Bar-Shalom 2001, Gustafsson 2000) were
  verified against publisher records with DOIs on 2026-08-26. The
  companion-paper entry [1] is a placeholder to be updated at submission.
- `figures/generate_letter_figures.m` — draws Fig. 1 from the frozen
  campaign CSVs in `campaigns/hybrid_estimator_v1/results/tables/`
  (TPEL style: below-panel labels, bottom/left ticks only, framed legend,
  upright units).

All quoted numbers come from
`campaigns/hybrid_estimator_v1/scripts/run_letter_campaign.m`
(162 static runs + 3x3 dynamic scenarios, per-profile calibration,
seeds 61xxx-64xxx). Regenerate with that script before changing any
number in the text.

Target venue: **IEEE TPEL Letters** (decided 2026-08-26). Verified
requirements and the remaining author actions (real byline — TPEL is
single-anonymous; companion-citation update) are in
`SUBMISSION_CHECKLIST.md`. Current state: 3 pages (limit 4 incl.
references), abstract 190 words (rule 150-200).

## RETIRED (2026-08-26)
The integration decision merged this letter's method into manuscript/ as the primary realization (v0.6). This folder is retained as history only; its verified references were moved into the main bibliography. Do not submit.
