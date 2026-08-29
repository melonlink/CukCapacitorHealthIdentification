# k_R calibration closure audit

Date: 2026-08-25

Final token: `THEORY_SIMULATION_MANUSCRIPT_FROZEN`

Primary classification: `EXACT_REPRODUCTION_ADOPTED`

Campaign classification: `RECALIBRATED_CAMPAIGN_PASS`

## Closure decision

The paper evaluation now adopts the independently reproduced simulation-calibration coefficient

```text
k_R = 0.97719802594550731
```

The historical `0.982` center remains only as a superseded configuration in the v0.26/v1.1/v1 provenance record. It is not used by paper-verification v1.2, algorithm-selection v2, or manuscript v0.3. All affected ESR outputs were regenerated after the replacement; estimator equations, hyperparameters, seeds, validity gates, and the predeclared `0.006` casewise amplitude were unchanged.

## Required questions

1. **Where does the current paper `k_R` enter the algorithm?**

   `paper_verification_v12/scripts/paper_verification_v12_engine.m` and `paper_algorithm_selection_v2/scripts/paper_algorithm_selection_v2_engine.m` set `cfg.kRCalibration=0.97719802594550731`. The frozen stream forms casewise `k_R` realizations and `h_R=k_R I_\Sigma`; the identical `h_R` is supplied to TS-D-RLS and TS-SLTVKE.

2. **Is it derived or hard-coded?**

   The adopted numeric value is derived from a simulation-calibration stage and then held fixed during evaluation. Its derivation is independently reproduced from the v2.1 calibration inputs.

3. **Do raw calibration data exist?**

   The archived source plants, measurement-chain settings, parameters, and seeds deterministically reconstruct all 588 edge ratios. `calibration_closure/results/table_kR_calibration_raw.csv` records the reconstructed ratios.

4. **What is the reference ESR source?**

   `SIMULATION_REFERENCE_TRUTH`: `model_parameters().ESR=0.05` ohm, propagated through the calibration cases. It is not an LCR-meter, impedance-analyzer, or hardware measurement.

5. **Are calibration and blind evaluation separated?**

   Yes. Four declared simulation-calibration profiles are aggregated before blind validation. Neither final estimator updates `k_R` from blind residuals.

6. **What is the formula?**

   For each accepted calibration edge,

   ```text
   kappa_m = z_R,m / (I_Sigma,m * r_C,ref,m)
   k_R = median_m(kappa_m)
   ```

7. **What rejection and weighting are used?**

   NaN omission only, matching `median(...,"omitnan")`. There is no weighting, trimming, residual gate, least-squares, WLS, or Huber step. All 588 reconstructed ratios are finite.

8. **What is the full-precision value?**

   Reproduced v2.1 value: `0.97719802594550731`. Archived v2.1 lock: `0.97719802594550731`. Absolute difference at saved precision: zero.

9. **Does it round to `0.982`?**

   No. The old value was a later campaign lock without a matching archived transition artifact. That version drift has been resolved by adopting the reproducible coefficient and rerunning all affected ESR results.

10. **Can it be reproduced with one command?**

    Yes: run `calibration_closure/scripts/reproduce_kR_calibration.m`.

11. **What is the role of `0.957654...`?**

    It is the conservative proof quantity `k_R,min=0.98*lockedV21.edgeGainCorrection=0.9576540654265971`. It is used only in the evaluated physical-PE lower bound and never replaces the online/casewise calibration scale.

12. **What is the bounded sensitivity?**

    The archived 35-row TS-D-RLS-only sensitivity check gives mean ESR bias `+1.0225%` at `-1%` assumed gain error and `-0.9779%` at `+1%`; worst absolute endpoint bias is `1.170818%`. No projection activation or retuning occurred.

13. **Does manuscript wording match the evidence level?**

    Yes. v0.3 displays `k_R=0.9772` in the main text, retains full precision in Supplementary/source traceability, states the simulation-truth reference and median formula, and identifies `0.006` as known casewise calibrated variation. Hardware commissioning appears only in future tense.

## Rerun audit

- Paper verification v1.2: 4,608 factorial rows, 18 paired-bootstrap rows, 18 dynamic rows, 45 PE cases, 10 covariance cases, and 200 projection seeds per state; `AUDIT=PASS`.
- Algorithm selection v2: 6 static, 18 abrupt, 162 ramp, 360 threshold, 24 transient, 48 noise/timing, 7 bootstrap, and 4,812 trace rows; `AUDIT=PASS`.
- Frozen estimator-core SHA-256 in both campaigns: `6B59445898F224C6C070B4E0C3B08E73C7500B5385F912BB058BADBC6AD67225`.
- Comparison audit: 25 of 66 algorithm result-metric cells changed; 51 of 88 manuscript-facing numeric rows changed. PE, complexity, and device-realistic numeric fields remained invariant.
- Selection result remained `DUAL_REALIZATION`.

## Stop-condition audit

- [x] Exact adopted value is present in both current engines.
- [x] Calibration/reference source and 588 reconstructed ratios are documented.
- [x] Calibration/blind separation and identical estimator regressors are verified.
- [x] Affected verification and algorithm-selection campaigns were rerun.
- [x] Row-count, frozen-core, invariance, and final-decision checks passed.
- [x] v0.3 tables, figures, prose, supplementary material, and traceability matrices were updated.
- [x] The manuscript compiles with resolved references and no overfull boxes or LaTeX errors.
- [x] The compressed PDF passed rasterized visual inspection.

## Decision

The earlier calibration-version mismatch is closed. The reproducible `0.97719802594550731` value is the sole computation center, the main text displays it as `0.9772`, and the affected ESR evidence remains frozen.
