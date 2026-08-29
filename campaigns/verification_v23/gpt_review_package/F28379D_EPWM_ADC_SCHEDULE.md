# F28379D ePWM/ADC schedule

## Clock and timer basis

SYSCLK is 200 MHz, but SPRS880P limits EPWMCLK to 100 MHz. Firmware therefore calls `SysCtl_setEPWMClockDivider(SYSCTL_EPWMCLK_DIV_2)`. With no additional TBCLK prescale, a 50 kHz up-counter uses `TBPRD=1999` and a 10 ns compare tick.

The selected policy is E1: one rising edge per PWM cycle. It is robust over D=0.25–0.65; a both-edge scheme causes burst collisions in the short state at D=0.25 and is not the first-hardware configuration.

## Register-realizable events

| ePWM event | Compare expression/count | Time at D=0.4 | ADC SOCs | Purpose |
|---|---:|---:|---|---|
| EPWM2 SOCA | CMPA=50 | 0.5 us | SOC3–5 | three post-edge samples |
| EPWM2 SOCB | CMPB=350 | 3.5 us | SOC6 | C on-state start |
| EPWM3 SOCA | CMPA=`2000D-80` (720) | 7.2 us | SOC7 | C on-state end |
| EPWM3 SOCB | CMPB=`2000D+80` (880) | 8.8 us | SOC8 | C off-state start |
| EPWM4 SOCA | CMPA=1650 | 16.5 us | SOC9 | C off-state end |
| EPWM4 SOCB | CMPB=1730 | 17.3 us | SOC0–2 | three pre-edge samples |

Within each three-SOC burst, conversion starts are separated by 915 ns. The complete acquisition span is 2.150 us. Four ADC modules receive the same event and queue the same SOC indices, so they sample synchronously module-to-module while each module serializes its own three conversions.

There are ten conversions/ADC/PWM period. ADC occupancy is `10×0.915/20=45.75%`; no SOC queue or cycle overrun exists. SOC2 is the last result of a cycle and produces late ADCINT1. Four DMA channels each copy RESULT0–9 into a 1024-cycle frame: 80 bytes/cycle, 4.0 MB/s total and 81,920 bytes/frame.

The full mapping is in `table_epwm_soc_schedule.csv`; DriverLib implementation is under `firmware_reference/`.
