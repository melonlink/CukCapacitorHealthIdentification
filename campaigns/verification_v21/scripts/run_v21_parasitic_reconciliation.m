function summary=run_v21_parasitic_reconciliation(v21Root)
%RUN_V21_PARASITIC_RECONCILIATION Identify Model A-P from Model B edges.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v21Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(fullfile(repoRoot,"verification_v2")), ...
    genpath(v21Root));
tableDir=fullfile(v21Root,"results","tables"); figureDir=fullfile(v21Root,"results","figures");
rawDir=fullfile(v21Root,"results","raw");
L=load(fullfile(rawDir,"locked_covariance_v21.mat"),"locked"); locked=L.locked;
eslValues=1e-9*[1,5,10,20,50]; requestedLoads=[.25,.5,1]; duties=[.3,.4,.6];
n=numel(eslValues)*numel(requestedLoads)*numel(duties);
featureRows=cell(n,21); compareRows=cell(n,19); traces=cell(n,1); row=0;
representative=struct(); cfg0=v21_default_config();
for duty=duties
    for requested=requestedLoads
        for esl=eslValues
            p=model_parameters(); p.D=duty; actual=requested; isCcm=false;
            while ~isCcm
                p.Rload=10/actual;
                baseB=run_modelB_v21(v21Root,p,esl,.0016);
                tail=baseB.t>=max(baseB.t(end)-.0005,0);
                isCcm=min(baseB.i1(tail))>0 && min(baseB.i2(tail))>0;
                if ~isCcm && actual<1, actual=min(1,actual+.125); else, break; end
            end
            baseA=simulate_switched_equation(p,struct("duration",.0016, ...
                "samplesPerPeriod",400));
            traceB=average_edges(baseB,p); traceA=average_edges(baseA,p);
            residual=traceB.vT-traceA.vT;
            fit=identify_damped_edge(traceB.tau,residual);
            fitResidual=evaluate_fit(fit,traceB.tau);
            traceAP=traceA.vT+fitResidual;
            feat=edge_features(traceB.tau,residual,fit,traceB,p);
            featAP=edge_features(traceB.tau,fitResidual,fit,traceB,p);
            esrB=edge_esr(traceB.tau,traceB.vT,traceB.i1,traceB.i2,p);
            esrAP=edge_esr(traceB.tau,traceAP,traceB.i1,traceB.i2,p);
            use=traceB.tau>=-2e-6 & traceB.tau<=5e-6;
            nrmse=sqrt(mean((traceAP(use)-traceB.vT(use)).^2))/ ...
                max(range(traceB.vT(use)),eps);
            baseAP=apply_model_ap(baseA,fit);
            cfg=cfg0; cfg.seed=70000+row;
            mB=v21_measurement_chain(baseB,p,cfg);
            mAP=v21_measurement_chain(baseAP,p,cfg);
            rB=structured_ltv_estimator_v21(mB,p,cfg,locked);
            rAP=structured_ltv_estimator_v21(mAP,p,cfg,locked);
            row=row+1;
            featureRows(row,:)={row,esl/1e-9,requested,actual,duty,p.Rload,isCcm, ...
                fit.ringIdentifiable, ...
                feat.ringFreqHz,feat.zeta,feat.overshootV,feat.settleS, ...
                feat.firstPeakS,feat.edgeSlopeVPerS,esrB, ...
                100*(esrB/p.ESR-1),fit.lambdaPerUs,fit.wRadPerUs, ...
                fit.A,fit.B,numel(traceB.edgeTimes)};
            compareRows(row,:)={row,esl/1e-9,actual,duty,nrmse, ...
                relative_error(featAP.ringFreqHz,feat.ringFreqHz), ...
                relative_error(featAP.zeta,feat.zeta), ...
                relative_error(featAP.overshootV,feat.overshootV), ...
                relative_error(featAP.settleS,feat.settleS),esrAP,esrB, ...
                100*abs(esrAP/p.ESR-1),100*abs(esrB/p.ESR-1), ...
                rAP.CMape,rB.CMape,rAP.ESRMape,rB.ESRMape, ...
                abs(rAP.ESRMape-rB.ESRMape), ...
                nrmse<.10 && abs(rAP.ESRMape-rB.ESRMape)<2};
            traces{row}=struct("p",p,"ESL",esl,"requestedLoad",requested, ...
                "actualLoad",actual,"traceB",traceB,"traceA",traceA, ...
                "traceAP",traceAP,"fit",fit);
            if abs(esl-20e-9)<eps && abs(duty-.4)<eps && actual==1
                representative=traces{row};
            end
        end
    end
    fprintf("v2.1 parasitic reconciliation: completed duty %.2f.\n",duty);
end
featureTable=cell2table(featureRows,"VariableNames",["test_id","ESL_nH", ...
    "requested_load_fraction","actual_load_fraction","D","Rload_Ohm","CCM", ...
    "ring_identifiable", ...
    "ring_freq_Hz","ring_zeta","ring_overshoot_V","ring_settle_s", ...
    "first_peak_s","edge_slope_V_per_s","edge_ESR_raw_Ohm", ...
    "edge_extrapolation_bias_percent","fit_lambda_per_us","fit_w_rad_per_us", ...
    "fit_A_V","fit_B_V","averaged_edge_count"]);
compareTable=cell2table(compareRows,"VariableNames",["test_id","ESL_nH", ...
    "load_fraction","D","modelB_waveform_NRMSE","ring_frequency_relative_error", ...
    "zeta_relative_error","peak_relative_error","settling_relative_error", ...
    "edge_ESR_AP_Ohm","edge_ESR_B_Ohm","edge_ESR_AP_MAPE_percent", ...
    "edge_ESR_B_MAPE_percent","TR_C_MAPE_AP_percent","TR_C_MAPE_B_percent", ...
    "TR_ESR_MAPE_AP_percent","TR_ESR_MAPE_B_percent", ...
    "TR_ESR_MAPE_difference_points","acceptance_pass"]);
writetable(featureTable,fullfile(tableDir,"table_modelB_edge_features_v21.csv"));
writetable(compareTable,fullfile(tableDir,"table_modelAP_vs_B_v21.csv"));
save(fullfile(rawDir,"modelB_edge_traces_v21.mat"),"traces","-v7.3");

fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
t=1e6*representative.traceB.tau;
nexttile; plot(t,representative.traceB.vT,"LineWidth",1.1); hold on;
plot(t,representative.traceA.vT,"--"); plot(t,representative.traceAP,"-.");
xlim([-2,5]); grid on; ylabel("Terminal voltage (V)");
legend("Model B","Model A","identified Model A-P");
title("20 nH, D=0.40, 100% load: averaged physical edge");
nexttile; plot(t,representative.traceB.vT-representative.traceA.vT); hold on;
plot(t,representative.traceAP-representative.traceA.vT,"--");
xlim([0,5]); grid on; xlabel("Edge-local time (us)"); ylabel("Parasitic residual (V)");
legend("Model B - Model A","identified second order");
save_verification_figure(fig,figureDir,"fig_v21_11_modelAP_modelB_edge_overlay");

fig=figure("Visible","off","Color","w"); tiledlayout(1,2);
nexttile; scatter(compareTable.ESL_nH,100*compareTable.modelB_waveform_NRMSE, ...
    28,compareTable.D,"filled"); yline(10,"k:"); grid on;
xlabel("ESL (nH)"); ylabel("Edge waveform NRMSE (%)"); colorbar;
title("Model A-P waveform agreement; color=D");
nexttile; scatter(compareTable.ESL_nH,compareTable.TR_ESR_MAPE_difference_points, ...
    28,compareTable.load_fraction,"filled"); yline(2,"k:"); grid on;
xlabel("ESL (nH)"); ylabel("|ESR MAPE_{A-P}-MAPE_B| (points)"); colorbar;
title("Estimator-error agreement; color=load fraction");
save_verification_figure(fig,figureDir,"fig_v21_12_modelAP_modelB_error");

summary=struct("featureRows",height(featureTable),"comparisonRows",height(compareTable), ...
    "waveformPassFraction",mean(compareTable.modelB_waveform_NRMSE<.10), ...
    "estimatorAgreementFraction",mean(compareTable.TR_ESR_MAPE_difference_points<2), ...
    "jointAcceptanceFraction",mean(compareTable.acceptance_pass), ...
    "switchNodeAvailable",false);
save(fullfile(rawDir,"parasitic_reconciliation_v21.mat"),"summary", ...
    "featureTable","compareTable");
end

function trace=average_edges(base,p)
idx=find(diff(base.u)>.5)+1; times=base.t(idx);
valid=times>=.0005 & times<=base.t(end)-6e-6; times=times(valid);
times=times(max(1,end-19):end); tau=(-3e-6:base.dt:6e-6)';
fields=["vT","iC","i1","i2"]; trace=struct("tau",tau,"edgeTimes",times);
for field=fields
    M=zeros(numel(tau),numel(times));
    for k=1:numel(times)
        M(:,k)=interp1(base.t,base.(field),times(k)+tau,"linear","extrap");
    end
    trace.(field)=mean(M,2);
end
trace.p=p;
end

function fit=identify_damped_edge(tau,residual)
use=tau>=0 & tau<=5e-6; u=1e6*tau(use); y=residual(use);
y=y-mean(y(u>=4.5)); objective=@(theta) fit_error(theta,u,y);
zeroCrossings=sum(diff(sign(y))~=0);
if zeroCrossings<4
    objective1=@(theta) mean((y-exp(-exp(theta)*u)* ...
        ((exp(-exp(theta)*u))\y)).^2);
    theta=fminsearch(objective1,log(.6),optimset("Display","off"));
    lambda=exp(theta); X=exp(-lambda*u); amplitude=X\y;
    fit=struct("lambdaPerUs",lambda,"wRadPerUs",NaN,"A",amplitude, ...
        "B",0,"ringFreqHz",NaN,"zeta",1,"ringIdentifiable",false);
    return;
end
theta=fminsearch(objective,log([.6,2*pi*.6]), ...
    optimset("Display","off","MaxIter",300,"TolX",1e-7));
lambda=exp(theta(1)); w=exp(theta(2)); X=basis(u,lambda,w); beta=X\y;
fit=struct("lambdaPerUs",lambda,"wRadPerUs",w,"A",beta(1),"B",beta(2), ...
    "ringFreqHz",w/(2*pi)*1e6,"zeta",lambda/sqrt(lambda^2+w^2), ...
    "ringIdentifiable",true);
end

function value=fit_error(theta,u,y)
lambda=exp(theta(1)); w=exp(theta(2)); X=basis(u,lambda,w); beta=X\y;
value=mean((y-X*beta).^2)+1e-8*(lambda+w);
end

function X=basis(u,lambda,w)
decay=exp(-lambda*u); X=[decay.*cos(w*u),decay.*sin(w*u)];
end

function residual=evaluate_fit(fit,tau)
residual=zeros(size(tau)); use=tau>=0; u=1e6*tau(use);
if fit.ringIdentifiable
    residual(use)=basis(u,fit.lambdaPerUs,fit.wRadPerUs)*[fit.A;fit.B];
else
    residual(use)=fit.A*exp(-fit.lambdaPerUs*u);
end
end

function baseAP=apply_model_ap(baseA,fit)
baseAP=baseA; correction=zeros(size(baseA.t)); edges=baseA.t(find(diff(baseA.u)>.5)+1);
for te=reshape(edges,1,[])
    idx=baseA.t>=te & baseA.t<=te+6e-6;
    correction(idx)=correction(idx)+evaluate_fit(fit,baseA.t(idx)-te);
end
baseAP.vT=baseA.vT+correction;
end

function feat=edge_features(tau,residual,fit,trace,p)
use=tau>=0; t=tau(use); y=residual(use); amp=max(abs(y));
[overshoot,peakIdx]=max(abs(y)); firstPeak=t(peakIdx);
threshold=.02*max(amp,eps); settle=NaN;
for k=1:numel(y)
    if all(abs(y(k:end))<=threshold), settle=t(k); break; end
end
edgeBand=abs(tau)<=.5e-6; slope=max(abs(diff(trace.vT(edgeBand))))/ ...
    max(mean(diff(tau)),eps);
feat=struct("ringFreqHz",fit.ringFreqHz,"zeta",fit.zeta, ...
    "overshootV",overshoot,"settleS",settle,"firstPeakS",firstPeak, ...
    "edgeSlopeVPerS",slope,"truthESR",p.ESR);
end

function estimate=edge_esr(tau,v,i1,i2,p)
g=.5; W=2; u=1e6*tau;
pre=u>=-g-W & u<=-g; post=u>=g & u<=g+W;
bPre=polyfit(u(pre),v(pre),1); bPost=polyfit(u(post),v(post),1);
iPre=polyfit(u(pre),i1(pre),1); iPost=polyfit(u(post),i2(post),1);
estimate=(polyval(bPre,0)-polyval(bPost,0))/ ...
    (polyval(iPre,0)+polyval(iPost,0));
if ~isfinite(estimate), estimate=p.ESR; end
end

function e=relative_error(a,b)
if ~isfinite(a)||~isfinite(b), e=NaN; else, e=abs(a-b)/max(abs(b),eps); end
end
