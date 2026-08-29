function [caseTable, bases] = v23_modelb_device_data(v23Root, cfg)
%V23_MODELB_DEVICE_DATA Run Model B and extract device-level stimuli.

repoRoot = fileparts(v23Root);
addpath(genpath(fullfile(repoRoot, "cuk_cap_health_verification")), ...
    genpath(fullfile(repoRoot, "verification_v2")), ...
    genpath(fullfile(repoRoot, "verification_v21")), ...
    genpath(v23Root));

n = numel(cfg.operatingCases);
bases = cell(n, 1);
rows = cell(n, 18);
for k = 1:n
    op = cfg.operatingCases(k);
    p = model_parameters();
    p.Vin = op.Vin;
    p.D = op.D;
    p.Rload = op.Rload;
    base = run_modelB_v21(fullfile(repoRoot, "verification_v21"), p, ...
        cfg.modelBESLH, cfg.modelBDurationS);
    base.vCplus = (1 - base.u) .* base.vT;
    base.vCminus = -base.u .* base.vT;
    base.vCM = .5 * (base.vCplus + base.vCminus);
    bases{k} = base;
    tail = base.t >= base.t(end) - 12 * p.Ts;
    edge = local_edge_stats(base, tail);
    charge = local_charge_stats(base, p, tail, cfg.guardUs * 1e-6);
    rows(k, :) = {string(op.name), op.Vin, op.D, op.Rload, ...
        min(base.i1(tail)), max(base.i1(tail)), min(base.i2(tail)), ...
        max(base.i2(tail)), edge.i1, edge.i2, edge.iSum, ...
        charge.qCoulomb, median(base.vT(tail)), max(base.vT(tail)), ...
        min(base.vCM(tail)), max(base.vCM(tail)), edge.slope, ...
        min([base.i1(tail); base.i2(tail)]) > 0};
end
names = ["operating_case" "Vin_V" "D" "Rload_Ohm" ...
    "i1_min_A" "i1_max_A" "i2_min_A" "i2_max_A" ...
    "i1_edge_A" "i2_edge_A" "I_sum_edge_A" "Q_safe_C" ...
    "vT_median_V" "vT_max_V" "plant_vCM_min_V" "plant_vCM_max_V" ...
    "edge_slope_V_per_s" "CCM"];
caseTable = cell2table(rows, VariableNames=names);
assert(all(caseTable.CCM), "v23:NonCCM", ...
    "The selected representative Model B cases must remain CCM.");
end

function s = local_edge_stats(base, tail)
idx = find(abs(diff(base.u)) > .5) + 1;
idx = idx(tail(idx));
idx = idx(max(1, end - 19):end);
dv = abs(gradient(base.vT, base.dt));
near = false(size(base.t));
for k = reshape(idx, 1, [])
    near = near | abs(base.t - base.t(k)) <= 2e-6;
end
s = struct("i1", median(base.i1(idx)), "i2", median(base.i2(idx)), ...
    "iSum", median(base.i1(idx) + base.i2(idx)), ...
    "slope", prctile(dv(near), 75));
end

function s = local_charge_stats(base, p, tail, guard)
rising = find(diff(base.u) > .5) + 1;
rising = rising(tail(rising));
rising = rising(max(1, end - 11):end);
charges = zeros(2 * numel(rising), 1);
q = 0;
for k = reshape(rising, 1, [])
    tr = base.t(k);
    masks = {base.t >= tr + guard & base.t <= tr + p.D * p.Ts - guard, ...
        base.t >= tr + p.D * p.Ts + guard & base.t <= tr + p.Ts - guard};
    for j = 1:2
        if nnz(masks{j}) >= 3
            q = q + 1;
            charges(q) = abs(trapz(base.t(masks{j}), base.iC(masks{j})));
        end
    end
end
s = struct("qCoulomb", median(charges(1:q)));
end
