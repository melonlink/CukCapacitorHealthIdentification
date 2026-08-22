# Paper Verification v1.1 result

## 1. Executive Decision

REOPEN_ALGORITHM

## 2. Observation x Estimator Result

Six cells and 4608 paired rows were retained. OBSERVATION_FRAMEWORK_IS_PRIMARY_INNOVATION

## 3. Primary Innovation Decision

OBSERVATION

The manuscript contribution is attributed primarily to the topology-specific observation framework according to the measured factorial effects, not to universal static-MAPE rank or a broad incremental advantage of the E3 kernel.

## 4. RLS with Proposed Observation

C_MAPE O0-O1 6.6639 (95% CI 6.4732 to 6.858, improved 1.000); ESR_MAPE O0-O1 0.97478 (95% CI 0.92463 to 1.0277, improved 0.958); convergence O0-O1 652.22 (95% CI 620.63 to 683.79, improved 0.987)

## 5. Dual EKF with Proposed Observation

C_MAPE O0-O1 6.7113 (95% CI 6.5227 to 6.8976, improved 1.000); ESR_MAPE O0-O1 0.062089 (95% CI -0.029783 to 0.15478, improved 0.562); convergence O0-O1 649.98 (95% CI 616.49 to 682.56, improved 0.908)

## 6. TS-SLTVKE Incremental Value

C_MAPE O0-O1 6.7378 (95% CI 6.5542 to 6.9268, improved 1.000); ESR_MAPE O0-O1 0.57961 (95% CI 0.50088 to 0.65795, improved 0.819); convergence O0-O1 690.69 (95% CI 657.48 to 722.51, improved 0.932) O1-E3 C MAPE 0.3011%, ESR MAPE 0.6428%, mean convergence 33.04 cycles, joint CI coverage 0.8906, and divergence 0.0000%. E3 was slightly best on mean C error but not on ESR, convergence, timing, or CI calibration versus both alternatives; its broad incremental factorial value is therefore not established.

## 7. Factor Interaction

E3-vs-E1 interaction is 0.0738914 for C MAPE and -0.395169 for ESR MAPE. Signs are reported without suppression.

## 8. Physical PE Lower Bound

Across 45 frozen Model-B CCM cases, the weakest single-cycle bounds are mu_C=0.217943 and mu_R=880.008. Minimum empirical/lower ratios are 1.02872 and 1.02334.

## 9. Covariance Fixed-Point Bound

Maximum validated C-direction P*=0.0112191; maximum ESR P*=8.82437e-06. All simulated posterior sequences remain below their conservative lower-information envelopes.

## 10. Projection Independence

Projection OFF retained 200 legal-PE seeds with divergence 0. Projection ON activation fraction was 0.

## 11. Final Proposition Text

Proposition 1: valid CCM operating bounds, sign-invariant safe charge windows, positive accepted edge current, bounded measurement covariance, and recurring C/R observations imply an explicit positive diagonal finite-window information lower bound and local structural identifiability.

Proposition 2: recurring information mu>=mu_lower>0 and finite Q_N imply P_next<=(P+Q_N)/(1+mu(P+Q_N)); the covariance is uniformly bounded by the positive fixed-point neighborhood, and for Q_N=0 contracts to zero in the ideal conditional linear model.

## 12. Final Safe Claims

Topology-induced PE and decoupled observations are defensible in valid CCM; the structured kernel adds measured convergence, gating, confidence, or robustness value where the tables show it.

## 13. Claims Removed

Removed: universal numerical SOTA; monotonic accuracy gain from every module; PWM-guaranteed PE at all operating points; global asymptotic nonlinear convergence; projection as the source of covariance boundedness.

## 14. Manuscript Freeze Decision

REOPEN_ALGORITHM

Dynamic factorial rows: 18; divergence rows: 0. O1-E3 did not converge within 257 post-step cycles for either health step; tail C error after C->0.8C was 19.2911% and tail ESR error after ESR->2R was 49.9379%. This explicit negative result triggers REOPEN_ALGORITHM without changing the frozen core in this package.
