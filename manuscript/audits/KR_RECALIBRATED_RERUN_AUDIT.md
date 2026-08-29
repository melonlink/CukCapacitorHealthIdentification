# Recalibrated k_R campaign audit

Date: 2026-08-25

Adopted center: `k_R=0.97719802594550731`

Decision source: explicit project authorization to replace the historical
`0.982` center and rerun every affected ESR result.

## Version preservation

- Historical `paper_verification_v11`, `paper_algorithm_selection_v1`,
  `manuscript_v026`, and all earlier artifacts were not overwritten.
- Recalibrated evidence was generated in `paper_verification_v12` and
  `paper_algorithm_selection_v2`.
- Manuscript changes were isolated in `manuscript_v027`.

## Controlled change

The only campaign input intentionally changed was the central calibration value:

    old center = 0.982
    new center = 0.97719802594550731

The following remained fixed:

- `k_R` casewise seed amplitude `0.006`;
- blind cases, noise profiles, residual-skew levels, and random seeds;
- TS-D-RLS, TS-SLTVKE, and Dual EKF update equations;
- RLS forgetting factor, Kalman Q/P0 settings, NIS gate, projection bounds,
  validity gates, and health-report cadence;
- model hierarchy and metric definitions.

The frozen estimator checksum remained
`6B59445898F224C6C070B4E0C3B08E73C7500B5385F912BB058BADBC6AD67225`.

## Paper Verification v1.2

- 4608 factorial rows in six observation/estimator cells;
- 18 paired-bootstrap rows, each using 10,000 replicates;
- 18 dynamic rows;
- 45 physical PE cases and 10 covariance cases;
- 200 projection seeds per state;
- three negative observation effects retained;
- built-in audit result: `AUDIT=PASS`.

The primary contribution remained `OBSERVATION`, and the package-level decision
remained `REOPEN_ALGORITHM`, as expected for the pre-selection factorial stage.

## Algorithm Selection v2

- 6 static rows;
- 18 abrupt-step rows;
- 162 ramp rows and 360 threshold rows;
- 24 operating-transient rows;
- 48 noise/timing rows;
- 7 paired-bootstrap rows;
- 4812 consolidated trace rows;
- built-in audit result: `AUDIT=PASS`.

The final decision remained `DUAL_REALIZATION`: TS-D-RLS is the primary
low-cost realization and TS-SLTVKE the uncertainty-aware extension.

## Old/new numerical audit

`recalibrated_campaign/scripts/compare_kR_rerun.m` sorted all compared tables by
declared unique keys before evaluating differences. It verified row counts and
key equality, retained NaN/Inf semantics, and produced:

- 10 raw-factorial numeric variables with at least one changed row;
- 25 changed and 41 unchanged cells among the 66 machine-readable final
  method/metric cells;
- 88 manuscript-facing update rows, of which 51 changed and 37 were invariant;
- zero changed numeric fields in the PE lower-bound table;
- zero changed numeric fields in the complexity table.

The largest relative change among finite changed final-selection metrics was
`+0.800314%`, for TS-SLTVKE 10-s ESR-ramp nRMSE. No headline conclusion changed.

## Manuscript-facing outcomes

- TS-D-RLS ESR mean MAPE: `0.222188% -> 0.223280%`.
- TS-D-RLS ESR p95: `0.696774% -> 0.700200%`.
- TS-D-RLS mean convergence: `13.1888 -> 13.2109` cycles.
- TS-SLTVKE ESR mean MAPE: `0.642831% -> 0.644628%`.
- Dual EKF ESR mean MAPE: `1.192250% -> 1.193810%`.
- TS-SLTVKE joint 95% coverage: `89.0625% -> 88.9323%`.
- PE minima, covariance bounds, complexity, divergence counts, and the
  device-realistic v2.3 results were unchanged.

## Audit result

`RECALIBRATED_CAMPAIGN_PASS`

The reproducible calibration value has been adopted through a complete,
versioned, no-retuning rerun. No affected ESR result remains sourced from the
superseded `0.982` campaign in manuscript v0.27.
