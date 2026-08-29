function summary = run_letter_campaign(rootDir)
%RUN_LETTER_CAMPAIGN Full letter-grade evaluation of the supervised hybrid.
%   Blind-style static matrix (9 health points x 3 loads x 2 noise
%   profiles x 3 seeds, randomized initialization within the companion
%   paper's realized blind ranges), abrupt C/ESR steps (3 seeds each), and
%   the hardest (0.1-s) joint ramp (3 seeds), each evaluated for TS-D-RLS,
%   the direction-decoupled Kalman kernel, and the supervised-reset hybrid
%   on identical O1 feature streams. Calibration (k_R and empirical row
%   covariances) is per noise profile on nominal health with disjoint
%   seeds. Writes aggregate tables and downsampled trajectory CSVs for the
%   letter figures.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
addpath(fullfile(rootDir, "scripts"));
tableDir = fullfile(rootDir, "results", "tables");
if ~isfolder(tableDir), mkdir(tableDir); end

methods = ["RLS", "KF", "HYBRID"];
noiseNames = ["nominal", "10mV_5mA"];
noiseSigma = [1e-3 0.5e-3; 10e-3 5e-3];

% --- Per-profile calibration (nominal health, disjoint seeds). ---
calib = struct();
for np = 1:2
    c = baseConfig();
    c.sigmaV = noiseSigma(np,1); c.sigmaI = noiseSigma(np,2);
    c.Ctrue = c.Cb; c.ESRtrue = c.Rb;
    c.nCycles = 800; c.seed = 61000 + np;
    F = simulate_cuk_features(c);
    m = (101:800)';
    vR = m(F.validR(m)); vC = m(F.validC(m));
    calib(np).kR = median(F.zR(vR) ./ (F.Isum(vR) * c.ESRtrue));
    calib(np).RR = var(F.zR(vR) - calib(np).kR * F.Isum(vR) * c.ESRtrue);
    alphaTrue = c.Cb / c.Ctrue;
    calib(np).RC = var((F.dvT(vC) - c.ESRtrue * F.diC(vC)) ...
        - (F.q(vC) / c.Cb) * alphaTrue);
    fprintf("calib %s: kR=%.6f RR=%.3e RC=%.3e\n", noiseNames(np), ...
        calib(np).kR, calib(np).RR, calib(np).RC);
end

% --- Static blind-style matrix. ---
healthC = [0.8 0.9 1.0]; healthR = [1.0 1.5 2.0];
loads = [10/0.58, 10, 10/1.45];
nSeeds = 3;
staticRows = {};
runId = 0;
for hc = healthC
    for hr = healthR
        for ld = 1:3
            for np = 1:2
                for sd = 1:nSeeds
                    runId = runId + 1;
                    c = baseConfig();
                    c.p.Rload = loads(ld);
                    c.sigmaV = noiseSigma(np,1); c.sigmaI = noiseSigma(np,2);
                    c.Ctrue = hc * c.Cb; c.ESRtrue = hr * c.Rb;
                    c.kR = calib(np).kR; c.RR = calib(np).RR;
                    c.RC = calib(np).RC;
                    c.nCycles = 1500; c.seed = 62000 + runId;
                    initRng = RandStream("mt19937ar", "Seed", 63000 + runId);
                    c.Cinit = c.Ctrue * (0.708 + 0.579 * rand(initRng));
                    c.Rinit = c.ESRtrue * (0.512 + 0.971 * rand(initRng));
                    F = simulate_cuk_features(c);
                    for mi = 1:3
                        o = run_estimator_on_features(methods(mi), F, c);
                        eC = 100*abs(o.C./F.Ctrue - 1);
                        eR = 100*abs(o.ESR./F.Rtruth - 1);
                        tail = 1401:1500;
                        w = (501:1500)';
                        inC = abs(o.C(w) - F.Ctrue(w)) <= 1.96*o.sigmaC(w);
                        inR = abs(o.ESR(w) - F.Rtruth(w)) <= 1.96*o.sigmaR(w);
                        staticRows(end+1,:) = {noiseNames(np), hc, hr, ...
                            loads(ld), sd, methods(mi), mean(eC(tail)), ...
                            mean(eR(tail)), ...
                            convergenceCycles(eC, eR, 5, 32, c.nCycles), ...
                            100*mean(inC & inR), o.resets}; %#ok<AGROW>
                    end
                end
            end
        end
    end
end
S = cell2table(staticRows, "VariableNames", ["noise","C_factor", ...
    "ESR_factor","Rload","seed","method","tail_C_err","tail_ESR_err", ...
    "conv_cycles","joint_coverage","resets"]);
writetable(S, fullfile(tableDir, "table_letter_static_rows.csv"));

agg = {};
for np = 1:2
    for mi = 1:3
        rows = S(S.noise == noiseNames(np) & S.method == methods(mi), :);
        agg(end+1,:) = {noiseNames(np), methods(mi), ...
            mean(rows.tail_C_err), mean(rows.tail_ESR_err), ...
            prctile(rows.tail_C_err, 95), prctile(rows.tail_ESR_err, 95), ...
            mean(rows.conv_cycles), mean(rows.joint_coverage), ...
            sum(rows.resets)}; %#ok<AGROW>
    end
end
A = cell2table(agg, "VariableNames", ["noise","method","C_MAPE", ...
    "ESR_MAPE","C_p95","ESR_p95","mean_conv","mean_joint_coverage", ...
    "total_resets"]);
writetable(A, fullfile(tableDir, "table_letter_static_summary.csv"));
disp(A);

% --- Dynamic scenarios (nominal noise). ---
dynRows = {};
trajC = table(); trajR = table();
for sd = 1:3
    % Abrupt C step.
    c = dynConfig(calib(1), noiseSigma(1,:));
    c.CStepCycle = 800; c.CStepValue = 0.8*c.Cb;
    c.nCycles = 2000; c.seed = 64000 + sd;
    F = simulate_cuk_features(c);
    for mi = 1:3
        o = run_estimator_on_features(methods(mi), F, c);
        [dynRows, traj] = dynMetrics(dynRows, "C step", methods(mi), ...
            sd, o, F, 800);
        if sd == 1, trajC = [trajC; traj]; end %#ok<AGROW>
    end
    % Abrupt ESR step.
    c = dynConfig(calib(1), noiseSigma(1,:));
    c.RStepCycle = 800; c.RStepValue = 2.0*c.Rb;
    c.nCycles = 2000; c.seed = 64100 + sd;
    F = simulate_cuk_features(c);
    for mi = 1:3
        o = run_estimator_on_features(methods(mi), F, c);
        [dynRows, traj] = dynMetrics(dynRows, "ESR step", methods(mi), ...
            sd, o, F, 800);
        if sd == 1, trajR = [trajR; traj]; end %#ok<AGROW>
    end
    % 0.1-s joint ramp.
    c = dynConfig(calib(1), noiseSigma(1,:));
    c.nCycles = 6000; c.seed = 64200 + sd;
    c.CRamp = [501 5500 0.8*c.Cb];
    c.RRamp = [501 5500 2.0*c.Rb];
    F = simulate_cuk_features(c);
    for mi = 1:3
        o = run_estimator_on_features(methods(mi), F, c);
        w = (501:5500)';
        nrmC = sqrt(mean((o.C(w) - F.Ctrue(w)).^2) / ...
            mean((F.Ctrue(w) - F.Ctrue(1)).^2));
        nrmR = sqrt(mean((o.ESR(w) - F.Rtruth(w)).^2) / ...
            mean((F.Rtruth(w) - F.Rtruth(1)).^2));
        dynRows(end+1,:) = {"0.1-s joint ramp", methods(mi), sd, ...
            100*nrmC, 100*nrmR, NaN, NaN, o.resets}; %#ok<AGROW>
    end
end
D = cell2table(dynRows, "VariableNames", ["scenario","method","seed", ...
    "C_metric","ESR_metric","recovery_cycles","post_coverage","resets"]);
writetable(D, fullfile(tableDir, "table_letter_dynamic_rows.csv"));

dagg = {};
for scen = ["C step", "ESR step", "0.1-s joint ramp"]
    for mi = 1:3
        rows = D(D.scenario == scen & D.method == methods(mi), :);
        dagg(end+1,:) = {scen, methods(mi), mean(rows.C_metric), ...
            mean(rows.ESR_metric), mean(rows.recovery_cycles), ...
            mean(rows.post_coverage), mean(rows.resets)}; %#ok<AGROW>
    end
end
DA = cell2table(dagg, "VariableNames", ["scenario","method", ...
    "mean_C_metric","mean_ESR_metric","mean_recovery","mean_post_cov", ...
    "mean_resets"]);
writetable(DA, fullfile(tableDir, "table_letter_dynamic_summary.csv"));
disp(DA);

writetable(trajC, fullfile(tableDir, "table_letter_traj_cstep.csv"));
writetable(trajR, fullfile(tableDir, "table_letter_traj_esrstep.csv"));
summary = struct("static", A, "dynamic", DA, "calib", calib);
end

function c = baseConfig()
p = struct("Vin",24,"D",0.40,"fs",50e3,"L1",500e-6,"L2",500e-6, ...
    "C1",100e-6,"ESR",50e-3,"Co",470e-6,"Rload",10);
p.Ts = 1/p.fs;
c = struct("p", p, "samplesPerPeriod", 200, ...
    "sigmaV", 1e-3, "sigmaI", 0.5e-3, ...
    "guardS", 0.5e-6, "edgeWindowS", 2.2e-6, "chargeWindowS", 2.0e-6, ...
    "Cb", 100e-6, "Rb", 50e-3, "IsumGate", 0.12, ...
    "CBounds", 100e-6*[0.65 1.35], "RBounds", 50e-3*[0.35 2.50], ...
    "rlsLambda", 0.9975, "rlsP0", 1000, ...
    "kfQAlpha", 2e-9, "kfQR", 5e-9, ...
    "kfP0Alpha", 0.12^2, "kfP0R", (0.45*50e-3)^2, ...
    "nisGate", 9, ...
    "cusumDrift", 0.5, "cusumThreshold", 10, "cusumClip", 6, ...
    "kR", 1, "RR", 1e-6, "RC", 1e-6, ...
    "Ctrue", 100e-6, "ESRtrue", 50e-3, ...
    "Cinit", 100e-6, "Rinit", 50e-3, "nCycles", 1000, "seed", 1);
end

function c = dynConfig(cal, sig)
c = baseConfig();
c.sigmaV = sig(1); c.sigmaI = sig(2);
c.Ctrue = c.Cb; c.ESRtrue = c.Rb;
c.Cinit = 1.10*c.Cb; c.Rinit = 0.80*c.Rb;
c.kR = cal.kR; c.RR = cal.RR; c.RC = cal.RC;
end

function [rows, traj] = dynMetrics(rows, scen, method, sd, o, F, stepCycle)
eC = 100*abs(o.C./F.Ctrue - 1); eR = 100*abs(o.ESR./F.Rtruth - 1);
rec = recoveryCycles(eC, eR, stepCycle, 5, 32, F.nCycles);
w = [(401:799)'; ((stepCycle+rec+50):F.nCycles)'];
w = w(w <= F.nCycles);
inC = abs(o.C(w) - F.Ctrue(w)) <= 1.96*o.sigmaC(w);
inR = abs(o.ESR(w) - F.Rtruth(w)) <= 1.96*o.sigmaR(w);
tail = (F.nCycles-99):F.nCycles;
rows(end+1,:) = {scen, method, sd, mean(eC(tail)), mean(eR(tail)), ...
    rec, 100*mean(inC & inR), o.resets};
idx = (700:4:1400)';
traj = table(repmat(method, numel(idx), 1), idx, ...
    o.C(idx)/1e-6, o.ESR(idx)/1e-3, F.Ctrue(idx)/1e-6, ...
    F.Rtruth(idx)/1e-3, o.sigmaC(idx)/1e-6, o.sigmaR(idx)/1e-3, ...
    VariableNames=["method","cycle","C_uF","ESR_mOhm","Ctrue_uF", ...
    "Rtrue_mOhm","sigmaC_uF","sigmaR_mOhm"]);
end

function conv = convergenceCycles(eC, eR, tolPct, runLen, horizon)
ok = eC <= tolPct & eR <= tolPct;
conv = horizon; run = 0;
for k = 1:numel(ok)
    if ok(k), run = run + 1; else, run = 0; end
    if run >= runLen, conv = k - runLen + 1; return; end
end
end

function rec = recoveryCycles(eC, eR, stepCycle, tolPct, runLen, horizon)
ok = eC <= tolPct & eR <= tolPct;
rec = horizon - stepCycle; run = 0;
for k = stepCycle:numel(ok)
    if ok(k), run = run + 1; else, run = 0; end
    if run >= runLen, rec = k - runLen + 1 - stepCycle; return; end
end
end
