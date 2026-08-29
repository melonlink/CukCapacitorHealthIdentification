# Run v2.1 Audit

- Environment: MATLAB/Simulink R2023b through configured MATLAB MCP.
- Branch: `verification-v21`.
- v1/v2 policy: read only; Model B `.slx` not structurally edited.
- Model B invocation: `Simulink.SimulationInput` for every parameterized run.
- Sampling theory: 5,544 rows and 64 phases/combination.
- Edge theory: 140 rows, 12 Monte Carlo seeds/valid combination.
- Estimator covariance: trained on nominal, high-D, noisy, and Model B nominal;
  locked before blind seeds.
- Statistical validation: six scenarios × 100 seeds = 600 seed-level rows.
- Joint ADC/AFE: 1,344 nominal matrix rows + 16 asynchronous fsw perturbations.
- Model B parasitic extraction: 45 requested ESL/load/duty rows; DCM requests
  replaced by nearest tested CCM load and recorded.
- Timing: 324 condition rows, 20 seeds/row, random delay sign.
- Health blind set: 36 stratified CCM points, no blind retuning.
- CRLB: 15 sensitivity points, 20 seeds/point.
- Optimizations retained: explicit ADC current full-scale/saturation metric;
  continuous-time process noise; training-locked edge gain; health-envelope
  ESR prior; final-NEES-only option for large DOE without changing filtering.
- Known negative results retained: 0.8 MS/s geometry failure; opposed relative
  400 ns failure; Model A-P rejection; five ESR=2× blind CI/NEES failures.

