function F = simulate_cuk_features(cfg)
%SIMULATE_CUK_FEATURES Cycle-resolved Model-A run returning O1 features only.
%   Estimator-free variant of the closed-loop supplement simulator: it
%   integrates the ideal-parasitic switched Cuk equations (transfer-
%   capacitor ESR retained), forms the timestamp-reconstructed edge row and
%   the safe-window charge primitives per cycle from noisy samples, applies
%   the physical validity gates, and returns the feature stream so that
%   several estimators can be run on identical data. Supports abrupt health
%   steps and linear health ramps.

p = cfg.p;
spp = cfg.samplesPerPeriod;
dt = p.Ts / spp;
nCycles = cfg.nCycles;
nSamples = nCycles * spp + 1;
rng(cfg.seed, "twister");

% Health truth schedules (per cycle).
Ctrue = cfg.Ctrue * ones(nCycles, 1);
Rtruth = cfg.ESRtrue * ones(nCycles, 1);
if isfield(cfg, "CStepCycle")
    Ctrue(cfg.CStepCycle:end) = cfg.CStepValue;
end
if isfield(cfg, "RStepCycle")
    Rtruth(cfg.RStepCycle:end) = cfg.RStepValue;
end
if isfield(cfg, "CRamp")   % [startCycle endCycle finalValue]
    k0 = cfg.CRamp(1); k1 = cfg.CRamp(2);
    ramp = linspace(cfg.Ctrue, cfg.CRamp(3), k1 - k0 + 1)';
    Ctrue(k0:k1) = ramp; Ctrue(k1:end) = cfg.CRamp(3);
end
if isfield(cfg, "RRamp")
    k0 = cfg.RRamp(1); k1 = cfg.RRamp(2);
    ramp = linspace(cfg.ESRtrue, cfg.RRamp(3), k1 - k0 + 1)';
    Rtruth(k0:k1) = ramp; Rtruth(k1:end) = cfg.RRamp(3);
end

vOut0 = p.D / (1 - p.D) * p.Vin;
x = [p.D/(1-p.D)*(vOut0/p.Rload); vOut0/p.Rload; p.Vin/(1-p.D); vOut0];
i1 = zeros(nSamples, 1); i2 = zeros(nSamples, 1);
vC = zeros(nSamples, 1); vo = zeros(nSamples, 1);
uSig = zeros(nSamples, 1);
i1(1) = x(1); i2(1) = x(2); vC(1) = x(3); vo(1) = x(4);
t = (0:nSamples-1)' * dt;
nOn = round(p.D * spp);

for k = 1:nCycles
    base = (k-1) * spp;
    local = p; local.C1 = Ctrue(k); local.ESR = Rtruth(k);
    for i = 1:spp
        uk = double(i <= nOn);
        uSig(base+i) = uk;
        k1r = deriv(x, uk, local);
        k2r = deriv(x + 0.5*dt*k1r, uk, local);
        k3r = deriv(x + 0.5*dt*k2r, uk, local);
        k4r = deriv(x + dt*k3r, uk, local);
        x = x + dt * (k1r + 2*k2r + 2*k3r + k4r) / 6;
        i1(base+i+1) = x(1); i2(base+i+1) = x(2);
        vC(base+i+1) = x(3); vo(base+i+1) = x(4);
    end
end

i1m = i1 + cfg.sigmaI * randn(nSamples, 1);
i2m = i2 + cfg.sigmaI * randn(nSamples, 1);
iC = (1 - uSig) .* i1 - uSig .* i2;
vT = vC + Rtruth(min(ceil((1:nSamples)'/spp), nCycles)) .* iC;
vTm = vT + cfg.sigmaV * randn(nSamples, 1);
iCm = (1 - uSig) .* i1m - uSig .* i2m;

guard = round(cfg.guardS / dt);
fitLen = round(cfg.edgeWindowS / dt);
chargeLen = round(cfg.chargeWindowS / dt);

F = struct("nCycles", nCycles, "Ctrue", Ctrue, "Rtruth", Rtruth, ...
    "validR", false(nCycles,1), "zR", NaN(nCycles,1), "Isum", NaN(nCycles,1), ...
    "validC", false(nCycles,1), "q", NaN(nCycles,1), ...
    "dvT", NaN(nCycles,1), "diC", NaN(nCycles,1), "ccm", true(nCycles,1));

for k = 2:nCycles
    base = (k-1) * spp;
    idxE = base + 1;
    span = max(base - spp + 1, 1):min(base + spp, nSamples);
    F.ccm(k) = all(i1(span) + i2(span) > 0);

    preIdx = (idxE - guard - fitLen):(idxE - guard - 1);
    postIdx = (idxE + guard):(idxE + guard + fitLen - 1);
    if preIdx(1) >= 1 && all(uSig(preIdx) == 0) && all(uSig(postIdx) == 1) ...
            && F.ccm(k)
        te = t(idxE);
        cPre = polyfit(t(preIdx) - te, vTm(preIdx), 1);
        cPost = polyfit(t(postIdx) - te, vTm(postIdx), 1);
        cI1 = polyfit(t(preIdx) - te, i1m(preIdx), 1);
        cI2 = polyfit(t(postIdx) - te, i2m(postIdx), 1);
        Isum = cI1(2) + cI2(2);
        if Isum >= cfg.IsumGate
            F.validR(k) = true;
            F.zR(k) = cPre(2) - cPost(2);
            F.Isum(k) = Isum;
        end
    end

    aIdx = base + nOn + guard;
    bIdx = aIdx + chargeLen;
    if bIdx <= base + spp && F.ccm(k) && all(uSig(aIdx:bIdx) == 0)
        F.validC(k) = true;
        F.q(k) = trapz(t(aIdx:bIdx), iCm(aIdx:bIdx));
        F.dvT(k) = vTm(bIdx) - vTm(aIdx);
        F.diC(k) = iCm(bIdx) - iCm(aIdx);
    end
end
end

function dx = deriv(x, u, p)
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
