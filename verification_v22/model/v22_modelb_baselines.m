function [baselineTable, budgetTable, currentRangeTable, bases] = ...
        v22_modelb_baselines(v22Root, cfg)
%V22_MODELB_BASELINES Run Model B and derive signal/current budgets.

repoRoot = fileparts(v22Root);
addpath(genpath(fullfile(repoRoot, "cuk_cap_health_verification")), ...
    genpath(fullfile(repoRoot, "verification_v2")), ...
    genpath(fullfile(repoRoot, "verification_v21")), ...
    genpath(v22Root));
tableDir = fullfile(v22Root, "results", "tables");
rawDir = fullfile(v22Root, "results", "raw");

nCases = numel(cfg.operatingCases);
bases = cell(nCases, 1);
rows = cell(nCases, 17);
for k = 1:nCases
    op = cfg.operatingCases(k);
    p = model_parameters();
    p.Vin = op.Vin;
    p.D = op.D;
    p.Rload = op.Rload;
    base = run_modelB_v21(fullfile(repoRoot, "verification_v21"), p, ...
        cfg.modelBESLH, cfg.modelBDurationS);
    bases{k} = base;
    tail = base.t >= base.t(end) - 12 * p.Ts;
    edge = edge_statistics(base, p, tail);
    q = charge_statistics(base, p, tail, .5e-6);
    isCcm = min([base.i1(tail); base.i2(tail)]) > 0;
    rows(k, :) = {string(op.name), op.Vin, op.D, op.Rload, ...
        string(op.loadLabel), isCcm, min(base.i1(tail)), max(base.i1(tail)), ...
        min(base.i2(tail)), max(base.i2(tail)), edge.i1, edge.i2, ...
        edge.iSum, q.qCoulomb, median(base.vT(tail)), edge.slope, ...
        max(base.vT(tail))};
end
names = ["operating_case" "Vin_V" "D" "Rload_Ohm" "load" "CCM" ...
    "i1_min_A" "i1_max_A" "i2_min_A" "i2_max_A" "i1_edge_A" ...
    "i2_edge_A" "I_sum_edge_A" "Q_safe_C" "vT_baseline_V" ...
    "edge_slope_V_per_s" "vT_max_V"];
baselineTable = cell2table(rows, VariableNames=names);
assert(all(baselineTable.CCM), "v22:NonCCMBaseline", ...
    "All representative v2.2 baselines must be CCM.");

peakCurrent = max([baselineTable.i1_max_A; baselineTable.i2_max_A]);
candidate = cfg.currentMargins(:) * peakCurrent;
standard = zeros(size(candidate));
for k = 1:numel(candidate)
    idx = find(cfg.standardCurrentRangesA >= candidate(k), 1, "first");
    standard(k) = cfg.standardCurrentRangesA(idx);
end
currentRangeTable = table(cfg.currentMargins(:), repmat(peakCurrent, ...
    numel(candidate), 1), candidate, standard, peakCurrent ./ standard, ...
    VariableNames=["transient_margin" "max_observed_current_A" ...
    "minimum_full_scale_A" "engineering_full_scale_A" ...
    "peak_code_utilization_fraction"]);

nBudget = nCases * numel(cfg.CFactors) * numel(cfg.ESRFactors);
budgetRows = cell(nBudget, 13);
row = 0;
for k = 1:nCases
    b = baselineTable(k, :);
    for cFactor = cfg.CFactors
        for rFactor = cfg.ESRFactors
            row = row + 1;
            cValue = cfg.C0 * cFactor;
            rValue = cfg.ESR0 * rFactor;
            edgeMv = 1e3 * rValue * b.I_sum_edge_A;
            chargeMv = 1e3 * b.Q_safe_C / cValue;
            budgetRows(row, :) = {b.operating_case, b.Vin_V, b.D, b.load, ...
                cValue, rValue, b.i1_edge_A, b.i2_edge_A, b.I_sum_edge_A, ...
                edgeMv, chargeMv, b.Q_safe_C, b.vT_baseline_V};
        end
    end
end
budgetNames = ["operating_case" "Vin" "D" "load" "C" "ESR" ...
    "i1" "i2" "I_sum" "edge_ESR_signal_mV" "charge_C_signal_mV" ...
    "Q_safe_C" "vT_baseline_V"];
budgetTable = cell2table(budgetRows, VariableNames=budgetNames);
budgetTable.edge_global_min_mV(:) = min(budgetTable.edge_ESR_signal_mV);
budgetTable.edge_global_median_mV(:) = median(budgetTable.edge_ESR_signal_mV);
budgetTable.edge_global_max_mV(:) = max(budgetTable.edge_ESR_signal_mV);
budgetTable.charge_global_min_mV(:) = min(budgetTable.charge_C_signal_mV);
budgetTable.charge_global_median_mV(:) = median(budgetTable.charge_C_signal_mV);
budgetTable.charge_global_max_mV(:) = max(budgetTable.charge_C_signal_mV);

writetable(baselineTable, fullfile(tableDir, "table_modelB_baselines_v22.csv"));
writetable(budgetTable, fullfile(tableDir, "table_health_signal_budget_v22.csv"));
writetable(currentRangeTable, ...
    fullfile(tableDir, "table_current_range_design_v22.csv"));
save(fullfile(rawDir, "modelB_baselines_v22.mat"), "baselineTable", ...
    "budgetTable", "currentRangeTable", "bases", "-v7.3");
end

function stats = edge_statistics(base, p, tail)
idx = find(abs(diff(base.u)) > .5) + 1;
idx = idx(tail(idx));
idx = idx(max(1, end - 19):end);
i1 = base.i1(idx);
i2 = base.i2(idx);
dv = abs(gradient(base.vT, base.dt));
near = false(size(base.t));
for k = reshape(idx, 1, [])
    near = near | abs(base.t - base.t(k)) <= 2e-6;
end
stats = struct("i1", median(i1), "i2", median(i2), ...
    "iSum", median(i1 + i2), "slope", prctile(dv(near), 75));
if ~isfinite(stats.slope) || stats.slope == 0
    stats.slope = p.ESR * stats.iSum / 1e-6;
end
end

function stats = charge_statistics(base, p, tail, guard)
rising = find(diff(base.u) > .5) + 1;
rising = rising(tail(rising));
rising = rising(max(1, end - 11):end);
charges = [];
for k = reshape(rising, 1, [])
    tr = base.t(k);
    tf = tr + p.D * p.Ts;
    tn = tr + p.Ts;
    on = base.t >= tr + guard & base.t <= tf - guard;
    off = base.t >= tf + guard & base.t <= tn - guard;
    if nnz(on) >= 3
        charges(end + 1, 1) = abs(trapz(base.t(on), base.iC(on))); %#ok<AGROW>
    end
    if nnz(off) >= 3
        charges(end + 1, 1) = abs(trapz(base.t(off), base.iC(off))); %#ok<AGROW>
    end
end
stats = struct("qCoulomb", median(charges));
end
