function summary = run_sampling_tests(rootDir)
%RUN_SAMPLING_TESTS ADC resolution, sample density and PWM timing errors.

if nargin<1, rootDir=fileparts(fileparts(mfilename("fullpath"))); end
addpath(genpath(rootDir));
tableDir=fullfile(rootDir,"results","tables");
figureDir=fullfile(rootDir,"results","figures");
p=model_parameters();
base=simulate_switched_equation(p,struct("duration",0.006,"samplesPerPeriod",200));

%% ADC and samples-per-cycle matrix.
adcBits=[12,14,16]; sampleCounts=[4,8,16,32];
rows={}; testId=0;
for bits=adcBits
    for nSamples=sampleCounts
        idx=sample_indices(numel(base.t),base.samplesPerPeriod,nSamples);
        data=subset_data(base,idx);
        data.vT=quantize(data.vT,bits,0,100);
        data.i1=quantize(data.i1,bits,-5,5);
        data.i2=quantize(data.i2,bits,-5,5);
        data.iC=(1-data.u).*data.i1-data.u.*data.i2;
        f=measured_regression_features(data,struct("startTime",data.t(1)+50*p.Ts));
        edgeError=edge_mape(data,p.ESR);
        rls=topology_rls(f.Phi,f.z,struct("Cnom",p.C1,"ESRnom",p.ESR));
        lsbV=100/(2^bits-1);
        kf=ts_ltvkf(data,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
            "measurementVariance",max(lsbV^2/12,(2.5e-5*mean(abs(data.vT)))^2), ...
            "gateThreshold",20));
        for method=["RLS","TS_LTVKF"]
            testId=testId+1;
            if method=="RLS"
                Cest=median(rls.C(max(1,floor(.8*numel(rls.C))):end));
                Rest=median(rls.ESR(max(1,floor(.8*numel(rls.ESR))):end));
                conv=NaN;
            else
                Cest=median(kf.C(max(1,floor(.8*numel(kf.C))):end));
                Rest=median(kf.ESR(max(1,floor(.8*numel(kf.ESR))):end));
                conv=max(convergence_time(kf.t,kf.C,p.C1,.03,20*nSamples), ...
                    convergence_time(kf.t,kf.ESR,p.ESR,.05,20*nSamples));
            end
            rows(end+1,:)={testId,bits,nSamples,method,Cest,abs(Cest/p.C1-1)*100, ...
                Rest,abs(Rest/p.ESR-1)*100,conv,edgeError,f.rankPhi}; %#ok<AGROW>
        end
    end
end
adcTable=cell2table(rows,"VariableNames",["test_id","adc_bits", ...
    "samples_per_cycle","method","C_est_F","C_MAPE_percent", ...
    "ESR_est_Ohm","ESR_MAPE_percent","convergence_time_s", ...
    "edge_ESR_MAPE_percent","rank_Phi"]);
writetable(adcTable,fullfile(tableDir,"table_adc_sampling.csv"));

%% Relative timing offset between voltage and current/PWM channels.
syncBase=simulate_switched_equation(p,struct("duration",0.004,"samplesPerPeriod",1000));
offsetFractions=[0,.001,.002,.005,.01,.02,.05];
syncRows=zeros(numel(offsetFractions),8);
for k=1:numel(offsetFractions)
    shiftSamples=round(offsetFractions(k)*syncBase.samplesPerPeriod);
    data=syncBase;
    if shiftSamples>0
        data.vT=[repmat(syncBase.vT(1),shiftSamples,1);syncBase.vT(1:end-shiftSamples)];
    end
    f=measured_regression_features(data,struct("startTime",data.t(1)+50*p.Ts));
    rls=topology_rls(f.Phi,f.z,struct("Cnom",p.C1,"ESRnom",p.ESR));
    kf=ts_ltvkf(data,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
        "measurementVariance",max(1e-8,(2.5e-5*mean(abs(data.vT)))^2), ...
        "gateThreshold",20));
    rlsC=median(rls.C(max(1,floor(.8*numel(rls.C))):end));
    rlsR=median(rls.ESR(max(1,floor(.8*numel(rls.ESR))):end));
    kfC=median(kf.C(max(1,floor(.8*numel(kf.C))):end));
    kfR=median(kf.ESR(max(1,floor(.8*numel(kf.ESR))):end));
    syncRows(k,:)=[offsetFractions(k),shiftSamples*syncBase.dt,edge_mape(data,p.ESR), ...
        abs(rlsC/p.C1-1)*100,abs(rlsR/p.ESR-1)*100, ...
        abs(kfC/p.C1-1)*100,abs(kfR/p.ESR-1)*100,f.rankPhi];
end
syncTable=array2table(syncRows,"VariableNames",["sync_error_over_Ts", ...
    "sync_error_s","edge_ESR_MAPE_percent","RLS_C_MAPE_percent", ...
    "RLS_ESR_MAPE_percent","LTVKF_C_MAPE_percent", ...
    "LTVKF_ESR_MAPE_percent","rank_Phi"]);
writetable(syncTable,fullfile(tableDir,"table_sync_error.csv"));

fig=figure("Visible","off","Color","w");
tiledlayout(2,1);
nexttile; plot(100*syncTable.sync_error_over_Ts,syncTable.edge_ESR_MAPE_percent, ...
    "o-","LineWidth",1.2); grid on; ylabel("Edge ESR MAPE (%)");
title("Sensitivity to voltage/current PWM synchronization error");
nexttile; plot(100*syncTable.sync_error_over_Ts,syncTable.RLS_ESR_MAPE_percent, ...
    "o-","LineWidth",1.1); hold on;
plot(100*syncTable.sync_error_over_Ts,syncTable.LTVKF_ESR_MAPE_percent, ...
    "s--","LineWidth",1.1); grid on; xlabel("Timing offset (% of T_s)");
ylabel("ESR MAPE (%)"); legend("RLS","TS-LTVKF","Location","best");
save_verification_figure(fig,figureDir,"fig_08_sync_error");

recommended=adcTable(adcTable.method=="TS_LTVKF" & adcTable.C_MAPE_percent<3 & ...
    adcTable.ESR_MAPE_percent<5,:);
summary=struct("minimumPassingBits",min(recommended.adc_bits), ...
    "minimumPassingSamples",min(recommended.samples_per_cycle), ...
    "maxTestedSyncForFivePercentESR",max(syncTable.sync_error_over_Ts( ...
        syncTable.LTVKF_ESR_MAPE_percent<5)));
save(fullfile(rootDir,"results","sampling_summary.mat"),"summary","adcTable","syncTable");
fprintf('Sampling: minimum passing bits=%d, points/cycle=%d, sync<5%% ESR through %.3g Ts\n', ...
    summary.minimumPassingBits,summary.minimumPassingSamples,summary.maxTestedSyncForFivePercentESR);
end

function idx=sample_indices(n,spp,nSamples)
nCycles=floor((n-1)/spp);
phase=round((0:nSamples-1)*spp/nSamples);
idx=zeros(nCycles*nSamples+1,1); row=0;
for c=0:nCycles-1
    take=c*spp+phase+1;
    idx(row+(1:nSamples))=take;
    row=row+nSamples;
end
idx(end)=min(n,nCycles*spp+1);
idx=unique(idx);
end

function output=quantize(input,bits,minimum,maximum)
levels=2^bits-1;
code=round((input-minimum)/(maximum-minimum)*levels);
code=min(max(code,0),levels);
output=minimum+code/levels*(maximum-minimum);
end

function value=edge_mape(data,trueESR)
rising=find(diff(data.u)>0.5)+1;
rising=rising(rising>1);
estimate=(data.vT(rising-1)-data.vT(rising))./ ...
    (data.i1(rising-1)+data.i2(rising));
value=mean(abs(estimate/trueESR-1))*100;
end

function out=subset_data(data,idx)
fields=fieldnames(data); out=data;
for k=1:numel(fields)
    value=data.(fields{k});
    if isvector(value)&&numel(value)==numel(data.t), out.(fields{k})=value(idx); end
end
end
