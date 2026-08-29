function build_cuk_switched_equation_model()
%BUILD_CUK_SWITCHED_EQUATION_MODEL Rebuild the Model-A Simulink realization.
%   Reconstructs model/cuk_switched_equation_model.slx from Simulink
%   primitives implementing the ideal-parasitic switched Cuk equations with
%   the transfer-capacitor ESR retained (Appendix A of the manuscript):
%
%     u=1: di1 = Vin/L1,                 di2 = (vC - ESR*i2 - vo)/L2, iC = -i2
%     u=0: di1 = (Vin - vC - ESR*i1)/L1, di2 = -vo/L2,                iC = +i1
%     dvC = iC/C1, dvo = (i2 - vo/Rload)/Co, vT = vC + ESR*iC
%
%   Unified form used by the diagram (equivalent to the above):
%     di1 = (Vin - (1-u)*(vC + ESR*i1))/L1
%     di2 = (u*(vC - ESR*i2) - vo)/L2
%     iC  = (1-u)*i1 - u*i2
%
%   Parameters are workspace variables (Vin, D, Ts, L1, L2, C1, ESR, Co,
%   Rload, I1_init, I2_init, VC_init, VO_init) supplied by
%   scripts/run_simulink_model_a.m through Simulink.SimulationInput.
%   Logged signals: u, i1, i2, iC, vC, vT, vo.

name = "cuk_switched_equation_model";
here = fileparts(mfilename("fullpath"));
target = fullfile(here, name + ".slx");

if bdIsLoaded(name), close_system(name, 0); end
if isfile(target)
    backup = fullfile(here, name + "_empty_backup.slx");
    if ~isfile(backup), copyfile(target, backup); end
    delete(target);
end
new_system(name);

add = @(kind, blk, pos, varargin) add_block(kind, name + "/" + blk, ...
    "Position", pos, varargin{:});

% Sources and state integrators.
add("simulink/Sources/Pulse Generator", "PWM", [40 40 80 70], ...
    "PulseType", "Sample based", "Amplitude", "1", "Period", "200", ...
    "PulseWidth", "round(200*D)", "PhaseDelay", "0", ...
    "SampleTime", "Ts/200");
add("simulink/Sources/Constant", "One", [40 110 80 140], "Value", "1");
add("simulink/Sources/Constant", "VinSrc", [40 180 80 210], "Value", "Vin");
add("simulink/Continuous/Integrator", "Int_i1", [560 40 600 80], ...
    "InitialCondition", "I1_init");
add("simulink/Continuous/Integrator", "Int_i2", [560 140 600 180], ...
    "InitialCondition", "I2_init");
add("simulink/Continuous/Integrator", "Int_vC", [560 240 600 280], ...
    "InitialCondition", "VC_init");
add("simulink/Continuous/Integrator", "Int_vo", [560 340 600 380], ...
    "InitialCondition", "VO_init");

% 1-u.
add("simulink/Math Operations/Sum", "OneMinusU", [130 100 160 130], ...
    "Inputs", "+-");

% iC = (1-u)*i1 - u*i2.
add("simulink/Math Operations/Product", "OffI1", [220 420 250 450]);
add("simulink/Math Operations/Product", "OnI2", [220 480 250 510]);
add("simulink/Math Operations/Sum", "SumIC", [300 440 330 470], ...
    "Inputs", "+-");

% di1 = (Vin - (1-u)*(vC + ESR*i1)) / L1.
add("simulink/Math Operations/Gain", "EsrI1", [130 250 160 280], ...
    "Gain", "ESR");
add("simulink/Math Operations/Sum", "VcPlusEsrI1", [200 240 230 270], ...
    "Inputs", "++");
add("simulink/Math Operations/Product", "OffTerm1", [270 230 300 260]);
add("simulink/Math Operations/Sum", "SumDi1", [340 40 370 70], ...
    "Inputs", "+-");
add("simulink/Math Operations/Gain", "InvL1", [420 40 460 70], ...
    "Gain", "1/L1");

% di2 = (u*(vC - ESR*i2) - vo) / L2.
add("simulink/Math Operations/Gain", "EsrI2", [130 320 160 350], ...
    "Gain", "ESR");
add("simulink/Math Operations/Sum", "VcMinusEsrI2", [200 310 230 340], ...
    "Inputs", "+-");
add("simulink/Math Operations/Product", "OnTerm2", [270 300 300 330]);
add("simulink/Math Operations/Sum", "SumDi2", [340 140 370 170], ...
    "Inputs", "+-");
add("simulink/Math Operations/Gain", "InvL2", [420 140 460 170], ...
    "Gain", "1/L2");

% dvC = iC / C1.
add("simulink/Math Operations/Gain", "InvC1", [420 240 460 270], ...
    "Gain", "1/C1");

% dvo = (i2 - vo/Rload) / Co.
add("simulink/Math Operations/Gain", "InvR", [130 390 160 420], ...
    "Gain", "1/Rload");
add("simulink/Math Operations/Sum", "SumDvo", [340 340 370 370], ...
    "Inputs", "+-");
add("simulink/Math Operations/Gain", "InvCo", [420 340 460 370], ...
    "Gain", "1/Co");

% vT = vC + ESR*iC.
add("simulink/Math Operations/Gain", "EsrIC", [400 440 430 470], ...
    "Gain", "ESR");
add("simulink/Math Operations/Sum", "SumVT", [480 440 510 470], ...
    "Inputs", "++");
add("simulink/Sinks/Terminator", "EndVT", [560 440 590 470]);

% Wiring.
c = @(src, dst) add_line(name, src, dst, "autorouting", "on");
c("PWM/1", "OneMinusU/2");
c("One/1", "OneMinusU/1");

c("OneMinusU/1", "OffI1/1");
c("Int_i1/1", "OffI1/2");
c("PWM/1", "OnI2/1");
c("Int_i2/1", "OnI2/2");
c("OffI1/1", "SumIC/1");
c("OnI2/1", "SumIC/2");

c("Int_i1/1", "EsrI1/1");
c("Int_vC/1", "VcPlusEsrI1/1");
c("EsrI1/1", "VcPlusEsrI1/2");
c("OneMinusU/1", "OffTerm1/1");
c("VcPlusEsrI1/1", "OffTerm1/2");
c("VinSrc/1", "SumDi1/1");
c("OffTerm1/1", "SumDi1/2");
c("SumDi1/1", "InvL1/1");
c("InvL1/1", "Int_i1/1");

c("Int_i2/1", "EsrI2/1");
c("Int_vC/1", "VcMinusEsrI2/1");
c("EsrI2/1", "VcMinusEsrI2/2");
c("PWM/1", "OnTerm2/1");
c("VcMinusEsrI2/1", "OnTerm2/2");
c("OnTerm2/1", "SumDi2/1");
c("Int_vo/1", "SumDi2/2");
c("SumDi2/1", "InvL2/1");
c("InvL2/1", "Int_i2/1");

c("SumIC/1", "InvC1/1");
c("InvC1/1", "Int_vC/1");

c("Int_vo/1", "InvR/1");
c("Int_i2/1", "SumDvo/1");
c("InvR/1", "SumDvo/2");
c("SumDvo/1", "InvCo/1");
c("InvCo/1", "Int_vo/1");

c("SumIC/1", "EsrIC/1");
c("Int_vC/1", "SumVT/1");
c("EsrIC/1", "SumVT/2");
c("SumVT/1", "EndVT/1");

% Signal logging with the audited names.
logSpec = { ...
    "PWM", 1, "u"; "Int_i1", 1, "i1"; "Int_i2", 1, "i2"; ...
    "SumIC", 1, "iC"; "Int_vC", 1, "vC"; "SumVT", 1, "vT"; ...
    "Int_vo", 1, "vo"};
for k = 1:size(logSpec, 1)
    ph = get_param(name + "/" + logSpec{k,1}, "PortHandles");
    line = get_param(ph.Outport(logSpec{k,2}), "Line");
    set_param(line, "Name", logSpec{k,3});
    set_param(ph.Outport(logSpec{k,2}), "DataLogging", "on", ...
        "DataLoggingNameMode", "SignalName");
end

set_param(name, "SolverType", "Fixed-step", "Solver", "ode4", ...
    "FixedStep", "Ts/200", "StopTime", "0.02", ...
    "SignalLogging", "on", "SignalLoggingName", "logsout", ...
    "SaveFormat", "Dataset");
save_system(name, target);
close_system(name, 0);
fprintf("Rebuilt %s\n", target);
end
