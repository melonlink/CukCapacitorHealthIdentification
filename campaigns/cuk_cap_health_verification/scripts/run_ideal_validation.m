function summary = run_ideal_validation(rootDir)
%RUN_IDEAL_VALIDATION Execute Model A theory and ideal algorithm gates.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
addpath(genpath(rootDir));
idealDir = fullfile(rootDir, "results", "ideal");
tableDir = fullfile(rootDir, "results", "tables");
figureDir = fullfile(rootDir, "results", "figures");
if ~isfolder(idealDir), mkdir(idealDir); end
if ~isfolder(tableDir), mkdir(tableDir); end
if ~isfolder(figureDir), mkdir(figureDir); end

p = model_parameters();
data = simulate_switched_equation(p, struct("duration", 0.02, ...
    "samplesPerPeriod", 200));
features = extract_cycle_features(data, struct("nCycles", 200));
iCrec = (1-data.u).*data.i1-data.u.*data.i2;
steady = data.t >= data.t(end)-200*p.Ts;
currentError = iCrec(steady)-data.iC(steady);
currentRmse = sqrt(mean(currentError.^2));
currentMax = max(abs(currentError));
currentNrmse = currentRmse / max(range(data.iC(steady)), eps);

edge = features.edgeTable;
edgeError = 100*(edge.ESR_edge_Ohm-edge.ESR_true_Ohm)./edge.ESR_true_Ohm;
edgeMape = mean(abs(edgeError));
edgeBias = mean(edge.ESR_edge_Ohm-edge.ESR_true_Ohm);
edgeStd = std(edge.ESR_edge_Ohm);
edgePred = edge.ESR_true_Ohm.*(edge.i1_A+edge.i2_A);
edgeFit = polyfit(edgePred, edge.delta_v_edge_V, 1);
edgeFitted = polyval(edgeFit, edgePred);
edgeR2 = 1-sum((edge.delta_v_edge_V-edgeFitted).^2) / ...
    sum((edge.delta_v_edge_V-mean(edge.delta_v_edge_V)).^2);

cap = features.capTable;
capOffMape = mean(abs(cap.C_OFF_F./cap.C_true_F-1))*100;
capOnMape = mean(abs(cap.C_ON_F./cap.C_true_F-1))*100;

rls = topology_rls(features.Phi, features.z, struct("Cnom", p.C1, ...
    "ESRnom", p.ESR, "Cinit", 0.7*p.C1, "ESRinit", 0.5*p.ESR));
kfDataStart = find(data.t >= data.t(end)-0.01, 1);
kfData = subset_data(data, kfDataStart:numel(data.t));
kf = ts_ltvkf(kfData, struct("Cnom", p.C1, "ESRnom", p.ESR, ...
    "Cinit", 0.7*p.C1, "ESRinit", 0.5*p.ESR, "sampleStride", 1));
rlsTime = (0:numel(rls.C)-1)'*(p.Ts/4);
rlsCMape = abs(rls.Cfinal/p.C1-1)*100;
rlsRMape = abs(rls.ESRfinal/p.ESR-1)*100;
kfCMape = abs(kf.Cfinal/p.C1-1)*100;
kfRMape = abs(kf.ESRfinal/p.ESR-1)*100;
rlsConv = max(convergence_time(rlsTime, rls.C, p.C1, 0.02, 100), ...
    convergence_time(rlsTime, rls.ESR, p.ESR, 0.03, 100));
kfConv = max(convergence_time(kf.t, kf.C, p.C1, 0.02, 1000), ...
    convergence_time(kf.t, kf.ESR, p.ESR, 0.03, 1000));

observability = ltv_observability(kfData, [3,5,10], ...
    struct("sampleStride", 1));
writetable(edge, fullfile(tableDir, "table_edge_esr.csv"));
writetable(cap, fullfile(tableDir, "table_capacitance_subinterval.csv"));
writetable(observability, fullfile(tableDir, "table_ltv_observability.csv"));
identifiability = table(p.Vin,p.D,p.Rload,p.C1,p.ESR,features.rankPhi, ...
    features.lambdaMin,features.condGram,features.condGramNormalized, ...
    "VariableNames",["Vin_V","D","Rload_Ohm","C_F","ESR_Ohm", ...
    "rank_Phi","lambda_min_gram","cond_gram_raw","cond_gram_normalized"]);
writetable(identifiability, fullfile(tableDir, "table_identifiability.csv"));

% Figure 1: capacitor current reconstruction.
fig = figure("Visible","off","Color","w");
idx = find(data.t >= data.t(end)-3*p.Ts);
tUs = 1e6*(data.t(idx)-data.t(idx(1)));
tiledlayout(2,1);
nexttile; plot(tUs,data.iC(idx),"LineWidth",1.3); hold on;
plot(tUs,iCrec(idx),"--","LineWidth",1.1); grid on;
xlabel("Time (us)"); ylabel("Capacitor current (A)");
legend("True branch current","Reconstructed current","Location","best");
title("Cuk transfer-capacitor current reconstruction, nominal CCM");
nexttile; plot(tUs,iCrec(idx)-data.iC(idx),"LineWidth",1.1); grid on;
xlabel("Time (us)"); ylabel("Error (A)");
title(sprintf("RMSE %.3g A, NRMSE %.3g",currentRmse,currentNrmse));
save_verification_figure(fig,figureDir,"fig_01_cap_current_reconstruction");

% Figure 2: ESR edge relation.
fig = figure("Visible","off","Color","w");
scatter(edgePred,edge.delta_v_edge_V,18,edge.cycle,"filled"); hold on;
xLine = linspace(min(edgePred),max(edgePred),100);
plot(xLine,polyval(edgeFit,xLine),"k-","LineWidth",1.4); grid on;
xlabel("r_C(i_1+i_2) (V)"); ylabel("Measured edge drop (V)");
title(sprintf("ESR edge relation: slope %.6f, R^2 %.8f",edgeFit(1),edgeR2));
legend("PWM edges","Least-squares fit","Location","best"); colorbar;
save_verification_figure(fig,figureDir,"fig_02_edge_relation");

% Figure 3: subinterval capacitance.
fig = figure("Visible","off","Color","w");
plot(cap.cycle,1e6*cap.C_OFF_F,"LineWidth",1.1); hold on;
plot(cap.cycle,1e6*cap.C_ON_F,"--","LineWidth",1.1);
yline(1e6*p.C1,"k:","True C"); grid on;
xlabel("Steady PWM cycle"); ylabel("Estimated capacitance (uF)");
legend("OFF charge relation","ON charge relation","True","Location","best");
title(sprintf("Subinterval charge estimates: OFF MAPE %.4g%%, ON MAPE %.4g%%", ...
    capOffMape,capOnMape));
save_verification_figure(fig,figureDir,"fig_03_capacitance_charge_relation");

% Figures 13 and 14: algorithm comparison.
fig = figure("Visible","off","Color","w");
plot(1e3*rlsTime,1e6*rls.C,"LineWidth",1.1); hold on;
plot(1e3*(kf.t-kf.t(1)),1e6*kf.C,"LineWidth",1.1);
yline(1e6*p.C1,"k:"); grid on; xlabel("Estimator time (ms)");
ylabel("Estimated C (uF)"); legend("RLS","TS-LTVKF","True","Location","best");
title("Ideal capacitance estimation, identical Model A data");
save_verification_figure(fig,figureDir,"fig_13_rls_vs_ltvkf_C");
fig = figure("Visible","off","Color","w");
plot(1e3*rlsTime,1e3*rls.ESR,"LineWidth",1.1); hold on;
plot(1e3*(kf.t-kf.t(1)),1e3*kf.ESR,"LineWidth",1.1);
yline(1e3*p.ESR,"k:"); grid on; xlabel("Estimator time (ms)");
ylabel("Estimated ESR (mOhm)"); legend("RLS","TS-LTVKF","True","Location","best");
title("Ideal ESR estimation, identical Model A data");
save_verification_figure(fig,figureDir,"fig_14_rls_vs_ltvkf_ESR");

summary = struct("currentRmse",currentRmse,"currentMax",currentMax, ...
    "currentNrmse",currentNrmse,"edgeMape",edgeMape,"edgeBias",edgeBias, ...
    "edgeStd",edgeStd,"edgeR2",edgeR2,"capOffMape",capOffMape, ...
    "capOnMape",capOnMape,"rankPhi",features.rankPhi, ...
    "condGramNormalized",features.condGramNormalized,"rlsCMape",rlsCMape, ...
    "rlsRMape",rlsRMape,"kfCMape",kfCMape,"kfRMape",kfRMape, ...
    "rlsConvergence",rlsConv,"kfConvergence",kfConv);
save(fullfile(idealDir,"ideal_validation.mat"),"data","features","rls","kf","summary");
fprintf('Ideal: edge %.6g%%, C(off/on) %.6g/%.6g%%, R2 %.9f\n', ...
    edgeMape,capOffMape,capOnMape,edgeR2);
fprintf('RLS C/ESR %.4g/%.4g%%; KF C/ESR %.4g/%.4g%%; rank(Phi)=%d\n', ...
    rlsCMape,rlsRMape,kfCMape,kfRMape,features.rankPhi);
end

function out = subset_data(data, idx)
fields = fieldnames(data);
out = data;
for k = 1:numel(fields)
    value = data.(fields{k});
    if isvector(value) && numel(value) == numel(data.t)
        out.(fields{k}) = value(idx);
    end
end
end

