function out = run_estimator_on_features(method, F, cfg)
%RUN_ESTIMATOR_ON_FEATURES Run one estimator on a common O1 feature stream.
%   METHOD: "RLS"    - locked TS-D-RLS scalar recursions (lambda, P0);
%           "KF"     - direction-decoupled scalar Kalman updates with the
%                      locked Q/P0/NIS-gate hyperparameters (TS-SLTVKE
%                      point behavior for the two health directions);
%           "HYBRID" - KF plus a per-direction two-sided CUSUM supervisor
%                      on the (accepted and rejected) normalized
%                      innovations; an alarm resets that direction's
%                      covariance to its initialization value, restoring
%                      gain after abrupt health changes.
%   The charge row is ESR-compensated with each estimator's own preceding
%   ESR estimate, exactly as in the frozen pipelines.

n = F.nCycles;
theta = [cfg.Cb / cfg.Cinit; cfg.Rinit];
switch method
    case "RLS"
        Pa = cfg.rlsP0; Pr = cfg.rlsP0;
    otherwise
        Pa = cfg.kfP0Alpha; Pr = cfg.kfP0R;
end
gPlusA = 0; gMinusA = 0; gPlusR = 0; gMinusR = 0;
resets = 0;

C = zeros(n,1); R = zeros(n,1); sA = zeros(n,1); sR = zeros(n,1);
for k = 1:n
    if method ~= "RLS"
        Pa = Pa + cfg.kfQAlpha;
        Pr = Pr + cfg.kfQR;
    end
    % --- ESR (edge) direction. ---
    if F.validR(k)
        h = cfg.kR * F.Isum(k);
        innov = F.zR(k) - h * theta(2);
        switch method
            case "RLS"
                Pr = Pr / cfg.rlsLambda;
                K = Pr * h / (1 + h^2 * Pr);
                theta(2) = theta(2) + K * innov;
                Pr = (1 - K * h) * Pr;
            otherwise
                S = h^2 * Pr + cfg.RR;
                eps_n = innov / sqrt(S);
                accepted = eps_n^2 <= cfg.nisGate;
                if accepted
                    K = Pr * h / S;
                    theta(2) = theta(2) + K * innov;
                    Pr = (1 - K * h)^2 * Pr + K^2 * cfg.RR;
                end
                if method == "HYBRID"
                    e = max(min(eps_n, cfg.cusumClip), -cfg.cusumClip);
                    gPlusR = max(0, gPlusR + e - cfg.cusumDrift);
                    gMinusR = max(0, gMinusR - e - cfg.cusumDrift);
                    if max(gPlusR, gMinusR) > cfg.cusumThreshold
                        Pr = cfg.kfP0R;
                        gPlusR = 0; gMinusR = 0;
                        resets = resets + 1;
                    end
                end
        end
    end
    % --- Capacitance (charge) direction. ---
    if F.validC(k)
        h = F.q(k) / cfg.Cb;
        z = F.dvT(k) - theta(2) * F.diC(k);
        innov = z - h * theta(1);
        switch method
            case "RLS"
                Pa = Pa / cfg.rlsLambda;
                K = Pa * h / (1 + h^2 * Pa);
                theta(1) = theta(1) + K * innov;
                Pa = (1 - K * h) * Pa;
            otherwise
                S = h^2 * Pa + cfg.RC;
                eps_n = innov / sqrt(S);
                accepted = eps_n^2 <= cfg.nisGate;
                if accepted
                    K = Pa * h / S;
                    theta(1) = theta(1) + K * innov;
                    Pa = (1 - K * h)^2 * Pa + K^2 * cfg.RC;
                end
                if method == "HYBRID"
                    e = max(min(eps_n, cfg.cusumClip), -cfg.cusumClip);
                    gPlusA = max(0, gPlusA + e - cfg.cusumDrift);
                    gMinusA = max(0, gMinusA - e - cfg.cusumDrift);
                    if max(gPlusA, gMinusA) > cfg.cusumThreshold
                        Pa = cfg.kfP0Alpha;
                        gPlusA = 0; gMinusA = 0;
                        resets = resets + 1;
                    end
                end
        end
    end
    theta(1) = min(max(theta(1), cfg.Cb/cfg.CBounds(2)), cfg.Cb/cfg.CBounds(1));
    theta(2) = min(max(theta(2), cfg.RBounds(1)), cfg.RBounds(2));
    C(k) = cfg.Cb / theta(1);
    R(k) = theta(2);
    sA(k) = sqrt(max(Pa, 0));
    sR(k) = sqrt(max(Pr, 0));
end
% Interval half-widths mapped to C units: sigma_C = (Cb/alpha^2) sigma_alpha.
alphaHat = cfg.Cb ./ C;
out = struct("C", C, "ESR", R, ...
    "sigmaC", cfg.Cb ./ max(alphaHat.^2, eps) .* sA, "sigmaR", sR, ...
    "resets", resets);
end
