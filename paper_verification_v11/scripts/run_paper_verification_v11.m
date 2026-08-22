%% Paper Verification v1.1 reproducible entry point
% Regenerates all factorial, theory, projection, report, and audit outputs.

clearvars;
close all;
scriptDir = fileparts(mfilename("fullpath"));
packageRoot = string(fileparts(scriptDir));
addpath(scriptDir);

fprintf("Paper Verification v1.1: package root = %s\n", packageRoot);
paper_verification_v11_engine(packageRoot);
run(fullfile(scriptDir, "validate_paper_verification_v11.m"));
run(fullfile(scriptDir, "assemble_gpt_review_package.m"));
fprintf("Paper Verification v1.1: complete and audited.\n");

