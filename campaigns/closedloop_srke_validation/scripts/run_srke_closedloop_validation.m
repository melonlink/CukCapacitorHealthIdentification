function summary = run_srke_closedloop_validation(rootDir)
%RUN_SRKE_CLOSEDLOOP_VALIDATION Minimal TS-SRKE closed-loop supplement.
%   Answers the two review questions for the supervised realization under
%   feedback: (1) do regulator transients falsely trigger the supervisor,
%   and (2) does an abrupt health change under feedback still reset and
%   recover. Five blind cases under the frozen discrete PI regulator:
%     CLS-1 nominal feedback, no transition, no health change;
%     CLS-2 1.45x load step, health fixed;
%     CLS-3 16-to-12-V reference step, health fixed;
%     CLS-4 abrupt ESR step rC -> 2 rC under nominal feedback;
%     CLS-5 abrupt C step C -> 0.8 C under nominal feedback.
%   CLS-4/5 run both the supervised estimator and its unsupervised parent
%   on identical noise realizations. The closed-loop edge gain reuses the
%   frozen k_R^cl of the sibling closedloop_dcm_validation campaign.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
addpath(fullfile(rootDir, "scripts"));
tableDir = fullfile(rootDir, "results", "tables");
if ~isfolder(tableDir), mkdir(tableDir); end

% Frozen closed-loop edge calibration from the sibling campaign.
calib = readtable(fullfile(fileparts(rootDir), ...
    "closedloop_dcm_validation", "results", "tables", ...
    "table_closedloop_calibration.csv"));
kRcl = calib.kR_closedloop(1);
fprintf("Reusing frozen closed-loop k_R = %.6f\n", kRcl);

base = baseConfig();
base.kR = kRcl;

STEP_CYCLE = 1500;
cases = {
 % id        Cfac  Rfac  kind      value  seed
 "CLS-1",    1.00, 1.50, "none",   NaN,   43001;
 "CLS-2",    0.90, 1.50, "load",   10/1.45, 43002;
 "CLS-3",    1.00, 2.00, "vref",   12.0,  43003;
 "CLS-4",    1.00, 1.00, "esrstep", 2.0,  43004;
 "CLS-5",    1.00, 1.00, "cstep",  0.8,   43005};
nCases = size(cases, 1);

rows = {};
histories = {};
for c = 1:nCases
    for supOn = [true, false]
        isStep = any(strcmp(cases{c,4}, ["esrstep", "cstep"]));
        if ~supOn && ~isStep, continue; end   % parent only on health steps
        cfg = base;
        cfg.supervisorEnabled = supOn;
        cfg.Ctrue = cases{c,2} * base.Cb;
        cfg.ESRtrue = cases{c,3} * base.Rb;
        cfg.Cinit = 1.15 * cfg.Ctrue;
        cfg.Rinit = 0.70 * cfg.ESRtrue;
        cfg.nCycles = 3000; cfg.seed = cases{c,6};
        switch cases{c,4}
            case "load", cfg.loadStepCycle = STEP_CYCLE; cfg.loadStepValue = cases{c,5};
            case "vref", cfg.vrefStepCycle = STEP_CYCLE; cfg.vrefStepValue = cases{c,5};
            case "esrstep", cfg.esrStepCycle = STEP_CYCLE; cfg.esrStepFactor = cases{c,5};
            case "cstep", cfg.cStepCycle = STEP_CYCLE; cfg.cStepFactor = cases{c,5};
        end
        out = simulate_cuk_cycles_srke(cfg);
        histories(end+1, :) = {cases{c,1}, supOn, out}; %#ok<AGROW>

        eC = 100 * abs(out.est.C ./ out.Ctrue - 1);
        eR = 100 * abs(out.est.ESR ./ out.ESRtrue - 1);
        tail = (cfg.nCycles-299):cfg.nCycles;
        if isStep
            settle = settleFrom(eC, eR, STEP_CYCLE, 5, 32, cfg.nCycles);
            settleMs = settle * 1e3 * base.p.Ts;
            falseC = NaN; falseR = NaN;
        else
            settleMs = NaN;
            post = STEP_CYCLE:(STEP_CYCLE+749);
            falseC = max(eC(post)); falseR = max(eR(post));
            if strcmp(cases{c,4}, "none"), falseC = NaN; falseR = NaN; end
        end
        rows(end+1, :) = {cases{c,1}, variantName(supOn), ...
            cases{c,2}, cases{c,3}, string(cases{c,4}), ...
            mean(eC(tail)), mean(eR(tail)), settleMs, ...
            sum(out.sup.fires), out.sup.firstFire(1), out.sup.firstFire(2), ...
            falseC, falseR, ...
            100 * mean(out.est.validC(2:end) & out.est.validR(2:end))}; %#ok<AGROW>
        fprintf("%s %-12s tail eC=%.3f%% eR=%.3f%% settle=%.2f ms fires=%d\n", ...
            cases{c,1}, variantName(supOn), rows{end,6}, rows{end,7}, ...
            settleMs, rows{end,9});
    end
end
T = cell2table(rows, "VariableNames", ["case_id","variant","C_factor", ...
    "ESR_factor","transition","tail_C_error_percent", ...
    "tail_ESR_error_percent","post_step_settle_ms","supervisor_fires", ...
    "first_fire_cycle_C","first_fire_cycle_R", ...
    "false_C_peak_percent","false_ESR_peak_percent", ...
    "valid_update_rate_percent"]);
writetable(T, fullfile(tableDir, "table_srke_closedloop.csv"));

% Downsampled histories for the frozen-CSV figure pipeline (step cases).
hist = table();
for r = 1:size(histories, 1)
    if ~any(strcmp(histories{r,1}, ["CLS-4", "CLS-5"])), continue; end
    h = histories{r,3};
    idx = (1:4:h.cfg.nCycles)';
    hist = [hist; table( ...
        repmat(string(histories{r,1}), numel(idx), 1), ...
        repmat(variantName(histories{r,2}), numel(idx), 1), ...
        idx * h.cfg.p.Ts * 1e3, ...
        h.est.C(idx) ./ h.Ctrue(idx), ...
        h.est.ESR(idx) ./ h.ESRtrue(idx), ...
        VariableNames=["case_id","variant","time_ms","C_norm","ESR_norm"])]; %#ok<AGROW>
end
writetable(hist, fullfile(tableDir, "table_srke_closedloop_history.csv"));

summary = struct("kR", kRcl, "table", T);
save(fullfile(rootDir, "results", "srke_closedloop_workspace.mat"), ...
    "summary", "-v7.3");
end

function name = variantName(supOn)
if supOn, name = "TS-SRKE"; else, name = "TS-SLTVKE"; end
end

function cfg = baseConfig()
p = struct("Vin",24,"D",0.40,"fs",50e3,"L1",500e-6,"L2",500e-6, ...
    "C1",100e-6,"ESR",50e-3,"Co",470e-6,"Rload",10);
p.Ts = 1 / p.fs;
cfg = struct("p", p, "samplesPerPeriod", 200, ...
    "Vref", 16, "D0", 0.40, "Kp", 3e-4, "Ki", 2.5, ...
    "Dmin", 0.20, "Dmax", 0.70, ...
    "sigmaV", 1e-3, "sigmaI", 0.5e-3, ...
    "guardS", 0.5e-6, "edgeWindowS", 2.2e-6, "chargeWindowS", 2.0e-6, ...
    "Cb", 100e-6, "Rb", 50e-3, ...
    "IsumGate", 0.12, "CBounds", 100e-6*[0.65 1.35], ...
    "RBounds", 50e-3*[0.35 2.50], "kR", 1, ...
    "ltvQ", [2e-9; 5e-9], "ltvP0Alpha", 0.12^2, "ltvP0RScale", 0.45, ...
    "nisGate", 9, "supFastRate", 1/16, "supSlowRate", 1/128, ...
    "supThreshold", 2.5, "supClip", 6, ...
    "supWarmupRows", 32, "supHoldoffRows", 32, ...
    "supervisorEnabled", true);
end

function settle = settleFrom(eC, eR, stepCycle, tolPct, runLen, horizon)
%SETTLEFROM Post-step settling in cycles (5%/32-cycle criterion).
ok = eC <= tolPct & eR <= tolPct;
settle = horizon - stepCycle;
run = 0;
for k = stepCycle:numel(ok)
    if ok(k), run = run + 1; else, run = 0; end
    if run >= runLen
        settle = k - runLen + 1 - stepCycle;
        return;
    end
end
end
