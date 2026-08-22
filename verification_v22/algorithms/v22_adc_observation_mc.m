function metrics = v22_adc_observation_mc(signal, profile, arch, nCycle, ...
        noiseCase, calibration, fusion, nSeed, seedBase, cfg)
%V22_ADC_OBSERVATION_MC Timestamp-aware C/ESR observation Monte Carlo.
%   This is the ADC/AFE outer measurement layer around the v2.1 locked
%   TS-SLTVKE formulation. Model B supplies I_sum, Q, voltage and slope.

cHat = zeros(nSeed, 1);
rHat = zeros(nSeed, 1);
cSigma = zeros(nSeed, 1);
rSigma = zeros(nSeed, 1);
nisC = zeros(nSeed, 1);
nisR = zeros(nSeed, 1);
nees = zeros(nSeed, 1);
coverC = false(nSeed, 1);
coverR = false(nSeed, 1);
accepted = zeros(nSeed, 1);
convergence = zeros(nSeed, 1);
saturation = zeros(nSeed, 1);

for s = 1:nSeed
    rng(seedBase + s, "twister");
    [zC, zR, iSumMeasured, qMeasured, noiseStdC, noiseStdR, sat] = ...
        simulate_cycles(signal, profile, arch, nCycle, noiseCase, ...
        calibration, cfg);
    zCbar = fuse(zC, fusion);
    zRbar = fuse(zR, fusion);
    if calibration.kRCorrected
        kREst = signal.kRTrue * (1 + cfg.kRCalibrationResidual * randn);
    else
        kREst = 1;
    end
    cHat(s) = qMeasured / max(abs(zCbar), eps);
    rHat(s) = abs(zRbar) / max(iSumMeasured * abs(kREst), eps);
    if noiseCase == "Q1_deterministic"
        effectiveN = 1;
    else
        effectiveN = nCycle;
    end
    cRandom = abs(qMeasured / max(zCbar, eps)^2) * noiseStdC / sqrt(effectiveN);
    rRandom = noiseStdR / max(iSumMeasured * abs(kREst), eps) / sqrt(effectiveN);
    cSigma(s) = hypot(cRandom, calibration.systematicFloorC * signal.C);
    rSigma(s) = hypot(rRandom, calibration.systematicFloorR * signal.ESR);
    cResidual = zC - median(zC);
    rResidual = zR - median(zR);
    nisC(s) = mean(cResidual.^2 / max(noiseStdC^2, eps));
    nisR(s) = mean(rResidual.^2 / max(noiseStdR^2, eps));
    nees(s) = ((cHat(s) - signal.C) / max(cSigma(s), eps))^2 + ...
        ((rHat(s) - signal.ESR) / max(rSigma(s), eps))^2;
    coverC(s) = abs(cHat(s) - signal.C) <= 1.96 * cSigma(s);
    coverR(s) = abs(rHat(s) - signal.ESR) <= 1.96 * rSigma(s);
    accepted(s) = sum(abs(rResidual) <= 3.5 * max(noiseStdR, eps));
    cNeed = (1.96 * noiseStdC / max(.03 * abs(signal.zC), eps))^2;
    rNeed = (1.96 * noiseStdR / max(.05 * abs(signal.zR), eps))^2;
    convergence(s) = min(nCycle, max(1, ceil(max(cNeed, rNeed))));
    saturation(s) = sat;
end

cErr = 100 * abs(cHat / signal.C - 1);
rErr = 100 * abs(rHat / signal.ESR - 1);
metrics = struct;
metrics.C_est_F = mean(cHat);
metrics.ESR_est_Ohm = mean(rHat);
metrics.C_MAPE_percent = mean(cErr);
metrics.C_MAPE_p95_percent = prctile(cErr, 95);
metrics.ESR_MAPE_percent = mean(rErr);
metrics.ESR_MAPE_p95_percent = prctile(rErr, 95);
metrics.C_bias_percent = 100 * (mean(cHat) / signal.C - 1);
metrics.ESR_bias_percent = 100 * (mean(rHat) / signal.ESR - 1);
metrics.C_variance = var(cHat, 1);
metrics.ESR_variance = var(rHat, 1);
metrics.NIS_C_mean = mean(nisC);
metrics.NIS_R_mean = mean(nisR);
metrics.NEES_mean = mean(nees);
metrics.CI_C_95_coverage = mean(coverC);
metrics.CI_ESR_95_coverage = mean(coverR);
metrics.convergence_cycles = median(convergence);
metrics.accepted_edge_updates = mean(accepted);
metrics.saturation_fraction = mean(saturation);
metrics.accuracy_pass = metrics.C_MAPE_percent < 3 && ...
    metrics.ESR_MAPE_percent < 5;
metrics.confidence_pass = metrics.CI_C_95_coverage >= .90 && ...
    metrics.CI_ESR_95_coverage >= .90 && metrics.NEES_mean < 5.991;
end

function [zC, zR, iSumMeasured, qMeasured, sigmaC, sigmaR, sat] = ...
        simulate_cycles(signal, profile, arch, nCycle, noiseCase, cal, cfg)
bits = profile.bits;
levels = 2^bits - 1;
cSpan = arch.cHighV - arch.cLowV;
rSpan = arch.rHighV - arch.rLowV;
cLsb = cSpan / levels;
rLsb = rSpan / levels;
if noiseCase == "Q1_deterministic"
    enobC = 0;
    enobR = 0;
    analog = 0;
    fullNonideal = false;
elseif startsWith(noiseCase, "Q2_")
    enobC = cSpan / (sqrt(12) * 2^profile.enob);
    enobR = rSpan / (sqrt(12) * 2^profile.enob);
    analog = str2double(erase(erase(noiseCase, "Q2_"), "mV")) * 1e-3;
    fullNonideal = false;
else
    enobC = cSpan / (sqrt(12) * 2^profile.enob);
    enobR = rSpan / (sqrt(12) * 2^profile.enob);
    analog = 2e-3;
    fullNonideal = true;
end
sigmaC = hypot(enobC, analog);
sigmaR = hypot(enobR, analog);
sigmaI = cfg.currentRangeA / (sqrt(12) * 2^profile.enob);

gainV = cal.gainResidualFraction * randn;
gainI = cal.gainResidualFraction * randn;
offsetCLsb = cal.offsetResidualLsb * randn;
offsetRLsb = cal.offsetResidualLsb * randn;
if fullNonideal
    inl = profile.inlLsb * (2 * rand - 1);
    dnl = profile.dnlLsb * (2 * rand - 1);
    refNoiseC = .25 * cLsb;
    refNoiseR = .25 * rLsb;
    jitterNs = 5;
else
    inl = 0;
    dnl = 0;
    refNoiseC = 0;
    refNoiseR = 0;
    jitterNs = 0;
end

edgePhysical = signal.zR * signal.kRTrue;
timingError = signal.edgeSlopeVPerS * cfg.edgeTimingSensitivity * ...
    (cal.timingResidualNs + jitterNs * randn) * 1e-9 * sign(randn);
settling = cal.settlingResidualFraction * edgePhysical * sign(randn);
if arch.separateEdgeChannel
    rPre = -.5 * edgePhysical * ones(nCycle, 1);
    rPost = .5 * edgePhysical * ones(nCycle, 1) + timingError + settling;
else
    rBase = signal.vBase * ones(nCycle, 1);
    rPre = rBase;
    rPost = rBase + edgePhysical + timingError + settling;
end
cPre = signal.vBase * ones(nCycle, 1);
cPost = cPre + signal.zC;

rPre = rPre + sigmaR * randn(nCycle, 1) + refNoiseR * randn(nCycle, 1);
rPost = rPost + sigmaR * randn(nCycle, 1) + refNoiseR * randn(nCycle, 1);
cPre = cPre + sigmaC * randn(nCycle, 1) + refNoiseC * randn(nCycle, 1);
cPost = cPost + sigmaC * randn(nCycle, 1) + refNoiseC * randn(nCycle, 1);

[rPreQ, sat1] = adc_quantize(rPre, arch.rLowV, arch.rHighV, levels, ...
    gainV, offsetRLsb, inl, dnl);
[rPostQ, sat2] = adc_quantize(rPost, arch.rLowV, arch.rHighV, levels, ...
    gainV, offsetRLsb, inl, dnl);
[cPreQ, sat3] = adc_quantize(cPre, arch.cLowV, arch.cHighV, levels, ...
    gainV, offsetCLsb, inl, dnl);
[cPostQ, sat4] = adc_quantize(cPost, arch.cLowV, arch.cHighV, levels, ...
    gainV, offsetCLsb, inl, dnl);
zR = rPostQ - rPreQ;
zC = cPostQ - cPreQ;

i1 = signal.i1 + sigmaI * randn(nCycle, 1);
i2 = signal.i2 + sigmaI * randn(nCycle, 1);
[i1q, sat5] = adc_quantize(i1, 0, cfg.currentRangeA, levels, ...
    gainI, 0, inl, dnl);
[i2q, sat6] = adc_quantize(i2, 0, cfg.currentRangeA, levels, ...
    gainI, 0, inl, dnl);
iSumMeasured = mean(i1q + i2q);
qMeasured = signal.Q * (1 + gainI) + ...
    signal.Q * sigmaI / max(mean([signal.i1 signal.i2]), eps) / ...
    sqrt(max(nCycle, 1)) * randn;
sat = mean([sat1; sat2; sat3; sat4; sat5; sat6]);
sigmaC = hypot(sqrt(2) * sigmaC, cLsb / sqrt(6));
sigmaR = hypot(sqrt(2) * sigmaR, rLsb / sqrt(6));
end

function [y, saturation] = adc_quantize(x, low, high, levels, gain, ...
        offsetLsb, inl, dnl)
if high - low <= 0
    error("v22:InvalidRange", "ADC high limit must exceed low limit.");
end
saturation = x < low | x > high;
lsb = (high - low) / levels;
xScaled = (x - low) * (1 + gain) / lsb + offsetLsb;
code = round(xScaled);
code = code + round(inl * sin(2 * pi * code / max(levels, 1)) + ...
    dnl * sign(sin(pi * code / 17)));
code = min(max(code, 0), levels);
y = low + code * lsb;
end

function value = fuse(x, fusion)
if fusion == "robust_trimmed_mean" && numel(x) >= 10
    x = sort(x);
    trim = floor(.1 * numel(x));
    value = mean(x(trim + 1:end - trim));
else
    value = mean(x);
end
end
