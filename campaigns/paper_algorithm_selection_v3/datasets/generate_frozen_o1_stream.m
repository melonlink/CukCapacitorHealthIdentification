function obs = generate_frozen_o1_stream(spec, cfg)
%GENERATE_FROZEN_O1_STREAM Common topology-decoupled O1 observation stream.
% FULL_SWITCHING_MODEL_A_EQUATIONS resolves every switching pair.
% TRACE_DERIVED_OBSERVATION uses information-equivalent grouped samples.

arguments
    spec (1, 1) struct
    cfg (1, 1) struct
end

totalCycles = max(2, round(spec.duration_s * cfg.fs));
groupSize = selectGroupSize(spec, totalCycles);
starts = (1:groupSize:totalCycles).';
ends = min(starts + groupSize - 1, totalCycles);
groupCycles = ends - starts + 1;
cycle = ends;
timeS = cycle / cfg.fs;
centerCycle = 0.5 * (starts + ends);
phase = 2 * pi * centerCycle / 37 + 0.17 * spec.duty0;

[Ctruth, Rtruth, loadFactor, Vin, duty] = trajectoryTruth(spec, timeS, cfg);
alphaTruth = cfg.Cb ./ Ctruth;
currentScale = cfg.modelBCurrentReference .* loadFactor .* (Vin / 24) .* ...
    (0.72 + 1.35 .* duty) / (0.72 + 1.35 * 0.45);
iSum = currentScale .* ...
    (1 + 0.13 * sin(phase) + 0.04 * sin(3 * phase + 0.5));
iSum = max(iSum, 0.12);

if spec.source_model == "FULL_SWITCHING_MODEL_A_EQUATIONS"
    iCapMagnitude = currentScale .* ...
        (0.78 + 0.18 * sin(4 * phase + 0.1));
    qSafe = iCapMagnitude * cfg.safeWindowS .* ...
        (1 + 0.04 * cos(2 * phase));
    hC = max(abs(qSafe / cfg.Cb), 0.012);
else
    hC = sqrt(loadFactor) .* (0.040 + 0.025 .* duty) .* ...
        (1 + 0.38 * sin(phase + 0.3) + ...
        0.08 * cos(5 * phase));
    hC = max(abs(hC), 0.012);
end
kR = cfg.kRCalibration + cfg.kRSeedAmplitude * ...
    sin(2 * pi * double(spec.seed) / 17);
hR = kR .* iSum;

acceptedCCount = ceil(groupCycles / 2);
acceptedRCount = floor(groupCycles / 2);
acceptedRCount(acceptedRCount == 0) = 1;
[sigmaV, sigmaI] = noiseBudget(spec.noise_profile, cfg, numel(timeS));
baseRC = max(2 * sigmaV.^2, 1e-8);
baseRR = max(2 * sigmaV.^2 + (sigmaI .* Rtruth).^2, 1e-8);
RC = baseRC ./ acceptedCCount;
RR = baseRR ./ acceptedRCount;

rng(spec.seed, "twister");
common = randn(numel(timeS), 1);
noiseC = sqrt(RC) .* (0.72 * common + ...
    sqrt(1 - 0.72^2) * randn(numel(timeS), 1));
noiseR = sqrt(RR) .* (0.54 * common + ...
    sqrt(1 - 0.54^2) * randn(numel(timeS), 1));
modelC = (0.0018 + 0.0012 * abs(duty - 0.48)) .* ...
    hC .* sin(2 * phase + 0.2);
residualSkew = cfg.modelBEdgeSlopeReference .* (Vin / 24) .* ...
    sin(phase + 0.7) .* spec.skew_ns * 1e-9;
[transientBiasC, transientBiasR] = operatingTransientBias( ...
    spec, timeS, hC, hR, cfg);

zC = hC .* alphaTruth + modelC + residualSkew * 0.05 + ...
    transientBiasC + noiseC;
zR = hR .* Rtruth + residualSkew + transientBiasR + noiseR;
validC = acceptedCCount > 0 & loadFactor >= 0.20;
validR = acceptedRCount > 0 & loadFactor >= 0.20 & iSum >= 0.12;

frame = floor(cycle / cfg.healthFrameCycles);
reportMask = [false; diff(frame) > 0];
reportMask(end) = true;
streamId = sprintf("O1-%s-%s-%s-%.6g-%s-%dns-%d", ...
    spec.case_id, spec.trajectory_type, spec.shape, spec.duration_s, ...
    spec.noise_profile, spec.skew_ns, spec.seed);

obs = struct( ...
    "stream_id", string(streamId), ...
    "case_id", string(spec.case_id), ...
    "source_model", string(spec.source_model), ...
    "trajectory_type", string(spec.trajectory_type), ...
    "trajectory_duration_s", spec.duration_s, ...
    "shape", string(spec.shape), ...
    "noise_profile", string(spec.noise_profile), ...
    "skew_ns", spec.skew_ns, ...
    "seed", spec.seed, ...
    "time_s", timeS, ...
    "cycle", cycle, ...
    "group_cycles", groupCycles, ...
    "hC", hC, ...
    "hR", hR, ...
    "zC", zC, ...
    "zR", zR, ...
    "RC", RC, ...
    "RR", RR, ...
    "sigmaV", sigmaV, ...
    "sigmaI", sigmaI, ...
    "validC", validC, ...
    "validR", validR, ...
    "accepted_C_count", acceptedCCount, ...
    "accepted_R_count", acceptedRCount, ...
    "reportMask", reportMask, ...
    "Ctruth", Ctruth, ...
    "Rtruth", Rtruth, ...
    "alphaTruth", alphaTruth, ...
    "load_factor", loadFactor, ...
    "Vin_V", Vin, ...
    "duty", duty, ...
    "Cinit", spec.Cinit_factor * Ctruth(1), ...
    "Rinit", spec.Rinit_factor * Rtruth(1), ...
    "health_report_period_s", cfg.healthFrameCycles / cfg.fs);
end

function groupSize = selectGroupSize(spec, totalCycles)
if isfield(spec, "group_cycles") && spec.group_cycles > 0
    groupSize = spec.group_cycles;
elseif spec.source_model == "FULL_SWITCHING_MODEL_A_EQUATIONS"
    groupSize = 2;
else
    groupSize = max(2, 2 * ceil(totalCycles / 40000 / 2));
end
groupSize = max(2, 2 * round(groupSize / 2));
end

function [C, R, loadFactor, Vin, duty] = trajectoryTruth(spec, timeS, cfg)
n = numel(timeS);
C = cfg.Cb * ones(n, 1);
R = cfg.Rb * ones(n, 1);
loadFactor = spec.load0 * ones(n, 1);
Vin = spec.Vin0 * ones(n, 1);
duty = spec.duty0 * ones(n, 1);
xi = min(max(timeS / max(spec.duration_s, eps), 0), 1);
if spec.shape == "smooth"
    progress = 3 * xi.^2 - 2 * xi.^3;
else
    progress = xi;
end

switch spec.trajectory_type
    case "C_ramp"
        C = cfg.Cb .* (1 - 0.20 * progress);
    case "ESR_ramp"
        R = cfg.Rb .* (1 + progress);
    case "joint_ramp"
        C = cfg.Cb .* (1 - 0.20 * progress);
        R = cfg.Rb .* (1 + progress);
    case {"C_abrupt", "ESR_abrupt", "joint_abrupt"}
        changed = timeS >= spec.change_time_s;
        if ismember(spec.trajectory_type, ["C_abrupt", "joint_abrupt"])
            C(changed) = 0.8 * cfg.Cb;
        end
        if ismember(spec.trajectory_type, ["ESR_abrupt", "joint_abrupt"])
            R(changed) = 2 * cfg.Rb;
        end
    case "load_up"
        changed = timeS >= spec.change_time_s;
        loadFactor(~changed) = 0.25;
        loadFactor(changed) = 0.75;
    case "load_down"
        changed = timeS >= spec.change_time_s;
        loadFactor(~changed) = 1.00;
        loadFactor(changed) = 0.50;
    case "Vin_step"
        changed = timeS >= spec.change_time_s;
        Vin(~changed) = 0.8 * spec.Vin0;
        Vin(changed) = 1.2 * spec.Vin0;
    case "duty_step"
        changed = timeS >= spec.change_time_s;
        duty(~changed) = 0.35;
        duty(changed) = 0.60;
end
end

function [sigmaV, sigmaI] = noiseBudget(name, cfg, n)
index = find(cfg.noiseNames == name, 1, "first");
assert(~isempty(index), "algsel:NoiseProfile", ...
    "Unknown noise profile %s.", name);
sigmaV = repmat(cfg.sigmaV(index), n, 1);
sigmaI = repmat(cfg.sigmaI(index), n, 1);
end

function [biasC, biasR] = operatingTransientBias(spec, timeS, hC, hR, cfg)
biasC = zeros(size(timeS));
biasR = zeros(size(timeS));
isOperating = ismember(spec.trajectory_type, ...
    ["load_up", "load_down", "Vin_step", "duty_step"]);
if ~isOperating
    return;
end
elapsed = timeS - spec.change_time_s;
active = elapsed >= 0;
envelope = zeros(size(timeS));
envelope(active) = exp(-elapsed(active) / 8e-4);
ring = zeros(size(timeS));
ring(active) = sin(2 * pi * elapsed(active) / 2.5e-4);
switch spec.trajectory_type
    case {"load_up", "load_down"}
        scaleC = 0.10;
        scaleR = 0.32;
    case "Vin_step"
        scaleC = 0.08;
        scaleR = 0.25;
    otherwise
        scaleC = 0.07;
        scaleR = 0.22;
end
biasC = scaleC .* hC .* envelope .* ring;
biasR = scaleR .* hR .* cfg.Rb .* envelope .* ring;
end
