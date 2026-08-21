# Cuk Energy-Transfer Capacitor Health Verification

This directory contains the executable verification package required by
`docs/Codex_Cuk_Capacitor_Health_Verification_Task_v1.0.md`.

The package deliberately separates two models:

- **Model A**: switched state-equation model implemented in MATLAB and Simulink.
- **Model B**: an independently connected Simscape Electrical circuit model.

The batch entry point is `scripts/run_all.m`. Each script adds the project
folders to the MATLAB path, uses deterministic random seeds, writes raw CSV
tables, and exports figures as both PNG and MATLAB FIG files.

Default benchmark: 24 V input, 40% duty, 50 kHz switching, 500 uH inductors,
100 uF transfer capacitor, 50 mOhm ESR, 470 uF output capacitor, and 10 Ohm
load. The output voltage is represented by its positive magnitude.

## Reproduce in MATLAB R2023b

```matlab
projectRoot = "D:/PROJECT/AI_PROJECT/CukCapacitorHealthIdentification/cuk_cap_health_verification";
addpath(genpath(projectRoot));
summaries = run_all(projectRoot);
```

The complete run uses deterministic seeds and can take several minutes. The
human-readable conclusion is in `RESULT_SUMMARY.md`; the stricter audit record
is in `RESULT_FOR_CHATGPT.md`; normalized machine-readable metrics are in
`results/tables/result_metrics.csv`. Raw Monte Carlo rows and MAT workspaces
are retained under `results/` so failed cases remain inspectable.
