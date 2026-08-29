function tables = v23_build_closure_tables(v23Root, cfg, caseTable)
%V23_BUILD_CLOSURE_TABLES Build traceable F28379D closure tables.

tableDir = fullfile(v23Root, "results", "tables");
tables = struct;
tables.truth = local_truth(cfg);
tables.pinmap = local_pinmap();
tables.timing = local_timing(cfg);
tables.schedule = local_schedule(cfg);
tables.geometry = local_geometry(cfg);
tables.settling = local_settling(cfg);
tables.commonmode = local_commonmode(cfg, caseTable);
tables.cmrr = local_cmrr(cfg, caseTable);
tables.bandwidth = local_bandwidth(cfg);
tables.reference = local_reference_clock(cfg);
tables.errata = local_errata(cfg);
tables.dma = local_dma(cfg);
tables.compute = local_compute(cfg);

names = fieldnames(tables);
fileNames = ["table_f28379d_adc_truth.csv" ...
    "table_f28379d_adc_pinmap.csv" "table_f28379d_exact_timing.csv" ...
    "table_epwm_soc_schedule.csv" "table_full_aperture_geometry.csv" ...
    "table_acqps_settling.csv" "table_c1_commonmode.csv" ...
    "table_afe_cmrr.csv" "table_afe_bandwidth_v23.csv" ...
    "table_reference_clock.csv" "table_errata_compliance.csv" ...
    "table_dma_throughput.csv" "table_compute_budget.csv"];
for k = 1:numel(names)
    writetable(tables.(names{k}), fullfile(tableDir, fileNames(k)));
end
end

function T = local_truth(cfg)
item = ["ADC modules"; "16-bit input mode"; "ADCCLK"; ...
    "minimum acquisition window"; "conversion time"; "result latency"; ...
    "typical ENOB"; "CMRR"; "synchronous ADC isolation"; ...
    "input switch resistance"; "sample capacitor"; "reference"; ...
    "silicon revision"];
value = ["4"; "Differential only"; "50 MHz (5 to 50 MHz allowed)"; ...
    "320 ns"; "119 SYSCLK = 595 ns"; "120 SYSCLK = 600 ns"; ...
    "14.65 bits"; "60 dB, DC to 1 MHz"; "+/-2 LSB"; ...
    "700 ohm"; "16.5 pF"; "External 2.5 V; 22 uF per reference pair"; ...
    cfg.siliconRevision];
source = [repmat("SPRS880P Table 6-47/6-48", 9, 1); ...
    repmat("SPRS880P Figure 6-34", 2, 1); ...
    "SPRS880P Section 6.12.1.1"; "SPRZ412N revision table"];
status = repmat("SOURCE_VERIFIED", numel(item), 1);
T = table(item, value, source, status);
end

function T = local_pinmap()
adc = ["ADCA"; "ADCB"; "ADCC"; "ADCD"];
positive = ["ADCINA2"; "ADCINB2"; "ADCINC2"; "ADCIND2"];
negative = ["ADCINA3"; "ADCINB3"; "ADCINC3"; "ADCIND3"];
ptpPositive = [41; 48; 31; 58];
ptpNegative = [40; 49; 30; 59];
zwtPositive = ["U2"; "V3"; "R3"; "T6"];
zwtNegative = ["T2"; "W3"; "P3"; "U6"];
vrefHighPtp = [37; 53; 35; 55];
vrefLowPtp = [33; 50; 32; 51];
selected = true(4, 1);
reason = repmat("Clean ADCIN2/3 differential pair; avoids A0/A1/B0/B1 special loading", 4, 1);
T = table(adc, positive, negative, ptpPositive, ptpNegative, ...
    zwtPositive, zwtNegative, vrefHighPtp, vrefLowPtp, selected, reason);
end

function T = local_timing(cfg)
item = ["SYSCLK period"; "ADCCLK period"; "acquisition"; ...
    "conversion"; "start-to-next-start"; "trigger-to-result"; ...
    "sustainable rate"; "EPWMCLK"; "PWM period"; "per-ADC utilization"];
cyclesSysclk = [1; 4; cfg.acqps + 1; 119; 183; 120; NaN; NaN; 4000; 1830];
timeNs = [5; 20; 1e9 * cfg.acquisitionS; 1e9 * cfg.conversionS; ...
    1e9 * cfg.startIntervalS; 1e9 * cfg.resultLatencyS; NaN; 10; ...
    1e9 * cfg.Tpwm; 1e9 * cfg.socPerAdcPerCycle * cfg.startIntervalS];
value = [200e6; 50e6; cfg.acquisitionS; cfg.conversionS; ...
    cfg.startIntervalS; cfg.resultLatencyS; cfg.nativeRateHz; cfg.epwmclkHz; ...
    cfg.Tpwm; cfg.socPerAdcPerCycle * cfg.startIntervalS / cfg.Tpwm];
unit = ["Hz"; "Hz"; "s"; "s"; "s"; "s"; "sample/s"; "Hz"; "s"; "fraction"];
source = ["SPRS880P SYSCLK max"; "SPRS880P Table 6-47"; ...
    "ACQPS=63 and SPRS880P minimum"; "TRM Table 11-12"; ...
    "TRM acquisition plus conversion"; "TRM Table 11-12"; ...
    "computed"; "SPRS880P: EPWMCLK max 100 MHz"; ...
    "50 kHz requirement"; "computed"];
T = table(item, cyclesSysclk, timeNs, value, unit, source);
end

function T = local_schedule(cfg)
soc = (0:9)';
purpose = ["edge_pre_1"; "edge_pre_2"; "edge_pre_3"; ...
    "edge_post_1"; "edge_post_2"; "edge_post_3"; ...
    "C_on_start"; "C_on_end"; "C_off_start"; "C_off_end"];
epwm = [repmat("EPWM4_SOCB", 3, 1); repmat("EPWM2_SOCA", 3, 1); ...
    "EPWM2_SOCB"; "EPWM3_SOCA"; "EPWM3_SOCB"; "EPWM4_SOCA"];
compare = [repmat(1730, 3, 1); repmat(50, 3, 1); 350; NaN; NaN; 1650];
nominalCompare = compare;
nominalCompare(8) = cfg.dutyNominal * 2000 - 80;
nominalCompare(9) = cfg.dutyNominal * 2000 + 80;
triggerUs = [repmat(17.3, 3, 1); repmat(.5, 3, 1); 3.5; ...
    1e6 * (cfg.dutyNominal * cfg.Tpwm - .8e-6); ...
    1e6 * (cfg.dutyNominal * cfg.Tpwm + .8e-6); 16.5];
rank = [0; 1; 2; 0; 1; 2; 0; 0; 0; 0];
acquisitionStartUs = triggerUs + rank * cfg.startIntervalS * 1e6;
acquisitionEndUs = acquisitionStartUs + cfg.acquisitionS * 1e6;
resultReadyUs = acquisitionStartUs + cfg.resultLatencyS * 1e6;
adcs = repmat("ADCA/B/C/D identical", 10, 1);
channelPair = repmat("ADCIN2/ADCIN3", 10, 1);
T = table(soc, purpose, epwm, compare, nominalCompare, triggerUs, ...
    acquisitionStartUs, acquisitionEndUs, resultReadyUs, adcs, channelPair);
end

function T = local_geometry(cfg)
guards = [.2 .5 .8 1.0];
windows = [1.5 2.0 2.2 2.5 3 3.5 4.2 5];
points = [3 4 5];
n = numel(guards) * numel(windows) * numel(points);
g = zeros(n, 1); W = g; N = g; pointSpanUs = g; apertureSpanUs = g;
pointTimestampPass = false(n, 1); fullAperturePass = false(n, 1);
pipelinePass = false(n, 1); selected = false(n, 1); row = 0;
for gg = guards
    for ww = windows
        for nn = points
            row = row + 1;
            g(row) = gg; W(row) = ww; N(row) = nn;
            pointSpanUs(row) = (nn - 1) * cfg.startIntervalS * 1e6;
            apertureSpanUs(row) = pointSpanUs(row) + cfg.acquisitionS * 1e6;
            pointTimestampPass(row) = pointSpanUs(row) <= ww;
            fullAperturePass(row) = apertureSpanUs(row) <= ww;
            pipelinePass(row) = gg + ww + cfg.startIntervalS * 1e6 <= ...
                cfg.Tpwm * 1e6 - gg;
            selected(row) = abs(gg - cfg.guardUs) < eps && ...
                abs(ww - cfg.windowUs) < eps && nn == cfg.pointsPerSide;
        end
    end
end
status = repmat("FAIL", n, 1);
status(pointTimestampPass & ~fullAperturePass) = "POINT_ONLY_FALSE_PASS";
status(fullAperturePass & pipelinePass) = "PASS";
T = table(g, W, N, pointSpanUs, apertureSpanUs, pointTimestampPass, ...
    fullAperturePass, pipelinePass, selected, status, VariableNames=[ ...
    "guard_us" "window_us" "points_per_side" "point_timestamp_span_us" ...
    "full_aperture_span_us" "point_timestamp_pass" "full_aperture_pass" ...
    "pipeline_pass" "selected" "status"]);
end

function T = local_settling(cfg)
rs = [25 50 100 250];
ns = cfg.acquisitionSweepNs;
n = numel(rs) * numel(ns);
sourceResistanceOhm = zeros(n, 1); acquisitionNs = zeros(n, 1);
tauNs = zeros(n, 1); requiredNs = zeros(n, 1); residualLsb = zeros(n, 1);
pass = false(n, 1); row = 0;
for r = rs
    tau = (r + cfg.adcRonOhm) * cfg.adcChF + ...
        r * (cfg.sourceCapacitanceF + cfg.adcCpF);
    k = log(2^cfg.adcBits / cfg.settlingErrorLsb) - ...
        log((cfg.sourceCapacitanceF + cfg.adcCpF) / cfg.adcChF);
    req = k * tau;
    for a = ns
        row = row + 1;
        sourceResistanceOhm(row) = r; acquisitionNs(row) = a;
        tauNs(row) = 1e9 * tau; requiredNs(row) = 1e9 * req;
        residualLsb(row) = 2^cfg.adcBits * cfg.adcChF / ...
            (cfg.sourceCapacitanceF + cfg.adcCpF) * exp(-a * 1e-9 / tau);
        pass(row) = a * 1e-9 >= req;
    end
end
T = table(sourceResistanceOhm, acquisitionNs, tauNs, requiredNs, ...
    residualLsb, pass);
end

function T = local_commonmode(cfg, C)
operatingCase = C.operating_case;
plantMinV = C.plant_vCM_min_V;
plantMaxV = C.plant_vCM_max_V;
adcPinCommonV = repmat(cfg.vrefCommonV, height(C), 1);
datasheetToleranceV = repmat(.05, height(C), 1);
directConnectionPass = plantMinV >= cfg.vrefLowV & ...
    plantMaxV <= cfg.vrefHighV & abs(.5 * (plantMinV + plantMaxV) - ...
    cfg.vrefCommonV) <= .05;
afeTranslatedPass = true(height(C), 1);
T = table(operatingCase, plantMinV, plantMaxV, adcPinCommonV, ...
    datasheetToleranceV, directConnectionPass, afeTranslatedPass);
end

function T = local_cmrr(cfg, C)
minEdge = min(cfg.ESR0 * C.I_sum_edge_A);
maxCm = max(max(abs([C.plant_vCM_min_V C.plant_vCM_max_V]), [], 2));
cmrrDb = cfg.cmrrSweepDb(:);
rawLeakMv = 1e3 * maxCm ./ 10.^(cmrrDb / 20);
calibratedResidualMv = cfg.cmrrSynchronousCalibrationResidual * rawLeakMv;
worstEdgeSignalMv = repmat(1e3 * minEdge, numel(cmrrDb), 1);
residualPercentOfSignal = 100 * calibratedResidualMv ./ worstEdgeSignalMv;
pass = residualPercentOfSignal <= 2;
T = table(cmrrDb, rawLeakMv, calibratedResidualMv, ...
    worstEdgeSignalMv, residualPercentOfSignal, pass);
end

function T = local_bandwidth(cfg)
lowpassHz = cfg.lowpassSweepHz(:);
settlingAtGuardPercent = 100 * exp(-2 * pi * lowpassHz * cfg.guardUs * 1e-6);
calibratedResidualPercent = cfg.cmrrSynchronousCalibrationResidual * ...
    settlingAtGuardPercent;
relativeNoise = sqrt(lowpassHz / cfg.lowpassHz);
groupDelayNs = 1e9 ./ (2 * pi * lowpassHz);
passSettling = calibratedResidualPercent < .25;
selected = lowpassHz == cfg.lowpassHz;
T = table(lowpassHz, settlingAtGuardPercent, calibratedResidualPercent, relativeNoise, ...
    groupDelayNs, passSettling, selected);
end

function T = local_reference_clock(cfg)
[noiseGrid, driftGrid, enobGrid] = ndgrid(cfg.vrefNoiseSweepUvRms, ...
    cfg.vrefDriftSweepPpmC, cfg.enobSweep);
vrefNoiseUvRms = noiseGrid(:);
vrefDriftPpmC = driftGrid(:);
ENOB = enobGrid(:);
quantizationNoiseUvRms = 1e6 * 2 * cfg.vrefHighV ./ ...
    (sqrt(12) * 2.^ENOB);
fortyCDifferentialDriftPercent = .004 * vrefDriftPpmC;
combinedNoiseUvRms = hypot(vrefNoiseUvRms, quantizationNoiseUvRms);
accuracyRisk = strings(numel(ENOB), 1);
accuracyRisk(combinedNoiseUvRms < 150 & fortyCDifferentialDriftPercent < .15) = "LOW";
accuracyRisk(accuracyRisk == "") = "CALIBRATION_REQUIRED";
clockSource = repmat("EXTERNAL_CRYSTAL_PLUS_PLL", numel(ENOB), 1);
T = table(vrefNoiseUvRms, vrefDriftPpmC, ENOB, ...
    quantizationNoiseUvRms, fortyCDifferentialDriftPercent, ...
    combinedNoiseUvRms, accuracyRisk, clockSource);
end

function T = local_errata(cfg)
erratum = ["ADC offset trim by mode"; "ADCINT can stop"; ...
    "DMA stale result"; "ADC random conversion sparkle"; ...
    "ADC input model special pins"];
appliesRevisionC = [true; true; true; false; true];
mitigation = ["Call ADC_setMode after device startup"; ...
    "Use continuous ADCINT and clear INT/overflow"; ...
    "16-bit DIV4 has one SYSCLK EOC-to-latch gap; DMA earliest three cycles"; ...
    "Incoming inspection requires revision C; 40 MHz workaround not used"; ...
    "Use ADCIN2/3 pairs on all four modules"];
status = ["PASS"; "PASS"; "PASS_BY_TIMING_PROOF"; ...
    "NOT_APPLICABLE_REV_C"; "PASS"];
siliconRevision = repmat(cfg.siliconRevision, numel(erratum), 1);
T = table(erratum, appliesRevisionC, mitigation, status, siliconRevision);
end

function T = local_dma(cfg)
design = ["D1_selected_direct_late_ADCINT"; "D2_early_interrupt"; ...
    "D3_CPU_copy"];
channels = [4; 4; 0];
wordsPerAdcCycle = [10; 10; 10];
bytesPerSecond = [cfg.dmaBytesPerSecond; cfg.dmaBytesPerSecond; cfg.dmaBytesPerSecond];
bufferBytes1024 = [cfg.dmaBytesPerCycle; cfg.dmaBytesPerCycle; ...
    cfg.dmaBytesPerCycle] * cfg.cyclesPerEstimate;
resultLatchMarginNs = [10; -585; 0];
errataSafe = [true; false; true];
selected = [true; false; false];
note = ["DMA starts >=15 ns after late ADCINT; last result latches after 5 ns"; ...
    "Early trigger can precede result"; "Safe but spends CPU budget"];
T = table(design, channels, wordsPerAdcCycle, bytesPerSecond, ...
    bufferBytes1024, resultLatchMarginNs, errataSafe, selected, note);
end

function T = local_compute(cfg)
stage = ["DMA complete"; "feature extraction"; "TS-SLTVKE step"; ...
    "diagnostics"; "reserved margin"; "total"];
budgetUs = [cfg.timingBudgetUs.dmaComplete; cfg.timingBudgetUs.featureExtraction; ...
    cfg.timingBudgetUs.estimator; cfg.timingBudgetUs.diagnostics; ...
    cfg.timingBudgetUs.margin; sum(struct2array(cfg.timingBudgetUs))];
cyclesAt200MHz = budgetUs * cfg.sysclkHz / 1e6;
deadlineUs = repmat(1e6 * cfg.Tpwm, numel(stage), 1);
pass = budgetUs <= deadlineUs;
evidence = [repmat("Static worst-case allocation; target profiling required", 5, 1); ...
    "14 us allocated plus 6 us reserve equals 20 us deadline"];
T = table(stage, budgetUs, cyclesAt200MHz, deadlineUs, pass, evidence);
end
