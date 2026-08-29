# Closed-Loop and Light-Load Supplement (v0.4)

Supplementary evaluation package supporting manuscript Sections VII-H and
VII-I. Reuses the locked TS-D-RLS hyperparameters, gates, and projection
bounds on the ideal-parasitic Model-A plant (Appendix A equations,
transfer-capacitor ESR retained). No frozen artifact is modified.

## Contents

- `scripts/simulate_cuk_cycles.m` — cycle-resolved Model-A simulator
  (open- or closed-loop duty), per-cycle O1 edge/charge features with
  timestamp-reconstructed fits, predeclared gates, and the locked scalar
  RLS recursions (`lambda = 0.9975`, `P0 = 1000`, `I_Sigma,gate = 0.12 A`,
  projection bounds `[0.65, 1.35] C_b` / `[0.35, 2.50] r_b`).
- `scripts/run_closedloop_validation.m` — commissions `k_R` under feedback
  on a nominal-health calibration case (`k_R^cl = 0.998665`, 600 accepted
  edges), then runs three blind cases with a 1.45x load step, a +20%
  input-voltage step, and a 16-to-12-V reference step under a discrete PI
  voltage regulator (`Kp = 3e-4`, `Ki = 2.5`, 0.5% duty quantization,
  deliberately low bandwidth). Writes
  `results/tables/table_closedloop_validation.csv` and manuscript figure
  `fig_closedloop.pdf`.
- `scripts/run_lightload_sweep.m` — fixed-duty availability sweep,
  R = 10..150 Ohm (100% down to 6.7% load), steady-state window after the
  startup L-C1 resonance decays. Writes
  `results/tables/table_lightload_sweep.csv` and manuscript figure
  `fig_lightload.pdf`.

## Key results (seeds 41001/42001-42003/43001-43012)

| Case | Tail C err | Tail ESR err | Conv | Post-step max C/ESR |
|---|---|---|---|---|
| CL-1 load step  | 0.068% | 0.111% | 3 | 0.410% / 0.102% |
| CL-2 Vin step   | 0.110% | 0.065% | 7 | 0.367% / 0.102% |
| CL-3 Vref step  | 0.222% | 0.013% | 6 | 0.370% / 0.094% |

Light load: steady-state cycle acceptance 100% down to 20% load;
68.8/49.8/36.1/9.9% at 16.7/14.3/12.5/10.0% load; zero at and below 8.3%
load. Endpoint errors over accepted rows <= 1.4% down to 10% load.

## Boundaries

- One noise seed per case; a single simple PI regulator; not a
  controller-design study.
- Model A flags would-be DCM cycles via the combined-current gate but does
  not emulate DCM conduction; the sweep quantifies availability only.
- The closed-loop `k_R` differs from the paper's measurement-chain value
  (0.9772) because this supplement uses ideal 10-MS/s sampling of the
  plant rather than the F28379D acquisition chain.
