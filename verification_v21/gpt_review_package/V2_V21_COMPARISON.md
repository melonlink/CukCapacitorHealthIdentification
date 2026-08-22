# v2 versus v2.1

| Item | v2 | v2.1 |
|---|---|---|
| ADC minimum support | 14-bit/8–16 spc claims from separate phase sweep | 1.6 MS/s/channel, 16-bit candidate from joint matrix; 0.8 MS/s rejected geometrically |
| ADC recommendation | ≥16 spc | 5 MS/s/channel, simultaneous 16-bit research bench |
| Edge window | 1.5–2 us recommendation mixed with slower ADC tests | 2 us with explicit phase geometry |
| Points/side | at least 3, not jointly consistent | worst-phase 3 at 1.6 MS/s; 10 at 5 MS/s |
| Voltage AFE | about 1 MHz minimum, 2 MHz better | second-order 2 MHz in selected joint region |
| Current AFE | separate bandwidth tests | second-order 1 MHz selected with voltage/ADC jointly |
| Alias handling | ADC and AFE tested separately | spectrum-based alias ratio plus phase and fsw ±1% asynchronous perturbation |
| Timing boundary | about ±200 ns from selected points | 50 ns worst-case; nominal 100 ns; high-D 200 ns |
| Estimator formulation | masked (H_V=[1,0,i_C]) gain | conditional (z_V), no gain mask, Joseph updates |
| Data reuse | possible overlap, independence implicit | disjoint V/C/R raw-index policy |
| Process noise | fixed per ADC sample | continuous-time (Q_c\Delta t), independent of ADC rate |
| Covariance consistency | C/R NIS very conservative | NIS/NEES/CI trained then locked; limits explicitly reported |
| Model A parasitic | arbitrary derivative + decaying ringing stress | historical only; removed as physical evidence |
| Model A-P | absent | attempted from 45 Model B rows; substitution rejected |
| Model B evidence | selected points including 20 nH | 45 edge-feature rows + 324 timing rows + 100-seed 20 nH scenario |
| Blind health validation | nominal-oriented 51 CCM operating sweep | 36 stratified C=80–100%, ESR=1–2× points; 36/36 accuracy, 31/36 full gate |
| Hardware readiness | broadly optimistic | conditional bench candidate; not an unqualified health-monitor freeze |

