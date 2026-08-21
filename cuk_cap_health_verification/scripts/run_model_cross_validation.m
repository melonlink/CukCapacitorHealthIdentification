function summary = run_model_cross_validation(rootDir)
%RUN_MODEL_CROSS_VALIDATION Compare equation Model A with Simscape Model B.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
addpath(genpath(rootDir));
tableDir = fullfile(rootDir,"results","tables");
figureDir = fullfile(rootDir,"results","figures");
modelBDir = fullfile(rootDir,"results","model_b");
if ~isfolder(tableDir), mkdir(tableDir); end
if ~isfolder(figureDir), mkdir(figureDir); end
if ~isfolder(modelBDir), mkdir(modelBDir); end

source = load(fullfile(modelBDir,"simscape_model_b.mat"));
b = source.outData;
p = source.p;
t = b.i1_time;
analysisStart = t(end)-200*p.Ts;
steady = t >= analysisStart;
iCrec = (1-b.u).*b.i1-b.u.*b.i2;
recError = iCrec(steady)-b.iC(steady);
bCurrentRmse = rms(recError);
bCurrentNrmse = bCurrentRmse/max(range(b.iC(steady)),eps);

[edgeTable,capTable,Phi,z] = measured_features(b,p,analysisStart);
edgeMapeB = mean(abs(edgeTable.ESR_edge_Ohm/p.ESR-1))*100;
capOffMapeB = mean(abs(capTable.C_OFF_F/p.C1-1))*100;
capOnMapeB = mean(abs(capTable.C_ON_F/p.C1-1))*100;
rlsB = topology_rls(Phi,z,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
    "Cinit",0.7*p.C1,"ESRinit",0.5*p.ESR));

% Uniform resampling for waveform comparison and LTVKF.
dt = p.Ts/200;
tGrid = (analysisStart:dt:t(end))';
i1B = interp1(t,b.i1,tGrid,"linear");
i2B = interp1(t,b.i2,tGrid,"linear");
iCB = interp1(t,b.iC,tGrid,"linear");
vTB = interp1(t,b.vT,tGrid,"linear");
voB = interp1(t,b.vo,tGrid,"linear");
vCB = vTB-p.ESR*iCB;
rawIdx = find(t>=analysisStart);
rawB = struct("t",t(rawIdx),"iC",b.iC(rawIdx),"vT",b.vT(rawIdx), ...
    "Ctrue",p.C1*ones(size(rawIdx)),"ESRtrue",p.ESR*ones(size(rawIdx)));
kfB = ts_ltvkf(rawB,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
    "Cinit",0.7*p.C1,"ESRinit",0.5*p.ESR,"sampleStride",1, ...
    "measurementVariance",1e-6));

modelA = simulate_switched_equation(p,struct("duration",t(end), ...
    "samplesPerPeriod",200));
i1A = interp1(modelA.t,modelA.i1,tGrid,"linear");
i2A = interp1(modelA.t,modelA.i2,tGrid,"linear");
vCA = interp1(modelA.t,modelA.vC,tGrid,"linear");
vTA = interp1(modelA.t,modelA.vT,tGrid,"linear");
voA = interp1(modelA.t,modelA.vo,tGrid,"linear");

metric = ["mean_i1";"mean_i2";"mean_vC";"mean_vT";"mean_vo"; ...
    "iC_reconstruction_NRMSE";"edge_ESR_MAPE";"C_OFF_MAPE"; ...
    "C_ON_MAPE";"RLS_C_est";"RLS_ESR_est";"LTVKF_C_est";"LTVKF_ESR_est"];
unit = ["A";"A";"V";"V";"V";"1";"percent";"percent"; ...
    "percent";"F";"Ohm";"F";"Ohm"];
featuresA = extract_cycle_features(modelA,struct("nCycles",200));
rlsA = topology_rls(featuresA.Phi,featuresA.z,struct("Cnom",p.C1, ...
    "ESRnom",p.ESR));
kfA = ts_ltvkf(subset_data(modelA,find(modelA.t>=analysisStart)), ...
    struct("Cnom",p.C1,"ESRnom",p.ESR));
valueA = [mean(i1A);mean(i2A);mean(vCA);mean(vTA);mean(voA);0; ...
    mean(abs(featuresA.edgeTable.ESR_edge_Ohm/p.ESR-1))*100; ...
    mean(abs(featuresA.capTable.C_OFF_F/p.C1-1))*100; ...
    mean(abs(featuresA.capTable.C_ON_F/p.C1-1))*100; ...
    rlsA.Cfinal;rlsA.ESRfinal;kfA.Cfinal;kfA.ESRfinal];
valueB = [mean(i1B);mean(i2B);mean(vCB);mean(vTB);mean(voB);bCurrentNrmse; ...
    edgeMapeB;capOffMapeB;capOnMapeB;rlsB.Cfinal;rlsB.ESRfinal; ...
    kfB.Cfinal;kfB.ESRfinal];
absDifference = abs(valueB-valueA);
relativeDifferencePercent = 100*absDifference./max(abs(valueA),eps);
crossTable = table(metric,unit,valueA,valueB,absDifference, ...
    relativeDifferencePercent);
writetable(crossTable,fullfile(tableDir,"table_model_cross_validation.csv"));
writetable(edgeTable,fullfile(modelBDir,"table_model_b_edge_esr.csv"));
writetable(capTable,fullfile(modelBDir,"table_model_b_capacitance.csv"));

fig = figure("Visible","off","Color","w");
idx = tGrid >= tGrid(end)-3*p.Ts;
tUs = 1e6*(tGrid(idx)-tGrid(find(idx,1)));
tiledlayout(3,1);
nexttile; plot(tUs,i1A(idx),"LineWidth",1.1); hold on;
plot(tUs,i1B(idx),"--","LineWidth",1.1); grid on;
ylabel("i_1 (A)"); legend("Model A","Model B","Location","best");
title("Equation model vs independently connected Simscape circuit");
nexttile; plot(tUs,i2A(idx),"LineWidth",1.1); hold on;
plot(tUs,i2B(idx),"--","LineWidth",1.1); grid on; ylabel("i_2 (A)");
legend("Model A","Model B","Location","best");
nexttile; plot(tUs,vTA(idx),"LineWidth",1.1); hold on;
plot(tUs,vTB(idx),"--","LineWidth",1.1); grid on;
xlabel("Time within final 3 cycles (us)"); ylabel("v_T (V)");
legend("Model A","Model B","Location","best");
save_verification_figure(fig,figureDir,"fig_model_cross_validation");

summary = struct("currentNrmse",bCurrentNrmse,"edgeMape",edgeMapeB, ...
    "capOffMape",capOffMapeB,"capOnMape",capOnMapeB, ...
    "rlsCMape",abs(rlsB.Cfinal/p.C1-1)*100, ...
    "rlsESRMape",abs(rlsB.ESRfinal/p.ESR-1)*100, ...
    "kfCMape",abs(kfB.Cfinal/p.C1-1)*100, ...
    "kfESRMape",abs(kfB.ESRfinal/p.ESR-1)*100, ...
    "meanVo",mean(voB),"ccmMargin",min([i1B;i2B]));
save(fullfile(modelBDir,"model_cross_validation.mat"),"summary", ...
    "edgeTable","capTable","rlsB","kfB","crossTable");
fprintf('Model B: iC NRMSE %.3g, edge %.4g%%, C off/on %.4g/%.4g%%\n', ...
    bCurrentNrmse,edgeMapeB,capOffMapeB,capOnMapeB);
fprintf('Model B RLS C/ESR %.4g/%.4g%%, KF C/ESR %.4g/%.4g%%\n', ...
    summary.rlsCMape,summary.rlsESRMape,summary.kfCMape,summary.kfESRMape);
end

function [edgeTable,capTable,Phi,z] = measured_features(b,p,analysisStart)
t = b.i1_time;
vC = b.vT-p.ESR*b.iC;
rising = find(diff(b.u)>0.5)+1;
falling = find(diff(b.u)<-0.5)+1;
rising = rising(t(rising)>=analysisStart);
n = numel(rising)-1;
edgeRows = zeros(n,7);
capRows = zeros(n,6);
Phi = zeros(4*n,2);
z = zeros(4*n,1);
row = 0;
for c = 1:n
    kr = rising(c); kr2 = rising(c+1);
    kf = falling(find(falling>kr & falling<kr2,1));
    edgeRows(c,:) = [c,t(kr),b.vT(kr-1)-b.vT(kr),b.i1(kr-1), ...
        b.i2(kr),(b.vT(kr-1)-b.vT(kr))/(b.i1(kr-1)+b.i2(kr)),p.ESR];
    on = kr:kf-1; off = kf:kr2-1;
    qOnPositive = trapz(t(on),b.i2(on));
    qOff = trapz(t(off),b.i1(off));
    cOn = qOnPositive/(-(vC(on(end))-vC(on(1))));
    cOff = qOff/(vC(off(end))-vC(off(1)));
    capRows(c,:) = [c,t(kr),cOff,cOn,p.C1,p.ESR];
    row=row+1; Phi(row,:)=[0,b.iC(kr)-b.iC(kr-1)]; z(row)=b.vT(kr)-b.vT(kr-1);
    row=row+1; Phi(row,:)=[trapz(t(on),b.iC(on)),b.iC(on(end))-b.iC(on(1))]; z(row)=b.vT(on(end))-b.vT(on(1));
    row=row+1; Phi(row,:)=[0,b.iC(kf)-b.iC(kf-1)]; z(row)=b.vT(kf)-b.vT(kf-1);
    row=row+1; Phi(row,:)=[trapz(t(off),b.iC(off)),b.iC(off(end))-b.iC(off(1))]; z(row)=b.vT(off(end))-b.vT(off(1));
end
edgeTable = array2table(edgeRows,"VariableNames",["cycle","time_s", ...
    "delta_v_edge_V","i1_A","i2_A","ESR_edge_Ohm","ESR_true_Ohm"]);
capTable = array2table(capRows,"VariableNames",["cycle","time_s", ...
    "C_OFF_F","C_ON_F","C_true_F","ESR_true_Ohm"]);
end

function out = subset_data(data,idx)
fields = fieldnames(data); out = data;
for k=1:numel(fields)
    value=data.(fields{k});
    if isvector(value) && numel(value)==numel(data.t), out.(fields{k})=value(idx); end
end
end
