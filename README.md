# Ćuk Energy-Transfer Capacitor Health Identification

Topology-synchronous decoupled C–ESR identification for the energy-transfer
capacitor in Ćuk converters: switched-model theory, finite-window
identifiability bounds, TS-D-RLS / TS-SLTVKE estimators, blind Monte Carlo
verification, and TMS320F28379D device-realistic feasibility.

## Repository layout

```
manuscript/    The living IEEE manuscript (main.tex + sections/ + figures/
               + supplementary/ + source_traceability/ + audit records).
               Version identity lives in the changelog files and git tags,
               NOT in the folder name — the folder never gets renamed.
letter/        Companion letter manuscript (supervised covariance reset),
               drawing its numbers from campaigns/hybrid_estimator_v1/.
campaigns/     Frozen, self-contained evaluation packages. Every package
               resolves siblings as fullfile(fileparts(<packageRoot>), name),
               so all packages must stay direct children of campaigns/.
docs/          Theory document, task briefs, cleanup/structure manifests.
```

### Campaign packages (current chain)

| Package | Role |
|---|---|
| `cuk_cap_health_verification` | Base Model-A code, algorithms, rebuilt Simulink models |
| `verification_v2` | Model-B Simscape circuit (`cuk_simscape_circuit_model_v2.slx`) |
| `verification_v21` | Frozen Model-B traces, locked covariance, frozen estimator, CRLB table |
| `verification_v23` | F28379D device-realistic results and supplementary figures |
| `paper_verification_v1` | Frozen 48-blind-case table |
| `paper_verification_v12` | Current observation/estimator factorial (recalibrated k_R) |
| `paper_algorithm_selection_v2` | Current estimator selection campaign |
| `closedloop_dcm_validation` | v0.4 closed-loop and light-load supplements |
| `calibration_closure`, `recalibrated_campaign` | k_R provenance chain (frozen audit outputs) |

Superseded packages (`paper_verification_v11`, `paper_algorithm_selection_v1`,
`verification_v22`) were removed in the v0.4 cleanup; restore from git
history if a historical audit must be re-run
(`docs/REPO_CLEANUP_MANIFEST_V04.md`).

## Versioning convention for future optimization rounds

1. **Manuscript**: edit `manuscript/` in place. Each round adds one
   `manuscript/audits/Vxx_..._CHANGELOG.md`, keeps the 16 frozen quantities in
   `SCIENTIFIC_CHECKSUM_V031.csv` untouched (or re-audits them
   deliberately), drops a versioned PDF snapshot into
   `manuscript/releases/` (e.g., `main_v051_current.pdf`; the previous
   snapshot loses its `_current` suffix), and ends with a git tag
   `manuscript-vX.Y`. Sources of every historical version live in git
   history; `releases/` exists so versions can be compared without git
   archaeology.
2. **New evidence**: never edit a frozen campaign. Add a NEW package
   `campaigns/<topic>_vN/` that reads frozen inputs from its siblings and
   writes its own `results/tables` + `results/figures`. Manuscript figures
   are then redrawn from those frozen CSVs by a script in
   `manuscript/figures/`.
3. **Traceability**: every new figure/number gets a row in
   `manuscript/source_traceability/` (FIGURE_SOURCE_MAP, claim/parameter
   matrices) pointing at a `campaigns/...` CSV.
4. Large regenerable `.mat` workspaces stay out of git (see `.gitignore`);
   run scripts rebuild them.

## Build

```powershell
# manuscript (TeX Live 2025)
$env:Path = "D:\TOOLS\texlive\texlive\2025\bin\windows;" + $env:Path
cd manuscript; latexmk -pdf -outdir=build main.tex; copy build\main.pdf main.pdf
```

MATLAB R2023b regenerates campaign results via each package's
`scripts/run_*_all.m` / `run_*.m` entry point.
