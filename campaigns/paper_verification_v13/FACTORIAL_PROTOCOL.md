# Factorial protocol

## Frozen scope

This package reuses the 48 Paper Verification v1 blind case IDs, four noise profiles, four residual-skew levels, initial factors, condition seeds, Model-B calibration anchors, physical bounds, and training/blind split. The frozen algorithm file is checksum-audited and is not edited.

## Observation factor

- O0 Mixed: physically valid non-decoupled row H=[q/C_b, Delta i_C] from generic within-cycle samples. It retains the raw acquisition-lag contribution and never uses deliberately wrong edge assignment.
- O1 Proposed: odd disjoint updates use the safe-window C-only row; even disjoint updates use timestamp-reconstructed ESR-only edges. Both use the same locked calibration and F28379D budget.

## Estimator factor

- E1: constrained RLS, lambda=0.997500.
- E2: the locked Dual EKF state update with only its parameter row changed by O0/O1.
- E3: mixed Joseph LTV kernel for O0 and frozen TS-SLTVKE update rules for O1.

Each estimator family uses exactly one hyperparameter row for O0 and O1. No per-cell tuning, failed-row deletion, or rank-seeking retuning is allowed. All 10000 bootstrap replicates are paired by case_id, noise_profile, skew_ns, and seed.
