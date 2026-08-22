# Target DSP ADC Profile — v2.2

## Status

```text
TARGET_DSP_NOT_FIXED
```

No DSP part number, C2000 device symbol, hardware configuration, ADC register
definition, or board BOM entry was found in the repository. The values below
are architecture references required by the v2.2 task and must not be cited as
silicon specifications.

| Reference mode | Nominal bits | Rate/channel | ENOB used | Status |
|---|---:|---:|---:|---|
| native_12bit_highspeed | 12 | 4.0 MS/s | 10.5 | parameterized |
| native_16bit_slow | 16 | 1.1 MS/s | 13.5 | parameterized |
| external_14bit_reference | 14 | 5.0 MS/s | 12.0 | control |
| external_16bit_reference | 16 | 5.0 MS/s | 13.5 | control |

The complete machine-readable profile, including every required unknown, is
in `results/tables/table_target_dsp_adc_profile_v22.csv`. INL, DNL, offset,
gain, reference noise, acquisition settling, channel skew, conversion latency,
SOC count, differential capability, and simultaneous conversion are explicitly
marked `DATASHEET_NOT_SPECIFIED` or `PARAMETER_SWEEP`.

## Parameterized channel/module assignment proposal

If the selected DSP provides four independent ADC modules or truly concurrent
sample-and-hold resources, use:

| Resource | Signal | Purpose |
|---|---|---|
| ADC-A | Vedge/Vripple | ESR edge observation only, ±2 V plant span |
| ADC-B | Vabs | absolute terminal voltage and C safe window, 0–80 V |
| ADC-C | i1 | synchronized current channel, 0–20 A |
| ADC-D | i2 | synchronized current channel, 0–20 A |

All modules must share the PWM time base. Vedge window bursts use the locked
guard/window/point schedule from `table_native_adc_geometry_v22.csv`; channel
timestamps must include measured acquisition and conversion latency.

If the actual DSP has fewer modules, this assignment is not valid by default.
MUX settling, sequential skew, charge kickback, aggregate sample-rate derating,
and SOC scheduling must be re-simulated from the selected datasheet. The v2.2
decision therefore becomes a device-selection requirement, not proof that an
unspecified DSP already has these resources.

## Datasheet closure checklist

Before schematic freeze, replace every parameterized entry with the selected
part's values and rerun v2.2. Required closure items are: part number; ADC
module count; resolution/rate combinations; ENOB or SINAD; single-ended and
differential ranges; SOC count; ePWM trigger routing; concurrent conversion;
acquisition window; conversion latency; reference range and drive; INL/DNL;
offset/gain error; source-impedance limit; aperture jitter; channel skew; and
temperature drift.
