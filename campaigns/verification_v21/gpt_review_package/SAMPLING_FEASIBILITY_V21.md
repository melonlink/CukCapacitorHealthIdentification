# Sampling Feasibility v2.1

The analytical and 64-phase enumeration confirms the v2 contradiction.
At 50 kHz switching, 16 samples/cycle is 0.8 MS/s and (T_a=1.25\,\mu s).
For three points, (A1) requires a 2.5 us span, so a requested 1.5–2 us
window cannot contain three uniformly spaced points on every side. In the
explicit (g=0.5\,\mu s, W=2\,\mu s, N_w=3) enumeration, 0.8 MS/s has zero
feasible phases and only one worst-phase point for every tested duty.

For the same guard/window/point count, 1.6 MS/s has three worst-phase points
and 100% phase feasibility for all tested duties
(D=[0.25,0.35,0.40,0.45,0.55,0.65]). It is therefore the geometric minimum
among the tested ADC rates. The margin gate also passes because
(g+W=2.5\,\mu s) is below the shortest 5 us state at D=0.25/0.75.

This does not by itself recommend 1.6 MS/s. The joint ADC/AFE table is the
accuracy and aliasing gate. It finds robust nominal-duty candidates beginning
at 1.6 MS/s, while 5 MS/s provides ten or more points per 2 us side and greater
headroom for asynchronous switching-frequency perturbations.

The edge bias/variance experiment contains 140 combinations: 29 are infeasible
and 111 are valid. At the recommended research configuration (5 MS/s,
0.5 us guard, 2 us window), the minimum observed samples/side is 10. For
(N_w=3), predicted and empirical single-edge ESR standard deviations are
1.006 and 1.011 mOhm, and the measured bias is -0.0587 mOhm. This agreement
supports the OLS propagation used in the estimator.

Hardware interpretation:

- 0.8 MS/s + 2 us + 3 points/side: rejected geometrically.
- 1.6 MS/s + 2 us + 3 points/side: tested geometric minimum and joint-design
  minimum candidate.
- 5 MS/s + 2 us + at least 10 observed points/side: recommended first research
  prototype configuration, subject to the timing boundary.
- Designed synchronous phase is reported separately and is not used to rescue
  a design that fails the 95% phase criterion.

Evidence is in `table_sampling_geometry_v21.csv`,
`table_edge_bias_variance_v21.csv`, and Figures 01–04.

