# TS-SLTVKE finite-window theory

## 1. Notation

Let `theta=[alpha_bar,r_C]^T`, with `alpha_bar=C_b/C`. The structured health observations are `z_C=h_C alpha_bar+nu_C` and `z_R=h_R r_C+nu_R`, where `h_C=q/C_b` and `h_R=k_R I_Sigma`.

## 2. Assumptions

1. `0<C_min<=C_k<=C_max` and `0<r_min<=r_k<=r_max`.
2. `0<R_min I <= R_k <= R_max I` and `0<=Q_k<=Q_max I`.
3. In every valid C window, `sum h_C^2/R_C >= mu_C>0`.
4. In every valid ESR window, `sum h_R^2/R_R >= mu_R>0`.
5. Health updates occur only in valid CCM with `|q|>=q_min`, `I_Sigma>=I_min`, and passed gates.
6. Conditional-voltage mismatch has bounded second moment.

## 3. Proposition 1 — structural finite-window identifiability

Within a valid window containing nonzero C and ESR information, the health-information Gramian is `G=sum diag(h_C^2/R_C,h_R^2/R_R)`. Assumptions 3–4 give `G >= diag(mu_C,mu_R)>0`; therefore `rank(G)=2`, and `(alpha_bar,r_C)` is locally structurally identifiable. Since `C=C_b/alpha_bar` is one-to-one on the bounded positive interval, `(C,r_C)` is also locally identifiable.

## 4. Proposition 2 — mean-square bounded health error

For each structured scalar Joseph update, prediction covariance is bounded by the prior bound plus `Q_max`. The information contribution in a valid finite window is at least `mu_C` or `mu_R`; hence the posterior scalar covariance is upper-bounded by the reciprocal of prior information plus that positive window information. Repeating valid windows prevents unbounded covariance growth. Bounded process noise, positive measurement covariance, projection on a compact physical set, and bounded conditional mismatch then yield a finite second-moment error bound. With `Q_theta=0`, unbiased observations, and recurring PE, accumulated information is monotone and covariance contracts. With `Q_theta>0`, covariance reaches a nonzero bounded neighborhood determined by process noise, measurement noise, and mismatch.

This is an estimator-consistent proof sketch using the scalar information recursion; it is not a global nonlinear convergence proof. **Global asymptotic convergence is not claimed.**

## 5. Corollary — excitation gating and freeze

If `|q|<q_min`, `I_Sigma<I_min`, DCM is detected, or a validity gate fails, the corresponding parameter update is frozen. This removes uninformed innovation-driven parameter drift. When CCM and finite-window PE return, Proposition 1 applies again and covariance contraction resumes.

## 6. Numerical connection

Across 36 operating points, minimum information was `mu_C=1.004e+04` and `mu_R=3.473e+06`. The log-information/log-variance correlations were -0.9969 for C and -0.9969 for ESR, matching the required inverse direction. Empirical variance remains above the computed ideal CRLB because model mismatch and process floors are retained.

## 7. Limitations

The proof assumes correct CCM mode labeling, bounded conditional mismatch, calibrated observation directions, and recurring finite-window PE. Projection guarantees physical boundedness but does not by itself prove unbiasedness. During arbitrarily long non-PE intervals, accuracy is not guaranteed. Temperature and hardware ringing are outside the present theorem.

## 8. Classical LTV mapping and references

For the health random walk, `F_theta=I`; the finite-window weighted Gramian is exactly the diagonal information sum in Proposition 1. Assumptions 2-4 provide bounded positive measurement covariance and uniform health-direction observability on valid CCM windows. Classical LTV Kalman stability results use uniform complete observability together with bounded covariance/realization conditions; here the structured scalar information proof is stronger and more direct for the health block, while the classical result supports the full-state interpretation. Cite Jazwinski, *Stochastic Processes and Filtering Theory* (1970); Anderson and Moore, *Optimal Filtering* (1979); Ni and Zhang, “Stability of the Kalman filter for continuous time output error systems,” *Systems & Control Letters* 94 (2016), DOI 10.1016/j.sysconle.2016.06.006; and Viegas et al., “On the stability of the continuous-time Kalman filter subject to exponentially decaying perturbations,” *Systems & Control Letters* 89 (2016), DOI 10.1016/j.sysconle.2015.10.012. The continuous-time papers are supporting stability references, not a claim that their theorems are copied unchanged to the discrete estimator.
