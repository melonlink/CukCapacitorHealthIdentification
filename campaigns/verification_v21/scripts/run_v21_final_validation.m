function summary=run_v21_final_validation(v21Root)
%RUN_V21_FINAL_VALIDATION Timing boundary, blind health cases and CRLB closure.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v21Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(fullfile(repoRoot,"verification_v2")), ...
    genpath(v21Root));
tableDir=fullfile(v21Root,"results","tables"); figureDir=fullfile(v21Root,"results","figures");
rawDir=fullfile(v21Root,"results","raw");
L=load(fullfile(rawDir,"locked_covariance_v21.mat"),"locked"); locked=L.locked;
cfg0=v21_default_config();

%% Model B timing pass probability and 95% boundary.
delays=[0,50,100,150,200,250,300,400,500]; esls=1e-9*[1,10,20];
jitters=[0,20,50]; nSeed=20;
opNames=["nominal","high_load","high_D_CCM","low_CCM_margin"];
opD=[.4,.4,.6,.4]; opR=[10,5,7.5,35];
nRows=numel(delays)*numel(esls)*numel(jitters)*numel(opNames);
rows=cell(nRows,17); row=0; modelBases=cell(numel(esls),numel(opNames));
for ei=1:numel(esls)
    for oi=1:numel(opNames)
        p=model_parameters(); p.D=opD(oi); p.Rload=opR(oi);
        modelBases{ei,oi}=run_modelB_v21(v21Root,p,esls(ei),.0025);
        for jitter=jitters
            for delay=delays
                cErr=zeros(nSeed,1); rErr=cErr; pass=false(nSeed,1);
                nees=cErr; coverC=false(nSeed,1); coverR=coverC;
                for s=1:nSeed
                    cfg=cfg0; cfg.voltageDelayNs=(-1)^s*delay;
                    cfg.jitterRmsNs=jitter; cfg.computeNeesHistory=false;
                    cfg.seed=90000+10000*ei+1000*oi+100*s+delay;
                    m=v21_measurement_chain(modelBases{ei,oi},p,cfg);
                    r=structured_ltv_estimator_v21(m,p,cfg,locked);
                    cErr(s)=r.CMape; rErr(s)=r.ESRMape;
                    pass(s)=r.CMape<3 && r.ESRMape<5;
                    nees(s)=r.neesParam(end); coverC(s)=r.CI_C_contains_true;
                    coverR(s)=r.CI_ESR_contains_true;
                end
                row=row+1; rows(row,:)={opNames(oi),p.Vin,p.D,p.Rload, ...
                    esls(ei)/1e-9,jitter,delay,nSeed,mean(pass),mean(cErr), ...
                    prctile(cErr,95),mean(rErr),prctile(rErr,95),mean(nees), ...
                    mean(coverC),mean(coverR),mean(pass)>=.95};
            end
        end
    end
    fprintf("v2.1 timing boundary: completed ESL %.3g nH.\n",esls(ei)/1e-9);
end
timingTable=cell2table(rows,"VariableNames",["operating_case","Vin_V","D", ...
    "Rload_Ohm","ESL_nH","jitter_rms_ns","absolute_voltage_delay_ns", ...
    "seed_count","pass_probability","C_MAPE_mean_percent","C_MAPE_p95_percent", ...
    "ESR_MAPE_mean_percent","ESR_MAPE_p95_percent","NEES_param_mean", ...
    "CI_C_95_coverage","CI_ESR_95_coverage","meets_95_percent_boundary"]);
groups=unique(timingTable(:,["operating_case","ESL_nH","jitter_rms_ns"]),"rows");
boundary=zeros(height(groups),1);
for k=1:height(groups)
    z=timingTable(timingTable.operating_case==groups.operating_case(k) & ...
        timingTable.ESL_nH==groups.ESL_nH(k) & ...
        timingTable.jitter_rms_ns==groups.jitter_rms_ns(k),:);
    ok=z.absolute_voltage_delay_ns(z.pass_probability>=.95);
    if isempty(ok), boundary(k)=NaN; else, boundary(k)=max(ok); end
end
boundaryTable=[groups,table(boundary,VariableNames="delay_95_percent_boundary_ns")];
writetable(timingTable,fullfile(tableDir,"table_timing_boundary_v21.csv"));
writetable(boundaryTable,fullfile(tableDir,"table_timing_boundary_summary_v21.csv"));
fig=figure("Visible","off","Color","w");
colors=lines(numel(esls));
for ei=1:numel(esls)
    z=timingTable(timingTable.operating_case=="nominal" & ...
        timingTable.ESL_nH==esls(ei)/1e-9 & timingTable.jitter_rms_ns==20,:);
    plot(z.absolute_voltage_delay_ns,100*z.pass_probability,"o-", ...
        "Color",colors(ei,:),"DisplayName",compose("ESL %.0f nH",esls(ei)/1e-9)); hold on;
end
yline(95,"k:"); ylim([0,105]); grid on; xlabel("|voltage-channel delay| (ns)");
ylabel("Joint C/ESR pass probability (%)"); legend("Location","southwest");
title("Model B timing boundary, 20 ns RMS jitter, random delay sign");
save_verification_figure(fig,figureDir,"fig_v21_13_timing_pass_probability");

%% 36 stratified blind Model A health/operating cases.
vins=[19.2,24,28.8]; duties=[.3,.4,.55,.65]; loadRequests=[.25,.5,1];
cFactors=[.8,.9,1]; rFactors=[1,1.5,2]; blindRows=cell(36,24); id=0;
for vin=vins
    for duty=duties
        for requested=loadRequests
            id=id+1; actual=requested; pPlant=model_parameters();
            pPlant.Vin=vin; pPlant.D=duty;
            pPlant.C1=100e-6*cFactors(mod(id-1,3)+1);
            pPlant.ESR=50e-3*rFactors(mod(floor((id-1)/3),3)+1);
            while true
                pPlant.Rload=10/actual;
                base=simulate_switched_equation(pPlant,struct("duration",.003, ...
                    "samplesPerPeriod",400));
                tail=base.t>=.002; isCcm=min(base.i1(tail))>0 && min(base.i2(tail))>0;
                if isCcm || actual>=1, break; end
                actual=min(1,actual+.125);
            end
            pNom=pPlant; pNom.C1=100e-6; pNom.ESR=50e-3;
            cfg=cfg0; cfg.seed=120000+id; cfg.computeNeesHistory=false;
            m=v21_measurement_chain(base,pNom,cfg);
            r=structured_ltv_estimator_v21(m,pNom,cfg,locked);
            if isempty(r.edges), pre=0; post=0; else
                pre=min(r.edges.pre_points); post=min(r.edges.post_points); end
            samplePass=pre>=3 && post>=3;
            statPass=r.neesParam(end)<chi2inv(.995,2);
            jointPass=r.CMape<3 && r.ESRMape<5 && samplePass && statPass;
            blindRows(id,:)={id,vin,duty,requested,actual,pPlant.Rload,isCcm, ...
                pPlant.C1,pPlant.ESR,r.Cfinal,r.ESRfinal,r.CMape,r.ESRMape, ...
                pre,post,samplePass,r.neesFull(end),r.neesParam(end), ...
                r.CI_C_contains_true,r.CI_ESR_contains_true,m.aliasRatioWorstdB, ...
                m.currentSaturationFraction,jointPass,"locked, no blind retuning"};
        end
    end
end
blindTable=cell2table(blindRows,"VariableNames",["test_id","Vin_V","D", ...
    "requested_load_fraction","actual_load_fraction","Rload_Ohm","CCM", ...
    "C_true_F","ESR_true_Ohm","C_est_F","ESR_est_Ohm","C_MAPE_percent", ...
    "ESR_MAPE_percent","points_available_pre","points_available_post", ...
    "sampling_geometry_feasible","NEES_full","NEES_param", ...
    "CI_C_contains_true","CI_ESR_contains_true","alias_ratio_dB", ...
    "current_saturation_fraction","joint_pass","notes"]);
writetable(blindTable,fullfile(tableDir,"table_blind_validation_v21.csv"));

%% Fisher information / CRLB one-factor sensitivity with 20 seeds per point.
cases=crlb_cases(); crlbRows=cell(height(cases),19);
for c=1:height(cases)
    p=model_parameters(); p.D=cases.D(c); p.Rload=cases.Rload_Ohm(c);
    base=simulate_switched_equation(p,struct("duration",.003,"samplesPerPeriod",400));
    cfg=cfg0; cfg.fsAdcHz=cases.fs_adc_Hz(c); cfg.afeFcVHz=cases.afe_fc_v_Hz(c);
    cfg.computeNeesHistory=false;
    cfg.voltageDelayNs=cases.voltage_delay_ns(c);
    cEst=zeros(20,1); rEst=cEst; infos=zeros(20,2);
    for s=1:20
        cfg.seed=140000+100*c+s; m=v21_measurement_chain(base,p,cfg);
        r=structured_ltv_estimator_v21(m,p,cfg,locked);
        cEst(s)=r.Cfinal; rEst(s)=r.ESRfinal;
        infos(s,:)=parameter_information(m,p,r,locked);
    end
    infoC=median(infos(:,1)); infoR=median(infos(:,2));
    crlbC=p.C1^2/max(infoC,eps); crlbR=1/max(infoR,eps);
    empiricalVarC=var(cEst,1); empiricalVarR=var(rEst,1);
    rmseC=sqrt(mean((cEst-p.C1).^2)); rmseR=sqrt(mean((rEst-p.ESR).^2));
    crlbRows(c,:)={cases.dimension(c),cases.level(c),p.D,p.Rload, ...
        cfg.fsAdcHz,cfg.afeFcVHz,cfg.voltageDelayNs,infoC,infoR,crlbC,crlbR, ...
        empiricalVarC,empiricalVarR,rmseC,rmseR,rmseC/sqrt(crlbC), ...
        rmseR/sqrt(crlbR),mean(100*abs(cEst/p.C1-1)), ...
        mean(100*abs(rEst/p.ESR-1))};
end
crlbTable=cell2table(crlbRows,"VariableNames",["sensitivity_dimension", ...
    "level","D","Rload_Ohm","fs_adc_Hz","afe_fc_v_Hz","voltage_delay_ns", ...
    "C_information","ESR_information","CRLB_C","CRLB_ESR", ...
    "empirical_variance_C","empirical_variance_ESR","RMSE_C","RMSE_ESR", ...
    "rmse_to_crlb_C","rmse_to_crlb_ESR","C_MAPE_mean_percent", ...
    "ESR_MAPE_mean_percent"]);
writetable(crlbTable,fullfile(tableDir,"table_CRLB_v21.csv"));
fig=figure("Visible","off","Color","w"); tiledlayout(1,2);
nexttile; loglog(sqrt(crlbTable.CRLB_C),sqrt(crlbTable.empirical_variance_C),"o");
hold on; lim=xlim; plot(lim,lim,"k:"); grid on; axis square;
xlabel("Predicted C sigma (F)"); ylabel("Empirical C sigma (F)"); title("C: empirical vs CRLB");
nexttile; loglog(sqrt(crlbTable.CRLB_ESR),sqrt(crlbTable.empirical_variance_ESR),"o");
hold on; lim=xlim; plot(lim,lim,"k:"); grid on; axis square;
xlabel("Predicted ESR sigma (Ohm)"); ylabel("Empirical ESR sigma (Ohm)");
title("ESR: empirical vs CRLB");
save_verification_figure(fig,figureDir,"fig_v21_14_empirical_vs_CRLB");

summary=struct("timingRows",height(timingTable),"minimumBoundaryNs", ...
    min(boundaryTable.delay_95_percent_boundary_ns,[],"omitnan"), ...
    "medianBoundaryNs",median(boundaryTable.delay_95_percent_boundary_ns,"omitnan"), ...
    "blindRows",height(blindTable),"blindPassFraction",mean(blindTable.joint_pass), ...
    "crlbRows",height(crlbTable));
save(fullfile(rawDir,"final_validation_v21.mat"),"summary","timingTable", ...
    "boundaryTable","blindTable","crlbTable","-v7.3");
end

function cases=crlb_cases()
dimension=[repmat("load",3,1);repmat("duty",3,1);repmat("adc",3,1); ...
    repmat("afe",3,1);repmat("timing",3,1)];
level=["25%";"50%";"100%";"D=.30";"D=.40";"D=.60"; ...
    "1.6M";"2.5M";"5M";"1.5M";"2M";"3M";"0ns";"100ns";"200ns"];
D=[.4;.4;.4;.3;.4;.6;.4;.4;.4;.4;.4;.4;.4;.4;.4];
Rload=[40;20;10;10;10;7.5;10;10;10;10;10;10;10;10;10];
fs=1e6*[5;5;5;5;5;5;1.6;2.5;5;5;5;5;5;5;5];
afe=1e6*[2;2;2;2;2;2;2;2;2;1.5;2;3;2;2;2];
delay=[0;0;0;0;0;0;0;0;0;0;0;0;0;100;200];
cases=table(dimension,level,D,Rload,fs,afe,delay,VariableNames= ...
    ["dimension","level","D","Rload_Ohm","fs_adc_Hz","afe_fc_v_Hz", ...
    "voltage_delay_ns"]);
end

function info=parameter_information(m,p,r,locked)
Cb=p.C1; Prr=r.P(3,3,end); alpha=Cb/r.Cfinal; Ri=m.sigmaI^2; Rv=m.sigmaV^2;
infoC=0;
for k=1:height(r.charges)
    q=r.charges.q_C(k); dI=r.charges.delta_iC_A(k);
    idx=r.charges.sample_indices{k}; Rq=max(numel(idx)-1,1)* ...
        mean(diff(m.t(idx)))^2*Ri;
    RC=locked.chargeVarianceScale*(2*Rv+dI^2*Prr+ ...
        r.ESRfinal^2*2*Ri+(alpha/Cb)^2*Rq);
    infoC=infoC+(q/Cb)^2/max(RC,locked.RCFloor);
end
infoR=0;
for k=1:height(r.edges)
    te=r.edges.edge_time_s(k);
    pre=r.edges.pre_first_index(k):r.edges.pre_last_index(k);
    post=r.edges.post_first_index(k):r.edges.post_last_index(k);
    factor=intercept_factor(m.t(pre)-te)+intercept_factor(m.t(post)-te);
    knownV=m.sigmaV^2*factor; knownI=r.ESRfinal^2*m.sigmaI^2*factor;
    curvature=max(r.edges.edge_fit_variance_V2(k)-knownV,0);
    RR=max(locked.RRFloor,knownV+knownI+locked.edgeVarianceScale*curvature);
    H=locked.edgeGainCorrection*r.edges.i_sum_A(k);
    infoR=infoR+H^2/RR;
end
info=[infoC,infoR];
end

function factor=intercept_factor(t)
t=1e6*t(:); X=[ones(numel(t),1),t]; factor=[1,0]*pinv(X'*X)*[1;0];
end
