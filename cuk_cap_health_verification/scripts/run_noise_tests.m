function summary = run_noise_tests(rootDir)
%RUN_NOISE_TESTS Deterministic Monte Carlo sensor-noise verification.

if nargin<1, rootDir=fileparts(fileparts(mfilename("fullpath"))); end
addpath(genpath(rootDir));
tableDir=fullfile(rootDir,"results","tables");
figureDir=fullfile(rootDir,"results","figures");
noiseDir=fullfile(rootDir,"results","noise");
if ~isfolder(tableDir), mkdir(tableDir); end
if ~isfolder(figureDir), mkdir(figureDir); end
if ~isfolder(noiseDir), mkdir(noiseDir); end
p=model_parameters();
base=simulate_switched_equation(p,struct("duration",0.004,"samplesPerPeriod",200));
snrValues=[20,30,40,50];
seeds=1:20;
targets=["vT","i1","i2","all"];
rawRows={};
runId=0;

for it=1:numel(targets)
    for is=1:numel(snrValues)
        for seed=seeds
            runId=runId+1;
            data=base;
            switch targets(it)
                case "vT"
                    data.vT=add_awgn_at_snr(base.vT,snrValues(is),seed);
                case "i1"
                    data.i1=add_awgn_at_snr(base.i1,snrValues(is),seed+1000);
                case "i2"
                    data.i2=add_awgn_at_snr(base.i2,snrValues(is),seed+2000);
                case "all"
                    data.vT=add_awgn_at_snr(base.vT,snrValues(is),seed);
                    data.i1=add_awgn_at_snr(base.i1,snrValues(is),seed+1000);
                    data.i2=add_awgn_at_snr(base.i2,snrValues(is),seed+2000);
            end
            data.iC=(1-data.u).*data.i1-data.u.*data.i2;
            f=measured_regression_features(data,struct("startTime",data.t(1)+20*p.Ts));
            rls=topology_rls(f.Phi,f.z,struct("Cnom",p.C1,"ESRnom",p.ESR));
            tailR=max(1,floor(.8*numel(rls.C))):numel(rls.C);
            rlsC=median(rls.C(tailR)); rlsR=median(rls.ESR(tailR));

            if targets(it)=="vT" || targets(it)=="all"
                measurementVariance=rms(base.vT)^2/10^(snrValues(is)/10);
            else
                measurementVariance=max(1e-8,(2.5e-5*mean(abs(base.vT)))^2);
            end
            kf=ts_ltvkf(data,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
                "measurementVariance",measurementVariance,"gateThreshold",20));
            tailK=max(1,floor(.8*numel(kf.C))):numel(kf.C);
            kfC=median(kf.C(tailK)); kfR=median(kf.ESR(tailK));
            rawRows(end+1,:)=make_row(runId,targets(it),snrValues(is),seed,"RLS",rlsC,rlsR,p); %#ok<AGROW>
            rawRows(end+1,:)=make_row(runId,targets(it),snrValues(is),seed,"TS_LTVKF",kfC,kfR,p); %#ok<AGROW>
        end
    end
end
rawTable=cell2table(rawRows,"VariableNames",["run_id","noise_target","SNR_dB", ...
    "seed","method","C_est_F","C_MAPE_percent","ESR_est_Ohm", ...
    "ESR_MAPE_percent","failed"]);
writetable(rawTable,fullfile(noiseDir,"noise_monte_carlo_raw.csv"));

aggRows={};
for it=1:numel(targets)
    for is=1:numel(snrValues)
        for method=["RLS","TS_LTVKF"]
            select=rawTable.noise_target==targets(it) & rawTable.SNR_dB==snrValues(is) & rawTable.method==method;
            Cerror=rawTable.C_MAPE_percent(select);
            Rerror=rawTable.ESR_MAPE_percent(select);
            aggRows(end+1,:)={targets(it),snrValues(is),method,median(Cerror), ...
                mean(Cerror),prctile(Cerror,95),median(Rerror),mean(Rerror), ...
                prctile(Rerror,95),mean(rawTable.failed(select))}; %#ok<AGROW>
        end
    end
end
noiseTable=cell2table(aggRows,"VariableNames",["noise_target","SNR_dB","method", ...
    "C_MAPE_median_percent","C_MAPE_mean_percent","C_MAPE_p95_percent", ...
    "ESR_MAPE_median_percent","ESR_MAPE_mean_percent", ...
    "ESR_MAPE_p95_percent","failure_rate"]);
writetable(noiseTable,fullfile(tableDir,"table_noise_monte_carlo.csv"));

allNoise=noiseTable(noiseTable.noise_target=="all",:);
fig=figure("Visible","off","Color","w");
tiledlayout(2,1);
nexttile; hold on;
for method=["RLS","TS_LTVKF"]
    q=allNoise(allNoise.method==method,:);
    errorbar(q.SNR_dB,q.C_MAPE_median_percent, ...
        q.C_MAPE_p95_percent-q.C_MAPE_median_percent,"o-","LineWidth",1.1);
end
yline(3,"k:","3% target"); grid on; ylabel("C MAPE (%)");
legend("RLS median-to-p95","TS-LTVKF median-to-p95","Target","Location","best");
title("All-sensor Monte Carlo noise robustness, seeds 1-20");
nexttile; hold on;
for method=["RLS","TS_LTVKF"]
    q=allNoise(allNoise.method==method,:);
    errorbar(q.SNR_dB,q.ESR_MAPE_median_percent, ...
        q.ESR_MAPE_p95_percent-q.ESR_MAPE_median_percent,"o-","LineWidth",1.1);
end
yline(5,"k:","5% target"); grid on; xlabel("Measurement SNR (dB)");
ylabel("ESR MAPE (%)"); legend("RLS median-to-p95", ...
    "TS-LTVKF median-to-p95","Target","Location","best");
save_verification_figure(fig,figureDir,"fig_07_error_vs_snr");

at30=allNoise(allNoise.SNR_dB==30,:);
summary=struct("runs",height(rawTable), ...
    "rls30C",at30.C_MAPE_median_percent(at30.method=="RLS"), ...
    "rls30ESR",at30.ESR_MAPE_median_percent(at30.method=="RLS"), ...
    "kf30C",at30.C_MAPE_median_percent(at30.method=="TS_LTVKF"), ...
    "kf30ESR",at30.ESR_MAPE_median_percent(at30.method=="TS_LTVKF"));
save(fullfile(noiseDir,"noise_summary.mat"),"summary","rawTable","noiseTable");
fprintf('Noise all-sensor 30 dB median RLS C/R %.3g/%.3g%%; KF %.3g/%.3g%%\n', ...
    summary.rls30C,summary.rls30ESR,summary.kf30C,summary.kf30ESR);
end

function row=make_row(runId,target,snrDb,seed,method,Cest,Rest,p)
cError=abs(Cest/p.C1-1)*100;
rError=abs(Rest/p.ESR-1)*100;
failed=~isfinite(cError) || ~isfinite(rError) || cError>10 || rError>20;
row={runId,target,snrDb,seed,method,Cest,cError,Rest,rError,failed};
end
