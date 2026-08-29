# TPEL Letters Submission Checklist

Venue requirements verified 2026-08-26 against the official sources:
- IEEE PELS TPEL page: https://www.ieee-pels.org/publications/transactions-on-power-electronics/
- "Guidelines for Manuscript Submission to IEEE Transactions on Power
  Electronics" (REV 2025 PDF):
  https://www.ieee-pels.org/wp-content/uploads/2025/07/REV-2025-TPEL-Guidelines-for-Manuscript-Submission.pdf

## Hard requirements vs. current state

| Requirement (verbatim basis) | Rule | Current state |
|---|---|---|
| Page limit | "Letters should be no longer than four pages (including references). Manuscripts longer than four pages will not be reviewed." No overlength for Letters. | **3 pages — PASS** (one page of headroom) |
| Format | Double-column, single-spaced, letter-size; standard IEEE journal template | IEEEtran journal mode — PASS |
| Abstract | 150-200 words | **190 words — PASS** |
| Review model | Single-anonymous; "author bylines are required by IEEE at all stages of the review process," byline must match the submission-system author list | **FAIL until fixed: byline is "Anonymous Author(s)" — replace with real authors/affiliations in BOTH `letter/main.tex` and `manuscript/main.tex`** |
| Biographies/photos | Excluded from initial submission | None present — PASS |
| Figures/tables | No per-item caps; must be interspersed and count toward the 4 pages | 1 figure, 2 tables interspersed — PASS |
| Supplementary | Allowed (general provision, not excluded for Letters) | None planned — OK |

## Submission mechanics

- Submission via the IEEE Author Portal
  (https://ieee.atyponrex.com/submission/dashboard?siteName=tpel-ieee);
  peer review runs in ScholarOne.
- Designate the manuscript type as **Letter** for expedited review.
- A mandatory **institutional primary email** is required for the
  submitting author.
- No cover page; add a first-page footnote if any content was previously
  presented at a conference (not applicable here).
- No graphical abstract or novelty statement is required for Letters.

## Remaining pre-submission edits (author actions)

1. Replace the byline in `main.tex` with real authors + affiliations +
   the institutional email (and do the same in the companion
   `manuscript/main.tex` — TPEL is single-anonymous for both).
2. Update reference [5] (`companion2026` in `references.bib`) once the
   companion paper has a submission identifier or DOI.
3. Re-run `latexmk -pdf -outdir=build main.tex` and confirm the page
   count stays at or below 4 after the real byline is inserted.
