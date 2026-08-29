function summary = run_parameter_sweep(rootDir)
%RUN_PARAMETER_SWEEP Sensitivity, identifiability, observability and CCM sweep.

if nargin<1, rootDir=fileparts(fileparts(mfilename("fullpath"))); end
addpath(genpath(rootDir));
tableDir=fullfile(rootDir,"results","tables");
figureDir=fullfile(rootDir,"results","figures");
sweepDir=fullfile(rootDir,"results","sweep");
if ~isfolder(tableDir), mkdir(tableDir); end
if ~isfolder(figureDir), mkdir(figureDir); end
if ~isfolder(sweepDir), mkdir(sweepDir); end
p0=model_parameters();
previousOperating=[];
operatingPath=fullfile(tableDir,"result_operating_sweep.csv");
if isfile(operatingPath)
    candidate=readtable(operatingPath,"TextType","string");
    if all(ismember(["LTVKF_C_MAPE_percent","LTVKF_ESR_MAPE_percent"], ...
            string(candidate.Properties.VariableNames)))
        previousOperating=candidate;
    end
end

%% 5-by-5 C-ESR orthogonality matrix.
cFraction=[1,.95,.90,.85,.80];
rFraction=[1,1.25,1.50,1.75,2.00];
FR=zeros(numel(rFraction),numel(cFraction));
FC=zeros(size(FR));
rankMatrix=zeros(size(FR));
condMatrix=zeros(size(FR));
crossRows=zeros(numel(FR),10);
idRows={};
testIndex=0;
for ir=1:numel(rFraction)
    for ic=1:numel(cFraction)
        p=p0; p.C1=p0.C1*cFraction(ic); p.ESR=p0.ESR*rFraction(ir);
        data=simulate_switched_equation(p,struct("duration",0.006,"samplesPerPeriod",200));
        f=extract_cycle_features(data,struct("nCycles",120));
        FR(ir,ic)=mean(f.edgeTable.ESR_edge_Ohm);
        FC(ir,ic)=mean([f.capTable.C_OFF_F;f.capTable.C_ON_F]);
        rankMatrix(ir,ic)=f.rankPhi;
        condMatrix(ir,ic)=f.condGramNormalized;
        testIndex=testIndex+1;
        idRows(end+1,:)={testIndex,"sensitivity",p.Vin,p.D,1,p.Rload,p.C1,p.ESR, ...
            f.rankPhi,f.lambdaMin,f.condGram,f.condGramNormalized}; %#ok<AGROW>
    end
end
Cvalues=p0.C1*cFraction;
Rvalues=p0.ESR*rFraction;
[dFRdC,dFRdR]=gradient(FR,mean(abs(diff(Cvalues))),mean(diff(Rvalues)));
[dFCdC,dFCdR]=gradient(FC,mean(abs(diff(Cvalues))),mean(diff(Rvalues)));
row=0;
for ir=1:numel(rFraction)
    for ic=1:numel(cFraction)
        row=row+1;
        crossRows(row,:)=[cFraction(ic),rFraction(ir),FR(ir,ic),FC(ir,ic), ...
            abs(dFRdC(ir,ic)),abs(dFRdR(ir,ic)),abs(dFCdC(ir,ic)), ...
            abs(dFCdR(ir,ic)),abs(Cvalues(ic)/FR(ir,ic)*dFRdC(ir,ic)), ...
            abs(Rvalues(ir)/FC(ir,ic)*dFCdR(ir,ic))];
    end
end
crossTable=array2table(crossRows,"VariableNames",["C_over_C0","ESR_over_ESR0", ...
    "F_R_Ohm","F_C_F","S_R_C_Ohm_per_F","S_R_R", ...
    "S_C_C","S_C_R_F_per_Ohm","normalized_cross_R_C","normalized_cross_C_R"]);
writetable(crossTable,fullfile(tableDir,"table_cross_sensitivity.csv"));

fig=figure("Visible","off","Color","w");
imagesc(cFraction,rFraction,1e3*FR); axis xy; colorbar;
xlabel("C/C_0"); ylabel("ESR/ESR_0"); title("ESR-sensitive edge feature F_R (mOhm)");
save_verification_figure(fig,figureDir,"fig_04_esr_feature_heatmap");
fig=figure("Visible","off","Color","w");
imagesc(cFraction,rFraction,1e6*FC); axis xy; colorbar;
xlabel("C/C_0"); ylabel("ESR/ESR_0"); title("Charge-domain capacitance feature F_C (uF)");
save_verification_figure(fig,figureDir,"fig_05_c_feature_heatmap");

%% Load observability and operating-condition sweep.
loadFractions=[.10,.25,.50,.75,1.0];
obsRows={};
obsFigure=zeros(numel(loadFractions),4);
for il=1:numel(loadFractions)
    p=p0; p.Rload=p0.Rload/loadFractions(il);
    data=simulate_switched_equation(p,struct("duration",0.006,"samplesPerPeriod",200));
    tail=data.t>=data.t(end)-100*p.Ts;
    margin=min([data.i1(tail);data.i2(tail)]);
    obs=ltv_observability(subset_data(data,find(tail)),[3,5,10],struct("sampleStride",4));
    for k=1:height(obs)
        obsRows(end+1,:)={"load_sweep",p.Vin,p.D,loadFractions(il),p.C1,p.ESR,margin, ...
            obs.window_N(k),obs.rank_min(k),obs.rank_median(k),obs.sigma_min_worst(k), ...
            obs.sigma_min_median(k),obs.condition_worst(k),obs.condition_median(k)}; %#ok<AGROW>
    end
    row10=obs.window_N==10;
    obsFigure(il,:)=[loadFractions(il),margin,obs.sigma_min_worst(row10),obs.sigma_min_median(row10)];
end

vinRatios=[.8,1,1.2];
dutyValues=[.25,.35,.45,.55,.65];
opRows={};
opIndex=0;
for iv=1:numel(vinRatios)
    for id=1:numel(dutyValues)
        for il=1:numel(loadFractions)
            opIndex=opIndex+1;
            p=p0; p.Vin=p0.Vin*vinRatios(iv); p.D=dutyValues(id);
            p.Rload=p0.Rload/loadFractions(il);
            data=simulate_switched_equation(p,struct("duration",0.005,"samplesPerPeriod",200));
            tail=data.t>=data.t(end)-100*p.Ts;
            margin=min([data.i1(tail);data.i2(tail)]);
            f=extract_cycle_features(data,struct("nCycles",100));
            idRows(end+1,:)={opIndex,"operating",p.Vin,p.D,loadFractions(il),p.Rload, ...
                p.C1,p.ESR,f.rankPhi,f.lambdaMin,f.condGram,f.condGramNormalized}; %#ok<AGROW>
            if margin<=0
                status="EXCLUDED_DCM";
                rlsC=NaN; rlsR=NaN; kfC=NaN; kfR=NaN; conv=NaN;
                obsRank=NaN; obsCond=NaN; obsSigma=NaN;
            else
                status="CCM";
                rls=topology_rls(f.Phi,f.z,struct("Cnom",p.C1,"ESRnom",p.ESR));
                kfPart=subset_data(data,find(data.t>=data.t(end)-0.003));
                measurementVariance=max(1e-8,(2.5e-5*mean(abs(kfPart.vT)))^2);
                kf=ts_ltvkf(kfPart,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
                    "measurementVariance",measurementVariance));
                rlsC=abs(rls.Cfinal/p.C1-1)*100;
                rlsR=abs(rls.ESRfinal/p.ESR-1)*100;
                kfC=abs(kf.Cfinal/p.C1-1)*100;
                kfR=abs(kf.ESRfinal/p.ESR-1)*100;
                conv=max(convergence_time(kf.t,kf.C,p.C1,.02,1000), ...
                    convergence_time(kf.t,kf.ESR,p.ESR,.03,1000));
                obs=ltv_observability(kfPart,10,struct("sampleStride",4));
                obsRank=obs.rank_min; obsCond=obs.condition_worst; obsSigma=obs.sigma_min_worst;
                obsRows(end+1,:)={"operating",p.Vin,p.D,loadFractions(il),p.C1,p.ESR,margin, ...
                    10,obs.rank_min,obs.rank_median,obs.sigma_min_worst,obs.sigma_min_median, ...
                    obs.condition_worst,obs.condition_median}; %#ok<AGROW>
            end
            oldKfC=NaN; oldKfR=NaN; oldFixedC=NaN; oldFixedR=NaN;
            if ~isempty(previousOperating) && height(previousOperating)>=opIndex
                oldKfC=previousOperating.LTVKF_C_MAPE_percent(opIndex);
                oldKfR=previousOperating.LTVKF_ESR_MAPE_percent(opIndex);
                if all(ismember(["LTVKF_robust_C_MAPE_percent", ...
                        "LTVKF_robust_ESR_MAPE_percent"], ...
                        string(previousOperating.Properties.VariableNames)))
                    oldFixedC=previousOperating.LTVKF_robust_C_MAPE_percent(opIndex);
                    oldFixedR=previousOperating.LTVKF_robust_ESR_MAPE_percent(opIndex);
                end
            end
            opRows(end+1,:)={opIndex,p.Vin,p.D,loadFractions(il),p.Rload,margin, ...
                f.rankPhi,f.condGramNormalized,rlsC,rlsR,oldKfC,oldKfR, ...
                oldFixedC,oldFixedR,kfC,kfR,conv,obsRank,obsCond,obsSigma,status}; %#ok<AGROW>
        end
    end
end
operatingTable=cell2table(opRows,"VariableNames",["test_id","Vin_V","D", ...
    "load_fraction","Rload_Ohm","ccm_margin_A","rank_Phi","cond_Phi_normalized", ...
    "RLS_C_MAPE_percent","RLS_ESR_MAPE_percent","LTVKF_C_MAPE_percent", ...
    "LTVKF_ESR_MAPE_percent","LTVKF_robust_C_MAPE_percent", ...
    "LTVKF_robust_ESR_MAPE_percent","LTVKF_adaptive_C_MAPE_percent", ...
    "LTVKF_adaptive_ESR_MAPE_percent","LTVKF_convergence_s","rank_Obs", ...
    "cond_Obs","min_singular_Obs","status"]);
writetable(operatingTable,fullfile(tableDir,"result_operating_sweep.csv"));

idTable=cell2table(idRows,"VariableNames",["test_id","test_group","Vin_V","D", ...
    "load_fraction","Rload_Ohm","C_F","ESR_Ohm","rank_Phi", ...
    "lambda_min_gram","cond_gram_raw","cond_gram_normalized"]);
writetable(idTable,fullfile(tableDir,"table_identifiability.csv"));
obsTable=cell2table(obsRows,"VariableNames",["test_group","Vin_V","D", ...
    "load_fraction","C_F","ESR_Ohm","ccm_margin_A","window_N", ...
    "rank_min","rank_median","sigma_min_worst","sigma_min_median", ...
    "condition_worst","condition_median"]);
writetable(obsTable,fullfile(tableDir,"table_ltv_observability.csv"));

fig=figure("Visible","off","Color","w");
yyaxis left; semilogy(100*obsFigure(:,1),obsFigure(:,3),"o-","LineWidth",1.2); hold on;
semilogy(100*obsFigure(:,1),obsFigure(:,4),"s--","LineWidth",1.2);
ylabel("Minimum singular value, N=10");
yyaxis right; plot(100*obsFigure(:,1),obsFigure(:,2),"d-","LineWidth",1.1);
ylabel("CCM current margin (A)"); xlabel("Load (%)"); grid on;
legend("Worst window","Median window","CCM margin","Location","best");
title("Finite-window TS-LTVKF observability versus load");
save_verification_figure(fig,figureDir,"fig_06_observability_vs_load");

%% LTVKF initialization robustness.
nominal=simulate_switched_equation(p0,struct("duration",0.004,"samplesPerPeriod",200));
sets=[.7,.5;1.3,1.5];
rng(20260821,"twister");
sets=[sets;[.6+.8*rand(20,1),.5+1.5*rand(20,1)]];
initRows=zeros(size(sets,1),10);
for k=1:size(sets,1)
    kf=ts_ltvkf(nominal,struct("Cnom",p0.C1,"ESRnom",p0.ESR, ...
        "Cinit",sets(k,1)*p0.C1,"ESRinit",sets(k,2)*p0.ESR));
    cErr=abs(kf.Cfinal/p0.C1-1)*100;
    rErr=abs(kf.ESRfinal/p0.ESR-1)*100;
    conv=max(convergence_time(kf.t,kf.C,p0.C1,.02,1000), ...
        convergence_time(kf.t,kf.ESR,p0.ESR,.03,1000));
    converged=isfinite(conv) && cErr<2 && rErr<3;
    physical=all(kf.C>0) && all(kf.ESR>=0);
    initRows(k,:)=[k,sets(k,1),sets(k,2),kf.Cfinal,kf.ESRfinal,cErr,rErr,conv,converged,physical];
end
initTable=array2table(initRows,"VariableNames",["run","C_init_over_C0", ...
    "ESR_init_over_ESR0","C_final_F","ESR_final_Ohm","C_MAPE_percent", ...
    "ESR_MAPE_percent","convergence_time_s","converged","physical"]);
writetable(initTable,fullfile(tableDir,"table_initialization_robustness.csv"));

summary=struct("maxCrossRC",max(crossTable.normalized_cross_R_C), ...
    "maxCrossCR",max(crossTable.normalized_cross_C_R), ...
    "rankPhiMin",min(rankMatrix,[],"all"),"condPhiWorst",max(condMatrix,[],"all"), ...
    "ccmCases",sum(operatingTable.status=="CCM"), ...
    "dcmExcluded",sum(operatingTable.status=="EXCLUDED_DCM"), ...
    "initializationSuccessRate",mean(initTable.converged));
save(fullfile(sweepDir,"parameter_sweep.mat"),"summary","FR","FC", ...
    "crossTable","operatingTable","idTable","obsTable","initTable");
fprintf('Sweep: rank(Phi) min %d, CCM %d/%d, init success %.1f%%\n', ...
    summary.rankPhiMin,summary.ccmCases,height(operatingTable),100*summary.initializationSuccessRate);
end

function out=subset_data(data,idx)
fields=fieldnames(data); out=data;
for k=1:numel(fields)
    value=data.(fields{k});
    if isvector(value) && numel(value)==numel(data.t), out.(fields{k})=value(idx); end
end
end
