# F28379D differential AFE interface

## Why direct connection is forbidden

Model B gives the ideal-switch terminal reconstruction

`vCplus=(1-u)vT`, `vCminus=-u vT`, and `vCM=(0.5-u)vT`.

Across the four simulated operating cases, plant common mode reaches -34.343 to +34.698 V. F28379D 16-bit differential inputs instead require both pins inside 0–2.5 V and common mode at 1.25 V ±50 mV. Direct ground-referenced connection fails every case.

## Required AFE outputs

Every channel shall drive `VP=1.25+Vdiff/2` and `VN=1.25-Vdiff/2`, with normal `|Vdiff|≤2.0 V` so each ADC pin retains at least 0.25 V headroom. Vabs maps 0–80 V to -2–+2 V differential; Vedge AC-couples the switching ripple into -2–+2 V; current channels map the validated 0–20 A range to -2–+2 V.

The front end must withstand the actual floating terminal/common-mode range, not just the differential ripple. Overvoltage protection must not add unmatched capacitance or clamp inside the normal range.

## Driver and settling constraint

Selected per-pin ADC network: source resistance no more than 50 ohm, 330 pF local reservoir, selected-pair package capacitance up to 6.3 pF. With TI's 700 ohm/16.5 pF input model, the TRM settling equation gives 29.19 ns effective time constant and 276.20 ns to a 0.25-LSB target. The allocated 320 ns aperture leaves 43.8 ns margin and an analytical residual of 0.0557 LSB.

All four channels must use this same `ACQPS=63`; different acquisition windows would invalidate the selected TI synchronous-ADC condition.

## Bandwidth, CMRR and calibration constraints

- Vedge high-pass: 5 kHz. Low-pass: 1.2 MHz. At the 0.5 us guard the raw first-order transient residual is 2.31%; after the required synchronous waveform template calibration (≤5% residual) it is 0.115%, below the 0.25% allocation. At least 1.0 MHz passes this calibrated criterion; 1.2 MHz is retained for edge fidelity.
- Uncalibrated total-chain CMRR would need about 95 dB at the switching edge to keep leakage below 2% of the 31.94 mV worst ESR signal. The selected alternative is measured edge-band CMRR ≥70 dB plus repeatable synchronous common-mode template calibration with residual ≤5%; the modeled residual is then 1.72%. DC/low-frequency CMRR target remains ≥90 dB.
- Cal3 production calibration is mandatory: Vabs offset residual ≤0.05 LSB, residual INL contribution ≤0.15 LSB, Vabs gain 1-sigma ≤0.3%, current gain ≤0.25%, edge gain ≤0.7%, and kR residual ≤0.3%.
- External 2.5 V reference noise target is ≤10 uV RMS; drift ≤25 ppm/°C is included with temperature-surrogate calibration. Use an external crystal plus PLL; the 14.65 ENOB datasheet typical must not be assumed with the internal oscillator.

If either the CMRR/template condition or Cal3 residuals cannot be demonstrated on the bench, Gate E is reopened and the internal-ADC confirmation does not apply.
