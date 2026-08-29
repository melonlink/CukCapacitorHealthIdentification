# v2.3 official source index

Retrieved 2026-08-22 from TI-controlled endpoints. These three PDFs are the device source of truth; v2.2 parameterized ADC profiles are not used as F28379D specifications.

| Document | Revision | Local file | SHA-256 | Official URL |
|---|---:|---|---|---|
| TMS320F2837xD datasheet, SPRS880 | P (Feb 2024) | `SPRS880P_TMS320F2837xD_datasheet.pdf` | `CDC174FFD7195B56149A8261F2F3CF167208350E563CD1B17789D3207F6A8E52` | https://www.ti.com/lit/ds/symlink/tms320f28379d.pdf |
| TMS320F2837xD TRM, SPRUHM8 | K (May 2024) | `SPRUHM8K_F2837xD_TRM.pdf` | `C55F033DE84039581BB3228DB827EE2DF0E6958803C7B29D140E67D6F777EE97` | https://www.ti.com/lit/ug/spruhm8k/spruhm8k.pdf |
| TMS320F2837xD silicon errata, SPRZ412 | N (May 2024) | `SPRZ412N_F2837xD_errata.pdf` | `7BB959008DB3744B6C8216FFD1A19537467ED8C7107283D91556C2680C1D1FC5` | https://www.ti.com/lit/er/sprz412n/sprz412n.pdf |

DriverLib API names were statically checked against TI's F2837xD guides and current official C2000Ware source:

- ADC: https://software-dl.ti.com/C2000/docs/C2000_driverlib_api_guide/f2837xd/build/html/modules/adc.html
- ePWM: https://software-dl.ti.com/C2000/docs/C2000_driverlib_api_guide/f2837xd/build/html/modules/epwm.html
- DMA: https://software-dl.ti.com/C2000/docs/C2000_driverlib_api_guide/f2837xd/build/html/modules/dma.html
- SysCtl: https://software-dl.ti.com/C2000/docs/C2000_driverlib_api_guide/f2837xd/build/html/modules/sysctl.html
- C2000Ware repository: https://github.com/TexasInstruments/c2000ware-core-sdk

The local computer has CCS 11.2 but no C2000Ware F2837xD DriverLib tree, so firmware status is `NOT_COMPILED`.
