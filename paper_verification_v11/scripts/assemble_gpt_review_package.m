%% Assemble the audited GPT review package without changing evidence.

scriptDir = fileparts(mfilename("fullpath"));
packageRoot = string(fileparts(scriptDir));
reviewRoot = fullfile(packageRoot, "gpt_review_package");
reviewTableDir = fullfile(reviewRoot, "tables");
reviewFigureDir = fullfile(reviewRoot, "figures");
reviewRawDir = fullfile(reviewRoot, "raw");
reviewLogDir = fullfile(reviewRoot, "logs");
reviewFolders = [reviewRoot, reviewTableDir, reviewFigureDir, ...
    reviewRawDir, reviewLogDir];
for k = 1:numel(reviewFolders)
    if ~isfolder(reviewFolders(k))
        mkdir(reviewFolders(k));
    end
end

reportNames = [
    "FACTORIAL_PROTOCOL.md"
    "OBSERVATION_FACTORIAL_RESULTS.md"
    "PAPER_THEORY_PROOF_V11.md"
    "PAPER_VERIFICATION_V11_RESULT.md"
    "PAPER_READY_UPDATE_V11.md"
    "result_metrics_paper_v11.csv"
    "LOCKED_FACTORIAL_HYPERPARAMETERS.csv"
    ];
for k = 1:numel(reportNames)
    copyfile(fullfile(packageRoot, reportNames(k)), ...
        fullfile(reviewRoot, reportNames(k)), "f");
end

tableNames = [
    "table_observation_estimator_factorial.csv"
    "table_observation_effect_bootstrap.csv"
    "table_factorial_dynamic.csv"
    "table_physical_PE_lower_bound.csv"
    "table_covariance_bound_validation.csv"
    "table_projection_on_off.csv"
    "table_paper_final_claims_v11.csv"
    ];
for k = 1:numel(tableNames)
    copyfile(fullfile(packageRoot, "results", "tables", tableNames(k)), ...
        fullfile(reviewTableDir, tableNames(k)), "f");
end

figureFiles = dir(fullfile(packageRoot, "results", "figures", ...
    "fig_pv11_*.png"));
for k = 1:numel(figureFiles)
    copyfile(fullfile(figureFiles(k).folder, figureFiles(k).name), ...
        fullfile(reviewFigureDir, figureFiles(k).name), "f");
end

copyfile(fullfile(packageRoot, "results", "raw", ...
    "factorial_rows.csv"), fullfile(reviewRawDir, ...
    "factorial_rows.csv"), "f");
copyfile(fullfile(packageRoot, "results", "raw", ...
    "factorial_dynamic_history.csv"), fullfile(reviewRawDir, ...
    "factorial_dynamic_history.csv"), "f");
copyfile(fullfile(packageRoot, "logs", ...
    "audit_paper_verification_v11.txt"), fullfile(reviewLogDir, ...
    "audit_paper_verification_v11.txt"), "f");

reviewText = strjoin([
    "# GPT review package -- Paper Verification v1.1"
    ""
    "Final evidence decision: REOPEN_ALGORITHM."
    "Primary supported innovation: OBSERVATION."
    ""
    "Start with PAPER_VERIFICATION_V11_RESULT.md, then inspect " + ...
        "PAPER_THEORY_PROOF_V11.md and PAPER_READY_UPDATE_V11.md."
    "The tables folder contains all seven mandatory summary tables; " + ...
        "figures contains all ten mandatory figures."
    "raw/factorial_rows.csv retains all 4608 paired rows and all negative " + ...
        "effects. No row was removed."
    "logs/audit_paper_verification_v11.txt records AUDIT=PASS and the " + ...
        "frozen-core SHA-256."
    ""
    "Blocking result: O1-E3 failed to converge within the 257-cycle " + ...
        "post-step horizon for both C->0.8C and ESR->2R. This package " + ...
        "does not modify or retune the frozen TS-SLTVKE core."
    ], newline);
[fid, message] = fopen(fullfile(reviewRoot, ...
    "README_GPT_REVIEW.md"), "w");
assert(fid >= 0, "pv11review:WriteFailure", "%s", message);
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, char(reviewText), "char");
fprintf("GPT review package assembled: %s\n", reviewRoot);
