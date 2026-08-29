function f = newFigure(widthIn, heightIn)
%NEWFIGURE Vector-renderer figure at final placement size (rule G1/G2).
f = figure("Visible", "off", "Color", "w", "Renderer", "painters", ...
    "Units", "inches", "Position", [1 1 widthIn heightIn]);
end
