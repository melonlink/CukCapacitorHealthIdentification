# k_R recalibration impact and resolution

Date: 2026-08-25

The reproducible simulation-calibration value is

    k_R,new = 0.97719802594550731,

and the superseded campaign center was

    k_R,old = 0.982.

Their relative difference is `-0.4889993946%`. At fixed edge voltage and
current, the exact inverse-scale ESR effect is `+0.4914023491%`; this was the
pre-rerun expectation, not a substitute for executing the campaign.

## Full rerun outcome

The project authorized the new coefficient and regenerated all affected ESR
evidence. Key changes were:

| Metric | Old | Recalibrated |
|---|---:|---:|
| TS-D-RLS static ESR mean MAPE (%) | 0.222188 | 0.223280 |
| TS-SLTVKE static ESR mean MAPE (%) | 0.642831 | 0.644628 |
| Dual EKF static ESR mean MAPE (%) | 1.192250 | 1.193810 |
| TS-D-RLS static ESR p95 (%) | 0.696774 | 0.700200 |
| TS-SLTVKE joint CI coverage (%) | 89.0625 | 88.9323 |
| TS-D-RLS load-step false ESR (%) | 4.459230 | 4.467956 |

Across the 66 method/metric cells in the machine-readable final-selection
table, 25 changed and 41 remained identical. The final estimator decision stayed
`DUAL_REALIZATION`. PE lower bounds, complexity values, divergence counts, and
maximum reliable degradation-rate classifications were unchanged.

Complete differences are in
`recalibrated_campaign/results/table_algorithm_metric_deltas.csv` and
`table_manuscript_numeric_updates.csv`.

## Bounded sensitivity retained

The earlier 35-row, no-retuning TS-D-RLS sensitivity remains useful for
calibration-uncertainty interpretation. Mean endpoint ESR bias ranged from
`+1.0225%` at `-1%` assumed-gain error to `-0.9779%` at `+1%`; the largest
absolute case was `1.170818%`. It was not used to tune or replace the full rerun.
