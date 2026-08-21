function data = simulate_switched_equation(p, options)
%SIMULATE_SWITCHED_EQUATION Fixed-step switching-level Cuk Model A.
%   DATA = SIMULATE_SWITCHED_EQUATION(P, OPTIONS) integrates the two PWM
%   topologies directly. The output voltage is its positive inverting
%   magnitude. Optional parameter steps are applied at exact sample times.

if nargin < 2
    options = struct();
end
samplesPerPeriod = get_option(options, "samplesPerPeriod", 200);
duration = get_option(options, "duration", 0.02);
dt = p.Ts / samplesPerPeriod;
n = round(duration / dt) + 1;
t = (0:n-1)' * dt;
u = double(mod(t, p.Ts) < p.D * p.Ts);

vOut0 = p.D / (1 - p.D) * p.Vin;
i20 = vOut0 / p.Rload;
i10 = p.D / (1 - p.D) * i20;
vC0 = p.Vin / (1 - p.D);
x0 = get_option(options, "initialState", [i10, i20, vC0, vOut0]);

x = zeros(n, 4);
x(1, :) = x0;
Ctrue = p.C1 * ones(n, 1);
ESRtrue = p.ESR * ones(n, 1);
Rtrue = p.Rload * ones(n, 1);
VinTrue = p.Vin * ones(n, 1);

[Ctrue, ESRtrue, Rtrue, VinTrue] = apply_steps( ...
    t, Ctrue, ESRtrue, Rtrue, VinTrue, options);

for k = 1:n-1
    local = p;
    local.C1 = Ctrue(k);
    local.ESR = ESRtrue(k);
    local.Rload = Rtrue(k);
    local.Vin = VinTrue(k);
    uk = u(k);
    xk = x(k, :)';
    k1 = state_derivative(xk, uk, local);
    k2 = state_derivative(xk + 0.5 * dt * k1, uk, local);
    k3 = state_derivative(xk + 0.5 * dt * k2, uk, local);
    k4 = state_derivative(xk + dt * k3, uk, local);
    x(k+1, :) = (xk + dt * (k1 + 2*k2 + 2*k3 + k4) / 6)';
end

i1 = x(:, 1);
i2 = x(:, 2);
vC = x(:, 3);
vo = x(:, 4);
iC = (1 - u) .* i1 - u .* i2;
vT = vC + ESRtrue .* iC;
if p.ESL ~= 0
    diCdt = [0; diff(iC)] / dt;
    vT = vT + p.ESL * diCdt;
end

data = struct("t", t, "dt", dt, "samplesPerPeriod", samplesPerPeriod, ...
    "u", u, "i1", i1, "i2", i2, "iC", iC, "vC", vC, ...
    "vT", vT, "vo", vo, "Ctrue", Ctrue, "ESRtrue", ESRtrue, ...
    "Rload", Rtrue, "Vin", VinTrue);
end

function dx = state_derivative(x, u, p)
i1 = x(1);
i2 = x(2);
vC = x(3);
vo = x(4);
if u >= 0.5
    di1 = (p.Vin - (p.rL1 + p.Rsw) * i1) / p.L1;
    di2 = (vC - p.ESR*i2 - vo - (p.rL2 + p.Rsw)*i2) / p.L2;
    iC = -i2;
else
    di1 = (p.Vin - vC - p.ESR*i1 - (p.rL1 + p.Rd)*i1 - p.Vd) / p.L1;
    di2 = (-vo - (p.rL2 + p.Rd)*i2 - p.Vd) / p.L2;
    iC = i1;
end
dvC = iC / p.C1;
dvo = (i2 - vo / p.Rload) / p.Co;
dx = [di1; di2; dvC; dvo];
end

function value = get_option(options, name, defaultValue)
if isfield(options, name)
    value = options.(name);
else
    value = defaultValue;
end
end

function [C, ESR, R, Vin] = apply_steps(t, C, ESR, R, Vin, options)
if isfield(options, "stepTime")
    idx = t >= options.stepTime;
    if isfield(options, "CFinal"), C(idx) = options.CFinal; end
    if isfield(options, "ESRFinal"), ESR(idx) = options.ESRFinal; end
    if isfield(options, "RFinal"), R(idx) = options.RFinal; end
    if isfield(options, "VinFinal"), Vin(idx) = options.VinFinal; end
end
end

