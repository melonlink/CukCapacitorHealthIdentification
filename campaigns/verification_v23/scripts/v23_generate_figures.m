function v23_generate_figures(root, cfg, ~, bases, T, ~, MC, gates)
%V23_GENERATE_FIGURES Produce the fourteen mandatory review figures.

figDir = fullfile(root, "results", "figures");
blue = [0.12 0.40 0.74]; orange = [0.90 0.42 0.10];

f = local_figure();
bar(categorical(T.timing.item(3:6)), 1e9 * T.timing.value(3:6));
ylabel("Time (ns)"); title("F28379D 16-bit ADC timing"); grid on;
local_export(f, figDir, "fig_v23_01_adc_real_timing.png");

f = local_figure();
g = T.geometry(T.geometry.points_per_side == 3 & T.geometry.guard_us == .5, :);
plot(g.window_us, g.point_timestamp_span_us, "o-", Color=blue, LineWidth=1.5); hold on;
plot(g.window_us, g.full_aperture_span_us, "s-", Color=orange, LineWidth=1.5);
plot(g.window_us, g.window_us, "k--"); hold off; grid on;
xlabel("Window (us)"); ylabel("Required/available span (us)");
legend("Point timestamps", "Full apertures", "Available", Location="northwest");
title("Complete aperture closes at W = 2.2 us");
local_export(f, figDir, "fig_v23_02_full_aperture_edge_window.png");

f = local_figure();
scatter(T.schedule.acquisitionStartUs, T.schedule.soc, 70, T.schedule.soc, "filled");
xlabel("Time in PWM cycle (us)"); ylabel("SOC number"); grid on;
title("Register-realizable ePWM/SOC schedule (nominal D=0.4)");
local_export(f, figDir, "fig_v23_03_soc_schedule.png");

f = local_figure();
S = T.settling(T.settling.sourceResistanceOhm == cfg.sourceResistanceOhm, :);
semilogy(S.acquisitionNs, S.residualLsb, "o-", Color=blue, LineWidth=1.5); hold on;
yline(cfg.settlingErrorLsb, "r--", "0.25 LSB target"); hold off; grid on;
xlabel("Acquisition aperture (ns)"); ylabel("Worst residual (LSB)");
title("ADC input network settling, Rs=50 ohm, Cs=330 pF");
local_export(f, figDir, "fig_v23_04_acqps_vs_settling.png");

f = local_figure();
duty = .25:.01:.65; shortState = min(duty, 1-duty) * cfg.Tpwm * 1e6;
maxPoints = floor((shortState - 2 * cfg.guardUs - cfg.acquisitionS * 1e6) / ...
    (cfg.startIntervalS * 1e6)) + 1;
plot(duty, maxPoints, LineWidth=1.7, Color=blue); hold on;
yline(cfg.pointsPerSide, "r--", "Selected N=3"); hold off; grid on;
xlabel("Duty ratio"); ylabel("Full-aperture points in shorter state");
title("Edge point capacity versus duty");
local_export(f, figDir, "fig_v23_05_edge_points_vs_duty.png");

f = local_figure();
b = bases{4}; tail = b.t >= b.t(end) - 2 * cfg.Tpwm;
plot(1e6 * (b.t(tail) - b.t(find(tail,1))), b.vCplus(tail), LineWidth=1.1); hold on;
plot(1e6 * (b.t(tail) - b.t(find(tail,1))), b.vCminus(tail), LineWidth=1.1);
plot(1e6 * (b.t(tail) - b.t(find(tail,1))), b.vCM(tail), "k", LineWidth=1.5); hold off;
xlabel("Time in final two cycles (us)"); ylabel("Plant voltage (V)"); grid on;
legend("C1+ to ground", "C1- to ground", "C1 common mode");
title("Floating Cuk capacitor terminals: high-D Model B");
local_export(f, figDir, "fig_v23_06_c1_diff_commonmode.png");

f = local_figure();
semilogy(T.cmrr.cmrrDb, T.cmrr.residualPercentOfSignal, "o-", ...
    LineWidth=1.5, Color=orange); hold on; yline(2, "r--", "2% allocation"); hold off;
xlabel("AFE chain CMRR (dB)"); ylabel("Residual / worst ESR signal (%)"); grid on;
title("Finite-CMRR ESR error after synchronous calibration");
local_export(f, figDir, "fig_v23_07_cmrr_esr_error.png");

f = local_figure();
yyaxis left; semilogx(T.bandwidth.lowpassHz, T.bandwidth.settlingAtGuardPercent, ...
    "o-", LineWidth=1.5); ylabel("Residual at guard (%)");
yyaxis right; semilogx(T.bandwidth.lowpassHz, T.bandwidth.relativeNoise, ...
    "s-", LineWidth=1.5); ylabel("Relative integrated noise");
xlabel("Vedge low-pass bandwidth (Hz)"); grid on; title("AFE bandwidth tradeoff");
local_export(f, figDir, "fig_v23_08_afe_bw_native_adc.png");

f = local_figure();
R = groupsummary(T.reference, "vrefNoiseUvRms", "mean", "combinedNoiseUvRms");
plot(R.vrefNoiseUvRms, R.mean_combinedNoiseUvRms, "o-", ...
    Color=blue, LineWidth=1.5); grid on;
xlabel("VREF noise (uV RMS)"); ylabel("Mean combined input noise (uV RMS)");
title("Reference-noise sensitivity across ENOB sweep");
local_export(f, figDir, "fig_v23_09_reference_noise.png");

f = local_figure();
cats = categorical(["AFE gain" "CMRR" "ENOB/noise" "VREF" "timing"]);
bar(cats, [.7 1.0 .35 .25 .20], FaceColor=blue); ylabel("Representative ESR error allocation (%)");
title("Calibrated device/AFE error budget"); grid on;
local_export(f, figDir, "fig_v23_10_adc_error_budget.png");

f = local_figure();
B = T.compute(1:end-1, :);
barh(categorical(B.stage), B.budgetUs, FaceColor=blue); hold on;
xline(1e6 * cfg.Tpwm, "r--", "20 us deadline"); hold off;
xlabel("Allocated time (us)"); title("Real-time compute allocation"); grid on;
local_export(f, figDir, "fig_v23_11_compute_timeline.png");

f = local_figure();
x = 1:height(MC);
bar(x - .18, MC.p95_C_abs_error_percent, .36, FaceColor=blue); hold on;
bar(x + .18, MC.p95_ESR_abs_error_percent, .36, FaceColor=orange);
yline(cfg.cMapeLimitPercent, "--", "C limit"); yline(cfg.esrMapeLimitPercent, ":", "ESR limit"); hold off;
xticks(x); xticklabels(MC.validation_case); xtickangle(25); ylabel("p95 absolute error (%)");
legend("C", "ESR"); grid on; title("200-seed device-level accuracy");
local_export(f, figDir, "fig_v23_12_monte_carlo_accuracy.png");

f = local_figure();
bar(x - .18, 100 * MC.mean_C_CI95_covered, .36, FaceColor=blue); hold on;
bar(x + .18, 100 * MC.mean_ESR_CI95_covered, .36, FaceColor=orange);
yline(95, "k--", "95% target"); hold off; ylim([80 100]);
xticks(x); xticklabels(MC.validation_case); xtickangle(25); ylabel("Empirical coverage (%)");
legend("C", "ESR"); grid on; title("95% confidence-interval coverage");
local_export(f, figDir, "fig_v23_13_ci_coverage.png");

f = local_figure();
gateCats = categorical(gates.gateName, gates.gateName);
bar(gateCats, double(gates.pass), FaceColor=blue); ylim([0 1.2]);
yticks([0 1]); yticklabels(["FAIL" "PASS"]); xtickangle(30); grid on;
xticklabels(["A Datasheet" "B Aperture" "C ADC sync" "D AFE settling" ...
    "E Common mode" "F Errata" "G Real time" "H Accuracy"]);
title("Final F28379D hardware-closure gates");
local_export(f, figDir, "fig_v23_14_final_hardware_window.png");
end

function f = local_figure()
f = figure("Visible", "off", "Color", "white", "Position", [100 100 980 560]);
end

function local_export(f, folder, name)
exportgraphics(f, fullfile(folder, name), Resolution=180);
close(f);
end
