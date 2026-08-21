# Baseline Cliff Reproduction

## Result

**Gate 1: PASS — sample association artifact.** The v1 cliff aligns with an integer delayed-sample/source-state transition while `rank(Phi)=2` remains.

- Model A: Vin=24.0 V, D=0.40, fs=50 kHz.
- Zero-offset raw edge ESR MAPE: 0.153496%.
- Maximum pre-/post-projection ESR MAPE: 99.4744% / 90%.
- `rank(Phi)` remained 2 for all 15 offsets.

## Required Answers

1. The error jumps when the integer source index changes.
2. Projection explains the exact 90% lower-bound plateau, but not the underlying observation failure.
3. The pre-projection columns preserve the unconstrained C/ESR estimates; see `results/tables/table_v1_edge_assignment_diagnostics.csv`.
4. `rank(Phi)=2` throughout.
5. The cliff is an incorrectly constructed adjacent-edge observation, not a loss of structural C–ESR identifiability.
