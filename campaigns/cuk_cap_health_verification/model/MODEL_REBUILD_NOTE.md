# Model Rebuild Note (2026-08-25)

## Problem found

The two v1 Simulink files committed in `74e5a35` were **empty models**
(root system only, zero blocks):

- `cuk_switched_equation_model.slx`
- `cuk_simscape_circuit_model.slx`

`scripts/run_simulink_model_a.m` and `scripts/run_simscape_model_b.m`
therefore could not reproduce any logged signals, contradicting the v1
result documents. The paper data chain was unaffected (it uses the v2
Simscape model and frozen v2.1 traces), but the public-reproducibility
claim was broken.

## Fix

1. `cuk_switched_equation_model.slx` was rebuilt programmatically by
   `build_cuk_switched_equation_model.m` from Simulink primitives
   implementing the Appendix-A switched equations (transfer-capacitor ESR
   retained, other parasitics zero). PWM is a sample-based pulse source on
   the `Ts/200` grid, so the topology state is held constant across each
   RK4 major step, matching the equation-level convention. Logged signals:
   `u, i1, i2, iC, vC, vT, vo`.
2. `cuk_simscape_circuit_model.slx` was restored as a copy of the verified
   `verification_v2/model/cuk_simscape_circuit_model_v2.slx` (the v2 model
   does not reference `LESL` internally; that term is applied analytically
   in post-processing by `run_modelB_v21.m`, so the v1 runner interface is
   unchanged).

## Validation

- Simulink Model A vs. a grid-exact MATLAB RK4 of the same equations:
  `u` mismatches 0; max state differences `i1 5.0e-14`, `i2 6.4e-14`,
  `vC 1.3e-13`, `vo 4.6e-14` over 0.1 s (machine precision).
- `run_simscape_model_b.m` runs the restored circuit: 6 logged signals,
  steady-state `vo` mean 15.79 V, matching the v2 baseline.

## Known discrepancy in the frozen reference (documented, not fixed)

`simulate_switched_equation.m` derives `u` from `mod(t, Ts) < D*Ts` in
floating point. Accumulated rounding makes ~46% of switching periods carry
one extra on-grid on-sample (+0.23% effective duty), which biases its
steady-state `vo` mean by about +0.6% relative to the exact-duty
trajectory. The rebuilt Simulink model is jitter-free. This has no effect
on the paper's identification claims: the estimator features use the
actual per-sample `u` and timestamps, not the nominal duty. The frozen
file is deliberately left byte-identical.
