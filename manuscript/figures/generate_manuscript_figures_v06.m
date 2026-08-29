function generate_manuscript_figures_v06()
%GENERATE_MANUSCRIPT_FIGURES_V06 Redraw all ten data figures from frozen CSVs.
% Sole figure entry point for the manuscript (v0.6, four methods).
% NORMATIVE RULES: figures/FIGURE_STANDARD.md. Style implementation:
% the +figstyle package (this file only delegates). Reads archived
% campaign CSV outputs only; runs no model or estimator.

scriptDir = fileparts(mfilename("fullpath"));
projectRoot = fileparts(fileparts(scriptDir));
campaignRoot = fullfile(projectRoot, "campaigns");

verificationRoot = fullfile(campaignRoot, "paper_verification_v13", "results");
selectionRoot = fullfile(campaignRoot, "paper_algorithm_selection_v3", "results");
supplementRoot = fullfile(campaignRoot, "closedloop_dcm_validation", ...
    "results", "tables");
crlbSource = fullfile(campaignRoot, "verification_v21", "results", ...
    "tables", "table_CRLB_v21.csv");

methodKeys = ["M1 TS-D-RLS", "M2 TS-SLTVKE", "M3 Dual EKF", "M4 TS-SRKE"];
methodLabels = ["TS-D-RLS", "TS-SLTVKE", "Dual EKF", "TS-SRKE"];
methodColors = [0.00 0.35 0.70; 0.85 0.33 0.10; 0.30 0.60 0.25; 0.45 0.18 0.60];
lineStyles = ["-", "--", "-.", ":"];
markers = ["o", "s", "^", "d"];

makeObservationEffect(verificationRoot, scriptDir, methodLabels, methodColors);
makeStaticComparison(selectionRoot, scriptDir, methodKeys, methodLabels, ...
    methodColors);
makeNoiseTiming(selectionRoot, scriptDir, methodKeys, methodLabels, ...
    methodColors, lineStyles, markers);
makeJointRamp(selectionRoot, scriptDir, methodKeys, methodLabels, ...
    methodColors, lineStyles, markers);
makeComplexityPareto(selectionRoot, scriptDir, methodKeys, methodLabels, ...
    methodColors, markers);
makePeLowerBound(fullfile(verificationRoot, "tables", ...
    "table_physical_PE_lower_bound.csv"), scriptDir);
makeCrlbEfficiency(crlbSource, scriptDir);
makeClosedLoop(supplementRoot, scriptDir);
makeLightLoad(fullfile(supplementRoot, "table_lightload_sweep.csv"), scriptDir);
makeAbruptRecovery(fullfile(selectionRoot, "raw", "abrupt_history.csv"), ...
    scriptDir, methodKeys, methodLabels, methodColors, lineStyles, markers);
makeSrkeClosedloop(fullfile(campaignRoot, "closedloop_srke_validation", ...
    "results", "tables", "table_srke_closedloop_history.csv"), scriptDir, ...
    methodLabels, methodColors, lineStyles, markers);
fprintf("Generated eleven v0.7 vector figures in %s\n", scriptDir);
end

function makeAbruptRecovery(source, outDir, keys, labels, colors, ...
    styles, markers)
T = readtable(source, "TextType", "string");
T = T(T.mode == "Equal-Report", :);
f = newFigure(3.5, 3.9);
tl = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");

ax1 = nexttile(tl);
hold(ax1, "on");
sub = T(T.trajectory_type == "C_abrupt", :);
truth = sortrows(sub(sub.method == keys(1), :), "time_s");
plot(ax1, truth.time_s * 1e3, truth.C_true * 1e6, "k--", ...
    "LineWidth", 1.2, "DisplayName", "truth");
for m = 1:numel(keys)
    rows = sortrows(sub(sub.method == keys(m), :), "time_s");
    plot(ax1, rows.time_s * 1e3, rows.C_est * 1e6, ...
        "LineStyle", styles(m), "Marker", markers(m), ...
        "MarkerSize", 4.2, "MarkerFaceColor", "white", ...
        "Color", colors(m, :), "DisplayName", labels(m));
end
hold(ax1, "off");
ylabel(ax1, ['Capacitance (' char(181) 'F)']);
xlim(ax1, [0 240]); ylim(ax1, [76 104]);
xticklabels(ax1, []);                 % shared time axis: labels on (b)
framedLegend(ax1, [], [], "northeast", "vertical");

ax2 = nexttile(tl);
hold(ax2, "on");
sub = T(T.trajectory_type == "ESR_abrupt", :);
truth = sortrows(sub(sub.method == keys(1), :), "time_s");
plot(ax2, truth.time_s * 1e3, truth.ESR_true * 1e3, "k--", ...
    "LineWidth", 1.2);
for m = 1:numel(keys)
    rows = sortrows(sub(sub.method == keys(m), :), "time_s");
    plot(ax2, rows.time_s * 1e3, rows.ESR_est * 1e3, ...
        "LineStyle", styles(m), "Marker", markers(m), ...
        "MarkerSize", 4.2, "MarkerFaceColor", "white", ...
        "Color", colors(m, :));
end
hold(ax2, "off");
ylabel(ax2, ['ESR (m' char(937) ')']);
xlabel(ax2, "Time (ms)");
xlim(ax2, [0 240]); ylim(ax2, [40 108]);

styleFigure(f);
panelLabel(ax1, "(a)", 0.05);
panelLabel(ax2, "(b)", 0.24);
exportVector(f, fullfile(outDir, "fig_abrupt_recovery.pdf"));
end

function makeSrkeClosedloop(source, outDir, labels, colors, styles, markers)
% Supervised vs unsupervised recovery under closed-loop regulation:
% (a) CLS-5 C step, (b) CLS-4 ESR step. Estimates normalized by the
% time-varying truth, so truth is the unit line. Health step at 30 ms.
T = readtable(source, "TextType", "string");
sel = [2, 4];                             % TS-SLTVKE (parent), TS-SRKE
f = newFigure(3.5, 3.9);
tl = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");

ax1 = nexttile(tl);
hold(ax1, "on");
hTruth = yline(ax1, 1, "k--", "LineWidth", 1.2);
xline(ax1, 30, "-", "Color", [0.4 0.4 0.4], "LineWidth", 0.6);
hM = gobjects(1, numel(sel));
sub = T(T.case_id == "CLS-5", :);
for m = 1:numel(sel)
    rows = sortrows(sub(sub.variant == labels(sel(m)), :), "time_ms");
    hM(m) = plot(ax1, rows.time_ms, rows.C_norm, ...
        "LineStyle", styles(sel(m)), "Marker", markers(sel(m)), ...
        "MarkerSize", 4.2, "MarkerFaceColor", "white", ...
        "MarkerIndices", 1:25:height(rows), ...
        "Color", colors(sel(m), :), "LineWidth", 1.15);
end
hold(ax1, "off");
ylabel(ax1, "{\itC}_{est} / {\itC}_{true}");
xlim(ax1, [20 45]); ylim(ax1, [0.88 1.44]);
xticklabels(ax1, []);                     % shared time axis: labels on (b)
framedLegend(ax1, [hTruth, hM], ["truth", labels(sel)], ...
    "northeast", "vertical");

ax2 = nexttile(tl);
hold(ax2, "on");
yline(ax2, 1, "k--", "LineWidth", 1.2);
xline(ax2, 30, "-", "Color", [0.4 0.4 0.4], "LineWidth", 0.6);
sub = T(T.case_id == "CLS-4", :);
for m = 1:numel(sel)
    rows = sortrows(sub(sub.variant == labels(sel(m)), :), "time_ms");
    plot(ax2, rows.time_ms, rows.ESR_norm, ...
        "LineStyle", styles(sel(m)), "Marker", markers(sel(m)), ...
        "MarkerSize", 4.2, "MarkerFaceColor", "white", ...
        "MarkerIndices", 1:25:height(rows), ...
        "Color", colors(sel(m), :), "LineWidth", 1.15);
end
hold(ax2, "off");
ylabel(ax2, "{\itr}_{C,est} / {\itr}_{C,true}");
xlabel(ax2, "Time (ms)");
xlim(ax2, [20 45]); ylim(ax2, [0.42 1.12]);

styleFigure(f);
panelLabel(ax1, "(a)", 0.05);
panelLabel(ax2, "(b)", 0.24);
exportVector(f, fullfile(outDir, "fig_srke_closedloop.pdf"));
end

%% ------------------------------------------------------------------ figures

function makeObservationEffect(root, outDir, labels, colors)
T = readtable(fullfile(root, "tables", ...
    "table_observation_effect_bootstrap.csv"), ...
    "TextType", "string", "VariableNamingRule", "preserve");
estimatorKeys = ["E1 RLS", "E3 LTV/Joseph", "E2 Dual EKF"];
metrics = ["C_MAPE", "C_p95"; "ESR_MAPE", "ESR_p95"];

f = newFigure(3.5, 4.35);
tl = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");
axList = gobjects(2, 1);
for p = 1:2
    ax = nexttile(tl);
    axList(p) = ax;
    means = zeros(2, 3); lower = zeros(2, 3); upper = zeros(2, 3);
    for q = 1:2
        for m = 1:3
            row = T(T.estimator == estimatorKeys(m) & ...
                T.metric == metrics(p, q), :);
            assert(height(row) == 1, "Unexpected effect row count.");
            means(q, m) = row.mean_paired_effect;
            lower(q, m) = means(q, m) - row.ci95_low;
            upper(q, m) = row.ci95_high - means(q, m);
        end
    end
    hold(ax, "on");
    [~, xPos] = drawGroupedBars(ax, means, colors);
    hLeg = gobjects(3, 1);
    for m = 1:3
        hLeg(m) = plot(ax, nan, nan, "s", "MarkerSize", 5, ...
            "MarkerFaceColor", colors(m, :), ...
            "MarkerEdgeColor", [0.15 0.15 0.15], "LineStyle", "none");
    end
    for q = 1:2
        errorbar(ax, xPos(q, :), means(q, :), lower(q, :), upper(q, :), ...
            "k.", "LineWidth", 1.0, "CapSize", 4);
    end
    yline(ax, 0, "k--", "LineWidth", 0.8);
    hold(ax, "off");
    xticks(ax, 1:2);
    ylabel(ax, ['O0 ' char(8722) ' O1 effect (percentage points)']);
    if p == 1
        xticklabels(ax, []);          % shared category axis: labels only on
        ylim(ax, [0 16.5]);           % the bottom panel (headroom for legend)
        yticks(ax, 0:4:16);
        framedLegend(ax, hLeg, labels(1:3), "north", "horizontal");
    else
        xticklabels(ax, ["Mean MAPE", "p95 error"]);
    end
end
styleFigure(f);
panelLabel(axList(1), "(a)", 0.05);
panelLabel(axList(2), "(b)", 0.13);
exportVector(f, fullfile(outDir, "fig_observation_effect.pdf"));
end

function makeStaticComparison(root, outDir, keys, labels, colors)
T = readtable(fullfile(root, "tables", ...
    "table_algorithm_static_comparison.csv"), ...
    "TextType", "string", "VariableNamingRule", "preserve");
T = orderByMethod(T(T.mode == "Native", :), keys);

f = newFigure(3.5, 3.8);
tl = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");
values = [T.C_mean_MAPE_percent, T.ESR_mean_MAPE_percent];
axList = gobjects(2, 1);
for p = 1:2
    ax = nexttile(tl);
    axList(p) = ax;
    drawBars(ax, values(:, p), colors);
    xticks(ax, 1:numel(labels));
    if p == 2
        xticklabels(ax, labels);      % shared method axis: labels only on
    else                              % the bottom panel
        xticklabels(ax, []);
    end
    ylabel(ax, "Mean MAPE (%)");
    ylim(ax, [0, 1.12 * max(values(:, p))]);
end
styleFigure(f);
panelLabel(axList(1), "(a)", 0.05);
panelLabel(axList(2), "(b)", 0.14);
exportVector(f, fullfile(outDir, "fig_static_comparison.pdf"));
end

function makeNoiseTiming(root, outDir, keys, labels, colors, styles, markers)
T = readtable(fullfile(root, "tables", "table_algorithm_noise_timing.csv"), ...
    "TextType", "string", "VariableNamingRule", "preserve");
T = T(T.mode == "Native" & T.noise_profile == "F28379D_device_realistic", :);

f = newFigure(3.5, 4.15);
tl = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");
fields = ["C_p95_percent", "ESR_p95_percent"];
axList = gobjects(2, 1);
for p = 1:2
    ax = nexttile(tl);
    axList(p) = ax;
    hold(ax, "on");
    for m = 1:numel(keys)
        rows = sortrows(T(T.method == keys(m), :), "skew_ns");
        plot(ax, rows.skew_ns, rows.(fields(p)), "LineStyle", styles(m), ...
            "Marker", markers(m), "Color", colors(m, :), ...
            "MarkerSize", 4.8, "MarkerFaceColor", "white", ...
            "DisplayName", labels(m));
    end
    hold(ax, "off");
    ylabel(ax, "p95 error (%)");
    xticks(ax, [0 20 50 100]);
    ylim(ax, [0, 1.12 * max(T.(fields(p)))]);
    if p == 1
        xticklabels(ax, []);          % shared time axis: labels and axis
        framedLegend(ax, [], [], "southeast", "vertical");
    else                              % title only on the bottom panel
        xlabel(ax, "Residual timing skew (ns)");
        framedLegend(ax, [], [], "northwest", "vertical");
    end
end
styleFigure(f);
panelLabel(axList(1), "(a)", 0.05);
panelLabel(axList(2), "(b)", 0.24);
exportVector(f, fullfile(outDir, "fig_noise_timing.pdf"));
end

function makeJointRamp(root, outDir, keys, labels, colors, styles, markers)
T = readtable(fullfile(root, "raw", "ramp_history.csv"), ...
    "TextType", "string", "VariableNamingRule", "preserve");
T = T(T.trajectory_type == "joint_ramp" & ...
    T.source_model == "TRACE_DERIVED_OBSERVATION" & ...
    T.trajectory_duration_s == 1, :);

f = newFigure(5.87, 2.75);
tl = tiledlayout(f, 1, 2, "TileSpacing", "compact", "Padding", "compact");
tl.OuterPosition = [0 0.09 1 0.91];   % bottom margin for the panel labels
ax1 = nexttile(tl);
plotRampPanel(ax1, T, keys, labels, colors, styles, markers, "C");
ax2 = nexttile(tl);
plotRampPanel(ax2, T, keys, labels, colors, styles, markers, "ESR");
styleFigure(f);
panelLabel(ax1, "(a)", 0.26);
panelLabel(ax2, "(b)", 0.26);
exportVector(f, fullfile(outDir, "fig_joint_ramp.pdf"));
end

function plotRampPanel(ax, T, keys, labels, colors, styles, markers, parameter)
hold(ax, "on");
truth = sortrows(T(T.method == keys(1), :), "time_s");
if parameter == "C"
    truthY = 1e6 * truth.C_true;
    yField = "C_est"; scale = 1e6;
    yLabel = ['Capacitance (' char(181) 'F)'];
    legendLocation = "northeast";
else
    truthY = 1e3 * truth.ESR_true;
    yField = "ESR_est"; scale = 1e3;
    yLabel = ['ESR (m' char(937) ')'];
    legendLocation = "northwest";
end
plot(ax, truth.time_s, truthY, "k--", "LineWidth", 1.25, ...
    "DisplayName", "Truth");
for m = 1:numel(keys)
    rows = sortrows(T(T.method == keys(m), :), "time_s");
    markerIndex = unique(min(max(round(linspace(1, height(rows), 7)) + ...
        3 * (m - 1), 1), height(rows)));   % stagger coincident markers
    plot(ax, rows.time_s, scale * rows.(yField), ...
        "LineStyle", styles(m), "Marker", markers(m), ...
        "MarkerIndices", markerIndex, "MarkerSize", 4.6, ...
        "MarkerFaceColor", "white", "Color", colors(m, :), ...
        "DisplayName", labels(m));
end
hold(ax, "off");
xlabel(ax, "Time (s)");
ylabel(ax, yLabel);
framedLegend(ax, [], [], legendLocation, "vertical");
end

function makeComplexityPareto(root, outDir, keys, labels, colors, markers)
S = readtable(fullfile(root, "tables", ...
    "table_algorithm_static_comparison.csv"), ...
    "TextType", "string", "VariableNamingRule", "preserve");
S = orderByMethod(S(S.mode == "Native", :), keys);
C = readtable(fullfile(root, "tables", "table_algorithm_complexity.csv"), ...
    "TextType", "string", "VariableNamingRule", "preserve");
C = orderByMethod(C, keys);
x = C.multiplications_per_observation;
y = mean([S.C_mean_MAPE_percent, S.ESR_mean_MAPE_percent], 2);

f = newFigure(3.5, 2.55);
ax = axes(f);
hold(ax, "on");
for m = 1:numel(keys)
    scatter(ax, x(m), y(m), 54, colors(m, :), markers(m), "filled", ...
        "MarkerEdgeColor", [0.10 0.10 0.10], "LineWidth", 0.7);
    if labels(m) == "TS-SLTVKE"
        text(ax, x(m) - 1.2, y(m), labels(m), "HorizontalAlignment", ...
            "right", "VerticalAlignment", "middle", "FontSize", 7);
    else
        text(ax, x(m) + 1.2, y(m), labels(m), "HorizontalAlignment", ...
            "left", "VerticalAlignment", "middle", "FontSize", 7);
    end
end
hold(ax, "off");
xlabel(ax, "Multiplications per accepted observation");
ylabel(ax, "Mean of C/ESR MAPE (%)");
xlim(ax, [22 75]);
yPad = 0.10 * range(y);
ylim(ax, [min(y) - yPad, max(y) + yPad]);
styleFigure(f);
exportVector(f, fullfile(outDir, "fig_complexity_pareto.pdf"));
end

function makePeLowerBound(source, outDir)
T = readtable(source, "TextType", "string");
f = newFigure(3.5, 2.9);
ax = axes(f);
h1 = loglog(ax, T.mu_C_lower, T.mu_C_empirical, "o", ...
    "Color", [0.00 0.35 0.70], "MarkerSize", 4.5, "LineWidth", 0.9);
hold(ax, "on");
h2 = loglog(ax, T.mu_R_lower, T.mu_R_empirical, "s", ...
    "Color", [0.85 0.33 0.10], "MarkerSize", 4.5, "LineWidth", 0.9);
allVals = [T.mu_C_lower; T.mu_C_empirical; T.mu_R_lower; T.mu_R_empirical];
lims = [min(allVals) * 0.5, max(allVals) * 2];
h3 = loglog(ax, lims, lims, "k:", "LineWidth", 0.8);
xlim(ax, lims); ylim(ax, lims);
xlabel(ax, "Conservative lower bound");
ylabel(ax, "Empirical finite-window information");
framedLegend(ax, [h1 h2 h3], ...
    ["{\it\alpha}_b direction", "{\itr}_C direction", "equality"], ...
    "northwest", "vertical");
styleFigure(f);
exportVector(f, fullfile(outDir, "fig_pe_lower_bound.pdf"));
end

function makeCrlbEfficiency(source, outDir)
T = readtable(source, "TextType", "string");
n = height(T);
x = (1:n)';
f = newFigure(3.5, 2.9);
ax = axes(f);
h1 = semilogy(ax, x, T.rmse_to_crlb_C, "o", "Color", [0.00 0.35 0.70], ...
    "MarkerSize", 4.5, "LineWidth", 0.9);
hold(ax, "on");
h2 = semilogy(ax, x, T.rmse_to_crlb_ESR, "s", "Color", [0.85 0.33 0.10], ...
    "MarkerSize", 4.5, "LineWidth", 0.9);
yline(ax, 1, "k:", "LineWidth", 0.8);
ylim(ax, [0.5, 100]);
xlim(ax, [0.5, n + 0.5]);
set(ax, "XTick", x, "XTickLabel", T.level, "XTickLabelRotation", 45);
dims = T.sensitivity_dimension;
edges = find(dims(1:end-1) ~= dims(2:end));
for e = edges'
    xline(ax, e + 0.5, "-", "Color", [0.75 0.75 0.75], "LineWidth", 0.5);
end
groupStarts = [1; edges + 1]; groupEnds = [edges; n];
for g = 1:numel(groupStarts)
    text(ax, (groupStarts(g) + groupEnds(g)) / 2, 62, dims(groupStarts(g)), ...
        "HorizontalAlignment", "center", "FontSize", 7, ...
        "Color", [0.25 0.25 0.25]);
end
ylabel(ax, ['RMSE / ' char(8730) 'CRLB']);
framedLegend(ax, [h1 h2], ["capacitance", "ESR"], "southwest", "horizontal");
styleFigure(f);
exportVector(f, fullfile(outDir, "fig_crlb_efficiency.pdf"));
end

function makeClosedLoop(root, outDir)
H = readtable(fullfile(root, "table_closedloop_history.csv"), ...
    "TextType", "string");
caseIds = unique(H.case_id, "stable");
colors = [0.00 0.35 0.70; 0.85 0.33 0.10; 0.30 0.60 0.25];
styles = ["-", "--", "-."];
shortLabels = ["load step", "{\itV}_{in} step", "{\itV}_{ref} step"];

f = newFigure(3.5, 4.7);
tl = tiledlayout(f, 3, 1, "TileSpacing", "compact", "Padding", "compact");

ax1 = nexttile(tl);
hold(ax1, "on");
hCase = gobjects(numel(caseIds), 1);
for c = 1:numel(caseIds)
    rows = H(H.case_id == caseIds(c), :);
    hCase(c) = plot(ax1, rows.time_ms, rows.duty, styles(c), ...
        "Color", colors(c, :));
end
xline(ax1, 30, ":", "Color", [0.4 0.4 0.4]);
text(ax1, 29.2, 0.345, "transition", "FontSize", 7, ...
    "Color", [0.35 0.35 0.35], "HorizontalAlignment", "right");
ylabel(ax1, "Duty ratio");
ylim(ax1, [0.33 0.42]);
xticklabels(ax1, []);                 % shared time axis: labels only on (c)
framedLegend(ax1, hCase, shortLabels, "southwest", "vertical");

ax2 = nexttile(tl);
hold(ax2, "on");
for c = 1:numel(caseIds)
    rows = H(H.case_id == caseIds(c), :);
    plot(ax2, rows.time_ms, rows.C_norm, styles(c), "Color", colors(c, :));
end
yline(ax2, 1, "k:"); xline(ax2, 30, ":", "Color", [0.4 0.4 0.4]);
ylabel(ax2, "{\itC}_{est} / {\itC}");
ylim(ax2, [0.9 1.2]);
xticklabels(ax2, []);

ax3 = nexttile(tl);
hold(ax3, "on");
for c = 1:numel(caseIds)
    rows = H(H.case_id == caseIds(c), :);
    plot(ax3, rows.time_ms, rows.ESR_norm, styles(c), "Color", colors(c, :));
end
yline(ax3, 1, "k:"); xline(ax3, 30, ":", "Color", [0.4 0.4 0.4]);
ylabel(ax3, "{\itr}_{C,est} / {\itr}_C");
xlabel(ax3, "Time (ms)");
ylim(ax3, [0.6 1.1]);

styleFigure(f);
panelLabel(ax1, "(a)", 0.05);
panelLabel(ax2, "(b)", 0.05);
panelLabel(ax3, "(c)", 0.24);
exportVector(f, fullfile(outDir, "fig_closedloop.pdf"));
end

function makeLightLoad(source, outDir)
T = readtable(source, "TextType", "string");
f = newFigure(3.5, 3.75);
tl = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");

ax1 = nexttile(tl);
hold(ax1, "on");
h1 = plot(ax1, T.load_percent, T.ccm_cycle_percent, "-o", ...
    "Color", [0.00 0.35 0.70], "MarkerSize", 4);
h2 = plot(ax1, T.load_percent, T.valid_R_percent, "--s", ...
    "Color", [0.85 0.33 0.10], "MarkerSize", 4);
set(ax1, "XScale", "log", "XDir", "reverse", ...
    "XTick", [10 20 50 100], "XTickLabel", []);
ylabel(ax1, "Cycle acceptance (%)");   % shared load axis: labels only on (b)
ylim(ax1, [-5 105]);
text(ax1, 7.6, 22, "all cycles" + newline + "rejected", "FontSize", 7, ...
    "Color", [0.35 0.35 0.35], "HorizontalAlignment", "center");
framedLegend(ax1, [h1 h2], ["CCM-valid cycles", "accepted edge rows"], ...
    "southwest", "vertical");

ax2 = nexttile(tl);
hold(ax2, "on");
okIdx = T.ccm_cycle_percent > 0;
plot(ax2, T.load_percent(okIdx), T.tail_C_error_percent(okIdx), "-o", ...
    "Color", [0.00 0.35 0.70], "MarkerSize", 4, ...
    "DisplayName", "capacitance");
plot(ax2, T.load_percent(okIdx), T.tail_ESR_error_percent(okIdx), "--s", ...
    "Color", [0.85 0.33 0.10], "MarkerSize", 4, "DisplayName", "ESR");
set(ax2, "XScale", "log", "XDir", "reverse", "YScale", "log", ...
    "XTick", [10 20 50 100], "XTickLabel", ["10" "20" "50" "100"], ...
    "YTick", [0.01 0.1 1]);
xlabel(ax2, "Load fraction (%)");
ylabel(ax2, "Endpoint error (%)");
ylim(ax2, [0.005 3]);
framedLegend(ax2, [], [], "southwest", "horizontal");

styleFigure(f);
panelLabel(ax1, "(a)", 0.05);
panelLabel(ax2, "(b)", 0.26);
exportVector(f, fullfile(outDir, "fig_lightload.pdf"));
end

%% ------------------------------------------------------------ style engine
% Single implementation lives in the +figstyle package (see
% FIGURE_STANDARD.md). These wrappers only delegate.

function f = newFigure(widthIn, heightIn)
f = figstyle.newFigure(widthIn, heightIn);
end

function styleFigure(f)
figstyle.apply(f);
end

function panelLabel(ax, label, offsetNorm)
figstyle.panelLabel(ax, label, offsetNorm);
end

function framedLegend(ax, handles, labels, location, orientation)
figstyle.framedLegend(ax, handles, labels, location, orientation);
end

function exportVector(f, path)
figstyle.exportVector(f, path);
end

%% ----------------------------------------------------------------- helpers

function T = orderByMethod(T, keys)
ordered = T([], :);
for key = keys
    rows = T(T.method == key, :);
    assert(height(rows) == 1, "Expected one row for method %s.", key);
    ordered = [ordered; rows]; %#ok<AGROW>
end
T = ordered;
end

function drawBars(ax, values, colors)
hold(ax, "on");
for m = 1:numel(values)
    rectangle(ax, "Position", [m - 0.34, 0, 0.68, values(m)], ...
        "FaceColor", colors(m, :), "EdgeColor", [0.15 0.15 0.15], ...
        "LineWidth", 0.8);
end
xlim(ax, [0.5, numel(values) + 0.5]);
end

function [handles, xPositions] = drawGroupedBars(ax, values, colors)
offsets = [-0.24, 0, 0.24];
barWidth = 0.20;
handles = gobjects(3, 1);
xPositions = zeros(2, 3);
for q = 1:2
    for m = 1:3
        x = q + offsets(m);
        value = values(q, m);
        xPositions(q, m) = x;
        h = rectangle(ax, "Position", ...
            [x - barWidth/2, min(0, value), barWidth, abs(value)], ...
            "FaceColor", colors(m, :), "EdgeColor", [0.15 0.15 0.15], ...
            "LineWidth", 0.8);
        if q == 1, handles(m) = h; end
    end
end
xlim(ax, [0.5 2.5]);
end

