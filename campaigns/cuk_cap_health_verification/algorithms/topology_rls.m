function result = topology_rls(Phi, z, options)
%TOPOLOGY_RLS Ordinary/forgetting/projected topology regression.

if nargin < 3
    options = struct();
end
lambda = get_option(options, "lambda", 0.995);
Cnom = get_option(options, "Cnom", 100e-6);
ESRnom = get_option(options, "ESRnom", 50e-3);
Cinit = get_option(options, "Cinit", 0.7*Cnom);
ESRinit = get_option(options, "ESRinit", 0.5*ESRnom);
project = get_option(options, "project", true);

scale = [1e-5, 1];
phiScaled = Phi ./ scale;
beta = [scale(1)/Cinit; ESRinit*scale(2)];
P = diag([10, 1e-2]);
n = size(Phi, 1);
Cest = zeros(n, 1);
Rest = zeros(n, 1);
innovation = zeros(n, 1);

for k = 1:n
    phi = phiScaled(k, :)';
    gain = P*phi / (lambda + phi'*P*phi);
    innovation(k) = z(k) - phi'*beta;
    beta = beta + gain*innovation(k);
    P = (P - gain*phi'*P) / lambda;
    P = 0.5*(P + P');
    if project
        C = scale(1) / max(beta(1), eps);
        C = min(max(C, 0.5*Cnom), 1.5*Cnom);
        beta(1) = scale(1) / C;
        beta(2) = min(max(beta(2), 0.1*ESRnom), 4*ESRnom);
    end
    Cest(k) = scale(1) / beta(1);
    Rest(k) = beta(2) / scale(2);
end

result = struct("C", Cest, "ESR", Rest, "innovation", innovation, ...
    "Cfinal", Cest(end), "ESRfinal", Rest(end), "P", P, ...
    "lambda", lambda);
end

function value = get_option(options, name, defaultValue)
if isfield(options, name), value = options.(name); else, value = defaultValue; end
end

