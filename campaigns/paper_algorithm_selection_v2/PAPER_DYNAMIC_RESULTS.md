# Paper dynamic results

Abrupt C, ESR, and joint steps are retained only as estimator stress tests. The primary health results are linear and smooth C-down, ESR-up, and joint ramps at 0.1/1/10/100 s.

## Ramp summary

- 0.1 s: RLS combined nRMSE 0.1161, TS-SLTVKE 0.2160; normalized lag 8.053% versus 22.027%; dominance result: TS-D-RLS.
- 1.0 s: RLS combined nRMSE 0.0163, TS-SLTVKE 0.0454; normalized lag 1.360% versus 3.537%; dominance result: TS-D-RLS.
- 10.0 s: RLS combined nRMSE 0.0160, TS-SLTVKE 0.0456; normalized lag 1.752% versus 4.492%; dominance result: TS-D-RLS.
- 100.0 s: RLS combined nRMSE 0.0213, TS-SLTVKE 0.0477; normalized lag 2.827% versus 4.868%; dominance result: TS-D-RLS.

Threshold results cover C/C0 = 0.95/0.90/0.85 and ESR/ESR0 = 1.25/1.50/1.75. A missed detection is preserved as a failure row.

## Interpretation boundary

Failure on an artificial fast ramp means finite health-tracking bandwidth; it does not imply failure for physical capacitor aging. `source_model` separates trace-derived long ramps from switching-equation cross-checks.
