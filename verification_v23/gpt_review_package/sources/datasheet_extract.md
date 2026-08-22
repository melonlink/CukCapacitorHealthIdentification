# Datasheet/TRM/errata extract used by v2.3

This is a paraphrased traceability extract, not a substitute for the PDFs.

## ADC electrical and timing facts

- SPRS880P, ADC operating conditions and 16-bit characteristics: four ADC modules; 16-bit differential mode; 5–50 MHz ADCCLK; at least 320 ns acquisition; 29.6 typical/31 maximum ADCCLK conversion cycles; 1.1 MSPS/module; typical 14.65 ENOB at VREFHI=2.5 V and a 10 kHz test input.
- The quoted 14.65 ENOB is typical, not a production minimum. TI's AC characterization uses a high-accuracy external clock/PLL and minimizes adjacent I/O activity. v2.3 therefore uses 13.5 engineering ENOB and sweeps 12.5–14.65.
- 16-bit asynchronous multi-ADC AC operation is not supported. Synchronous characterization requires identical ADCCLK, resolution, signal mode, acquisition duration and trigger timing.
- Differential pins must each stay within VREFLO–VREFHI, and input common mode must remain VREFCM ±50 mV, where VREFCM=(VREFHI+VREFLO)/2. The negative input cannot simply be grounded in 16-bit mode.
- Input model: approximately 700 ohm switch resistance and 16.5 pF sample capacitor. ADCIN2/3 package parasitic is at most 6.3 pF among the selected pairs.
- External reference is required for 16-bit use; v2.3 selects 2.5 V and follows TI's 22 uF local reference-decoupling guidance.
- SPRS880P ePWM timing: EPWMCLK is limited to 100 MHz and must be SYSCLK/2 when SYSCLK exceeds 100 MHz. This corrected the initial 200 MHz TBCLK assumption.

## TRM register/timing facts

- `ACQPS` encodes `(ACQPS+1)` SYSCLK cycles. `ACQPS=63` at 200 MHz is exactly 320 ns.
- ADC prescaler enum/register value 6 is divide-by-4, giving 50 MHz ADCCLK from 200 MHz SYSCLK.
- In 16-bit divide-by-4 mode, late end-of-conversion is 119 SYSCLK cycles (595 ns) after acquisition completes, and the result latch is at 120 cycles (600 ns). Start-to-next-start is therefore 320+595=915 ns, or 1.092896 MSPS.
- For synchronous operation, use the same ePWM trigger, SOC priority, burst setting, resolution, signal mode and ACQPS on ADCA–ADCD. Software-force calls do not create four-ADC simultaneity.

## Errata facts

- Call `ADC_setMode` after startup so resolution/mode-specific trims load.
- Use continuous ADCINT or explicitly service flag and overflow to avoid a stopped interrupt stream.
- DMA can read a stale result when its trigger precedes the result latch by enough cycles. In the selected 16-bit divide-by-4 late-interrupt schedule the latch gap is 5 ns and DMA cannot access earlier than 15 ns, giving 10 ns timing margin.
- ADC sparkle/random-conversion advisories apply to earlier silicon. Production hardware is constrained to revision C; the earlier-revision 40 MHz workaround is not applied to revision C.
