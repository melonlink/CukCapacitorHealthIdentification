function summaries = run_all(rootDir)
%RUN_ALL Reproduce the complete Cuk capacitor-health verification package.

if nargin<1, rootDir=fileparts(fileparts(mfilename("fullpath"))); end
addpath(genpath(rootDir));
fprintf('Cuk capacitor-health verification: %s\n',rootDir);

summaries=struct();
run_simulink_model_a(rootDir);
summaries.ideal=run_ideal_validation(rootDir);
run_simscape_model_b(rootDir,.01);
summaries.modelCross=run_model_cross_validation(rootDir);
summaries.sweep=run_parameter_sweep(rootDir);
summaries.noiseFull=run_noise_tests(rootDir);
summaries.noiseAllDefinitions=run_noise_ripple_tests(rootDir);
summaries.sampling=run_sampling_tests(rootDir);
summaries.dynamic=run_dynamic_tests(rootDir);
summaries.nonideal=run_nonideal_tests(rootDir);
summaries.metrics=generate_result_metrics(rootDir);

fprintf('Verification complete. Review RESULT_FOR_CHATGPT.md and results/tables/result_metrics.csv.\n');
end
