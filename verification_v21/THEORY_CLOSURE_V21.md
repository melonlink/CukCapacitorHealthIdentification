# Theory Closure v2.1

## 1. Sampling geometry

Let the switching and ADC periods be (T_s=1/f_s) and (T_a=1/f_{ADC}).
For (N_w) uniformly spaced samples on one side of an edge, the minimum span is

\[
W_{min}=(N_w-1)T_a. \tag{A1}
\]

For an edge exclusion guard (g), a complete fit window must satisfy

\[
g+W\le T_{state}, \tag{A2}
\]

and both switch states are available only if

\[
g+W\le \min(D,1-D)T_s. \tag{A3}
\]

Combining (A1) and (A3) gives the point-placement lower bound

\[
f_{ADC}\ge \frac{N_w-1}{\min(D,1-D)T_s-g}. \tag{A4}
\]

This is a geometric lower bound, not an accuracy or aliasing bound. The actual
enumeration uses (t_n=nT_a+\phi), 64 uniformly spaced values of
(phi\in[0,T_a)), and separately reports mean, 95%, 100%, and designed-phase
feasibility. Therefore a design may satisfy (A4) yet fail the 95% phase gate.

## 2. Linear edge-extrapolation variance

For one side of an edge, write (v_i=a t_i+b+\epsilon_i), where the edge is
the local origin and (\operatorname{var}(\epsilon_i)=\sigma_v^2). With
(X=[\mathbf 1,\,t]), the OLS covariance is

\[
\operatorname{cov}(\hat\beta)=\sigma_v^2(X^TX)^{-1}.
\]

The intercept variance is consequently

\[
\operatorname{var}[\hat v(0)]=\sigma_v^2\left[
\frac1N+\frac{\bar t^2}{\sum_i(t_i-\bar t)^2}\right]. \tag{B1}
\]

If the pre- and post-edge sample sets are disjoint,

\[
\operatorname{var}(\Delta v_R)=
\operatorname{var}(\hat v^-)+\operatorname{var}(\hat v^+). \tag{B2}
\]

With (r_C=\Delta v_R/I_\Sigma), first-order propagation gives

\[
\sigma_r^2\simeq
\frac{\sigma_{\Delta v}^2}{I_\Sigma^2}+
\frac{r_C^2\sigma_{I_\Sigma}^2}{I_\Sigma^2}. \tag{B3}
\]

The implementation does not scale known ADC noise. It adds that OLS term in
physical units and separately scales only the excess fit-curvature term learned
on the declared training cases. The edge measurement gain correction is also
estimated on training data and locked before blind validation.

## 3. Capacitance pseudo measurement

For a safe interval with disjoint endpoint/integration samples,

\[
z_C=\Delta v_T-\hat r_C\Delta i_C,
\qquad q=\int_{t_0}^{t_1}i_C(t)\,dt.
\]

For the normalized parameter (\bar\alpha=C_b/C),

\[
z_C=\frac{q}{C_b}\bar\alpha+\nu_C. \tag{C1}
\]

The implemented first-order covariance is

\[
R_C\simeq R_{\Delta v}+(\Delta i_C)^2P_{rr}
+\hat r_C^2R_{\Delta i}+\alpha^2R_q. \tag{C2}
\]

Here (R_{\Delta v}=2R_v), (R_{\Delta i}=2R_i), and (R_q) is formed from
the current-noise variance, ADC interval, and number of trapezoidal increments.
The scalar information and accumulated information are

\[
\mathcal I_{C,k}=\frac{(q_k/C_b)^2}{R_{C,k}}, \tag{C3}
\]

\[
\mathcal I_{C,N}=\sum_k\frac{(q_k/C_b)^2}{R_{C,k}}. \tag{C4}
\]

## 4. Final normalized state

The selected state is

\[
x_k=[v_{C,k},\ \bar\alpha_k,\ r_{C,k}]^T,
\qquad \bar\alpha=C_b/C.
\]

The nominal base (C_b=100\,\mu F) remains fixed when degraded-capacitance
plants are evaluated. Truth used for MAPE, NEES, and CI coverage comes from the
simulated plant trajectory, not from the nominal parameter object.

## 5. State propagation

For charge increment (q_k\) between ADC timestamps,

\[
F_k=\begin{bmatrix}
1&q_k/C_b&0\\0&1&0\\0&0&1
\end{bmatrix},
\qquad x^-_k=F_kx^+_{k-1}.
\]

Process noise is a continuous-time spectral density (Q_c):

\[
P^-_k=F_kP^+_{k-1}F_k^T+Q_c\Delta t_k.
\]

This correction is important: adding a fixed (Q) once per ADC sample makes
the same physical estimator covariance depend spuriously on ADC rate.

## 6. Three final measurement directions

The selected conditional voltage observation is

\[
z_V=v_T-\hat r_Ci_C,
\qquad H_V^*=[1,0,0].
\]

The C and ESR pseudo measurements are

\[
z_C=\Delta v_T-\hat r_C\Delta i_C,
\qquad H_C=[0,q/C_b,0],
\]

\[
z_R=\hat v^- -\hat v^+,
\qquad H_R=[0,0,k_RI_\Sigma],
\]

where the training-locked (k_R) compensates the repeatable AFE/fit gain at
the selected design point. All accepted updates use the ordinary scalar Kalman
gain and Joseph covariance recursion; the final variant has no gain mask.

## 7. Measurement covariance

The conditional voltage variance is

\[
R_V^*=R_v+\hat r_C^2R_i+gamma_Vi_C^2P_{rr}. \tag{D3}
\]

Known ADC noise is not multiplied by a fitted global scale. (\gamma_V)
applies only to propagated ESR uncertainty. The edge variance is the sum of
known OLS voltage/current noise and a separately scaled positive curvature
excess. (R_C) follows (C2). This separation was necessary because scaling the
whole variance could fit nominal data only by making the 10 mV/5 mA case
overconfident.

## 8. Measurement correlation

The final policy assigns three raw index sets: (S_V) for mid-interval voltage,
(S_C) for charge endpoints/integration, and (S_R) for edge fits. It enforces

\[
S_V\cap S_C=\varnothing,\quad S_V\cap S_R=\varnothing,
\quad S_C\cap S_R\approx\varnothing.
\]

This removes same-sample information reuse within a cycle. The analog filter
still introduces temporal correlation across ADC samples and cycles. Training
showed that scalar C-NIS could be near one while final C-NEES was too high;
the locked (Q_{\bar\alpha}) therefore represents this remaining effective
correlation/model discrepancy. A fully correlated batch likelihood would be a
future refinement.

## 9. NIS, NEES, and confidence intervals

For a scalar innovation (e_k) with variance (S_k),

\[
NIS_k=e_k^2/S_k,
\]

with one-degree-of-freedom mean 1 and 95th percentile 3.841. For known truth,

\[
NEES_k=(\hat x_k-x_k)^TP_k^{-1}(\hat x_k-x_k).
\]

The package reports full three-state, parameter-only two-state, and scalar C
and ESR NEES. Across 100 independent seeds, average-NEES reference intervals
are computed from (\chi^2_{Nd}/N). CI calibration is reported at nominal
50%, 80%, 90%, 95%, and 99% levels.

## 10. Fisher information and CRLB

For the selected scalar observations,

\[
\mathcal I=\sum_k H_k^TR_k^{-1}H_k.
\]

The parameter block is accumulated from the C and ESR pseudo measurements.
For normalized (\bar\alpha),

\[
\operatorname{var}(C)\ge
\left(\frac{C_b}{\bar\alpha^2}\right)^2
[\mathcal I^{-1}]_{\bar\alpha\bar\alpha},
\qquad
\operatorname{var}(r_C)\ge[\mathcal I^{-1}]_{rr}.
\]

The implementation compares this local independent-measurement bound with
empirical variance and RMSE. A large RMSE/CRLB ratio indicates bias or model
mismatch; a simultaneously large CRLB indicates information shortage.

## 11. Identifiability versus numerical information

Full rank of a normalized observability or information matrix establishes only
structural identifiability under the assumed model. It does not guarantee a
useful smallest singular value, adequate Fisher information, low bias, or a
calibrated confidence interval. v2.1 therefore does not use `rank=3` as an
accuracy claim; sampling geometry, NIS/NEES, CRLB, alias perturbation, and Model
B disagreement are reported independently.

## References used for formulation checks

- Piché, *Online tests of Kalman filter consistency*, International Journal of
  Adaptive Control and Signal Processing, DOI: 10.1002/acs.2571.
- Sun and Deng, *Optimal sequential Kalman filtering with cross-correlated
  measurement noises*, Aerospace Science and Technology 26 (2013), DOI:
  10.1016/j.ast.2012.02.023.

