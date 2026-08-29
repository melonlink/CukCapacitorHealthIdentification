# Estimator Formulation Audit

## v2 code findings

The audit of `verification_v2/algorithms/tr_ts_ltvkf.m` found:

1. The stable terminal-voltage model is coded as `H=[1,0,iC]`.
2. The update then zeros the C/ESR Kalman-gain rows. This is an engineering
   gain mask; it is not the unconstrained Kalman solution for that H.
3. C and ESR pseudo measurements are applied as sequential scalar updates.
4. The v2 stable-voltage mask and charge-window construction can use the same
   raw ADC samples.
5. Stable samples can also approach data used by edge extrapolation.
6. The sequential covariance recursion treats those constructed measurements
   as independent and carries no raw-sample cross covariance.
7. Consequently the overlapping policy can double count information even when
   its point estimate looks accurate.

The masked implementation is closest to an ad-hoc Schmidt-like/consider
estimator, but it is not a complete Schmidt filter: no formal consider-state
cross-covariance recursion is defined. It should therefore be described as the
"v2 masked-gain implementation", not as a standard KF.

## Compared variants

`structured_ltv_estimator_v21.m` implements:

- `masked_v2`: physical terminal-voltage H with C/ESR gain rows forced to zero;
- `full_ltv`: the same H with the standard unconstrained gain;
- `conditional_structured`: (z_V=v_T-\hat r i_C), (H_V=[1,0,0]), full
  Joseph updates, and explicit uncertainty from ESR and current.

Each is run with disjoint and overlapping raw-data policies. The overlapping
case is retained only as an audit experiment. The selected algorithm is
`conditional_structured + disjoint`.

## Final name

The implementation is most accurately named **Topology-Synchronous Structured
LTV Kalman Estimator (TS-SLTVKE)**. It is topology synchronous, timestamp aware,
multi-rate, and uses standard scalar Kalman/Joseph recursions after constructing
direction-specific conditional observations. The older TR-TS-LTVKF name is
retained only when referring to v2.

## Remaining statistical qualification

Disjoint index assignment removes same-sample reuse but not analog-filter
temporal correlation. This is why v2.1 uses both innovation consistency and
truth-based NEES/coverage. A correlated batch measurement model would be needed
before claiming an exact maximum-likelihood covariance under the full AFE
process.

