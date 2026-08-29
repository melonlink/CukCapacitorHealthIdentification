# Editorial Polish Changelog (2026-08-25)

Language-only editorial pass. No frozen scientific-checksum number was
added, removed, or altered; all 16 checksum quantities remain in the
manuscript at their frozen values. Rebuilt with TeX Live 2025 latexmk:
0 errors, 0 undefined references, 0 overfull boxes, 11 pages (unchanged).

## Edits

1. Abstract: "mean capacitance and ESR absolute percentage errors of
   0.3727% and 0.2233%" -> "mean absolute percentage errors of 0.3727%
   in capacitance and 0.2233% in ESR" (clearer attachment of numbers).
2. Sec. I: related-work comparison now "categorical rather than
   numerical ... across studies"; roadmap sentence compressed.
3. Sec. II: expanded CCM, DCM, ESL at first use.
4. Sec. III: the previously unanchored "$\pm0.006$ spread" is now
   introduced as a declared case-wise spread about $\hat k_R$;
   NIS expanded at first use.
5. Sec. VI: convergence-cycles definition regrammared ("first cycle
   beginning 32 consecutive cycles ... unconverged cases are assigned
   the 1024-cycle horizon"); MAPE/p95 and Dual EKF expanded at first
   use; AFE expanded at first use; removed defensive clause "inventing
   one would not reproduce the published baseline".
6. Sec. VII: WCET expanded at first use.
7. Sec. VIII: "Direct ADC connection is invalid" -> "infeasible".
8. Sec. IX-A: removed verbatim repetition of Sec. VII-A numbers
   (numbers remain in Sec. VII-A; Discussion now cross-references).
9. Sec. IV: "persistent excitation (PE)" acronym introduced.
10. Appendix B: condensed the case-dependent mismatch remark.

## Verification

- `build/main.log`: 0 errors, 0 overfull hboxes, 11 pages.
- Pages 1 and 11 visually inspected at 110 dpi (title accent, abstract,
  appendices, references all render correctly; references end at [24]
  on page 11).
- Frozen values spot-checked present: 0.3727 / 0.2233 / 13.21 / 0.3011 /
  0.6446 / 0.3043 / 1.1938 / 0.217943 / 880.008 / 0.9772 / 0.12 / 2.0 /
  2.2 / 1.6425 / 2.6109.
