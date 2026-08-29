# k_R simulation-calibration trace

Date audited: 2026-08-25

## Archived simulation-calibration implementation

`verification_v21/covariance/train_v21_covariance.m` declares four independent
calibration profiles (`nominal`, `high_D`, `noisy`, and
`modelB_parasitic_nominal`) with seeds 11901--11904. Its reference ESR is the
known planted simulation value `model_parameters().ESR=0.05 ohm`.

For each accepted edge it computes

    kappa_m = edges.ESR_raw_Ohm / params{c}.ESR

and pools all profiles using `median(ratios,"omitnan")`. No weights, trimming,
LS/WLS, Huber loss, or residual rejection are present. The archived output is
`locked.edgeGainCorrection=0.97719802594550731`.

## Independent reproduction

`calibration_closure/scripts/reproduce_kR_calibration.m` re-executed the source
plants, measurement chain, profiles, and seeds. All 588 ratios were finite. The
pooled median was `0.97719802594550731`, exactly equal to the archived lock with
absolute error zero.

## Historical drift

The superseded `paper_verification_v11` and `paper_algorithm_selection_v1`
packages used a separately hard-coded `0.982` center. v0.26 correctly classified
that state as `KR_VERSION_DRIFT`; `0.977198...` does not round to `0.982`.

## Authorized adoption and rerun

On 2026-08-25, the project selected the reproducible value and required all
affected ESR results to be rerun. New versioned packages were created:

- `paper_verification_v12`, with `cfg.kRCalibration=0.97719802594550731`;
- `paper_algorithm_selection_v2`, using the same full-precision center and the
  regenerated v1.2 factorial rows;
- `recalibrated_campaign`, which aligns old/new tables by declared keys and
  records every numerical change needed by the manuscript.

Both estimators consume the same casewise `obs.hR`; the coefficient is never
updated from blind residuals. The `0.006` seed amplitude, random seeds,
estimators, hyperparameters, gates, and comparison matrix were not changed.

Status: `EXACT_REPRODUCTION_ADOPTED`

Release consequence: calibration provenance is closed; the v0.3 main text may
display `0.9772`, while Supplementary/source traceability retain full precision.
