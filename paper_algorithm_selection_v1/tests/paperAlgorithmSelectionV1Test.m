classdef paperAlgorithmSelectionV1Test < matlab.unittest.TestCase
    properties
        PackageRoot (1, 1) string
        TablesDir (1, 1) string
    end

    methods (TestMethodSetup)
        function addProjectPaths(testCase)
            import matlab.unittest.fixtures.PathFixture
            testDir = string(fileparts(mfilename("fullpath")));
            testCase.PackageRoot = string(fileparts(testDir));
            testCase.TablesDir = fullfile(testCase.PackageRoot, ...
                "results", "tables");
            testCase.applyFixture(PathFixture(fullfile( ...
                testCase.PackageRoot, "scripts")));
            testCase.applyFixture(PathFixture(fullfile( ...
                testCase.PackageRoot, "algorithms")));
            testCase.applyFixture(PathFixture(fullfile( ...
                testCase.PackageRoot, "datasets")));
        end
    end

    methods (Test)
        function staticMatrixIsComplete(testCase)
            data = readtable(fullfile(testCase.TablesDir, ...
                "table_algorithm_static_comparison.csv"), ...
                "TextType", "string");
            testCase.verifyEqual(height(data), 6);
            testCase.verifyEqual(data.case_count, repmat(768, 6, 1));
            testCase.verifyEqual(numel(unique(data.method)), 3);
            testCase.verifyEqual(numel(unique(data.mode)), 2);
        end

        function rampMatrixAndSourcesAreComplete(testCase)
            data = readtable(fullfile(testCase.TablesDir, ...
                "table_algorithm_ramp_tracking.csv"), ...
                "TextType", "string");
            main = data(data.source_model == ...
                "TRACE_DERIVED_OBSERVATION", :);
            crosscheck = data(data.source_model == ...
                "FULL_SWITCHING_MODEL_A_EQUATIONS", :);
            testCase.verifyEqual(height(data), 162);
            testCase.verifyEqual(height(main), 144);
            testCase.verifyEqual(height(crosscheck), 18);
            testCase.verifyEqual(sort(unique(main.trajectory_duration_s)), ...
                [0.1; 1; 10; 100]);
        end

        function frozenStepFailureIsRetained(testCase)
            data = readtable(fullfile(testCase.TablesDir, ...
                "table_algorithm_abrupt_step.csv"), ...
                "TextType", "string");
            ts = data(data.method == "M2 TS-SLTVKE" & ...
                ismember(data.trajectory_type, ...
                ["C_abrupt", "ESR_abrupt"]), :);
            testCase.verifyEqual(height(ts), 4);
            testCase.verifyTrue(all(ts.legacy_failure_reproduced));
        end

        function uncertaintyDoesNotModifyPointEstimate(testCase)
            data = readtable(fullfile(testCase.TablesDir, ...
                "table_algorithm_uncertainty.csv"), ...
                "TextType", "string");
            testCase.verifyEqual(height(data), 3);
            testCase.verifyTrue(all(data.point_estimate_unchanged));
            testCase.verifySubstring(data.uncertainty_type(1), ...
                "sandwich");
        end

        function bootstrapAndDecisionAreLocked(testCase)
            bootstrap = readtable(fullfile(testCase.TablesDir, ...
                "table_algorithm_paired_bootstrap.csv"), ...
                "TextType", "string");
            decision = readtable(fullfile(testCase.TablesDir, ...
                "table_algorithm_final_selection.csv"), ...
                "TextType", "string");
            allowed = ["PRIMARY_TS_D_RLS", "PRIMARY_TS_SLTVKE", ...
                "DUAL_REALIZATION", "ESTIMATOR_SELECTION_UNRESOLVED"];
            testCase.verifyEqual(height(bootstrap), 7);
            testCase.verifyEqual(bootstrap.bootstrap_count, ...
                repmat(10000, 7, 1));
            testCase.verifyTrue(ismember(decision.final_decision(1), allowed));
            testCase.verifyEqual(numel(unique(decision.final_decision)), 1);
        end

        function auditPassed(testCase)
            auditPath = fullfile(testCase.PackageRoot, "logs", ...
                "audit_paper_algorithm_selection_v1.txt");
            testCase.verifyTrue(isfile(auditPath));
            testCase.verifySubstring(string(fileread(auditPath)), ...
                "AUDIT=PASS");
        end
    end
end
