# Paper Verification v1 result

## 1. Executive Decision

`PAPER_READY_WITH_MINOR_GAPS`

The simulation/theory package passes its reproducibility audit. Minor gaps are reserved for hardware, temperature normalization, and a final subscription-database novelty search.

## 2. Novelty Boundary

The defensible novelty is the combined Cuk-specific bidirectional excitation, physically separated timestamp-edge/charge observations, and structured disjoint multi-rate estimator. Generic online C/ESR, inherent-signal, Kalman, RLS, wavelet, and Cuk diagnosis claims are not firsts.

## 3. SOTA Baseline

TS-SLTVKE blind means: C 0.301%; ESR 0.577%. B1 RLS and B3 Dual EKF are better on important static accuracy aggregates. This is Case C, so the principal defensible value is the Cuk-specific decoupled observation/gating framework and fast structured convergence, not a universal accuracy or complexity win.

## 4. Ablation

A0 to A6 mean C MAPE: 0.394% to 0.170%; ESR MAPE: 3.807% to 3.101%. A1 is the static ESR optimum, whereas A5/A6 are the C optima. A2/A3 contain negative aggregate gains, A4 primarily repairs CI consistency, and A6 adds calibration/gating/projection protection. The complete stack is not justified as necessary by static accuracy alone.

## 5. Theory

Proposition 1 is a full rank/information proof under finite-window PE. Proposition 2 is an estimator-consistent mean-square boundedness proof sketch based on bounded information recursion, process/noise bounds, and compact projection. Global asymptotic convergence is not claimed.

## 6. Persistent Excitation

The weakest scanned information is `mu_C=1.004e+04`, `mu_R=3.473e+06`; low-margin CCM is the limiting regime and activates freeze logic when thresholds fail.

## 7. Complexity

TS-SLTVKE uses scalar sequential inversions, 46 multiplications/update, 31 stored scalars, and an estimated 2.12 us/update on the frozen F28379D budget.

## 8. Final Simulation Claims

The authors may report the 45-trace frozen Model-B anchor set, retained 48 x 4 x 4 blind matrix, p50/p95/max tables, A0-A6 gains, inverse PE-variance relationship, and scalar-update complexity. These are Model-B-trace-derived unified-observation simulation claims, not hardware measurements.

## 9. Limitations

- CCM only; DCM is detect/freeze.
- ESR remains temperature- and frequency-dependent; normalization is pending.
- Hardware experiment is pending.
- Physical ringing and final analog-front-end behavior require bench confirmation.

## 10. Journal Readiness

- IEEE TPEL: technically aligned, but hardware is normally important for the strongest version.
- IEEE TIE: aligned after embedded/hardware validation.
- IEEE JESTPE: good topical fit with hardware extension.
- IET Power Electronics: simulation manuscript is close, hardware still strengthens it.
- IEEE Access: simulation/theory package is broadly ready after manuscript assembly.

No acceptance probability is implied.

## 11. Hardware Dependency

Identifiability, the finite-window covariance argument, algorithmic comparison on the common dataset, ablation, and operation counts do not logically depend on new hardware. Absolute ADC/AFE error, ringing tolerance, temperature compensation, and execution timing must be confirmed on hardware.
