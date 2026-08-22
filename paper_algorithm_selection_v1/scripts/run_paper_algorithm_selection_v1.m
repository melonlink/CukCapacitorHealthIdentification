% Run Paper Algorithm Selection v1 from frozen inputs through final audit.
scriptDir = string(fileparts(mfilename("fullpath")));
packageRoot = string(fileparts(scriptDir));
repositoryRoot = string(fileparts(packageRoot));
addpath(char(scriptDir));
addpath(char(fullfile(packageRoot, "algorithms")));
addpath(char(fullfile(packageRoot, "datasets")));

summary = paper_algorithm_selection_engine(packageRoot);
fprintf("Algorithm selection decision: %s\n", summary.decision);
fprintf("Static/abrupt/ramp/transient rows: %d/%d/%d/%d\n", ...
    summary.static_rows, summary.abrupt_rows, summary.ramp_rows, ...
    summary.transient_rows);

run(fullfile(scriptDir, "validate_paper_algorithm_selection_v1.m"));
assemble_gpt_review_package(packageRoot, repositoryRoot);
fprintf("Paper Algorithm Selection v1 completed and review package assembled.\n");
