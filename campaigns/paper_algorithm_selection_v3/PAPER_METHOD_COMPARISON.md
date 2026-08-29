# Paper method comparison

## 1. Static estimation

On the frozen 48 x 4 x 4 O1 blind matrix, TS-D-RLS achieved C/ESR mean MAPE 0.3727%/0.2233% and 13.21-cycle convergence. TS-SLTVKE achieved 0.3011%/0.6446% and 33.09 cycles; Dual EKF achieved 0.3043%/1.1938% and 40.58 cycles. Native and Equal-Report use identical estimates; Equal-Report changes only the visible 20.48 ms cadence.

## 2. Noise and timing robustness

Low, nominal, high, and F28379D-realistic noise were retained with 0/20/50/100 ns residual mismatch. The complete paired summaries are in `table_algorithm_noise_timing.csv`; no timing-failure row was removed.

## 3. Abrupt parameter stress tests

The frozen 257-post-cycle TS-SLTVKE failures were retained: C-step error 19.2911% and ESR-step error 49.9384%. These discontinuities are stress tests, not claimed physical aging rates.

## 4. Slow degradation tracking

- 0.1 s: RLS combined nRMSE 0.1161, TS-SLTVKE 0.2160; normalized lag 8.053% versus 22.027%; dominance result: TS-D-RLS.
- 1.0 s: RLS combined nRMSE 0.0163, TS-SLTVKE 0.0454; normalized lag 1.360% versus 3.537%; dominance result: TS-D-RLS.
- 10.0 s: RLS combined nRMSE 0.0160, TS-SLTVKE 0.0456; normalized lag 1.752% versus 4.492%; dominance result: TS-D-RLS.
- 100.0 s: RLS combined nRMSE 0.0213, TS-SLTVKE 0.0477; normalized lag 2.827% versus 4.868%; dominance result: TS-D-RLS.

The main long ramps use frozen trace-derived O1 sufficient statistics; the 0.1 s cases are cross-checked with every switching pair from the frozen Model-A equations. Neither label means hardware data.

## 5. Operating-point transient immunity

Health was held constant during load, Vin, and duty transitions. Peak false-health, recovery, alarm count, and NIS rejection are reported without deleting failures.

## 6. Computational complexity

Per accepted observation, TS-D-RLS/TS-SLTVKE/Dual EKF require 28/46/62 multiplications and 1.36/2.12/3.05 us on the frozen F28379D arithmetic model. Per-frame values use exactly 1024 observations.

## 7. Uncertainty reporting

RLS uncertainty is an auxiliary residual-weighted information/sandwich diagnostic and does not alter the estimate. TS-SLTVKE and Dual EKF use their frozen covariance readouts.

## 8. Final estimator choice

**PRIMARY_TS_SRKE**. The selected token also identifies the primary realization. The decision uses scientific dominance and Pareto evidence, not an arbitrary weighted score.

Paired bootstrap used 10000 resamples; 15 metric/mode rows were retained.
