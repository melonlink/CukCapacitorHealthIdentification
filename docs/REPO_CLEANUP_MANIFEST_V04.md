# Repository Cleanup Manifest (v0.4, 2026-08-25)

Goal: remove superseded process packages and keep the complete material
chain for the current manuscript version
(`manuscript_final_author_patch`, 13-page v0.4 build).

## Removed (recoverable from git history)

| Folder | Size | Superseded by | Historical role |
|---|---|---|---|
| `paper_verification_v11` | 5.1 MB | `paper_verification_v12` | pre-recalibration factorial (kR center 0.982) |
| `paper_algorithm_selection_v1` | 11 MB | `paper_algorithm_selection_v2` | pre-recalibration estimator selection |
| `verification_v22` | 12.6 MB | `verification_v23` | generic DSP/ADC study before the F28379D-specific v2.3 |

Restore any of them with:
`git checkout <pre-cleanup-commit> -- <folder>`
(the deletions are staged on branch `manuscript-final-author-patch`; the
last commit containing all three is `4fafe81`).

## Compensating patches

1. `verification_v23/scripts/run_v23_all.m` — dropped the defensive
   `addpath(genpath(verification_v22))`; v2.3 calls no v22 function and
   reads no v22 data file (verified by search).
2. `calibration_closure/scripts/run_kR_sensitivity.m` — repointed from the
   v1 to the v2 algorithm package. `generate_frozen_o1_stream.m` is
   byte-identical between v1 and v2; `run_locked_o1_estimator.m` differs
   in one comment line only (verified by byte/text diff).
3. `calibration_closure/scripts/reproduce_kR_calibration.m` — the
   historical-config drift check now parses `cfg.kRCalibration` from the
   v2 engine (adopted full-precision value 0.97719802594550731; parse
   verified). Re-running the ORIGINAL 0.982-era comparison, or
   `recalibrated_campaign/scripts/compare_kR_rerun.m`, requires restoring
   the removed folders from git history; their frozen output tables are
   retained in `calibration_closure/results/` and
   `recalibrated_campaign/results/`.

## Kept (current-version chain)

- `manuscript_final_author_patch/` — manuscript, figures, supplementary,
  source-traceability matrices, audits.
- `paper_verification_v12/`, `paper_algorithm_selection_v2/` — current
  result engines and frozen tables (all manuscript numbers).
- `paper_verification_v1/` — frozen 48-blind-case table (v1.2 input).
- `verification_v21/` — frozen Model-B traces, locked covariance, frozen
  estimator, CRLB table.
- `verification_v2/` — Model-B Simscape circuit (v2 model file).
- `verification_v23/` — F28379D device-realistic results and
  supplementary figures.
- `cuk_cap_health_verification/` — base Model-A code, algorithms, rebuilt
  Simulink models (see `model/MODEL_REBUILD_NOTE.md`).
- `closedloop_dcm_validation/` — v0.4 closed-loop and light-load
  supplement.
- `calibration_closure/`, `recalibrated_campaign/` — kR provenance chain
  (frozen audit outputs).
- `docs/` — theory document (cited by the figure source map) and task
  briefs.

## Validation after cleanup

- All 14 current-chain dependency files verified present (blind-case
  table, v21 anchors, v12/v2 tables, v2 circuit, v23 figures, supplement
  tables).
- Patched kR parse verified against the v2 engine (0.97719802594550731).
- Manuscript PDF unchanged by the cleanup (no manuscript source touched).

## Remaining local caches (deletion blocked in-session; optional)

These are gitignored, regenerable caches (~182 MB) declared reproducible
by `.gitignore`; remove them manually if desired:

```powershell
Get-ChildItem cuk_cap_health_verification\results -Recurse -Filter *.mat | Remove-Item -Force
Get-ChildItem verification_v2\results -Recurse -Filter *.mat | Remove-Item -Force
Remove-Item closedloop_dcm_validation\results\*.mat -Force
```

(`run_all.m` / `run_v2_all.m` / the supplement run scripts rebuild them.)

## Restructure addendum (same day)

The flat layout was reorganized for continuous versioning:

- `manuscript_final_author_patch/` -> `manuscript/` (stable name; version
  identity moves to changelogs and git tags).
- All ten campaign packages moved under `campaigns/` in one step, which
  preserves every `fullfile(fileparts(<packageRoot>), <sibling>)`
  cross-reference by construction.
- Patched for the one-level change: the two manuscript figure-generation
  scripts (campaign table paths), the two closedloop supplement scripts
  (manuscript figure output path), `.gitignore`, and the five
  source-traceability CSVs (campaign paths prefixed with `campaigns/`).
- Validated after the move: dependency file check, cross-tree figure
  regeneration, deterministic closed-loop rerun (identical numbers,
  k_R = 0.998665), and a clean 13-page latexmk build.

See the root `README.md` for the layout contract and the convention for
adding future campaign packages.
