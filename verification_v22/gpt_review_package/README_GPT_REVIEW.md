# GPT Review Package — v2.2

Start with:

1. `Codex_Cuk_Capacitor_Health_Verification_Task_v2.2_DSP_ADC.md`
2. `DSP_ADC_DECISION.md`
3. `RESULT_V22_FOR_CHATGPT.md`
4. `TARGET_DSP_ADC_PROFILE.md`
5. `RUN_V22_AUDIT.md`

The forced decision is `NATIVE_HIGH_RESOLUTION_MODE_REQUIRED`, conditional on
the explicitly parameterized native 16-bit/1.1 MS/s/ENOB 13.5 reference.
The repository contains no target DSP part number (`TARGET_DSP_NOT_FIXED`).

The `tables/` and `figures/` folders contain exactly the 12 mandatory CSV and
12 mandatory PNG deliverables. `result_metrics_v22.csv` is duplicated at the
package root for quick review.

Review cautions:

- Native 16-bit point accuracy is PASS; statistical confidence is PARTIAL.
- Native 12-bit V2 solves ESR but fails C due weak absolute-channel code
  utilization and nonlinear quantization floor.
- The ADC/AFE Monte Carlo uses Model-B-derived sufficient signals around the
  locked v2.1 TS-SLTVKE measurement formulation; it is not a full Simscape run
  for every seed.
- No parameterized ADC property should be cited as a real datasheet value.
