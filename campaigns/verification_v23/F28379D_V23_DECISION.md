# F28379D v2.3 decision

```text
F28379D_INTERNAL_ADC_CONFIRMED_WITH_AFE_CONSTRAINTS
```

All eight simulation gates pass. This is conclusion B, not an unconditional ADC approval.

The approval requires: PTP-176/revision-C silicon; external 2.5 V reference and external crystal/PLL; 16-bit differential ADCIN2/3 on ADCA–D; common `ACQPS=63`; 50 MHz ADCCLK; 100 MHz EPWMCLK with `TBPRD=1999`; E1 one-edge schedule with g=0.5 us, W=2.2 us, N=3; ≤50 ohm/330 pF ADC driver networks; the finite-CMRR/template-calibration constraints; and Cal3 multi-point production calibration.

Device-level 200-seed validation across seven representative conditions produced worst p95 C error 1.6425%, worst p95 ESR error 2.6109%, and 100% threshold pass fraction. The original 2.0 us three-point full-aperture geometry does not pass and is not approved.

Empirical CI coverage is 93.5–97.5% for C and 98–100% for ESR. The lowest 200-seed coverage remains statistically compatible with nominal 95% coverage and is reported rather than hidden.

Simulation and sampling architecture may be frozen for PCB/bench implementation. Firmware remains `NOT_COMPILED`; target compilation and measured WCET are release gates before firmware freeze, not reasons to select an external ADC now.
