# Verification v2 — Timing-Robust Cuk Capacitor Health Identification

This directory implements the v2.0 strengthening task without modifying the
v1 package in `../cuk_cap_health_verification/`.

The batch entry point is `scripts/run_v2_all.m`. All numerical tests use the
locked v1 Model A equations; required circuit-level stress points reuse the
independent Simscape Electrical Model B through `Simulink.SimulationInput`.

Outputs are written to `results/tables`, `results/figures`, and `results/raw`.
The two final review documents are `V1_V2_COMPARISON.md` and
`RESULT_V2_FOR_CHATGPT.md`.

Actual MATLAB R2023b execution produced 51/51 blind CCM passes, 3/4 required
Simscape Model B passes, 2,778 unified metric rows, and 20 PNG + 20 FIG plots.
The scientific grade is C (partially supported): the Preferred 200 ns timing
point is supported, while 500 ns and the aggressive Model A ESL/ringing model
remain explicit failures.

Use `scripts/validate_v2_outputs.m` for a fast deliverable audit. The dedicated
`gpt_review_package/` directory contains the reports, all CSV tables, and all
20 PNG figures for external review.
