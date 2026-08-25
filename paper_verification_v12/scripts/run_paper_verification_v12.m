%% Paper Verification v1.2 recalibrated reproducible entry point
% Regenerates all factorial, theory, projection, report, and audit outputs.

clearvars;
close all;
scriptDir = fileparts(mfilename("fullpath"));
packageRoot = string(fileparts(scriptDir));
addpath(scriptDir);

fprintf("Paper Verification v1.2: package root = %s\n", packageRoot);
paper_verification_v12_engine(packageRoot);
run(fullfile(scriptDir, "validate_paper_verification_v12.m"));
run(fullfile(scriptDir, "assemble_gpt_review_package.m"));
fprintf("Paper Verification v1.2: complete and audited.\n");
