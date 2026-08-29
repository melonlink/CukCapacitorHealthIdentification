function summary=run_v21_estimator_statistics(v21Root)
%RUN_V21_ESTIMATOR_STATISTICS Double-counting audit and 100-seed consistency.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v21Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(fullfile(repoRoot,"verification_v2")), ...
    genpath(v21Root));
tableDir=fullfile(v21Root,"results","tables"); figureDir=fullfile(v21Root,"results","figures");
rawDir=fullfile(v21Root,"results","raw");
L=load(fullfile(rawDir,"locked_covariance_v21.mat"),"locked"); locked=L.locked;
cfg0=v21_default_config(); p0=model_parameters();
base0=simulate_switched_equation(p0,struct("duration",.003,"samplesPerPeriod",400));

%% Three estimator forms against disjoint and overlapping raw-sample policies.
variants=["masked_v2","full_ltv","conditional_structured"];
policies=["disjoint","overlap"]; nReuse=24; rows=cell(6,15); row=0;
for policy=policies
    for variant=variants
        cErr=zeros(nReuse,1); rErr=cErr; nees=cErr; coverC=false(nReuse,1);
        coverR=coverC; p22=cErr; p33=cErr; nisV=cErr; nisC=cErr; nisR=cErr;
        for s=1:nReuse
            cfg=cfg0; cfg.dataPolicy=policy; cfg.estimatorVariant=variant;
            cfg.computeNeesHistory=false;
            cfg.seed=21000+s; m=v21_measurement_chain(base0,p0,cfg);
            r=structured_ltv_estimator_v21(m,p0,cfg,locked);
            cErr(s)=r.CMape; rErr(s)=r.ESRMape; nees(s)=r.neesParam(end);
            coverC(s)=r.CI_C_contains_true; coverR(s)=r.CI_ESR_contains_true;
            p22(s)=r.P(2,2,end); p33(s)=r.P(3,3,end);
            nisV(s)=mean(r.nisV,"omitnan"); nisC(s)=mean(r.nisC,"omitnan");
            nisR(s)=mean(r.nisR,"omitnan");
        end
        row=row+1; rows(row,:)={variant,policy,policy=="overlap", ...
            variant=="masked_v2",mean(cErr),mean(rErr),mean(nees), ...
            mean(coverC),mean(coverR),median(p22),median(p33), ...
            mean(nisV),mean(nisC),mean(nisR),nReuse};
    end
end
reuseTable=cell2table(rows,"VariableNames",["estimator_variant","data_policy", ...
    "double_counting_flag","gain_mask_used","C_MAPE_mean_percent", ...
    "ESR_MAPE_mean_percent","NEES_param_mean","CI_C_95_coverage", ...
    "CI_ESR_95_coverage","P_alpha_final_median","P_ESR_final_median", ...
    "NIS_V_mean","NIS_C_mean","NIS_R_mean","seed_count"]);
writetable(reuseTable,fullfile(tableDir,"table_measurement_reuse_v21.csv"));
fig=figure("Visible","off","Color","w"); tiledlayout(1,3);
labels=categorical(reuseTable.estimator_variant+"/"+reuseTable.data_policy);
nexttile; bar(labels,[reuseTable.C_MAPE_mean_percent,reuseTable.ESR_MAPE_mean_percent]);
grid on; ylabel("Mean absolute percentage error (%)"); legend("C","ESR");
title("Accuracy and sample reuse");
nexttile; bar(labels,reuseTable.NEES_param_mean); yline(2,"k:"); grid on;
ylabel("Final parameter NEES mean"); title("Covariance consistency");
nexttile; bar(labels,100*[reuseTable.CI_C_95_coverage,reuseTable.CI_ESR_95_coverage]);
yline(95,"k:"); ylim([0,105]); grid on; ylabel("Empirical 95% coverage (%)");
legend("C","ESR"); title("Double-counting effect");
save_verification_figure(fig,figureDir,"fig_v21_06_double_counting_effect");

%% Locked blind statistical scenarios, 100 independent measurement seeds each.
[scenarioNames,bases,params,cfgs]=statistical_scenarios(v21Root,cfg0);
nSeed=100; statRows=cell(numel(scenarioNames),35); seedRows=cell(nSeed*numel(scenarioNames),13);
sr=0; allCError=[]; allRError=[]; allCSigma=[]; allRSigma=[];
for c=1:numel(scenarioNames)
    acc=empty_accumulator(nSeed); v=[]; q=[]; e=[];
    for s=1:nSeed
        cfg=cfgs{c}; cfg.seed=60000+1000*c+s;
        cfg.computeNeesHistory=false;
        m=v21_measurement_chain(bases{c},params{c},cfg);
        r=structured_ltv_estimator_v21(m,params{c},cfg,locked);
        v=[v;r.nisV(isfinite(r.nisV))]; q=[q;r.nisC(isfinite(r.nisC))]; %#ok<AGROW>
        e=[e;r.nisR(isfinite(r.nisR))]; %#ok<AGROW>
        acc.neesFull(s)=r.neesFull(end); acc.neesParam(s)=r.neesParam(end);
        acc.neesC(s)=r.neesC(end); acc.neesR(s)=r.neesR(end);
        acc.cMape(s)=r.CMape; acc.rMape(s)=r.ESRMape;
        acc.cError(s)=r.Cfinal-params{c}.C1; acc.rError(s)=r.ESRfinal-params{c}.ESR;
        acc.cSigma(s)=r.sigmaC; acc.rSigma(s)=r.sigmaESR;
        acc.coverC(s)=r.CI_C_contains_true; acc.coverR(s)=r.CI_ESR_contains_true;
        acc.pass(s)=r.CMape<3 && r.ESRMape<5;
        sr=sr+1; seedRows(sr,:)={scenarioNames(c),s,r.Cfinal,r.ESRfinal, ...
            r.CMape,r.ESRMape,r.sigmaC,r.sigmaESR,r.neesFull(end), ...
            r.neesParam(end),r.CI_C_contains_true,r.CI_ESR_contains_true,acc.pass(s)};
    end
    [fLo,fHi]=average_nees_bounds(nSeed,3); [pLo,pHi]=average_nees_bounds(nSeed,2);
    statRows(c,:)={scenarioNames(c),nSeed,mean(v),median(v),prctile(v,95), ...
        mean(v<=3.841458821),mean(v>locked.gateV),mean(q),median(q), ...
        prctile(q,95),mean(q<=3.841458821),mean(q>locked.gateC), ...
        mean(e),median(e),prctile(e,95),mean(e<=3.841458821), ...
        mean(e>locked.gateR),mean(acc.neesFull),fLo,fHi, ...
        mean(acc.neesParam),pLo,pHi,mean(acc.neesC),mean(acc.neesR), ...
        mean(acc.coverC),mean(acc.coverR),mean(acc.cMape),prctile(acc.cMape,95), ...
        mean(acc.rMape),prctile(acc.rMape,95),mean(acc.pass), ...
        cfgs{c}.fsAdcHz,cfgs{c}.afeFcVHz,cfgs{c}.afeFcI1Hz};
    allCError=[allCError;acc.cError]; allRError=[allRError;acc.rError]; %#ok<AGROW>
    allCSigma=[allCSigma;acc.cSigma]; allRSigma=[allRSigma;acc.rSigma]; %#ok<AGROW>
    fprintf("v2.1 statistics %s: pass %.1f%%, CI C/R %.1f/%.1f%%.\n", ...
        scenarioNames(c),100*mean(acc.pass),100*mean(acc.coverC),100*mean(acc.coverR));
end
names=["scenario","seed_count","NIS_V_mean","NIS_V_p50","NIS_V_p95", ...
    "NIS_V_95_coverage","NIS_V_rejection_fraction","NIS_C_mean","NIS_C_p50", ...
    "NIS_C_p95","NIS_C_95_coverage","NIS_C_rejection_fraction", ...
    "NIS_R_mean","NIS_R_p50","NIS_R_p95","NIS_R_95_coverage", ...
    "NIS_R_rejection_fraction","NEES_full_mean","NEES_full_95_lower", ...
    "NEES_full_95_upper","NEES_param_mean","NEES_param_95_lower", ...
    "NEES_param_95_upper","NEES_C_mean","NEES_ESR_mean","CI_C_95_coverage", ...
    "CI_ESR_95_coverage","C_MAPE_mean_percent","C_MAPE_p95_percent", ...
    "ESR_MAPE_mean_percent","ESR_MAPE_p95_percent","joint_pass_fraction", ...
    "fs_adc_Hz","afe_fc_v_Hz","afe_fc_i_Hz"];
statisticsTable=cell2table(statRows,"VariableNames",names);
writetable(statisticsTable,fullfile(tableDir,"table_NIS_NEES_v21.csv"));
seedTable=cell2table(seedRows,"VariableNames",["scenario","seed","C_est_F", ...
    "ESR_est_Ohm","C_MAPE_percent","ESR_MAPE_percent","sigma_C_F", ...
    "sigma_ESR_Ohm","NEES_full","NEES_param","CI_C_contains_true", ...
    "CI_ESR_contains_true","accuracy_pass"]);
writetable(seedTable,fullfile(tableDir,"table_NIS_NEES_seed_level_v21.csv"));

fig=figure("Visible","off","Color","w"); tiledlayout(1,2);
nexttile; bar(categorical(statisticsTable.scenario), ...
    [statisticsTable.NIS_V_mean,statisticsTable.NIS_C_mean,statisticsTable.NIS_R_mean]);
yline(1,"k:"); grid on; ylabel("NIS mean"); legend("V","C","ESR");
title("Scalar innovation consistency — locked blind cases");
nexttile; errorbar(1:height(statisticsTable),statisticsTable.NEES_param_mean, ...
    statisticsTable.NEES_param_mean-statisticsTable.NEES_param_95_lower, ...
    statisticsTable.NEES_param_95_upper-statisticsTable.NEES_param_mean,"o");
hold on; yline(2,"k:"); xticks(1:height(statisticsTable));
xticklabels(statisticsTable.scenario); grid on; ylabel("Parameter NEES mean");
title("100-seed parameter NEES and 95% reference interval");
save_verification_figure(fig,figureDir,"fig_v21_07_NIS_NEES_consistency");

levels=[.50,.80,.90,.95,.99]; z=[.67448975,1.28155157,1.64485363,1.95996398,2.5758293];
coverageC=zeros(size(levels)); coverageR=coverageC;
for k=1:numel(levels)
    coverageC(k)=mean(abs(allCError)<=z(k)*allCSigma);
    coverageR(k)=mean(abs(allRError)<=z(k)*allRSigma);
end
coverageTable=table(levels',coverageC',coverageR',VariableNames= ...
    ["nominal_coverage","empirical_C_coverage","empirical_ESR_coverage"]);
writetable(coverageTable,fullfile(tableDir,"table_CI_calibration_v21.csv"));
fig=figure("Visible","off","Color","w"); tiledlayout(1,2);
nexttile; bar(categorical(statisticsTable.scenario),100*[statisticsTable.CI_C_95_coverage, ...
    statisticsTable.CI_ESR_95_coverage]); yline(95,"k:"); ylim([0,105]); grid on;
ylabel("95% interval coverage (%)"); legend("C","ESR"); title("Coverage by blind case");
nexttile; plot(100*levels,100*coverageC,"o-"); hold on;
plot(100*levels,100*coverageR,"s-"); plot([45,100],[45,100],"k:"); axis square;
grid on; xlabel("Nominal coverage (%)"); ylabel("Empirical coverage (%)");
legend("C","ESR","ideal","Location","northwest"); title("Parameter CI calibration");
save_verification_figure(fig,figureDir,"fig_v21_08_CI_coverage");

summary=struct("reuseRows",height(reuseTable),"scenarioRows",height(statisticsTable), ...
    "seedRows",height(seedTable),"minJointPass",min(statisticsTable.joint_pass_fraction), ...
    "meanC95Coverage",mean(statisticsTable.CI_C_95_coverage), ...
    "meanR95Coverage",mean(statisticsTable.CI_ESR_95_coverage));
save(fullfile(rawDir,"estimator_statistics_v21.mat"),"summary","reuseTable", ...
    "statisticsTable","seedTable","coverageTable","-v7.3");
end

function [names,bases,params,cfgs]=statistical_scenarios(v21Root,cfg0)
names=["nominal","high_D","low_CCM_margin","noise_10mV_5mA", ...
    "opposed_delay_200ns","modelB_20nH"];
bases=cell(1,6); params=cell(1,6); cfgs=repmat({cfg0},1,6);
for k=1:5, params{k}=model_parameters(); end
params{2}.D=.65; params{2}.Rload=6;
params{3}.Rload=35;
cfgs{4}.sigmaVmV=10; cfgs{4}.sigmaImA=5;
cfgs{5}.voltageDelayNs=200; cfgs{5}.i1DelayNs=-200; cfgs{5}.i2DelayNs=-200;
for k=1:5
    bases{k}=simulate_switched_equation(params{k}, ...
        struct("duration",.003,"samplesPerPeriod",400));
end
params{6}=model_parameters(); bases{6}=run_modelB_v21(v21Root,params{6},20e-9,.003);
end

function acc=empty_accumulator(n)
z=zeros(n,1); acc=struct("neesFull",z,"neesParam",z,"neesC",z, ...
    "neesR",z,"cMape",z,"rMape",z,"cError",z,"rError",z, ...
    "cSigma",z,"rSigma",z,"coverC",false(n,1),"coverR",false(n,1), ...
    "pass",false(n,1));
end

function [lo,hi]=average_nees_bounds(n,dof)
lo=chi2inv(.025,n*dof)/n; hi=chi2inv(.975,n*dof)/n;
end
