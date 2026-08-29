function out = simulate_cuk_cycles_srke(cfg)
%SIMULATE_CUK_CYCLES_SRKE Cycle-resolved closed-loop run with TS-SRKE.
%   OUT = SIMULATE_CUK_CYCLES_SRKE(CFG) integrates the ideal-parasitic
%   switched Cuk equations (transfer-capacitor ESR retained) cycle by
%   cycle under the discrete PI voltage regulator of the frozen
%   closed-loop supplement, forms the O1 edge and charge rows from noisy
%   samples with the predeclared validity gates, and runs the
%   direction-wise scalar LTV/Joseph kernel with the frozen two-time-scale
%   supervisor (TS-SRKE). Setting CFG.supervisorEnabled = false runs the
%   identical kernel without the supervisor (the unsupervised parent) on
%   the same noise realization.
%
%   Plant, regulator, gates, and feature construction match
%   campaigns/closedloop_dcm_validation/scripts/simulate_cuk_cycles.m;
%   the estimator block is the only difference. Supervisor and kernel
%   constants are the frozen v13/selection-v3 values. No frozen artifact
%   is modified; this is a supplementary evaluation harness.

p = cfg.p;
spp = cfg.samplesPerPeriod;
dt = p.Ts / spp;
nCycles = cfg.nCycles;
nSamples = nCycles * spp + 1;
rng(cfg.seed, "twister");

% --- Truth schedules (per cycle), including abrupt health steps. ---
Ctrue = cfg.Ctrue * ones(nCycles, 1);
Rtruth = cfg.ESRtrue * ones(nCycles, 1);
Rload = p.Rload * ones(nCycles, 1);
Vin = p.Vin * ones(nCycles, 1);
Vref = cfg.Vref * ones(nCycles, 1);
if isfield(cfg, "loadStepCycle")
    Rload(cfg.loadStepCycle:end) = cfg.loadStepValue;
end
if isfield(cfg, "vinStepCycle")
    Vin(cfg.vinStepCycle:end) = cfg.vinStepValue;
end
if isfield(cfg, "vrefStepCycle")
    Vref(cfg.vrefStepCycle:end) = cfg.vrefStepValue;
end
if isfield(cfg, "cStepCycle")
    Ctrue(cfg.cStepCycle:end) = cfg.cStepFactor * cfg.Ctrue;
end
if isfield(cfg, "esrStepCycle")
    Rtruth(cfg.esrStepCycle:end) = cfg.esrStepFactor * cfg.ESRtrue;
end

% --- State and waveform storage. ---
vOut0 = p.D / (1 - p.D) * p.Vin;
x = [p.D/(1-p.D)*(vOut0/p.Rload); vOut0/p.Rload; p.Vin/(1-p.D); vOut0];
i1 = zeros(nSamples, 1); i2 = zeros(nSamples, 1);
vC = zeros(nSamples, 1); vo = zeros(nSamples, 1);
uSig = zeros(nSamples, 1);
i1(1) = x(1); i2(1) = x(2); vC(1) = x(3); vo(1) = x(4);
t = (0:nSamples-1)' * dt;

% --- Regulator state. ---
integ = 0;
Dhist = zeros(nCycles, 1);

guard = round(cfg.guardS / dt);
fitLen = round(cfg.edgeWindowS / dt);
chargeLen = round(cfg.chargeWindowS / dt);

% --- TS-SRKE state (frozen kernel and supervisor constants). ---
theta = [cfg.Cb / cfg.Cinit; cfg.Rinit];
P0 = [cfg.ltvP0Alpha; (cfg.ltvP0RScale * cfg.ESRtrue)^2];
P = P0;                                   % per-direction scalar variances
RC = max(2 * cfg.sigmaV^2, 1e-8);
RR = max(2 * cfg.sigmaV^2 + (cfg.sigmaI * cfg.ESRtrue)^2, 1e-8);
sup = struct("mFast", [0; 0], "mSlow", [0; 0], "rows", [0; 0], ...
    "holdoff", [0; 0], "fires", [0; 0], "firstFire", [NaN; NaN]);

est = struct("C", zeros(nCycles,1), "ESR", zeros(nCycles,1), ...
    "validC", false(nCycles,1), "validR", false(nCycles,1), ...
    "ccm", true(nCycles,1), "fireC", false(nCycles,1), ...
    "fireR", false(nCycles,1), "D", zeros(nCycles,1), ...
    "voCycle", zeros(nCycles,1));

% --- Plant integration, one switching period per regulator update. ---
for k = 1:nCycles
    base = (k-1) * spp;
    voMeas = x(4) + cfg.sigmaV * randn;
    e = Vref(k) - voMeas;
    integ = integ + e * p.Ts;
    D = min(max(cfg.D0 + cfg.Kp*e + cfg.Ki*integ, cfg.Dmin), cfg.Dmax);
    nOn = min(max(round(D * spp), round(cfg.Dmin*spp)), round(cfg.Dmax*spp));
    Dhist(k) = nOn / spp;

    local = p; local.C1 = Ctrue(k); local.ESR = Rtruth(k);
    local.Rload = Rload(k); local.Vin = Vin(k);
    for i = 1:spp
        uk = double(i <= nOn);
        uSig(base+i) = uk;
        k1 = deriv(x, uk, local);
        k2 = deriv(x + 0.5*dt*k1, uk, local);
        k3 = deriv(x + 0.5*dt*k2, uk, local);
        k4 = deriv(x + dt*k3, uk, local);
        x = x + dt * (k1 + 2*k2 + 2*k3 + k4) / 6;
        i1(base+i+1) = x(1); i2(base+i+1) = x(2);
        vC(base+i+1) = x(3); vo(base+i+1) = x(4);
    end
    est.D(k) = Dhist(k); est.voCycle(k) = voMeas;
end

% --- Measured signals (shared noise realization). ---
i1m = i1 + cfg.sigmaI * randn(nSamples, 1);
i2m = i2 + cfg.sigmaI * randn(nSamples, 1);
iC = (1 - uSig) .* i1 - uSig .* i2;
vT = vC + Rtruth(min(ceil((1:nSamples)'/spp), nCycles)) .* iC;
vTm = vT + cfg.sigmaV * randn(nSamples, 1);
iCm = (1 - uSig) .* i1m - uSig .* i2m;

% --- Per-cycle O1 features and supervised Joseph updates. ---
for k = 2:nCycles
    base = (k-1) * spp;
    idxE = base + 1;                      % u:0->1 edge at cycle start
    nOnPrev = round(est.D(k-1) * spp);
    nOn = round(est.D(k) * spp);
    span = max(base - spp + 1, 1):min(base + spp, nSamples);
    est.ccm(k) = all(i1(span) + i2(span) > 0);

    % Edge row: guarded pre/post linear fits extrapolated to the edge time.
    preIdx = (idxE - guard - fitLen):(idxE - guard - 1);
    postIdx = (idxE + guard):(idxE + guard + fitLen - 1);
    okPre = preIdx(1) >= 1 && all(uSig(preIdx) == 0) ...
        && preIdx(1) > base - spp + nOnPrev;
    okPost = all(uSig(postIdx) == 1);
    if okPre && okPost && est.ccm(k)
        te = t(idxE);
        cPre = polyfit(t(preIdx) - te, vTm(preIdx), 1);
        cPost = polyfit(t(postIdx) - te, vTm(postIdx), 1);
        zR = cPre(2) - cPost(2);
        cI1 = polyfit(t(preIdx) - te, i1m(preIdx), 1);
        cI2 = polyfit(t(postIdx) - te, i2m(postIdx), 1);
        Isum = cI1(2) + cI2(2);
        if Isum >= cfg.IsumGate
            est.validR(k) = true;
            [theta(2), P(2), sup, fired] = supervisedUpdate( ...
                2, zR, cfg.kR * Isum, RR, theta(2), P(2), ...
                cfg.ltvQ(2), P0(2), sup, cfg, k);
            est.fireR(k) = fired;
        end
    end

    % Charge row: guarded safe window wholly inside the current off-state.
    aIdx = base + nOn + guard;
    bIdx = aIdx + chargeLen;
    if bIdx <= base + spp && est.ccm(k) && all(uSig(aIdx:bIdx) == 0)
        q = trapz(t(aIdx:bIdx), iCm(aIdx:bIdx));
        dvT = vTm(bIdx) - vTm(aIdx);
        diC = iCm(bIdx) - iCm(aIdx);
        if abs(q) > 0
            est.validC(k) = true;
            zC = dvT - theta(2) * diC;
            [theta(1), P(1), sup, fired] = supervisedUpdate( ...
                1, zC, q / cfg.Cb, RC, theta(1), P(1), ...
                cfg.ltvQ(1), P0(1), sup, cfg, k);
            est.fireC(k) = fired;
        end
    end

    % Predeclared projection bounds.
    theta(1) = min(max(theta(1), cfg.Cb/cfg.CBounds(2)), cfg.Cb/cfg.CBounds(1));
    theta(2) = min(max(theta(2), cfg.RBounds(1)), cfg.RBounds(2));
    est.C(k) = cfg.Cb / theta(1);
    est.ESR(k) = theta(2);
end
est.C(1) = cfg.Cinit; est.ESR(1) = cfg.Rinit;

out = struct("est", est, "Dhist", Dhist, "sup", sup, ...
    "Ctrue", Ctrue, "ESRtrue", Rtruth, "Rload", Rload, "Vin", Vin, ...
    "cfg", cfg);
end

function [th, Pd, sup, fired] = supervisedUpdate(d, z, h, Rm, th, Pd, ...
    Qd, P0d, sup, cfg, k)
%SUPERVISEDUPDATE One scalar Joseph update with the two-time-scale supervisor.
%   Direction D processes measurement Z with regressor H and variance RM.
%   The supervisor watches the clipped normalized innovation of EVERY
%   valid row (accepted or NIS-rejected); after the warm-up row count it
%   resets the direction variance to its initialization value when the
%   fast/slow EWMA difference exceeds the predeclared threshold.
fired = false;
Pd = Pd + Qd;
S = h^2 * Pd + Rm;
eps = (z - h * th) / sqrt(S);

if cfg.supervisorEnabled
    epsc = min(max(eps, -cfg.supClip), cfg.supClip);
    sup.mFast(d) = sup.mFast(d) + cfg.supFastRate * (epsc - sup.mFast(d));
    sup.mSlow(d) = sup.mSlow(d) + cfg.supSlowRate * (epsc - sup.mSlow(d));
    sup.rows(d) = sup.rows(d) + 1;
    if sup.holdoff(d) > 0
        sup.holdoff(d) = sup.holdoff(d) - 1;
    elseif sup.rows(d) > cfg.supWarmupRows && ...
            abs(sup.mFast(d) - sup.mSlow(d)) > cfg.supThreshold
        Pd = P0d;
        sup.mFast(d) = sup.mSlow(d);
        sup.holdoff(d) = cfg.supHoldoffRows;
        sup.fires(d) = sup.fires(d) + 1;
        if isnan(sup.firstFire(d)), sup.firstFire(d) = k; end
        fired = true;
        S = h^2 * Pd + Rm;                % gain restored for this row
        eps = (z - h * th) / sqrt(S);
    end
end

if eps^2 <= cfg.nisGate
    K = Pd * h / S;
    th = th + K * (z - h * th);
    Pd = (1 - K * h)^2 * Pd + K^2 * Rm;   % scalar Joseph form
end
end

function dx = deriv(x, u, p)
% Ideal-parasitic switched Cuk equations with transfer-capacitor ESR
% (Appendix A of the manuscript; other parasitics zero).
i1 = x(1); i2 = x(2); vC = x(3); vo = x(4);
if u >= 0.5
    di1 = p.Vin / p.L1;
    di2 = (vC - p.ESR*i2 - vo) / p.L2;
    iC = -i2;
else
    di1 = (p.Vin - vC - p.ESR*i1) / p.L1;
    di2 = -vo / p.L2;
    iC = i1;
end
dx = [di1; di2; iC/p.C1; (i2 - vo/p.Rload)/p.Co];
end
