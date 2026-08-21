function p = model_parameters()
%MODEL_PARAMETERS Return the reproducible benchmark and nonideal parameters.

p.Vin = 24;
p.D = 0.40;
p.fs = 50e3;
p.Ts = 1 / p.fs;
p.L1 = 500e-6;
p.L2 = 500e-6;
p.C1 = 100e-6;
p.ESR = 50e-3;
p.Co = 470e-6;
p.Rload = 10;

% Individually enabled nonideal terms.
p.rL1 = 0;
p.rL2 = 0;
p.Rsw = 0;
p.Vd = 0;
p.Rd = 0;
p.ESL = 0;
end

