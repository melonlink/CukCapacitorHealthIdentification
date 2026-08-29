function panelLabel(ax, label, offsetNorm)
%PANELLABEL Centered (a)/(b) marker below the panel (rule P1-P3).
%   offsetNorm ~0.05 for panels without x tick labels, ~0.13 with tick
%   labels, ~0.24 with tick labels plus an axis title. The figure must
%   leave physical bottom margin for the bottom row (rule P3).
t = figstyle.tokens();
text(ax, 0.5, -offsetNorm, label, "Units", "normalized", ...
    "HorizontalAlignment", "center", "VerticalAlignment", "top", ...
    "FontName", t.font, "FontSize", t.panelPt, "FontWeight", "normal", ...
    "Clipping", "off");
end
