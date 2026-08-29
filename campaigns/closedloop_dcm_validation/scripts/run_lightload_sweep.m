function summary = run_lightload_sweep(rootDir)
%RUN_LIGHTLOAD_SWEEP Quantify observation availability toward the DCM boundary.
%   Sweeps the load resistance at fixed duty (open loop) from the nominal
%   point down to light load, and reports per-load CCM-valid cycle fraction,
%   accepted-row rates, convergence, and endpoint errors for the locked
%   TS-D-RLS pipeline. Cycles whose combined inductor current would reach
%   zero are flagged non-CCM and rejected by the predeclared gates; the
%   estimate is held on those cycles. The switched Model-A equations do not
%   emulate DCM conduction itself, so flagged cycles quantify availability,
%   not DCM waveform accuracy.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
repoRoot = fileparts(rootDir);
addpath(fullfile(rootDir, "scripts"));
tableDir = fullfile(rootDir, "results", "tables");
if ~isfolder(tableDir), mkdir(tableDir); end

Rvals = [10 15 20 30 40 50 60 70 80 100 120 150];
nR = numel(Rvals);
rows = cell(nR, 9);
for i = 1:nR
    cfg = baseConfig();
    cfg.p.Rload = Rvals(i);
    cfg.closedLoop = false;
    cfg.Ctrue = 0.9 * cfg.Cb;             % representative degraded health
    cfg.ESRtrue = 1.5 * cfg.Rb;
    cfg.Cinit = 1.15 * cfg.Ctrue;
    cfg.Rinit = 0.70 * cfg.ESRtrue;
    cfg.kR = 0.998665;                    % closed-loop-commissioned value
    cfg.nCycles = 1600; cfg.seed = 43000 + i;
    out = simulate_cuk_cycles(cfg);

    eC = 100 * abs(out.est.C ./ cfg.Ctrue - 1);
    eR = 100 * abs(out.est.ESR ./ cfg.ESRtrue - 1);
    conv = convergenceCycles(eC, eR, 5, 32, cfg.nCycles);
    tail = (cfg.nCycles-99):cfg.nCycles;
    ss = 801:cfg.nCycles;                 % steady-state window after the
    ccmRate = 100 * mean(out.est.ccm(ss));% startup L-C1 resonance decays
    rows(i,:) = {Rvals(i), 100 * 10 / Rvals(i), ccmRate, ...
        100 * mean(out.est.validC(ss)), ...
        100 * mean(out.est.validR(ss)), conv, ...
        mean(eC(tail)), mean(eR(tail)), ...
        median(out.est.hIsum(out.est.validR), "omitnan")};
    fprintf("R=%3d Ohm (%.1f%% load): CCM %.1f%%, conv %d, eC %.3f%%, eR %.3f%%\n", ...
        Rvals(i), rows{i,2}, ccmRate, conv, rows{i,7}, rows{i,8});
end
T = cell2table(rows, "VariableNames", ["Rload_Ohm", "load_percent", ...
    "ccm_cycle_percent", "valid_C_percent", "valid_R_percent", ...
    "convergence_cycles", "tail_C_error_percent", "tail_ESR_error_percent", ...
    "median_edge_current_A"]);
writetable(T, fullfile(tableDir, "table_lightload_sweep.csv"));

% Manuscript figure fig_lightload.pdf is drawn from the sweep table by
% manuscript/figures/generate_manuscript_figures_v05.m.
summary = struct("table", T);
save(fullfile(rootDir, "results", "lightload_workspace.mat"), "summary", "-v7.3");
end

function cfg = baseConfig()
p = struct("Vin",24,"D",0.40,"fs",50e3,"L1",500e-6,"L2",500e-6, ...
    "C1",100e-6,"ESR",50e-3,"Co",470e-6,"Rload",10);
p.Ts = 1 / p.fs;
cfg = struct("p", p, "samplesPerPeriod", 200, "closedLoop", false, ...
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


