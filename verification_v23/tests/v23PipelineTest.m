classdef v23PipelineTest < matlab.unittest.TestCase
    %V23PIPELINETEST Persistent tests for device-specific closure.

    properties
        Root
    end

    methods (TestClassSetup)
        function configurePath(testCase)
            root = fileparts(fileparts(mfilename("fullpath")));
            testCase.Root = root;
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(root, ...
                IncludingSubfolders=true));
        end
    end

    methods (Test)
        function testExactTiming(testCase)
            cfg = v23_default_config();
            testCase.verifyEqual(cfg.acquisitionS, 320e-9, AbsTol=1e-15);
            testCase.verifyEqual(cfg.conversionS, 595e-9, AbsTol=1e-15);
            testCase.verifyEqual(cfg.startIntervalS, 915e-9, AbsTol=1e-15);
            testCase.verifyEqual(cfg.nativeRateHz, 1/915e-9, RelTol=1e-12);
        end

        function testFullApertureCorrection(testCase)
            T = v23PipelineTest.readGeometry(testCase.Root);
            original = T(T.guard_us == .2 & T.window_us == 2 & ...
                T.points_per_side == 3, :);
            selected = T(T.selected ~= 0, :);
            testCase.verifyEqual(original.point_timestamp_pass, 1);
            testCase.verifyEqual(original.full_aperture_pass, 0);
            testCase.verifyEqual(selected.full_aperture_pass, 1);
            testCase.verifyEqual(selected.full_aperture_span_us, 2.15, AbsTol=1e-12);
        end

        function testDeviceAccuracy(testCase)
            T = v23PipelineTest.readMonteCarlo(testCase.Root);
            testCase.verifyLessThan(max(T.p95_C_abs_error_percent), 3);
            testCase.verifyLessThan(max(T.p95_ESR_abs_error_percent), 5);
            testCase.verifyGreaterThanOrEqual(min(T.pass_fraction), .95);
            testCase.verifyEqual(T.GroupCount, repmat(200, height(T), 1));
        end

        function testMandatoryOutputs(testCase)
            audit = validate_v23_outputs(testCase.Root);
            testCase.verifyEqual(audit.status, "PASS");
            testCase.verifyEqual(audit.mandatoryTables, 15);
            testCase.verifyEqual(audit.mandatoryFigures, 14);
            testCase.verifyEqual(audit.mandatoryDocuments, 8);
        end

        function testDecisionEnumeration(testCase)
            cfg = v23_default_config();
            metrics = v23PipelineTest.readMetrics(testCase.Root);
            decision = string(metrics.value(metrics.metric == "decision"));
            testCase.verifyTrue(ismember(decision, cfg.allowedDecisions));
            testCase.verifyEqual(decision, ...
                "F28379D_INTERNAL_ADC_CONFIRMED_WITH_AFE_CONSTRAINTS");
        end
    end

    methods (Static, Access=private)
        function T = readGeometry(root)
            T = readtable(fullfile(root, "results", "tables", ...
                "table_full_aperture_geometry.csv"), TextType="string");
        end

        function T = readMonteCarlo(root)
            T = readtable(fullfile(root, "results", "tables", ...
                "table_v23_monte_carlo.csv"), TextType="string");
        end

        function T = readMetrics(root)
            opts = delimitedTextImportOptions(NumVariables=4);
            opts.DataLines = [2 Inf];
            opts.Delimiter = ",";
            opts.VariableNames = ["metric" "value" "unit" "status"];
            opts.VariableTypes = ["string" "string" "string" "string"];
            T = readtable(fullfile(root, "result_metrics_v23.csv"), opts);
        end
    end
end
