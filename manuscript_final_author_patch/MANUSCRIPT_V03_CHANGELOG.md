# Manuscript v0.3 changelog

| ID | Section | Original issue | Revision | Scientific content changed? | Source check | Status |
|---|---|---|---|---|---|---|
| V03-001 | Baseline | Task named v0.26 although a recalibrated v0.27 existed | Used `manuscript_v027` as the latest frozen scientific baseline | NO | v0.27 final audit and recalibrated result manifest | COMPLETE |
| V03-002 | Title | Three alternatives required review | Retained the accurate current title; Abstract defines physically direction-decoupled observations | NO | theory/observation scope | COMPLETE |
| V03-003 | Abstract | Dense 13-page audit-style summary | Compressed to 205 TeXcount words and three quantitative groups | NO | v1.2/v2/v2.3 results | COMPLETE |
| V03-004 | Introduction | Literature categories and caveats were repetitive | Reorganized into five reviewer-facing paragraphs and shortened Table I wording | NO | bibliography audit and related-work matrix | COMPLETE |
| V03-005 | Section II | Full-precision `k_R` and commissioning wording appeared in Table III | Main-text display changed to `0.9772`; source identified as simulation calibration | NO — display only | calibration reproduction and PAR-020/PAR-048 | COMPLETE |
| V03-006 | Section III-B | `±0.006` estimator knowledge was ambiguous | Identified it as known casewise calibrated measurement-chain variation supplied identically to all estimators | NO | `generate_frozen_o1_stream.m` and common estimator calls | COMPLETE |
| V03-007 | Section III-B | Current simulation calibration could be read as hardware commissioning | Reserved commissioning for future hardware and added a precision statement | NO | calibration provenance | COMPLETE |
| V03-008 | Sections II–IV | Repeated conditionality and project-audit language | Tightened prose while retaining every observation equation and both propositions | NO | equation/label comparison with v0.27 | COMPLETE |
| V03-009 | Section IV | Proposition 2 competed with the primary identifiability result | Kept recursion/fixed point/interpretation in text and moved validated fixed-point values to Appendix B | NO | v1.2 PE/covariance invariant audit | COMPLETE |
| V03-010 | Section V | Standard-recursion exposition was longer than needed | Retained RLS/Kalman equations but emphasized topology-synchronous direction-specific application and uncertainty role | NO | estimator source/core checksum | COMPLETE |
| V03-011 | Section VI | Verification read as an engineering audit | Recast as a concise common-case fairness protocol; moved threshold detail to Supplementary S3 | NO | v1.2/v2 row-count audits | COMPLETE |
| V03-012 | Section VII-A | Bootstrap detail obscured the main attribution result | Retained core transitions and one ESR interval; preserved all paired intervals in Supplementary S3 | NO | factorial/bootstrap tables | COMPLETE |
| V03-013 | Section VII | Results repeated table values | Reduced narration to tradeoffs while retaining all adverse results and all table values | NO | algorithm-selection v2 results | COMPLETE |
| V03-014 | Operating transients | Fig. 8 consumed main-text space | Moved the trace to Supplementary Fig. S4; retained mixed-result paragraph | NO | transient result table/figure | COMPLETE |
| V03-015 | Complexity/uncertainty | Cost, WCET, cadence, and coverage were split across paragraphs | Combined the 28/46/62 cost and 13.00/88.93/81.90 coverage tradeoff | NO | complexity and coverage tables | COMPLETE |
| V03-016 | Section VIII | Register, DMA, utilization, common-mode, and margin detail dominated the feasibility claim | Main text retains ADC mode/count, aperture/window, AFE boundary, p95, and simulation status; details remain in S1 | NO | verification v2.3 | COMPLETE |
| V03-017 | Discussion | Eight audit-like limitations and repeated caveats | Merged into six evidence categories and shortened the experimental roadmap | NO | manuscript evidence boundary | COMPLETE |
| V03-018 | Conclusion | Repeated Abstract metrics | Reduced to 152 words; retained C/ESR MAPE and device p95 only | NO | v2/v2.3 final metrics | COMPLETE |
| V03-019 | Fig. 2 | Paths depended partly on color | Added dashed borders/arrows to the capacitance path and generated a grayscale preview | NO | visual QA | COMPLETE |
| V03-020 | Traceability | No v0.3 numeric freeze record | Added `SCIENTIFIC_CHECKSUM_V03.csv` and v0.3 claim/parameter display rows | NO | v0.27-to-v0.3 comparison | COMPLETE |
| V03-021 | Reviewer resistance | No consolidated attack audit | Added power-electronics, estimation/control, and reliability reviewer audits | NO | manuscript sections and evidence files | COMPLETE |
