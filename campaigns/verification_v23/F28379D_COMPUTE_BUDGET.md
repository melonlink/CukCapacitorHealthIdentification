# F28379D compute and memory budget

The 50 kHz PWM deadline is 20 us. The static CPU/CLA allocation is:

| Stage | Budget |
|---|---:|
| DMA completion/ownership | 4.5 us |
| Feature extraction | 3.0 us |
| TS-SLTVKE update | 5.0 us |
| Diagnostics/NIS/gating | 1.5 us |
| Reserved timing margin | 6.0 us |
| Total | 20.0 us |

Ten 16-bit results from four ADCs are 80 bytes/PWM cycle and 4.0 MB/s. A 1024-cycle frame is 81,920 bytes. DMA uses four of six channels. `ts_sltvke_step.c` performs the frame accumulation, NIS gating, scalar covariance updates and parameter projection without dynamic allocation.

This is a static feasibility budget, not measured target WCET. CCS 11.2 is present but C2000Ware/DriverLib and a target compiler project are absent, so firmware is correctly marked `NOT_COMPILED`. Before firmware freeze, compile for F28379D CPU1, verify RAM linker placement, measure worst-case cycles with cache/flash wait states, and require the measured non-reserve total to remain ≤14 us. The 6 us reserve is not available to communication or unrelated control tasks until profiling closes.
