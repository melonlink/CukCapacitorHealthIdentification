function summary = run_dynamic_tests(rootDir)
%RUN_DYNAMIC_TESTS Parameter tracking and operating-transient decoupling.

if nargin<1, rootDir=fileparts(fileparts(mfilename("fullpath"))); end
addpath(genpath(rootDir));
tableDir=fullfile(rootDir,"results","tables");
figureDir=fullfile(rootDir,"results","figures");
dynamicDir=fullfile(rootDir,"results","dynamic");
if ~isfolder(tableDir), mkdir(tableDir); end
if ~isfolder(figureDir), mkdir(figureDir); end
if ~isfolder(dynamicDir), mkdir(dynamicDir); end
p=model_parameters(); stepTime=.01; duration=.02;
scenarios={ ...
    "C_90",struct("CFinal",.9*p.C1); ...
    "C_80",struct("CFinal",.8*p.C1); ...
    "ESR_150",struct("ESRFinal",1.5*p.ESR); ...
    "ESR_200",struct("ESRFinal",2*p.ESR); ...
    "Joint_85_175",struct("CFinal",.85*p.C1,"ESRFinal",1.75*p.ESR)};
rows={}; stored=struct();

for s=1:size(scenarios,1)
    name=scenarios{s,1}; options=scenarios{s,2};
    options.duration=duration; options.samplesPerPeriod=200; options.stepTime=stepTime;
    data=simulate_switched_equation(p,options);
    estimates=estimate_both(data,p);
    cFinal=data.Ctrue(end); rFinal=data.ESRtrue(end);
    for method=["RLS","TS_LTVKF"]
        e=estimates.(method);
        cMetrics=step_metrics(e.t,e.C,p.C1,cFinal,stepTime);
        rMetrics=step_metrics(e.t,e.ESR,p.ESR,rFinal,stepTime);
        cFalse=NaN; rFalse=NaN;
        if cFinal==p.C1, cFalse=max(abs(e.C(e.t>=stepTime)/p.C1-1))*100; end
        if rFinal==p.ESR, rFalse=max(abs(e.ESR(e.t>=stepTime)/p.ESR-1))*100; end
        rows(end+1,:)={name,method,p.C1,cFinal,p.ESR,rFinal, ...
            cMetrics.trackingTime,cMetrics.overshoot,cMetrics.settledBias, ...
            rMetrics.trackingTime,rMetrics.overshoot,rMetrics.settledBias, ...
            cFalse,rFalse}; %#ok<AGROW>
    end
    stored.(name)=struct("data",data,"estimates",estimates);
end
dynamicTable=cell2table(rows,"VariableNames",["scenario","method","C_initial_F", ...
    "C_final_F","ESR_initial_Ohm","ESR_final_Ohm","C_tracking_10_90_s", ...
    "C_overshoot_percent","C_settled_bias_percent","ESR_tracking_10_90_s", ...
    "ESR_overshoot_percent","ESR_settled_bias_percent", ...
    "false_C_peak_percent","false_ESR_peak_percent"]);
writetable(dynamicTable,fullfile(tableDir,"table_dynamic_tracking.csv"));

plot_parameter_case(stored.C_80,p,stepTime,figureDir, ...
    "fig_09_dynamic_C_step","C step: 100 uF to 80 uF",true,false);
plot_parameter_case(stored.ESR_200,p,stepTime,figureDir, ...
    "fig_10_dynamic_ESR_step","ESR step: 50 mOhm to 100 mOhm",false,true);
plot_parameter_case(stored.Joint_85_175,p,stepTime,figureDir, ...
    "fig_11_dynamic_joint_step","Joint C/ESR parameter step",true,true);

%% Load and input-voltage transient decoupling.
transientRows={}; loadStored=struct();
loadCases={"Load_25_to_75",p.Rload/.25,p.Rload/.75; ...
    "Load_100_to_50",p.Rload,p.Rload/.5};
for s=1:size(loadCases,1)
    local=p; local.Rload=loadCases{s,2};
    data=simulate_switched_equation(local,struct("duration",duration, ...
        "samplesPerPeriod",200,"stepTime",stepTime,"RFinal",loadCases{s,3}));
    estimates=estimate_both(data,p);
    transientRows=[transientRows;transient_metrics(loadCases{s,1},"load", ...
        loadCases{s,2},loadCases{s,3},estimates,p,stepTime)]; %#ok<AGROW>
    loadStored.(loadCases{s,1})=struct("data",data,"estimates",estimates);
end
vinCases={"Vin_80_to_120",.8*p.Vin,1.2*p.Vin; ...
    "Vin_120_to_80",1.2*p.Vin,.8*p.Vin};
for s=1:size(vinCases,1)
    local=p; local.Vin=vinCases{s,2};
    data=simulate_switched_equation(local,struct("duration",duration, ...
        "samplesPerPeriod",200,"stepTime",stepTime,"VinFinal",vinCases{s,3}));
    estimates=estimate_both(data,p);
    transientRows=[transientRows;transient_metrics(vinCases{s,1},"Vin", ...
        vinCases{s,2},vinCases{s,3},estimates,p,stepTime)]; %#ok<AGROW>
end
transientTable=cell2table(transientRows,"VariableNames",["scenario","transient_type", ...
    "initial_value","final_value","method","C_transient_peak_percent", ...
    "C_settled_bias_percent","ESR_transient_peak_percent", ...
    "ESR_settled_bias_percent"]);
writetable(transientTable,fullfile(tableDir,"table_transient_decoupling.csv"));

q=loadStored.Load_25_to_75;
fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
nexttile; hold on;
plot(1e3*q.estimates.RLS.t,1e6*q.estimates.RLS.C,"LineWidth",1.1);
plot(1e3*q.estimates.TS_LTVKF.t,1e6*q.estimates.TS_LTVKF.C,"LineWidth",1.1);
yline(1e6*p.C1,"k:"); xline(1e3*stepTime,"k--"); grid on;
ylabel("Estimated C (uF)"); legend("RLS","TS-LTVKF","True","Load step","Location","best");
title("False health drift during 25% to 75% load step");
nexttile; hold on;
plot(1e3*q.estimates.RLS.t,1e3*q.estimates.RLS.ESR,"LineWidth",1.1);
plot(1e3*q.estimates.TS_LTVKF.t,1e3*q.estimates.TS_LTVKF.ESR,"LineWidth",1.1);
yline(1e3*p.ESR,"k:"); xline(1e3*stepTime,"k--"); grid on;
xlabel("Time (ms)"); ylabel("Estimated ESR (mOhm)");
legend("RLS","TS-LTVKF","True","Load step","Location","best");
save_verification_figure(fig,figureDir,"fig_15_load_transient_decoupling");

summary=struct("dynamicRows",height(dynamicTable), ...
    "maxSettledC",max(abs(transientTable.C_settled_bias_percent)), ...
    "maxSettledESR",max(abs(transientTable.ESR_settled_bias_percent)), ...
    "maxTransientC",max(transientTable.C_transient_peak_percent), ...
    "maxTransientESR",max(transientTable.ESR_transient_peak_percent));
save(fullfile(dynamicDir,"dynamic_results.mat"),"summary","dynamicTable", ...
    "transientTable","stored","loadStored","-v7.3");
fprintf('Dynamic: max settled false C/ESR %.3g/%.3g%%, transient peaks %.3g/%.3g%%\n', ...
    summary.maxSettledC,summary.maxSettledESR,summary.maxTransientC,summary.maxTransientESR);
end

function estimates=estimate_both(data,p)
f=measured_regression_features(data,struct("startTime",20*p.Ts));
rls=topology_rls(f.Phi,f.z,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
    "Cinit",p.C1,"ESRinit",p.ESR,"lambda",.995));
kf=ts_ltvkf(data,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
    "Cinit",p.C1,"ESRinit",p.ESR,"measurementVariance",1e-6, ...
    "gateThreshold",20,"processCovariance",diag([1e-8,1e-9,1e-9])));
estimates=struct("RLS",struct("t",f.time,"C",rls.C,"ESR",rls.ESR), ...
    "TS_LTVKF",struct("t",kf.t,"C",kf.C,"ESR",kf.ESR));
end

function metrics=step_metrics(t,estimate,initial,finalValue,stepTime)
settled=t>=t(end)-.002;
metrics.settledBias=100*(mean(estimate(settled))/finalValue-1);
if finalValue==initial
    metrics.trackingTime=NaN; metrics.overshoot=NaN; return;
end
after=find(t>=stepTime);
progress=(estimate(after)-initial)/(finalValue-initial);
i10=find(progress>=.1,1); i90=find(progress>=.9,1);
if isempty(i10)||isempty(i90), metrics.trackingTime=NaN;
else, metrics.trackingTime=t(after(i90))-t(after(i10)); end
metrics.overshoot=max(max(progress)-1,0)*100;
end

function plot_parameter_case(q,p,stepTime,figureDir,fileName,plotTitle,plotC,plotR)
fig=figure("Visible","off","Color","w");
if plotC&&plotR, tiledlayout(2,1); end
if plotC
    if plotR, nexttile; end
    plot(1e3*q.estimates.RLS.t,1e6*q.estimates.RLS.C,"LineWidth",1.1); hold on;
    plot(1e3*q.estimates.TS_LTVKF.t,1e6*q.estimates.TS_LTVKF.C,"LineWidth",1.1);
    plot(1e3*q.data.t,1e6*q.data.Ctrue,"k:","LineWidth",1.1); xline(1e3*stepTime,"k--");
    grid on; ylabel("C (uF)"); legend("RLS","TS-LTVKF","True","Step","Location","best");
end
if plotR
    if plotC, nexttile; end
    plot(1e3*q.estimates.RLS.t,1e3*q.estimates.RLS.ESR,"LineWidth",1.1); hold on;
    plot(1e3*q.estimates.TS_LTVKF.t,1e3*q.estimates.TS_LTVKF.ESR,"LineWidth",1.1);
    plot(1e3*q.data.t,1e3*q.data.ESRtrue,"k:","LineWidth",1.1); xline(1e3*stepTime,"k--");
    grid on; ylabel("ESR (mOhm)"); xlabel("Time (ms)");
    legend("RLS","TS-LTVKF","True","Step","Location","best");
end
sgtitle(plotTitle+" — "+string(p.fs/1e3)+" kHz switching");
save_verification_figure(fig,figureDir,fileName);
end

function rows=transient_metrics(name,typeName,initialValue,finalValue,estimates,p,stepTime)
rows=cell(2,9); methods=["RLS","TS_LTVKF"];
for k=1:2
    e=estimates.(methods(k)); after=e.t>=stepTime; settled=e.t>=e.t(end)-.002;
    cPeak=max(abs(e.C(after)/p.C1-1))*100;
    rPeak=max(abs(e.ESR(after)/p.ESR-1))*100;
    cSettled=(mean(e.C(settled))/p.C1-1)*100;
    rSettled=(mean(e.ESR(settled))/p.ESR-1)*100;
    rows(k,:)={name,typeName,initialValue,finalValue,methods(k),cPeak,cSettled,rPeak,rSettled};
end
end
