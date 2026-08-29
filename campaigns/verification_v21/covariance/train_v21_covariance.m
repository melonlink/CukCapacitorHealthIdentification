function locked=train_v21_covariance(v21Root)
%TRAIN_V21_COVARIANCE Calibrate only on declared training cases, then lock.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v21Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(fullfile(repoRoot,"verification_v2")), ...
    genpath(v21Root));
tableDir=fullfile(v21Root,"results","tables"); rawDir=fullfile(v21Root,"results","raw");
cfg0=v21_default_config();
locked=struct("Q",diag([25,.5,.001]),"RVFloor",1e-10, ...
    "RCFloor",1e-10,"RRFloor",1e-10,"edgeVarianceScale",1, ...
    "chargeVarianceScale",1,"voltageVarianceScale",1, ...
    "edgeGainCorrection",1,"gateV",9,"gateC",9,"gateR",9);
[cases,bases,params,cfgs]=training_cases(v21Root,cfg0);
locked.edgeGainCorrection=calibrate_edge_gain(bases,params,cfgs);
targetMedian=.454936423119573;
history=table();
for iteration=1:2
    nis=collect_nis(bases,params,cfgs,locked,8,12000+100*iteration);
    med=[median(nis.V,"omitnan"),median(nis.C,"omitnan"), ...
        median(nis.R,"omitnan")];
    ratios=min(max(med/targetMedian,.1),10);
    locked.voltageVarianceScale=max(.02,min(20, ...
        locked.voltageVarianceScale*ratios(1)));
    locked.chargeVarianceScale=max(.02,min(20, ...
        locked.chargeVarianceScale*ratios(2)));
    locked.edgeVarianceScale=max(.02,min(20, ...
        locked.edgeVarianceScale*ratios(3)));
    history=[history;table(iteration,med(1),med(2),med(3), ...
        locked.voltageVarianceScale,locked.chargeVarianceScale, ...
        locked.edgeVarianceScale)]; %#ok<AGROW>
end

rows=cell(numel(cases),16);
for c=1:numel(cases)
    stats=run_case(bases{c},params{c},cfgs{c},locked,12,15000+100*c);
    rows(c,:)={cases(c),stats.nisVMean,stats.nisVMedian,stats.nisVP95, ...
        stats.nisCMean,stats.nisCMedian,stats.nisCP95,stats.nisRMean, ...
        stats.nisRMedian,stats.nisRP95,stats.neesParamMean, ...
        stats.coverC95,stats.coverR95,locked.voltageVarianceScale, ...
        locked.chargeVarianceScale,locked.edgeVarianceScale};
end
trainingTable=cell2table(rows,"VariableNames",["training_case","NIS_V_mean", ...
    "NIS_V_p50","NIS_V_p95","NIS_C_mean","NIS_C_p50","NIS_C_p95", ...
    "NIS_R_mean","NIS_R_p50","NIS_R_p95","NEES_param_mean", ...
    "CI_C_95_coverage","CI_ESR_95_coverage","voltage_variance_scale", ...
    "charge_variance_scale","edge_variance_scale"]);
writetable(trainingTable,fullfile(tableDir,"table_covariance_training_v21.csv"));
writetable(history,fullfile(tableDir,"table_covariance_iterations_v21.csv"));
locked.trainingCases=cases; locked.trainingSeeds=12;
locked.calibrationRule="two-pass median-NIS scale; target chi-square(1) median";
locked.QInterpretation="continuous-time covariance spectral density; Qk=Q*delta_t";
locked.edgeGainRule="training median of raw edge ESR divided by true ESR";
locked.lockedBeforeBlindValidation=true;
save(fullfile(rawDir,"locked_covariance_v21.mat"),"locked","trainingTable","history");
fprintf("v2.1 covariance locked: V/C/R scales %.4g / %.4g / %.4g.\n", ...
    locked.voltageVarianceScale,locked.chargeVarianceScale,locked.edgeVarianceScale);
end

function gain=calibrate_edge_gain(bases,params,cfgs)
ratios=[];
for c=1:numel(bases)
    cfg=cfgs{c}; cfg.seed=11900+c;
    m=v21_measurement_chain(bases{c},params{c},cfg);
    edges=v2_edge_estimates(m,params{c},cfg);
    ratios=[ratios;edges.ESR_raw_Ohm/params{c}.ESR]; %#ok<AGROW>
end
gain=median(ratios,"omitnan");
end

function [names,bases,params,cfgs]=training_cases(v21Root,cfg0)
names=["nominal","high_D","noisy","modelB_parasitic_nominal"];
bases=cell(1,4); params=cell(1,4); cfgs=repmat({cfg0},1,4);
for k=1:3, params{k}=model_parameters(); end
params{2}.D=.60; params{2}.Rload=7.5;
cfgs{3}.sigmaVmV=10; cfgs{3}.sigmaImA=5;
for k=1:3
    bases{k}=simulate_switched_equation(params{k}, ...
        struct("duration",.003,"samplesPerPeriod",400));
end
params{4}=model_parameters();
bases{4}=run_modelB_v21(v21Root,params{4},10e-9,.003);
end

function nis=collect_nis(bases,params,cfgs,locked,nSeed,seed0)
nis=struct("V",[],"C",[],"R",[]);
for c=1:numel(bases)
    for s=1:nSeed
        cfg=cfgs{c}; cfg.seed=seed0+100*c+s;
        m=v21_measurement_chain(bases{c},params{c},cfg);
        r=structured_ltv_estimator_v21(m,params{c},cfg,locked);
        nis.V=[nis.V;r.nisV(isfinite(r.nisV))];
        nis.C=[nis.C;r.nisC(isfinite(r.nisC))];
        nis.R=[nis.R;r.nisR(isfinite(r.nisR))];
    end
end
end

function stats=run_case(base,p,cfg0,locked,nSeed,seed0)
v=[]; c=[]; rr=[]; nees=zeros(nSeed,1); coverC=false(nSeed,1); coverR=coverC;
for s=1:nSeed
    cfg=cfg0; cfg.seed=seed0+s; m=v21_measurement_chain(base,p,cfg);
    r=structured_ltv_estimator_v21(m,p,cfg,locked);
    v=[v;r.nisV(isfinite(r.nisV))]; c=[c;r.nisC(isfinite(r.nisC))]; %#ok<AGROW>
    rr=[rr;r.nisR(isfinite(r.nisR))]; %#ok<AGROW>
    nees(s)=r.neesParam(end); coverC(s)=r.CI_C_contains_true;
    coverR(s)=r.CI_ESR_contains_true;
end
stats=struct("nisVMean",mean(v),"nisVMedian",median(v),"nisVP95",prctile(v,95), ...
    "nisCMean",mean(c),"nisCMedian",median(c),"nisCP95",prctile(c,95), ...
    "nisRMean",mean(rr),"nisRMedian",median(rr),"nisRP95",prctile(rr,95), ...
    "neesParamMean",mean(nees),"coverC95",mean(coverC),"coverR95",mean(coverR));
end
