classdef v22PipelineTest < matlab.unittest.TestCase
    %V22PIPELINETEST Persistent regression tests for v2.2 outputs.

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
        function testConfigurationIsParameterized(testCase)
            cfg = v22_default_config();
            testCase.verifyEqual(cfg.targetStatus, "TARGET_DSP_NOT_FIXED");
            testCase.verifyEqual(numel(cfg.profiles), 4);
            testCase.verifyEqual(numel(cfg.architectures), 3);
        end

        function testMandatoryOutputs(testCase)
            audit = validate_v22_outputs(testCase.Root);
            testCase.verifyEqual(audit.status, "PASS");
            testCase.verifyEqual(audit.mandatoryTables, 12);
            testCase.verifyEqual(audit.mandatoryFigures, 12);
        end

        function testNativeHighResolutionDecision(testCase)
            comparison = v22PipelineTest.readComparison(testCase.Root);
            native16 = comparison(comparison.path_id == "native_16_V2", :);
            native12 = comparison(comparison.path_id == "native_12_V2", :);
            testCase.verifyGreaterThanOrEqual( ...
                native16.accuracy_pass_fraction, .95);
            testCase.verifyLessThan(native12.accuracy_pass_fraction, .95);
            testCase.verifyLessThan(native16.C_MAPE_worst_percent, 3);
            testCase.verifyLessThan(native16.ESR_MAPE_worst_percent, 5);
        end

        function testHighResolutionGeometry(testCase)
            selected = v22PipelineTest.readSelectedGeometry(testCase.Root);
            highResolution = selected(selected.fs_adc_Hz == 1.1e6, :);
            testCase.verifyEqual(height(highResolution), 1);
            testCase.verifyEqual(highResolution.guard_us, .2, AbsTol=1e-12);
            testCase.verifyEqual(highResolution.window_us, 2, AbsTol=1e-12);
            testCase.verifyGreaterThanOrEqual( ...
                highResolution.points_available_per_side, 3);
            testCase.verifyLessThan( ...
                highResolution.modelB_worst_extrapolation_bias_percent, 5);
        end

        function testCurrentRangeIsNotLegacy40A(testCase)
            range = v22PipelineTest.readCurrentRange(testCase.Root);
            selected = range(range.transient_margin == 1.5, :);
            testCase.verifyEqual(selected.engineering_full_scale_A, 20, ...
                AbsTol=1e-12);
            testCase.verifyLessThan(selected.engineering_full_scale_A, 40);
        end
    end

    methods (Static, Access=private)
        function T = readComparison(root)
            T = readtable(fullfile(root, "results", "tables", ...
                "table_native_vs_external_v22.csv"), TextType="string");
        end

        function T = readSelectedGeometry(root)
            T = readtable(fullfile(root, "results", "tables", ...
                "table_native_adc_geometry_v22.csv"), TextType="string");
            T = T(T.selected ~= 0, :);
        end

        function T = readCurrentRange(root)
            T = readtable(fullfile(root, "results", "tables", ...
                "table_current_range_design_v22.csv"), TextType="string");
        end
    end
end
