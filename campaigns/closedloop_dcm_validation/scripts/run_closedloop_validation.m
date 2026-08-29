function summary = run_closedloop_validation(rootDir)
%RUN_CLOSEDLOOP_VALIDATION Closed-loop supplement study for the manuscript.
%   Runs a calibration case to fix k_R under the closed-loop measurement
%   conditions, then three blind health cases with a load, input-voltage,
%   and reference (duty) transition under a discrete PI voltage regulator.
%   Writes result tables and a manuscript vector figure.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
repoRoot = fileparts(rootDir);
addpath(fullfile(rootDir, "scripts"));
tableDir = fullfile(rootDir, "results", "tables");
if ~isfolder(tableDir), mkdir(tableDir); end

base = baseConfig();

% --- Calibration case: nominal health, closed loop, no transition. ---
cal = base;
cal.Ctrue = base.Cb; cal.ESRtrue = base.Rb;
cal.Cinit = base.Cb; cal.Rinit = base.Rb;
cal.nCycles = 800; cal.seed = 41001;
cal.kR = 1;                               % placeholder during calibration
calOut = simulate_cuk_cycles(cal);
mask = false(cal.nCycles, 1); mask(101:700) = true;
kR = median(calOut.kRsamples(mask & isfinite(calOut.kRsamples)));
fprintf("Closed-loop calibrated k_R = %.6f (%d accepted edges)\n", ...
    kR, nnz(mask & isfinite(calOut.kRsamples)));

% --- Blind cases. ---
cases = {
 "CL-1 load step",  0.80, 2.00, "load", 10/1.45;
 "CL-2 Vin step",   0.90, 1.50, "vin",  28.8;
 "CL-3 Vref step",  1.00, 2.00, "vref", 12.0};
nCases = size(cases, 1);
rows = cell(nCases, 9);
histories = cell(nCases, 1);
for c = 1:nCases
    cfg = base;
    cfg.kR = kR;
    cfg.Ctrue = cases{c,2} * base.Cb;
    cfg.ESRtrue = cases{c,3} * base.Rb;
    cfg.Cinit = 1.15 * cfg.Ctrue;         % blind-range initialization offset
    cfg.Rinit = 0.70 * cfg.ESRtrue;
    cfg.nCycles = 3000; cfg.seed = 42000 + c;
    stepCycle = 1500;
    switch cases{c,4}
        case "load", cfg.loadStepCycle = stepCycle; cfg.loadStepValue = cases{c,5};
        case "vin",  cfg.vinStepCycle = stepCycle;  cfg.vinStepValue = cases{c,5};
        case "vref", cfg.vrefStepCycle = stepCycle; cfg.vrefStepValue = cases{c,5};
    end
    out = simulate_cuk_cycles(cfg);
    histories{c} = out;

    eC = 100 * abs(out.est.C ./ cfg.Ctrue - 1);
    eR = 100 * abs(out.est.ESR ./ cfg.ESRtrue - 1);
    conv = convergenceCycles(eC, eR, 5, 32, cfg.nCycles);
    tail = (cfg.nCycles-299):cfg.nCycles;
    post = stepCycle:(stepCycle+749);
    rows(c,:) = {string(cases{c,1}), cases{c,2}, cases{c,3}, ...
        mean(eC(tail)), mean(eR(tail)), conv, ...
        max(eC(post)), max(eR(post)), ...
        100 * mean(out.est.validC(2:end) & out.est.validR(2:end))};
    fprintf("%s: tail eC=%.3f%% eR=%.3f%% conv=%d falseC=%.3f%% falseR=%.3f%%\n", ...
        cases{c,1}, rows{c,4}, rows{c,5}, conv, rows{c,7}, rows{c,8});
end
T = cell2table(rows, "VariableNames", ["case_id","C_factor","ESR_factor", ...
    "tail_C_error_percent","tail_ESR_error_percent","convergence_cycles", ...
    "post_step_max_C_error_percent","post_step_max_ESR_error_percent", ...
    "valid_update_rate_percent"]);
writetable(T, fullfile(tableDir, "table_closedloop_validation.csv"));

% Downsampled trajectory history so manuscript figures redraw from frozen
% CSV output rather than from the transient workspace.
hist = table();
for c = 1:nCases
    h = histories{c};
    idx = (1:4:numel(h.Dhist))';
    hist = [hist; table( ...
        repmat(string(cases{c,1}), numel(idx), 1), ...
        idx * 0.02, h.Dhist(idx), ...
        h.est.C(idx) ./ h.cfg.Ctrue, ... %#ok<AGROW>
        h.est.ESR(idx) ./ h.cfg.ESRtrue, ...
        VariableNames=["case_id","time_ms","duty","C_norm","ESR_norm"])];
end
writetable(hist, fullfile(tableDir, "table_closedloop_history.csv"));
calibRow = table(kR, nnz(mask & isfinite(calOut.kRsamples)), ...
    VariableNames=["kR_closedloop", "accepted_calibration_edges"]);
writetable(calibRow, fullfile(tableDir, "table_closedloop_calibration.csv"));

% Manuscript figure fig_closedloop.pdf is drawn from the two CSV tables by
% manuscript/figures/generate_manuscript_figures_v05.m.
summary = struct("kR", kR, "table", T);
save(fullfile(rootDir, "results", "closedloop_workspace.mat"), ...
    "summary", "histories", "cases", "kR", "-v7.3");
end

function cfg = baseConfig()
p = struct("Vin",24,"D",0.40,"fs",50e3,"L1",500e-6,"L2",500e-6, ...
    "C1",100e-6,"ESR",50e-3,"Co",470e-6,"Rload",10);
p.Ts = 1 / p.fs;
cfg = struct("p", p, "samplesPerPeriod", 200, "closedLoop", true, ...
    "Vref", 16, "D0", 0.40, "Kp", 3e-4, "Ki", 2.5, ...
    "Dmin", 0.20, "Dmax", 0.70, ...
    "sigmaV", 1e-3, "sigmaI", 0.5e-3, ...
    "guardS", 0.5e-6, "edgeWindowS", 2.2e-6, "chargeWindowS", 2.0e-6, ...
    "Cb", 100e-6, "Rb", 50e-3, "rlsLambda", 0.9975, "rlsP0", 1000, ...
    "IsumGate", 0.12, "CBounds", 100e-6*[0.65 1.35], ...
    "RBounds", 50e-3*[0.35 2.50], "kR", 1);
end

function conv = convergenceCycles(eC, eR, tolPct, runLen, horizon)
ok = eC <= tolPct & eR <= tolPct;
conv = horizon;
run = 0;
for k = 1:numel(ok)
    if ok(k), run = run + 1; else, run = 0; end
    if run >= runLen, conv = k - runLen + 1; return; end
end
end


