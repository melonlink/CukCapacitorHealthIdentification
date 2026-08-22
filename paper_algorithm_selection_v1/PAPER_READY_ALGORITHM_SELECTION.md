# Paper-ready algorithm selection

- Final architecture decision: **DUAL_REALIZATION**; primary manuscript realization: **TS-D-RLS**; extension: **TS-SLTVKE**.
- Preferred method name: topology-synchronized direction-specific RLS (TS-D-RLS) when M1 is selected; topology-synchronized structured linear time-varying Kalman estimator (TS-SLTVKE) when M2 is selected.
- Static C/ESR mean MAPE (M1/M2/M3): 0.3727/0.3011/0.3043% and 0.2222/0.6428/1.1923%.
- Complexity (M1/M2/M3): 28/46/62 multiplications per observation.
- Dynamic evidence: all C, ESR, and joint 0.1/1/10/100 s ramps are in `table_algorithm_ramp_tracking.csv`.
- Maximum reliable degradation rate (M1/M2/M3): C 0.2000/0.2000/0.0200 pu/s; ESR 1.0000/10.0000/10.0000 pu/s under the frozen 3%/5% error and 5% normalized-lag rule.
- Limitations: simulation/trace-derived evidence, no hardware aging experiment, no claim that an abrupt step is a physical aging rate.
- Selected tables: all ten `table_algorithm_*.csv` files.
- Selected figures: all twelve `fig_alg_*.png` files.
- Caption-ready statement: Under identical topology-decoupled O1 observations, estimator selection is governed by static error, health tracking bandwidth, transient immunity, uncertainty calibration, and same-basis embedded cost.
