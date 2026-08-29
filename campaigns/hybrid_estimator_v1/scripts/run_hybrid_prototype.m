function summary = run_hybrid_prototype(rootDir)
%RUN_HYBRID_PROTOTYPE Prototype study: supervised-reset hybrid estimator.
%   Compares TS-D-RLS, the direction-decoupled Kalman kernel (TS-SLTVKE
%   point behavior), and the proposed supervised-reset hybrid on identical
%   O1 feature streams: static blind cases, abrupt health steps, and the
%   hardest (0.1-s) health ramps. Prototype scope: Model-A plant, nominal
%   noise, ideal sampling; not a frozen paper campaign.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
addpath(fullfile(rootDir, "scripts"));
tableDir = fullfile(rootDir, "results", "tables");
if ~isfolder(tableDir), mkdir(tableDir); end

cfg = baseConfig();

% --- Calibration on a nominal-health run: kR and empirical row noise. ---
cal = cfg; cal.Ctrue = cfg.Cb; cal.ESRtrue = cfg.Rb;
cal.nCycles = 800; cal.seed = 51001;
Fc = simulate_cuk_features(cal);
m = (101:800)';
vR = Fc.validR(m); vCk = Fc.validC(m);
kR = median(Fc.zR(m(vR)) ./ (Fc.Isum(m(vR)) * cal.ESRtrue));
cfg.kR = kR;
resR = Fc.zR(m(vR)) - kR * Fc.Isum(m(vR)) * cal.ESRtrue;
alphaTrue = cfg.Cb / cal.Ctrue;
resC = (Fc.dvT(m(vCk)) - cal.ESRtrue * Fc.diC(m(vCk))) ...
    - (Fc.q(m(vCk)) / cfg.Cb) * alphaTrue;
cfg.RR = var(resR);
cfg.RC = var(resC);
fprintf("Calibrated kR=%.6f, RR=%.3e, RC=%.3e\n", kR, cfg.RR, cfg.RC);

methods = ["RLS", "KF", "HYBRID"];
rows = {};

% --- S1: static blind cases, 10 seeds, coverage over settled window. ---
statC = zeros(3,1); statR = zeros(3,1); conv = zeros(3,1);
cov = zeros(3,1); nSeeds = 10;
for s = 1:nSeeds
    c = cfg; c.Ctrue = 0.85*cfg.Cb; c.ESRtrue = 1.6*cfg.Rb;
    c.Cinit = 1.15*c.Ctrue; c.Rinit = 0.70*c.ESRtrue;
    c.nCycles = 1500; c.seed = 52000 + s;
    F = simulate_cuk_features(c);
    for mi = 1:3
        o = run_estimator_on_features(methods(mi), F, c);
        eC = 100*abs(o.C./F.Ctrue - 1); eR = 100*abs(o.ESR./F.Rtruth - 1);
        tail = 1401:1500;
        statC(mi) = statC(mi) + mean(eC(tail))/nSeeds;
        statR(mi) = statR(mi) + mean(eR(tail))/nSeeds;
        conv(mi) = conv(mi) + convergenceCycles(eC, eR, 5, 32, c.nCycles)/nSeeds;
        w = 501:1500;
        inC = abs(o.C(w) - F.Ctrue(w)) <= 1.96*o.sigmaC(w);
        inR = abs(o.ESR(w) - F.Rtruth(w)) <= 1.96*o.sigmaR(w);
        cov(mi) = cov(mi) + 100*mean(inC & inR)/nSeeds;
    end
end
for mi = 1:3
    rows(end+1,:) = {"S1 static", methods(mi), statC(mi), statR(mi), ...
        conv(mi), cov(mi), NaN}; %#ok<AGROW>
    fprintf("S1 %-6s: eC=%.3f%% eR=%.3f%% conv=%.1f joint cov=%.1f%%\n", ...
        methods(mi), statC(mi), statR(mi), conv(mi), cov(mi));
end

% --- S2: abrupt health steps at cycle 800 (C-down run and ESR-up run). ---
steps = { "C step",  @(c) setfield(setfield(c,"CStepCycle",800), ...
              "CStepValue", 0.8*cfg.Cb); ...
          "ESR step", @(c) setfield(setfield(c,"RStepCycle",800), ...
              "RStepValue", 2.0*cfg.Rb) };
for si = 1:2
    c = cfg; c.Ctrue = cfg.Cb; c.ESRtrue = cfg.Rb;
    c.Cinit = 1.10*cfg.Cb; c.Rinit = 0.80*cfg.Rb;
    c.nCycles = 2000; c.seed = 53000 + si;
    c = steps{si,2}(c);
    F = simulate_cuk_features(c);
    for mi = 1:3
        o = run_estimator_on_features(methods(mi), F, c);
        eC = 100*abs(o.C./F.Ctrue - 1); eR = 100*abs(o.ESR./F.Rtruth - 1);
        rec = recoveryCycles(eC, eR, 800, 5, 32, c.nCycles);
        tail = 1901:2000;
        tailErr = max(mean(eC(tail)), mean(eR(tail)));
        w = [401:799, (800+rec+50):2000]';  % settled windows before/after
        w = w(w <= c.nCycles);
        inC = abs(o.C(w) - F.Ctrue(w)) <= 1.96*o.sigmaC(w);
        inR = abs(o.ESR(w) - F.Rtruth(w)) <= 1.96*o.sigmaR(w);
        covS = 100*mean(inC & inR);
        rows(end+1,:) = {"S2 " + steps{si,1}, methods(mi), ...
            mean(eC(tail)), mean(eR(tail)), rec, covS, o.resets}; %#ok<AGROW>
        fprintf("S2 %-8s %-6s: recovery=%4d cycles, tail err=%.3f%%, cov=%.1f%%, resets=%d\n", ...
            steps{si,1}, methods(mi), rec, tailErr, covS, o.resets);
    end
end

% --- S3: 0.1-s joint ramp (hardest paper ramp): C down 20%, ESR up 2x. ---
c = cfg; c.Ctrue = cfg.Cb; c.ESRtrue = cfg.Rb;
c.Cinit = cfg.Cb; c.Rinit = cfg.Rb;
c.nCycles = 6000; c.seed = 54001;
c.CRamp = [501 5500 0.8*cfg.Cb];
c.RRamp = [501 5500 2.0*cfg.Rb];
F = simulate_cuk_features(c);
for mi = 1:3
    o = run_estimator_on_features(methods(mi), F, c);
    w = 501:5500;
    nrmC = sqrt(mean((o.C(w) - F.Ctrue(w)).^2) / ...
        mean((F.Ctrue(w) - F.Ctrue(1)).^2));
    nrmR = sqrt(mean((o.ESR(w) - F.Rtruth(w)).^2) / ...
        mean((F.Rtruth(w) - F.Rtruth(1)).^2));
    inC = abs(o.C(w) - F.Ctrue(w)) <= 1.96*o.sigmaC(w);
    inR = abs(o.ESR(w) - F.Rtruth(w)) <= 1.96*o.sigmaR(w);
    covS = 100*mean(inC & inR);
    rows(end+1,:) = {"S3 0.1-s joint ramp", methods(mi), 100*nrmC, ...
        100*nrmR, NaN, covS, o.resets}; %#ok<AGROW>
    fprintf("S3 ramp %-6s: nRMSE C=%.4f ESR=%.4f, cov=%.1f%%, resets=%d\n", ...
        methods(mi), nrmC, nrmR, covS, o.resets);
end

T = cell2table(rows, "VariableNames", ["scenario","method", ...
    "C_metric_percent","ESR_metric_percent","conv_or_recovery_cycles", ...
    "joint_coverage_percent","supervisor_resets"]);
writetable(T, fullfile(tableDir, "table_hybrid_prototype.csv"));
summary = struct("kR", kR, "table", T);
end

function cfg = baseConfig()
p = struct("Vin",24,"D",0.40,"fs",50e3,"L1",500e-6,"L2",500e-6, ...
    "C1",100e-6,"ESR",50e-3,"Co",470e-6,"Rload",10);
p.Ts = 1/p.fs;
cfg = struct("p", p, "samplesPerPeriod", 200, ...
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
