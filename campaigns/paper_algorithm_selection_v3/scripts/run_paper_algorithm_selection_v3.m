% Run Paper Algorithm Selection v3 (adds M4 TS-SRKE) from the v1.3
% verification inputs. Validation: the M1-M3 static summary must reproduce
% the frozen v2 campaign exactly, because the imported O1 rows for E1-E3
% are invariant and the local dynamic streams are seed-identical.
scriptDir = string(fileparts(mfilename("fullpath")));
packageRoot = string(fileparts(scriptDir));
repoRoot = string(fileparts(packageRoot));
addpath(char(scriptDir));
addpath(char(fullfile(packageRoot, "algorithms")));
addpath(char(fullfile(packageRoot, "datasets")));

summary = paper_algorithm_selection_v3_engine(packageRoot);
fprintf("Algorithm selection decision: %s\n", summary.decision);

% Invariance check against the frozen v2 static summary (M1-M3 rows).
new = readtable(fullfile(packageRoot, "results", "tables", ...
    "table_algorithm_static_comparison.csv"), "TextType", "string");
old = readtable(fullfile(repoRoot, "paper_algorithm_selection_v2", ...
    "results", "tables", "table_algorithm_static_comparison.csv"), ...
    "TextType", "string");
keys = ["method", "mode"];
sub = sortrows(new(ismember(new.method, unique(old.method)), :), keys);
old = sortrows(old, keys);
cols = ["C_mean_MAPE_percent", "ESR_mean_MAPE_percent", ...
    "C_p95_percent", "ESR_p95_percent", "convergence_cycles_mean"];
maxDelta = 0;
for c = cols
    maxDelta = max(maxDelta, max(abs(sub.(c) - old.(c))));
end
fprintf("v3 invariance check: M1-M3 static max |delta| = %.3e\n", maxDelta);
assert(maxDelta < 1e-9, "algselv3:InvarianceBroken");
fprintf("Paper Algorithm Selection v3 completed.\n");
