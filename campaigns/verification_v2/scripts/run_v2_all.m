function summary=run_v2_all(v2Root)
%RUN_V2_ALL Reproduce the complete v2 verification package in MATLAB R2023b.

if nargin<1, v2Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v2Root);
addpath(genpath(fullfile(repoRoot,"cuk_cap_health_verification")),genpath(v2Root));
close all force;

fprintf('Verification v2 root: %s\n',v2Root);
baseline=run_v2_baseline(v2Root);
[locked,training]=train_v2_covariance(v2Root);
timing=run_v2_timing_doe(v2Root);
analysis=run_v2_analysis(v2Root);
metrics=generate_result_metrics_v2(v2Root);
reviewDir=package_v2_for_gpt(v2Root);

summary=struct("baseline",baseline,"locked",locked,"trainingRows",height(training), ...
    "timing",timing,"analysis",analysis,"metricRows",height(metrics), ...
    "reviewDirectory",reviewDir);
save(fullfile(v2Root,"results","raw","run_v2_all_summary.mat"),"summary","-v7.3");
fprintf('Verification v2 complete: %d metric rows; review package: %s\n', ...
    height(metrics),reviewDir);
end
