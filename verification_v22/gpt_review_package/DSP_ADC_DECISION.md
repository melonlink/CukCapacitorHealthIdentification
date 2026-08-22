# DSP ADC Decision — v2.2

## Forced decision

```text
NATIVE_HIGH_RESOLUTION_MODE_REQUIRED
```

This is conditional on a target DSP actually providing a 16-bit-class mode
near 1.1 MS/s/channel with ENOB about 13.5, PWM/SOC triggering, enough
concurrent resources, and calibratable residual skew. Because the part number
is absent, the hardware selection status remains `TARGET_DSP_NOT_FIXED`.

## Answers to the 20 mandatory questions

1. **Target DSP:** not specified in source, README, model parameters, or
   hardware configuration. No part number was invented.
2. **Native modes:** parameterized 12-bit/4 MS/s/ENOB 10.5 and
   16-bit/1.1 MS/s/ENOB 13.5 references.
3. **Fastest native geometry:** yes. At 4 MS/s the locked PWM-triggered burst
   uses 0.2 µs guard, 1.5 µs window, and 6 required points/side (7 available).
4. **High-resolution geometry:** it does not fail after window redesign. At
   1.1 MS/s, 0.2 µs guard + 2 µs window gives 3 points/side; Model B 95th
   percentile extrapolation bias is 1.16%.
5. **ENOB:** separated from nominal bits. The 12-bit sweep is
   9.5–12 ENOB; the reference operating points are 10.5 and 13.5 ENOB.
6. **Minimum ESR signal:** 31.943 mV. Median/max are 250.605/1605.569 mV.
7. **Wide 0–100 V, 12 bit:** only 1.31 codes at the minimum ESR signal.
8. **Level-shifted single window, 12 bit:** 2.91 minimum ESR codes. It remains
   quantization sensitive and does not meet the blind gate.
9. **Dual-range Vedge:** yes, significant improvement: 32.70 minimum ESR
   codes at 12 bit and worst ESR MAPE 1.51%. It solves ESR, not the weak C
   endpoint difference on Vabs.
10. **Current full scale:** Model B peak is 10.877 A. The 1.25/1.5/2.0 margins
    map to 15/20/25 A engineering ranges. The recommendation is 20 A, not 40 A.
11. **Multi-cycle gain:** on the worst signal with the passing HR profile,
    full-nonideal C/ESR MAPE changes from 13.21/7.68% at 1 cycle to
    2.65/0.335% at 1024 cycles. C first crosses 3% at 256 cycles in this sweep.
12. **Deterministic floor:** yes. In Q1, error does not follow sqrt(N); the
    HR reference stays near 0.95% C and 0.20–0.26% ESR from 1 to 1024 cycles.
13. **PWM timing:** the geometry accepts a 50 ns residual inside the 0.2 µs
    guard. Cal2/Cal3 assume 20 ns residual and pass; Cal0/Cal1 at 120 ns fail
    the v2.1 worst-case timing requirement.
14. **Native + calibration accuracy:** 12-bit high-speed fails (27.8% blind
    accuracy pass). 16-bit slow + V2 + Cal3 passes 36/36; worst C/ESR MAPE is
    2.737/0.417%.
15. **ESR=2×:** passes. Worst C/ESR MAPE among ESR=0.1 Ω cases is
    2.604/0.269%.
16. **Minimum usable native configuration:** parameterized 16-bit,
    ENOB 13.5, 1.1 MS/s, V2, 20 A current range, 1024-cycle fusion, Cal2 timing.
17. **Recommended native configuration:** the same with Cal3 kR correction,
    independent/concurrent Vedge, Vabs, i1, i2 resources, and a 20 ns residual
    timing target.
18. **Must an external ADC be used?** No, not under the passing native-HR
    reference. Actual device capability is still unverified.
19. **External minimum if the selected DSP lacks HR mode:** the combined
    geometry/accuracy lower bound is nominal 16 bit, ENOB about 13.5,
    at least 1.1 MS/s/channel, concurrent timed channels, and ≤20 ns calibrated
    residual. The explicit 16-bit/5 MS/s control passes; 14-bit/5 MS/s passes
    only 75% and is insufficient. A real external part must be re-run from its
    datasheet.
20. **Final architecture:** V2 dual range; Vabs 0–80 V, Vedge −2 to +2 V with
    5 kHz high-pass/1.2 MHz low-pass parameterization, i1/i2 0–20 A,
    PWM-triggered timestamped windows, TS-SLTVKE sequential fusion over up to
    1024 cycles, and Cal3 recommended.

## Confidence classification

Point accuracy is **PASS** for the native HR reference. Statistical confidence
is **PARTIAL**: across the 36 HR blind rows, mean 95% CI coverage is 93.19% for
C and 100% for ESR, but only 75% of individual rows meet the per-row 90%
coverage check. Mean parameter NEES is 1.77, yet the weakest C cases remain
under-covered. Hardware covariance calibration remains mandatory.

## Why external 16-bit/5 MS/s is not the default

The external control and native HR profile produce identical observation-layer
accuracy when ENOB/nonideal assumptions match; the geometry table shows that
1.1 MS/s is sufficient after PWM-synchronous window redesign. Therefore 5 MS/s
does not create the passing result. Effective resolution and C-channel range
are the binding constraints in this study.
