%% Paper Verification v1 reproducible entry point
% Regenerates the blind comparison, ablation, theory checks, tables,
% figures, reports, and audit log without modifying the frozen estimator.

clearvars;
close all;
scriptDir = fileparts(mfilename('fullpath'));
packageRoot = fileparts(scriptDir);
addpath(scriptDir);

fprintf('Paper Verification v1: package root = %s\n', packageRoot);
paper_verification_engine(packageRoot);
run(fullfile(scriptDir, 'validate_paper_verification_v1.m'));
fprintf('Paper Verification v1: complete and audited.\n');
