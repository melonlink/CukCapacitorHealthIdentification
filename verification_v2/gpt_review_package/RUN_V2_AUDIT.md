# Verification v2 Execution Audit

- Runtime: MATLAB R2023b with Simulink and Simscape Electrical through the configured MATLAB MCP.
- Branch: `verification-v2`.
- v1 directory modified: no.
- Baseline cliff: reproduced; Gate A PASS.
- Timing DOE: 337 delay rows, 1,200 jitter rows, 120 window rows, 90 ESL/timing rows, 15 front-end rows, 480 ADC/phase rows, 180 absolute-noise rows.
- Blind regression: 51/51 CCM PASS; 24 DCM excluded/frozen.
- Model B: 3/4 PASS; 20 nH + 500 ns + 50 ns RMS jitter FAIL.
- Output audit: 13 mandatory tables, 20 PNG + 20 FIG, 2,778 metric rows, 65 fields.
- Required v2 metric fields missing: 0.
- MATLAB Code Analyzer: 14/14 new `.m` files checked, 0 issue files.
- Simulink Model B structural check: healthy; no unconnected ports or lines.
- Projection audit: failed rows retain maximum-deviation pre-projection C/ESR diagnostics and final post-projection estimates.

The full reproducible entry point is `../scripts/run_v2_all.m`; the fast output-only audit is `../scripts/validate_v2_outputs.m`.
