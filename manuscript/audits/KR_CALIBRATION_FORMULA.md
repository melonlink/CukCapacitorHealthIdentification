# k_R calibration formula

Date: 2026-08-23

## Archived implementation

For edge m, verification_v2/timing/v2_edge_estimates.m computes

    z_R,m = y_R_V = v_minus_V - v_plus_V
    I_Sigma,m = i_sum_A = i1_minus_A + i2_plus_A
    ESR_raw_Ohm,m = z_R,m / I_Sigma,m.

verification_v21/covariance/train_v21_covariance.m then uses the planted simulation reference ESR:

    kappa_m = ESR_raw_Ohm,m / r_C,ref,m
            = z_R,m / (I_Sigma,m * r_C,ref,m).

All per-edge ratios from the four profiles are pooled, and

    k_R(v2.1) = median(kappa_m, "omitnan").

## Inputs

- Four profiles: nominal, high_D, noisy, modelB_parasitic_nominal.
- Seeds: 11901, 11902, 11903, 11904.
- Reference ESR: model_parameters().ESR = 0.05 ohm for every profile.
- Default acquisition: 5-MHz ADC, sample phase 0.37, 0.5-us guard, 2.0-us edge window, timestamped linear fit.
- High-duty/load case: D=0.60, Rload=7.5 ohm.
- Noisy case: 10-mV voltage noise and 5-mA current noise.
- Model-B case: nominal operating point with 10-nH ESL.

## Rejection

The source uses median(ratios,"omitnan"). Therefore:

- NaN ratios are omitted.
- There is no residual threshold, percentile clipping, or explicit outlier rejection.
- Infinite values would not be removed by the stated rule; none occurred in the reproduction.
- All 588 reconstructed ratios were finite and accepted.

## Weighting

No weights are used. This is not LS, WLS, Huber regression, a trimmed mean, or a ratio of sums.

## Aggregation output

| Profile | Ratios | Profile median |
|---|---:|---:|
| nominal | 147 | 0.9770199620981099 |
| high_D | 147 | 0.9771298710947420 |
| noisy | 147 | 0.9712130307401762 |
| modelB_parasitic_nominal | 147 | 0.9783009879572436 |
| pooled | 588 | 0.97719802594550731 |

The pooled value exactly matches verification_v21/results/raw/locked_covariance_v21.mat.

## Rounding and adopted paper-package value

The v2.1 code saves the full double-precision median and has no three-decimal rounding step. Its displayed three-decimal value is 0.977.

The superseded paper_algorithm_selection_v1 package used the unrelated hard-coded center 0.982. After the explicit project decision, paper_verification_v12 and paper_algorithm_selection_v2 both set their campaign center to the reproduced full-precision value 0.97719802594550731. The declared casewise seed amplitude remains 0.006. All affected ESR results were regenerated; no rounding was used to define the adopted center.
