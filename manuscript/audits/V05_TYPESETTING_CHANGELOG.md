# v0.5 Typesetting Changelog (2026-08-25)

Submission-grade figure and typography pass. Standard applied: the
evidence-based TPEL figure/axes standard distilled from five highly cited
IEEE power-electronics papers (Wang & Blaabjerg TIA 2014, >2000 citations;
Yao TPEL 2015 — both directly in this manuscript's reference list — plus
Peng TPEL 2021, Zhao TPEL 2022, Choksi TPEL 2023), from
`PUBLIC_SKILLS/control-paper-writing/references/tpel-figure-axes-standard.md`.

All 16 frozen scientific-checksum quantities unchanged. Build: 0 errors,
0 undefined references, 0 overfull boxes, 13 pages.

## Figure violations found and fixed (all nine data figures regenerated)

| Rule | Violation before | Fix |
|---|---|---|
| M5/F1 no in-figure titles | every multi-panel figure used MATLAB `title()` | titles removed; information moved to captions |
| M4 panel markers | (a)(b)(c) inside titles above panels | centered BELOW each panel, parentheses, not bold, 8 pt |
| M1 frame/ticks | `box on` mirrored ticks to top/right | box off + top/right frame drawn as data-space constant lines (tracks relayout) |
| M3/F5 units | "Capacitance (uF)", "ESR (ohm)" | upright µ (char 181) and mΩ (values rescaled ×10³) |
| M6 legends | frameless legends | framed in-axes legends (or direct curve labels, Fig. 11) |
| R3 grids/fonts | solid grids, uniform 8 pt | grids off; ticks 7 pt / labels 8 pt / legends & annotations 7 pt, Times |
| R6/R7 axes | auto log ticks on reversed axis | explicit tick vectors (Fig. 10: 100/50/20/10), 10^n labels |
| M9 event marking | transitions only in caption | "transition" annotated at the 30-ms line (Fig. 9); "all cycles rejected" region labeled (Fig. 10) |
| 1:1 export | Fig. 8 authored 7.16 in but placed at 5.87 in | re-authored at 5.87 in (fonts now true size) |
| F6 bold markers | Fig. 1 TikZ headers bold "(a)…" | panel letters unbolded; caption now enumerates (a)–(c) |

Single figure-generation entry point: `figures/generate_manuscript_figures_v05.m`
(supersedes `generate_vector_figures_v031.m` and
`generate_supplement_figures_v04.m`, both removed; git history retains them).
Closed-loop trajectories now flow through the frozen campaign CSV
`campaigns/closedloop_dcm_validation/results/tables/table_closedloop_history.csv`
(new export in the campaign script), keeping the redraw-from-frozen-CSV
discipline for every manuscript figure.

## Caption updates

Captions for Figs. 1, 4, 5, 6, 8 now enumerate their panels
"(a) …; (b) …" since the in-figure titles were removed.

## Text typography fixes

- Unit micro signs set upright via siunitx (`\si{\micro\second}` etc.) in
  Tables III/V/VIII, Secs. III–IV, VIII, and Supplementary Note S1; the
  mathematical information symbol µ in Sec. IV remains italic (a quantity,
  not a unit).
- Non-breaking spaces inserted between numbers and units (24~V, 50~kHz,
  0.12~A, 20.48~ms, 50~mΩ, …).
- "Buck/Boost" normalized to lowercase common nouns (Table I and Sec. I),
  fixing an internal inconsistency.

## Validation

- All nine regenerated PDFs rendered and visually inspected individually;
  all 13 manuscript pages rendered and inspected after integration.
- Frozen numbers spot-verified present in the rebuilt PDF.

## v0.5.1 addendum: shared-axis stacked panels

User review caught a remaining axis violation: panels stacked over a
common x-axis repeated their x tick numbers (and in one case the axis
title) on interior panel edges. Fixed in all five vertical stacks
(Figs. 4, 5, 6, 9, 10): interior panels keep tick marks but drop tick
labels and axis titles; only the bottom panel carries numbers and the
axis title. Tile spacing tightened accordingly; panel markers re-seated.
The side-by-side Fig. 8 correctly retains labels on both panels.
Verified by 160-300 dpi edge-crop inspection of all nine figures
(no tick marks on any top/right frame edge; no tick numbers on any
interior shared edge) and a clean 13-page rebuild.
