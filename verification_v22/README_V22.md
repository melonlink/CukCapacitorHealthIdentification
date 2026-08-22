# Verification v2.2 — DSP Native ADC Decision

This directory is the independent v2.2 verification layer. The v1, v2, and
v2.1 directories are read-only inputs.

## Decision

`NATIVE_HIGH_RESOLUTION_MODE_REQUIRED`

The repository does not identify a target DSP part number, so every native
ADC property in this study is a parameterized reference, not a datasheet
claim (`TARGET_DSP_NOT_FIXED`). Under the locked reference profiles:

- native 12-bit / 4 MS/s / ENOB 10.5 fails the C accuracy gate even with the
  dual-range Vedge channel and 1024-cycle fusion;
- native 16-bit / 1.1 MS/s / ENOB 13.5 with V2, PWM-triggered sampling,
  20 A current range, and Cal3 passes all 36 point-accuracy blind cases;
- confidence calibration remains partial and must be closed on real hardware.

## Reproduce

Run in MATLAB R2023b from the repository root:

```matlab
addpath(genpath(fullfile(pwd,"verification_v22")));
run_v22_all(fullfile(pwd,"verification_v22"));
validate_v22_outputs(fullfile(pwd,"verification_v22"));
```

The pipeline reruns four Model B baselines and writes all tables, figures, and
raw MAT data under `results/`. The ADC Monte Carlo is an observation-layer
study around the locked v2.1 TS-SLTVKE formulation: Model B supplies edge
current, safe-window charge, terminal voltage, and edge slope; the ADC/AFE
layer then applies quantization, ENOB, calibration, timing, and multi-cycle
fusion. It is not a claim that every Monte Carlo seed is a full Simscape run.

## Main outputs

- `TARGET_DSP_ADC_PROFILE.md`
- `DSP_ADC_DECISION.md`
- `RESULT_V22_FOR_CHATGPT.md`
- `results/tables/` — 12 mandatory tables plus Model B baseline table
- `results/figures/` — 12 mandatory PNG and matching FIG files
- `tests/v22PipelineTest.m` — class-based regression tests
- `gpt_review_package/` — compact review bundle
