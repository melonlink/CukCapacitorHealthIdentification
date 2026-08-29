function out = simulate_cuk_cycles(cfg)
%SIMULATE_CUK_CYCLES Cycle-resolved Model-A run with O1 features and TS-D-RLS.
%   OUT = SIMULATE_CUK_CYCLES(CFG) integrates the ideal-parasitic switched
%   Cuk equations (transfer-capacitor ESR retained) cycle by cycle, with a
%   fixed duty ratio (open loop) or a discrete PI voltage regulator updating
%   the duty ratio once per switching period (closed loop). For every cycle
%   it forms the timestamp-reconstructed edge row and the safe-window charge
%   row from noisy samples, applies the predeclared validity gates, and runs
%   the locked direction-specific scalar RLS recursions.
%
%   The plant equations, initial conditions, hyperparameters, gates, and
%   projection bounds match the frozen paper pipeline. No frozen artifact is
%   modified; this is a supplementary evaluation harness.

p = cfg.p;
spp = cfg.samplesPerPeriod;
dt = p.Ts / spp;
nCycles = cfg.nCycles;
nSamples = nCycles * spp + 1;
rng(cfg.seed, "twister");

% Truth schedules (per cycle).
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

% State and waveform storage.
vOut0 = p.D / (1 - p.D) * p.Vin;
x = [p.D/(1-p.D)*(vOut0/p.Rload); vOut0/p.Rload; p.Vin/(1-p.D); vOut0];
i1 = zeros(nSamples, 1); i2 = zeros(nSamples, 1);
vC = zeros(nSamples, 1); vo = zeros(nSamples, 1);
uSig = zeros(nSamples, 1);
i1(1) = x(1); i2(1) = x(2); vC(1) = x(3); vo(1) = x(4);
t = (0:nSamples-1)' * dt;

% Controller state.
D = p.D;
integ = 0;
Dhist = zeros(nCycles, 1);

guard = round(cfg.guardS / dt);
fitLen = round(cfg.edgeWindowS / dt);
chargeLen = round(cfg.chargeWindowS / dt);

% Estimator state (locked TS-D-RLS hyperparameters).
theta = [cfg.Cb / cfg.Cinit; cfg.Rinit];
Pc = cfg.rlsP0; Pr = cfg.rlsP0;
lambda = cfg.rlsLambda;
est = struct("C", zeros(nCycles,1), "ESR", zeros(nCycles,1), ...
    "validC", false(nCycles,1), "validR", false(nCycles,1), ...
    "ccm", true(nCycles,1), "zR", NaN(nCycles,1), "hIsum", NaN(nCycles,1), ...
    "D", zeros(nCycles,1), "voCycle", zeros(nCycles,1));

for k = 1:nCycles
    base = (k-1) * spp;
    % --- Discrete PI voltage regulator (closed loop only). ---
    voMeas = x(4) + cfg.sigmaV * randn;
    if cfg.closedLoop
        e = Vref(k) - voMeas;
        integ = integ + e * p.Ts;
        D = min(max(cfg.D0 + cfg.Kp*e + cfg.Ki*integ, cfg.Dmin), cfg.Dmax);
    end
    nOn = min(max(round(D * spp), round(cfg.Dmin*spp)), round(cfg.Dmax*spp));
    Dhist(k) = nOn / spp;

    % --- Integrate one switching period (RK4, zero-order-held topology). ---
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

% Measured signals (shared noise realization for the whole record).
i1m = i1 + cfg.sigmaI * randn(nSamples, 1);
i2m = i2 + cfg.sigmaI * randn(nSamples, 1);
iC = (1 - uSig) .* i1 - uSig .* i2;
vT = vC + Rtruth(min(ceil((1:nSamples)'/spp), nCycles)) .* iC;
vTm = vT + cfg.sigmaV * randn(nSamples, 1);
iCm = (1 - uSig) .* i1m - uSig .* i2m;

% --- Per-cycle O1 features and locked RLS updates. ---
kRsamples = NaN(nCycles, 1);
for k = 2:nCycles
    base = (k-1) * spp;
    idxE = base + 1;                      % u:0->1 edge at cycle start
    nOnPrev = round(est.D(k-1) * spp);
    nOn = round(est.D(k) * spp);
    % CCM validity: combined inductor current stays positive over the cycle.
    span = max(base - spp + 1, 1):min(base + spp, nSamples);
    est.ccm(k) = all(i1(span) + i2(span) > 0);

    % Edge row: guarded pre/post linear fits extrapolated to the edge time.
    preIdx = (idxE - guard - fitLen):(idxE - guard - 1);
    postIdx = (idxE + guard):(idxE + guard + fitLen - 1);
    okPre = preIdx(1) >= 1 && all(uSig(preIdx) == 0) ...
        && preIdx(1) > base - spp + nOnPrev;    % wholly in previous off-state
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
            est.zR(k) = zR; est.hIsum(k) = Isum;
            kRsamples(k) = zR / (Isum * Rtruth(k));
            h = cfg.kR * Isum;
            Pr = Pr / lambda;
            K = Pr * h / (1 + h^2 * Pr);
            theta(2) = theta(2) + K * (zR - h * theta(2));
            Pr = (1 - K * h) * Pr;
        end
    end

    % Charge row: guarded safe window wholly inside the current off-state.
    aIdx = base + nOn + guard;
    bIdx = aIdx + chargeLen;
    if bIdx <= base + spp && est.ccm(k) && all(uSig(aIdx:bIdx) == 0)
        q = trapz(t(aIdx:bIdx), iCm(aIdx:bIdx));
        dvT = vTm(bIdx) - vTm(aIdx);
        diC = iCm(bIdx) - iCm(aIdx);
        zC = dvT - theta(2) * diC;
        h = q / cfg.Cb;
        if abs(q) > 0
            est.validC(k) = true;
            Pc = Pc / lambda;
            K = Pc * h / (1 + h^2 * Pc);
            theta(1) = theta(1) + K * (zC - h * theta(1));
            Pc = (1 - K * h) * Pc;
        end
    end

    % Predeclared projection bounds.
    theta(1) = min(max(theta(1), cfg.Cb/cfg.CBounds(2)), cfg.Cb/cfg.CBounds(1));
    theta(2) = min(max(theta(2), cfg.RBounds(1)), cfg.RBounds(2));
    est.C(k) = cfg.Cb / theta(1);
    est.ESR(k) = theta(2);
end
est.C(1) = cfg.Cinit; est.ESR(1) = cfg.Rinit;

out = struct("est", est, "Dhist", Dhist, "t", t, "vo", vo, ...
    "Ctrue", Ctrue, "ESRtrue", Rtruth, "Rload", Rload, "Vin", Vin, ...
    "kRsamples", kRsamples, "cfg", cfg);
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
