%% Audit Paper Verification v1.1 generated evidence.

scriptDir = fileparts(mfilename("fullpath"));
packageRoot = string(fileparts(scriptDir));
repoRoot = string(fileparts(packageRoot));
tableDir = fullfile(packageRoot, "results", "tables");
rawDir = fullfile(packageRoot, "results", "raw");
figureDir = fullfile(packageRoot, "results", "figures");

factorial = readtable(fullfile(rawDir, "factorial_rows.csv"), ...
    TextType="string");
factorialSummary = readtable(fullfile(tableDir, ...
    "table_observation_estimator_factorial.csv"), TextType="string");
bootstrap = readtable(fullfile(tableDir, ...
    "table_observation_effect_bootstrap.csv"), TextType="string");
dynamic = readtable(fullfile(tableDir, ...
    "table_factorial_dynamic.csv"), TextType="string");
pe = readtable(fullfile(tableDir, ...
    "table_physical_PE_lower_bound.csv"), TextType="string");
covariance = readtable(fullfile(tableDir, ...
    "table_covariance_bound_validation.csv"), TextType="string");
projection = readtable(fullfile(tableDir, ...
    "table_projection_on_off.csv"), TextType="string");
hyperparameters = readtable(fullfile(packageRoot, ...
    "LOCKED_FACTORIAL_HYPERPARAMETERS.csv"), TextType="string");
metricsPath = fullfile(packageRoot, "result_metrics_paper_v11.csv");
metricsOptions = detectImportOptions(metricsPath, TextType="string");
metricsOptions = setvartype(metricsOptions, ["metric", "value", "unit"], ...
    "string");
metrics = readtable(metricsPath, metricsOptions);

assert(height(factorial) == 4608, "pv11audit:FactorialRows");
assert(height(factorialSummary) == 6, "pv11audit:FactorialCells");
cellCounts = groupcounts(factorial, ["observation", "estimator"]);
assert(all(cellCounts.GroupCount == 768), "pv11audit:CellCount");
assert(numel(unique(factorial.observation)) == 2, ...
    "pv11audit:ObservationCount");
assert(numel(unique(factorial.estimator)) == 3, ...
    "pv11audit:EstimatorCount");

o0 = sortrows(factorial(factorial.observation == "O0 Mixed", :), ...
    ["estimator", "case_id", "noise_profile", "skew_ns", "seed"]);
o1 = sortrows(factorial(factorial.observation == "O1 Proposed", :), ...
    ["estimator", "case_id", "noise_profile", "skew_ns", "seed"]);
pairVars = ["estimator", "case_id", "noise_profile", "skew_ns", "seed"];
assert(isequal(o0(:, pairVars), o1(:, pairVars)), ...
    "pv11audit:PairingMismatch");
assert(all(hyperparameters.applies_to_O0) && ...
    all(hyperparameters.applies_to_O1), ...
    "pv11audit:HyperparameterObservationSplit");
assert(all(hyperparameters.locked_before_blind), ...
    "pv11audit:UnlockedHyperparameter");
assert(height(bootstrap) == 18 && ...
    all(bootstrap.bootstrap_replicates == 10000), ...
    "pv11audit:BootstrapCompleteness");
assert(all(ismember(["C_MAPE", "ESR_MAPE", "C_p95", "ESR_p95", ...
    "timing_failure", "convergence"], unique(bootstrap.metric))), ...
    "pv11audit:BootstrapMetricMissing");
assert(height(dynamic) == 18, "pv11audit:DynamicCompleteness");

assert(height(pe) >= 36, "pv11audit:PeCaseCount");
assert(all(pe.mu_C_lower > 0) && all(pe.mu_R_lower > 0), ...
    "pv11audit:NonpositivePeLowerBound");
assert(all(pe.ratio_C >= 1 - 1e-10) && ...
    all(pe.ratio_R >= 1 - 1e-10), ...
    "pv11audit:PeLowerBoundViolation");
assert(all(pe.sign_invariant), "pv11audit:ChargeSignViolation");

fixedPoint = (-covariance.Q_N + sqrt(covariance.Q_N.^2 + ...
    4 * covariance.Q_N ./ covariance.mu_lower)) / 2;
assert(all(abs(fixedPoint - covariance.P_star) <= ...
    1e-10 .* max(1, abs(fixedPoint))), ...
    "pv11audit:FixedPointEquationMismatch");
assert(all(covariance.bound_pass), ...
    "pv11audit:CovarianceEnvelopeFailure");
assert(all(covariance.Q0_sanity_max_error <= 1e-12), ...
    "pv11audit:Q0SanityFailure");

assert(height(projection) == 2 && all(projection.N_seeds == 200), ...
    "pv11audit:ProjectionSeedCount");
assert(any(projection.projection_state == "OFF"), ...
    "pv11audit:ProjectionOffMissing");

requiredReports = [
    "FACTORIAL_PROTOCOL.md"
    "OBSERVATION_FACTORIAL_RESULTS.md"
    "PAPER_THEORY_PROOF_V11.md"
    "PAPER_VERIFICATION_V11_RESULT.md"
    "PAPER_READY_UPDATE_V11.md"
    ];
assert(all(isfile(fullfile(packageRoot, requiredReports))), ...
    "pv11audit:RequiredReportMissing");
requiredFigures = "fig_pv11_" + compose("%02d", (1:10).') + [
    "_factorial_C.png"
    "_factorial_ESR.png"
    "_observation_effect.png"
    "_factorial_timing.png"
    "_factorial_dynamic.png"
    "_accuracy_robustness_pareto.png"
    "_covariance_bound_C.png"
    "_covariance_bound_ESR.png"
    "_PE_lower_bound.png"
    "_projection_on_off.png"
    ];
assert(all(isfile(fullfile(figureDir, requiredFigures))), ...
    "pv11audit:RequiredFigureMissing");

decisionValue = string(metrics{metrics.metric == "freeze_decision", "value"});
verificationText = string(fileread(fullfile(packageRoot, ...
    "PAPER_VERIFICATION_V11_RESULT.md")));
assert(contains(verificationText, decisionValue), ...
    "pv11audit:DecisionTraceability");
assert(contains(verificationText, ...
    compose("%.6g", min(pe.mu_C_lower))) && ...
    contains(verificationText, compose("%.6g", min(pe.mu_R_lower))), ...
    "pv11audit:PeReportTraceability");

frozenPath = fullfile(repoRoot, "verification_v21", "algorithms", ...
    "structured_ltv_estimator_v21.m");
assert(sha256File(frozenPath) == ...
    "6B59445898F224C6C070B4E0C3B08E73C7500B5385F912BB058BADBC6AD67225", ...
    "pv11audit:FrozenCoreModified");

auditLines = [
    "PAPER VERIFICATION V1.1 AUDIT"
    "timestamp=" + string(datetime("now", Format="yyyy-MM-dd HH:mm:ss"))
    "factorial_rows=" + string(height(factorial))
    "factorial_cells=" + string(height(factorialSummary))
    "paired_bootstrap_rows=" + string(height(bootstrap))
    "dynamic_rows=" + string(height(dynamic))
    "physical_PE_cases=" + string(height(pe))
    "covariance_cases=" + string(height(covariance))
    "projection_seeds_per_state=" + string(projection.N_seeds(1))
    "negative_observation_effects_retained=" + ...
        string(sum(bootstrap.mean_paired_effect < 0))
    "frozen_core_sha256=" + sha256File(frozenPath)
    "AUDIT=PASS"
    ];
auditPath = fullfile(packageRoot, "logs", ...
    "audit_paper_verification_v11.txt");
[fid, message] = fopen(auditPath, "w");
assert(fid >= 0, "pv11audit:AuditWriteFailure", "%s", message);
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, char(strjoin(auditLines, newline)), "char");
fprintf("Paper Verification v1.1 audit PASS.\n");

function hash = sha256File(path)
fid = fopen(path, "r");
assert(fid >= 0, "pv11audit:HashReadFailure");
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, "*uint8");
engine = java.security.MessageDigest.getInstance("SHA-256");
engine.update(bytes);
hash = upper(string(reshape(dec2hex(typecast(engine.digest(), ...
    "uint8"), 2).', 1, [])));
end
