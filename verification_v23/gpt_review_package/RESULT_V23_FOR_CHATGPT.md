# v2.3 result for GPT review

1. **Difference from v2.2:** v2.3 replaces the generic 16-bit/1.1 MSPS profile with F28379D's real 320 ns aperture, 595 ns conversion occupancy, differential/common-mode limits, input RC, pin map, reference, 100 MHz ePWM limit and errata.
2. **14.65 ENOB condition:** TI typical AC characterization at 2.5 V reference and 10 kHz input with controlled external clock/PLL and layout/activity conditions; it is not a guaranteed minimum.
3. **Engineering ENOB:** 13.5 baseline; 12.5–14.65 swept.
4. **Original 2 us/3-point aperture:** no. Timestamps span 1.830 us, but complete apertures span 2.150 us.
5. **Final edge geometry:** guard 0.5 us, window 2.2 us, three points per side, one rising edge per cycle.
6. **ACQPS:** 63, meaning 64×5 ns=320 ns.
7. **Sustainable rate:** 1,092,896.175 samples/s/module.
8. **Four-ADC synchronization:** yes, with identical ePWM triggers, ADCCLK, mode, ACQPS, SOC priority and power-up order. Software forcing is excluded.
9. **Differential pairs:** ADCA A2/A3 pins 41/40; ADCB B2/B3 48/49; ADCC C2/C3 31/30; ADCD D2/D3 58/59 on PTP-176.
10. **Package:** PTP-176 for the prototype; ZWT-337 is electrically possible but harder to escape.
11. **ePWM generation:** EPWMCLK=100 MHz, TBPRD=1999. EPWM2/3/4 SOCA/B compare events generate six schedule anchors; repeated SOCs serialize three-sample edge bursts.
12. **SOC overrun:** no. Ten conversions use 45.75% of each 20 us period.
13. **One or two edges:** one rising edge (E1). Both-edge sampling collides in the short state at D=0.25.
14. **Floating common mode:** Model B spans -34.343 to +34.698 V over representative cases. Direct ADC connection is invalid.
15. **AFE CMRR:** either uncalibrated total-chain edge CMRR about 95 dB, or the selected measured ≥70 dB edge-band CMRR plus synchronous template calibration residual ≤5%; DC target ≥90 dB.
16. **1.2 MHz LP:** yes. It preserves edge content and, with the required template calibration, leaves 0.115% settling residual at the 0.5 us guard.
17. **VREF/clock:** external 2.5 V, ≤10 uV RMS target and ≤25 ppm/°C drift; external crystal+PLL. Reference noise/gain drift are calibrated and included in Monte Carlo.
18. **Errata impact:** load mode trims after startup; continuous ADCINT and overflow handling; late SOC2 ADCINT→DMA timing proof; accept revision C only; avoid special ADC pins.
19. **1024-cycle real time:** static budget says yes: 14 us work plus 6 us reserve per 20 us deadline, 4 MB/s DMA. Target WCET is still required because firmware could not be compiled locally.
20. **p95 accuracy:** worst across cases is C=1.6425%, ESR=2.6109%. Per-case results are in `table_v23_monte_carlo.csv`. Empirical 95% CI coverage is 93.5–97.5% for C and 98–100% for ESR; with 200 samples, the 93.5% observation's binomial uncertainty includes the nominal 95% target.
21. **Internal ADC confirmed:** yes, with AFE constraints.
22. **Root cause if constraints fail:** likely high-common-mode AFE/CMRR or production calibration, not nominal ADC bit count. The old 2 us window also fails the full-aperture definition.
23. **External ADC required:** no at this stage. Reconsider only if bench CMRR/template, Cal3, settling or target timing cannot be met.
24. **Freeze status:** freeze simulation and sampling architecture for PCB/bench. Do not freeze firmware release until C2000Ware target compile, linker/RAM check and measured WCET pass.

Final enum: `F28379D_INTERNAL_ADC_CONFIRMED_WITH_AFE_CONSTRAINTS`.
