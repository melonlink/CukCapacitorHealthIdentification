function metrics=generate_result_metrics_v2(v2Root)
%GENERATE_RESULT_METRICS_V2 Assemble one audit table across all v2 studies.

if nargin<1, v2Root=fileparts(fileparts(mfilename("fullpath"))); end
tableDir=fullfile(v2Root,"results","tables");
lockedData=load(fullfile(v2Root,"results","raw","locked_covariance.mat"),"locked");
tpl=metric_template(lockedData.locked); allRows=repmat(tpl,0,1);

%% Baseline cliff reproduction.
T=readtable(fullfile(tableDir,"table_v1_edge_assignment_diagnostics.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="baseline_"+T.test_id(k); r.test_family="baseline_cliff";
    r.algorithm_version="v1"; r.method="adjacent-edge assignment";
    r.edge_method="adjacent"; r.common_pwm_offset_ns=T.requested_offset_ns(k);
    r.sync_error_s=1e-9*T.requested_offset_ns(k);
    r.pre_projection_C=T.pre_projection_C_F(k);
    r.pre_projection_ESR=T.pre_projection_ESR_Ohm(k);
    r.post_projection_C=T.post_projection_C_F(k);
    r.post_projection_ESR=T.post_projection_ESR_Ohm(k);
    r.C_est_F=r.post_projection_C; r.ESR_est_Ohm=r.post_projection_ESR;
    r.C_MAPE_percent=T.post_projection_C_MAPE_percent(k);
    r.ESR_MAPE_percent=T.post_projection_ESR_MAPE_percent(k);
    r.rank_Phi=T.rank_Phi(k); r.status=pass_fail(r.C_MAPE_percent,r.ESR_MAPE_percent);
    r.notes="sample-index cliff diagnostic; pre/post projection retained";
    rows(k)=r;
end
allRows=[allRows;rows];

%% Edge estimator comparison.
T=readtable(fullfile(tableDir,"table_edge_estimator_comparison_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="edge_"+T.test_id(k); r.test_family="edge_estimator";
    r.edge_method=T.edge_method(k); r.method=T.edge_method(k);
    if r.edge_method=="adjacent"
        r.algorithm_version="v1"; r.edge_fit_order=0;
    elseif r.edge_method=="robust_polynomial"
        r.edge_fit_order=2;
    else
        r.edge_fit_order=1;
    end
    r.common_pwm_offset_ns=T.common_pwm_offset_ns(k);
    r.sync_error_s=1e-9*T.common_pwm_offset_ns(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.pre_projection_C=r.C_est_F; r.pre_projection_ESR=r.ESR_est_Ohm;
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.edge_guard_us=T.edge_guard_us(k); r.edge_window_us=T.edge_window_us(k);
    r.edge_fit_rmse_V=T.edge_fit_rmse_V(k);
    r.edge_fit_variance_V2=T.edge_fit_variance_V2(k);
    r.status=pass_fail(r.C_MAPE_percent,r.ESR_MAPE_percent);
    r.notes="edge-only comparison; raw estimates are not projected"; rows(k)=r;
end
allRows=[allRows;rows];

%% Independent channel delay.
T=readtable(fullfile(tableDir,"table_channel_delay_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="delay_"+T.test_id(k); r.test_family="channel_delay";
    r.method=T.method(k); r.edge_method=edge_from_method(T.method(k));
    if T.method(k)=="adjacent", r.algorithm_version="v1"; end
    r.voltage_delay_ns=T.voltage_delay_ns(k); r.i1_delay_ns=T.i1_delay_ns(k);
    r.i2_delay_ns=T.i2_delay_ns(k); r.sync_error_s=1e-9*T.delay_magnitude_ns(k);
    r.pre_projection_C=T.pre_projection_C_F(k);
    r.pre_projection_ESR=T.pre_projection_ESR_Ohm(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.status=T.status(k); r.notes=T.test_group(k)+ ...
        "; pre-projection is maximum-deviation raw diagnostic"; rows(k)=r;
end
allRows=[allRows;rows];

%% Jitter Monte Carlo.
T=readtable(fullfile(tableDir,"table_jitter_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="jitter_"+string(k); r.test_family="jitter";
    r.jitter_rms_ns=T.jitter_rms_ns(k); r.samples_per_cycle=T.samples_per_cycle(k);
    r.pre_projection_C=T.pre_projection_C_F(k);
    r.pre_projection_ESR=T.pre_projection_ESR_Ohm(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.status=T.status(k); r.notes=T.jitter_mode(k)+" jitter; seed="+T.seed(k)+ ...
        "; pre-projection is maximum-deviation raw diagnostic"; rows(k)=r;
end
allRows=[allRows;rows];

%% Edge-window design.
T=readtable(fullfile(tableDir,"table_edge_window_design_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="window_"+string(k); r.test_family="edge_window";
    r.method=T.edge_method(k); r.edge_method=T.edge_method(k);
    r.edge_guard_us=T.edge_guard_us(k); r.edge_window_us=T.edge_window_us(k);
    r.edge_points_per_side=T.edge_points_per_side(k); r.edge_fit_order=1;
    r.edge_fit_rmse_V=T.edge_fit_rmse_V(k);
    r.edge_fit_variance_V2=T.edge_fit_variance_V2(k);
    r.samples_per_cycle=T.samples_per_cycle(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.status=T.status(k); r.notes="raw edge-window design; no projection"; rows(k)=r;
end
allRows=[allRows;rows];

%% ESL plus timing and jitter.
T=readtable(fullfile(tableDir,"table_esl_timing_joint_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="esl_"+T.test_id(k); r.test_family="esl_timing";
    r.model_type=T.model_type(k); r.ESL_H=1e-9*T.ESL_nH(k);
    r.voltage_delay_ns=T.delay_magnitude_ns(k);
    r.i1_delay_ns=-T.delay_magnitude_ns(k); r.i2_delay_ns=-T.delay_magnitude_ns(k);
    r.jitter_rms_ns=T.jitter_rms_ns(k);
    r.pre_projection_C=T.pre_projection_C_F(k);
    r.pre_projection_ESR=T.pre_projection_ESR_Ohm(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.status=T.status(k); r.notes=T.stress_group(k)+ ...
        "; pre-projection is maximum-deviation raw diagnostic"; rows(k)=r;
end
allRows=[allRows;rows];

%% Analog front end.
T=readtable(fullfile(tableDir,"table_frontend_delay_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="frontend_"+T.test_id(k); r.test_family="front_end";
    r.voltage_frontend_fc_Hz=T.voltage_frontend_fc_Hz(k);
    r.i1_frontend_fc_Hz=T.i1_frontend_fc_Hz(k);
    r.i2_frontend_fc_Hz=T.i2_frontend_fc_Hz(k);
    r.pre_projection_C=T.pre_projection_C_F(k);
    r.pre_projection_ESR=T.pre_projection_ESR_Ohm(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.status=T.status(k); r.notes=T.frontend_type(k)+ ...
        "; group delay plus waveform distortion; pre-projection is maximum-deviation diagnostic";
    rows(k)=r;
end
allRows=[allRows;rows];

%% ADC bits, samples per cycle and phase.
T=readtable(fullfile(tableDir,"table_adc_phase_sweep_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="adc_"+string(k); r.test_family="adc_phase";
    r.adc_bits=T.adc_bits(k); r.samples_per_cycle=T.samples_per_cycle(k);
    r.sample_phase_fraction=T.sample_phase_fraction(k); r.method=T.method(k);
    if T.method(k)=="old_TS_LTVKF", r.algorithm_version="v1"; r.edge_method="adjacent"; end
    r.edge_window_us=T.edge_window_us(k); r.edge_points_per_side=T.edge_points_per_side(k);
    r.pre_projection_C=T.pre_projection_C_F(k);
    r.pre_projection_ESR=T.pre_projection_ESR_Ohm(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.status=T.status(k); r.notes="phase sweep; pre-projection is maximum-deviation diagnostic for TR rows";
    rows(k)=r;
end
allRows=[allRows;rows];

%% Absolute analog noise.
T=readtable(fullfile(tableDir,"table_absolute_noise_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="noise_"+string(k); r.test_family="absolute_noise";
    r.sigma_v_mV_RMS=T.sigma_v_mV_RMS(k); r.sigma_i_mA_RMS=T.sigma_i_mA_RMS(k);
    r.pre_projection_C=T.pre_projection_C_F(k);
    r.pre_projection_ESR=T.pre_projection_ESR_Ohm(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.status=T.status(k); r.notes=T.noise_type(k)+"; seed="+T.seed(k)+ ...
        "; pre-projection is maximum-deviation raw diagnostic"; rows(k)=r;
end
allRows=[allRows;rows];

%% Normalized observability and Fisher information.
T=readtable(fullfile(tableDir,"table_observability_normalized_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="obs_"+string(k); r.test_family="observability";
    r.Vin=T.Vin_V(k); r.D=T.D(k); r.load_percent=100*T.load_fraction(k);
    r.rank_Obs=T.rank_Obs_normalized(k); r.cond_Obs=T.cond_Obs_normalized(k);
    r.min_singular_Obs=T.min_sv_Obs_normalized(k);
    r.rank_Obs_normalized=T.rank_Obs_normalized(k);
    r.cond_Obs_normalized=T.cond_Obs_normalized(k);
    r.min_sv_Obs_normalized=T.min_sv_Obs_normalized(k);
    r.info_min_eig=T.info_min_eig(k); r.info_cond=T.info_cond(k);
    r.R_V=T.R_V(k); r.status="INFORMATION_ONLY";
    r.notes=T.operating_case(k)+"; "+T.observation_set(k)+ ...
        "; window="+T.window_cycles(k)+" cycles"; rows(k)=r;
end
allRows=[allRows;rows];

%% Covariance/NIS rows.
T=readtable(fullfile(tableDir,"table_covariance_consistency_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="cov_"+T.test_id(k)+"_"+T.measurement_type(k);
    r.test_family="covariance"; r.Vin=T.Vin_V(k); r.D=T.D(k);
    r.load_percent=100*T.load_fraction(k); r.R_V=T.R_V(k);
    r.R_C=T.R_C_floor(k); r.R_R=T.R_R_floor(k);
    switch T.measurement_type(k)
        case "V", r.NIS_V=T.NIS_mean(k); r.gate_V=T.NIS_gate(k);
        case "C", r.NIS_C=T.NIS_mean(k); r.gate_C=T.NIS_gate(k);
        case "R", r.NIS_R=T.NIS_mean(k); r.gate_R=T.NIS_gate(k);
    end
    r.status="INFORMATION_ONLY"; r.notes="locked covariance blind CCM NIS"; rows(k)=r;
end
allRows=[allRows;rows];

%% Blind operating regression.
T=readtable(fullfile(tableDir,"table_v2_operating_regression.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="operating_"+T.test_id(k); r.test_family="ccm_regression";
    r.Vin=T.Vin_V(k); r.D=T.D(k); r.load_percent=100*T.load_fraction(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.pre_projection_C=r.C_est_F; r.pre_projection_ESR=r.ESR_est_Ohm;
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.convergence_time_s=T.convergence_time_s(k); r.NIS_V=T.NIS_V_mean(k);
    r.NIS_C=T.NIS_C_mean(k); r.NIS_R=T.NIS_R_mean(k);
    r.status=T.status(k); r.notes="blind test with one locked covariance rule"; rows(k)=r;
end
allRows=[allRows;rows];

%% Independent Simscape Model B.
T=readtable(fullfile(tableDir,"table_model_b_cross_validation_v2.csv"), ...
    "TextType","string"); rows=repmat(tpl,height(T),1);
for k=1:height(T)
    r=tpl; r.test_id="model_b_"+T.case_name(k); r.test_family="model_b";
    r.model_type="Model_B_Simscape"; r.ESL_H=1e-9*T.ESL_nH(k);
    r.voltage_delay_ns=T.opposed_channel_delay_ns(k);
    r.i1_delay_ns=-T.opposed_channel_delay_ns(k);
    r.i2_delay_ns=-T.opposed_channel_delay_ns(k); r.jitter_rms_ns=T.jitter_rms_ns(k);
    r.pre_projection_C=T.pre_projection_C_F(k);
    r.pre_projection_ESR=T.pre_projection_ESR_Ohm(k);
    r.C_est_F=T.C_est_F(k); r.C_MAPE_percent=T.C_MAPE_percent(k);
    r.ESR_est_Ohm=T.ESR_est_Ohm(k); r.ESR_MAPE_percent=T.ESR_MAPE_percent(k);
    r.post_projection_C=r.C_est_F; r.post_projection_ESR=r.ESR_est_Ohm;
    r.NIS_R=T.NIS_R_median(k); r.status=T.status(k);
    r.notes=T.notes(k)+"; pre-projection is maximum-deviation raw diagnostic"; rows(k)=r;
end
allRows=[allRows;rows];

metrics=struct2table(allRows);
writetable(metrics,fullfile(v2Root,"result_metrics_v2.csv"));
writetable(metrics,fullfile(tableDir,"result_metrics_v2.csv"));
fprintf('result_metrics_v2.csv: %d rows, %d fields.\n',height(metrics),width(metrics));
end

function r=metric_template(locked)
r=struct( ...
    "test_id","","model_type","Model_A","Vin",24,"D",.4, ...
    "load_percent",100,"fs_Hz",50000,"C_true_F",1e-4, ...
    "ESR_true_Ohm",.05,"noise_SNR_dB",NaN,"adc_bits",NaN, ...
    "samples_per_cycle",80,"sync_error_s",0,"ESL_H",0, ...
    "method","TR_TS_LTVKF","C_est_F",NaN,"C_MAPE_percent",NaN, ...
    "ESR_est_Ohm",NaN,"ESR_MAPE_percent",NaN,"convergence_time_s",NaN, ...
    "rank_Phi",NaN,"cond_Phi",NaN,"rank_Obs",NaN,"cond_Obs",NaN, ...
    "min_singular_Obs",NaN,"status","","notes","", ...
    "algorithm_version","v2_TR_TS_LTVKF","edge_method","timestamped_linear", ...
    "pre_projection_C",NaN,"pre_projection_ESR",NaN, ...
    "post_projection_C",NaN,"post_projection_ESR",NaN, ...
    "sample_phase_fraction",NaN,"common_pwm_offset_ns",0, ...
    "voltage_delay_ns",0,"i1_delay_ns",0,"i2_delay_ns",0, ...
    "jitter_rms_ns",0,"adc_aperture_ns",0, ...
    "voltage_frontend_fc_Hz",Inf,"i1_frontend_fc_Hz",Inf, ...
    "i2_frontend_fc_Hz",Inf,"edge_guard_us",.5,"edge_window_us",2, ...
    "edge_points_per_side",3,"edge_fit_order",1, ...
    "edge_fit_rmse_V",NaN,"edge_fit_variance_V2",NaN, ...
    "R_V",locked.RV,"R_C",locked.RCFloor,"R_R",locked.RRFloor, ...
    "NIS_V",NaN,"NIS_C",NaN,"NIS_R",NaN, ...
    "gate_V",locked.gateV,"gate_C",locked.gateC,"gate_R",locked.gateR, ...
    "rank_Obs_normalized",NaN,"cond_Obs_normalized",NaN, ...
    "min_sv_Obs_normalized",NaN,"info_min_eig",NaN,"info_cond",NaN, ...
    "sigma_v_mV_RMS",0,"sigma_i_mA_RMS",0,"test_family","");
end

function value=edge_from_method(method)
if contains(method,"robust")
    value="robust_polynomial";
elseif contains(method,"adjacent")
    value="adjacent";
else
    value="timestamped_linear";
end
end

function state=pass_fail(ce,re)
if isfinite(ce)&&isfinite(re)&&ce<3&&re<5
    state="PASS";
else
    state="FAIL";
end
end
