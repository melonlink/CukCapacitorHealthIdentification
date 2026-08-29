function summary=run_v2_analysis(v2Root)
%RUN_V2_ANALYSIS Observability, blind CCM, covariance, DCM and Model B tests.

if nargin<1, v2Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v2Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(v2Root));
tableDir=fullfile(v2Root,"results","tables");
figureDir=fullfile(v2Root,"results","figures"); rawDir=fullfile(v2Root,"results","raw");
L=load(fullfile(rawDir,"locked_covariance.mat"),"locked"); locked=L.locked;
baseCfg=struct("samplesPerCycle",40,"edgeGuardUs",.5,"edgeWindowUs",2, ...
    "edgePointsPerSide",3,"edgeMethod","timestamped_linear", ...
    "RRFloor",locked.RRFloor,"RCFloor",locked.RCFloor,"Cinit",.8e-4, ...
    "ESRinit",.035);

%% Normalized observability and information gain across representative CCM cases.
obsCases={"nominal",24,.4,1;"mid_load",24,.4,.5; ...
    "high_D",28.8,.65,.25;"low_D",19.2,.25,1};
obsAll=table();
for k=1:size(obsCases,1)
    p=model_parameters(); p.Vin=obsCases{k,2}; p.D=obsCases{k,3};
    p.Rload=p.Rload/obsCases{k,4};
    base=simulate_switched_equation(p,struct("duration",.003,"samplesPerPeriod",300));
    m=v2_make_measurements(base,p,baseCfg);
    q=v2_observability_information(m,p,baseCfg,locked,[3,5,10,20]);
    q=addvars(q,repmat(string(obsCases{k,1}),height(q),1), ...
        repmat(p.Vin,height(q),1),repmat(p.D,height(q),1), ...
        repmat(obsCases{k,4},height(q),1),'Before',1, ...
        'NewVariableNames',["operating_case","Vin_V","D","load_fraction"]);
    obsAll=[obsAll;q]; %#ok<AGROW>
end
writetable(obsAll,fullfile(tableDir,"table_observability_normalized_v2.csv"));
q=obsAll(obsAll.operating_case=="nominal" & obsAll.observation_set=="full_TR",:);
fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
nexttile; semilogy(q.window_cycles,q.cond_Obs_normalized,"o-"); grid on;
ylabel("cond(O normalized)"); title("Normalized observability — nominal Model A");
nexttile; semilogy(q.window_cycles,q.min_sv_Obs_normalized,"o-"); grid on;
xlabel("Window (cycles)"); ylabel("Minimum singular value");
save_verification_figure(fig,figureDir,"fig_v2_16_observability_normalized");
q=obsAll(obsAll.operating_case=="nominal" & obsAll.window_cycles==10,:);
fig=figure("Visible","off","Color","w");
bar(categorical(q.observation_set),q.info_min_eig); grid on;
ylabel("Minimum eigenvalue of normalized information matrix");
title("Information gain by C/ESR pseudo measurement — Model A, N=10");
save_verification_figure(fig,figureDir,"fig_v2_17_information_gain_by_measurement");

%% Blind 51-CCM regression with one locked covariance rule.
v1Operating=readtable(fullfile(v1Root,"results","tables", ...
    "result_operating_sweep.csv"),"TextType","string");
opRows=cell(height(v1Operating),22); covRows={};
for k=1:height(v1Operating)
    p=model_parameters(); p.Vin=v1Operating.Vin_V(k); p.D=v1Operating.D(k);
    p.Rload=v1Operating.Rload_Ohm(k);
    if v1Operating.status(k)~="CCM"
        opRows(k,:)={k,p.Vin,p.D,v1Operating.load_fraction(k),p.Rload, ...
            v1Operating.ccm_margin_A(k),"EXCLUDED_DCM",NaN,NaN,NaN,NaN, ...
            NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,"health update frozen"};
        continue;
    end
    base=simulate_switched_equation(p,struct("duration",.005,"samplesPerPeriod",200));
    m=v2_make_measurements(base,p,baseCfg); r=tr_ts_ltvkf(m,p,baseCfg,locked);
    conv=max(convergence_time(r.t,r.C,p.C1,.03,20), ...
        convergence_time(r.t,r.ESR,p.ESR,.05,20));
    [mv,medv,pv,rv]=nis_stats(r.nisV,r.gateV);
    [mc,medc,pc,rc]=nis_stats(r.nisC,r.gateC);
    [mr,medr,pr,rr]=nis_stats(r.nisR,r.gateR);
    status=pass_fail(r.CMape,r.ESRMape);
    opRows(k,:)={k,p.Vin,p.D,v1Operating.load_fraction(k),p.Rload, ...
        v1Operating.ccm_margin_A(k),status,r.Cfinal,r.CMape,r.ESRfinal, ...
        r.ESRMape,conv,mv,medv,pv,rv,mc,pc,rc,mr,pr,rr};
    types=["V","C","R"]; means=[mv,mc,mr]; medians=[medv,medc,medr];
    p95=[pv,pc,pr]; rejects=[rv,rc,rr];
    for j=1:3
        covRows(end+1,:)={k,p.Vin,p.D,v1Operating.load_fraction(k),types(j), ...
            means(j),medians(j),p95(j),rejects(j),9,locked.RV, ...
            locked.RCFloor,locked.RRFloor}; %#ok<AGROW>
    end
end
operatingTable=cell2table(opRows,"VariableNames",["test_id","Vin_V","D", ...
    "load_fraction","Rload_Ohm","ccm_margin_A","status","C_est_F", ...
    "C_MAPE_percent","ESR_est_Ohm","ESR_MAPE_percent", ...
    "convergence_time_s","NIS_V_mean","NIS_V_median","NIS_V_p95", ...
    "gate_V_rejected_fraction","NIS_C_mean","NIS_C_p95", ...
    "gate_C_rejected_fraction","NIS_R_mean","NIS_R_p95", ...
    "gate_R_rejected_fraction"]);
writetable(operatingTable,fullfile(tableDir,"table_v2_operating_regression.csv"));
covTable=cell2table(covRows,"VariableNames",["test_id","Vin_V","D", ...
    "load_fraction","measurement_type","NIS_mean","NIS_median","NIS_p95", ...
    "rejected_fraction","NIS_gate","R_V","R_C_floor","R_R_floor"]);
writetable(covTable,fullfile(tableDir,"table_covariance_consistency_v2.csv"));
fig=figure("Visible","off","Color","w"); tiledlayout(1,2);
types=["V","C","R"]; meanN=zeros(1,3); p95N=meanN; reject=meanN;
for j=1:3
    z=covTable(covTable.measurement_type==types(j),:);
    meanN(j)=median(z.NIS_mean,"omitnan"); p95N(j)=median(z.NIS_p95,"omitnan");
    reject(j)=median(z.rejected_fraction,"omitnan");
end
nexttile; bar(categorical(types),[meanN;p95N]'); yline(9,"k:"); grid on;
ylabel("NIS"); legend("median of means","median p95","gate");
title("Locked covariance consistency — 51 CCM cases");
nexttile; bar(categorical(types),100*reject); grid on;
ylabel("Rejected measurements (%)"); title("Median gate rejection rate");
save_verification_figure(fig,figureDir,"fig_v2_06_NIS_consistency");

%% Worst v1 covariance case with fixed-small, v1 floor and v2 covariance.
p=model_parameters(); p.Vin=28.8; p.D=.65; p.Rload=40;
base=simulate_switched_equation(p,struct("duration",.004,"samplesPerPeriod",300));
m=v2_make_measurements(base,p,baseCfg);
small=ts_ltvkf(m,struct("Cnom",p.C1,"ESRnom",p.ESR,"Cinit",.8*p.C1, ...
    "ESRinit",.7*p.ESR,"measurementVariance",1e-8,"gateThreshold",20));
v1R=max(1e-8,(2.5e-5*mean(abs(m.vT)))^2);
adaptive=ts_ltvkf(m,struct("Cnom",p.C1,"ESRnom",p.ESR,"Cinit",.8*p.C1, ...
    "ESRinit",.7*p.ESR,"measurementVariance",v1R,"gateThreshold",20));
tr=tr_ts_ltvkf(m,p,baseCfg,locked);
fig=figure("Visible","off","Color","w"); tiledlayout(4,1);
nexttile; plot(1e3*small.t,1e6*small.C); hold on;
plot(1e3*adaptive.t,1e6*adaptive.C); plot(1e3*tr.t,1e6*tr.C); yline(100,"k:");
grid on; ylabel("C (uF)"); legend("fixed-small R","v1 floor","v2 locked");
title("Worst covariance case: Vin=28.8 V, D=0.65, 25% load — Model A");
nexttile; plot(1e3*small.t,1e3*small.ESR); hold on;
plot(1e3*adaptive.t,1e3*adaptive.ESR); plot(1e3*tr.t,1e3*tr.ESR); yline(50,"k:");
grid on; ylabel("ESR (mOhm)");
nexttile; plot(1e3*small.t,small.innovation); hold on;
plot(1e3*adaptive.t,adaptive.innovation); plot(1e3*tr.t,tr.nisV);
grid on; ylabel("Innovation / NIS"); legend("small innovation","v1 innovation","v2 NIS_V");
nexttile; semilogy(1e3*tr.t,tr.Pdiag); grid on; xlabel("Time (ms)");
ylabel("diag(P)"); legend("vC","scaled alpha","ESR");
save_verification_figure(fig,figureDir,"fig_v2_18_worst_covariance_case");

%% CCM -> DCM -> CCM freeze/resume.
p=model_parameters(); sequence=simulate_load_sequence(p);
m=v2_make_measurements(sequence,p,baseCfg); freeze=tr_ts_ltvkf(m,p,baseCfg,locked);
fig=figure("Visible","off","Color","w"); tiledlayout(3,1);
nexttile; stairs(1e3*sequence.t,sequence.Rload,"LineWidth",1.1); grid on;
ylabel("Rload (Ohm)"); title("CCM-DCM-CCM health-update freeze/resume — Model A");
nexttile; plot(1e3*freeze.t,1e6*freeze.C); hold on;
area(1e3*freeze.t,150*double(~freeze.ccmHealthEnabled), ...
    "FaceAlpha",.15,"EdgeColor","none"); yline(100,"k:"); grid on; ylabel("C (uF)");
nexttile; plot(1e3*freeze.t,1e3*freeze.ESR); hold on;
area(1e3*freeze.t,200*double(~freeze.ccmHealthEnabled), ...
    "FaceAlpha",.15,"EdgeColor","none"); yline(50,"k:"); grid on;
xlabel("Time (ms)"); ylabel("ESR (mOhm)");
save_verification_figure(fig,figureDir,"fig_v2_19_ccm_dcm_freeze_resume");

%% Independent Simscape Model B: nominal, delay and physical ESL stress points.
p=model_parameters(); modelBRows=cell(4,14);
baseB0=run_simscape_model_b_v2(v2Root,0,.003);
baseB20=run_simscape_model_b_v2(v2Root,20e-9,.003);
modelBCases={"nominal_1nH",baseB0,1,0,0; ...
    "delay_200ns",baseB0,1,200,0; ...
    "ESL20_delay200_jitter20",baseB20,20,200,20; ...
    "ESL20_delay500_jitter50",baseB20,20,500,50};
for k=1:4
    cfg=baseCfg; cfg.useBaseTerminalVoltage=true; cfg.voltageDelayNs=modelBCases{k,4};
    cfg.i1DelayNs=-modelBCases{k,4}; cfg.i2DelayNs=-modelBCases{k,4};
    cfg.jitterRmsNs=modelBCases{k,5}; cfg.jitterMode="independent";
    cfg.seed=4200+k;
    m=v2_make_measurements(modelBCases{k,2},p,cfg); r=tr_ts_ltvkf(m,p,cfg,locked);
    modelBRows(k,:)={string(modelBCases{k,1}),modelBCases{k,3},modelBCases{k,4}, ...
        modelBCases{k,5},r.CpreFinal,r.ESRpreFinal, ...
        r.Cfinal,r.CMape,r.ESRfinal,r.ESRMape,mean(r.gateR(isfinite(r.nisR))), ...
        median(r.nisR,"omitnan"),pass_fail(r.CMape,r.ESRMape), ...
        "physical Simscape ESL and timestamped measurement"};
end
modelBTable=cell2table(modelBRows,"VariableNames",["case_name","ESL_nH", ...
    "opposed_channel_delay_ns","jitter_rms_ns","pre_projection_C_F", ...
    "pre_projection_ESR_Ohm","C_est_F","C_MAPE_percent","ESR_est_Ohm", ...
    "ESR_MAPE_percent","edge_gate_accept_fraction","NIS_R_median","status","notes"]);
writetable(modelBTable,fullfile(tableDir,"table_model_b_cross_validation_v2.csv"));

%% v1 versus v2 summary figure.
ccm=operatingTable.status~="EXCLUDED_DCM";
v2MaxC=max(operatingTable.C_MAPE_percent(ccm));
v2MaxR=max(operatingTable.ESR_MAPE_percent(ccm));
fig=figure("Visible","off","Color","w");
bar(categorical(["v1 adaptive C","v2 TR C","v1 adaptive ESR","v2 TR ESR"]), ...
    [max(v1Operating.LTVKF_adaptive_C_MAPE_percent,[],"omitnan"),v2MaxC, ...
    max(v1Operating.LTVKF_adaptive_ESR_MAPE_percent,[],"omitnan"),v2MaxR]);
yline(3,"k:","C target"); yline(5,"k--","ESR target"); grid on;
ylabel("Maximum MAPE across 51 CCM cases (%)");
title("v1 vs v2 locked-parameter regression — Model A");
save_verification_figure(fig,figureDir,"fig_v2_20_v1_vs_v2_summary");

summary=struct("ccmCases",sum(ccm),"excludedDcm",sum(~ccm), ...
    "v2MedianC",median(operatingTable.C_MAPE_percent(ccm)), ...
    "v2MaxC",v2MaxC,"v2MedianESR",median(operatingTable.ESR_MAPE_percent(ccm)), ...
    "v2MaxESR",v2MaxR,"ccmPassFraction",mean(operatingTable.status(ccm)=="PASS"), ...
    "normalizedRankMin",min(obsAll.rank_Obs_normalized), ...
    "modelBPassFraction",mean(modelBTable.status=="PASS"), ...
    "dcmParameterCSpanPercent",100*range(freeze.C( ...
        freeze.t>=.002 & freeze.t<.004))/p.C1, ...
    "dcmParameterRSpanPercent",100*range(freeze.ESR( ...
        freeze.t>=.002 & freeze.t<.004))/p.ESR);
save(fullfile(rawDir,"analysis_summary.mat"),"summary","small","adaptive", ...
    "tr","freeze","modelBTable","-v7.3");
fprintf('v2 analysis: CCM pass %.1f%%, max C/ESR %.3g/%.3g%%, Model B pass %.1f%%.\n', ...
    100*summary.ccmPassFraction,summary.v2MaxC,summary.v2MaxESR, ...
    100*summary.modelBPassFraction);
end

function [meanN,medianN,p95N,rejected]=nis_stats(nis,gate)
valid=isfinite(nis); x=nis(valid);
if isempty(x), meanN=NaN; medianN=NaN; p95N=NaN; rejected=NaN; return; end
meanN=mean(x); medianN=median(x); p95N=prctile(x,95);
rejected=1-mean(gate(valid));
end

function state=pass_fail(ce,re)
if isfinite(ce)&&isfinite(re)&&ce<3&&re<5, state="PASS"; else, state="FAIL"; end
end

function data=simulate_load_sequence(p)
loads=[p.Rload,10*p.Rload,p.Rload]; duration=.002;
segments=cell(1,3); x0=[];
for k=1:3
    local=p; local.Rload=loads(k); options=struct("duration",duration, ...
        "samplesPerPeriod",200);
    if ~isempty(x0), options.initialState=x0; end
    segments{k}=simulate_switched_equation(local,options);
    x0=[segments{k}.i1(end),segments{k}.i2(end),segments{k}.vC(end),segments{k}.vo(end)];
end
fields=["u","i1","i2","iC","vC","vT","vo","Ctrue","ESRtrue", ...
    "Rload","Vin"];
data=segments{1};
for k=2:3
    offset=data.t(end); data.t=[data.t;offset+segments{k}.t(2:end)];
    for f=fields, data.(f)=[data.(f);segments{k}.(f)(2:end)]; end
end
end
