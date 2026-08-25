# Reviewer-style compression audit

Date: 2026-08-25

Baseline: `manuscript_v027` (13 pages). Target: `manuscript_v03` (10.5–12 IEEE pages).

## Repeated points removed or consolidated

| # | Repeated point in baseline | v0.3 treatment |
|---|---|---|
| R1 | Observation design, not recursive complexity, is the main contribution. | Stated in the Abstract, Results attribution, Discussion, and Conclusion only where each serves a distinct role. |
| R2 | RLS itself is standard. | Kept once in the contribution list and once beside the RLS equations. |
| R3 | TS-SLTVKE is not the universal point-estimation winner. | Consolidated into Results and the realization tradeoff in Discussion. |
| R4 | All compared estimators use common O1 observations. | Consolidated in Sections V–VI. |
| R5 | No blind retuning occurred. | Stated once in the fairness protocol; detailed provenance remains in traceability. |
| R6 | Abrupt steps are not aging. | Kept once in the stress-test result and once in grouped Limitations. |
| R7 | Long ramps are not hardware aging data. | Kept in the ramp caption/protocol and grouped Limitations. |
| R8 | Device-realistic results are not hardware validation. | Concentrated in Section VIII and Limitations. |
| R9 | Per-observation arithmetic time is not platform WCET. | Consolidated in Complexity and the final device boundary. |
| R10 | The calibration reference is planted simulation truth. | Stated at the calibration equation and documented fully in Supplementary S2. |

## Representative sentence compression

| # | Baseline issue | Compressed v0.3 wording |
|---|---|---|
| S1 | Long abstract listed every evaluation layer and caveat. | Abstract reduced to 196 words and three quantitative groups. |
| S2 | Introduction enumerated adjacent papers individually. | Related work grouped into ripple, switched-observer, spectral, and recursive classes. |
| S3 | “The comparison is categorical; numerical rank claims are avoided...” | “The comparison is categorical because the converter topologies, sensing sets, and reporting protocols differ.” |
| S4 | Calibration paragraphs repeated source archives, rerun status, and unchanged hyperparameters. | Main text now gives the formula, `0.9772` display rule, Case-A spread meaning, and hardware future tense. |
| S5 | Validity section described the absence of `q_gate` in audit language. | Reduced to the actual acceptance rule and its proof/online-threshold boundary. |
| S6 | Verification hierarchy repeatedly used “frozen,” “locked,” and “campaign.” | Recast as an evaluation protocol with common cases and predeclared settings. |
| S7 | Full three-effect bootstrap intervals occupied the central attribution paragraph. | Main text retains one ESR effect/interval; all three remain in Supplementary S3. |
| S8 | Slow-ramp paragraph restated multiple table values. | Reduced to lower aggregate nRMSE/lag at all durations plus the retained exception. |
| S9 | F28379D section listed every register-derived margin and data-rate value. | Main text keeps ADC count/mode, aperture, window, AFE boundary, p95, and evidence level. |
| S10 | Eight audit-like limitation bullets overlapped. | Merged into six reviewer-facing evidence categories. |

## Details moved to Supplementary

1. Full O0–O1 bootstrap intervals for capacitance, ESR, and convergence.
2. Exact threshold-crossing rules and retained-miss treatment.
3. Operating-transient trace figure and detailed false-health values.
4. F28379D 4.0 MB/s DMA rate, 45.75% utilization, 2.150-µs aperture span, and 50-ns margin.
5. F28379D common-mode extrema, detailed AFE assumptions, and Monte Carlo coverage ranges.

## Negative-result statements that remain mandatory

1. Dual-EKF O0–O1 ESR-p95 effect is negative and its interval does not favor O1.
2. TS-SLTVKE misses the abrupt-step convergence criterion within 257 cycles for both health steps.
3. TS-SLTVKE abrupt tail errors remain 19.2911% for capacitance and 49.9384% for ESR.
4. TS-SLTVKE can outperform TS-D-RLS on an individual trajectory despite the aggregate ramp result.
5. TS-D-RLS auxiliary joint coverage remains 13.00%, well below the uncertainty-aware alternatives.

## Outcome

The main manuscript is compressed without removing propositions, frozen performance values, adverse results, or the simulation-only evidence boundary. Engineering provenance remains in Supplementary and source traceability.
