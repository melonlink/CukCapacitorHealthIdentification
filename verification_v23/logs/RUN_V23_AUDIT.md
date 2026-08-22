# v2.3 run audit

- MATLAB: R2023b Update 1 through the configured MCP session.
- Model: unchanged `verification_v2/model/cuk_simscape_circuit_model_v2.slx`, executed using `Simulink.SimulationInput` via `run_modelB_v21`.
- Model B runs: low CCM, nominal, high load and high duty; 50,001 resampled points per run.
- Monte Carlo: 200 deterministic seeds for each of seven conditions, 1,400 seed rows total.
- Key correction: EPWMCLK is 100 MHz at 200 MHz SYSCLK; final `TBPRD=1999` and compare values use 10 ns ticks.
- Result: all Gates A–H pass; worst p95 C=1.6425%, ESR=2.6109%; minimum threshold pass fraction=100%.
- Firmware: DriverLib APIs statically checked against TI official headers/guides; `NOT_COMPILED` because local C2000Ware is absent.
- DMA address proof: 10-word burst uses +1 source/destination burst steps and -9/+1 transfer steps, returning RESULT9 to RESULT0 while appending the next frame row.
- Tests: see final MATLAB test output and `validate_v23_outputs` audit.
