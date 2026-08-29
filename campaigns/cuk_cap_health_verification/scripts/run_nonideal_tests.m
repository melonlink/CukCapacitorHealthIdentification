function summary = run_nonideal_tests(rootDir)
%RUN_NONIDEAL_TESTS Isolate conduction losses, ESL, and edge ringing.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
addpath(fullfile(rootDir,"model"),fullfile(rootDir,"algorithms"), ...
    fullfile(rootDir,"scripts"));
tableDir=fullfile(rootDir,"results","tables");
figureDir=fullfile(rootDir,"results","figures");
resultDir=fullfile(rootDir,"results","nonideal");
if ~isfolder(tableDir), mkdir(tableDir); end
if ~isfolder(figureDir), mkdir(figureDir); end
if ~isfolder(resultDir), mkdir(resultDir); end
p=model_parameters();

%% Isolated conduction nonidealities.
scenarioNames=["Ideal","Inductor_DCR","MOSFET_Ron","Diode","Combined"];
nonidealRows=cell(2*numel(scenarioNames),12);
savedCases=struct(); row=0;
for s=1:numel(scenarioNames)
    local=p;
    switch scenarioNames(s)
        case "Inductor_DCR"
            local.rL1=.05; local.rL2=.05;
        case "MOSFET_Ron"
            local.Rsw=.03;
        case "Diode"
            local.Vd=.7; local.Rd=.02;
        case "Combined"
            local.rL1=.05; local.rL2=.05; local.Rsw=.03;
            local.Vd=.7; local.Rd=.02;
    end
    data=simulate_switched_equation(local,struct("duration",.02, ...
        "samplesPerPeriod",200));
    f=measured_regression_features(data,struct("startTime",.005));
    rls=topology_rls(f.Phi,f.z,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
        "Cinit",p.C1,"ESRinit",p.ESR,"lambda",.995));
    kf=ts_ltvkf(data,struct("Cnom",p.C1,"ESRnom",p.ESR, ...
        "Cinit",p.C1,"ESRinit",p.ESR,"measurementVariance",1e-6, ...
        "gateThreshold",20));
    methods=["RLS","TS_LTVKF"];
    cEst=[rls.Cfinal,kf.Cfinal]; rEst=[rls.ESRfinal,kf.ESRfinal];
    for m=1:2
        row=row+1;
        nonidealRows(row,:)={scenarioNames(s),methods(m),local.rL1,local.rL2, ...
            local.Rsw,local.Vd,local.Rd,mean(data.vo(end-round(.002/data.dt):end)), ...
            cEst(m),100*abs(cEst(m)/p.C1-1),rEst(m), ...
            100*abs(rEst(m)/p.ESR-1)};
    end
    savedCases.(scenarioNames(s))=data;
end
nonidealTable=cell2table(nonidealRows,"VariableNames",["scenario","method", ...
    "rL1_Ohm","rL2_Ohm","Rsw_Ohm","diode_drop_V","diode_Ron_Ohm", ...
    "mean_vo_V","C_est_F","C_MAPE_percent","ESR_est_Ohm", ...
    "ESR_MAPE_percent"]);
writetable(nonidealTable,fullfile(tableDir,"table_nonideal_tests.csv"));

%% ESL and ringing: compare three edge estimators on identical waveforms.
eslValues=[0,5,10,20]*1e-9;
methods=["naive_peak","safe_window","linear_extrapolation"];
edgeRows=cell(numel(eslValues)*numel(methods),9);
waveforms=struct(); row=0;
for e=1:numel(eslValues)
    local=p; local.ESL=eslValues(e);
    data=simulate_switched_equation(local,struct("duration",.012, ...
        "samplesPerPeriod",200));
    data.vT=add_edge_ringing(data,local.ESL);
    estimates=estimate_edges(data,.004,120);
    for m=1:numel(methods)
        x=estimates.(methods(m)); row=row+1;
        edgeRows(row,:)={local.ESL,methods(m),p.ESR,mean(x,"omitnan"), ...
            median(x,"omitnan"),std(x,"omitnan"), ...
            mean(abs(x/p.ESR-1),"omitnan")*100, ...
            prctile(abs(x/p.ESR-1)*100,95),sum(isfinite(x))};
    end
    fieldName="ESL_"+string(round(local.ESL/1e-9))+"nH";
    waveforms.(fieldName)=data;
end
edgeTable=cell2table(edgeRows,"VariableNames",["ESL_H","method", ...
    "ESR_true_Ohm","ESR_est_mean_Ohm","ESR_est_median_Ohm", ...
    "ESR_est_std_Ohm","ESR_MAPE_percent","ESR_AE95_percent", ...
    "valid_edges"]);
writetable(edgeTable,fullfile(tableDir,"table_edge_method_comparison.csv"));

%% Representative 20 nH edge figure.
q=waveforms.ESL_20nH; rising=find(diff(q.u)>.5)+1;
kr=rising(find(q.t(rising)>.006,1));
window=kr-round(.8e-6/q.dt):kr+round(2.2e-6/q.dt);
fig=figure("Visible","off","Color","w"); tiledlayout(2,1);
nexttile; plot(1e6*(q.t(window)-q.t(kr)),q.vT(window),"LineWidth",1.1); hold on;
xline(0,"k--"); xline(1.2,"Color",[.4 .4 .4],"LineStyle",":");
grid on; ylabel("v_T (V)");
title("20 nH ESL: ringing and post-edge safe-window delay");
legend("Measured terminal voltage","PWM edge","Safe window start", ...
    "Location","best");
nexttile; hold on;
for m=1:numel(methods)
    rows=edgeTable.ESL_H==20e-9 & edgeTable.method==methods(m);
    scatter(m,1e3*edgeTable.ESR_est_mean_Ohm(rows),65,"filled");
end
yline(1e3*p.ESR,"k:","True ESR"); grid on; xlim([.5,3.5]);
xticks(1:3); xticklabels(["Naive peak","Safe window","Extrapolation"]);
ylabel("Mean ESR estimate (mOhm)");
save_verification_figure(fig,figureDir,"fig_12_edge_extrapolation");

summary=struct("maxConductionCError",max(nonidealTable.C_MAPE_percent), ...
    "maxConductionESRError",max(nonidealTable.ESR_MAPE_percent), ...
    "esl20NaiveError",edgeTable.ESR_MAPE_percent( ...
        edgeTable.ESL_H==20e-9 & edgeTable.method=="naive_peak"), ...
    "esl20ExtrapError",edgeTable.ESR_MAPE_percent( ...
        edgeTable.ESL_H==20e-9 & edgeTable.method=="linear_extrapolation"));
save(fullfile(resultDir,"nonideal_results.mat"),"summary","nonidealTable", ...
    "edgeTable","savedCases","waveforms","-v7.3");
fprintf(['Nonideal: max conduction C/ESR error %.3g/%.3g%%; ', ...
    '20 nH naive/extrapolated ESR error %.3g/%.3g%%\n'], ...
    summary.maxConductionCError,summary.maxConductionESRError, ...
    summary.esl20NaiveError,summary.esl20ExtrapError);
end

function vRing=add_edge_ringing(data,esl)
vRing=data.vT;
if esl==0, return; end
edges=find(abs(diff(data.u))>.5)+1;
ringLength=round(2e-6/data.dt);
for k=reshape(edges,1,[])
    last=min(numel(vRing),k+ringLength);
    tau=(0:last-k)'*data.dt;
    deltaI=data.iC(k)-data.iC(k-1);
    impulse=esl*deltaI/data.dt;
    ring=.65*impulse*exp(-tau/.35e-6).*cos(2*pi*2.2e6*tau);
    vRing(k:last)=vRing(k:last)+ring;
end
end

function estimates=estimate_edges(data,startTime,nEdges)
rising=find(diff(data.u)>.5)+1;
rising=rising(data.t(rising)>=startTime);
rising=rising(1:min(nEdges,numel(rising)));
naive=nan(numel(rising),1); safe=naive; extrap=naive;
preNear=round(.25e-6/data.dt); postNear=round(.35e-6/data.dt);
preStart=round(1e-6/data.dt); preEnd=round(.25e-6/data.dt);
postStart=round(1.2e-6/data.dt); postEnd=round(2e-6/data.dt);
for j=1:numel(rising)
    k=rising(j);
    if k-preStart<1 || k+postEnd>numel(data.t), continue; end
    denom=data.i1(k-1)+data.i2(k);
    naive(j)=(max(data.vT(k-preNear:k-1))- ...
        min(data.vT(k:k+postNear)))/denom;
    pre=(k-preStart):(k-preEnd); post=(k+postStart):(k+postEnd);
    safeDenom=mean(data.i1(pre))+mean(data.i2(post));
    safe(j)=(mean(data.vT(pre))-mean(data.vT(post)))/safeDenom;
    tPre=data.t(pre)-data.t(k); tPost=data.t(post)-data.t(k);
    fitVPre=polyfit(tPre,data.vT(pre),1);
    fitVPost=polyfit(tPost,data.vT(post),1);
    fitIPre=polyfit(tPre,data.i1(pre),1);
    fitIPost=polyfit(tPost,data.i2(post),1);
    extrapDenom=polyval(fitIPre,0)+polyval(fitIPost,0);
    extrap(j)=(polyval(fitVPre,0)-polyval(fitVPost,0))/extrapDenom;
end
estimates=struct("naive_peak",naive,"safe_window",safe, ...
    "linear_extrapolation",extrap);
end
