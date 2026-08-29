function t = tokens()
%TOKENS Single source of truth for all figure design tokens.
%   Any color, size, font, or style used by a manuscript figure MUST come
%   from here. See FIGURE_STANDARD.md for the governing rules.

% --- Method identity (fixed across the whole paper; never reassign) ---
t.methods = ["M1 TS-D-RLS", "M2 TS-SLTVKE", "M3 Dual EKF", "M4 TS-SRKE"];
t.labels  = ["TS-D-RLS", "TS-SLTVKE", "Dual EKF", "TS-SRKE"];
t.colors  = [0.00 0.35 0.70;    % TS-D-RLS   blue
             0.85 0.33 0.10;    % TS-SLTVKE  orange
             0.30 0.60 0.25;    % Dual EKF   green
             0.45 0.18 0.60];   % TS-SRKE    violet (primary)
t.styles  = ["-", "--", "-.", ":"];
t.markers = ["o", "s", "^", "d"];

% --- Semantic colors (shared with the TikZ figures) ---
t.esrBlue    = [34 91 151] / 255;    % edge/ESR direction
t.capOrange  = [190 92 20] / 255;    % charge/C direction
t.superViolet= [115 46 153] / 255;   % supervisor
t.truthStyle = "k--";                % truth is always black dashed
t.refGray    = [0.4 0.4 0.4];        % event/reference lines

% --- Typography (Times, sized for 1:1 placement) ---
t.font        = "Times New Roman";
t.tickPt      = 7;
t.labelPt     = 8;    % axis labels via LabelFontSizeMultiplier
t.annotPt     = 7;    % legends, in-axes text
t.panelPt     = 8;    % (a)(b) markers

% --- Geometry ---
t.colWidthIn  = 3.5;   % single-column figures (placed at \columnwidth)
t.spanWidthIn = 5.87;  % fig* placed at 0.82\textwidth
t.axisLw      = 0.6;
t.dataLw      = 1.15;
t.legendEdge  = [0.45 0.45 0.45];
t.legendLw    = 0.4;
end
