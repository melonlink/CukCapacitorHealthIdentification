function framedLegend(ax, handles, labels, location, orientation)
%FRAMEDLEGEND In-axes framed legend (rule L1-L3).
%   Pass explicit handles whenever any plotted object (band, xline, frame
%   line) must stay out of the legend; the axes must reserve headroom so
%   the frame never covers the closed top edge.
t = figstyle.tokens();
if isempty(handles)
    lg = legend(ax, "Location", location);
else
    lg = legend(ax, handles, labels, "Location", location);
end
set(lg, "Box", "on", "EdgeColor", t.legendEdge, "LineWidth", t.legendLw, ...
    "FontSize", t.annotPt, "Orientation", orientation);
end
