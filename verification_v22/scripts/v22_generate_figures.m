function v22_generate_figures(v22Root, ~, budget, codes, geometry, ...
        voltage, nonideal, multicycle, kR, comparison)
%V22_GENERATE_FIGURES Generate the twelve mandatory v2.2 figures.

figureDir = fullfile(v22Root, "results", "figures");
colors = lines(6);

fig = new_figure();
tiledlayout(1, 2);
nexttile;
bar([min(budget.edge_ESR_signal_mV), median(budget.edge_ESR_signal_mV), ...
    max(budget.edge_ESR_signal_mV)]);
set(gca, XTickLabel=["min" "median" "max"]); ylabel("ESR edge signal (mV)");
grid on; title("ESR health signal");
nexttile;
bar([min(budget.charge_C_signal_mV), median(budget.charge_C_signal_mV), ...
    max(budget.charge_C_signal_mV)]);
set(gca, XTickLabel=["min" "median" "max"]); ylabel("C charge signal (mV)");
grid on; title("C safe-window signal");
save_png(fig, figureDir, "fig_v22_01_health_signal_amplitude");

fig = new_figure();
native = codes(codes.ADC_mode == "native_12bit_highspeed", :);
tiledlayout(1, 2);
nexttile; boxchart(categorical(native.voltage_architecture), ...
    native.ESR_edge_codes); yline(4, "r:"); yline(16, "k:");
set(gca, YScale="log"); grid on; ylabel("ESR edge codes");
nexttile; boxchart(categorical(native.voltage_architecture), ...
    native.C_charge_window_codes); yline(4, "r:"); yline(16, "k:");
set(gca, YScale="log"); grid on; ylabel("C window codes");
save_png(fig, figureDir, "fig_v22_02_adc_code_utilization");

fig = new_figure();
selected = geometry(geometry.selected, :);
yyaxis left; plot(selected.fs_adc_Hz / 1e6, selected.locked_window_us, ...
    "o-", LineWidth=1.5); ylabel("Locked window (us)");
yyaxis right; stairs(selected.fs_adc_Hz / 1e6, ...
    selected.locked_points_per_side, "s-", LineWidth=1.5);
ylabel("Locked points per side"); xlabel("ADC rate (MS/s)"); grid on;
title("PWM-triggered geometry optimization");
save_png(fig, figureDir, "fig_v22_03_native_adc_sampling_geometry");

fig = new_figure();
tiledlayout(1, 2);
nexttile; bar(categorical(voltage.voltage_architecture), ...
    [voltage.worst_C_MAPE_percent voltage.worst_ESR_MAPE_percent]);
yline(3, "k:"); yline(5, "r:"); ylabel("Worst blind MAPE (%)");
legend("C", "ESR"); grid on;
nexttile; bar(categorical(voltage.voltage_architecture), ...
    [voltage.minimum_C_codes_12bit voltage.minimum_ESR_codes_12bit]);
set(gca, YScale="log"); ylabel("Minimum signal codes"); legend("C", "ESR"); grid on;
save_png(fig, figureDir, "fig_v22_04_voltage_architecture_comparison");

fig = new_figure();
z = nonideal(nonideal.sweep_type == "ENOB_sweep", :);
plot(z.ENOB, z.ESR_MAPE_percent, "o-", LineWidth=1.5);
yline(5, "k:"); grid on; xlabel("ENOB"); ylabel("ESR MAPE (%)");
title("12-bit native mode: ENOB sensitivity");
save_png(fig, figureDir, "fig_v22_05_esr_error_vs_bits_enob");

fig = new_figure();
plot_multicycle(multicycle, "ESR_MAPE_percent", "ESR MAPE (%)", colors);
yline(5, "k:");
save_png(fig, figureDir, "fig_v22_06_esr_error_vs_multicycle");

fig = new_figure();
plot_multicycle(multicycle, "C_MAPE_percent", "C MAPE (%)", colors);
yline(3, "k:");
save_png(fig, figureDir, "fig_v22_07_C_error_vs_multicycle");

fig = new_figure();
z = multicycle(multicycle.quantization_case == "Q1_deterministic" & ...
    multicycle.fusion_method == "TS_SLTVKE_sequential", :);
for path = unique(z.path_id)'
    q = z(z.path_id == path, :);
    semilogx(q.multi_cycle, q.ESR_MAPE_percent, "o-", ...
        DisplayName=path); hold on;
end
grid on; xlabel("Coherently repeated cycles"); ylabel("ESR MAPE (%)");
legend(Location="best"); title("Deterministic quantization does not average as sqrt(N)");
save_png(fig, figureDir, "fig_v22_08_deterministic_quantization_floor");

fig = new_figure();
z = nonideal(nonideal.sweep_type == "calibration_sweep_native16", :);
bar(categorical(z.calibration_level), [z.C_MAPE_percent z.ESR_MAPE_percent]);
yline(3, "k:"); yline(5, "r:"); grid on; ylabel("MAPE (%)");
legend("C", "ESR"); title("Calibration hierarchy benefit");
save_png(fig, figureDir, "fig_v22_09_calibration_benefit");

fig = new_figure();
tiledlayout(1, 2);
nexttile; boxchart(categorical(kR.voltage_architecture), kR.kR_raw);
yline(1, "k:"); grid on; ylabel("Raw k_R");
nexttile; boxchart(categorical(kR.voltage_architecture), ...
    kR.kR_after_once_calibration); yline(1, "k:"); grid on;
ylabel("k_R after one-time gain calibration");
save_png(fig, figureDir, "fig_v22_10_kR_variation");

fig = new_figure();
tiledlayout(1, 2);
pathCategory = categorical(comparison.path_id, comparison.path_id, Ordinal=true);
nexttile; bar(pathCategory, ...
    100 * comparison.accuracy_pass_fraction); yline(95, "k:");
ylim([0 105]); ylabel("Blind accuracy pass (%)"); grid on;
nexttile; bar(pathCategory, ...
    [comparison.C_MAPE_worst_percent comparison.ESR_MAPE_worst_percent]);
yline(3, "k:"); yline(5, "r:"); ylabel("Worst MAPE (%)");
legend("C", "ESR"); grid on;
save_png(fig, figureDir, "fig_v22_11_native_vs_external");

fig = new_figure();
sz = 80 + 160 * comparison.accuracy_pass_fraction;
xDisplay = comparison.fs_adc_Hz / 1e6;
native12 = find(startsWith(comparison.path_id, "native_12"));
xDisplay(native12) = xDisplay(native12) + [-.25; 0; .25];
scatter(xDisplay, comparison.ENOB, sz, ...
    comparison.accuracy_pass_fraction, "filled"); colorbar; clim([0 1]);
xlabel("ADC rate (MS/s)"); ylabel("ENOB"); grid on;
labels = replace(comparison.path_id, ["native_12_" "native_16_" ...
    "external_14_" "external_16_"], ["N12-" "N16-" "E14-" "E16-"]);
text(xDisplay, comparison.ENOB, "  " + labels, Interpreter="none", FontSize=8);
xlim([.8 5.45]);
title("Final decision region: size/color = blind accuracy pass fraction");
save_png(fig, figureDir, "fig_v22_12_final_adc_decision_region");
close all;
fprintf("v2.2 figures complete: 12 mandatory PNG files.\n");
end

function fig = new_figure()
fig = figure(Visible="off", Color="w", Position=[100 100 1000 480]);
end

function save_png(fig, folder, name)
exportgraphics(fig, fullfile(folder, name + ".png"), Resolution=180);
savefig(fig, fullfile(folder, name + ".fig"));
close(fig);
end

function plot_multicycle(T, variable, label, colors)
z = T(T.quantization_case == "Q3_full_nonideal" & ...
    T.fusion_method == "TS_SLTVKE_sequential", :);
paths = unique(z.path_id, "stable");
for k = 1:numel(paths)
    q = z(z.path_id == paths(k), :);
    loglog(q.multi_cycle, q.(variable), "o-", Color=colors(k, :), ...
        DisplayName=paths(k), LineWidth=1.2); hold on;
end
grid on; xlabel("Fused PWM cycles"); ylabel(label); legend(Location="best");
title("Full nonideal model with locked Cal3");
end
