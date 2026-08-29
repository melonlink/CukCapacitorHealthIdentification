%% Audit Paper Verification v1 outputs
scriptDir = fileparts(mfilename('fullpath'));
packageRoot = fileparts(scriptDir);
tableDir = fullfile(packageRoot, 'results', 'tables');
figureDir = fullfile(packageRoot, 'results', 'figures');
rawDir = fullfile(packageRoot, 'results', 'raw');

mandatory = {
    fullfile(packageRoot, 'literature', 'SOTA_LITERATURE_MATRIX.csv')
    fullfile(packageRoot, 'literature', 'SOTA_REVIEW.md')
    fullfile(packageRoot, 'literature', 'NOVELTY_BOUNDARY.md')
    fullfile(packageRoot, 'baselines', 'LOCKED_HYPERPARAMETERS.csv')
    fullfile(tableDir, 'table_paper_sota_comparison.csv')
    fullfile(tableDir, 'table_paper_ablation.csv')
    fullfile(tableDir, 'table_paper_PE_analysis.csv')
    fullfile(tableDir, 'table_paper_complexity.csv')
    fullfile(tableDir, 'table_paper_blind_cases.csv')
    fullfile(tableDir, 'table_modelB_anchor_traceability.csv')
    fullfile(packageRoot, 'result_metrics_paper_v1.csv')
    fullfile(packageRoot, 'PAPER_THEORY_PROOF.md')
    fullfile(packageRoot, 'SOTA_COMPARISON.md')
    fullfile(packageRoot, 'ABLATION_RESULTS.md')
    fullfile(packageRoot, 'PAPER_VERIFICATION_RESULT.md')
    fullfile(packageRoot, 'PAPER_READY_RESULTS.md')
    fullfile(packageRoot, 'PAPER_CONTRIBUTIONS_DRAFT.md')
    fullfile(packageRoot, 'BASELINE_PROTOCOL.md')
    fullfile(packageRoot, 'README.md')
    };
figureNames = compose('fig_paper_%02d_', 1:12);
for i = 1:numel(mandatory)
    assert(isfile(mandatory{i}), 'paper:audit:MissingFile', ...
        'Missing mandatory file: %s', mandatory{i});
end
allFigures = dir(fullfile(figureDir, 'fig_paper_*.png'));
assert(numel(allFigures) == 12, 'paper:audit:FigureCount', ...
    'Expected exactly 12 paper figures, found %d.', numel(allFigures));
for i = 1:12
    assert(any(startsWith(string({allFigures.name}), figureNames(i))), ...
        'paper:audit:FigureSequence', 'Missing paper figure sequence %02d.', i);
end

literature = readtable(fullfile(packageRoot, 'literature', 'SOTA_LITERATURE_MATRIX.csv'), ...
    'TextType', 'string');
assert(height(literature) >= 20, 'paper:audit:LiteratureCount', ...
    'Literature count is below 20.');
requiredMetadata = {'title', 'authors', 'year', 'venue', 'DOI_or_URL', ...
    'converter_topology', 'estimated_parameters', 'method', 'validation'};
for i = 1:numel(requiredMetadata)
    v = literature.(requiredMetadata{i});
    assert(~any(ismissing(v) | strlength(string(v)) == 0), ...
        'paper:audit:LiteratureMetadata', 'Missing metadata in %s.', requiredMetadata{i});
end
assert(sum(literature.direct_joint_C_ESR == "Yes") >= 8);
assert(sum(literature.kalman_class == "Yes") >= 4);
assert(sum(literature.rls_ls_class == "Yes") >= 4);
assert(sum(literature.inherent_no_injection == "Yes") >= 3);
assert(sum(literature.wavelet_reconstruction == "Yes") >= 2);
assert(sum(literature.Cuk_diagnosis_prognostic == "Yes") >= 3);

locked = readtable(fullfile(packageRoot, 'baselines', 'LOCKED_HYPERPARAMETERS.csv'), ...
    'TextType', 'string');
lockedFlag = lower(string(locked.locked_before_blind));
assert(all(lockedFlag == "true" | lockedFlag == "1"), 'paper:audit:UnlockedParameter', ...
    'At least one hyperparameter is not locked.');

cases = readtable(fullfile(tableDir, 'table_paper_blind_cases.csv'), 'TextType', 'string');
modelBAnchors = readtable(fullfile(tableDir, 'table_modelB_anchor_traceability.csv'), ...
    'TextType', 'string');
blind = readtable(fullfile(rawDir, 'blind_algorithm_rows.csv'), 'TextType', 'string');
assert(height(modelBAnchors) == 45, 'paper:audit:ModelBAnchorCount', ...
    'Expected 45 frozen Model-B anchors.');
assert(all(contains(modelBAnchors.source_file, "modelB_edge_traces_v21.mat")), ...
    'paper:audit:ModelBAnchorSource', 'Model-B source traceability is incomplete.');
assert(height(cases) >= 36, 'paper:audit:BlindCaseCount', 'Fewer than 36 blind cases.');
algorithms = unique(blind.algorithm, 'stable');
assert(numel(algorithms) == 6, 'paper:audit:AlgorithmCount', ...
    'Expected B0-B4 plus TS-SLTVKE.');
expectedRows = height(cases) * 4 * 4 * numel(algorithms);
assert(height(blind) == expectedRows, 'paper:audit:CherryPick', ...
    'Blind row count mismatch: expected %d, found %d.', expectedRows, height(blind));
numericVars = {'C_true_F', 'ESR_true_ohm', 'C_est_F', 'ESR_est_ohm', ...
    'C_error_percent', 'ESR_error_percent', 'C_variance', 'ESR_variance'};
for i = 1:numel(numericVars)
    assert(all(isfinite(blind.(numericVars{i}))), 'paper:audit:Nonfinite', ...
        'Nonfinite value in %s.', numericVars{i});
end
conditionKey = blind.case_id + "|" + blind.noise_profile + "|" + string(blind.skew_ns);
[groups, ~, groupIndex] = unique(conditionKey);
for i = 1:numel(groups)
    rows = groupIndex == i;
    assert(numel(unique(blind.seed(rows))) == 1, 'paper:audit:SeedMismatch', ...
        'Algorithms used different seeds for condition %s.', groups(i));
    assert(numel(unique(blind.algorithm(rows))) == numel(algorithms), ...
        'paper:audit:MissingAlgorithmRow', 'Condition %s is incomplete.', groups(i));
end

ablation = readtable(fullfile(tableDir, 'table_paper_ablation.csv'), 'TextType', 'string');
assert(isequal(unique(ablation.variant, 'stable'), ["A0"; "A1"; "A2"; "A3"; "A4"; "A5"; "A6"]), ...
    'paper:audit:AblationOrder', 'A0-A6 are missing or reordered.');
assert(numel(unique(ablation.scenario)) >= 7, 'paper:audit:AblationScenarios');
assert(all(isfinite(ablation.C_MAPE_percent)) && all(isfinite(ablation.ESR_MAPE_percent)), ...
    'paper:audit:AblationNonfinite');

pe = readtable(fullfile(tableDir, 'table_paper_PE_analysis.csv'));
assert(all(pe.mu_C > 0) && all(pe.mu_R > 0));
assert(corr(log10(pe.mu_C), log10(pe.empirical_variance_C)) < 0, ...
    'paper:audit:PEDirectionC', 'C information/variance direction is not inverse.');
assert(corr(log10(pe.mu_R), log10(pe.empirical_variance_R)) < 0, ...
    'paper:audit:PEDirectionR', 'ESR information/variance direction is not inverse.');

theory = fileread(fullfile(packageRoot, 'PAPER_THEORY_PROOF.md'));
assert(contains(theory, 'Proposition 1') && contains(theory, 'Proposition 2'));
assert(contains(theory, 'Global asymptotic convergence is not claimed'));
resultReport = fileread(fullfile(packageRoot, 'PAPER_VERIFICATION_RESULT.md'));
metricsPath = fullfile(packageRoot, 'result_metrics_paper_v1.csv');
metricOptions = detectImportOptions(metricsPath, 'TextType', 'string');
metricOptions = setvartype(metricOptions, metricOptions.VariableNames, 'string');
metricOptions.DataLines = [2, Inf];
metrics = readtable(metricsPath, metricOptions);
decisionIndex = find(strcmpi(string(metrics.metric), "decision"), 1, 'first');
assert(~isempty(decisionIndex), 'paper:audit:DecisionMissing', ...
    'Decision row is missing from result_metrics_paper_v1.csv.');
decisionText = char(string(metrics{decisionIndex, 'value'}));
assert(contains(resultReport, decisionText), 'paper:audit:ReportMetricMismatch', ...
    'Decision does not match metrics CSV.');

auditPath = fullfile(packageRoot, 'logs', 'audit_paper_verification_v1.txt');
fid = fopen(auditPath, 'w', 'n', 'UTF-8');
assert(fid >= 0, 'paper:audit:LogOpen');
cleaner = onCleanup(@() fclose(fid));
fprintf(fid, 'PAPER VERIFICATION V1 AUDIT: PASS\n');
fprintf(fid, 'literature_rows=%d\n', height(literature));
fprintf(fid, 'blind_cases=%d\n', height(cases));
fprintf(fid, 'modelB_anchors=%d\n', height(modelBAnchors));
fprintf(fid, 'blind_algorithm_rows=%d\n', height(blind));
fprintf(fid, 'algorithms=%s\n', strjoin(algorithms, ';'));
fprintf(fid, 'ablation_rows=%d\n', height(ablation));
fprintf(fid, 'pe_rows=%d\n', height(pe));
fprintf(fid, 'figures=%d\n', numel(allFigures));
fprintf(fid, 'decision=%s\n', decisionText);
fprintf('PAPER VERIFICATION V1 AUDIT: PASS\n');
