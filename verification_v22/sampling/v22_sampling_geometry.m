function geometryTable = v22_sampling_geometry(v22Root, cfg, baselineTable, bases)
%V22_SAMPLING_GEOMETRY Optimize locked g/W/Nw for each ADC rate.

tableDir = fullfile(v22Root, "results", "tables");
rawDir = fullfile(v22Root, "results", "raw");
nRows = numel(cfg.adcRatesHz) * numel(cfg.guardsUs) * ...
    numel(cfg.windowsUs) * numel(cfg.pointsPerSide);
rows = cell(nRows, 16);
row = 0;
for fsAdc = cfg.adcRatesHz
    Ta = 1 / fsAdc;
    for guardUs = cfg.guardsUs
        for windowUs = cfg.windowsUs
            pointsAvailable = floor(windowUs * 1e-6 / Ta + 1e-10) + 1;
            marginUs = min(min([baselineTable.D, 1 - baselineTable.D], [], 2) ...
                * cfg.Ts - (guardUs + windowUs) * 1e-6) * 1e6;
            for pointsRequired = cfg.pointsPerSide
                geometryPass = pointsAvailable >= pointsRequired && marginUs >= 0;
                if geometryPass
                    [biasPct, kR] = modelb_bias(bases, fsAdc, ...
                        guardUs * 1e-6, windowUs * 1e-6);
                else
                    biasPct = NaN;
                    kR = NaN;
                end
                residualPass = cfg.phaseResidualNs * 1e-3 < guardUs;
                row = row + 1;
                rows(row, :) = {fsAdc, Ta, guardUs, windowUs, pointsRequired, ...
                    pointsAvailable, marginUs, geometryPass, biasPct, kR, ...
                    residualPass, false, NaN, NaN, NaN, ...
                    "designed_PWM_SOC_burst"};
            end
        end
    end
end
names = ["fs_adc_Hz" "adc_interval_s" "guard_us" "window_us" ...
    "points_required_per_side" "points_available_per_side" ...
    "minimum_topology_margin_us" "sampling_geometry_feasible" ...
    "modelB_worst_extrapolation_bias_percent" "modelB_median_kR" ...
    "residual_50ns_inside_guard" "selected" "locked_guard_us" ...
    "locked_window_us" "locked_points_per_side" "trigger_mode"];
geometryTable = cell2table(rows, VariableNames=names);

for fsAdc = cfg.adcRatesHz
    idx = find(geometryTable.fs_adc_Hz == fsAdc & ...
        geometryTable.sampling_geometry_feasible & ...
        geometryTable.residual_50ns_inside_guard & ...
        geometryTable.modelB_worst_extrapolation_bias_percent < 5);
    if isempty(idx)
        continue
    end
    candidate = geometryTable(idx, :);
    candidate.neg_points = -candidate.points_required_per_side;
    candidate = sortrows(candidate, ["window_us" "guard_us" ...
        "neg_points" "modelB_worst_extrapolation_bias_percent"]);
    chosen = idx(geometryTable(idx, :).guard_us == candidate.guard_us(1) & ...
        geometryTable(idx, :).window_us == candidate.window_us(1) & ...
        geometryTable(idx, :).points_required_per_side == ...
        candidate.points_required_per_side(1));
    chosen = chosen(1);
    geometryTable.selected(chosen) = true;
    geometryTable.locked_guard_us(geometryTable.fs_adc_Hz == fsAdc) = ...
        geometryTable.guard_us(chosen);
    geometryTable.locked_window_us(geometryTable.fs_adc_Hz == fsAdc) = ...
        geometryTable.window_us(chosen);
    geometryTable.locked_points_per_side(geometryTable.fs_adc_Hz == fsAdc) = ...
        geometryTable.points_required_per_side(chosen);
end
writetable(geometryTable, fullfile(tableDir, "table_native_adc_geometry_v22.csv"));
save(fullfile(rawDir, "native_adc_geometry_v22.mat"), "geometryTable");
end

function [worstBias, medianKR] = modelb_bias(bases, fsAdc, g, W)
Ta = 1 / fsAdc;
preT = -(g + (0:floor(W / Ta + 1e-10)) * Ta)';
postT = -flipud(preT);
bias = [];
kValues = [];
for b = 1:numel(bases)
    base = bases{b};
    edgeIdx = find(abs(diff(base.u)) > .5) + 1;
    edgeIdx = edgeIdx(edgeIdx > numel(base.t) * .7);
    edgeIdx = edgeIdx(max(1, end - 11):end);
    for k = reshape(edgeIdx, 1, [])
        te = base.t(k);
        if te + max(postT) > base.t(end) || te + min(preT) < base.t(1)
            continue
        end
        vPre = interp1(base.t, base.vT, te + preT, "linear");
        vPost = interp1(base.t, base.vT, te + postT, "linear");
        pPre = polyfit(preT * 1e6, vPre, 1);
        pPost = polyfit(postT * 1e6, vPost, 1);
        observed = abs(pPost(2) - pPre(2));
        iSum = interp1(base.t, base.i1 + base.i2, te, "linear");
        truth = .05 * iSum;
        kR = observed / max(truth, eps);
        kValues(end + 1, 1) = kR; %#ok<AGROW>
        bias(end + 1, 1) = 100 * abs(kR - 1); %#ok<AGROW>
    end
end
worstBias = prctile(bias, 95);
medianKR = median(kValues);
if isempty(bias) || any(~isfinite([worstBias medianKR]))
    worstBias = 100;
    medianKR = NaN;
end
end
