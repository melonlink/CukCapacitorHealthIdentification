# Final estimator decision

1. **Does O1-RLS retain the v1.2 static advantage?** Yes for ESR, convergence, and complexity; C mean MAPE is 0.3727% versus 0.3011%.
2. **Was the TS-SLTVKE abrupt failure reproduced?** Yes. Both frozen C and ESR 257-cycle failure flags are 1/1.
3. **Who is better at 0.1 s?** TS-D-RLS.
4. **Who is better at 1 s?** TS-D-RLS.
5. **Who is better at 10 s?** TS-D-RLS.
6. **Who is better at 100 s?** TS-D-RLS.
- 0.1 s: RLS combined nRMSE 0.1161, TS-SLTVKE 0.2160; normalized lag 8.053% versus 22.027%; dominance result: TS-D-RLS.
- 1.0 s: RLS combined nRMSE 0.0163, TS-SLTVKE 0.0454; normalized lag 1.360% versus 3.537%; dominance result: TS-D-RLS.
- 10.0 s: RLS combined nRMSE 0.0160, TS-SLTVKE 0.0456; normalized lag 1.752% versus 4.492%; dominance result: TS-D-RLS.
- 100.0 s: RLS combined nRMSE 0.0213, TS-SLTVKE 0.0477; normalized lag 2.827% versus 4.868%; dominance result: TS-D-RLS.
7. **Does TS-SLTVKE remain materially delayed for slow health change?** Yes in the 1/10/100 s aggregate comparisons; conclusions remain rate-specific.
8. **Is RLS false-health response worse?** Mixed, not an overall TS dominance. Mean peak C false health is 1.3017% for RLS and 0.7570% for TS-SLTVKE, while mean peak ESR false health is 1.8474% versus 5.1919%; RLS also recovers faster in this campaign.
9. **Does TS-SLTVKE confidence provide a material advantage?** Yes for calibration, but it does not reverse the overall Pareto result. Joint coverage is 88.93% versus the RLS auxiliary 13.00%; this is reported as an extension-level benefit unless it reverses the core Pareto relation.
10. **Which is cheaper on F28379D?** TS-D-RLS: 28 versus 46 multiplications per observation.
11. **Primary realization?** `TS-D-RLS` for the first manuscript; overall decision token `DUAL_REALIZATION`.
12. **Role of the other estimator?** `TS-SLTVKE` is the uncertainty-aware health-reporting extension; Dual EKF remains a third reference.
13. **Can formal manuscript drafting start?** Yes, with all source-model and stress-versus-aging limitations stated.

Final machine-readable decision:

```text
DUAL_REALIZATION
```
