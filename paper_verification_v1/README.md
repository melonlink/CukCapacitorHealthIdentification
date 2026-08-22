# Paper Verification v1

Decision: `PAPER_READY_WITH_MINOR_GAPS`.

Run `scripts/run_paper_verification_v1.m` in MATLAB R2023b. The entry regenerates every mandatory CSV, twelve PNG figures, the result reports, a MAT audit workspace, and `logs/audit_paper_verification_v1.txt`.

The frozen implementation in `../verification_v21/algorithms/structured_ltv_estimator_v21.m` is not edited. The entry explicitly loads 45 frozen Model-B traces from `../verification_v21/results/raw/modelB_edge_traces_v21.mat`, writes their traceability table, and uses their current/edge-slope statistics with frozen v2.3 F28379D noise/timing budgets for the high-volume unified observation comparison.

Primary protocol: `BASELINE_PROTOCOL.md`. Literature evidence: `literature/`. Locked tuning: `baselines/LOCKED_HYPERPARAMETERS.csv`. Paper decision: `PAPER_VERIFICATION_RESULT.md`.
