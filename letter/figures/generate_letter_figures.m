function generate_letter_figures()
%GENERATE_LETTER_FIGURES Draw the letter figure from frozen campaign CSVs.
% TPEL style: no in-figure titles, panel labels below panels, ticks only
% bottom/left, framed in-axes legend, Times 7/8 pt, upright units.

scriptDir = fileparts(mfilename("fullpath"));
repoRoot = fileparts(fileparts(scriptDir));
tabDir = fullfile(repoRoot, "campaigns", "hybrid_estimator_v1", ...
    "results", "tables");

Tc = readtable(fullfile(tabDir, "table_letter_traj_cstep.csv"), ...
    "TextType", "string");
Tr = readtable(fullfile(tabDir, "table_letter_traj_esrstep.csv"), ...
    "TextType", "string");

colors = struct("RLS", [0.00 0.35 0.70], "KF", [0.85 0.33 0.10], ...
    "HYBRID", [0.30 0.60 0.25]);
styles = struct("RLS", "-", "KF", "--", "HYBRID", "-");
labels = struct("RLS", "TS-D-RLS", "KF", "Kalman kernel", ...
    "HYBRID", "supervised hybrid");

set(groot, "defaultAxesFontName", "Times New Roman", ...
    "defaultAxesFontSize", 7, "defaultTextFontName", "Times New Roman", ...
    "defaultTextFontSize", 7, "defaultLegendFontName", "Times New Roman", ...
    "defaultLegendFontSize", 7, "defaultLineLineWidth", 1.15);

f = figure("Visible","off","Color","w","Renderer","painters", ...
    "Units","inches","Position",[1 1 3.5 3.9]);
tl = tiledlayout(f, 2, 1, "TileSpacing", "compact", "Padding", "compact");

ax1 = nexttile(tl);
plotPanel(ax1, Tc, "C_uF", "Ctrue_uF", "sigmaC_uF", colors, styles, labels);
ylabel(ax1, ['Capacitance (' char(181) 'F)']);
ylim(ax1, [78 104]);
xticklabels(ax1, []);              % shared time axis: labels only on (b)
framedLegend(ax1);

ax2 = nexttile(tl);
plotPanel(ax2, Tr, "ESR_mOhm", "Rtrue_mOhm", "sigmaR_mOhm", ...
    colors, styles, labels);
ylabel(ax2, ['ESR (m' char(937) ')']);
ylim(ax2, [38 108]);
xlabel(ax2, "Time (ms)");

styleFigure(f);
panelLabel(ax1, "(a)", 0.05);
panelLabel(ax2, "(b)", 0.24);
exportgraphics(f, fullfile(scriptDir, "fig_step_recovery.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(f);
fprintf("Generated letter figure in %s\n", scriptDir);
end

function plotPanel(ax, T, yField, truthField, sigField, colors, styles, labels)
hold(ax, "on");
truth = T(T.method == "RLS", :);
tMs = truth.cycle * 0.02;
% Hybrid 95% interval band drawn first so lines sit on top.
H = T(T.method == "HYBRID", :);
tH = H.cycle * 0.02;
band = fill(ax, [tH; flipud(tH)], ...
    [H.(yField) - 1.96*H.(sigField); ...
     flipud(H.(yField) + 1.96*H.(sigField))], ...
    colors.HYBRID, "FaceAlpha", 0.15, "EdgeColor", "none");
band.Annotation.LegendInformation.IconDisplayStyle = "off";
plot(ax, tMs, truth.(truthField), "k--", "LineWidth", 1.2, ...
    "DisplayName", "truth");
for m = ["RLS", "KF", "HYBRID"]
    rows = T(T.method == m, :);
    plot(ax, rows.cycle * 0.02, rows.(yField), styles.(m), ...
        "Color", colors.(m), "DisplayName", labels.(m));
end
hold(ax, "off");
end

function framedLegend(ax)
lg = legend(ax, "Location", "southeast");
set(lg, "Box", "on", "EdgeColor", [0.45 0.45 0.45], "LineWidth", 0.4, ...
    "FontSize", 7);
end

function styleFigure(f)
drawnow;
for a = findall(f, "Type", "axes")'
    set(a, "Box", "off", "TickDir", "out", ...
        "FontName", "Times New Roman", "FontSize", 7, ...
        "LabelFontSizeMultiplier", 8/7, "LineWidth", 0.6, ...
        "XGrid", "off", "YGrid", "off", "Layer", "top");
    delete(get(a, "Title"));
    xl = xlim(a); yl = ylim(a); xlim(a, xl); ylim(a, yl);
    hx = xline(a, xl(2), "-", "Color", get(a, "XColor"), "LineWidth", 0.6);
    hy = yline(a, yl(2), "-", "Color", get(a, "YColor"), "LineWidth", 0.6);
    hx.Annotation.LegendInformation.IconDisplayStyle = "off";
    hy.Annotation.LegendInformation.IconDisplayStyle = "off";
end
set(findall(f, "Type", "text"), "FontName", "Times New Roman");
end

function panelLabel(ax, label, offsetNorm)
text(ax, 0.5, -offsetNorm, label, "Units", "normalized", ...
    "HorizontalAlignment", "center", "VerticalAlignment", "top", ...
    "FontName", "Times New Roman", "FontSize", 8, "Clipping", "off");
end
