function summary=run_v21_all(v21Root)
%RUN_V21_ALL Reproduce the complete v2.1 verification package in R2023b.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
run_v21_theory(v21Root);
train_v21_covariance(v21Root);
run_v21_estimator_statistics(v21Root);
run_v21_adc_afe_joint(v21Root);
run_v21_parasitic_reconciliation(v21Root);
run_v21_final_validation(v21Root);
run_v21_crlb(v21Root);
generate_result_metrics_v21(v21Root);
summary=validate_v21_outputs(v21Root);
end
