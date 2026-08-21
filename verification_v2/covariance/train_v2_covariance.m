function [locked,trainingTable]=train_v2_covariance(v2Root)
%TRAIN_V2_COVARIANCE Determine one locked covariance rule from three sets.

if nargin<1, v2Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v2Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(v2Root));
sets={"nominal",24,.4,0,0;"high_D",28.8,.65,0,0; ...
    "noisy",24,.4,5,2};
resV=[]; resProcess=[]; resC=[]; resR=[]; rows=cell(size(sets,1),11);
for k=1:size(sets,1)
    p=model_parameters(); p.Vin=sets{k,2}; p.D=sets{k,3};
    base=simulate_switched_equation(p,struct("duration",.004, ...
        "samplesPerPeriod",400));
    cfg=struct("samplesPerCycle",80,"sigmaVmV",sets{k,4}, ...
        "sigmaImA",sets{k,5},"seed",100+k,"edgeMethod", ...
        "timestamped_linear","edgeGuardUs",.5,"edgeWindowUs",1.5, ...
        "edgePointsPerSide",3,"RRFloor",0,"RCFloor",0);
    m=v2_make_measurements(base,p,cfg);
    edge=v2_edge_estimates(m,p,cfg);
    charge=v2_charge_estimates(m,p,cfg);
    vC=interp1(base.t,base.vC,m.t,"linear","extrap");
    rv=m.vT-(vC+p.ESR*m.iC);
    qStep=.5*(m.iC(1:end-1)+m.iC(2:end)).*diff(m.t);
    rProcess=vC(2:end)-(vC(1:end-1)+qStep/p.C1);
    rr=edge.y_R_V-p.ESR*edge.i_sum_A;
    rc=charge.delta_vT_V-p.ESR*charge.delta_iC_A-charge.q_C/p.C1;
    resV=[resV;rv]; resProcess=[resProcess;rProcess]; %#ok<AGROW>
    resR=[resR;rr]; resC=[resC;rc]; %#ok<AGROW>
    rows(k,:)={string(sets{k,1}),p.Vin,p.D,sets{k,4},sets{k,5}, ...
        rms(rv),rms(rProcess),rms(rc),rms(rr),height(charge),height(edge)};
end
trainingTable=cell2table(rows,"VariableNames",["training_set","Vin_V","D", ...
    "sigma_v_mV","sigma_i_mA","rms_residual_V", ...
    "rms_vC_process_residual_V","rms_C_pseudo_V","rms_R_pseudo_V", ...
    "C_measurements","R_measurements"]);

locked=struct();
locked.RV=max(prctile(abs(resV),75)^2,1e-8);
locked.RCFloor=max(prctile(abs(resC),75)^2,1e-8);
locked.RRFloor=max(prctile(abs(resR),75)^2,1e-8);
% The switching instants occupy only a small part of each cycle, so a
% central percentile would miss their one-step integration mismatch.  The
% 97.5th percentile captures those transitions without using the maximum.
qVC=max(prctile(abs(resProcess),97.5)^2,1e-10);
locked.Q=diag([qVC,1e-10,1e-10]);
locked.gateV=9; locked.gateC=9; locked.gateR=9;
locked.stableGuard=.3e-6; locked.ccmCurrentThreshold=0;
locked.resumeSamples=20; locked.resumeCycles=2;
locked.trainingSets=["nominal","high_D","noisy"];
locked.rule="R floors: 75th absolute measurement residual squared plus "+ ...
    "1e-8; Q_vC: 97.5th absolute one-step process residual squared; "+ ...
    "health-parameter Q=1e-10; NIS gates=9";

rawDir=fullfile(v2Root,"results","raw"); tableDir=fullfile(v2Root,"results","tables");
if ~isfolder(rawDir), mkdir(rawDir); end
if ~isfolder(tableDir), mkdir(tableDir); end
save(fullfile(rawDir,"locked_covariance.mat"),"locked","trainingTable");
writetable(trainingTable,fullfile(tableDir,"table_covariance_training_v2.csv"));
fprintf('Locked covariance: Q_vC %.4g, RV %.4g, RC floor %.4g, RR floor %.4g\n', ...
    locked.Q(1,1),locked.RV,locked.RCFloor,locked.RRFloor);
end
