function summary=run_v2_timing_doe(v2Root)
%RUN_V2_TIMING_DOE Execute timing, ESL, front-end, ADC and noise studies.

if nargin<1, v2Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v2Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(v2Root));
tableDir=fullfile(v2Root,"results","tables");
figureDir=fullfile(v2Root,"results","figures"); rawDir=fullfile(v2Root,"results","raw");
folders={tableDir,figureDir,rawDir};
for k=1:numel(folders), if ~isfolder(folders{k}), mkdir(folders{k}); end, end
lockedFile=fullfile(rawDir,"locked_covariance.mat");
if isfile(lockedFile), L=load(lockedFile,"locked"); locked=L.locked;
else, locked=train_v2_covariance(v2Root); end
p=model_parameters();
base=simulate_switched_equation(p,struct("duration",.003,"samplesPerPeriod",400));
baseCfg=struct("samplesPerCycle",80,"edgeGuardUs",.5,"edgeWindowUs",1.5, ...
    "edgePointsPerSide",3,"edgeMethod","timestamped_linear", ...
    "RRFloor",locked.RRFloor,"RCFloor",locked.RCFloor);

%% Edge method comparison and timestamp tolerance.
offsets=[-1000,-500,-200,-100,-50,-20,-10,0,10,20,50,100,200,500,1000];
methods=["adjacent","timestamped_linear","robust_polynomial"];
edgeRows=cell(numel(offsets)*numel(methods),13); row=0; example=[];
for io=1:numel(offsets)
    for im=1:numel(methods)
        cfg=baseCfg; cfg.commonPwmOffsetNs=offsets(io); cfg.edgeMethod=methods(im);
        cfg.edgeFitOrder=1+(methods(im)=="robust_polynomial");
        m=v2_make_measurements(base,p,cfg); edge=v2_edge_estimates(m,p,cfg);
        charge=v2_charge_estimates(m,p,cfg);
        row=row+1; edgeRows(row,:)=edge_row(row,offsets(io),methods(im),edge,charge,p,cfg);
        if offsets(io)==200 && methods(im)=="timestamped_linear", example=struct("m",m,"edge",edge); end
    end
end
edgeComparison=cell2table(edgeRows,"VariableNames",["test_id", ...
    "common_pwm_offset_ns","edge_method","C_est_F","C_MAPE_percent", ...
    "ESR_est_Ohm","ESR_MAPE_percent","ESR_p95_MAPE_percent", ...
    "edge_fit_rmse_V","edge_fit_variance_V2","valid_edges", ...
    "edge_guard_us","edge_window_us"]);
writetable(edgeComparison,fullfile(tableDir,"table_edge_estimator_comparison_v2.csv"));
plot_edge_example(example,p,figureDir);
fig=figure("Visible","off","Color","w"); hold on;
for method=methods
    q=edgeComparison(edgeComparison.edge_method==method,:);
    semilogy(q.common_pwm_offset_ns,q.ESR_MAPE_percent,"o-","LineWidth",1.1, ...
        "DisplayName",method);
end
yline(5,"k:","5% target"); grid on; xlabel("PWM timestamp offset (ns)");
ylabel("ESR MAPE (%)"); title("Edge estimator timing tolerance — Model A");
legend("Location","best"); save_verification_figure(fig,figureDir, ...
    "fig_v2_05_edge_method_timing_tolerance");

%% Fixed channel delays: single-channel, pair grid and 100 random combinations.
delayValues=[-1000,-500,-200,-100,-50,-20,0,20,50,100,200,500,1000];
delayRows={}; testId=0;
for channel=["voltage","i1","i2"]
    for d=delayValues
        cfg=baseCfg; cfg=set_delay(cfg,channel,d);
        for method=["adjacent","timestamped_linear","robust_polynomial","TR_TS_LTVKF"]
            testId=testId+1;
            [ce,re,cest,rest,~,preC,preR]=estimate_case(base,p,cfg,locked,method);
            delayRows(end+1,:)={testId,"single_"+channel,d, ...
                get_delay(cfg,"voltage"),get_delay(cfg,"i1"),get_delay(cfg,"i2"), ...
                method,preC,preR,cest,ce,rest,re,pass_fail(ce,re)}; %#ok<AGROW>
        end
    end
end
pairAxis=[-1000,-500,-200,-100,0,100,200,500,1000];
pairMatrix=zeros(numel(pairAxis),numel(pairAxis));
for iv=1:numel(pairAxis)
    for ii=1:numel(pairAxis)
        cfg=baseCfg; cfg.voltageDelayNs=pairAxis(iv);
        cfg.i1DelayNs=pairAxis(ii); cfg.i2DelayNs=pairAxis(ii);
        [ce,re,cest,rest,~,preC,preR]=estimate_case(base,p,cfg,locked,"timestamped_linear");
        testId=testId+1; delayRows(end+1,:)={testId,"pair_grid", ...
            max(abs([pairAxis(iv),pairAxis(ii)])),pairAxis(iv),pairAxis(ii), ...
            pairAxis(ii),"timestamped_linear",preC,preR,cest,ce,rest,re, ...
            pass_fail(ce,re)}; %#ok<AGROW>
        pairMatrix(iv,ii)=re;
    end
end
rng(2202,"twister"); lhs=lhsdesign(100,3,"criterion","maximin");
lhs=-1000+2000*lhs;
for k=1:size(lhs,1)
    cfg=baseCfg; cfg.voltageDelayNs=lhs(k,1); cfg.i1DelayNs=lhs(k,2);
    cfg.i2DelayNs=lhs(k,3);
    [ce,re,cest,rest,~,preC,preR]=estimate_case(base,p,cfg,locked,"TR_TS_LTVKF");
    testId=testId+1; delayRows(end+1,:)={testId,"random_uniform", ...
        max(abs(lhs(k,:))),lhs(k,1),lhs(k,2),lhs(k,3),"TR_TS_LTVKF", ...
        preC,preR,cest,ce,rest,re,pass_fail(ce,re)}; %#ok<AGROW>
end
channelDelay=cell2table(delayRows,"VariableNames",["test_id","test_group", ...
    "delay_magnitude_ns","voltage_delay_ns","i1_delay_ns","i2_delay_ns", ...
    "method","pre_projection_C_F","pre_projection_ESR_Ohm", ...
    "C_est_F","C_MAPE_percent","ESR_est_Ohm", ...
    "ESR_MAPE_percent","status"]);
writetable(channelDelay,fullfile(tableDir,"table_channel_delay_v2.csv"));
fig=figure("Visible","off","Color","w"); tiledlayout(1,3);
for channel=["voltage","i1","i2"]
    nexttile; q=channelDelay(channelDelay.test_group=="single_"+channel & ...
        channelDelay.method=="TR_TS_LTVKF",:);
    plot(q.delay_magnitude_ns.*sign(q.(channel+"_delay_ns")), ...
        q.ESR_MAPE_percent,"o-"); yline(5,"k:"); grid on;
    xlabel(channel+" delay (ns)"); ylabel("ESR MAPE (%)"); title(channel);
end
sgtitle("Single-channel delay — locked TR-TS-LTVKF, Model A");
save_verification_figure(fig,figureDir,"fig_v2_07_delay_single_channel");
fig=figure("Visible","off","Color","w"); imagesc(pairAxis,pairAxis,pairMatrix);
axis xy; colorbar; xlabel("Current-channel delay (ns)"); ylabel("Voltage delay (ns)");
title("Timestamped linear ESR MAPE (%) — Model A");
save_verification_figure(fig,figureDir,"fig_v2_08_delay_pair_heatmap");

%% Jitter Monte Carlo: 3 modes x 8 levels x 50 seeds.
jitterLevels=[0,5,10,20,50,100,200,500]; jitterModes=["common","independent","pwm"];
jitterRows=cell(numel(jitterLevels)*numel(jitterModes)*50,12); row=0;
for mode=jitterModes
    for jt=jitterLevels
        for seed=1:50
            cfg=baseCfg; cfg.samplesPerCycle=40; cfg.edgeWindowUs=2.0;
            cfg.jitterMode=mode; cfg.jitterRmsNs=jt; cfg.seed=3000+seed;
            [ce,re,cest,rest,fitReject,preC,preR]=estimate_case(base,p,cfg,locked,"TR_TS_LTVKF");
            row=row+1; jitterRows(row,:)={mode,jt,seed,preC,preR,cest,ce,rest,re, ...
                pass_fail(ce,re),fitReject,cfg.samplesPerCycle};
        end
    end
end
jitterTable=cell2table(jitterRows,"VariableNames",["jitter_mode", ...
    "jitter_rms_ns","seed","pre_projection_C_F", ...
    "pre_projection_ESR_Ohm","C_est_F","C_MAPE_percent","ESR_est_Ohm", ...
    "ESR_MAPE_percent","status","edge_fit_rejection_rate", ...
    "samples_per_cycle"]);
writetable(jitterTable,fullfile(tableDir,"table_jitter_v2.csv"));
jitterAgg=aggregate_jitter(jitterTable,jitterModes,jitterLevels);
fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
nexttile; hold on; nexttile; hold on;
for mode=jitterModes
    q=jitterAgg(jitterAgg.jitter_mode==mode,:);
    nexttile(1); semilogy(q.jitter_rms_ns,q.C_MAPE_median_percent,"o-", ...
        "DisplayName",mode); nexttile(2);
    semilogy(q.jitter_rms_ns,q.ESR_MAPE_median_percent,"o-","DisplayName",mode);
end
nexttile(1); yline(3,"k:"); grid on; ylabel("Median C MAPE (%)");
title("Jitter robustness — 50 seeds, Model A"); legend("Location","best");
nexttile(2); yline(5,"k:"); grid on; xlabel("Jitter RMS (ns)");
ylabel("Median ESR MAPE (%)"); legend("Location","best");
save_verification_figure(fig,figureDir,"fig_v2_09_error_vs_jitter");

%% Edge window robust-region scan.
guards=[.1,.2,.5,1,1.5,2]; widths=[.5,1,1.5,2,3]; points=[3,4,6,8];
windowRows=cell(numel(guards)*numel(widths)*numel(points),12); row=0;
windowMap=nan(numel(guards),numel(widths));
for ig=1:numel(guards)
    for iw=1:numel(widths)
        for ip=1:numel(points)
            cfg=baseCfg; cfg.samplesPerCycle=160; cfg.edgeGuardUs=guards(ig);
            cfg.edgeWindowUs=widths(iw); cfg.edgePointsPerSide=points(ip);
            m=v2_make_measurements(base,p,cfg); edge=v2_edge_estimates(m,p,cfg);
            if isempty(edge), re=NaN; p95=NaN; rmse=NaN; variance=NaN;
            else
                err=100*abs(edge.ESR_raw_Ohm/p.ESR-1); re=median(err);
                p95=prctile(err,95); rmse=median(edge.edge_fit_rmse_V);
                variance=median(edge.edge_fit_variance_V2);
            end
            row=row+1; windowRows(row,:)={guards(ig),widths(iw),points(ip), ...
                height(edge),re,p95,rmse,variance,guards(ig)+widths(iw), ...
                cfg.samplesPerCycle,pass_fail(0,re),"timestamped_linear"};
        end
        q=cell2mat(windowRows(row-numel(points)+1:row,5));
        windowMap(ig,iw)=min(q,[],"omitnan");
    end
end
windowTable=cell2table(windowRows,"VariableNames",["edge_guard_us", ...
    "edge_window_us","edge_points_per_side","valid_edges","ESR_MAPE_percent", ...
    "ESR_p95_MAPE_percent","edge_fit_rmse_V","edge_fit_variance_V2", ...
    "latency_us","samples_per_cycle","status","edge_method"]);
writetable(windowTable,fullfile(tableDir,"table_edge_window_design_v2.csv"));
fig=figure("Visible","off","Color","w"); imagesc(widths,guards,windowMap);
axis xy; colorbar; xlabel("Window width (us)"); ylabel("Guard time (us)");
title("Best ESR MAPE across point-count choices (%) — Model A");
save_verification_figure(fig,figureDir,"fig_v2_10_edge_window_robust_region");

%% ESL + timing/jitter layered DOE.
eslValues=[0,5,10,20,50]; tauValues=[0,50,100,200,500,1000];
jointRows={}; testId=0;
for esl=eslValues
    for tau=tauValues
        cfg=baseCfg; cfg.ESL_H=esl*1e-9; cfg.voltageDelayNs=tau;
        cfg.i1DelayNs=-tau; cfg.i2DelayNs=-tau;
        [ce,re,cest,rest,rej,preC,preR]=estimate_case(base,p,cfg,locked,"TR_TS_LTVKF");
        testId=testId+1; jointRows(end+1,:)={testId,"Model_A","layered",esl,tau,0, ...
            preC,preR,cest,ce,rest,re,rej,pass_fail(ce,re)}; %#ok<AGROW>
    end
end
stress=[20,200,20;20,500,50;50,500,100];
for k=1:size(stress,1)
    for seed=1:20
        cfg=baseCfg; cfg.ESL_H=stress(k,1)*1e-9;
        cfg.voltageDelayNs=stress(k,2); cfg.i1DelayNs=-stress(k,2);
        cfg.i2DelayNs=-stress(k,2); cfg.jitterRmsNs=stress(k,3);
        cfg.jitterMode="independent"; cfg.seed=4000+seed;
        [ce,re,cest,rest,rej,preC,preR]=estimate_case(base,p,cfg,locked,"TR_TS_LTVKF");
        testId=testId+1; jointRows(end+1,:)={testId,"Model_A","Stress_"+k, ...
            stress(k,1),stress(k,2),stress(k,3),preC,preR,cest,ce,rest,re,rej, ...
            pass_fail(ce,re)}; %#ok<AGROW>
    end
end
jointTable=cell2table(jointRows,"VariableNames",["test_id","model_type", ...
    "stress_group","ESL_nH","delay_magnitude_ns","jitter_rms_ns", ...
    "pre_projection_C_F","pre_projection_ESR_Ohm","C_est_F", ...
    "C_MAPE_percent","ESR_est_Ohm","ESR_MAPE_percent", ...
    "edge_fit_rejection_rate","status"]);
writetable(jointTable,fullfile(tableDir,"table_esl_timing_joint_v2.csv"));
layer=jointTable(jointTable.stress_group=="layered",:);
M=reshape(layer.ESR_MAPE_percent,numel(tauValues),numel(eslValues))';
fig=figure("Visible","off","Color","w"); imagesc(tauValues,eslValues,M);
axis xy; colorbar; xlabel("Opposed channel delay magnitude (ns)"); ylabel("ESL (nH)");
title("TR-TS-LTVKF ESR MAPE (%) — Model A");
save_verification_figure(fig,figureDir,"fig_v2_11_esl_timing_joint");

%% Analog front-end bandwidth and group delay.
fc=[100e3,250e3,500e3,1e6,2e6]; frontRows={}; testId=0;
for f=fc
    cfg=baseCfg; cfg.voltageFrontendFcHz=f; cfg.i1FrontendFcHz=f;
    cfg.i2FrontendFcHz=f;
    [ce,re,cest,rest,~,preC,preR]=estimate_case(base,p,cfg,locked,"TR_TS_LTVKF");
    gd=group_delay_first_order(f,p.fs);
    testId=testId+1; frontRows(end+1,:)={testId,"matched",f,f,f,gd,gd,gd, ...
        preC,preR,cest,ce,rest,re,pass_fail(ce,re)}; %#ok<AGROW>
end
for fv=fc
    for fi=[250e3,1e6]
        cfg=baseCfg; cfg.voltageFrontendFcHz=fv; cfg.i1FrontendFcHz=fi;
        cfg.i2FrontendFcHz=fi;
        [ce,re,cest,rest,~,preC,preR]=estimate_case(base,p,cfg,locked,"TR_TS_LTVKF");
        testId=testId+1; frontRows(end+1,:)={testId,"mismatched",fv,fi,fi, ...
            group_delay_first_order(fv,p.fs),group_delay_first_order(fi,p.fs), ...
            group_delay_first_order(fi,p.fs),preC,preR,cest,ce,rest,re, ...
            pass_fail(ce,re)}; %#ok<AGROW>
    end
end
frontTable=cell2table(frontRows,"VariableNames",["test_id","frontend_type", ...
    "voltage_frontend_fc_Hz","i1_frontend_fc_Hz","i2_frontend_fc_Hz", ...
    "voltage_group_delay_at_fs_s","i1_group_delay_at_fs_s", ...
    "i2_group_delay_at_fs_s","pre_projection_C_F", ...
    "pre_projection_ESR_Ohm","C_est_F","C_MAPE_percent","ESR_est_Ohm", ...
    "ESR_MAPE_percent","status"]);
writetable(frontTable,fullfile(tableDir,"table_frontend_delay_v2.csv"));
fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
q=frontTable(frontTable.frontend_type=="matched",:);
nexttile; semilogx(q.voltage_frontend_fc_Hz,q.C_MAPE_percent,"o-");
yline(3,"k:"); grid on; ylabel("C MAPE (%)"); title("Matched analog front-end — Model A");
nexttile; semilogx(q.voltage_frontend_fc_Hz,q.ESR_MAPE_percent,"o-");
yline(5,"k:"); grid on; xlabel("Channel cutoff frequency (Hz)");
ylabel("ESR MAPE (%)"); save_verification_figure(fig,figureDir, ...
    "fig_v2_12_frontend_bandwidth");

%% ADC bits x samples/cycle x 16 sample phases: old vs TR.
bitsList=[12,14,16]; nsList=[8,12,16,24,32]; phases=(0:15)/16;
adcRows=cell(numel(bitsList)*numel(nsList)*numel(phases)*2,15); row=0;
for bits=bitsList
    for Ns=nsList
        for phase=phases
            cfg=baseCfg; cfg.adcBits=bits; cfg.samplesPerCycle=Ns;
            cfg.phaseFraction=phase; cfg.edgeWindowUs=min(6,max(1.5,3*p.Ts/Ns*1e6));
            cfg.edgePointsPerSide=3;
            for method=["old_TS_LTVKF","TR_TS_LTVKF"]
                if method=="old_TS_LTVKF"
                    m=v2_make_measurements(base,p,cfg);
                    old=ts_ltvkf(m,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
                        "measurementVariance",max(locked.RV,(100/(2^bits-1))^2/12), ...
                        "gateThreshold",20));
                    tail=max(1,floor(.8*numel(old.C))):numel(old.C);
                    cest=median(old.C(tail)); rest=median(old.ESR(tail));
                    ce=100*abs(cest/p.C1-1); re=100*abs(rest/p.ESR-1);
                    preC=cest; preR=rest;
                else
                    [ce,re,cest,rest,~,preC,preR]=estimate_case(base,p,cfg,locked,method);
                end
                row=row+1; adcRows(row,:)={bits,100/(2^bits-1),10/(2^bits-1), ...
                    Ns,phase,method,preC,preR,cest,ce,rest,re,pass_fail(ce,re), ...
                    cfg.edgeWindowUs,cfg.edgePointsPerSide};
            end
        end
    end
end
adcTable=cell2table(adcRows,"VariableNames",["adc_bits","voltage_LSB_V", ...
    "current_LSB_A","samples_per_cycle","sample_phase_fraction","method", ...
    "pre_projection_C_F","pre_projection_ESR_Ohm","C_est_F", ...
    "C_MAPE_percent","ESR_est_Ohm","ESR_MAPE_percent", ...
    "status","edge_window_us","edge_points_per_side"]);
writetable(adcTable,fullfile(tableDir,"table_adc_phase_sweep_v2.csv"));
adcAgg=aggregate_adc(adcTable,bitsList,nsList);
fig=figure("Visible","off","Color","w"); hold on;
for bits=bitsList
    q=adcAgg(adcAgg.adc_bits==bits & adcAgg.method=="TR_TS_LTVKF",:);
    plot(q.samples_per_cycle,100*q.pass_fraction,"o-","DisplayName",bits+" bit");
end
yline(95,"k:","95% target"); grid on; xlabel("Samples per switching cycle");
ylabel("Pass fraction across 16 phases (%)"); title("Phase-independent ADC result — Model A");
legend("Location","best"); save_verification_figure(fig,figureDir, ...
    "fig_v2_13_adc_phase_passrate");
fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
q=adcTable(adcTable.adc_bits==16 & adcTable.samples_per_cycle==16,:);
for method=["old_TS_LTVKF","TR_TS_LTVKF"]
    z=q(q.method==method,:); nexttile(1); hold on;
    plot(z.sample_phase_fraction,z.C_MAPE_percent,"o-","DisplayName",method);
    nexttile(2); hold on;
    plot(z.sample_phase_fraction,z.ESR_MAPE_percent,"o-","DisplayName",method);
end
nexttile(1); yline(3,"k:"); grid on; ylabel("C MAPE (%)"); legend;
title("16-bit, 16 samples/cycle phase sweep — Model A");
nexttile(2); yline(5,"k:"); grid on; xlabel("Sampling phase / interval");
ylabel("ESR MAPE (%)"); legend;
save_verification_figure(fig,figureDir,"fig_v2_14_error_vs_sampling_phase");

%% Absolute analog noise in engineering units.
noisePairs=[.5,.1;1,.5;2,1;5,2;10,5;20,10;50,20;50,.1;.5,20];
noiseRows=cell(size(noisePairs,1)*20,12); row=0;
for q=1:size(noisePairs,1)
    for seed=1:20
        cfg=baseCfg; cfg.sigmaVmV=noisePairs(q,1); cfg.sigmaImA=noisePairs(q,2);
        cfg.seed=5000+seed;
        [ce,re,cest,rest,rej,preC,preR]=estimate_case(base,p,cfg,locked,"TR_TS_LTVKF");
        row=row+1; noiseRows(row,:)={noisePairs(q,1),noisePairs(q,2),seed, ...
            preC,preR,cest,ce,rest,re,rej,pass_fail(ce,re),"analog_only"};
    end
end
noiseTable=cell2table(noiseRows,"VariableNames",["sigma_v_mV_RMS", ...
    "sigma_i_mA_RMS","seed","pre_projection_C_F", ...
    "pre_projection_ESR_Ohm","C_est_F","C_MAPE_percent","ESR_est_Ohm", ...
    "ESR_MAPE_percent","edge_fit_rejection_rate","status","noise_type"]);
writetable(noiseTable,fullfile(tableDir,"table_absolute_noise_v2.csv"));
noiseAgg=aggregate_noise(noiseTable,noisePairs);
fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
nexttile; semilogx(noiseAgg.sigma_v_mV_RMS,noiseAgg.C_MAPE_median_percent,"o-");
yline(3,"k:"); grid on; ylabel("Median C MAPE (%)");
title("Absolute analog noise — matched levels, Model A");
nexttile; semilogx(noiseAgg.sigma_v_mV_RMS,noiseAgg.ESR_MAPE_median_percent,"o-");
yline(5,"k:"); grid on; xlabel("Voltage noise (mV RMS)");
ylabel("Median ESR MAPE (%)");
save_verification_figure(fig,figureDir,"fig_v2_15_absolute_noise");

summary=struct("edgeRows",height(edgeComparison),"delayRows",height(channelDelay), ...
    "jitterRows",height(jitterTable),"windowRows",height(windowTable), ...
    "jointRows",height(jointTable),"frontendRows",height(frontTable), ...
    "adcRows",height(adcTable),"noiseRows",height(noiseTable), ...
    "randomDelayPassFraction",mean(channelDelay.status( ...
        channelDelay.test_group=="random_uniform")=="PASS"), ...
    "adc95Configurations",sum(adcAgg.pass_fraction>=.95 & ...
        adcAgg.method=="TR_TS_LTVKF"));
save(fullfile(rawDir,"timing_doe_summary.mat"),"summary","jitterAgg", ...
    "adcAgg","noiseAgg");
fprintf('v2 timing DOE: %d delay, %d jitter, %d ADC rows; %d TR ADC configs >=95%% phase pass.\n', ...
    height(channelDelay),height(jitterTable),height(adcTable),summary.adc95Configurations);
end

function row=edge_row(id,offset,method,edge,charge,p,cfg)
if isempty(edge), rest=NaN; re=NaN; p95=NaN; rmse=NaN; variance=NaN;
else
    rest=median(edge.ESR_raw_Ohm,"omitnan"); err=100*abs(edge.ESR_raw_Ohm/p.ESR-1);
    re=median(err,"omitnan"); p95=prctile(err,95); rmse=median(edge.edge_fit_rmse_V);
    variance=median(edge.edge_fit_variance_V2);
end
cest=median(charge.C_raw_F,"omitnan"); ce=100*abs(cest/p.C1-1);
row={id,offset,method,cest,ce,rest,re,p95,rmse,variance,height(edge), ...
    cfg.edgeGuardUs,cfg.edgeWindowUs};
end

function plot_edge_example(q,p,figureDir)
if isempty(q), return; end
edge=q.edge(round(height(q.edge)/2),:); te=edge.edge_time_s;
idx=q.m.t>=te-2.5e-6 & q.m.t<=te+2.5e-6;
fig=figure("Visible","off","Color","w"); plot(1e6*(q.m.t(idx)-te),q.m.vT(idx), ...
    "o-","LineWidth",1); hold on; scatter(0,edge.v_minus_V,65,"filled");
scatter(0,edge.v_plus_V,65,"filled"); xline(0,"k--"); grid on;
xlabel("Time relative to reported PWM edge (us)"); ylabel("v_T (V)");
title("Timestamped linear edge fit example — Model A, 200 ns timestamp error");
legend("ADC samples","pre-edge extrapolation","post-edge extrapolation", ...
    "reported edge","Location","best");
text(.02,edge.v_minus_V,sprintf('  true ESR %.0f mOhm',1e3*p.ESR));
save_verification_figure(fig,figureDir,"fig_v2_04_edge_fit_example");
end

function cfg=set_delay(cfg,channel,value)
cfg.(channel+"DelayNs")=value;
end

function value=get_delay(cfg,channel)
name=channel+"DelayNs"; if isfield(cfg,name), value=cfg.(name); else, value=0; end
end

function [ce,re,cest,rest,rejection,preCest,preRest]=estimate_case(base,p,cfg,locked,method)
cfg.edgeMethod=method;
if method=="TR_TS_LTVKF"
    cfg.edgeMethod="timestamped_linear"; m=v2_make_measurements(base,p,cfg);
    r=tr_ts_ltvkf(m,p,cfg,locked); cest=r.Cfinal; rest=r.ESRfinal;
    ce=r.CMape; re=r.ESRMape;
    preCest=r.CpreFinal; preRest=r.ESRpreFinal;
    rejection=1-mean(r.gateR(isfinite(r.nisR)));
else
    m=v2_make_measurements(base,p,cfg); edge=v2_edge_estimates(m,p,cfg);
    charge=v2_charge_estimates(m,p,cfg);
    cest=median(charge.C_raw_F,"omitnan"); rest=median(edge.ESR_raw_Ohm,"omitnan");
    ce=100*abs(cest/p.C1-1); re=100*abs(rest/p.ESR-1); rejection=0;
    preCest=cest; preRest=rest;
end
if isempty(rejection)||isnan(rejection), rejection=1; end
end

function state=pass_fail(ce,re)
if isfinite(ce)&&isfinite(re)&&ce<3&&re<5, state="PASS"; else, state="FAIL"; end
end

function T=aggregate_jitter(raw,modes,levels)
rows=cell(numel(modes)*numel(levels),10); row=0;
for mode=modes
    for jt=levels
        q=raw(raw.jitter_mode==mode & raw.jitter_rms_ns==jt,:); row=row+1;
        rows(row,:)={mode,jt,median(q.C_MAPE_percent),prctile(q.C_MAPE_percent,95), ...
            median(q.ESR_MAPE_percent),prctile(q.ESR_MAPE_percent,95), ...
            mean(q.status=="FAIL"),median(q.edge_fit_rejection_rate),min(q.C_MAPE_percent), ...
            max(q.ESR_MAPE_percent)};
    end
end
T=cell2table(rows,"VariableNames",["jitter_mode","jitter_rms_ns", ...
    "C_MAPE_median_percent","C_MAPE_p95_percent","ESR_MAPE_median_percent", ...
    "ESR_MAPE_p95_percent","failure_rate","edge_fit_rejection_rate", ...
    "C_MAPE_min_percent","ESR_MAPE_max_percent"]);
end

function gd=group_delay_first_order(fc,f)
tau=1/(2*pi*fc); gd=tau/(1+(f/fc)^2);
end

function T=aggregate_adc(raw,bitsList,nsList)
rows=cell(numel(bitsList)*numel(nsList)*2,9); row=0;
for bits=bitsList
    for Ns=nsList
        for method=["old_TS_LTVKF","TR_TS_LTVKF"]
            q=raw(raw.adc_bits==bits & raw.samples_per_cycle==Ns & raw.method==method,:);
            row=row+1; rows(row,:)={bits,Ns,method,mean(q.status=="PASS"), ...
                median(q.C_MAPE_percent),max(q.C_MAPE_percent), ...
                median(q.ESR_MAPE_percent),max(q.ESR_MAPE_percent), ...
                prctile(q.ESR_MAPE_percent,95)};
        end
    end
end
T=cell2table(rows,"VariableNames",["adc_bits","samples_per_cycle","method", ...
    "pass_fraction","C_MAPE_median_percent","C_MAPE_worst_percent", ...
    "ESR_MAPE_median_percent","ESR_MAPE_worst_percent", ...
    "ESR_MAPE_p95_percent"]);
end

function T=aggregate_noise(raw,pairs)
rows=cell(size(pairs,1),8);
for k=1:size(pairs,1)
    q=raw(raw.sigma_v_mV_RMS==pairs(k,1) & raw.sigma_i_mA_RMS==pairs(k,2),:);
    rows(k,:)={pairs(k,1),pairs(k,2),median(q.C_MAPE_percent), ...
        prctile(q.C_MAPE_percent,95),median(q.ESR_MAPE_percent), ...
        prctile(q.ESR_MAPE_percent,95),mean(q.status=="FAIL"), ...
        median(q.edge_fit_rejection_rate)};
end
T=cell2table(rows,"VariableNames",["sigma_v_mV_RMS","sigma_i_mA_RMS", ...
    "C_MAPE_median_percent","C_MAPE_p95_percent","ESR_MAPE_median_percent", ...
    "ESR_MAPE_p95_percent","failure_rate","edge_fit_rejection_rate"]);
end
