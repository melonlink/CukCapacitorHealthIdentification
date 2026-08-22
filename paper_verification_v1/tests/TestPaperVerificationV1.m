classdef TestPaperVerificationV1 < matlab.unittest.TestCase
    % Persistent output and evidence-chain tests for Paper Verification v1.

    properties (Constant)
        PackageRoot = fileparts(fileparts(mfilename('fullpath')))
    end

    properties (TestParameter)
        RequiredAlgorithm = {"B0 Closed-form", "B1 RLS", ...
            "B2 Augmented EKF", "B3 Dual EKF", ...
            "B4 Cuk-adapted wavelet-KF", "TS-SLTVKE"}
    end

    methods (TestClassSetup)
        function addScriptPath(testCase)
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture(fullfile(testCase.PackageRoot, 'scripts')));
        end
    end

    methods (Test)
        function blindSetIsComplete(testCase)
            cases = readtable(fullfile(testCase.PackageRoot, 'results', 'tables', ...
                'table_paper_blind_cases.csv'), 'TextType', 'string');
            rows = readtable(fullfile(testCase.PackageRoot, 'results', 'raw', ...
                'blind_algorithm_rows.csv'), 'TextType', 'string');
            testCase.verifyEqual(height(cases), 48);
            testCase.verifyEqual(height(rows), 48 * 4 * 4 * 6);
            testCase.verifyFalse(any(~isfinite(rows.C_error_percent)));
            testCase.verifyFalse(any(~isfinite(rows.ESR_error_percent)));
        end

        function eachAlgorithmIsPresent(testCase, RequiredAlgorithm)
            rows = readtable(fullfile(testCase.PackageRoot, 'results', 'raw', ...
                'blind_algorithm_rows.csv'), 'TextType', 'string');
            testCase.verifyTrue(any(rows.algorithm == RequiredAlgorithm));
        end

        function frozenModelBAnchorsAreLoaded(testCase)
            anchors = readtable(fullfile(testCase.PackageRoot, 'results', 'tables', ...
                'table_modelB_anchor_traceability.csv'), 'TextType', 'string');
            testCase.verifyEqual(height(anchors), 45);
            testCase.verifyTrue(all(contains(anchors.source_file, ...
                "modelB_edge_traces_v21.mat")));
            testCase.verifyGreaterThan(median(anchors.median_I_sum_A), 0);
        end

        function seedsAndTestSetsAreShared(testCase)
            rows = readtable(fullfile(testCase.PackageRoot, 'results', 'raw', ...
                'blind_algorithm_rows.csv'), 'TextType', 'string');
            key = rows.case_id + "|" + rows.noise_profile + "|" + string(rows.skew_ns);
            [~, ~, idx] = unique(key);
            seedSpread = splitapply(@(x) max(x) - min(x), rows.seed, idx);
            algorithmCount = splitapply(@(x) numel(unique(x)), rows.algorithm, idx);
            testCase.verifyEqual(seedSpread, zeros(size(seedSpread)));
            testCase.verifyEqual(algorithmCount, 6 * ones(size(algorithmCount)));
        end

        function ablationOrderAndGainsExist(testCase)
            a = readtable(fullfile(testCase.PackageRoot, 'results', 'tables', ...
                'table_paper_ablation.csv'), 'TextType', 'string');
            testCase.verifyEqual(unique(a.variant, 'stable'), ...
                ["A0"; "A1"; "A2"; "A3"; "A4"; "A5"; "A6"]);
            testCase.verifyGreaterThanOrEqual(numel(unique(a.scenario)), 7);
            testCase.verifyTrue(all(isfinite(a.C_absolute_gain)));
            testCase.verifyTrue(all(isfinite(a.ESR_absolute_gain)));
        end

        function peHasExpectedDirection(testCase)
            p = readtable(fullfile(testCase.PackageRoot, 'results', 'tables', ...
                'table_paper_PE_analysis.csv'));
            testCase.verifyLessThan(corr(log10(p.mu_C), ...
                log10(p.empirical_variance_C)), 0);
            testCase.verifyLessThan(corr(log10(p.mu_R), ...
                log10(p.empirical_variance_R)), 0);
            testCase.verifyTrue(all(p.CRLB_C <= p.empirical_variance_C));
            testCase.verifyTrue(all(p.CRLB_R <= p.empirical_variance_R));
        end

        function literatureCoveragePasses(testCase)
            l = readtable(fullfile(testCase.PackageRoot, 'literature', ...
                'SOTA_LITERATURE_MATRIX.csv'), 'TextType', 'string');
            testCase.verifyGreaterThanOrEqual(height(l), 20);
            testCase.verifyGreaterThanOrEqual(sum(l.direct_joint_C_ESR == "Yes"), 8);
            testCase.verifyGreaterThanOrEqual(sum(l.kalman_class == "Yes"), 4);
            testCase.verifyGreaterThanOrEqual(sum(l.rls_ls_class == "Yes"), 4);
            testCase.verifyGreaterThanOrEqual(sum(l.inherent_no_injection == "Yes"), 3);
            testCase.verifyGreaterThanOrEqual(sum(l.wavelet_reconstruction == "Yes"), 2);
            testCase.verifyGreaterThanOrEqual(sum(l.Cuk_diagnosis_prognostic == "Yes"), 3);
        end

        function mandatoryReportsAndFiguresExist(testCase)
            reports = ["PAPER_THEORY_PROOF.md", "SOTA_COMPARISON.md", ...
                "ABLATION_RESULTS.md", "PAPER_VERIFICATION_RESULT.md", ...
                "PAPER_READY_RESULTS.md", "PAPER_CONTRIBUTIONS_DRAFT.md"];
            for i = 1:numel(reports)
                testCase.verifyTrue(isfile(fullfile(testCase.PackageRoot, reports(i))));
            end
            figures = dir(fullfile(testCase.PackageRoot, 'results', 'figures', ...
                'fig_paper_*.png'));
            testCase.verifyEqual(numel(figures), 12);
        end
    end
end
