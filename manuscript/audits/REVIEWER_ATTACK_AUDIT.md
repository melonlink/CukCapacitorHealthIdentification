# Reviewer attack audit

Date: 2026-08-25

Scope: wording and structure review of manuscript v0.3. No algorithm, model, parameter, or result change is authorized by this audit.

## Reviewer A — Power electronics

| # | Likely reviewer comment | Current manuscript defense | Remaining weakness | Recommended wording patch |
|---|---|---|---|---|
| A1 | The capacitor-current signs may be inconsistent across the two Ćuk switch states. | Section II gives `i_C=(1-u)i_1-ui_2`, Fig. 1 shows both states, and Appendix A reproduces the switched equations. | A reader may use an opposite output-current convention. | Retain the explicit sentence that `i_1` and `i_2` follow their usual positive inductor directions and that `v_o` is the magnitude of the negative output. |
| A2 | “No injection” may hide a substantial sensing burden. | Introduction Table I and its sensing note identify `v_T`, `i_1`, `i_2`, PWM state/time, and the separate absolute/edge voltage ranges. | Actual probes and isolation have not been demonstrated. | Keep “No diagnostic injection does not imply zero sensing burden” and avoid “sensorless.” |
| A3 | ESL, edge ringing, and bandwidth may invalidate an instantaneous ESR step. | Section III reconstructs both sides to a common timestamp; Sections II and IX state the first-order model and ringing/AFE limits. | There is no bench edge waveform. | Describe `z_R` as an “ESR-dominant reconstructed discontinuity” and retain hardware ringing as an open limitation. |
| A4 | The claimed internal-ADC implementation may exceed F28379D timing or common-mode limits. | Section VIII states four synchronized 16-bit differential modules, 320-ns aperture, the 2.2-µs window, and the mandatory differential AFE; Supplementary S1 retains the full schedule. | Compiler closure and bench AFE verification are absent. | Use “device-realistic feasibility simulation,” never “hardware implementation,” and retain the explicit WCET/AFE release gates. |
| A5 | The operating envelope may include DCM or inadequate edge current. | Sections III–IV define CCM, timestamp, safe-window, and `I_Σ` gates and restrict the proof to accepted rows. | DCM behavior is not estimated. | Keep “DCM and weak-excitation intervals hold the estimate” in Limitations. |

## Reviewer B — Estimation and control

| # | Likely reviewer comment | Current manuscript defense | Remaining weakness | Recommended wording patch |
|---|---|---|---|---|
| B1 | The parameters are not identifiable if calibration gain and ESR are both free. | Section III states that only `k_R r_C` is identifiable when both are unknown and holds `k_R` fixed after a separate simulation-calibration stage. | Hardware calibration transfer is not established. | Retain the scale-ambiguity sentence and the future-tense hardware commissioning requirement. |
| B2 | The `±0.006` spread is ambiguous and may give the estimators privileged truth. | Section III now states that it is known casewise calibrated measurement-chain variation and is supplied identically through `h_R` to every estimator. | The assumption is optimistic if future hardware cannot reproduce casewise calibration. | Keep “assumed known after calibration” and do not call the spread unobserved uncertainty. |
| B3 | PWM does not guarantee persistent excitation. | Proposition 1 is conditional on valid accepted charge/edge rows and positive finite-window lower bounds. | The proof does not cover arbitrary load or DCM. | Keep the single main-text statement “PWM alone does not guarantee persistent excitation at every load or conduction mode.” |
| B4 | The Kalman covariance proposition overstates nonlinear convergence. | Proposition 2 is explicitly a conditional scalar covariance envelope; Appendix B gives the derivation. | Model bias is only bounded qualitatively. | Retain “not a global nonlinear-converter convergence theorem” and avoid asymptotic state-convergence language. |
| B5 | The estimator comparison may be unfair or post-tuned. | Section VI states common cases, observations, seeds, initialization distributions, noise/timing realizations, predeclared parameters, retained failures, and paired bootstrap testing. | The adapted wavelet baseline is not an exact published Ćuk method. | Keep the publication-mapping caveat and avoid numerical-SOTA claims. |

## Reviewer C — Reliability and condition monitoring

| # | Likely reviewer comment | Current manuscript defense | Remaining weakness | Recommended wording patch |
|---|---|---|---|---|
| C1 | ESR is strongly temperature- and frequency-dependent, so it is not a unique aging variable. | Sections II and IX define effective ESR under specified switching and thermal conditions. | No temperature-compensation model is validated. | Use “condition indicator” and “effective ESR,” not “remaining useful life” or “temperature-independent health.” |
| C2 | The 0.1–100-s ramps are unrealistically fast aging. | Sections VI, VII, and IX label them synthetic or trace-derived bandwidth tests. | No run-to-failure dataset is included. | Keep “degradation trajectory” only with the simulation qualifier and label steps “recovery stress tests.” |
| C3 | Device-realistic simulation is not experimental validation. | Abstract, Section VIII, Limitations, and Conclusion state the evidence boundary. | No hardware data exist. | Concentrate the caveat in Section VIII and Limitations; avoid repeatedly defensive wording elsewhere. |
| C4 | Estimated C/ESR may be condition indicators rather than direct health or lifetime measures. | Section II explicitly separates condition indicators from RUL prediction. | Mapping to lifetime remains application-dependent. | Retain that distinction and do not introduce RUL, accelerated-aging, or lifetime claims. |
| C5 | The uncertainty-aware method has better coverage but poor dynamic behavior. | Section VII reports 88.93% joint coverage and the retained abrupt-step failures; Discussion frames the methods as complementary. | Neither interval is universally calibrated across all unmodeled disturbances. | Keep “RLS wins cost/tracking; the Kalman extension provides better calibrated confidence within the evaluated cases.” |

## Audit conclusion

All 15 attacks are answerable from the current manuscript or an explicit evidence boundary. The recommended defenses are wording/organization measures only. No scientific conflict requiring algorithm revalidation was found.
