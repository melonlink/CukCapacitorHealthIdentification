# Frozen baseline protocol

## Pre-registered choices

- B0: timestamp-fair closed-form edge/charge estimator.
- B1: conventional projected RLS on `theta=[1/C,r]`.
- B2: augmented-state EKF on `[vC,C,r]` with analytic Jacobians.
- B3: **Dual EKF**, chosen before blind-test execution. It is not replaced by a UKF based on outcome.
- B4: **Cuk-adapted wavelet-KF baseline** using a one-level Haar decomposition and Kalman parameter update. It is not called an exact reproduction.
- B5: not executed. The public NPC spectral equations do not provide a unique fair Cuk adaptation, and B1 already represents the transferable RLS core.
- Proposed: frozen TS-SLTVKE behavior; this paper package does not alter `verification_v21/algorithms/structured_ltv_estimator_v21.m`.

## Data split and anti-cherry-picking rule

Training cases use seeds 11001–11012 and are used only to lock numerical hyperparameters. Blind cases use seeds 21001 onward. All methods receive the same case identifiers, observation samples, initialization factors, timestamps, noise realization, and validity flags. Every method/case row is written, including saturation or failure rows. A failed estimate is not deleted; its finite projected terminal estimate and `failure_flag` are retained.

## Blind design

The blind design contains 48 stratified operating/health points spanning:

- `Vin={19.2,24,28.8} V`;
- `D={0.30,0.40,0.55,0.65}`;
- low-margin, nominal, and high-load CCM;
- `C/C0={0.8,0.9,1.0}` and `ESR/ESR0={1,1.5,2}`.

Each point is evaluated under four noise profiles and four residual-skew values `{0,20,50,100} ns`. Dynamic scenarios cover a 25% to 75% load step, `C0 -> 0.8 C0`, and `r0 -> 2 r0`.

## Equal resources

The sensor-fair comparison uses only `vT`, `i1`, `i2`, PWM state, and timestamps. No method receives truth after initialization. Initial factors are deterministic draws from `C0/Ctrue in [0.7,1.3]` and `r0/rtrue in [0.5,1.5]` shared across methods.

The method-native requirements are documented in the literature matrix but are not mixed with the primary sensor-fair numerical ranking.

## Unified observation dataset

The primary batch is a unified switching observation dataset derived from 45 frozen Model-B switching traces in `verification_v21/results/raw/modelB_edge_traces_v21.mat`, the validated Cuk equations, and frozen v2.3 F28379D acquisition budgets. The entry script loads those traces, exports `table_modelB_anchor_traceability.csv`, and uses their current and edge-slope statistics. The dataset preserves the edge, charge, terminal-voltage, excitation, noise, skew, and gate channels consumed by the estimators. It is not presented as 48 separate Simscape hardware models.

## Locked evaluation

After `LOCKED_HYPERPARAMETERS.csv` is written, the entry script only reads it. Per-case retuning is prohibited. Primary accuracy is final-window MAPE; p50, p95, maximum, bias, variance, convergence, saturation, divergence, and compute counts are reported.
