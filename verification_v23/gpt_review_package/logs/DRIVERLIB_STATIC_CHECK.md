# F2837xD DriverLib static check

Status: `PASS_STATIC_API / NOT_COMPILED`.

Checked 2026-08-22 against TI's official F2837xD ADC/ePWM/DMA/SysCtl API guides and current `TexasInstruments/c2000ware-core-sdk` headers.

- ADC enums/functions confirmed: divide-by-4 enum value 6; 16-bit differential; ADCIN2/3 pair; EPWM2/3/4 SOCA/B triggers; SOC setup; end-of-conversion pulse; all-round-robin priority; continuous interrupt; overflow clear.
- ePWM enums/functions confirmed: 100 MHz EPWMCLK through `SYSCTL_EPWMCLK_DIV_2`; up-counter; compare A/B SOCA/B; event prescale 1; sync-out at counter zero; phase load on trigger timers.
- DMA enums/functions confirmed: ADCA1/B1/C1/D1 triggers; 16-bit burst/transfer/wrap API; four channels; end-of-transfer interrupt and overrun diagnostics.
- Address stepping checked: burst size 10 with source/destination step +1; after each burst, transfer step -9 returns RESULT9 to RESULT0 and +1 advances the destination to the next ten-word row.
- Errata mapping checked: late ADCINT from SOC2, continuous mode, mode-trim load and revision-C restriction.

Target compilation was not attempted because C2000Ware/DriverLib headers and a target compiler project are not installed. A C2000Ware CPU1 build and measured WCET remain mandatory before firmware release.
