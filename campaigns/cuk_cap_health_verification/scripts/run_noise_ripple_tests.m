function summary = run_noise_ripple_tests(rootDir)
%RUN_NOISE_RIPPLE_TESTS Repeat Monte Carlo with AC-ripple-referenced SNR.

if nargin<1, rootDir=fileparts(fileparts(mfilename("fullpath"))); end
addpath(genpath(rootDir));
tableDir=fullfile(rootDir,"results","tables");
figureDir=fullfile(rootDir,"results","figures");
noiseDir=fullfile(rootDir,"results","noise");
p=model_parameters();
base=simulate_switched_equation(p,struct("duration",0.004,"samplesPerPeriod",200));
snrValues=[20,30,40,50]; seeds=1:20;
targets=["vT","i1","i2","all"];
baselinePath=fullfile(noiseDir,"noise_monte_carlo_raw.csv");
baseline=readtable(baselinePath,"TextType","string");
baseline=addvars(baseline,repmat("full_signal_rms",height(baseline),1), ...
    'Before','noise_target','NewVariableNames','snr_reference');
rows={}; runId=max(baseline.run_id);

for it=1:numel(targets)
    for is=1:numel(snrValues)
        for seed=seeds
            runId=runId+1; data=base;
            switch targets(it)
                case "vT"
                    data.vT=add_ac_noise(base.vT,snrValues(is),seed);
                case "i1"
                    data.i1=add_ac_noise(base.i1,snrValues(is),seed+1000);
                case "i2"
                    data.i2=add_ac_noise(base.i2,snrValues(is),seed+2000);
                case "all"
                    data.vT=add_ac_noise(base.vT,snrValues(is),seed);
                    data.i1=add_ac_noise(base.i1,snrValues(is),seed+1000);
                    data.i2=add_ac_noise(base.i2,snrValues(is),seed+2000);
            end
            data.iC=(1-data.u).*data.i1-data.u.*data.i2;
            f=measured_regression_features(data,struct("startTime",data.t(1)+20*p.Ts));
            rls=topology_rls(f.Phi,f.z,struct("Cnom",p.C1,"ESRnom",p.ESR));
            tailR=max(1,floor(.8*numel(rls.C))):numel(rls.C);
            rlsC=median(rls.C(tailR)); rlsR=median(rls.ESR(tailR));
            if targets(it)=="vT" || targets(it)=="all"
                % Keep a model-mismatch floor: an overconfident covariance at
                % high SNR rejects valid topology transitions and diverges.
                measurementVariance=max(1e-5, ...
                    rms(base.vT-mean(base.vT))^2/10^(snrValues(is)/10));
            else
                measurementVariance=max(1e-8,(2.5e-5*mean(abs(base.vT)))^2);
            end
            kf=ts_ltvkf(data,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
                "measurementVariance",measurementVariance,"gateThreshold",20));
            tailK=max(1,floor(.8*numel(kf.C))):numel(kf.C);
            kfC=median(kf.C(tailK)); kfR=median(kf.ESR(tailK));
            rows(end+1,:)=make_row(runId,targets(it),snrValues(is),seed,"RLS",rlsC,rlsR,p); %#ok<AGROW>
            rows(end+1,:)=make_row(runId,targets(it),snrValues(is),seed,"TS_LTVKF",kfC,kfR,p); %#ok<AGROW>
        end
    end
end
ripple=cell2table(rows,"VariableNames",["run_id","snr_reference","noise_target", ...
    "SNR_dB","seed","method","C_est_F","C_MAPE_percent", ...
    "ESR_est_Ohm","ESR_MAPE_percent","failed"]);
rawTable=[baseline;ripple];
writetable(rawTable,fullfile(noiseDir,"noise_monte_carlo_raw_all_definitions.csv"));

refs=["full_signal_rms","ac_ripple_rms"];
aggRows={};
for ir=1:numel(refs)
    for it=1:numel(targets)
        for is=1:numel(snrValues)
            for method=["RLS","TS_LTVKF"]
                select=rawTable.snr_reference==refs(ir) & rawTable.noise_target==targets(it) & ...
                    rawTable.SNR_dB==snrValues(is) & rawTable.method==method;
                ce=rawTable.C_MAPE_percent(select); re=rawTable.ESR_MAPE_percent(select);
                aggRows(end+1,:)={refs(ir),targets(it),snrValues(is),method,median(ce), ...
                    mean(ce),prctile(ce,95),median(re),mean(re),prctile(re,95), ...
                    mean(rawTable.failed(select))}; %#ok<AGROW>
            end
        end
    end
end
noiseTable=cell2table(aggRows,"VariableNames",["snr_reference","noise_target", ...
    "SNR_dB","method","C_MAPE_median_percent","C_MAPE_mean_percent", ...
    "C_MAPE_p95_percent","ESR_MAPE_median_percent","ESR_MAPE_mean_percent", ...
    "ESR_MAPE_p95_percent","failure_rate"]);
writetable(noiseTable,fullfile(tableDir,"table_noise_monte_carlo.csv"));

q=noiseTable(noiseTable.noise_target=="all",:);
fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
nexttile; hold on;
for ref=refs
    for method=["RLS","TS_LTVKF"]
        z=q(q.snr_reference==ref & q.method==method,:);
        semilogy(z.SNR_dB,z.C_MAPE_median_percent,"o-","LineWidth",1.1, ...
            "DisplayName",ref+" / "+method);
    end
end
yline(3,"k:","3% target"); grid on; ylabel("Median C MAPE (%)");
legend("Location","best"); title("Noise robustness under two explicit SNR definitions");
nexttile; hold on;
for ref=refs
    for method=["RLS","TS_LTVKF"]
        z=q(q.snr_reference==ref & q.method==method,:);
        semilogy(z.SNR_dB,z.ESR_MAPE_median_percent,"o-","LineWidth",1.1, ...
            "DisplayName",ref+" / "+method);
    end
end
yline(5,"k:","5% target"); grid on; xlabel("SNR (dB)");
ylabel("Median ESR MAPE (%)"); legend("Location","best");
save_verification_figure(fig,figureDir,"fig_07_error_vs_snr");

at30=q(q.SNR_dB==30,:);
summary=struct("fullKF_C",value(at30,"full_signal_rms","TS_LTVKF","C_MAPE_median_percent"), ...
    "fullKF_ESR",value(at30,"full_signal_rms","TS_LTVKF","ESR_MAPE_median_percent"), ...
    "rippleKF_C",value(at30,"ac_ripple_rms","TS_LTVKF","C_MAPE_median_percent"), ...
    "rippleKF_ESR",value(at30,"ac_ripple_rms","TS_LTVKF","ESR_MAPE_median_percent"));
save(fullfile(noiseDir,"noise_all_definitions.mat"),"summary","rawTable","noiseTable");
fprintf('30 dB KF all-sensor: full-RMS C/R %.3g/%.3g%%; ripple-RMS %.3g/%.3g%%\n', ...
    summary.fullKF_C,summary.fullKF_ESR,summary.rippleKF_C,summary.rippleKF_ESR);
end

function noisy=add_ac_noise(signal,snrDb,seed)
ac=signal-mean(signal);
noisyAc=add_awgn_at_snr(ac,snrDb,seed);
noisy=signal+(noisyAc-ac);
end

function row=make_row(runId,target,snrDb,seed,method,Cest,Rest,p)
cError=abs(Cest/p.C1-1)*100; rError=abs(Rest/p.ESR-1)*100;
failed=~isfinite(cError)||~isfinite(rError)||cError>10||rError>20;
row={runId,"ac_ripple_rms",target,snrDb,seed,method,Cest,cError,Rest,rError,failed};
end

function output=value(tableIn,reference,method,variable)
output=tableIn.(variable)(tableIn.snr_reference==reference & tableIn.method==method);
end
