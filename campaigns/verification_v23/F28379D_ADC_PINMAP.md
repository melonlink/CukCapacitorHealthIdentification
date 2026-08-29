# F28379D ADC pin and package map

## Selected PTP-176 map

| ADC | Positive | PTP pin | Negative | PTP pin | VREFHI | VREFLO |
|---|---|---:|---|---:|---:|---:|
| ADCA | ADCINA2 | 41 | ADCINA3 | 40 | 37 | 33 |
| ADCB | ADCINB2 | 48 | ADCINB3 | 49 | 53 | 50 |
| ADCC | ADCINC2 | 31 | ADCINC3 | 30 | 35 | 32 |
| ADCD | ADCIND2 | 58 | ADCIND3 | 59 | 55 | 51 |

The equivalent ZWT-337 pairs are U2/T2, V3/W3, R3/P3 and T6/U6. PTP-176 is recommended for the prototype because it provides all four clean differential ADCIN2/3 pairs, all four external reference pairs, ePWM resources, crystal pins, debug and communication resources with lower PCB escape complexity.

ADCINA0/A1 and ADCINB0/B1 are deliberately avoided because the datasheet documents additional loading/special functions on those pins. Each selected pair receives a symmetric 50 ohm isolation path and 330 pF charge reservoir at the ADC pins. Each VREFHI/VREFLO pair needs local analog-ground routing and the datasheet-specified reference decoupling.

PCB constraints: no digital traces through the four ADC/reference islands; matched differential routing; continuous analog return; reference capacitor beside pins; external crystal/PLL layout per TI; and measurement access for VREF, VREFCM and all four AFE outputs.
