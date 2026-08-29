function apply(f)
%APPLY Enforce the axis contract on every axes of figure F (rules A1-A6).
%   Ticks only bottom/left; frame closed by data-space constant lines that
%   track any late relayout (the overlay-axes approach drifts on export);
%   Times 7/8 pt hierarchy; no grids; no in-figure titles; data-line
%   weight above axis weight. Call AFTER all plotting, BEFORE panelLabel.
t = figstyle.tokens();
drawnow;
for a = findall(f, "Type", "axes")'
    set(a, "Box", "off", "TickDir", "out", ...
        "FontName", t.font, "FontSize", t.tickPt, ...
        "LabelFontSizeMultiplier", t.labelPt / t.tickPt, ...
        "LineWidth", t.axisLw, "XGrid", "off", "YGrid", "off", ...
        "XMinorTick", "off", "YMinorTick", "off", ...
        "XMinorGrid", "off", "YMinorGrid", "off", "Layer", "top");
    for h = findall(a, "Type", "line")'
        if h.LineWidth < 1.1 && ~isempty(h.LineStyle) && ...
                ~strcmp(h.LineStyle, "none")
            h.LineWidth = t.dataLw;
        end
    end
    delete(get(a, "Title"));                       % rule A4: no titles
    xl = xlim(a); yl = ylim(a); xlim(a, xl); ylim(a, yl);
    if strcmp(get(a, "XDir"), "reverse")
        rightEdge = xl(1);
    else
        rightEdge = xl(2);
    end
    hx = xline(a, rightEdge, "-", "Color", get(a, "XColor"), ...
        "LineWidth", t.axisLw);
    hy = yline(a, yl(2), "-", "Color", get(a, "YColor"), ...
        "LineWidth", t.axisLw);
    hx.Annotation.LegendInformation.IconDisplayStyle = "off";
    hy.Annotation.LegendInformation.IconDisplayStyle = "off";
end
set(findall(f, "Type", "text"), "FontName", t.font);
set(findall(f, "Type", "legend"), "FontName", t.font, ...
    "FontSize", t.annotPt);
set(findall(f, "Type", "constantline"), "FontName", t.font);
end
