function result = run_locked_o1_estimator(method, obs, cfg)
%RUN_LOCKED_O1_ESTIMATOR Run one frozen estimator on a common O1 stream.
% Point-estimator updates are unchanged from Paper Verification v1.1.

arguments
    method (1, 1) string
    obs (1, 1) struct
    cfg (1, 1) struct
end

n = numel(obs.time_s);
theta = [cfg.Cb / obs.Cinit; obs.Rinit];
switch method
    case "M1 TS-D-RLS"
        P = cfg.rlsP0 * eye(2);
    case "M2 TS-SLTVKE"
        P = diag([cfg.ltvP0Alpha, ...
            (cfg.ltvP0RScale * obs.Rtruth(1))^2]);
    case "M3 Dual EKF"
        P = diag([cfg.dualP0Alpha, ...
            (cfg.dualP0RScale * obs.Rtruth(1))^2]);
    otherwise
        error("algsel:UnknownMethod", "Unknown method %s.", method);
end

thetaHistory = zeros(n, 2);
pAlpha = zeros(n, 1);
pR = zeros(n, 1);
nisC = NaN(n, 1);
nisR = NaN(n, 1);
acceptedC = false(n, 1);
acceptedR = false(n, 1);
projectionActivation = false(n, 1);
residualC = NaN(n, 1);
residualR = NaN(n, 1);
informationC = zeros(n, 1);
informationR = zeros(n, 1);
Pv = 0.25;

for k = 1:n
    cycleCount = obs.group_cycles(k);
    switch method
        case "M1 TS-D-RLS"
            P = P / cfg.rlsLambda^cycleCount;
            if obs.validC(k)
                residualC(k) = obs.zC(k) - obs.hC(k) * theta(1);
                [theta, P] = rlsMeasurement(theta, P, obs.zC(k), ...
                    [obs.hC(k), 0], obs.RC(k));
                acceptedC(k) = true;
                informationC(k) = obs.hC(k)^2 / obs.RC(k);
            end
            if obs.validR(k)
                residualR(k) = obs.zR(k) - obs.hR(k) * theta(2);
                [theta, P] = rlsMeasurement(theta, P, obs.zR(k), ...
                    [0, obs.hR(k)], obs.RR(k));
                acceptedR(k) = true;
                informationR(k) = obs.hR(k)^2 / obs.RR(k);
            end
        case "M2 TS-SLTVKE"
            P = P + cfg.ltvQ * cycleCount;
            if obs.validC(k)
                residualC(k) = obs.zC(k) - obs.hC(k) * theta(1);
                [theta, P, nisC(k), acceptedC(k)] = ...
                    kalmanMeasurement(theta, P, obs.zC(k), ...
                    [obs.hC(k), 0], obs.RC(k), cfg.nisGate);
                informationC(k) = obs.hC(k)^2 / obs.RC(k);
            end
            if obs.validR(k)
                residualR(k) = obs.zR(k) - obs.hR(k) * theta(2);
                [theta, P, nisR(k), acceptedR(k)] = ...
                    kalmanMeasurement(theta, P, obs.zR(k), ...
                    [0, obs.hR(k)], obs.RR(k), cfg.nisGate);
                informationR(k) = obs.hR(k)^2 / obs.RR(k);
            end
        case "M3 Dual EKF"
            stateR = max(obs.sigmaV(k)^2, 1e-8);
            PvPred = Pv + 2.5e-5 * cycleCount;
            Kstate = PvPred / (PvPred + stateR);
            Pv = (1 - Kstate) * PvPred;
            P = P + cfg.dualQ * cycleCount;
            if obs.validC(k)
                residualC(k) = obs.zC(k) - obs.hC(k) * theta(1);
                [theta, P, nisC(k), acceptedC(k)] = ...
                    kalmanMeasurement(theta, P, obs.zC(k), ...
                    [obs.hC(k), 0], obs.RC(k) + 0.15 * Pv, Inf);
                informationC(k) = obs.hC(k)^2 / obs.RC(k);
            end
            if obs.validR(k)
                residualR(k) = obs.zR(k) - obs.hR(k) * theta(2);
                [theta, P, nisR(k), acceptedR(k)] = ...
                    kalmanMeasurement(theta, P, obs.zR(k), ...
                    [0, obs.hR(k)], obs.RR(k) + 0.15 * Pv, Inf);
                informationR(k) = obs.hR(k)^2 / obs.RR(k);
            end
    end
    before = theta;
    theta(1) = min(max(theta(1), cfg.Cb / cfg.CBounds(2)), ...
        cfg.Cb / cfg.CBounds(1));
    theta(2) = min(max(theta(2), cfg.RBounds(1)), cfg.RBounds(2));
    projectionActivation(k) = any(abs(theta - before) > ...
        10 * eps(max(abs(before), 1)));
    thetaHistory(k, :) = theta.';
    pAlpha(k) = P(1, 1);
    pR(k) = P(2, 2);
end

Cest = cfg.Cb ./ thetaHistory(:, 1);
Rest = thetaHistory(:, 2);
sigmaC = cfg.Cb ./ max(thetaHistory(:, 1).^2, eps) .* ...
    sqrt(max(pAlpha, 0));
sigmaR = sqrt(max(pR, 0));
diagnostic = uncertaintyDiagnostic(residualC, residualR, obs, ...
    informationC, informationR, cfg, theta);

result = struct( ...
    "method", method, ...
    "time_s", obs.time_s, ...
    "cycle", obs.cycle, ...
    "C", Cest, ...
    "ESR", Rest, ...
    "theta", thetaHistory, ...
    "P_alpha", pAlpha, ...
    "P_R", pR, ...
    "sigmaC", sigmaC, ...
    "sigmaR", sigmaR, ...
    "nisC", nisC, ...
    "nisR", nisR, ...
    "acceptedC", acceptedC, ...
    "acceptedR", acceptedR, ...
    "accepted_C_updates", sum(obs.accepted_C_count(acceptedC)), ...
    "accepted_R_updates", sum(obs.accepted_R_count(acceptedR)), ...
    "rejected_C_groups", nnz(obs.validC & ~acceptedC), ...
    "rejected_R_groups", nnz(obs.validR & ~acceptedR), ...
    "projection_activations", nnz(projectionActivation), ...
    "reportMask", obs.reportMask, ...
    "uncertainty", diagnostic, ...
    "finalP", P);
end

function [theta, P] = rlsMeasurement(theta, P, z, H, R)
S = H * P * H.' + R;
K = P * H.' / S;
theta = theta + K * (z - H * theta);
A = eye(2) - K * H;
P = A * P * A.' + K * R * K.';
P = 0.5 * (P + P.');
end

function [theta, P, nis, accepted] = kalmanMeasurement(theta, P, z, H, R, gate)
innovation = z - H * theta;
S = H * P * H.' + R;
nis = innovation^2 / max(S, eps);
accepted = isfinite(nis) && nis <= gate;
if accepted
    K = P * H.' / S;
    theta = theta + K * innovation;
    A = eye(2) - K * H;
    P = A * P * A.' + K * R * K.';
    P = 0.5 * (P + P.');
end
end

function diagnostic = uncertaintyDiagnostic(resC, resR, obs, ...
        infoC, infoR, cfg, theta)
validC = isfinite(resC) & infoC > 0;
validR = isfinite(resR) & infoR > 0;
[varAlpha, typeC] = robustDirectionVariance(resC(validC), ...
    obs.hC(validC), obs.RC(validC), sum(infoC(validC)));
[varR, typeR] = robustDirectionVariance(resR(validR), ...
    obs.hR(validR), obs.RR(validR), sum(infoR(validR)));
varC = (cfg.Cb / max(theta(1)^2, eps))^2 * varAlpha;
diagnostic = struct( ...
    "variance_C", varC, ...
    "variance_R", varR, ...
    "sigma_C", sqrt(max(varC, 0)), ...
    "sigma_R", sqrt(max(varR, 0)), ...
    "type_C", typeC, ...
    "type_R", typeR);
end

function [variance, type] = robustDirectionVariance(residual, h, R, info)
if numel(residual) < 3 || info <= 0
    variance = NaN;
    type = "insufficient residuals";
    return;
end
w = 1 ./ R;
weightedScale = sum(w .* residual.^2) / max(numel(residual) - 1, 1);
classic = weightedScale / info;
sandwich = sum((w .* h .* residual).^2) / info^2;
variance = max(classic, sandwich);
type = "weighted residual + information inverse + sandwich maximum";
end
