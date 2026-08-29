function result = ts_ltvkf(data, options)
%TS_LTVKF Topology-synchronous LTV Kalman filter with Joseph update.

if nargin < 2
    options = struct();
end
Cnom = get_option(options, "Cnom", median(data.Ctrue));
ESRnom = get_option(options, "ESRnom", median(data.ESRtrue));
Cinit = get_option(options, "Cinit", 0.7*Cnom);
ESRinit = get_option(options, "ESRinit", 0.5*ESRnom);
sampleStride = get_option(options, "sampleStride", 1);
measurementVariance = get_option(options, "measurementVariance", 1e-8);
gateThreshold = get_option(options, "gateThreshold", 8);
alphaScale = 1e-4;

idx = (1:sampleStride:numel(data.t))';
t = data.t(idx);
iC = data.iC(idx);
vT = data.vT(idx);
n = numel(idx);
x = [vT(1)-ESRinit*iC(1); alphaScale/Cinit; ESRinit];
P = get_option(options, "initialCovariance", ...
    diag([1, 0.25^2, (0.75*ESRnom)^2]));
Q = get_option(options, "processCovariance", diag([1e-9, 2e-10, 2e-10]));
R = measurementVariance;
I = eye(3);

xHistory = zeros(n, 3);
sigmaC = zeros(n, 1);
sigmaR = zeros(n, 1);
innovation = zeros(n, 1);
accepted = false(n, 1);
xHistory(1, :) = x';
sigmaC(1) = alphaScale/x(2)^2*sqrt(P(2,2));
sigmaR(1) = sqrt(P(3,3));

for k = 2:n
    q = 0.5*(iC(k-1)+iC(k))*(t(k)-t(k-1));
    F = [1, q/alphaScale, 0; 0, 1, 0; 0, 0, 1];
    xPred = F*x;
    PPred = F*P*F' + Q;
    H = [1, 0, iC(k)];
    innovation(k) = vT(k) - H*xPred;
    S = H*PPred*H' + R;
    nis = innovation(k)^2 / max(S, eps);
    if nis <= gateThreshold^2
        K = PPred*H'/S;
        x = xPred + K*innovation(k);
        A = I-K*H;
        P = A*PPred*A' + K*R*K';
        accepted(k) = true;
    else
        x = xPred;
        P = PPred;
    end
    C = alphaScale / max(x(2), eps);
    C = min(max(C, 0.5*Cnom), 1.5*Cnom);
    x(2) = alphaScale/C;
    x(3) = min(max(x(3), 0.1*ESRnom), 4*ESRnom);
    P = 0.5*(P+P');
    xHistory(k, :) = x';
    sigmaC(k) = alphaScale/x(2)^2*sqrt(max(P(2,2),0));
    sigmaR(k) = sqrt(max(P(3,3),0));
end

result = struct("t", t, "index", idx, "vC", xHistory(:,1), ...
    "C", alphaScale./xHistory(:,2), "ESR", xHistory(:,3), ...
    "sigmaC", sigmaC, "sigmaESR", sigmaR, "innovation", innovation, ...
    "accepted", accepted, "P", P, "Cfinal", alphaScale/x(2), ...
    "ESRfinal", x(3));
end

function value = get_option(options, name, defaultValue)
if isfield(options, name), value = options.(name); else, value = defaultValue; end
end
