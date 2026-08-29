function sensitivity = run_kR_sensitivity()
%RUN_KR_SENSITIVITY Small frozen TS-D-RLS calibration-gain sensitivity.
% The observation stream is generated once with k_R=0.982 and zero seed
% amplitude. Only the ESR regressor supplied to the frozen estimator is
% scaled; no estimator setting is tuned and no full campaign is rerun.

scriptDir = string(fileparts(mfilename("fullpath")));
closureRoot = string(fileparts(scriptDir));
repoRoot = string(fileparts(closureRoot));
resultDir = fullfile(closureRoot,"results");
figureDir = fullfile(closureRoot,"figures");
logDir = fullfile(closureRoot,"logs");
ensureFolders([resultDir figureDir logDir]);

logPath = fullfile(logDir,"run_kR_sensitivity.log");
diary(logPath);
diaryCleanup = onCleanup(@() diary("off")); %#ok<NASGU>

% paper_algorithm_selection_v1 was removed in the v0.4 repository cleanup;
% the v2 package carries byte-identical generate_frozen_o1_stream and a
% comment-only-different run_locked_o1_estimator.
algorithmRoot = fullfile(repoRoot,"paper_algorithm_selection_v2");
addpath(fullfile(algorithmRoot,"datasets"), ...
    fullfile(algorithmRoot,"algorithms"));

cfg = struct;
cfg.Cb = 100e-6;
cfg.Rb = 0.05;
cfg.CBounds = [0.65 1.35]*cfg.Cb;
cfg.RBounds = [0.35 2.50]*cfg.Rb;
cfg.fs = 50e3;
cfg.healthFrameCycles = 1024;
cfg.rlsLambda = 0.9975;
cfg.rlsP0 = 1000;
cfg.modelBCurrentReference = 3.6;
cfg.safeWindowS = 2e-6;
cfg.kRCalibration = 0.982;
cfg.kRSeedAmplitude = 0;
cfg.modelBEdgeSlopeReference = 1.8e5;
cfg.noiseNames = ["5mV_2mA" "nominal" "10mV_5mA" ...
    "F28379D_device_realistic"];
cfg.sigmaV = [0.005 0.001 0.010 0.0022];
cfg.sigmaI = [0.002 0.0005 0.005 0.0012];

caseId = ["low_CCM";"nominal";"high_load";"ESR_1x";"ESR_2x"];
loadFactor = [0.25;0.75;1.00;0.50;0.50];
esrFactor = [1;1;1;1;2];
seeds = (4701:4705).';
deltas = [-0.01 -0.005 -0.0025 0 0.0025 0.005 0.01].';
rows = table();

for iCase = 1:numel(caseId)
    if esrFactor(iCase) == 2
        trajectoryType = "ESR_abrupt";
        changeTime = 0;
        rInitFactor = 0.5;
    else
        trajectoryType = "static";
        changeTime = Inf;
        rInitFactor = 0.8;
    end
    spec = struct("case_id",caseId(iCase), ...
        "trajectory_type",trajectoryType,"duration_s",0.02048, ...
        "shape","step","source_model", ...
        "TRACE_DERIVED_OBSERVATION","seed",seeds(iCase), ...
        "noise_profile","nominal","skew_ns",0, ...
        "change_time_s",changeTime,"Cinit_factor",0.9, ...
        "Rinit_factor",rInitFactor,"load0",loadFactor(iCase), ...
        "Vin0",24,"duty0",0.40,"group_cycles",2);
    truthObs = generate_frozen_o1_stream(spec,cfg);
    for delta = reshape(deltas,1,[])
        estimatorKR = cfg.kRCalibration*(1+delta);
        estimatorObs = truthObs;
        estimatorObs.hR = truthObs.hR*(estimatorKR/cfg.kRCalibration);
        estimate = run_locked_o1_estimator("M1 TS-D-RLS", ...
            estimatorObs,cfg);
        finalEsr = estimate.ESR(end);
        trueEsr = truthObs.Rtruth(end);
        biasPercent = 100*(finalEsr/trueEsr-1);
        theoryBiasPercent = 100*(cfg.kRCalibration/estimatorKR-1);
        row = table(caseId(iCase),loadFactor(iCase),esrFactor(iCase), ...
            cfg.kRCalibration,estimatorKR,delta,100*delta,trueEsr, ...
            finalEsr,biasPercent,theoryBiasPercent, ...
            estimate.accepted_R_updates,estimate.projection_activations, ...
            VariableNames=["case_id" "load_factor" "ESR_factor" ...
            "true_kR" "estimator_kR" "delta_fraction" "delta_percent" ...
            "true_ESR_Ohm" "estimated_ESR_Ohm" "ESR_bias_percent" ...
            "theory_scale_bias_percent" "accepted_R_updates" ...
            "projection_activations"]);
        rows = [rows;row]; %#ok<AGROW>
    end
end

sensitivity = rows;
writetable(sensitivity,fullfile(resultDir,"table_kR_sensitivity.csv"));

oldVisibility = get(groot,"defaultFigureVisible");
visibilityCleanup = onCleanup(@() set(groot,"defaultFigureVisible", ...
    oldVisibility)); %#ok<NASGU>
set(groot,"defaultFigureVisible","off");
fig = figure(Color="w",Position=[100 100 1050 650]);
hold on;
colors = lines(numel(caseId));
for iCase = 1:numel(caseId)
    subset = sensitivity(sensitivity.case_id==caseId(iCase),:);
    plot(subset.delta_percent,subset.ESR_bias_percent,"-o", ...
        Color=colors(iCase,:),LineWidth=1.5, ...
        DisplayName=replace(caseId(iCase),"_","\_"));
end
plot(100*deltas,100*(1./(1+deltas)-1),"k--",LineWidth=2, ...
    DisplayName="ideal inverse-scale relation");
yline(0,"k:",HandleVisibility="off");
grid on;
xlabel("Assumed k_R error (%)");
ylabel("Final ESR bias (%)");
title("Frozen TS-D-RLS sensitivity to k_R calibration error");
subtitle("Five representative O1 cases; no retuning");
legend(Location="best");
exportgraphics(fig,fullfile(figureDir,"fig_kR_sensitivity.png"), ...
    Resolution=220);
close(fig);

summary = groupsummary(sensitivity,"delta_percent", ...
    ["mean" "min" "max"],"ESR_bias_percent");
writetable(summary,fullfile(resultDir, ...
    "table_kR_sensitivity_summary.csv"));
fprintf("Sensitivity complete: %d rows, worst |ESR bias| %.6f %%\n", ...
    height(sensitivity),max(abs(sensitivity.ESR_bias_percent)));
end

function ensureFolders(paths)
for path = reshape(string(paths),1,[])
    if ~isfolder(path)
        mkdir(path);
    end
end
end
