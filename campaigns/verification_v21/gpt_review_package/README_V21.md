# Verification v2.1 — Theory–Simulation Closure

This directory closes the sampling, analog-chain, parasitic-model and
estimator-formulation inconsistencies found in `verification_v2`. The v1 and
v2 directories are read-only inputs.

The final candidate is the **Topology-Synchronous Structured LTV Kalman
Estimator (TS-SLTVKE)**. It uses normalized state `x=[vC, Cb/C, ESR]'`,
disjoint raw-data policies, conditional voltage pseudo-measurements, ordinary
sequential scalar Kalman/Joseph updates, and covariance terms derived from the
same voltage/current samples used to construct each observation. Process noise
is a continuous-time spectral density applied as `Qc*delta_t`.

Run `scripts/run_v21_all.m` from MATLAB R2023b to reproduce the package.
All generated tables and plots are stored under `results/`; the fast audit is
`scripts/validate_v21_outputs.m`.

Current outcome: the simulation formulation is frozen as a bench candidate,
but the full hardware/health claim is not. The minimum supported candidate is
1.6 MS/s/channel, simultaneous 16-bit, second-order 2 MHz voltage / 1 MHz
current AFE. The recommended first prototype is 5 MS/s/channel. Worst-case
Model B timing support is 50 ns, and Model A-P failed to replace Model B.

Primary review entry points are `RESULT_V21_FOR_CHATGPT.md`,
`THEORY_CLOSURE_V21.md`, and `result_metrics_v21.csv`.
