# k_R calibration provenance

Date: 2026-08-25

Final classification: `EXACT_REPRODUCTION_ADOPTED`

Calibration-provenance status: closed. The historical `0.982` campaign remains
archived but is superseded by independently regenerated campaigns using the
reproducible full-precision value.

## Simulation-calibration chain

    planted simulation ESR: p.ESR = 0.05 ohm
            |
            v
    four declared profiles; seeds 11901--11904
            |
            v
    timestamp-reconstructed z_R and fitted I_Sigma
            |
            v
    kappa_m = z_R,m / (I_Sigma,m * r_C,ref,m)
            |
            v
    588 finite ratios; NaN omission only; no weights
            |
            v
    unweighted pooled median
            |
            v
    k_R = 0.97719802594550731
            |
            v
    exact match to locked.edgeGainCorrection
            |
            v
    paper_verification_v12 and paper_algorithm_selection_v2
            |
            v
    casewise-fixed h_R; no blind update of k_R

## Arrow-by-arrow source map

| Stage | Source | Function/variable |
|---|---|---|
| Reference ESR | `cuk_cap_health_verification/model/model_parameters.m` | `model_parameters`, `p.ESR` |
| Profiles and seeds | `verification_v21/covariance/train_v21_covariance.m` | `training_cases`, `cfg.seed=11900+c` |
| Model A inputs | `cuk_cap_health_verification/model/simulate_switched_equation.m` | profiles 1--3 |
| Model B input | `verification_v21/model/run_modelB_v21.m` | profile 4, `LESL=10e-9` |
| Measurement chain | `verification_v21/sampling/v21_measurement_chain.m` | measured voltage/current and edge times |
| Edge features | `verification_v2/timing/v2_edge_estimates.m` | `y_R_V`, `i_sum_A`, `ESR_raw_Ohm` |
| Per-edge ratio | `verification_v21/covariance/train_v21_covariance.m` | `ESR_raw_Ohm/params{c}.ESR` |
| Aggregation | same | `median(ratios,"omitnan")` |
| Archived output | `verification_v21/results/raw/locked_covariance_v21.mat` | `locked.edgeGainCorrection` |
| Independent reproduction | `calibration_closure/scripts/reproduce_kR_calibration.m` | 588-row reconstruction and source manifest |
| Recalibrated factorial | `paper_verification_v12/scripts/paper_verification_v12_engine.m` | `cfg.kRCalibration`, `obs.kRtrue` |
| Recalibrated dynamic streams | `paper_algorithm_selection_v2/scripts/paper_algorithm_selection_v2_engine.m` | `cfg.kRCalibration=0.97719802594550731` |
| Shared regressor | `paper_algorithm_selection_v2/datasets/generate_frozen_o1_stream.m` | `hR=kR.*iSum` |
| Estimator consumers | `paper_algorithm_selection_v2/algorithms/run_locked_o1_estimator.m` | both TS-D-RLS and TS-SLTVKE consume identical `obs.hR` |

The reference classification is `SIMULATION_REFERENCE_TRUTH`. No impedance
analyzer, LCR-meter, or hardware reference measurement is claimed.

## Historical mismatch and authorized resolution

The archived Paper Verification v1.1 and Algorithm Selection v1 packages used a
hard-coded `0.982` center. That value was not a rounding of the reproducible
simulation-calibration output and was classified in v0.26 as `KR_VERSION_DRIFT`.

The user authorized adoption of `0.97719802594550731` on 2026-08-25. The
resolution was implemented by creating new packages, not by overwriting the
historical results:

- `paper_verification_v12`: 4608-row observation/estimator factorial, 10,000
  paired bootstrap replicates, dynamic checks, PE/covariance checks, and
  projection study;
- `paper_algorithm_selection_v2`: static, abrupt, ramp, operating-transient,
  noise/timing, uncertainty, complexity, bootstrap, and final-selection tables;
- `recalibrated_campaign`: deterministic old/new key alignment, numerical delta
  tables, invariance checks, and a manuscript-facing update list.

Both rerun packages passed their built-in audits. The estimator checksum,
hyperparameters, cases, seeds, gates, and declared `0.006` casewise amplitude
were unchanged. The final decision remained `DUAL_REALIZATION`.

## Exact numerical closure

- Reproduced coefficient: `0.97719802594550731`
- Archived v2.1 locked coefficient: `0.97719802594550731`
- Absolute error: `0`
- Adopted v1.2/v2 campaign center: `0.97719802594550731`
- Rounded manuscript display when three digits are used: `0.977`
- Historical superseded center: `0.982`

## Role of 0.957654

The evaluated proof constant remains

    kR_min = 0.98 * 0.97719802594550731
           = 0.9576540654265971.

It is a conservative evaluated-envelope lower bound, not the online or
casewise campaign center. The PE tables were numerically invariant in the rerun.

## Train/blind separation

- Calibration profiles are declared and aggregated before blind processing.
- The blind campaigns receive a fixed casewise coefficient and never infer it
  from blind residuals.
- The full rerun changed the calibration center only; no result-conditioned
  retuning or hidden post-blind calibration was introduced.
