function cfg = v23_default_config()
%V23_DEFAULT_CONFIG Locked F28379D hardware-closure configuration.

cfg = struct;
cfg.version = "v2.3";
cfg.partNumber = "TMS320F28379D";
cfg.package = "PTP-176";
cfg.siliconRevision = "C";
cfg.fswHz = 50e3;
cfg.Tpwm = 1 / cfg.fswHz;
cfg.dutyNominal = .40;
cfg.sysclkHz = 200e6;
cfg.epwmclkHz = 100e6;
cfg.tbclkHz = cfg.epwmclkHz;
cfg.tbprd = 1999;
cfg.adcclkDivider = 4;
cfg.adcclkHz = cfg.sysclkHz / cfg.adcclkDivider;
cfg.acqps = 63;
cfg.acquisitionS = (cfg.acqps + 1) / cfg.sysclkHz;
cfg.conversionCyclesAdc = 29.75;
cfg.conversionS = 119 / cfg.sysclkHz;
cfg.resultLatencyS = 120 / cfg.sysclkHz;
cfg.startIntervalS = cfg.acquisitionS + cfg.conversionS;
cfg.nativeRateHz = 1 / cfg.startIntervalS;

cfg.eventMode = "E1_RISING_EDGE_ONLY";
cfg.syncMode = "S1_FOUR_ADCS_SAME_TRIGGER";
cfg.guardUs = .5;
cfg.windowUs = 2.2;
cfg.pointsPerSide = 3;
cfg.cyclesPerEstimate = 1024;
cfg.socPerAdcPerCycle = 10;
cfg.channelBufferWords = cfg.cyclesPerEstimate * cfg.socPerAdcPerCycle;
cfg.adcCount = 4;
cfg.dmaBytesPerCycle = 2 * cfg.adcCount * cfg.socPerAdcPerCycle;
cfg.dmaBytesPerSecond = cfg.dmaBytesPerCycle * cfg.fswHz;

cfg.vrefHighV = 2.5;
cfg.vrefLowV = 0;
cfg.vrefCommonV = 1.25;
cfg.adcDifferentialSpanV = 5.0;
cfg.afeDifferentialLimitV = 2.0;
cfg.pinHeadroomV = .25;
cfg.adcBits = 16;
cfg.enobTypical = 14.65;
cfg.enobDesign = 13.5;
cfg.enobSweep = [12.5 13 13.5 14 14.65];
cfg.cmrrDcDb = 90;
cfg.cmrrEdgeDb = 70;
cfg.cmrrSynchronousCalibrationResidual = .05;
cfg.cmrrSweepDb = 60:10:110;
cfg.sourceResistanceOhm = 50;
cfg.sourceCapacitanceF = 330e-12;
cfg.adcRonOhm = 700;
cfg.adcChF = 16.5e-12;
cfg.adcCpF = 6.3e-12;
cfg.settlingErrorLsb = .25;
cfg.highpassHz = 5e3;
cfg.lowpassHz = 1.2e6;
cfg.lowpassSweepHz = [300 500 700 1000 1200 1500] * 1e3;
cfg.acquisitionSweepNs = [320 360 400 500 640];
cfg.vrefNoiseSweepUvRms = [1 5 10 20 50];
cfg.vrefDriftSweepPpmC = [5 10 25 50];
cfg.mcSeeds = 200;
cfg.randomSeedBase = 23000;

cfg.C0 = 100e-6;
cfg.ESR0 = 50e-3;
cfg.modelBESLH = 20e-9;
cfg.modelBDurationS = .0025;
cfg.operatingCases = struct( ...
    "name", {"low_CCM", "nominal", "high_load", "high_D"}, ...
    "Vin", {24, 24, 24, 24}, ...
    "D", {.40, .40, .40, .65}, ...
    "Rload", {30, 10, 5, 7.5});
cfg.validationCases = struct( ...
    "name", {"low_CCM", "nominal", "high_load", "high_D", ...
        "C_0p8", "ESR_2x", "combined_C_0p8_ESR_2x"}, ...
    "baseCase", {"low_CCM", "nominal", "high_load", "high_D", ...
        "nominal", "nominal", "high_D"}, ...
    "cFactor", {1, 1, 1, 1, .8, 1, .8}, ...
    "esrFactor", {1, 1, 1, 1, 1, 2, 2});

cfg.timingBudgetUs = struct( ...
    "dmaComplete", 4.5, "featureExtraction", 3.0, ...
    "estimator", 5.0, "diagnostics", 1.5, "margin", 6.0);
cfg.cMapeLimitPercent = 3;
cfg.esrMapeLimitPercent = 5;
cfg.requiredPassFraction = .95;
cfg.allowedDecisions = [ ...
    "F28379D_INTERNAL_ADC_CONFIRMED" ...
    "F28379D_INTERNAL_ADC_CONFIRMED_WITH_AFE_CONSTRAINTS" ...
    "F28379D_INTERNAL_ADC_MARGINAL" ...
    "EXTERNAL_ADC_REQUIRED" ...
    "UNRESOLVED" ...
];
end
