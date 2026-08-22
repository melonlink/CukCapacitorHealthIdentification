# F28379D ADC datasheet closure

## Locked proposal

| Parameter | Final value |
|---|---:|
| Device | TMS320F28379D, silicon revision C |
| SYSCLK | 200 MHz |
| EPWMCLK/TBCLK | 100 MHz (`SYSCTL_EPWMCLK_DIV_2`) |
| PWM | 50 kHz up-count, `TBPRD=1999` |
| ADC prescale | divide-by-4, DriverLib `ADC_CLK_DIV_4_0` (value 6) |
| ADCCLK | 50 MHz |
| Resolution/mode | 16-bit differential |
| ACQPS | 63 = 64 SYSCLK = 320 ns |
| Conversion occupancy | 119 SYSCLK = 595 ns |
| Result latency | 120 SYSCLK = 600 ns |
| Start-to-next-start | 915 ns |
| Sustainable rate | 1,092,896.175 samples/s/module |
| External reference | 2.5 V; VREFCM=1.25 V |
| Engineering ENOB | 13.5; sensitivity sweep 12.5–14.65 |

The `ACQPS+1` definition, 320 ns minimum, 50 MHz ADCCLK limit and 100 MHz EPWMCLK limit have all been applied at register level. The authoritative values and citations are in `table_f28379d_adc_truth.csv` and `sources/datasheet_extract.md`.

## Difference from v2.2

v2.2 used a parameterized “native 16-bit, 1.1 MSPS, ENOB 13.5” profile. v2.3 replaces it with the selected F28379D's real acquisition aperture, pipeline, differential/common-mode limits, input RC, pin/package mapping, reference, ePWM clock limit and errata. The 1.1 MSPS headline is consistent, but it did not prove that a 2 us three-point window contained three complete sample apertures.

For N=3, the start timestamps span `2×0.915=1.830 us`; adding the last 320 ns aperture gives `2.150 us`. Thus v2.2's W=2.0 us case is a point-timestamp false pass. The final W=2.2 us case passes with 50 ns margin.

## ENOB interpretation

TI's 14.65-bit value is a typical AC characterization result at 2.5 V reference and 10 kHz input under controlled clock and layout conditions. It is not a guaranteed worst-case production number. The verification baseline is 13.5 ENOB, with 12.5, 13, 13.5, 14 and 14.65 included in sensitivity analysis.

## Four-ADC synchronous proof

- Same 50 MHz ADCCLK: yes.
- Same 16-bit differential mode: yes.
- Same `ACQPS=63`: yes.
- Same ADCIN2/3 pair index: yes.
- Same ePWM SOC event for each corresponding SOC: yes.
- Same all-round-robin priority and burst disabled: yes.
- All modules powered before enabling triggers: required by initialization order.
- Software forces used for synchronous sampling: no.

Asynchronous 16-bit operation is excluded from the selected architecture.
