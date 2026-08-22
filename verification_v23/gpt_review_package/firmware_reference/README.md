# F28379D firmware reference

Status: `NOT_COMPILED`.

This folder is a DriverLib-mapped implementation skeleton for C2000Ware F2837xD. The workstation has CCS 11.2 but no local C2000Ware/DriverLib headers or F28379D compiler project, so a truthful target build could not be performed. Function and enum names were checked against TI's F2837xD DriverLib API guide.

Locked configuration:

- 200 MHz SYSCLK, 100 MHz EPWMCLK/TBCLK (`SYSCTL_EPWMCLK_DIV_2`), and `TBPRD=1999`. ADC prescale `ADC_CLK_DIV_4_0` (register value 6) gives 50 MHz ADCCLK.
- 16-bit differential, `ADCIN2/ADCIN3`, `ACQPS=63` on ADCA through ADCD.
- Ten SOC results per ADC per 50 kHz cycle. SOC0-2 and SOC3-5 form the edge bursts; SOC6-9 support C charge integration.
- Late ADCINT1 from SOC2 triggers four DMA channels. Each event transfers RESULT0-9; 1024 events form a frame.
- DMA burst step is +1/+1; transfer step is -9/+1 so every event restarts at RESULT0 and appends the next ten-word destination row.
- Silicon revision C is required. `ADC_setMode` must execute after startup so mode-specific trims load.

Before hardware use, create a C2000Ware F2837xD CPU1 project, add these files, link each `ramgs*` section, run the compiler, inspect map-file RAM use, and profile `ts_sltvke_step` on the target. The static 20 us allocation is a pre-build budget, not measured WCET.
