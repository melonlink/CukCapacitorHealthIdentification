# Hybrid Estimator Prototype (v1)

Feasibility prototype for a method-level synthesis of the paper's two
realizations: the TS-SLTVKE Kalman backbone (calibrated covariance) plus a
per-direction two-sided CUSUM supervisor on the accepted AND gate-rejected
normalized innovations; an alarm resets that direction's covariance to its
initialization value, restoring gain after abrupt health changes. This
directly targets the manuscript's retained limitation 6 tradeoff and the
Sec. IX-B "adaptive change detector" future-work sentence.

Prototype scope (NOT a frozen paper campaign): Model-A plant, ideal
10-MS/s sampling, nominal noise (1 mV / 0.5 mA), locked gates and bounds;
10 seeds static, 1 seed per dynamic scenario. Supervisor constants
predeclared: drift 0.5, threshold 10, clip 6.

## Results (identical O1 feature streams for all three estimators)

| Scenario | Metric | TS-D-RLS | KF (TS-SLTVKE kernel) | Supervised hybrid |
|---|---|---|---|---|
| Static (10 seeds) | C / ESR tail err | 0.154 / 0.012 % | 0.118 / 0.109 % | 0.118 / 0.109 % (= KF; 0 resets) |
| Static | joint 95 % coverage | (uncalibrated) | 98.1 % | 98.1 % |
| C step -20 % | recovery / tail err | 531 cyc / 0.82 % | never / 21.4 % | **7 cyc / 0.15 %** (1 reset) |
| ESR step 2x | recovery / tail err | 871 cyc / 2.45 % | never / 50.1 % | **2 cyc / 0.22 %** (1 reset) |
| 0.1-s joint ramp | nRMSE C / ESR | 0.194 / 0.128 | 0.337 / 0.0042 | **0.098** / 0.0042 (6 resets) |

Reading: static behavior is bit-identical to the Kalman parent (supervisor
silent); abrupt recovery beats both parents by two orders of magnitude and
cures the Kalman stuck-rejection failure; hardest-ramp tracking beats both
parents in C while keeping the Kalman ESR advantage. Coverage during
transitions/ramps degrades (84 % / 30 %) because the noise-only intervals
do not model drift bias - an honest boundary to report, not hide.

Cost: Kalman update + ~6 operations per row for the supervisor.

## Status and boundaries

- Components (CUSUM, covariance resetting) are classical; any manuscript
  claim must position novelty at the construction level (direction-specific
  supervision on gated topology-synchronous rows), consistent with the
  paper's discipline.
- The KF column is a scalar two-direction re-implementation of the
  TS-SLTVKE point behavior, not the frozen 3-state code.
- Before any manuscript integration, the hybrid must run through the full
  frozen blind protocol (48 cases x noise x skew, bootstrap) as a new
  campaign; these prototype numbers must not be quoted as paper results.

Scripts: `simulate_cuk_features.m` (feature-only Model-A run, health steps
and ramps), `run_estimator_on_features.m` (three estimators on one stream),
`run_hybrid_prototype.m` (calibration + S1/S2/S3, writes
`results/tables/table_hybrid_prototype.csv`).

## STATUS (2026-08-26)
Prototype superseded: the paper-grade evaluation lives in campaigns/paper_verification_v13 and campaigns/paper_algorithm_selection_v3, and the final supervisor is the two-time-scale mean-shift detector, NOT this package's kappa=0.5 CUSUM. Keep for design-history provenance; do not quote these numbers.

