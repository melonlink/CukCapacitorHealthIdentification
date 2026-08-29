function tableOut = ltv_observability(data, windowLengths, options)
%LTV_OBSERVABILITY Compute finite-window LTV observability metrics.

if nargin < 2 || isempty(windowLengths), windowLengths = [3, 5, 10]; end
if nargin < 3, options = struct(); end
stride = get_option(options, "sampleStride", 1);
alphaScale = 1e-4;
idx = (1:stride:numel(data.t))';
t = data.t(idx);
iC = data.iC(idx);
rows = [];

for nWin = windowLengths
    ranks = [];
    sigmaMin = [];
    conditions = [];
    starts = 1:max(1, floor((numel(idx)-nWin)/50)):numel(idx)-nWin;
    for k0 = starts
        transition = eye(3);
        O = zeros(nWin, 3);
        for j = 1:nWin
            k = k0+j-1;
            H = [1, 0, iC(k)];
            O(j, :) = H*transition;
            if j < nWin
                q = 0.5*(iC(k)+iC(k+1))*(t(k+1)-t(k));
                F = [1, q/alphaScale, 0; 0, 1, 0; 0, 0, 1];
                transition = F*transition;
            end
        end
        s = svd(O);
        ranks(end+1,1) = rank(O); %#ok<AGROW>
        sigmaMin(end+1,1) = s(end); %#ok<AGROW>
        conditions(end+1,1) = cond(O); %#ok<AGROW>
    end
    rows = [rows; nWin, min(ranks), median(ranks), min(sigmaMin), ...
        median(sigmaMin), max(conditions), median(conditions)]; %#ok<AGROW>
end
tableOut = array2table(rows, "VariableNames", ...
    ["window_N","rank_min","rank_median","sigma_min_worst", ...
     "sigma_min_median","condition_worst","condition_median"]);
end

function value = get_option(options, name, defaultValue)
if isfield(options, name), value = options.(name); else, value = defaultValue; end
end

