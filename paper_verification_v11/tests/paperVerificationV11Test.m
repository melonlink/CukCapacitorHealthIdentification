classdef paperVerificationV11Test < matlab.unittest.TestCase
    %PAPERVERIFICATIONV11TEST Output-level tests for the v1.1 package.

    properties
        PackageRoot
        TableDir
        RawDir
    end

    methods (TestClassSetup)
        function configurePaths(testCase)
            testRoot = fileparts(mfilename("fullpath"));
            testCase.PackageRoot = string(fileparts(testRoot));
            testCase.TableDir = fullfile(testCase.PackageRoot, ...
                "results", "tables");
            testCase.RawDir = fullfile(testCase.PackageRoot, ...
                "results", "raw");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.PackageRoot, "scripts")));
        end
    end

    methods (Test)
        function testFactorialCardinality(testCase)
            rows = readtable(fullfile(testCase.RawDir, ...
                "factorial_rows.csv"), TextType="string");
            counts = groupcounts(rows, ["observation", "estimator"]);

            testCase.verifyEqual(height(rows), 4608);
            testCase.verifyEqual(height(counts), 6);
            testCase.verifyEqual(counts.GroupCount, repmat(768, 6, 1));
        end

        function testPairingKeys(testCase)
            rows = readtable(fullfile(testCase.RawDir, ...
                "factorial_rows.csv"), TextType="string");
            keyNames = ["estimator", "case_id", "noise_profile", ...
                "skew_ns", "seed"];
            o0 = sortrows(rows(rows.observation == "O0 Mixed", keyNames), ...
                keyNames);
            o1 = sortrows(rows(rows.observation == "O1 Proposed", keyNames), ...
                keyNames);

            testCase.verifyEqual(o0, o1);
        end

        function testHyperparameterLock(testCase)
            locked = readtable(fullfile(testCase.PackageRoot, ...
                "LOCKED_FACTORIAL_HYPERPARAMETERS.csv"), TextType="string");

            testCase.verifyTrue(all(locked.applies_to_O0));
            testCase.verifyTrue(all(locked.applies_to_O1));
            testCase.verifyTrue(all(locked.locked_before_blind));
        end

        function testBootstrapCoverage(testCase)
            bootstrap = readtable(fullfile(testCase.TableDir, ...
                "table_observation_effect_bootstrap.csv"), TextType="string");

            testCase.verifyEqual(height(bootstrap), 18);
            testCase.verifyEqual(bootstrap.bootstrap_replicates, ...
                repmat(10000, 18, 1));
            testCase.verifyTrue(all(isfinite(bootstrap.mean_paired_effect)));
        end

        function testPhysicalPeBounds(testCase)
            pe = readtable(fullfile(testCase.TableDir, ...
                "table_physical_PE_lower_bound.csv"), TextType="string");

            testCase.verifyGreaterThanOrEqual(height(pe), 36);
            testCase.verifyTrue(all(pe.ratio_C >= 1 - 1e-10));
            testCase.verifyTrue(all(pe.ratio_R >= 1 - 1e-10));
            testCase.verifyTrue(all(pe.sign_invariant));
        end

        function testCovarianceFixedPoint(testCase)
            covariance = readtable(fullfile(testCase.TableDir, ...
                "table_covariance_bound_validation.csv"), TextType="string");
            expected = (-covariance.Q_N + sqrt(covariance.Q_N.^2 + ...
                4 * covariance.Q_N ./ covariance.mu_lower)) / 2;

            testCase.verifyEqual(covariance.P_star, expected, ...
                AbsTol=1e-14, RelTol=1e-12);
            testCase.verifyTrue(all(covariance.bound_pass));
            testCase.verifyLessThanOrEqual( ...
                covariance.Q0_sanity_max_error, repmat(1e-12, 10, 1));
        end

        function testProjectionOffRetained(testCase)
            projection = readtable(fullfile(testCase.TableDir, ...
                "table_projection_on_off.csv"), TextType="string");

            testCase.verifyEqual(projection.projection_state, ["ON"; "OFF"]);
            testCase.verifyEqual(projection.N_seeds, [200; 200]);
            testCase.verifyEqual(projection.divergence_rate, [0; 0], ...
                AbsTol=1e-12);
        end

        function testRequiredArtifacts(testCase)
            figures = dir(fullfile(testCase.PackageRoot, "results", ...
                "figures", "fig_pv11_*.png"));
            reports = [
                "FACTORIAL_PROTOCOL.md"
                "OBSERVATION_FACTORIAL_RESULTS.md"
                "PAPER_THEORY_PROOF_V11.md"
                "PAPER_VERIFICATION_V11_RESULT.md"
                "PAPER_READY_UPDATE_V11.md"
                ];

            testCase.verifyEqual(numel(figures), 10);
            testCase.verifyTrue(all(isfile(fullfile( ...
                testCase.PackageRoot, reports))));
        end
    end
end
