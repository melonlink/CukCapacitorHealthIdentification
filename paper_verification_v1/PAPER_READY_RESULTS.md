# Paper-ready results

## Final numerical statements

- Physical traceability: 45 frozen Model-B switching traces loaded by the entry script.
- Common blind design: 48 operating/health points x 4 noise profiles x 4 residual-skew levels x 6 algorithms = 4608 retained rows.
- TS-SLTVKE: C MAPE 0.301% (p95 1.116%); ESR MAPE 0.577% (p95 2.134%).
- A0 to A6: C MAPE 0.394% -> 0.170%; ESR MAPE 3.807% -> 3.101%.
- PE validation: log-information/log-variance correlation -0.9969 (C), -0.9969 (ESR).
- TS-SLTVKE computational estimate: 46 multiplications/update, 2.12 us/update on the stated F28379D arithmetic budget.

## Final figures

1. `results/figures/fig_paper_01_sota_accuracy.png` — blind accuracy.
2. `fig_paper_02_sota_noise.png` — noise robustness.
3. `fig_paper_03_sota_timing.png` — residual-skew robustness.
4. `fig_paper_04_sota_dynamic.png` — C and ESR steps.
5. `fig_paper_05_ablation_C.png` — C ablation.
6. `fig_paper_06_ablation_ESR.png` — ESR ablation.
7. `fig_paper_07_ablation_timing.png` — timing contribution.
8. `fig_paper_08_ablation_confidence.png` — CI consistency.
9. `fig_paper_09_PE_vs_variance.png` — PE versus variance.
10. `fig_paper_10_information_vs_convergence.png` — information versus convergence.
11. `fig_paper_11_complexity.png` — operation cost.
12. `fig_paper_12_summary_radar_or_pareto.png` — accuracy/complexity Pareto view.

## Final tables

- `table_paper_sota_comparison.csv`: complete p50/p95/max and failure statistics.
- `table_paper_ablation.csv`: all A0-A6/scenario metrics and incremental gains.
- `table_paper_PE_analysis.csv`: information, CRLB, empirical variance, and convergence.
- `table_paper_complexity.csv`: dimensions, arithmetic, memory, samples, and latency.
- `table_paper_blind_cases.csv`: frozen 48-point design and initialization.
- `table_modelB_anchor_traceability.csv`: the 45 Model-B source traces used to calibrate current and edge-slope scales.

## Caption-ready result statement

Across the full non-cherry-picked blind matrix, conventional integral RLS and Dual EKF achieved lower static mean error than TS-SLTVKE. The proposed method nevertheless converged fastest with no divergence and retained explicit topology-synchronous C/ESR directions, excitation gates, and scalar inversions. The result supports a structural/interpretability contribution, not a universal numerical-SOTA claim.
