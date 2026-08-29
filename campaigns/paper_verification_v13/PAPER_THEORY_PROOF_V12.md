# Paper theory proof v1.2

## 1. Notation

Let theta=[alpha_bar,r_C]^T, alpha_bar=C_b/C, h_C=q/C_b, and h_R=k_R I_Sigma. R_C and R_R are the conditional scalar measurement covariances.

## 2. Cuk operating assumptions

The converter is in valid CCM; each accepted charge window is wholly inside one topology and i_C does not change sign; accepted edges satisfy I_Sigma>0; covariances are finite; at least one C and one ESR observation recur per finite window. DCM, invalid edges, failed gates, and weak-excitation windows are excluded by freeze.

## 3. Physical PE lower-bound lemma

For an accepted window of length T_w with |i_C|>=I_C,min, |q|>=I_C,min T_w. Therefore one C observation supplies at least (I_C,min T_w/C_b)^2/R_C,max information. For an accepted edge with k_R>=k_R,min and I_Sigma>=I_Sigma,min, one ESR observation supplies at least k_R,min^2 I_Sigma,min^2/R_R,max. Multiplying by the accepted counts m_C and m_R gives mu_C and mu_R.

The 45 frozen Model-B cases use T_w,min=2e-06 s, a conservative calibration lower bound k_R,min=0.957654, R_C,max=0.0002 V^2, and R_R,max=0.000200391 V^2. The weakest computed bounds are mu_C>=0.217943 and mu_R>=880.008. Every empirical/lower ratio is at least 1.02872 and 1.02334, respectively.

## 4. Proposition 1 -- Cuk operating-condition-induced finite-window identifiability

If the operating assumptions above hold and a finite window contains m_C,m_R>=1 accepted observations, then the information Gramian satisfies G_theta >= diag(mu_C_lower,mu_R_lower)>0. Consequently (C,r_C) is locally structurally identifiable in that window. The proof follows by applying the two scalar lower-bound lemmas to the topology-decoupled rows and summing positive semidefinite contributions.

The physical source is the Cuk +i_L1/-i_L2 transfer: a nonzero, fixed-sign capacitor-current interval supplies charge excitation, while I_Sigma=i1+i2>0 supplies edge excitation every valid CCM cycle. PWM alone is not asserted to guarantee PE at all loads.

## 5. Scalar covariance recursion lemma

Over one finite window, P_minus<=P+Q_N. With information mu>0, P_plus<=[1/(P+Q_N)+mu]^-1=(P+Q_N)/(1+mu(P+Q_N)). The map is increasing, bounded above by 1/mu, and has derivative below one away from the degenerate mu=Q_N=0 case.

## 6. Proposition 2 -- finite-window covariance boundedness and contraction

For recurring valid updates, finite 0<=Q_N<=Qbar_N, and mu>=mu_lower>0, the posterior recursion is bounded by the map above. Its positive fixed point is P*=(-Q_N+sqrt(Q_N^2+4Q_N/mu))/2. Monotonicity implies iterates above P* decrease and iterates below P* remain inside the finite invariant interval bounded by max(P0,P*). The v2.1 continuous-time spectral densities are converted as Q_N=S_Q*T_N; no per-sample Q is mixed with a spectral density. Across the five numerical cases, max C-direction P*=0.0112191 and max ESR P*=8.82437e-06.

## 7. Q=0 corollary

For Q_N=0, P_n^-1>=P_0^-1+n mu, hence P_n<=1/(P_0^-1+n mu)->0 under recurring PE and the correct conditional linear model. This is covariance contraction, not a claim of global asymptotic convergence for the nonlinear physical estimation error.

## 8. Gating/freeze corollary

If |q|, I_Sigma, CCM validity, edge validity, or the NIS gate fails, the current positive lower bound is unavailable and the parameter update freezes. Contraction resumes when accepted CCM windows recur.

## 9. Bounded mismatch

Under zero-mean correct conditional observations, covariance describes the mean-square error. With bounded conditional mismatch E[d_k^2]<=d_bar, the stable finite-window gain map yields a finite mismatch-dependent term B_d, so limsup E[e_theta^2]<=P*+B_d. No exact B_d is invented because the frozen nonlinear remainder is case dependent.

## 10. Projection role

Projection is not required to establish Proposition 2 covariance contraction. It remains only as a physical safety constraint for invalid/non-PE data. In 200 legal-PE seeds, projection OFF divergence was 0 and projection ON activation fraction was 0.

## 11. Numerical verification

All empirical PE values exceed their physical lower bounds, all ten covariance sequences remain below the lower-information envelope, and the Q=0 algebraic sanity error is 3.47e-18.

## 12. Limitations

The result is finite-window and conditional on valid CCM, bounded covariance, correct timestamp/calibration policy, and recurring accepted updates. It is not a global nonlinear observer theorem, does not cover DCM without gating, and does not replace hardware validation of ringing, temperature drift, or outliers.

## 13. Authoritative references

Jazwinski, Stochastic Processes and Filtering Theory, 1970; Anderson and Moore, Optimal Filtering, 1979; Ni and Zhang, System & Control Letters 94 (2016), 81-86; Viegas et al., Systems & Control Letters 86 (2015), 75-82.

Theory decision: REOPEN_ALGORITHM.
