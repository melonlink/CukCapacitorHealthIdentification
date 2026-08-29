# SOTA comparison

## Outcome

The common blind set is calibrated from 45 frozen Model-B switching traces and contains 48 stratified physical cases, four noise profiles, four residual-skew levels, and six algorithms, for 4608 retained algorithm rows. No failed or saturated row is removed.

TS-SLTVKE achieved mean C MAPE 0.301% and mean ESR MAPE 0.577%; the corresponding p95 values are 1.116% and 2.134%. The lowest mean C error was produced by B3 Dual EKF and the lowest mean ESR error by B1 RLS. This is the task-defined Case C: ordinary integral RLS and Dual EKF are numerically competitive or superior on the static unified dataset. The paper must therefore claim topology-specific observation structure, gating, interpretability, and convergence behavior rather than universal accuracy SOTA. TS-SLTVKE retained 0.000% divergence.

B4 is a Cuk-adapted wavelet-KF baseline, not an exact reproduction. B5 was pre-declared unsupported for a unique fair spectral migration.

## Fairness

All methods used identical observation rows, seeds, initialization factors, sensors, timestamps, projection ranges, and a locked tuning file. Method-native extra injection/sensor requirements are reported only in the literature matrix.
