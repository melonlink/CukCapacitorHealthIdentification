function [seedTable, summaryTable] = v23_device_monte_carlo(caseTable, cfg)
%V23_DEVICE_MONTE_CARLO Propagate F28379D/AFE nonidealities for 200 seeds.
%   The repeated common-mode transient is once-calibrated; the configured
%   residual is applied after calibration rather than assuming infinite CMRR.

cases = cfg.validationCases;
nSeeds = cfg.mcSeeds;
nCases = numel(cases);
n = nSeeds * nCases;
caseName = strings(n, 1);
seed = zeros(n, 1);
Ctrue = zeros(n, 1);
ESRtrue = zeros(n, 1);
Chat = zeros(n, 1);
ESRhat = zeros(n, 1);
Cerror = zeros(n, 1);
ESRerror = zeros(n, 1);
Ccovered = false(n, 1);
ESRcovered = false(n, 1);
enob = zeros(n, 1);
cmrrEdge = zeros(n, 1);
vrefNoiseUv = zeros(n, 1);
clockJitterNs = zeros(n, 1);
failCause = strings(n, 1);

row = 0;
for c = 1:nCases
    spec = cases(c);
    b = caseTable(caseTable.operating_case == spec.baseCase, :);
    assert(height(b) == 1, "v23:MissingBaseCase");
    cTrue = cfg.C0 * spec.cFactor;
    rTrue = cfg.ESR0 * spec.esrFactor;
    zCplant = b.Q_safe_C / cTrue;
    zRplant = b.I_sum_edge_A * rTrue;
    cmStep = max(abs([b.plant_vCM_min_V b.plant_vCM_max_V]));
    for s = 1:nSeeds
        row = row + 1;
        rng(cfg.randomSeedBase + 1000 * c + s, "twister");
        thisEnob = min(cfg.enobTypical, max(12.5, ...
            cfg.enobDesign + .35 * randn));
        thisCmrr = cfg.cmrrEdgeDb + 2 * randn;
        thisVrefNoise = max(.25, 10 * exp(.35 * randn));
        thisJitter = max(.2, 2 * exp(.25 * randn));

        % Plant-to-ADC differential gains: Vabs 0.05 V/V, Vedge 1 V/V,
        % and current 0.2 V/A. Noise is converted back to plant units.
        lsbDiff = 2 * cfg.vrefHighV / (2^cfg.adcBits - 1);
        qNoiseV = 2 * cfg.vrefHighV / (sqrt(12) * 2^thisEnob);
        adcNoiseV = hypot(qNoiseV, 100e-6);
        avgNoiseV = adcNoiseV / sqrt(cfg.cyclesPerEstimate);
        vrefNoiseV = thisVrefNoise * 1e-6 / sqrt(cfg.cyclesPerEstimate);

        % Cal3 requirement: multi-point offset/linearity calibration and
        % simultaneous current/voltage gain calibration at production test.
        gAbs = 1 + .0030 * randn;
        gEdge = 1 + .0070 * randn;
        gCurrent = 1 + .0025 * randn;
        krResidual = 1 + .0030 * randn;
        offsetAbsPlant = .05 * lsbDiff / .05 * randn;
        offsetEdgePlant = .05 * lsbDiff * randn;
        inlAbsPlant = .05 * 3 * lsbDiff / .05 * (2 * rand - 1);
        inlEdgePlant = .05 * 3 * lsbDiff * (2 * rand - 1);

        cmLeakRaw = cmStep / 10^(thisCmrr / 20);
        cmLeakResidual = cfg.cmrrSynchronousCalibrationResidual * ...
            cmLeakRaw * randn;
        timingNoise = b.edge_slope_V_per_s * thisJitter * 1e-9 / ...
            sqrt(2 * cfg.pointsPerSide * cfg.cyclesPerEstimate) * randn;

        zCmeas = zCplant * gAbs + offsetAbsPlant + inlAbsPlant + ...
            hypot(avgNoiseV / .05, vrefNoiseV / .05) * randn;
        qMeas = b.Q_safe_C * gCurrent * (1 + .0015 * randn);
        zRmeas = zRplant * gEdge * krResidual + offsetEdgePlant + ...
            inlEdgePlant + cmLeakResidual + timingNoise + ...
            hypot(avgNoiseV, vrefNoiseV) * randn;
        iMeas = b.I_sum_edge_A * gCurrent * (1 + .0015 * randn);
        cHat = qMeas / max(zCmeas, eps);
        rHat = zRmeas / max(iMeas, eps);

        absOffsetStd = .05 * lsbDiff / .05;
        absInlStd = .05 * 3 * lsbDiff / .05 / sqrt(3);
        absGainStd = hypot(.0030, hypot(.0025, .0015));
        sigmaRelC = 1.10 * hypot(absGainStd, hypot(avgNoiseV / .05 / zCplant, ...
            hypot(absOffsetStd / zCplant, absInlStd / zCplant)));
        sigmaRelR = 1.10 * hypot(.010, hypot(avgNoiseV / zRplant, ...
            cfg.cmrrSynchronousCalibrationResidual * cmLeakRaw / zRplant));
        cHalf = 1.96 * sigmaRelC * cHat;
        rHalf = 1.96 * sigmaRelR * rHat;
        cErr = 100 * abs(cHat - cTrue) / cTrue;
        rErr = 100 * abs(rHat - rTrue) / rTrue;

        caseName(row) = spec.name;
        seed(row) = s;
        Ctrue(row) = cTrue;
        ESRtrue(row) = rTrue;
        Chat(row) = cHat;
        ESRhat(row) = rHat;
        Cerror(row) = cErr;
        ESRerror(row) = rErr;
        Ccovered(row) = abs(cHat - cTrue) <= cHalf;
        ESRcovered(row) = abs(rHat - rTrue) <= rHalf;
        enob(row) = thisEnob;
        cmrrEdge(row) = thisCmrr;
        vrefNoiseUv(row) = thisVrefNoise;
        clockJitterNs(row) = thisJitter;
        failCause(row) = local_cause(cErr, rErr, cmLeakResidual, ...
            zRplant, cfg);
    end
end

seedTable = table(caseName, seed, Ctrue, ESRtrue, Chat, ESRhat, ...
    Cerror, ESRerror, Ccovered, ESRcovered, enob, cmrrEdge, ...
    vrefNoiseUv, clockJitterNs, failCause, VariableNames=[ ...
    "validation_case" "seed" "C_true_F" "ESR_true_Ohm" ...
    "C_hat_F" "ESR_hat_Ohm" "C_abs_error_percent" ...
    "ESR_abs_error_percent" "C_CI95_covered" "ESR_CI95_covered" ...
    "ENOB" "effective_edge_CMRR_dB" "VREF_noise_uV_rms" ...
    "clock_jitter_ns_rms" "failure_cause"]);

[group, validationCase] = findgroups(seedTable.validation_case);
GroupCount = splitapply(@numel, seedTable.seed, group);
mean_C_abs_error_percent = splitapply(@mean, seedTable.C_abs_error_percent, group);
median_C_abs_error_percent = splitapply(@median, seedTable.C_abs_error_percent, group);
p95_C_abs_error_percent = splitapply(@(x) prctile(x, 95), ...
    seedTable.C_abs_error_percent, group);
p99_C_abs_error_percent = splitapply(@(x) prctile(x, 99), ...
    seedTable.C_abs_error_percent, group);
max_C_abs_error_percent = splitapply(@max, seedTable.C_abs_error_percent, group);
mean_ESR_abs_error_percent = splitapply(@mean, seedTable.ESR_abs_error_percent, group);
median_ESR_abs_error_percent = splitapply(@median, seedTable.ESR_abs_error_percent, group);
p95_ESR_abs_error_percent = splitapply(@(x) prctile(x, 95), ...
    seedTable.ESR_abs_error_percent, group);
p99_ESR_abs_error_percent = splitapply(@(x) prctile(x, 99), ...
    seedTable.ESR_abs_error_percent, group);
max_ESR_abs_error_percent = splitapply(@max, seedTable.ESR_abs_error_percent, group);
mean_C_CI95_covered = splitapply(@mean, seedTable.C_CI95_covered, group);
mean_ESR_CI95_covered = splitapply(@mean, seedTable.ESR_CI95_covered, group);
pass_fraction = splitapply(@(c, r) mean(c < cfg.cMapeLimitPercent & ...
    r < cfg.esrMapeLimitPercent), seedTable.C_abs_error_percent, ...
    seedTable.ESR_abs_error_percent, group);
summaryTable = table(validationCase, GroupCount, mean_C_abs_error_percent, ...
    median_C_abs_error_percent, p95_C_abs_error_percent, ...
    p99_C_abs_error_percent, max_C_abs_error_percent, ...
    mean_ESR_abs_error_percent, median_ESR_abs_error_percent, ...
    p95_ESR_abs_error_percent, p99_ESR_abs_error_percent, ...
    max_ESR_abs_error_percent, mean_C_CI95_covered, ...
    mean_ESR_CI95_covered, pass_fraction, ...
    VariableNames=["validation_case" "GroupCount" ...
    "mean_C_abs_error_percent" "median_C_abs_error_percent" ...
    "p95_C_abs_error_percent" "p99_C_abs_error_percent" ...
    "max_C_abs_error_percent" "mean_ESR_abs_error_percent" ...
    "median_ESR_abs_error_percent" "p95_ESR_abs_error_percent" ...
    "p99_ESR_abs_error_percent" "max_ESR_abs_error_percent" ...
    "mean_C_CI95_covered" "mean_ESR_CI95_covered" "pass_fraction"]);
end

function cause = local_cause(cErr, rErr, cmResidual, zR, cfg)
if cErr < cfg.cMapeLimitPercent && rErr < cfg.esrMapeLimitPercent
    cause = "PASS";
elseif cErr >= cfg.cMapeLimitPercent && rErr >= cfg.esrMapeLimitPercent
    cause = "C_AND_ESR_CHAIN";
elseif cErr >= cfg.cMapeLimitPercent
    cause = "C_GAIN_REFERENCE_CHAIN";
elseif abs(cmResidual) / zR > .02
    cause = "ESR_COMMON_MODE_RESIDUAL";
else
    cause = "ESR_GAIN_TIMING_CHAIN";
end
end
