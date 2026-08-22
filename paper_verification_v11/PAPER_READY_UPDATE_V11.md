# Paper-ready update v1.1

## Freeze decision

REOPEN_ALGORITHM

## Contribution wording

The primary supported contribution is the Cuk topology-synchronous charge/edge observation framework. The guarded scalar Joseph LTV kernel is an implementation vehicle, but did not show a broad incremental factorial advantage and failed the two health-step tracking checks. Static accuracy is not claimed to be universally SOTA.

## Factorial core numbers

- E1 RLS: C MAPE 0.3727%, ESR MAPE 0.2222%, p95 1.3265%/0.6981%, convergence 13.19 cycles.
- E2 Dual EKF: C MAPE 0.3043%, ESR MAPE 1.1923%, p95 1.1507%/3.8714%, convergence 40.57 cycles.
- E3 LTV/Joseph: C MAPE 0.3011%, ESR MAPE 0.6428%, p95 1.1173%/2.5035%, convergence 33.04 cycles.

## Blocking dynamic result

O1-E3 did not converge within 257 post-step cycles. Tail C tracking error after C->0.8C was 19.2911%; tail ESR tracking error after ESR->2R was 49.9379%. This triggers REOPEN_ALGORITHM.

## Observation effects

The paired O0-O1 effects, including negative values and CIs that cross zero, are frozen in table_observation_effect_bootstrap.csv.

## Final Proposition 1

Valid CCM physical bounds imply mu_C>=0.217943 and mu_R>=880.008 in the weakest frozen Model-B case; empirical/lower ratios are at least 1.02872 and 1.02334.

## Final Proposition 2

The finite-window recursion has maximum validated fixed points 0.0112191 (C-alpha direction) and 8.82437e-06 (ESR); all numerical sequences satisfy the conservative envelope.

## Final Corollary

Weak charge, weak edge current, DCM, invalid edge, or failed NIS gate removes the current PE lower bound; parameter updates freeze and contraction resumes after valid CCM observations recur.

## Final limitations

- Finite-window, local, conditional result; no global nonlinear asymptotic convergence claim.
- Projection remains a safety constraint for invalid/non-PE data.
- Some cell-level accuracy effects may favor O0, RLS, or Dual EKF.
- Hardware ringing, temperature drift, and outliers require experimental confirmation.
- No large-scale SOTA search or rank-seeking retuning was performed.