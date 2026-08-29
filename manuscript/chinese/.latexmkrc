# Chinese manuscript build config.
# references.bib lives in manuscript/ (shared with the English master).
# bibtex runs inside build/, latexmk checks from chinese/ -- cover both.
$ENV{'BIBINPUTS'} = '..;../..;' . ($ENV{'BIBINPUTS'} // '');
$pdf_mode = 5;  # xelatex
