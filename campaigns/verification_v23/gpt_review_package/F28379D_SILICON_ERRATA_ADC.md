# F28379D ADC silicon-errata closure

Production input inspection is locked to silicon revision C.

| Advisory/constraint | Application | Mitigation/status |
|---|---|---|
| ADC offset/linearity trim depends on mode | Applies | Call `ADC_setMode(...16BIT, DIFFERENTIAL)` after startup and before enabling SOC triggers. |
| ADCINT can stop if continuous mode is disabled | Applies | Enable continuous ADCINT1; clear interrupt and overflow during initialization and error recovery. |
| DMA can read stale ADC result | Timing-dependent | Use late ADCINT1 from SOC2. In selected 16-bit divide-by-4 timing, result latch follows EOC by 5 ns while DMA access is no earlier than 15 ns: 10 ns proof margin. |
| Random/sparkle conversion errors | Earlier revisions | Revision C is not affected. Do not apply the earlier-revision 40 MHz workaround to revision C. |
| Special ADC input pin loading | Applies | Use ADCIN2/3 on all modules; avoid A0/A1/B0/B1. |

Boot software must compare the device revision against the released hardware list and inhibit health reporting on an unqualified revision. DMA overrun/error flags and ADC overflow status are diagnostic faults, not silent data drops.
