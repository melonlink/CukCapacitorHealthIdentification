# Paper Algorithm Selection v3

Extends the frozen v2 selection campaign with M4 TS-SRKE. Imports the
v1.3 factorial rows; reruns all dynamic scenarios locally on the frozen
O1 streams. M1-M3 static summary reproduces v2 with max |delta| = 0
(invariance check in the runner). Decision under predeclared criteria:
PRIMARY_TS_SRKE. Run: `scripts/run_paper_algorithm_selection_v3.m`.
Note: the internal PNG figures in results/figures use a legacy 3-color
array (cosmetic warnings); manuscript figures are drawn from the CSVs by
`manuscript/figures/generate_manuscript_figures_v06.m`.
