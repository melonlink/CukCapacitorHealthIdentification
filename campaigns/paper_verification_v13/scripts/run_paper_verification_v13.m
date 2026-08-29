function summary = run_paper_verification_v13()
%RUN_PAPER_VERIFICATION_V13 Execute the v1.3 factorial (E1-E3 + E4 TS-SRKE)
% and verify that the E1-E3 rows reproduce the frozen v1.2 campaign exactly
% (the observation streams are seeded per condition and shared, so adding
% E4 must not disturb them).

scriptDir = fileparts(mfilename("fullpath"));
packageRoot = string(fileparts(scriptDir));
repoRoot = fileparts(packageRoot);
addpath(scriptDir);

summary = paper_verification_v13_engine(packageRoot);

% --- Invariance check: E1-E3 rows must match frozen v1.2 exactly. ---
new = readtable(fullfile(packageRoot, "results", "raw", ...
    "factorial_rows.csv"), "TextType", "string");
old = readtable(fullfile(repoRoot, "paper_verification_v12", ...
    "results", "raw", "factorial_rows.csv"), "TextType", "string");
keys = ["case_id", "noise_profile", "skew_ns", "observation", "estimator"];
sub = new(ismember(new.estimator, unique(old.estimator)), :);
sub = sortrows(sub, keys);
old = sortrows(old, keys);
assert(height(sub) == height(old), "pv13:RowCount");
checkCols = ["C_error_percent", "ESR_error_percent", "convergence_cycles"];
maxDelta = 0;
for c = checkCols
    maxDelta = max(maxDelta, max(abs(sub.(c) - old.(c))));
end
fprintf("v1.3 invariance check: E1-E3 max |delta| = %.3e over %d rows\n", ...
    maxDelta, height(sub));
assert(maxDelta < 1e-9, "pv13:InvarianceBroken");
fprintf("v1.3 complete: %d factorial rows (E4 included).\n", height(new));
end
