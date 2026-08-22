# Verification v2.3

Device-specific closure for the TMS320F28379D internal ADC. Run in MATLAB R2023b:

```matlab
addpath(genpath(fullfile(pwd,"verification_v23")));
run_v23_all(fullfile(pwd,"verification_v23"));
runtests(fullfile(pwd,"verification_v23","tests","v23PipelineTest.m"));
```

The pipeline runs the unchanged v2 Simscape Model B through `SimulationInput`, reconstructs the floating C1 terminals/common mode, generates device/AFE/schedule tables, performs 200×7 device-level Monte Carlo, writes 14 review figures and evaluates Gates A–H.

Final decision: `F28379D_INTERNAL_ADC_CONFIRMED_WITH_AFE_CONSTRAINTS`.
