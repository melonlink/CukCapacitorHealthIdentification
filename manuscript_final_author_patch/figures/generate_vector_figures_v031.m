function generate_vector_figures_v031()
%GENERATE_VECTOR_FIGURES_V031 Redraw Figs. 4--8 from frozen result tables.
% This script reads archived CSV outputs only. It does not run a model,
% estimator, calibration, or simulation.

scriptDir = fileparts(mfilename("fullpath"));
projectRoot = fileparts(fileparts(scriptDir));

verificationRoot = fullfile(projectRoot, "paper_verification_v12", "results");
selectionRoot = fullfile(projectRoot, "paper_algorithm_selection_v2", "results");

methodKeys = ["M1 TS-D-RLS", "M2 TS-SLTVKE", "M3 Dual EKF"];
methodLabels = ["TS-D-RLS", "TS-SLTVKE", "Dual EKF"];
methodColors = [0.00 0.35 0.70; 0.85 0.33 0.10; 0.30 0.60 0.25];
lineStyles = ["-", "--", "-."];
markers = ["o", "s", "^"];

oldDefaults = setPublicationDefaults();
cleanup = onCleanup(@() restoreDefaults(oldDefaults)); %#ok<NASGU>

makeObservationEffect(verificationRoot, scriptDir, methodLabels, methodColors);
makeStaticComparison(selectionRoot, scriptDir, methodKeys, methodLabels, methodColors);
makeNoiseTiming(selectionRoot, scriptDir, methodKeys, methodLabels, ...
    methodColors, lineStyles, markers);
makeJointRamp(selectionRoot, scriptDir, methodKeys, methodLabels, ...
    methodColors, lineStyles, markers);
makeComplexityPareto(selectionRoot, scriptDir, methodKeys, methodLabels, ...
    methodColors, markers);

fprintf("Generated five vector figures from frozen CSV outputs in %s\n", scriptDir);
end

function old = setPublicationDefaults()
old.axesFontName = get(groot, "defaultAxesFontName");
old.axesFontSize = get(groot, "defaultAxesFontSize");
old.textFontName = get(groot, "defaultTextFontName");
old.textFontSize = get(groot, "defaultTextFontSize");
old.legendFontName = get(groot, "defaultLegendFontName");
old.legendFontSize = get(groot, "defaultLegendFontSize");
old.lineLineWidth = get(groot, "defaultLineLineWidth");

set(groot, "defaultAxesFontName", "Times New Roman", ...
    "defaultAxesFontSize", 8, ...
    "defaultTextFontName", "Times New Roman", ...
    "defaultTextFontSize", 8, ...
    "defaultLegendFontName", "Times New Roman", ...
    "defaultLegendFontSize", 8, ...
    "defaultLineLineWidth", 1.15);
end

function restoreDefaults(old)
set(groot, "defaultAxesFontName", old.axesFontName, ...
    "defaultAxesFontSize", old.axesFontSize, ...
    "defaultTextFontName", old.textFontName, ...
    "defaultTextFontSize", old.textFontSize, ...
    "defaultLegendFontName", old.legendFontName, ...
    "defaultLegendFontSize", old.legendFontSize, ...
    "defaultLineLineWidth", old.lineLineWidth);
end

function makeObservationEffect(root, outDir, labels, colors)
source = fullfile(root, "tables", "table_observation_effect_bootstrap.csv");
T = readtable(source, "TextType", "string", "VariableNamingRule", "preserve");
estimatorKeys = ["E1 RLS", "E3 LTV/Joseph", "E2 Dual EKF"];
metrics = ["C_MAPE", "C_p95"; "ESR_MAPE", "ESR_p95"];

f = newFigure(3.5, 4.15);
layout = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");
panelTitles = ["(a) Capacitance error effects", "(b) ESR error effects"];

for p = 1:2
    ax = nexttile(layout);
    means = zeros(2, 3);
    lower = zeros(2, 3);
    upper = zeros(2, 3);
    for q = 1:2
        for m = 1:3
            row = T(T.estimator == estimatorKeys(m) & T.metric == metrics(p, q), :);
            assert(height(row) == 1, "Unexpected observation-effect row count.");
            means(q, m) = row.mean_paired_effect;
            lower(q, m) = means(q, m) - row.ci95_low;
            upper(q, m) = row.ci95_high - means(q, m);
        end
    end
    hold(ax, "on");
    [~, xPositions] = drawGroupedVectorBars(ax, means, colors);
    legendHandles = gobjects(3, 1);
    for m = 1:3
        legendHandles(m) = plot(ax, nan, nan, "s", ...
            "MarkerSize", 5, "MarkerFaceColor", colors(m, :), ...
            "MarkerEdgeColor", [0.15 0.15 0.15], "LineStyle", "none");
    end
    for q = 1:2
        errorbar(ax, xPositions(q, :), means(q, :), lower(q, :), upper(q, :), ...
            "k.", "LineWidth", 1.0, "CapSize", 4);
    end
    yline(ax, 0, "k--", "LineWidth", 0.8);
    hold(ax, "off");
    xticks(ax, 1:2);
    xticklabels(ax, ["Mean MAPE", "p95 error"]);
    ylabel(ax, "O0 - O1 effect (percentage points)");
    title(ax, panelTitles(p), "FontWeight", "normal");
    if p == 1
        ylim(ax, [0 14.2]);
        legend(ax, legendHandles, labels, "Location", "north", ...
            "Orientation", "horizontal", "Box", "off");
    end
    formatAxes(ax);
end
exportVector(f, fullfile(outDir, "fig_observation_effect.pdf"));
end

function makeStaticComparison(root, outDir, keys, labels, colors)
source = fullfile(root, "tables", "table_algorithm_static_comparison.csv");
T = readtable(source, "TextType", "string", "VariableNamingRule", "preserve");
T = T(T.mode == "Native", :);
T = orderByMethod(T, keys);

f = newFigure(3.5, 3.55);
layout = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");
values = [T.C_mean_MAPE_percent, T.ESR_mean_MAPE_percent];
panelTitles = ["(a) Capacitance", "(b) ESR"];

for p = 1:2
    ax = nexttile(layout);
    drawVectorBars(ax, values(:, p), colors);
    xticks(ax, 1:3);
    xticklabels(ax, labels);
    ylabel(ax, "Mean MAPE (%)");
    title(ax, panelTitles(p), "FontWeight", "normal");
    ylim(ax, [0, 1.12 * max(values(:, p))]);
    formatAxes(ax);
end
exportVector(f, fullfile(outDir, "fig_static_comparison.pdf"));
end

function makeNoiseTiming(root, outDir, keys, labels, colors, styles, markers)
source = fullfile(root, "tables", "table_algorithm_noise_timing.csv");
T = readtable(source, "TextType", "string", "VariableNamingRule", "preserve");
T = T(T.mode == "Native" & T.noise_profile == "F28379D_device_realistic", :);

f = newFigure(3.5, 3.85);
layout = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");
fields = ["C_p95_percent", "ESR_p95_percent"];
panelTitles = ["(a) Capacitance p95", "(b) ESR p95"];

for p = 1:2
    ax = nexttile(layout);
    hold(ax, "on");
    for m = 1:3
        rows = T(T.method == keys(m), :);
        rows = sortrows(rows, "skew_ns");
        y = rows.(fields(p));
        plot(ax, rows.skew_ns, y, "LineStyle", styles(m), ...
            "Marker", markers(m), "Color", colors(m, :), ...
            "MarkerSize", 4.8, "MarkerFaceColor", "white", ...
            "DisplayName", labels(m));
    end
    hold(ax, "off");
    xlabel(ax, "Residual timing mismatch (ns)");
    ylabel(ax, "Absolute error p95 (%)");
    title(ax, panelTitles(p), "FontWeight", "normal");
    xticks(ax, [0 20 50 100]);
    ylim(ax, [0, 1.12 * max(ylimData(T, fields(p)))]);
    if p == 1
        legend(ax, "Location", "southeast", "Box", "off");
    else
        legend(ax, "Location", "northwest", "Box", "off");
    end
    formatAxes(ax);
end
exportVector(f, fullfile(outDir, "fig_noise_timing.pdf"));
end

function makeJointRamp(root, outDir, keys, labels, colors, styles, markers)
source = fullfile(root, "raw", "ramp_history.csv");
T = readtable(source, "TextType", "string", "VariableNamingRule", "preserve");
T = T(T.trajectory_type == "joint_ramp" & ...
    T.source_model == "TRACE_DERIVED_OBSERVATION" & ...
    T.trajectory_duration_s == 1, :);

f = newFigure(7.16, 2.65);
layout = tiledlayout(f, 1, 2, "TileSpacing", "compact", "Padding", "compact");
plotRampPanel(nexttile(layout), T, keys, labels, colors, styles, markers, "C");
plotRampPanel(nexttile(layout), T, keys, labels, colors, styles, markers, "ESR");
exportVector(f, fullfile(outDir, "fig_joint_ramp.pdf"));
end

function plotRampPanel(ax, T, keys, labels, colors, styles, markers, parameter)
hold(ax, "on");
truth = sortrows(T(T.method == keys(1), :), "time_s");
if parameter == "C"
    truthY = 1e6 * truth.C_true;
    yField = "C_est";
    scale = 1e6;
    yLabel = "Capacitance (uF)";
    panelTitle = "(a) Capacitance trajectory";
    legendLocation = "northeast";
else
    truthY = truth.ESR_true;
    yField = "ESR_est";
    scale = 1;
    yLabel = "ESR (ohm)";
    panelTitle = "(b) ESR trajectory";
    legendLocation = "northwest";
end
plot(ax, truth.time_s, truthY, "k--", "LineWidth", 1.25, ...
    "DisplayName", "Truth");
for m = 1:3
    rows = sortrows(T(T.method == keys(m), :), "time_s");
    markerIndex = unique(round(linspace(1, height(rows), 7)));
    plot(ax, rows.time_s, scale * rows.(yField), ...
        "LineStyle", styles(m), "Marker", markers(m), ...
        "MarkerIndices", markerIndex, "MarkerSize", 4.6, ...
        "MarkerFaceColor", "white", "Color", colors(m, :), ...
        "DisplayName", labels(m));
end
hold(ax, "off");
xlabel(ax, "Time (s)");
ylabel(ax, yLabel);
title(ax, panelTitle, "FontWeight", "normal");
legend(ax, "Location", legendLocation, "Box", "off");
formatAxes(ax);
end

function makeComplexityPareto(root, outDir, keys, labels, colors, markers)
staticSource = fullfile(root, "tables", "table_algorithm_static_comparison.csv");
complexitySource = fullfile(root, "tables", "table_algorithm_complexity.csv");
S = readtable(staticSource, "TextType", "string", "VariableNamingRule", "preserve");
S = orderByMethod(S(S.mode == "Native", :), keys);
C = readtable(complexitySource, "TextType", "string", "VariableNamingRule", "preserve");
C = orderByMethod(C, keys);

x = C.multiplications_per_observation;
y = mean([S.C_mean_MAPE_percent, S.ESR_mean_MAPE_percent], 2);

f = newFigure(3.5, 2.55);
ax = axes(f);
hold(ax, "on");
for m = 1:3
    scatter(ax, x(m), y(m), 54, colors(m, :), markers(m), "filled", ...
        "MarkerEdgeColor", [0.10 0.10 0.10], "LineWidth", 0.7);
    text(ax, x(m) + 1.2, y(m), labels(m), ...
        "HorizontalAlignment", "left", "VerticalAlignment", "middle");
end
hold(ax, "off");
xlabel(ax, "Multiplications per accepted observation");
ylabel(ax, "Mean of C/ESR MAPE (%)");
xlim(ax, [22 72]);
yPad = 0.10 * range(y);
ylim(ax, [min(y) - yPad, max(y) + yPad]);
formatAxes(ax);
exportVector(f, fullfile(outDir, "fig_complexity_pareto.pdf"));
end

function T = orderByMethod(T, keys)
ordered = T([],:);
for key = keys
    rows = T(T.method == key, :);
    assert(height(rows) == 1, "Expected one row for method %s.", key);
    ordered = [ordered; rows]; %#ok<AGROW>
end
T = ordered;
end

function y = ylimData(T, field)
y = T.(field);
end

function drawVectorBars(ax, values, colors)
holdState = ishold(ax);
hold(ax, "on");
for m = 1:3
    rectangle(ax, "Position", [m - 0.34, 0, 0.68, values(m)], ...
        "FaceColor", colors(m, :), "EdgeColor", [0.15 0.15 0.15], ...
        "LineWidth", 0.8);
end
xlim(ax, [0.5 3.5]);
if ~holdState
    hold(ax, "off");
end
end

function [handles, xPositions] = drawGroupedVectorBars(ax, values, colors)
holdState = ishold(ax);
hold(ax, "on");
offsets = [-0.24, 0, 0.24];
barWidth = 0.20;
handles = gobjects(3, 1);
xPositions = zeros(2, 3);
for q = 1:2
    for m = 1:3
        x = q + offsets(m);
        value = values(q, m);
        y0 = min(0, value);
        xPositions(q, m) = x;
        h = rectangle(ax, "Position", [x - barWidth/2, y0, barWidth, abs(value)], ...
            "FaceColor", colors(m, :), "EdgeColor", [0.15 0.15 0.15], ...
            "LineWidth", 0.8);
        if q == 1
            handles(m) = h;
        end
    end
end
xlim(ax, [0.5 2.5]);
if ~holdState
    hold(ax, "off");
end
end

function f = newFigure(widthIn, heightIn)
f = figure("Visible", "off", "Color", "w", "Renderer", "painters", ...
    "Units", "inches", "Position", [1 1 widthIn heightIn]);
end

function formatAxes(ax)
set(ax, "FontName", "Times New Roman", "FontSize", 8, ...
    "LineWidth", 0.7, "Box", "on", "TickDir", "out", ...
    "XGrid", "on", "YGrid", "on", "GridAlpha", 0.16, ...
    "MinorGridAlpha", 0.08, "Layer", "top");
end

function exportVector(f, path)
exportgraphics(f, path, "ContentType", "vector", ...
    "BackgroundColor", "white");
close(f);
end
