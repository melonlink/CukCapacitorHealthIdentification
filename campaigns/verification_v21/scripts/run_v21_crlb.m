function summary=run_v21_crlb(v21Root)
%RUN_V21_CRLB Standalone CRLB sensitivity after timing/blind validation.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v21Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(fullfile(repoRoot,"verification_v2")), ...
    genpath(v21Root));
tableDir=fullfile(v21Root,"results","tables"); figureDir=fullfile(v21Root,"results","figures");
rawDir=fullfile(v21Root,"results","raw");
L=load(fullfile(rawDir,"locked_covariance_v21.mat"),"locked"); locked=L.locked;
cfg0=v21_default_config(); cases=crlb_cases(); crlbRows=cell(height(cases),19);
for c=1:height(cases)
    p=model_parameters(); p.D=cases.D(c); p.Rload=cases.Rload_Ohm(c);
    base=simulate_switched_equation(p,struct("duration",.003,"samplesPerPeriod",400));
    cfg=cfg0; cfg.fsAdcHz=cases.fs_adc_Hz(c); cfg.afeFcVHz=cases.afe_fc_v_Hz(c);
    cfg.voltageDelayNs=cases.voltage_delay_ns(c); cfg.computeNeesHistory=false;
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
    fprintf("v2.1 CRLB: completed %s/%s.\n",cases.dimension(c),cases.level(c));
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
summary=struct("crlbRows",height(crlbTable), ...
    "medianRmseRatioC",median(crlbTable.rmse_to_crlb_C,"omitnan"), ...
    "medianRmseRatioESR",median(crlbTable.rmse_to_crlb_ESR,"omitnan"));
save(fullfile(rawDir,"crlb_v21.mat"),"summary","crlbTable","-v7.3");
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
    idx=r.charges.sample_indices{k};
    Rq=max(numel(idx)-1,1)*mean(diff(m.t(idx)))^2*Ri;
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
